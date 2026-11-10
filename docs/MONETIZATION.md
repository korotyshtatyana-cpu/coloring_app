# Monetization Specification

## Overview

The app uses a hybrid monetization model:
- **Free projects** — no ads, no payment
- **Rewarded projects** — open after watching a Rewarded Video
- **Paid projects** — open after individual purchase OR active Premium subscription

Two subscription plans are available:
- **No Ads** — removes all ads from the app
- **Premium** — removes ads AND unlocks all paid projects

**Requirement:** The app requires an active internet connection. There is no offline mode.

---

## 1. Project Access Types

### Enum: `contour_access_type`

| Value | Description |
|-------|-------------|
| `free` | Available to everyone, no ads |
| `rewarded` | Requires watching a Rewarded Video |
| `paid` | Requires individual purchase OR Premium subscription |

### Database

```sql
CREATE TYPE contour_access_type AS ENUM ('free', 'rewarded', 'paid');

ALTER TABLE public.contours
  ADD COLUMN access_type contour_access_type NOT NULL DEFAULT 'free',
  ADD COLUMN price integer; -- price in cents, for paid projects only
```

### Access Badge on Gallery Cards

The access badge sits in the **top-right corner** of a gallery card; the
favorite star remains in the **bottom-right** corner. The badge is shown only
while a project is locked or view-only — unlocked and free projects have no
badge.

| Project type | No subscription | No Ads | Premium |
|--------------|-----------------|--------|---------|
| `free` | no badge | no badge | no badge |
| `rewarded` | purple badge + white `rewarded.svg` (play) | no badge | no badge |
| `paid` | gold badge + black `paid.svg` (crown) | gold badge + crown | no badge |
| `paid` with progress | neutral badge + eye icon (`viewOnly`) | neutral + eye | no badge |

Badge colors use `colors.averagePurple` (`#7B35CA`) for rewarded and
`colors.premiumGold` (`#FFD700`) for paid. The SVG assets are bundled by
`core_ui` (`core_ui/resources/icons/`).

---

## 2. Subscription Plans

### Two Products × Three Base Plans (Google Play Billing)

Google Play's modern subscription model uses one **product** per plan and a
**base plan** for each billing period. The app queries only two product ids:

| Product | Base plans | Purpose |
|---------|------------|---------|
| `no_ads` | `week` / `month` / `year` | Removes all ads |
| `premium` | `week` / `month` / `year` | Removes ads AND unlocks all paid projects |

Prices are configured in Play Console for each base plan:

| Plan | Week | Month | Year |
|------|------|-------|------|
| `no_ads` | 99 ₽ | 249 ₽ | 1990 ₽ |
| `premium` | 149 ₽ | 399 ₽ | 2990 ₽ |

The client resolves the selected period at runtime from
`ProductDetails.subscriptionOfferDetails` (matching `basePlanId`) and passes
that entry's `offerToken` to the purchase call.

When the user already has an active subscription, the purchase is started as a
plan change: the client reads the current purchases from the store and passes
the existing transaction through `ChangeSubscriptionParam`. Changing to a
different subscription product (No Ads → Premium) uses
`ReplacementMode.withTimeProration`, so the replacement takes effect
immediately and unused time is credited. Changing only the base plan inside the
same product leaves the replacement mode to the Play Console configuration.
Re-selecting the exact plan that is already active re-verifies the owned
transaction instead of asking Google Play to replace a subscription with
itself. Verification stores
`subscriptions.product_id` as the plan-level id (`no_ads` / `premium`),
`subscriptions.plan_type` as the same value, `subscriptions.base_plan_id` as
the period (`week` / `month` / `year`) and `expires_at` from the Google Play
API response (`lineItems[0].expiryTime`).

Each paid period — the initial purchase, a restore, or an automatic renewal —
is also appended to `subscription_purchases`, keyed idempotently by
`(purchase_token, expires_at)`. The history screen reads that table, so a
renewal does not overwrite the previous period even though `subscriptions`
keeps a single row per token.

### Individual Project Purchase

- Price stored in `contours.price` (in cents).
- After purchase → project is **permanently unlocked** for this user.
- Independent of subscription status.

---

## 3. Access Logic

### `ProjectAccessCalculator.calculate`

| Scenario | Result |
|----------|--------|
| Project is `free` | ✅ Unlocked |
| Project purchased individually | ✅ Unlocked (forever) |
| Project is `rewarded` + any active subscription | ✅ Unlocked |
| Project is `rewarded` + `no_ads` purchased | ✅ Unlocked |
| Project is `rewarded` + active `rewarded_unlock` entitlement | ✅ Unlocked while the entitlement is active |
| Project is `rewarded` + no subscription | 🔒 Locked (watch ad required) |
| Project is `paid` + Premium active | ✅ Unlocked |
| Project is `paid` + only `no_ads` | 🔒 Locked |
| Project is `paid` + no subscription | 🔒 Locked |
| Project is `paid` + no Premium (with saved progress) | 👁 View-only |

`ProjectAccessCalculator` also honours an active `rewarded_unlock`
entitlement, but the client does not grant one after watching an ad today, so
rewarded projects keep asking for a video on every open.

### When Subscription Expires

