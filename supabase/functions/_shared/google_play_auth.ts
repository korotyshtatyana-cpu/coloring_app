// Shared Google Play Developer API authentication and purchase lookups.
//
// The OAuth2 service-account JWT grant flow is implemented with Web Crypto so
// the Edge Functions do not need a Node-only JWT library. Access tokens are
// cached in memory until shortly before they expire.
//
// Required environment variables:
//   GOOGLE_SERVICE_ACCOUNT_JSON - service account key JSON (full file content)
//   GOOGLE_PLAY_PACKAGE_NAME    - Android application id, e.g. com.example.app

import {
  decodeBase64,
  encodeBase64,
} from "https://deno.land/std@0.224.0/encoding/base64.ts";

const TOKEN_ENDPOINT = "https://oauth2.googleapis.com/token";
const ANDROID_PUBLISHER_SCOPE =
  "https://www.googleapis.com/auth/androidpublisher";
const ANDROID_PUBLISHER_BASE =
  "https://androidpublisher.googleapis.com/androidpublisher/v3/applications";
const JWT_LIFETIME_SECONDS = 3600;
// Google rejects tokens whose `iat` is even a few seconds in the future, and
// the Edge Function clock can drift slightly ahead of Google's. Backdating
// the issue time keeps the token valid on both sides.
const JWT_ISSUED_AT_SKEW_SECONDS = 60;
const TOKEN_REFRESH_MARGIN_MS = 60_000;
const DEFAULT_TOKEN_LIFETIME_SECONDS = 3600;

/** Shape of the service account JSON stored in the secret. */
interface ServiceAccount {
  client_email: string;
  private_key: string;
}

/** Cached OAuth2 access token. */
let cachedToken: { value: string; expiresAt: number } | null = null;

/**
 * Encodes bytes as unpadded base64url, as required by JWT.
 */
function base64UrlEncode(bytes: Uint8Array): string {
  return encodeBase64(bytes)
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/g, "");
}

/**
 * Converts a PEM encoded PKCS#8 private key into raw bytes.
 */
function pemToPkcs8(pem: string): Uint8Array {
  const base64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/g, "")
    .replace(/-----END PRIVATE KEY-----/g, "")
    .replace(/\s+/g, "");
  if (base64.length === 0) {
    throw new Error("GOOGLE_SERVICE_ACCOUNT_JSON has an empty private_key");
  }

  try {
    return decodeBase64(base64);
  } catch {
    throw new Error(
      "GOOGLE_SERVICE_ACCOUNT_JSON private_key is not valid base64",
    );
  }
}

/**
 * Reads a required environment variable and throws a clear error when missing.
 */
export function requireEnv(name: string): string {
  const value = Deno.env.get(name);
  if (!value) {
    throw new Error(`${name} is not configured`);
  }
  return value;
}

/**
 * Returns the configured Google Play package name.
 */
export function getPackageName(): string {
  return requireEnv("GOOGLE_PLAY_PACKAGE_NAME");
}

/**
 * Parses and validates the service account JSON stored in the environment.
 */
function readServiceAccount(): ServiceAccount {
  const raw = requireEnv("GOOGLE_SERVICE_ACCOUNT_JSON");
  let parsed: unknown;
  try {
    parsed = JSON.parse(raw);
  } catch {
    throw new Error("GOOGLE_SERVICE_ACCOUNT_JSON is not valid JSON");
  }

  if (!parsed || typeof parsed !== "object") {
    throw new Error("GOOGLE_SERVICE_ACCOUNT_JSON must be a JSON object");
  }
  const account = parsed as Record<string, unknown>;
  if (typeof account.client_email !== "string" || account.client_email === "") {
    throw new Error("GOOGLE_SERVICE_ACCOUNT_JSON is missing client_email");
  }
  if (typeof account.private_key !== "string" || account.private_key === "") {
    throw new Error("GOOGLE_SERVICE_ACCOUNT_JSON is missing private_key");
  }

  return {
    client_email: account.client_email,
    private_key: account.private_key,
  };
}

