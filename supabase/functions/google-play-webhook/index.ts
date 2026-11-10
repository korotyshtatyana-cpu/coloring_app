// Receives Google Play Real-time Developer Notifications (RTDN) through a
// Cloud Pub/Sub push subscription and reconciles refunds, voids, and
// subscription state changes.
//
// Configure the push endpoint in Google Play Console as:
//   https://<project-ref>.supabase.co/functions/v1/google-play-webhook
//     ?secret=<GOOGLE_PUBSUB_SECRET>
//
// Required environment variables:
//   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
//   GOOGLE_SERVICE_ACCOUNT_JSON, GOOGLE_PLAY_PACKAGE_NAME
//   GOOGLE_PUBSUB_SECRET
//
// Deploy with:
//   supabase functions deploy google-play-webhook --no-verify-jwt

import { decodeBase64 } from "https://deno.land/std@0.224.0/encoding/base64.ts";
import {
  assertGooglePlayConfig,
  getSubscription,
  requireEnv,
} from "../_shared/google_play_auth.ts";
import { corsHeaders, createAdminClient } from "../_shared/supabase.ts";

assertGooglePlayConfig();

const GOOGLE_PUBSUB_SECRET = requireEnv("GOOGLE_PUBSUB_SECRET");

const SUBSCRIPTION_RENEWED = 2;
const SUBSCRIPTION_CANCELED = 3;
const SUBSCRIPTION_PURCHASED = 4;
const SUBSCRIPTION_RESTARTED = 7;
const SUBSCRIPTION_REVOKED = 12;
const SUBSCRIPTION_EXPIRED = 13;

const ONE_TIME_PRODUCT_CANCELED = 2;

const SUBSCRIPTION_STATE_EXPIRED = "SUBSCRIPTION_STATE_EXPIRED";
const CREDIT_PRODUCT_ID = "unlock_credit";
const REFUNDED_PRODUCT_PREFIX = "refunded:";
const UNKNOWN_PRODUCT_ID = "project";

const TABLES = {
  processedPurchases: "processed_purchases",
  purchaseRefunds: "purchase_refunds",
  subscriptions: "subscriptions",
  subscriptionPurchases: "subscription_purchases",
  userEntitlements: "user_entitlements",
  users: "users",
} as const;

const COLUMNS = {
  id: "id",
  userId: "user_id",
  subscriptionId: "subscription_id",
  productId: "product_id",
  planType: "plan_type",
  basePlanId: "base_plan_id",
  purchaseToken: "purchase_token",
  orderId: "order_id",
  isAutoRenewal: "is_auto_renewal",
  isAutoRenew: "is_auto_renew",
  startedAt: "started_at",
  createdAt: "created_at",
  isActive: "is_active",
  expiresAt: "expires_at",
  credits: "credits",
} as const;

/** Pub/Sub push envelope. */
interface PubSubEnvelope {
  message?: { data?: unknown };
}

/** Decoded RTDN payload. */
interface DeveloperNotification {
  subscriptionNotification?: {
    purchaseToken?: unknown;
    subscriptionId?: unknown;
    notificationType?: unknown;
  };
  oneTimeProductNotification?: {
    purchaseToken?: unknown;
    sku?: unknown;
    notificationType?: unknown;
  };
  voidedPurchaseNotification?: {
    purchaseToken?: unknown;
    productType?: unknown;
    refundType?: unknown;
  };
  testNotification?: { version?: unknown };
}

/** Rows loaded for a purchase token before applying an RTDN action. */
interface PurchaseContext {
  processedProductId: string | null;
  processedUserId: string | null;
  entitlementUserId: string | null;
  subscriptionId: string | null;
  subscriptionUserId: string | null;
  subscriptionProductId: string | null;
}

/**
 * Creates a JSON response with CORS headers.
 */
function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

/**
 * Returns a safe identifier for logs without exposing the full token.
 */
