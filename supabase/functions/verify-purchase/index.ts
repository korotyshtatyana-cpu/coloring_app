// Verifies a Google Play purchase and grants the matching entitlement.
//
// The caller is authenticated with a Supabase JWT. The user identifier comes
// exclusively from the verified token; any client supplied `user_id` is
// ignored. One-time purchases grant credits through the `add_credits` RPC and
// subscriptions are stored in the `subscriptions` table.
//
// Required environment variables:
//   SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY
//   GOOGLE_SERVICE_ACCOUNT_JSON, GOOGLE_PLAY_PACKAGE_NAME
//
// Deploy with:
//   supabase functions deploy verify-purchase

import {
  assertGooglePlayConfig,
  getProduct,
  getSubscription,
  GooglePlayApiError,
} from "../_shared/google_play_auth.ts";
import {
  corsHeaders,
  createAdminClient,
  createUserClient,
} from "../_shared/supabase.ts";

assertGooglePlayConfig();

const TYPE_SUBSCRIPTION = "subscription";
const TYPE_CREDITS = "credits";
const PLATFORM_GOOGLE = "google";
const PLATFORM_APPLE = "apple";

const CREDIT_PRODUCT_ID = "unlock_credit";
const NO_ADS_PREFIX = "no_ads_";
const PREMIUM_PREFIX = "premium_";
const PLAN_NO_ADS = "no_ads";
const PLAN_PREMIUM = "premium";

const SUBSCRIPTION_STATE_EXPIRED = "SUBSCRIPTION_STATE_EXPIRED";
const SUBSCRIPTION_STATE_PENDING = "SUBSCRIPTION_STATE_PENDING";

const PURCHASE_STATE_PURCHASED = 0;
const PURCHASE_STATE_PENDING = 2;

const VERIFICATION_STATUS_VERIFIED = "verified";
const VERIFICATION_STATUS_PENDING = "pending";
const VERIFICATION_STATUS_FAILED = "failed";

const TABLES = {
  pendingPurchases: "pending_purchases",
  subscriptions: "subscriptions",
  users: "users",
} as const;

const COLUMNS = {
  id: "id",
  userId: "user_id",
  productId: "product_id",
  planType: "plan_type",
  isActive: "is_active",
  startedAt: "started_at",
  expiresAt: "expires_at",
  purchaseToken: "purchase_token",
  credits: "credits",
  status: "status",
  errorMessage: "error_message",
  resolvedAt: "resolved_at",
} as const;

const PENDING_STATUS_RESOLVED = "resolved";
const PENDING_STATUS_FAILED = "failed";

const RPC_ADD_CREDITS = "add_credits";
const RPC_SPEND_CREDIT_AND_UNLOCK = "spend_credit_and_unlock";

/** Request payload sent by the mobile client. */
interface VerifyPurchaseBody {
  product_id?: unknown;
  purchase_token?: unknown;
  type?: unknown;
  platform?: unknown;
  contour_id?: unknown;
}

/**
 * Creates a JSON response with the standard CORS headers.
 */
function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

/**
 * Returns the trimmed string value or an empty string when not a string.
 */