/**
 * Fails fast at startup when Google Play configuration is incomplete.
 */
export function assertGooglePlayConfig(): void {
  readServiceAccount();
  getPackageName();
}

/**
 * Creates a signed RS256 JWT for the Google OAuth2 token endpoint.
 */
async function createSignedJwt(account: ServiceAccount): Promise<string> {
  const issuedAt =
    Math.floor(Date.now() / 1000) - JWT_ISSUED_AT_SKEW_SECONDS;
  const header = { alg: "RS256", typ: "JWT" };
  const claims = {
    iss: account.client_email,
    scope: ANDROID_PUBLISHER_SCOPE,
    aud: TOKEN_ENDPOINT,
    iat: issuedAt,
    exp: issuedAt + JWT_LIFETIME_SECONDS,
  };
  const encoder = new TextEncoder();
  const signingInput = `${
    base64UrlEncode(encoder.encode(JSON.stringify(header)))
  }.${base64UrlEncode(encoder.encode(JSON.stringify(claims)))}`;

  const keyData = pemToPkcs8(account.private_key);
  const key = await crypto.subtle.importKey(
    "pkcs8",
    keyData.buffer as ArrayBuffer,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    encoder.encode(signingInput),
  );

  return `${signingInput}.${base64UrlEncode(new Uint8Array(signature))}`;
}

/**
 * Returns a valid OAuth2 access token, reusing the cached token when possible.
 */
export async function getAccessToken(): Promise<string> {
  const now = Date.now();
  if (
    cachedToken != null &&
    cachedToken.expiresAt - TOKEN_REFRESH_MARGIN_MS > now
  ) {
    return cachedToken.value;
  }

  const account = readServiceAccount();
  const assertion = await createSignedJwt(account);
  const response = await fetch(TOKEN_ENDPOINT, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });

  if (!response.ok) {
    throw new Error(`Google OAuth token request failed: ${response.status}`);
  }

  const payload = await response.json() as {
    access_token?: unknown;
    expires_in?: unknown;
  };
  if (typeof payload.access_token !== "string" || payload.access_token === "") {
    throw new Error(
      "Google OAuth token response did not include an access token",
    );
  }

  const lifetime = typeof payload.expires_in === "number"
    ? payload.expires_in
    : DEFAULT_TOKEN_LIFETIME_SECONDS;
  cachedToken = {
    value: payload.access_token,
    expiresAt: now + lifetime * 1000,
  };
  return payload.access_token;
}

/**
 * Error raised when the Android Publisher API returns a non-success status.
 */
export class GooglePlayApiError extends Error {
  /** HTTP status returned by the Android Publisher API. */
  readonly status: number;

  /**
   * Creates an error with the upstream HTTP status.
   */
  constructor(status: number, message: string) {
    super(message);
    this.name = "GooglePlayApiError";
    this.status = status;
  }
}

/**
 * Calls an Android Publisher API path and returns the parsed JSON response.
 */
async function fetchGooglePlay<T>(path: string): Promise<T> {
  const accessToken = await getAccessToken();
  const response = await fetch(`${ANDROID_PUBLISHER_BASE}${path}`, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });

  if (!response.ok) {
    let detail = "";
    try {
      const body = await response.json() as {
        error?: { message?: unknown };
      };
      if (
        typeof body.error?.message === "string" && body.error.message !== ""
      ) {
        detail = `: ${body.error.message}`;
      }
    } catch {
      // The error body is not JSON; the status is enough for the caller.
    }
    throw new GooglePlayApiError(
      response.status,
      `Google Play API request failed (${response.status})${detail}`,
    );
  }

  return await response.json() as T;
}

/**
 * Builds an application-scoped Android Publisher API path.
 */
function appPath(suffix: string): string {
  return `/${encodeURIComponent(getPackageName())}${suffix}`;
}

/**
 * Converts a numeric API field that may arrive as a string.
 */
