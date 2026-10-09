// Receives Google Play Real-time Developer Notifications (RTDN) delivered
// through a Cloud Pub/Sub push subscription and reconciles refunds, voids,
// cancellations and expirations.
//
// Configure the push endpoint in Google Play Console as:
//   https://<project-ref>.supabase.co/functions/v1/google-play-webhook?secret=<GOOGLE_PUBSUB_SECRET>

import { createAdminClient } from "../_shared/supabase.ts";

/** Pub/Sub push envelope. */
interface PubSubEnvelope {
  message?: { data?: string };
}

/** Decoded RTDN payload. */
interface DeveloperNotification {
  subscriptionNotification?: {
    purchaseToken?: string;
    subscriptionId?: string;
    notificationType?: number;
  };
  oneTimeProductNotification?: {
    purchaseToken?: string;
    sku?: string;
    notificationType?: number;
  };
  voidedPurchaseNotification?: {
    purchaseToken?: string;
    productType?: number;
    refundType?: number;
  };
  testNotification?: { version?: string };
}

const ONE_TIME_PRODUCT_CANCELED = 2;

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function decodeNotification(message: PubSubEnvelope): DeveloperNotification {
  const data = message.message?.data;
  if (!data) {
    return {};
  }
  const binary = atob(data);
  const bytes = Uint8Array.from(binary, (char) => char.charCodeAt(0));
  return JSON.parse(new TextDecoder().decode(bytes)) as DeveloperNotification;
}

/** Revokes an entitlement or subscription tied to a purchase token. */
async function revokeByToken(
  admin: ReturnType<typeof createAdminClient>,
  purchaseToken: string,
): Promise<void> {
  await admin
    .from("user_entitlements")
    .delete()
    .eq("purchase_token", purchaseToken);

  await admin
    .from("subscriptions")
    .update({ is_active: false, updated_at: new Date().toISOString() })
    .eq("purchase_token", purchaseToken);
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const configuredSecret = Deno.env.get("GOOGLE_PUBSUB_SECRET");
  const providedSecret = new URL(req.url).searchParams.get("secret");
  if (configuredSecret && providedSecret !== configuredSecret) {
    return json({ error: "Unauthorized" }, 401);
  }

  let notification: DeveloperNotification;
  try {
    notification = decodeNotification(
      (await req.json()) as PubSubEnvelope,
    );
  } catch {
    return json({ error: "Invalid notification payload" }, 400);
  }

  try {
    const admin = createAdminClient();

    if (notification.testNotification) {
      return json({ received: true, test: true });
    }

    const voided = notification.voidedPurchaseNotification;
    if (voided?.purchaseToken) {
      await revokeByToken(admin, voided.purchaseToken);
      return json({ received: true, action: "voided" });
    }

    const oneTime = notification.oneTimeProductNotification;
    if (oneTime?.purchaseToken) {
      if (oneTime.notificationType === ONE_TIME_PRODUCT_CANCELED) {
        await revokeByToken(admin, oneTime.purchaseToken);
      }
      return json({ received: true, action: "one_time_product" });
    }

    const subscription = notification.subscriptionNotification;
    if (subscription?.purchaseToken && subscription.notificationType != null) {
      // Subscription cancellation through RTDN only means auto-renew was
      // disabled; access remains until expiry, so the row is left untouched.
      // Revoked/expired are handled by the voided notification or by the next
      // verification lookup.
      return json({ received: true, action: "subscription" });
    }

    return json({ received: true, ignored: true });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    console.error("google-play-webhook failed:", message);
    return json({ error: message }, 500);
  }
});