function tokenLabel(purchaseToken: string): string {
  return purchaseToken.slice(-8);
}

/**
 * Formats an unknown error for server-side logging.
 */
function describeError(error: unknown): string {
  if (error instanceof Error) {
    return error.message;
  }
  if (error && typeof error === "object" && "message" in error) {
    const message = (error as { message?: unknown }).message;
    if (typeof message === "string") {
      return message;
    }
  }
  return String(error);
}

/**
 * Writes a prefixed webhook log line.
 */
function log(message: string): void {
  console.log(`[webhook] ${message}`);
}

/**
 * Writes a prefixed webhook error log line.
 */
function logError(message: string, error: unknown): void {
  console.error(`[webhook] ${message}: ${describeError(error)}`);
}

/**
 * Decodes and parses a base64 Pub/Sub message, returning an empty notification
 * when the payload is missing or malformed.
 */
function decodeNotification(envelope: unknown): DeveloperNotification {
  if (!envelope || typeof envelope !== "object") {
    return {};
  }
  const data = (envelope as PubSubEnvelope).message?.data;
  if (typeof data !== "string" || data === "") {
    return {};
  }

  try {
    const bytes = decodeBase64(data);
    const parsed = JSON.parse(new TextDecoder().decode(bytes)) as unknown;
    if (!parsed || typeof parsed !== "object") {
      log("decoded Pub/Sub message is not a JSON object");
      return {};
    }
    return parsed as DeveloperNotification;
  } catch {
    log("failed to decode Pub/Sub message");
    return {};
  }
}

/**
 * Reads the purchase rows associated with a token, tolerating individual
 * lookup failures so one missing table cannot block the notification.
 */
async function loadPurchaseContext(
  admin: ReturnType<typeof createAdminClient>,
  purchaseToken: string,
): Promise<PurchaseContext> {
  const [processed, entitlement, subscription] = await Promise.all([
    admin
      .from(TABLES.processedPurchases)
      .select(`${COLUMNS.userId}, ${COLUMNS.productId}`)
      .eq(COLUMNS.purchaseToken, purchaseToken)
      .maybeSingle(),
    admin
      .from(TABLES.userEntitlements)
      .select(COLUMNS.userId)
      .eq(COLUMNS.purchaseToken, purchaseToken)
      .maybeSingle(),
    admin
      .from(TABLES.subscriptions)
      .select(
        `${COLUMNS.id}, ${COLUMNS.userId}, ${COLUMNS.productId}`,
      )
      .eq(COLUMNS.purchaseToken, purchaseToken)
      .maybeSingle(),
  ]);

  if (processed.error) {
    logError("failed to load processed purchase", processed.error);
  }
  if (entitlement.error) {
    logError("failed to load entitlement", entitlement.error);
  }
  if (subscription.error) {
    logError("failed to load subscription", subscription.error);
  }

  const processedRow = processed.data as Record<string, unknown> | null;
  const entitlementRow = entitlement.data as Record<string, unknown> | null;
  const subscriptionRow = subscription.data as Record<string, unknown> | null;

  return {
    processedProductId: asNullableString(processedRow?.[COLUMNS.productId]),
    processedUserId: asNullableString(processedRow?.[COLUMNS.userId]),
    entitlementUserId: asNullableString(entitlementRow?.[COLUMNS.userId]),
    subscriptionId: asNullableString(subscriptionRow?.[COLUMNS.id]),
    subscriptionUserId: asNullableString(subscriptionRow?.[COLUMNS.userId]),
    subscriptionProductId: asNullableString(
      subscriptionRow?.[COLUMNS.productId],
    ),
  };
}

/**
 * Returns a string value or null for unknown row fields.
 */
function asNullableString(value: unknown): string | null {
  return typeof value === "string" && value !== "" ? value : null;
}

/**
 * Parses a numeric value returned by Supabase.
 */