function toNumberOrNull(value: unknown): number | null {
  if (typeof value === "number" && Number.isFinite(value)) {
    return value;
  }
  if (typeof value === "string" && value !== "") {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : null;
  }
  return null;
}

/** Normalized one-time product purchase returned by the Play API. */
export interface ProductPurchase {
  /** `0` means purchased; any other value means not completed. */
  purchaseState: number | null;
  /** Purchase time in epoch milliseconds, or `null` when unknown. */
  purchaseTimeMillis: number | null;
}

/** Raw `purchases.products.get` response fields used by this module. */
interface ProductPurchaseResponse {
  purchaseState?: unknown;
  purchaseTimeMillis?: unknown;
}

/**
 * Fetches a one-time product purchase from the Android Publisher API.
 */
export async function getProduct(
  productId: string,
  purchaseToken: string,
): Promise<ProductPurchase> {
  const data = await fetchGooglePlay<ProductPurchaseResponse>(
    appPath(
      `/purchases/products/${encodeURIComponent(productId)}/tokens/${
        encodeURIComponent(purchaseToken)
      }`,
    ),
  );

  return {
    purchaseState: toNumberOrNull(data.purchaseState),
    purchaseTimeMillis: toNumberOrNull(data.purchaseTimeMillis),
  };
}

/** Normalized subscription purchase returned by the Play API. */
export interface SubscriptionPurchase {
  /** Expiry time in epoch milliseconds, or `null` when unknown. */
  expiryTimeMillis: number | null;
  /** Raw payment state, for example `1` for received. */
  paymentState: string | number | null;
  /** Product id from the first line item, when present. */
  productId: string | null;
  /** Base plan id from the first line item, when present. */
  basePlanId: string | null;
  /** Latest order id, when present. */
  orderId: string | null;
  /** Whether Google Play will renew the subscription automatically. */
  autoRenewing: boolean | null;
  /** Raw subscription state, for example `SUBSCRIPTION_STATE_ACTIVE`. */
  state: string | null;
}

/** Raw `purchases.subscriptionsv2.get` response fields used here. */
interface SubscriptionPurchaseResponse {
  subscriptionState?: unknown;
  paymentState?: unknown;
  latestOrderId?: unknown;
  lineItems?: Array<{
    productId?: unknown;
    expiryTime?: unknown;
    offerDetails?: { basePlanId?: unknown };
    autoRenewingPlan?: { autoRenewEnabled?: unknown };
  }>;
}

/**
 * Fetches a subscription purchase from the Android Publisher API.
 */
export async function getSubscription(
  purchaseToken: string,
): Promise<SubscriptionPurchase> {
  const data = await fetchGooglePlay<SubscriptionPurchaseResponse>(
    appPath(
      `/purchases/subscriptionsv2/tokens/${encodeURIComponent(purchaseToken)}`,
    ),
  );
  const lineItem = Array.isArray(data.lineItems)
    ? data.lineItems[0]
    : undefined;
  const expiryTimeMillis = typeof lineItem?.expiryTime === "string"
    ? Date.parse(lineItem.expiryTime)
    : NaN;

  return {
    expiryTimeMillis: Number.isFinite(expiryTimeMillis)
      ? expiryTimeMillis
      : null,
    paymentState: typeof data.paymentState === "string" ||
        typeof data.paymentState === "number"
      ? data.paymentState
      : null,
    productId: typeof lineItem?.productId === "string"
      ? lineItem.productId
      : null,
    basePlanId: typeof lineItem?.offerDetails?.basePlanId === "string"
      ? lineItem.offerDetails.basePlanId
      : null,
    orderId: typeof data.latestOrderId === "string" ? data.latestOrderId : null,
    autoRenewing: typeof lineItem?.autoRenewingPlan?.autoRenewEnabled === "boolean"
      ? lineItem.autoRenewingPlan.autoRenewEnabled
      : null,
    state: typeof data.subscriptionState === "string"
      ? data.subscriptionState
      : null,
  };
}
