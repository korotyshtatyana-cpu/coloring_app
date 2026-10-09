// Shared Google Play Developer API helpers for the billing Edge Functions.
//
// Authentication uses a service account stored in the
// `GOOGLE_SERVICE_ACCOUNT_JSON` secret. An OAuth2 access token is minted with
// the JWT grant flow and cached until shortly before it expires.

import { JWT } from "npm:google-auth-library@9";

const ANDROID_PUBLISHER_SCOPE =
  "https://www.googleapis.com/auth/androidpublisher";

/** Shape of the service account JSON stored in the secret. */
interface ServiceAccount {
  client_email: string;
  private_key: string;
}

/** Cached OAuth2 access token. */
let cachedToken: { value: string; expiresAt: number } | null = null;

function readServiceAccount(): ServiceAccount {
  const raw = Deno.env.get("GOOGLE_SERVICE_ACCOUNT_JSON");
  if (!raw) {
    throw new Error("GOOGLE_SERVICE_ACCOUNT_JSON is not configured");
  }
  return JSON.parse(raw) as ServiceAccount;
}

/** Returns a valid OAuth2 access token for the Android Publisher API. */
export async function getAccessToken(): Promise<string> {
  const now = Date.now();
  if (cachedToken && cachedToken.expiresAt > now + 60_000) {
    return cachedToken.value;
  }

  const account = readServiceAccount();
  const client = new JWT({
    email: account.client_email,
    key: account.private_key,
    scopes: [ANDROID_PUBLISHER_SCOPE],
  });
  const accessToken = await client.getAccessToken();
  if (!accessToken.token) {
    throw new Error("Failed to obtain a Google access token");
  }

  cachedToken = {
    value: accessToken.token,
    expiresAt: now + 50 * 60_000,
  };
  return accessToken.token;
}

/** Returns the configured Google Play package name. */
export function getPackageName(): string {
  const packageName = Deno.env.get("GOOGLE_PLAY_PACKAGE_NAME");
  if (!packageName) {
    throw new Error("GOOGLE_PLAY_PACKAGE_NAME is not configured");
  }
  return packageName;
}

/** Normalized subscription state returned by the Play API. */
export interface SubscriptionPurchase {
  /** Expiry time in epoch milliseconds, or `null` when unknown. */
  expiryTimeMillis: number | null;
  /** Raw `subscriptionState`, for example `SUBSCRIPTION_STATE_ACTIVE`. */
  state: string | null;
}

/** Fetches a subscription purchase from the Play Developer API. */
export async function getSubscription(
  packageName: string,
  token: string,
): Promise<SubscriptionPurchase> {
  const accessToken = await getAccessToken();
  const url =
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${packageName}/purchases/subscriptionsv2/tokens/${token}`;
  const response = await fetch(url, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  if (!response.ok) {
    throw new Error(
      `Google Play subscription lookup failed: ${response.status}`,
    );
  }

  const data = await response.json();
  const expiryTime: string | undefined = data.lineItems?.[0]?.expiryTime;
  return {
    expiryTimeMillis: expiryTime ? Date.parse(expiryTime) : null,
    state: data.subscriptionState ?? null,
  };
}

/** Normalized one-time product state returned by the Play API. */
export interface ProductPurchase {
  /** `0` means purchased, `1` means canceled. */
  purchaseState: number | null;
  /** Purchase time in epoch milliseconds, or `null` when unknown. */
  purchaseTimeMillis: number | null;
}

/** Fetches a one-time product purchase from the Play Developer API. */
export async function getProduct(
  packageName: string,
  productId: string,
  token: string,
): Promise<ProductPurchase> {
  const accessToken = await getAccessToken();
  const url =
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${packageName}/purchases/products/${productId}/tokens/${token}`;
  const response = await fetch(url, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  if (!response.ok) {
    throw new Error(`Google Play product lookup failed: ${response.status}`);
  }

  const data = await response.json();
  return {
    purchaseState: data.purchaseState ?? null,
    purchaseTimeMillis: data.purchaseTimeMillis
      ? Number(data.purchaseTimeMillis)
      : null,
  };
}