function asNumber(value: unknown): number | null {
  if (typeof value === "number" && Number.isFinite(value)) {
    return value;
  }
  if (typeof value === "string" && value !== "") {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : null;
  }
  return null;
}

/**
 * Marks a subscription row inactive. Revoked and expired notifications use
 * this helper; a user-initiated cancellation only disables auto-renew and
 * keeps access until the paid period ends.
 */
async function setSubscriptionInactive(
  admin: ReturnType<typeof createAdminClient>,
  purchaseToken: string,
): Promise<void> {
  const { data, error } = await admin
    .from(TABLES.subscriptions)
    .update({ [COLUMNS.isActive]: false })
    .eq(COLUMNS.purchaseToken, purchaseToken)
    .select(COLUMNS.id);
  if (error) {
    logError("failed to deactivate subscription", error);
    return;
  }
  if (!Array.isArray(data) || data.length === 0) {
    log(`no subscription row for token ...${tokenLabel(purchaseToken)}`);
    return;
  }
  log(`subscription deactivated for token ...${tokenLabel(purchaseToken)}`);
}

/**
 * Updates the auto-renew flag without touching access. Cancelling a
 * subscription keeps the row active until `expires_at`; Google Play stops
 * charging at the end of the paid period.
 */
async function setSubscriptionAutoRenew(
  admin: ReturnType<typeof createAdminClient>,
  purchaseToken: string,
  isAutoRenew: boolean,
): Promise<void> {
  const { data, error } = await admin
    .from(TABLES.subscriptions)
    .update({ [COLUMNS.isAutoRenew]: isAutoRenew })
    .eq(COLUMNS.purchaseToken, purchaseToken)
    .select(COLUMNS.id);
  if (error) {
    logError("failed to update subscription auto-renew", error);
    return;
  }
  if (!Array.isArray(data) || data.length === 0) {
    log(`no subscription row for token ...${tokenLabel(purchaseToken)}`);
    return;
  }
  log(
    `subscription auto-renew set to ${isAutoRenew} for ...${
      tokenLabel(purchaseToken)
    }`,
  );
}

/**
 * Stores one paid subscription period so renewals survive the single-row
 * `subscriptions` record. Duplicate notifications for the same token and
 * expiry are ignored.
 */
async function recordSubscriptionPurchase(
  admin: ReturnType<typeof createAdminClient>,
  record: {
    userId: string;
    subscriptionId: string | null;
    purchaseToken: string;
    productId: string;
    planType: string;
    basePlanId: string | null;
    orderId: string | null;
    isAutoRenewal: boolean;
    startedAt: string;
    expiresAt: string;
  },
): Promise<void> {
  const { error } = await admin
    .from(TABLES.subscriptionPurchases)
    .upsert(
      {
        [COLUMNS.userId]: record.userId,
        [COLUMNS.subscriptionId]: record.subscriptionId,
        [COLUMNS.purchaseToken]: record.purchaseToken,
        [COLUMNS.productId]: record.productId,
        [COLUMNS.planType]: record.planType,
        [COLUMNS.basePlanId]: record.basePlanId,
        [COLUMNS.orderId]: record.orderId,
        [COLUMNS.isAutoRenewal]: record.isAutoRenewal,
        [COLUMNS.startedAt]: record.startedAt,
        [COLUMNS.expiresAt]: record.expiresAt,
      },
      {
        onConflict: `${COLUMNS.purchaseToken},${COLUMNS.expiresAt}`,
        ignoreDuplicates: true,
      },
    );
  if (error) {
    logError("failed to record subscription purchase", error);
    return;
  }
  log(
    `subscription ${record.isAutoRenewal ? "renewal" : "purchase"} recorded ` +
      `for ...${tokenLabel(record.purchaseToken)}`,
  );
}

/**
 * Refetches a subscription, updates its expiry and active flag, and records
 * the paid period. Renewals are marked as automatic.
 */