**For `paid` projects:**
- With saved strokes (`in progress`) → **View-only** (can view, cannot edit)
- Without strokes → **Locked** (fully blocked)

**For `rewarded` projects:**
- Require watching an ad again

**For individually purchased projects:**
- Remain **Unlocked forever**

### When Subscription is Renewed

- With a renewed **Premium** subscription, all `view-only` paid projects become
  `Unlocked`.
- No user action required — checked on project open.

---

## 4. Rewarded Video (Yandex Mobile Ads)

### Behavior

- User taps on a locked `rewarded` project → the gallery shows an ad-loading
  overlay and opens Rewarded Video.
- **Shown EVERY time** access resolves to locked (no cooldown; the client does
  not save a rewarded entitlement).
- **Watched to the end** (`RewardedAdOutcome.completed`) → the project opens.
- **Closed early** (`RewardedAdOutcome.dismissed`) → the project stays locked
  and **no dialog is shown**; tapping the project again retries the ad.
- **No ad can be shown** (`RewardedAdOutcome.unavailable`: SDK not ready,
  offline, no fill, 10-second load timeout) → the localized
  `rewarded_ad_unavailable` dialog is shown with a Retry action.

### Implementation

- The app depends on the `AdService` abstraction; `YandexAdService` is the only
  class that talks to the SDK. Other platforms use `StubAdService`, which makes
  every rewarded attempt return `unavailable` and renders no banner.
- The SDK is initialized in `DataDI._initAds` (called from `main_common.dart`).
  Initialization is retry-safe: a failed attempt can be triggered again by the
  next ad request.
- A rewarded ad is preloaded after initialization and after every impression.
  `showRewardedAd` waits at most `AdConstants.loadTimeout` (10 s) for a load.
- The service calls `setAdEventListener` **before** `show()`. Without it the
  Yandex plugin cannot report the reward, and every impression would look
  skipped.
- Missing `YANDEX_ADS_REWARDED_UNIT_ID` / `YANDEX_ADS_BANNER_UNIT_ID` disables
  the corresponding format for that build and logs a warning.

### Package

- **Official Yandex package only:** `yandex_mobileads` (currently
  `yandex_mobileads 7.18.0`; declared as `^7.0.0` in `data/pubspec.yaml`).

---

## 5. Banner in Gallery

- **Sticky ad banner** at the bottom of the Gallery screen, wrapped in
  `SafeArea` (Yandex Mobile Ads `BannerAd` in `YandexBannerAdView`).
- **Shown** when there is no active subscription (`no_ads` or `premium`) and
  the user does not own the permanent No Ads purchase (`no_ads_purchased`).
- **Not shown** to subscribers, on unsupported platforms (`StubAdService`), or
  when `YANDEX_ADS_BANNER_UNIT_ID` is empty.
- The banner is recreated when the screen width changes (rotation).
- A load failure is logged as
  `[Monetization] Banner ad failed: error={message}`; the UI simply collapses.
- `free` projects are always available without ads (the banner does not affect
  them).

---

## 6. Subscription Screen

### Structure (top to bottom)

**1. Header**
- Title: "Subscription"

**2. Current Status**
- If no subscription: "You don't have an active subscription."
- If active: plan name + expiration date/time. The same block is used for
  `no_ads` and `premium`.

**3. Stale Pending Notice**
- Shown when a subscription `pending_purchases` row older than 24 hours
  (`Constants.stalePendingPurchaseThreshold`) is not superseded by a newer
  successful subscription. A successful re-purchase hides the notice
  automatically, and it stays hidden after that subscription expires. Text
  explains that subscription setup failed and asks the user to contact support
  with a problem description, with a button that opens the feedback form.

**4. Plans — Two Blocks**

**Block "No Ads"** (purple accent)
- Description: "Removes all ads from the app. All `rewarded` projects open without watching videos."
- Segmented control: Week / Month / Year
- Localized store price for the selected base plan
- Button: "Subscribe"

**Block "Premium"** (gold accent, badge "Best Value")
- Description: "Full access to all projects in the app and complete ad removal."
- Segmented control: Week / Month / Year
- Localized store price for the selected base plan
- Button: "Subscribe"

**5. Restore Purchases Button**
- With hint: "If you already purchased a subscription, tap to restore access on this device."
- Disabled while a purchase or restore is in progress.

**6. Purchase and Subscription History**
- `PurchaseHistorySection` lists resolved `pending_purchases` rows, one-time
  project purchases from `user_entitlements` (`type = 'purchase'`), and every
  paid subscription period from `subscription_purchases` (most recent first).
  Entries are deduplicated by purchase token; a stored subscription period is
  authoritative over the generic `subscriptions` row and a resolved pending
  row for the same token.
- Subscription rows show the localized plan name, the billing interval
  (`Неделя` / `Месяц` / `Год`), and an `Автообновление` badge for periods paid
  automatically by the store (`is_auto_renewal = true`).
- Project rows show the contour title and a preview thumbnail when available.
  Every row shows the resolution/grant date (no amount).
- If empty: "History is empty."

**7. Footer**
- Link: "Terms of Service"
- Link: "Privacy Policy"

### Purchase Result Dialogs

The screen listens to `purchaseUpdates` and shows a dialog for the outcome:

| Update status | Dialog |
|---------------|--------|
| `success` | `purchase_success_title` + `purchase_success_text` (or `purchase_restore_success` for a restore) |
| `pending` | `purchase_processing_title` + `purchase_processing_text` |
| `failed` | `purchase_failed_title` + `purchase_failed_text` |
| `empty` (restore, nothing found) | `purchase_restore_button` + `purchase_restore_empty` |
| `canceled` | no dialog |

Load failures show the generic `something_went_wrong` dialog with a Retry
action.

---

## 7. Subscription Status in Profile

### Avatar Frame

The avatar frame color reflects subscription status:
- **Gray** — no subscription
- **Purple with "AD" letters** — `no_ads` active or the permanent
  `no_ads_purchased` flag is set
- **Gold with crown** (`Icons.workspace_premium`) — `premium` active

### Profile Text

- Line "Status" (`profile_status`):
  - active plan → plan name + expiration date;
  - permanent `no_ads_purchased` without an active subscription → No Ads title;
  - otherwise → "Subscription inactive".

### Timestamps

Monetization timestamps (`subscriptions`, `pending_purchases`,
`user_entitlements`, `subscription_purchases`) are stored as `timestamptz` in
UTC. The app parses them as UTC (`parseServerTimestamp`) and converts to the
device timezone only when rendering the expiry or a history date. Changing the
phone timezone therefore never changes the stored moment, only its display.

---

## 8. Errors and Recovery

### No Internet

The app requires an active connection for opening projects, watching rewarded
videos, purchases, subscription status and syncing projects.

There is **no dedicated offline detection or "No internet" dialog** in the
current code. Network failures surface as generic localized errors with a
Retry action:
- gallery load failure → `something_went_wrong` dialog;
- subscription screen load failure → `something_went_wrong` dialog;
- rewarded ad without network → `rewarded_ad_unavailable` dialog.

`error_no_internet_title` / `error_no_internet_text` exist in the locale files
but are not used yet.

### Pending Purchases

Sometimes Google Play Billing does not confirm a purchase immediately
(network hiccup, Google server delay). To avoid losing the purchase:

1. The client saves the transaction to the `pending_purchases` table together
   with the `contour_id` it unlocks (for project and credit purchases).
2. The purchase dialog stays open and switches to the processing state:
   "Payment is processing. We'll check it in a moment." The buy button is
   replaced with a tappable "Payment Processing" button.
3. Pressing that button re-checks the queued transaction with the store
   (`verify-purchase`). If the payment is still pending, an inline message next
   to the button asks the user to check again later; once the store confirms
   it, the dialog closes, the project unlocks and a success snackbar is shown. If Google Play reports
   the payment as canceled, the row becomes `failed`, the buy button returns,
   and the user sees a cancellation message.
4. Reopening the purchase dialog for the same project while the row is still
   `pending` shows the same processing state, so the purchase is not offered
   twice.
5. Unfinished store transactions are re-delivered by Google Play on a later
   app launch; the repository is subscribed to `purchaseStream` before billing
   initialization for this reason. The stored `contour_id` is used when a
   restored transaction no longer knows which project it was bought for. The
   server marks the row as `resolved` after successful verification (or
   `failed`). `GalleryScreen` also listens for non-restore project purchase
   updates, so a delayed confirmation refreshes access and shows the success
   snackbar even when the purchase dialog is no longer open.
6. Rows older than 24 hours trigger the stale-pending notice on the
   subscription screen, asking the user to contact support. The notice is not
   shown for a pending row that predates any successful subscription period:
   a successful re-purchase supersedes the earlier failed attempt, and the
   notice does not return when that subscription later expires.

The client does not independently poll `pending_purchases` rows.

### Purchase Refund

- Google Play webhook → Supabase Edge Function → remove record from `user_entitlements`.
- Access to project is revoked **immediately**.
- The webhook also inserts a row into `purchase_refunds` (one per purchase
  token). The app is notified in real time and tells the user that the funds
  were returned and the purchase is no longer valid; see
  "Refund handling (client-side)" below.
- Credit purchases always lose their entitlement on refund. Only a credit that
  was never spent is taken back from the balance, so the balance is not reduced
  twice.

### Refund handling (client-side)

The `purchase_refunds` table is the client's source of truth for refunds.

- **Detection.** `RefundMonitor` (data service, Supabase Realtime) subscribes
  to inserts on `purchase_refunds` filtered by the current user and reaches the
  app within seconds. The table must be part of the Supabase Realtime
  publication. The channel resubscribes automatically after a drop, and every
  event is deduplicated by id.
- **Fallback.** `getUnacknowledgedRefunds` (app resume via the observer, and
  `LoadMonetizationStatus` in the gallery, including pull-to-refresh) feeds
  the same deduplicated stream, so a refund discovered by polling instead of
  Realtime is delivered exactly once.
- **Pipeline.** `MonetizationRepository.watchRefunds(userId)` maps every
  refund to an entity, resolves the contour the purchase unlocked (from the
  product id for project purchases, best-effort from the purchase history for
  credit refunds), invalidates `SubscriptionCache`, and logs the event.