function asString(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

/**
 * Maps a Google Play subscription product id to the stored plan type.
 */
function resolvePlanType(productId: string): string | null {
  if (productId.startsWith(NO_ADS_PREFIX)) {
    return PLAN_NO_ADS;
  }
  if (productId.startsWith(PREMIUM_PREFIX)) {
    return PLAN_PREMIUM;
  }
  return null;
}

/**
 * Parses a credits value returned by the RPC or a users row.
 */
function parseCreditsValue(value: unknown): number | null {
  if (typeof value === "number" && Number.isFinite(value)) {
    return value;
  }
  if (typeof value === "string" && value.trim() !== "") {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : null;
  }
  return null;
}

/**
 * Extracts the new credits balance from the possible RPC response shapes.
 */
function extractCreditsBalance(data: unknown): number | null {
  const direct = parseCreditsValue(data);
  if (direct != null) {
    return direct;
  }
  if (Array.isArray(data)) {
    for (const item of data) {
      const parsed = extractCreditsBalance(item);
      if (parsed != null) {
        return parsed;
      }
    }
    return null;
  }
  if (data && typeof data === "object") {
    const record = data as Record<string, unknown>;
    const keys = [
      "credits_balance",
      "balance",
      "credits",
      "new_balance",
      "add_credits",
    ];
    for (const key of keys) {
      const parsed = parseCreditsValue(record[key]);
      if (parsed != null) {
        return parsed;
      }
    }
  }
  return null;
}

/**
 * Reads the user's credits balance as a fallback when the RPC omits it.
 */
async function readCreditsBalance(
  admin: ReturnType<typeof createAdminClient>,
  userId: string,
): Promise<number | null> {
  const { data, error } = await admin
    .from(TABLES.users)
    .select(COLUMNS.credits)
    .eq(COLUMNS.id, userId)
    .maybeSingle();
  if (error) {
    console.error(
      `[verify-purchase] failed to read credits balance: ${error.message}`,
    );
    return null;
  }
  if (!data || typeof data !== "object") {
    return null;
  }
  return parseCreditsValue((data as Record<string, unknown>)[COLUMNS.credits]);
}

/**
 * Marks queued pending purchases for a verified token as resolved.
 *
 * The entitlement has already been granted when this runs, so a bookkeeping
 * failure is logged instead of failing the verification response.
 */
async function resolvePendingPurchase(
  admin: ReturnType<typeof createAdminClient>,
  userId: string,
  purchaseToken: string,
): Promise<void> {
  const { error } = await admin
    .from(TABLES.pendingPurchases)
    .update({
      [COLUMNS.status]: PENDING_STATUS_RESOLVED,
      [COLUMNS.errorMessage]: null,
      [COLUMNS.resolvedAt]: new Date().toISOString(),
    })
    .eq(COLUMNS.userId, userId)
    .eq(COLUMNS.purchaseToken, purchaseToken);
  if (error) {
    console.error(
      `[verify-purchase] failed to resolve pending purchase: ${error.message}`,
    );
  }
}

/** Marks a queued purchase as rejected so it stops blocking a new attempt. */
async function failPendingPurchase(
  admin: ReturnType<typeof createAdminClient>,
  userId: string,
  purchaseToken: string,
  reason: string,
): Promise<void> {
  const { error } = await admin
    .from(TABLES.pendingPurchases)
    .update({
      [COLUMNS.status]: PENDING_STATUS_FAILED,
      [COLUMNS.errorMessage]: reason,
      [COLUMNS.resolvedAt]: new Date().toISOString(),
    })
    .eq(COLUMNS.userId, userId)
    .eq(COLUMNS.purchaseToken, purchaseToken)
    .eq(COLUMNS.status, "pending");
  if (error) {
    console.error(
      `[verify-purchase] failed to reject pending purchase: ${error.message}`,
    );
  }
}

/**
 * Verifies a one-time credit purchase and adds credits idempotently.
 */
async function grantCredits(
  admin: ReturnType<typeof createAdminClient>,
  userId: string,
  productId: string,
  purchaseToken: string,
  contourId: string | null,
): Promise<Response> {
  const purchase = await getProduct(productId, purchaseToken);
  if (purchase.purchaseState === PURCHASE_STATE_PENDING) {
    return json({ success: true, status: VERIFICATION_STATUS_PENDING });
  }
  if (purchase.purchaseState !== PURCHASE_STATE_PURCHASED) {
    const reason = "Purchase was canceled by Google Play";
    await failPendingPurchase(admin, userId, purchaseToken, reason);
    return json({
      success: false,
      status: VERIFICATION_STATUS_FAILED,
      error: reason,
    });
  }

  const { data, error } = await admin.rpc(RPC_ADD_CREDITS, {
    p_user_id: userId,
    p_purchase_token: purchaseToken,
    p_product_id: productId,
  });
  if (error) {
    throw new Error(`Failed to add credits: ${error.message}`);
  }

  let balance = extractCreditsBalance(data);
  if (balance == null) {
    balance = await readCreditsBalance(admin, userId);
  }
  if (balance == null) {
    throw new Error("add_credits did not return a credits balance");
  }

  if (contourId != null) {
    const spent = await admin.rpc(RPC_SPEND_CREDIT_AND_UNLOCK, {
      p_user_id: userId,
      p_contour_id: contourId,
      p_purchase_token: purchaseToken,
    });
    if (spent.error) {
      throw new Error(`Failed to unlock contour: ${spent.error.message}`);
    }

    const remaining = extractCreditsBalance(spent.data);
    if (remaining != null) {
      balance = remaining;
    }
  }

  await resolvePendingPurchase(admin, userId, purchaseToken);

  return json({
    success: true,
    status: VERIFICATION_STATUS_VERIFIED,
    credits_balance: balance,
    contour_id: contourId,
  });
}

/**
 * Verifies a subscription purchase and stores or refreshes its row.
 */
async function grantSubscription(
  admin: ReturnType<typeof createAdminClient>,
  userId: string,
  productId: string,
  purchaseToken: string,
): Promise<Response> {
  const purchase = await getSubscription(purchaseToken);
  if (purchase.state === SUBSCRIPTION_STATE_PENDING) {
    return json({ success: true, status: VERIFICATION_STATUS_PENDING });
  }
  if (
    purchase.state === SUBSCRIPTION_STATE_EXPIRED ||
    purchase.expiryTimeMillis == null ||
    purchase.expiryTimeMillis <= Date.now()
  ) {
    return json({ error: "Subscription is expired" }, 400);
  }

  const actualProductId = purchase.productId ?? productId;
  const planType = resolvePlanType(actualProductId);
  if (planType == null) {
    return json({ error: "Unsupported subscription product" }, 400);
  }

  const expiresAt = new Date(purchase.expiryTimeMillis).toISOString();
  const existing = await admin
    .from(TABLES.subscriptions)
    .select(COLUMNS.id)
    .eq(COLUMNS.purchaseToken, purchaseToken)
    .maybeSingle();
  if (existing.error) {
    throw new Error(
      `Failed to look up subscription: ${existing.error.message}`,
    );
  }

  if (existing.data) {
    const { error } = await admin
      .from(TABLES.subscriptions)
      .update({
        [COLUMNS.expiresAt]: expiresAt,
        [COLUMNS.isActive]: true,
      })
      .eq(COLUMNS.purchaseToken, purchaseToken);
    if (error) {
      throw new Error(`Failed to update subscription: ${error.message}`);
    }
  } else {
    const { error } = await admin
      .from(TABLES.subscriptions)
      .insert({
        [COLUMNS.userId]: userId,
        [COLUMNS.productId]: actualProductId,
        [COLUMNS.planType]: planType,
        [COLUMNS.isActive]: true,
        [COLUMNS.startedAt]: new Date().toISOString(),
        [COLUMNS.expiresAt]: expiresAt,
        [COLUMNS.purchaseToken]: purchaseToken,
      });
    if (error) {
      throw new Error(`Failed to store subscription: ${error.message}`);
    }
  }

  await resolvePendingPurchase(admin, userId, purchaseToken);

  return json({
    success: true,
    status: VERIFICATION_STATUS_VERIFIED,
    subscription: {
      product_id: actualProductId,
      plan_type: planType,
      is_active: true,
      expires_at: expiresAt,
    },
  });
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const authorization = req.headers.get("Authorization");
  if (!authorization) {
    return json({ error: "Missing Authorization header" }, 401);
  }

  try {
    const token = authorization.replace(/^Bearer\s+/i, "");
    const userClient = createUserClient(authorization);
    const { data: { user }, error: userError } = await userClient.auth.getUser(
      token,
    );
    if (userError || !user) {
      return json({ error: "Unauthorized" }, 401);
    }

    let parsedBody: unknown;
    try {
      parsedBody = await req.json();
    } catch {
      return json({ error: "Invalid JSON body" }, 400);
    }
    if (!parsedBody || typeof parsedBody !== "object") {
      return json({ error: "Invalid request body" }, 400);
    }
    const body = parsedBody as VerifyPurchaseBody;

    const productId = asString(body.product_id);
    const purchaseToken = asString(body.purchase_token);
    const type = asString(body.type);
    const contourId = asString(body.contour_id) || null;
    if (productId === "" || purchaseToken === "") {
      return json(
        { error: "product_id and purchase_token are required" },
        400,
      );
    }
    if (type === "") {
      return json({ error: "type is required" }, 400);
    }

    const rawPlatform = body.platform;
    if (rawPlatform != null && typeof rawPlatform !== "string") {
      return json({ error: "platform must be a string" }, 400);
    }
    const platform = asString(rawPlatform) || PLATFORM_GOOGLE;
    if (platform === PLATFORM_APPLE) {
      return json({ error: "Apple verification is not implemented" }, 501);
    }
    if (platform !== PLATFORM_GOOGLE) {
      return json({ error: "Unsupported platform" }, 400);
    }

    const admin = createAdminClient();
    if (type === TYPE_CREDITS) {
      if (productId !== CREDIT_PRODUCT_ID) {
        return json({ error: "Unsupported credit product" }, 400);
      }
      return await grantCredits(
        admin,
        user.id,
        productId,
        purchaseToken,
        contourId,
      );
    }
    if (type === TYPE_SUBSCRIPTION) {
      if (resolvePlanType(productId) == null) {
        return json({ error: "Unsupported subscription product" }, 400);
      }
      return await grantSubscription(admin, user.id, productId, purchaseToken);
    }

    return json({ error: "Unsupported purchase type" }, 400);
  } catch (error) {
    if (error instanceof GooglePlayApiError) {
      console.error(
        `[verify-purchase] Google Play API error: ${error.message}`,
      );
      return json(
        { error: `Google Play verification failed (${error.status})` },
        error.status,
      );
    }

    console.error("[verify-purchase] unexpected error:", error);
    return json({ error: "Internal server error" }, 500);
  }
});