async function refreshSubscription(
  admin: ReturnType<typeof createAdminClient>,
  purchaseToken: string,
  notificationType: number,
): Promise<void> {
  const purchase = await getSubscription(purchaseToken);
  if (purchase.expiryTimeMillis == null) {
    log(
      `subscription refresh returned no expiry for ...${
        tokenLabel(purchaseToken)
      }`,
    );
    return;
  }

  const expiresAt = new Date(purchase.expiryTimeMillis).toISOString();
  const isActive = purchase.state !== SUBSCRIPTION_STATE_EXPIRED &&
    purchase.expiryTimeMillis > Date.now();
  const isAutoRenewal = notificationType === SUBSCRIPTION_RENEWED;

  const existing = await admin
    .from(TABLES.subscriptions)
    .select(
      `${COLUMNS.id}, ${COLUMNS.userId}, ${COLUMNS.productId}, ` +
        `${COLUMNS.planType}, ${COLUMNS.startedAt}, ${COLUMNS.expiresAt}`,
    )
    .eq(COLUMNS.purchaseToken, purchaseToken)
    .maybeSingle();
  if (existing.error) {
    logError("failed to load subscription before refresh", existing.error);
    return;
  }
  const existingRow = existing.data as Record<string, unknown> | null;

  const update: Record<string, unknown> = {
    [COLUMNS.expiresAt]: expiresAt,
    [COLUMNS.isActive]: isActive,
  };
  if (purchase.autoRenewing != null) {
    update[COLUMNS.isAutoRenew] = purchase.autoRenewing;
  }
  if (purchase.basePlanId != null) {
    update[COLUMNS.basePlanId] = purchase.basePlanId;
  }
  if (purchase.productId != null) {
    update[COLUMNS.productId] = purchase.productId;
  }

  const { data, error } = await admin
    .from(TABLES.subscriptions)
    .update(update)
    .eq(COLUMNS.purchaseToken, purchaseToken)
    .select(COLUMNS.id);
  if (error) {
    logError("failed to refresh subscription", error);
    return;
  }
  if (!Array.isArray(data) || data.length === 0) {
    log(`no subscription row for token ...${tokenLabel(purchaseToken)}`);
    return;
  }

  const userId = asNullableString(existingRow?.[COLUMNS.userId]);
  const productId = purchase.productId ??
    asNullableString(existingRow?.[COLUMNS.productId]);
  const planType = asNullableString(existingRow?.[COLUMNS.planType]) ??
    productId;
  if (userId != null && productId != null && planType != null) {
    const previousExpiry = asNullableString(existingRow?.[COLUMNS.expiresAt]);
    const periodStartedAt = isAutoRenewal &&
        previousExpiry != null &&
        Date.parse(previousExpiry) < purchase.expiryTimeMillis
      ? previousExpiry
      : new Date().toISOString();
    await recordSubscriptionPurchase(admin, {
      userId,
      subscriptionId: asNullableString(existingRow?.[COLUMNS.id]),
      purchaseToken,
      productId,
      planType,
      basePlanId: purchase.basePlanId,
      orderId: purchase.orderId,
      isAutoRenewal,
      startedAt: periodStartedAt,
      expiresAt,
    });
  }

  log(
    `subscription refreshed product=${purchase.productId ?? "unknown"}, ` +
      `basePlan=${purchase.basePlanId ?? "unknown"}, active=${isActive} ` +
      `for ...${tokenLabel(purchaseToken)}`,
  );
}

/**
 * Deletes the contour entitlement tied to a purchase token and returns how
 * many rows were removed, or `null` when the delete failed.
 */
async function deleteEntitlement(
  admin: ReturnType<typeof createAdminClient>,
  purchaseToken: string,
): Promise<number | null> {
  const { data, error } = await admin
    .from(TABLES.userEntitlements)
    .delete()
    .eq(COLUMNS.purchaseToken, purchaseToken)
    .select(COLUMNS.id);
  if (error) {
    logError("failed to delete entitlement", error);
    return null;
  }
  const deleted = Array.isArray(data) ? data.length : 0;
  log(
    `entitlement deleted (${deleted}) for token ...${tokenLabel(purchaseToken)}`,
  );
  return deleted;
}