- **Dialog.** The session-scoped `RefundObserver` (wraps `MaterialApp.router`)
  owns the single `RefundDialog`: refunds arriving within
  `Constants.refundDialogMergeWindow` are merged into one dialog, the dialog
  cannot be dismissed without pressing OK, and dismissal acknowledges every
  shown refund (`acknowledged_at`) so it is not shown again. A contour preview
  is shown when the affected contour was resolved.
- **Access re-resolution.** `GalleryBloc` and `CanvasBloc` subscribe to the
  same stream. The gallery reloads monetization status, so the affected card
  flips to locked/view-only immediately. The canvas re-resolves access to the
  open contour through `GetGalleryItemsUseCase`; when the unlock is gone it
  dispatches `MarkCurrentContourAsViewOnly`, which discards the in-flight
  stroke, disables every editing action and shows the reason banner at the
  top; pan/zoom and sharing stay available. Editing a different contour is
  unaffected because its access still resolves as unlocked.

---

## 9. Database Schema (additions)

```sql
-- 1. Enum for access type
CREATE TYPE contour_access_type AS ENUM ('free', 'rewarded', 'paid');

-- 2. Fields in contours
ALTER TABLE public.contours
  ADD COLUMN access_type contour_access_type NOT NULL DEFAULT 'free',
  ADD COLUMN price integer; -- in cents, for paid projects only

-- 3. Field in users
ALTER TABLE public.users
  ADD COLUMN no_ads_purchased boolean DEFAULT false;

-- 4. Subscriptions table
CREATE TABLE public.subscriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  product_id text NOT NULL,
  plan_type text NOT NULL,
  base_plan_id text, -- billing period: week / month / year
  is_active boolean DEFAULT true,
  is_auto_renew boolean NOT NULL DEFAULT true, -- false after user-initiated cancellation
  started_at timestamptz DEFAULT now(),
  expires_at timestamptz NOT NULL,
  purchase_token text,
  created_at timestamptz DEFAULT now()
);

-- 5. One row per paid subscription period (initial purchase or renewal)
CREATE TABLE public.subscription_purchases (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  subscription_id uuid REFERENCES public.subscriptions(id) ON DELETE SET NULL,
  purchase_token text NOT NULL,
  product_id text NOT NULL,
  plan_type text NOT NULL,
  base_plan_id text,
  order_id text,
  is_auto_renewal boolean NOT NULL DEFAULT false,
  started_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Google Play can repeat a notification; the same period must not be listed twice.
CREATE UNIQUE INDEX subscription_purchases_token_expiry_key
  ON public.subscription_purchases (purchase_token, expires_at);

-- 6. User entitlements to projects
CREATE TABLE public.user_entitlements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  contour_id uuid NOT NULL REFERENCES public.contours(id) ON DELETE CASCADE,
  type text NOT NULL,
  granted_at timestamptz DEFAULT now(),
  expires_at timestamptz,
  UNIQUE(user_id, contour_id)
);

-- 7. Pending purchases queue
CREATE TABLE public.pending_purchases (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  product_id text NOT NULL,
  purchase_token text,
  contour_id uuid REFERENCES public.contours(id) ON DELETE SET NULL,
  status text DEFAULT 'pending',
  error_message text,
  created_at timestamptz DEFAULT now(),
  resolved_at timestamptz
);
```

The `subscriptions.base_plan_id` column and the `subscription_purchases`
table are created by
`supabase/migrations/20261110000000_subscription_purchases.sql`. The migration
also backfills one period per existing subscription (`is_auto_renewal = false`,
`base_plan_id` unknown) and adds the `select` RLS policy for
`subscription_purchases`. The related timestamp columns were converted from
`timestamp without time zone` to `timestamptz` by
`supabase/migrations/20261110000001_utc_monetization_timestamps.sql`, keeping
their existing UTC values. The auto-renew flag was added by
`supabase/migrations/20261110000002_subscription_auto_renew.sql`; it is
independent from `is_active`, so a cancelled subscription keeps access until
`expires_at`.

## 10. Google Play Billing Setup

### Step 1. Create Subscription Products
1. Play Console → Monetization → Products → Subscriptions
2. Create product `no_ads` with three base plans:
    - `week` — 99 ₽
    - `month` — 249 ₽
    - `year` — 1990 ₽
3. Create product `premium` with three base plans:
    - `week` — 149 ₽
    - `month` — 399 ₽
    - `year` — 2990 ₽
4. Activate every base plan. The client queries only `['no_ads', 'premium']`
   and resolves the selected `basePlanId` from `subscriptionOfferDetails`.
5. Old per-period products (`no_ads_week`, `no_ads_month`, …) are archived and
   no longer queried.

### Step 2. Create In-App Products (Paid Projects)
1. Play Console → Monetization → Products → In-app products
2. For each paid contour, create a one-time product
   with ID = `contours.product_id` (fallback: `contour_{id}`)
3. Price = `contours.price` (in cents)

### Step 3. Install Package

- `in_app_purchase: ^3.2.0` (official Flutter package).
- `in_app_purchase_android: ^0.5.3` for `GooglePlayPurchaseParam` and
  `subscriptionOfferDetails`.

### Step 4. Configure Webhooks (for Refunds)

1. Supabase → **Edge Functions** → create `google-play-webhook`.
2. Google Play Console → **Settings** → **Purchase notifications** → webhook URL.

---

## 11. Yandex Mobile Ads Setup

