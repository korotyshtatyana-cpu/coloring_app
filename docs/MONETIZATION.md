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

### Icons on Gallery Cards

The icon in the bottom-right corner of each card depends on the project type AND the user's subscription status:

| Project type | No subscription | No Ads | Premium |
|--------------|-----------------|--------|---------|
| `free` | free (no icon) | free | free |
| `rewarded` | ads (video icon) | free | free |
| `paid` | premium (lock/crown) | premium | free |

---

## 2. Subscription Plans

### Six SKUs (Google Play Billing)

**No Ads** — removes all ads:

| SKU | Duration | Price |
|-----|----------|-------|
| `no_ads_week` | 1 week | 99 ₽ |
| `no_ads_month` | 1 month | 249 ₽ |
| `no_ads_year` | 1 year | 1990 ₽ |

**Premium** — removes ads AND unlocks all paid projects:

| SKU | Duration | Price |
|-----|----------|-------|
| `premium_week` | 1 week | 149 ₽ |
| `premium_month` | 1 month | 399 ₽ |
| `premium_year` | 1 year | 2990 ₽ |

### Individual Project Purchase

- Price stored in `contours.price` (in cents).
- After purchase → project is **permanently unlocked** for this user.
- Independent of subscription status.

---

## 3. Access Logic

### Function `getProjectAccess`

| Scenario | Result |
|----------|--------|
| Project is `free` | ✅ Unlocked |
| Project purchased individually | ✅ Unlocked (forever) |
| Project is `rewarded` + any active subscription | ✅ Unlocked |
| Project is `rewarded` + `no_ads` purchased | ✅ Unlocked |
| Project is `rewarded` + no subscription | 🔒 Locked (watch ad required) |
| Project is `paid` + Premium active | ✅ Unlocked |
| Project is `paid` + only `no_ads` | 🔒 Locked |
| Project is `paid` + no subscription | 🔒 Locked |

### When Subscription Expires

**For `paid` projects:**
- With saved strokes (`in progress`) → **View-only** (can view, cannot edit)
- Without strokes → **Locked** (fully blocked)

**For `rewarded` projects:**
- Require watching an ad again

**For individually purchased projects:**
- Remain **Unlocked forever**

### When Subscription is Renewed

- All `view-only` projects → automatically become `Unlocked`.
- No user action required — checked on project open.

---

## 4. Rewarded Video (Yandex Mobile Ads)

### Behavior

- User taps on a `rewarded` project → opens Rewarded Video.
- **Shown EVERY time** the project is opened (no cooldown).
- If user **watches to the end** → project opens.
- If user **does not finish** → modal dialog with error message.

### Modal Dialog: "Ad not completed"

**EN:** `You didn't finish watching the ad. To open this project, please watch it fully.`

**RU:** `Вы не досмотрели рекламу до конца. Чтобы открыть проект, посмотрите её полностью.`

**Buttons:** "Retry" / "Cancel".

### Package

- **Official Yandex package only:** `yandex_mobileads`.

---

## 5. Banner in Gallery

- **Ad banner** at the bottom of the Gallery screen (Yandex Mobile Ads).
- **Shown:**
    - To all users **without** any subscription (`no_ads` or `premium`).
    - **Not shown** to subscribers.
- **`free` projects** are always available without ads (the banner does not affect them).

---

## 6. Subscription Screen

### Structure (top to bottom)

**1. Header**
- Title: "Subscription"

**2. Current Status**
- If no subscription: "You don't have an active subscription."
- If active: "Premium active until 15 November 2026, 23:59" + countdown timer (days, hours, minutes).

**3. Plans — Two Blocks**

**Block "No Ads"**
- Description: "Removes all ads from the app. All `rewarded` projects open without watching videos."
- Segmented control: Week / Month / Year
- Button: "Subscribe"

**Block "Premium"** (badge "Best Value")
- Description: "Everything from No Ads + all paid projects unlocked without purchase."
- Segmented control: Week / Month / Year
- Button: "Subscribe"

**4. Restore Purchases Button**
- With hint: "If you already purchased a subscription, tap to restore access on this device."

**5. Purchase and Subscription History**
- List of recent transactions with date, type, amount.
- If empty: "History is empty."

**6. Footer**
- Link: "Terms of Service"
- Link: "Privacy Policy"

---

## 7. Subscription Status in Profile

### Avatar Frame

The avatar frame color reflects subscription status:
- **Gray** — no subscription
- **Purple with "AD" letters** — `no_ads` active
- **Gold with crown** — `premium` active

### Profile Text