/**
 * Decrements one credit for a user, never going below zero.
 */
async function decrementCredits(
  admin: ReturnType<typeof createAdminClient>,
  userId: string,
): Promise<void> {
  const { data, error } = await admin
    .from(TABLES.users)
    .select(COLUMNS.credits)
    .eq(COLUMNS.id, userId)
    .maybeSingle();
  if (error) {
    logError("failed to read credits", error);
    return;
  }

  const current = asNumber(
    (data as Record<string, unknown> | null)?.[COLUMNS.credits],
  );
  if (current == null) {
    log(`no credits balance for user ${userId}`);
    return;
  }

  const next = Math.max(0, Math.floor(current) - 1);
  const { error: updateError } = await admin
    .from(TABLES.users)
    .update({ [COLUMNS.credits]: next })
    .eq(COLUMNS.id, userId);
  if (updateError) {
    logError("failed to decrement credits", updateError);
    return;
  }
  log(`credits decremented from ${current} to ${next} for user ${userId}`);
}

/**
 * Marks a processed purchase as refunded, inserting the row when necessary.
 */
async function markPurchaseRefunded(
  admin: ReturnType<typeof createAdminClient>,
  purchaseToken: string,
  productId: string,
  userId: string | null,
): Promise<void> {
  const marker = `${REFUNDED_PRODUCT_PREFIX}${productId}`;
  const { data, error } = await admin
    .from(TABLES.processedPurchases)
    .update({ [COLUMNS.productId]: marker })
    .eq(COLUMNS.purchaseToken, purchaseToken)
    .select(COLUMNS.purchaseToken)
    .maybeSingle();
  if (error) {
    logError("failed to mark purchase refunded", error);
    return;
  }
  if (data) {
    log(`purchase marked refunded for ...${tokenLabel(purchaseToken)}`);
    return;
  }

  if (userId == null) {
    log(
      `cannot insert refund marker without user for ...${
        tokenLabel(purchaseToken)
      }`,
    );
    return;
  }

  const { error: insertError } = await admin
    .from(TABLES.processedPurchases)
    .insert({
      [COLUMNS.purchaseToken]: purchaseToken,
      [COLUMNS.userId]: userId,
      [COLUMNS.productId]: marker,
    });
  if (insertError) {
    logError("failed to insert refund marker", insertError);
    return;
  }
  log(`refund marker inserted for ...${tokenLabel(purchaseToken)}`);
}

/**
 * Stores a user-visible refund notification for a purchase token.
 *
 * The client reads unacknowledged rows and shows a message stating that the
 * funds were returned and the purchase is no longer valid. The upsert keeps a
 * repeated RTDN delivery from creating duplicate messages.
 */
async function recordRefund(
  admin: ReturnType<typeof createAdminClient>,
  userId: string,
  purchaseToken: string,
  productId: string,
): Promise<void> {
  const { error } = await admin.from(TABLES.purchaseRefunds).upsert(
    {
      [COLUMNS.userId]: userId,
      [COLUMNS.purchaseToken]: purchaseToken,
      [COLUMNS.productId]: productId,
    },
    { onConflict: COLUMNS.purchaseToken, ignoreDuplicates: true },
  );
  if (error) {
    logError("failed to record refund", error);
    return;
  }
  log(`refund recorded for ...${tokenLabel(purchaseToken)}`);
}

/**
 * Returns whether a refund notification already exists for the token.
 *
 * Google Play can deliver a voided-purchase and a one-time-cancellation
 * notification for the same transaction. The persisted refund row makes the
 * handling idempotent so the user's credit balance is not reduced twice.
 */