### Step 1. Registration

1. Go to [Yandex Mobile Ads](https://yandex.ru/dev/mobile-ads/).
2. Create developer account.
3. Register the app.

### Step 2. Create Ad Units

1. Create **Rewarded Video** unit (for `rewarded` projects).
2. Create **Banner** unit (for gallery).
3. Copy **Ad Unit IDs** into `.env.dev` / `.env.prod`:
   - `YANDEX_ADS_REWARDED_UNIT_ID`
   - `YANDEX_ADS_BANNER_UNIT_ID`

`AppConfig` reads both values through `dotenv`. Empty values disable the
corresponding format and log a warning at startup.

### Step 3. Install Package

- `yandex_mobileads: ^7.0.0` in `data/pubspec.yaml` (official Flutter plugin,
  currently resolved to 7.18.0).
- Android permissions come from the plugin manifests; `INTERNET` is merged
  automatically.
- The advertising ID permission (`com.google.android.gms.permission.AD_ID`) is
  declared in `android/app/src/main/AndroidManifest.xml`; the SDK can use GAID
  for more relevant ads. Personalized ads still require a user-consent flow
  before `MobileAds.setUserConsent(true)` (tracked as a TODO in
  `yandex_ad_service.dart`; ads are effectively non-personalized today).
- Keep the Yandex rules in `android/app/proguard-rules.pro`
  (`-keep class com.yandex.mobile.ads.** { *; }`); release builds enable R8 and
  would otherwise strip the SDK.
- Debug builds call `MobileAds.setLogging(kDebugMode)`.

### Step 4. Initialize in Code

- `DataDI._initAds` (invoked from `main_common.dart` through
  `DataDI.initDependencies`) awaits `AdService.initialize()`.
- `YandexAdService.initialize()` wraps `MobileAds.initialize()` in a shared
  future; a failed initialization is cleared so a later call can retry.
- Rewarded ads are preloaded after initialization and after each impression,
  so the unlock flow usually does not wait for a fresh load. A cold load waits
  up to 10 seconds (`AdConstants.loadTimeout`).
- Show Rewarded Video via `RewardedAd`. Always call `setAdEventListener` before
  `show()`: the reward is captured in `onRewarded`, and
  `onAdDismissed`/`onAdFailedToShow` map to `completed` / `dismissed` /
  `unavailable`.
- Show the banner via `BannerAd` in `YandexBannerAdView`; the banner is
  recreated when the screen width changes (rotation) and destroyed with the
  widget.
- The banner is only built when the gallery's `showAds` flag is true.

---

## 12. Localization Keys

Keys currently used by the monetization UI:

```text
subscription_title
subscription_no_ads_title
subscription_no_ads_description
subscription_premium_title
subscription_premium_description
subscription_premium_badge
subscription_restore_button
subscription_restore_hint
subscription_history_title
subscription_history_empty
subscription_status_active
subscription_status_inactive
subscription_week
subscription_month
subscription_year
subscription_buy_button
subscription_terms_of_service
subscription_privacy_policy

purchase_dialog_project_price
purchase_dialog_buy_project
purchase_dialog_subscribe
purchase_dialog_subscribe_badge
purchase_dialog_cancel

purchase_processing_title
purchase_processing_text
purchase_checking_text
purchase_pending_retry_text
purchase_canceled_text
purchase_failed_title
purchase_failed_text
purchase_success_title
purchase_success_text
purchase_restore_success
purchase_restore_empty

refund_dialog_title
refund_dialog_body_credit
refund_dialog_body_subscription
refund_dialog_ok
canvas_refund_banner
canvas_subscription_expired_banner

rewarded_ad_loading
rewarded_ad_unavailable
banner_ad_label

error_contact_support
profile_status
```

Defined but **not referenced** by the current UI (kept for backend-driven text
or future work): `subscription_expires_at`, `purchase_dialog_title`,
`purchase_placeholder_message`, `error_no_internet_title`,
`error_no_internet_text`, `error_purchase_pending_title`,
`error_purchase_pending_text`, `contour_access_free`, `contour_access_ads`,
`contour_access_premium`.

Generated accessors live in
`core/lib/src/localization/generated/locale_keys.g.dart` and are produced by
`easy_localization:generate` from the JSON files in `core/resources/lang/`
(`en-US`, `ru-RU`, `es-ES`, `pt-BR`, `be-BY`, `de-DE`, `fr-FR`). Every locale
must contain the same keys, otherwise missing translations fall back to
`en-US`.

---

## 13. UI States Reference

### Contour Card (Gallery)

Badge in the top-right corner, favorite star in the bottom-right corner.

| Access type | No subscription | No Ads | Premium |
|-------------|-----------------|--------|---------|
| free | no badge | no badge | no badge |
| rewarded | purple + white play SVG | no badge | no badge |
| paid | gold + black crown SVG | gold + crown SVG | no badge |
| paid (`viewOnly`) | neutral + eye icon | neutral + eye | no badge |

While an ad is loading, the gallery shows a full-screen `AdLoadingOverlay`.

### Purchase Dialog (for `paid` project)

- Preview of the project
- Title of the project
- **Individual price** (only when `contours.price` is set) + "Buy Project"
  button
- **Premium description** + "Subscribe" button (with the "Best Value" badge)
- "Cancel" button

Outcome handling while the dialog is open:
- success → closes the dialog; the gallery-level purchase listener reloads
  monetization status and shows a `purchase_success_text` snackbar;
- pending → keeps the processing state; failed → localized error dialog;
- canceled → dialog returns to its idle state.

---

## 14. Backend Verification (Supabase Edge Functions)

Purchases are verified server-side; the client never marks a purchase as
granted on its own.

### `verify-purchase`

- Authenticated with the caller's Supabase JWT; `user_id` is taken from the
  token and any client supplied value is ignored.
- Request body: `{ product_id, purchase_token, type, platform, contour_id? }`.
- Response `status` is `verified` when the entitlement was granted,
  `pending` while Google Play has not finalized the payment yet, and `failed`
  when the store reports a canceled one-time payment. The client completes a
  store transaction only after `verified`; pending transactions are retried
  later, while failed ones stop blocking a new buy.
- A store purchase is never reported as failed after Google Play already
  confirmed the payment. If verification is unavailable (network, function or
  database error), a subscription is queued as `pending` and the transaction
  stays unacknowledged, so Play re-delivers it for another verification.
- When Play reports `ITEM_ALREADY_OWNED` (for example, an earlier attempt left
  the transaction unacknowledged), the client starts a restore instead of
  showing a purchase error; the restored transaction is verified and
  acknowledged normally.
- `platform` is `google` or `apple`.
  - `google` — verified with the Android Publisher API
    (`purchases.subscriptionsv2.get` for subscriptions,
    `purchases.products.get` for one-time products).
  - `apple` — **not implemented yet**, returns `501`.
- Subscription verification reads `lineItems[0].productId` (the plan product
  id, `no_ads` / `premium`) and `lineItems[0].offerDetails.basePlanId` (the
  period); `product_id`, `plan_type`, `base_plan_id`, `is_auto_renew` and
  `expires_at` come from `lineItems[0]` (`autoRenewingPlan.autoRenewEnabled`
  for the auto-renew flag).
- Subscriptions are stored in `subscriptions` keyed by `purchase_token`;
  individual projects grant a row in `user_entitlements`.
- Verification also appends the paid period to `subscription_purchases` with
  `is_auto_renewal = false`, because a direct verification is the initial
  purchase or a restore, not a store renewal.
- The matching `pending_purchases` row is marked `resolved` after a grant or
  `failed` after a canceled one-time payment.

### `google-play-webhook`

- Receives Real-time Developer Notifications through a Cloud Pub/Sub push
  subscription.
- Push endpoint:
  `https://<project-ref>.supabase.co/functions/v1/google-play-webhook?secret=<GOOGLE_PUBSUB_SECRET>`
- Handles voids/refunds (removes `user_entitlements`, deactivates
  `subscriptions`, records a user-visible `purchase_refunds` notice), one-time
  product cancellations, and Pub/Sub test notifications.
- On `SUBSCRIPTION_PURCHASED`, `SUBSCRIPTION_RESTARTED` and
  `SUBSCRIPTION_RENEWED`, it refetches the subscription from Google Play,
  updates `expires_at` / `base_plan_id` / `is_active` / `is_auto_renew`, and
  appends the paid period to `subscription_purchases`.
- `SUBSCRIPTION_CANCELED` (user turned off auto-renew) only sets
  `subscriptions.is_auto_renew = false`; the subscription stays active until
  `expires_at`. `SUBSCRIPTION_EXPIRED` and `SUBSCRIPTION_REVOKED` deactivate it
  immediately.
- `SUBSCRIPTION_RENEWED` (RTDN type `2`) is the only notification that writes
  `is_auto_renewal = true`; the period starts at the previous expiry when the
  new expiry is later. Repeated notifications for the same token and expiry are
  ignored by the unique index.

### Secrets

| Secret | Purpose |
|--------|---------|
| `GOOGLE_SERVICE_ACCOUNT_JSON` | Service account for the Android Publisher API |
| `GOOGLE_PLAY_PACKAGE_NAME` | Android application id |
| `GOOGLE_PUBSUB_SECRET` | Shared secret guarding the Pub/Sub webhook |
| `SUPABASE_URL` / `SUPABASE_ANON_KEY` / `SUPABASE_SERVICE_ROLE_KEY` | Provided automatically |

---

## 15. Future: iOS Billing

iOS billing is intentionally a stub for the current Android-only release. The
data layer exposes a platform-agnostic `BillingPlatform` abstraction; the iOS
implementation must satisfy the same contract.

Checklist for the iOS release:

1. Create the two subscription products (`no_ads`, `premium`) with three
   periods each, plus the per-project products, in App Store Connect.
2. Implement `AppleBillingPlatform` in
   `data/lib/src/services/apple_billing_platform.dart` via `in_app_purchase`
   (App Store) — replace the `UnimplementedError` stubs. Add the iOS-specific
   imports and App Store configuration at that point only.
3. Implement the `platform == "apple"` branch of `verify-purchase` using the
   App Store Server API (`GET /inApps/v1/subscriptions/{transactionId}` and
   `/inApps/v2/history`) with an App Store Server API key.
4. Wire App Store Server Notifications v2 to a new
   `supabase/functions/apple-app-store-webhook` function to reconcile refunds,
   cancellations and expirations.
5. Test with StoreKit sandbox accounts before submission.
---

## 16. Future: iOS Ads

Advertising is Yandex-only on Android for the current release. The data layer
exposes a platform-agnostic `AdService` abstraction; every ad provider must
satisfy the same contract (`initialize`, `isInitialized`, `showRewardedAd`,
`buildBanner`). `AdServiceFactory` returns `YandexAdService` on Android and
`StubAdService` (ads disabled) everywhere else.

Checklist for iOS ads:

1. Add an iOS ad SDK dependency (for example the Yandex Mobile Ads iOS pod) to
   `data/pubspec.yaml` and the iOS project.
2. Implement an `AppleAdService` in `data/lib/src/services/` that fulfils the
   `AdService` contract using the iOS SDK. Keep the SDK imports inside that
   file only, mirroring the current `YandexAdService`.
3. Extend `AdServiceFactory` to return the new implementation for
   `Platform.isIOS`, passing the same `AppConfig` ad unit identifiers (add
   iOS-specific keys to `env.sample` if the placements differ).
4. Review consent handling (ATT / GDPR) and call the SDK's consent APIs before
   the first ad request where required.
5. Create the rewarded and banner placements in the provider's dashboard and
   test with the provider's test ad units before release.

---

## 17. Testing checklist

Manual QA matrix for the monetization flows. Access decisions are derived from
server-provided state; the short subscription cache never extends access past
the subscription's own expiry. Every scenario below must be verified against a
real or sandbox Google Play account and the deployed Edge Functions.

### Purchases

- [ ] **No Ads purchase** — buying No Ads removes the gallery banner and opens
      every `rewarded` project without an ad.
- [ ] **Premium purchase** — buying Premium unlocks all `paid` projects and
      removes the banner.
- [ ] **Individual project purchase** — buying a `paid` project unlocks that
      project permanently, and stays unlocked after restart and reinstall.
- [ ] **Cancel** — dismissing the store sheet leaves the app unchanged and
      emits `monetization_purchase_canceled`; the dialog closes cleanly.
- [ ] **Pending** — a deferred payment shows the "processing" state, is stored
      in `pending_purchases`, and resolves on a later check.
- [ ] **Failed verification** — a server error shows a localized error, queues
      the purchase, and retries later without granting access.

### Restore

- [ ] Restoring on a device with existing purchases unlocks access within the
      restore timeout.
- [ ] Restoring with no purchases shows the "nothing to restore" result and
      changes nothing.
- [ ] Repeated restores do not duplicate entitlements.

### Expiry and renewal

- [ ] An active subscription that passes its `expires_at` stops granting
      access on the next gallery open and emits
      `monetization_subscription_expired` exactly once.
- [ ] A renewal extends `expires_at` and keeps access without any user action.
- [ ] A renewal adds a `subscription_purchases` row with
      `is_auto_renewal = true`, and the history shows the new period with the
      `Автообновление` badge.
- [ ] History rows show the purchased billing interval (week / month / year)
      and list every paid period, newest first.
- [ ] A re-delivered RTDN for an already stored period does not duplicate it.
- [ ] Expired Premium keeps `viewOnly` access to paid projects the user had
      already started, and blocks the rest.
- [ ] A server `is_active = false` subscription does not grant access even if
      its `expires_at` is still in the future.

### Refunds and revocation

- [ ] A refunded subscription (webhook) revokes access; the gallery card
      flips to locked within seconds, without reloading the app.
- [ ] A refunded individual purchase revokes that project's access.
- [ ] The refund dialog appears in real time on whatever screen is open, is
      shown once, and does not reappear after it is acknowledged.
- [ ] Drawing the refunded contour switches the canvas to view-only (banner,
      editing disabled); drawing a different contour keeps working.
- [ ] With Realtime disabled, an app resume or a gallery pull-to-refresh
      still surfaces the refund.
- [ ] A charged-back / canceled subscription behaves like an expiry.

### Rewarded video

- [ ] Watching a rewarded video to the end (`onRewarded` fired) opens the
      project; the event listener is registered before `show()`.
- [ ] Closing the rewarded video early keeps the project locked without a
      dialog; tapping the project again retries the ad.
- [ ] When no ad can be loaded (offline, no fill, 10-second timeout) the project
      stays locked and the `rewarded_ad_unavailable` dialog offers Retry.
- [ ] If the SDK initialization failed, the next rewarded attempt retries
      initialization instead of failing forever.
- [ ] An active subscription or No Ads skips the ad entirely for `rewarded`
      projects.
- [ ] `paid` projects are never opened through a rewarded video; they show the
      purchase dialog instead.
- [ ] With an empty `YANDEX_ADS_REWARDED_UNIT_ID`, the unavailable dialog is
      shown and a startup warning is logged.

### Banner

- [ ] The gallery banner is visible for users without an active plan and
      without the permanent `no_ads_purchased` flag.
- [ ] The banner disappears immediately after a successful purchase or restore.
- [ ] Rotating the device recreates the banner with the new width.
- [ ] No banner is shown on unsupported platforms (`StubAdService`) or when
      `YANDEX_ADS_BANNER_UNIT_ID` is empty.
- [ ] Ad unit IDs are configured in `.env.dev` / `.env.prod` only; a failed
      banner load is logged and the layout collapses without an error dialog.
- [ ] A release build (R8/ProGuard) still serves ads.

### Offline and errors

- [ ] Opening the gallery offline shows the generic localized error with a
      retry action; no technical exception text is shown to the user.
- [ ] The subscription screen offline shows the generic localized error and a
      retry.
- [ ] Previously cached state is never used to grant access to an expired
      subscription while offline.

### Cache

- [ ] Re-opening the gallery within the 5-minute cache TTL
      (`RequestConstants.monetizationCacheTtl`) does not re-query Supabase.
- [ ] A successful purchase invalidates the cache and the new access is visible
      immediately.
- [ ] Cache entries expire after the TTL and are refreshed from the server.

### Pending purchases and history

- [ ] A deferred purchase shows the processing state and queues a
      `pending_purchases` row with the unlocked `contour_id`.
- [ ] The "Payment Processing" button re-checks the store: it keeps the dialog
      open while the payment is still pending and closes it after confirmation.
- [ ] A store-canceled pending payment becomes `failed`, shows the cancellation
      message and offers the buy button again instead of staying pending forever.
- [ ] Re-opening the purchase dialog for the same project while the row is
      still pending shows the processing state instead of the buy button.
- [ ] A delayed confirmation unlocks the original project even after an app
      restart (contour recovered from the stored row); with the dialog closed,
      the gallery refreshes access and shows the success snackbar.
- [ ] An unfinished store transaction re-delivered on the next launch is
      verified and the purchase completes.
- [ ] A pending row older than 24 hours shows the stale-pending notice on the
      subscription screen.
- [ ] The history section lists resolved rows (product ID + date) and shows the
      empty state when there are none.

### Analytics

- [ ] `monetization_purchase_started`, `monetization_purchase_completed`,
      `monetization_purchase_pending`, `monetization_purchase_canceled` and
      `monetization_purchase_failed` are emitted on the matching purchase
      transitions.
- [ ] `monetization_rewarded_ad_shown`, `monetization_rewarded_ad_completed`,
      `monetization_rewarded_ad_skipped` and
      `monetization_rewarded_ad_unavailable` are emitted for the ad flows;
      `unavailable` carries `reason` (`not_ready`, `load_timeout`,
      `request_error`, `unexpected_error`).
- [ ] `monetization_subscription_expired` is emitted once per active-to-none
      transition.

---

## Logging conventions

Monetization events are written through the existing `AppLogger` and always
start with `[Monetization]`, so they can be filtered from the rest of the log.
Purchase tokens are never logged in full: only the first 8 characters are kept
and the rest is replaced with `...`.

### Access checks

| Event | Level | Emitted from |
|-------|-------|--------------|
| `[Monetization] Access check: contour={id}, type={accessType}, result={locked\|unlocked\|viewOnly}` | `debug` | `GalleryBloc` when a project is opened |

### Rewarded ads

| Event | Level | Emitted from |
|-------|-------|--------------|
| `[Monetization] Rewarded ad started: contour={id}` | `debug` | `AdService` implementation |
| `[Monetization] Rewarded ad completed: contour={id}` | `debug` | `AdService` implementation |
| `[Monetization] Rewarded ad skipped: contour={id}` | `warning` | `AdService` implementation |
| `[Monetization] Rewarded ad failed: contour={id}, error={message}` | `warning` (`error` for unexpected exceptions) | `AdService` implementation |

### Banner ads

| Event | Level | Emitted from |
|-------|-------|--------------|
| `[Monetization] Banner ad failed: error={message}` | `warning` | `YandexBannerAdView` |

SDK initialization/config warnings (for example an empty ad unit ID) are logged
without the `[Monetization]` prefix.

### Purchases

| Event | Level | Emitted from |
|-------|-------|--------------|
| `[Monetization] Purchase initiated: product={productId}, type={subscription\|project}` | `debug` | `SubscriptionBloc` (subscriptions) and `MonetizationRepositoryImpl.buyProject` (projects) |
| `[Monetization] Purchase completed: product={productId}, token={short}` | `debug` | `MonetizationRepositoryImpl` |
| `[Monetization] Purchase failed: product={productId}, error={message}` | `warning` (store error) / `error` (verification exception) | `MonetizationRepositoryImpl` |
| `[Monetization] Purchase pending: product={productId}, token={short}` | `debug` | `MonetizationRepositoryImpl` |

### Restore purchases

| Event | Level | Emitted from |
|-------|-------|--------------|
| `[Monetization] Restore started` | `debug` | `MonetizationRepositoryImpl` |
| `[Monetization] Restore completed: count={n}` | `debug` | `MonetizationRepositoryImpl` |
| `[Monetization] Restore failed: error={message}` | `error` | `MonetizationRepositoryImpl` |

### Subscription state

| Event | Level | Emitted from |
|-------|-------|--------------|
| `[Monetization] Subscription activated: plan={no_ads\|premium}` | `debug` | `MonetizationRepositoryImpl` (confirmed purchase or inactive-to-active transition) |
| `[Monetization] Subscription expired: product={productId}` | `debug` | `MonetizationRepositoryImpl` (active-to-none transition) |
