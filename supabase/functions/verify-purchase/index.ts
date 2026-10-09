// Verifies a Google Play purchase and grants the matching entitlement.
//
// The caller is authenticated with a Supabase JWT; the user identifier is
// taken exclusively from the token and any client supplied `user_id` is
// ignored. Google Play verification is performed with the Android Publisher
// API using a service account stored in `GOOGLE_SERVICE_ACCOUNT_JSON`.

import {
  getPackageName,
  getProduct,
  getSubscription,
} from "../_shared/googlePlay.ts";
import {
  corsHeaders,
  createAdminClient,
  createUserClient,
} from "../_shared/supabase.ts";

const SUBSCRIPTION_PRODUCT_IDS: ReadonlySet<string> = new Set([
  "no_ads_week",
  "no_ads_month",
  "no_ads_year",
  "premium_week",
  "premium_month",
  "premium_year",
]);

const PLAN_NO_ADS = "no_ads";
const PLAN_PREMIUM = "premium";
const ENTITLEMENT_TYPE_PURCHASE = "purchase";
const PENDING_STATUS_PENDING = "pending";
const PENDING_STATUS_RESOLVED = "resolved";
const PLATFORM_GOOGLE = "google";
const PLATFORM_APPLE = "apple";
const CONTOUR_PRODUCT_ID_PREFIX = "contour_";

/** Request payload sent by the mobile client. */
interface VerifyPurchaseBody {
  product_id?: string;
  purchase_token?: string;
  type?: string;
  platform?: string;
  contour_id?: string;
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

async function resolveContourId(
  admin: ReturnType<typeof createAdminClient>,
  contourId: string | undefined,
  productId: string,
): Promise<string | null> {
  if (contourId) {
    return contourId;
  }

  const byProduct = await admin
    .from("contours")
    .select("id")
    .eq("product_id", productId)
    .maybeSingle();
  if (byProduct.data?.id) {
    return byProduct.data.id as string;
  }

  if (productId.startsWith(CONTOUR_PRODUCT_ID_PREFIX)) {
    return productId.slice(CONTOUR_PRODUCT_ID_PREFIX.length);
  }
  return null;
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
    const {
      data: { user },
      error: userError,
    } = await userClient.auth.getUser(token);
    if (userError || !user) {
      return json({ error: "Unauthorized" }, 401);
    }

    const body = (await req.json()) as VerifyPurchaseBody;
    const productId = body.product_id;
    const purchaseToken = body.purchase_token;
    const platform = body.platform ?? PLATFORM_GOOGLE;

    if (!productId || !purchaseToken) {
      return json(
        { error: "product_id and purchase_token are required" },
        400,
      );
    }

    if (platform === PLATFORM_APPLE) {
      // TODO: implement App Store verification via the App Store Server API
      // and App Store Server Notifications v2. Planned for the iOS release.
      throw new Error("Apple verification not implemented yet");
    }
    if (platform !== PLATFORM_GOOGLE) {
      return json({ error: `Unsupported platform: ${platform}` }, 400);
    }

    const admin = createAdminClient();
    const packageName = getPackageName();

    if (SUBSCRIPTION_PRODUCT_IDS.has(productId)) {
      const purchase = await getSubscription(packageName, purchaseToken);
      const planType = productId.startsWith(PLAN_NO_ADS)
        ? PLAN_NO_ADS
        : PLAN_PREMIUM;
      const expiresAt = purchase.expiryTimeMillis
        ? new Date(purchase.expiryTimeMillis)
        : null;
      const isActive = expiresAt != null && expiresAt.getTime() > Date.now();
      const nowIso = new Date().toISOString();

      const existing = await admin
        .from("subscriptions")
        .select("id")
        .eq("purchase_token", purchaseToken)
        .maybeSingle();

      if (existing.data?.id) {
        const { error } = await admin
          .from("subscriptions")
          .update({
            product_id: productId,
            plan_type: planType,
            is_active: isActive,
            expires_at: expiresAt?.toISOString() ?? nowIso,
            updated_at: nowIso,
          })
          .eq("id", existing.data.id);
        if (error) {
          throw new Error(`Failed to update subscription: ${error.message}`);
        }
      } else {
        const { error } = await admin.from("subscriptions").insert({
          user_id: user.id,
          product_id: productId,
          plan_type: planType,
          is_active: isActive,
          started_at: nowIso,
          expires_at: expiresAt?.toISOString() ?? nowIso,
          purchase_token: purchaseToken,
        });
        if (error) {
          throw new Error(`Failed to store subscription: ${error.message}`);
        }
      }
    } else {
      const purchase = await getProduct(packageName, productId, purchaseToken);
      if (purchase.purchaseState !== 0) {
        return json({ error: "Purchase is not completed" }, 409);
      }

      const contourId = await resolveContourId(
        admin,
        body.contour_id,
        productId,
      );
      if (!contourId) {
        return json({ error: "Contour not found" }, 404);
      }

      const { error } = await admin.from("user_entitlements").upsert(
        {
          user_id: user.id,
          contour_id: contourId,
          type: ENTITLEMENT_TYPE_PURCHASE,
          purchase_token: purchaseToken,
          granted_at: new Date().toISOString(),
        },
        { onConflict: "user_id,contour_id" },
      );
      if (error) {
        throw new Error(`Failed to grant entitlement: ${error.message}`);
      }
    }

    await admin
      .from("pending_purchases")
      .update({
        status: PENDING_STATUS_RESOLVED,
        resolved_at: new Date().toISOString(),
      })
      .eq("purchase_token", purchaseToken)
      .eq("status", PENDING_STATUS_PENDING);

    return json({ success: true });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    const status = message.includes("not implemented") ? 501 : 500;
    return json({ error: message }, status);
  }
});