async function hasRecordedRefund(
  admin: ReturnType<typeof createAdminClient>,
  purchaseToken: string,
): Promise<boolean> {
  const { data, error } = await admin
    .from(TABLES.purchaseRefunds)
    .select(COLUMNS.id)
    .eq(COLUMNS.purchaseToken, purchaseToken)
    .maybeSingle();
  if (error) {
    logError("failed to check recorded refund", error);
    return false;
  }
  return data != null;
}

/**
 * Revokes everything a refunded purchase granted and records a one-time
 * notification for the client.
 *
 * Both the voided-purchase and one-time-cancellation notifications call this,
 * and Google Play may deliver both for the same token. The processed purchase
 * row is marked as refunded before any balance change, so a second delivery
 * takes the idempotent branch and never decrements the same credit twice.
 */
async function handleRefund(
  admin: ReturnType<typeof createAdminClient>,
  purchaseToken: string,
  productIdHint: string | null = null,
): Promise<void> {
  const context = await loadPurchaseContext(admin, purchaseToken);
  const processedProductId = context.processedProductId;
  const userId = context.processedUserId ?? context.entitlementUserId ??
    context.subscriptionUserId;
  const storedProductId = processedProductId ??
    context.subscriptionProductId ?? UNKNOWN_PRODUCT_ID;
  const rawProductId = productIdHint ?? storedProductId;
  // A previous notification may have marked the processed purchase; strip the
  // marker so the refund row keeps the real store product id.
  const productId = rawProductId.startsWith(REFUNDED_PRODUCT_PREFIX)
    ? rawProductId.slice(REFUNDED_PRODUCT_PREFIX.length)
    : rawProductId;

  const markerExists = processedProductId != null &&
    processedProductId.startsWith(REFUNDED_PRODUCT_PREFIX);
  if (markerExists || await hasRecordedRefund(admin, purchaseToken)) {
    // Access revoke is idempotent and must run on every delivery in case a
    // previous attempt stopped halfway. The credit balance is deliberately
    // not touched here: the first delivery already accounted for it.
    await deleteEntitlement(admin, purchaseToken);
    if (context.subscriptionId != null) {
      await setSubscriptionInactive(admin, purchaseToken);
    }
    if (userId != null) {
      await recordRefund(admin, userId, purchaseToken, productId);
    }
    log(`refund already handled for ...${tokenLabel(purchaseToken)}`);
    return;
  }

  // Mark before mutating the balance so a redelivered notification cannot
  // decrement the same unspent credit twice.
  await markPurchaseRefunded(admin, purchaseToken, productId, userId);

  // A refunded purchase must lose access regardless of its type. Credit
  // purchases used to skip this branch, so a refunded credit kept its project
  // unlocked.
  const deletedEntitlements = await deleteEntitlement(admin, purchaseToken);

  // If the refunded credit was never spent, there is no entitlement to remove;
  // take the credit itself back. When an entitlement was deleted, the credit
  // had already been spent on it and the balance is correct as is. A failed
  // delete returns null and must not touch the balance.
  if (productId === CREDIT_PRODUCT_ID && deletedEntitlements === 0) {
    if (userId == null) {
      log(
        `cannot decrement credits without user for ...${
          tokenLabel(purchaseToken)
        }`,
      );
    } else {
      await decrementCredits(admin, userId);
    }
  }

  if (context.subscriptionId != null) {
    await setSubscriptionInactive(admin, purchaseToken);
  }

  if (userId != null) {
    await recordRefund(admin, userId, purchaseToken, productId);
  }
}

/**
 * Handles a canceled one-time product purchase.
 *
 * A pending purchase that was never verified grants nothing and takes no
 * money, so it is ignored here.
 */
async function handleOneTimeCancellation(
  admin: ReturnType<typeof createAdminClient>,
  purchaseToken: string,
  sku: string | null,
): Promise<void> {
  const context = await loadPurchaseContext(admin, purchaseToken);
  const wasGranted = context.processedProductId != null ||
    context.entitlementUserId != null;
  if (!wasGranted) {
    log(
      `canceled purchase was never granted for ...${
        tokenLabel(purchaseToken)
      }`,
    );
    return;
  }

  await handleRefund(admin, purchaseToken, sku);
}