- Line "Status": "Premium until 15.11.2026" (if active) or "Subscription inactive".

---

## 8. Errors and Recovery

### No Internet

Modal dialog: "No internet connection. Please check your network and try again."

The app requires an active connection for:
- Opening any project
- Watching Rewarded Video
- Making purchases
- Checking subscription status
- Syncing projects with the cloud

### Pending Purchase (Billing not confirmed)

1. Save transaction to **pending queue** (local storage).
2. Show dialog: "Payment is processing. We'll check it as soon as you're back online."
3. On next app launch (or network restoration) → check queue via Google Play Billing.
4. If unresolved after 24 hours → show: "Please contact the app support."
5. Show user **what they can do**: "Check your internet connection and update the app."

### Purchase Refund

- Google Play webhook → Supabase Edge Function → remove record from `user_entitlements`.
- Access to project is revoked **immediately**.

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
  is_active boolean DEFAULT true,
  started_at timestamp DEFAULT now(),
  expires_at timestamp NOT NULL,
  purchase_token text,
  created_at timestamp DEFAULT now()
);

-- 5. User entitlements to projects
CREATE TABLE public.user_entitlements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  contour_id uuid NOT NULL REFERENCES public.contours(id) ON DELETE CASCADE,
  type text NOT NULL,
  granted_at timestamp DEFAULT now(),
  expires_at timestamp,
  UNIQUE(user_id, contour_id)
);

-- 6. Pending purchases queue
CREATE TABLE public.pending_purchases (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  product_id text NOT NULL,
  purchase_token text,
  status text DEFAULT 'pending',
  error_message text,
  created_at timestamp DEFAULT now(),
  resolved_at timestamp
);
```

## 10. Google Play Billing Setup

### Step 1. Create In-App Products (No Ads)

1. Play Console → App → **Monetization** → **Products** → **In-app products**.
2. Create 3 products:
    - ID: `no_ads_week` | Name: "No Ads — Week" | Price: 99 ₽
    - ID: `no_ads_month` | Name: "No Ads — Month" | Price: 249 ₽
    - ID: `no_ads_year` | Name: "No Ads — Year" | Price: 1990 ₽
3. Activate.

### Step 2. Create Subscriptions (Premium)

1. **Monetization** → **Products** → **Subscriptions**.
2. Create 3 subscriptions:
    - ID: `premium_week` | Price: 149 ₽/week
    - ID: `premium_month` | Price: 399 ₽/month
    - ID: `premium_year` | Price: 2990 ₽/year
3. Configure a base plan for each.

### Step 3. Configure Test Account

1. **Settings** → **License Testing**.
2. Add your Gmail to "License testers".
3. **License response:** `RESPOND_NORMALLY`.
4. Save.

### Step 4. Install Package

- `in_app_purchase: ^3.2.0` (official Flutter package).

### Step 5. Configure Webhooks (for Refunds)

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
3. Copy **Ad Unit IDs**.

### Step 3. Install Package

- `yandex_mobileads: ^7.0.0` (official Flutter plugin).
- Add required permissions in `AndroidManifest.xml` and `Info.plist`.

### Step 4. Initialize in Code

- Initialize SDK in `main_common.dart`.
- Show Rewarded Video via `RewardedAd`.
- Show banner via `BannerAd`.

---

## 12. Localization Keys
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
subscription_expires_at
subscription_week
subscription_month
subscription_year
subscription_buy_button

rewarded_ad_not_completed_title
rewarded_ad_not_completed_text
rewarded_ad_retry
rewarded_ad_cancel

purchase_dialog_title
purchase_dialog_project_price
purchase_dialog_buy_project
purchase_dialog_subscribe
purchase_dialog_subscribe_badge
purchase_dialog_cancel

error_no_internet_title
error_no_internet_text
error_purchase_pending_title
error_purchase_pending_text
error_contact_support

contour_access_free
contour_access_ads
contour_access_premium
```

---

## 13. UI States Reference

### Contour Card (Gallery)

| Access type | No subscription | No Ads | Premium |
|-------------|-----------------|--------|---------|
| free | normal | normal | normal |
| rewarded | icon: video | icon: none | icon: none |
| paid | icon: lock | icon: lock | icon: none |

### Purchase Dialog (for `paid` project)

- Preview of the project
- Title of the project
- **Individual price** + "Buy Project" button
- **Subscription description** + "Subscribe" button (with "Best Value" badge)
- "Cancel" button

### Rewarded Ad Error Dialog

- Title: "Ad not completed"
- Text: error message
- Buttons: "Retry" / "Cancel"