/**
 * Handles a voided purchase notification for any product type.
 */
function handleVoidedPurchase(
  admin: ReturnType<typeof createAdminClient>,
  purchaseToken: string,
): Promise<void> {
  return handleRefund(admin, purchaseToken);
}

/**
 * Applies a subscription notification to the stored subscription row.
 */
async function handleSubscriptionNotification(
  admin: ReturnType<typeof createAdminClient>,
  purchaseToken: string,
  notificationType: number,
): Promise<void> {
  switch (notificationType) {
    case SUBSCRIPTION_CANCELED:
      // The user turned off auto-renew. Access stays until `expires_at`; the
      // later `SUBSCRIPTION_EXPIRED` notification deactivates the row.
      await setSubscriptionAutoRenew(admin, purchaseToken, false);
      return;
    case SUBSCRIPTION_REVOKED:
    case SUBSCRIPTION_EXPIRED:
      await setSubscriptionInactive(admin, purchaseToken);
      return;
    case SUBSCRIPTION_RENEWED:
    case SUBSCRIPTION_PURCHASED:
    case SUBSCRIPTION_RESTARTED:
      await refreshSubscription(admin, purchaseToken, notificationType);
      return;
    default:
      log(`ignored subscription notification type ${notificationType}`);
  }
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const providedSecret = new URL(req.url).searchParams.get("secret");
  if (providedSecret !== GOOGLE_PUBSUB_SECRET) {
    return json({ error: "Forbidden" }, 403);
  }

  let envelope: PubSubEnvelope;
  try {
    envelope = await req.json() as PubSubEnvelope;
  } catch {
    log("request body is not valid JSON");
    return json({ received: true });
  }

  const notification = decodeNotification(envelope);
  if (notification.testNotification) {
    log("test notification received");
    return json({ received: true, test: true });
  }

  try {
    const admin = createAdminClient();

    const voided = notification.voidedPurchaseNotification;
    if (voided && typeof voided.purchaseToken === "string") {
      await handleVoidedPurchase(admin, voided.purchaseToken);
      return json({ received: true, action: "voided" });
    }

    const subscription = notification.subscriptionNotification;
    if (
      subscription &&
      typeof subscription.purchaseToken === "string" &&
      typeof subscription.notificationType === "number"
    ) {
      const purchaseToken = subscription.purchaseToken;
      const subscriptionId =
        typeof subscription.subscriptionId === "string"
          ? subscription.subscriptionId
          : "unknown";
      log(
        `subscription notification type ${subscription.notificationType} ` +
          `for product=${subscriptionId}, token ...${
            tokenLabel(purchaseToken)
          }`,
      );
      await handleSubscriptionNotification(
        admin,
        purchaseToken,
        subscription.notificationType,
      );
      return json({ received: true, action: "subscription" });
    }

    const oneTime = notification.oneTimeProductNotification;
    if (
      oneTime &&
      typeof oneTime.purchaseToken === "string" &&
      typeof oneTime.notificationType === "number"
    ) {
      const purchaseToken = oneTime.purchaseToken;
      if (oneTime.notificationType === ONE_TIME_PRODUCT_CANCELED) {
        const sku = typeof oneTime.sku === "string" ? oneTime.sku : null;
        await handleOneTimeCancellation(admin, purchaseToken, sku);
        return json({ received: true, action: "one_time_product" });
      }
      log(
        `ignored one-time notification type ${oneTime.notificationType} for ...${
          tokenLabel(purchaseToken)
        }`,
      );
      return json({ received: true, action: "one_time_product" });
    }

    log("notification contains no supported action");
    return json({ received: true, ignored: true });
  } catch (error) {
    logError("unhandled notification error", error);
    return json({ received: true });
  }
});
