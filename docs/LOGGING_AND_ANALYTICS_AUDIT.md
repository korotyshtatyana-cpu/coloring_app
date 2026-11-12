# Audit of Logging, Analytics, and Error Handling

## 1. TL;DR

- **What is collected:** Monetization flow milestones (purchase started, pending, completed, failed, canceled, expired), rewarded ad lifecycle events (shown, completed, skipped, unavailable), unhandled UI/framework errors, and billing/ad SDK warnings.
- **Where it goes:** **All client logs and analytics remain strictly local.** `AnalyticsService` is a facade wrapping `AppLogger`, which uses the Dart `logger` package printing exclusively to stdout (`print` / `dart:developer`). There are no third-party analytics or crash-reporting SDKs (no Firebase, Sentry, or Datadog) integrated into the mobile app. Supabase Edge Functions write logs to Deno `console.log` / `console.error` hosted on Supabase Cloud.
- **Top risks:**
  1. **Zero Production Telemetry:** Production crashes and payment errors are invisible remotely because no crash reporter or remote analytics provider is configured.
  2. **Unfiltered Error Payloads:** `ErrorReporting.report` logs raw exception objects and stack traces via `AppLogger.error()`. Database exceptions (`PostgrestException`) or platform billing errors may leak internal schema details or raw store response strings into console outputs.
  3. **No Environment Gating:** `AppLogger` is initialized with `PrettyPrinter` unconditionally in both dev and production builds without `kReleaseMode` or `kDebugMode` checks.

---

## 2. Logging channels

| Channel | Sink | Data logged | Remote? |
| :--- | :--- | :--- | :--- |
| `AppLogger` | stdout / `dart:developer` (`PrettyPrinter`) | Debug, info, warning, error, wtf application logs | **No** (Local device stdout only) |
| `AnalyticsService` | stdout via `AppLogger.info('[analytics] ...')` | Monetization & Ad event names + key-value parameter maps | **No** (Local device stdout only) |
| `ErrorReporting` | stdout via `AppLogger.error(...)` | Exception `toString()`, custom message, `StackTrace` | **No** (Local device stdout only) |
| `Supabase Edge Functions` | Deno stdout / stderr (`console.log`, `console.error`) | Verification statuses, PubSub RTDN webhook actions, Google Play API errors | **Yes** (Supabase Cloud Function Logs) |

---

## 3. AnalyticsEvents

| Constant | Value | Used? | Call Sites |
| :--- | :--- | :---: | :--- |
| `purchaseStarted` | `monetization_purchase_started` | **Yes** | `data/lib/src/repositories/monetization_repository_impl.dart:778,876,908` |
| `purchaseCompleted` | `monetization_purchase_completed` | **Yes** | `data/lib/src/repositories/monetization_repository_impl.dart:691` |
| `purchasePending` | `monetization_purchase_pending` | **Yes** | `data/lib/src/repositories/monetization_repository_impl.dart:564,721` |
| `purchaseFailed` | `monetization_purchase_failed` | **Yes** | `data/lib/src/repositories/monetization_repository_impl.dart:590,750` |
| `purchaseCanceled` | `monetization_purchase_canceled` | **Yes** | `data/lib/src/repositories/monetization_repository_impl.dart:608` |
| `rewardedAdShown` | `monetization_rewarded_ad_shown` | **Yes** | `data/lib/src/services/yandex_ad_service.dart:206` |
| `rewardedAdCompleted` | `monetization_rewarded_ad_completed` | **Yes** | `data/lib/src/services/yandex_ad_service.dart:243` |
| `rewardedAdSkipped` | `monetization_rewarded_ad_skipped` | **Yes** | `data/lib/src/services/yandex_ad_service.dart:249,254` |
| `rewardedAdUnavailable` | `monetization_rewarded_ad_unavailable` | **Yes** | `data/lib/src/services/yandex_ad_service.dart:173,196,265,273` |
| `subscriptionExpired` | `monetization_subscription_expired` | **Yes** | `data/lib/src/repositories/monetization_repository_impl.dart:80` |

*Note: 0 declared constants are unused.*

---

## 4. AppLogger calls

| File:Line | Level | Message Template / Content | Fields / Interpolations | PII Risk? |
| :--- | :--- | :--- | :--- | :---: |
| `core/lib/src/services/analytics_service.dart:21` | `info` | `[analytics] $event$details` | `event`, `details` (key=value string) | Low |
| `data/lib/src/di/data_di.dart:140` | `warning` | `Billing platform is not implemented yet` | None | No |
| `data/lib/src/di/data_di.dart:142` | `warning` | `Billing is not supported on this platform` | None | No |
| `data/lib/src/di/data_di.dart:151` | `warning` | `Ad SDK initialization failed` | None | No |
| `data/lib/src/repositories/monetization_repository_impl.dart:77` | `debug` | `[Monetization] Subscription expired: product=${previous.productId}` | `previous.productId` | No |
| `data/lib/src/repositories/monetization_repository_impl.dart:94` | `debug` | `[Monetization] Subscription activated: plan=${model.planType}` | `model.planType` | No |
| `data/lib/src/repositories/monetization_repository_impl.dart:443` | `debug` | `[Monetization] Purchase initiated: product=$resolvedProductId, type=...` | `resolvedProductId` | No |
| `data/lib/src/repositories/monetization_repository_impl.dart:468` | `warning` | `[Monetization] failed to resolve affected contour for credit refund: token=${_lastTokenChars(model.purchaseToken)}` | Truncated token (last 6 chars) | No |
| `data/lib/src/repositories/monetization_repository_impl.dart:560` | `debug` | `[Monetization] Store item already owned; restoring to verify: product=$errorProductId...` | `errorProductId` | No |
| `data/lib/src/repositories/monetization_repository_impl.dart:586` | `warning` | `[Monetization] Restore after already-owned failed: product=$errorProductId, error=$error` | `errorProductId`, `error` | No |
| `data/lib/src/repositories/monetization_repository_impl.dart:604` | `warning` | `[Monetization] Purchase failed: product=$errorProductId..., error=${purchase.error?.message ?? 'unknown'}` | `errorProductId`, store error | No |
| `data/lib/src/repositories/monetization_repository_impl.dart:623` | `debug` | `[Monetization] Purchase canceled: product=$productId...` | `productId` | No |
| `data/lib/src/repositories/monetization_repository_impl.dart:627` | `debug` | `[Monetization] Purchase pending: product=${purchase.productID}..., token=${_shortToken(...)}` | Truncated token | No |
| `data/lib/src/repositories/monetization_repository_impl.dart:640` | `warning` | `[Monetization] Purchase rejected by store: product=${purchase.productID}` | `purchase.productID` | No |
| `data/lib/src/repositories/monetization_repository_impl.dart:665` | `debug` | `[Monetization] Subscription purchase completed: product=..., token=${_lastTokenChars(token)}` | Truncated token | No |
| `data/lib/src/repositories/monetization_repository_impl.dart:686` | `debug` | `[Monetization] Subscription activated: plan=${_subscriptionPlanOf(purchase.productID)}` | `productID` | No |
| `data/lib/src/repositories/monetization_repository_impl.dart:702` | `debug` | `[Monetization] Purchase completed: product=${purchase.productID}, token=${_shortToken(token)}` | Truncated token | No |
| `data/lib/src/repositories/monetization_repository_impl.dart:716` | `warning` | `[Monetization] Subscription verification deferred: product=..., error=$error` | `productID`, `error` | No |
| `data/lib/src/repositories/monetization_repository_impl.dart:746` | `error` | `[Monetization] Purchase failed: product=..., error=$error` | `productID`, `error` | No |
| `data/lib/src/repositories/monetization_repository_impl.dart:773` | `debug` | `[Monetization] Subscription purchase initiated: product=${product.productId}, basePlan=${product.basePlanId}` | `productId`, `basePlanId` | No |
| `data/lib/src/repositories/monetization_repository_impl.dart:778` | `debug` | `[Monetization] Purchase initiated: product=$resolvedProductId, type=...` | `resolvedProductId` | No |
| `data/lib/src/repositories/monetization_repository_impl.dart:829` | `debug` | `[Monetization] Credit purchase initiated: product=..., contour=$contourId` | `contourId` | No |
| `data/lib/src/repositories/monetization_repository_impl.dart:859` | `debug` | `[Monetization] Restore started` | None | No |
| `data/lib/src/repositories/monetization_repository_impl.dart:865` | `debug` | `[Monetization] Restore completed: count=$_restoredCount` | `_restoredCount` | No |
| `data/lib/src/repositories/monetization_repository_impl.dart:870` | `error` | `[Monetization] Restore failed: error=$error` | `error` | No |
| `data/lib/src/repositories/monetization_repository_impl.dart:902` | `debug` | `[Monetization] Restore completed: count=$_restoredCount` | `_restoredCount` | No |
| `data/lib/src/repositories/monetization_repository_impl.dart:927` | `debug` | `[Monetization] refund event received: token=${_lastTokenChars(model.purchaseToken)}, product=${model.productId}` | Truncated token, `productId` | No |
| `data/lib/src/services/google_play_billing_platform.dart:43` | `warning` | `Google Play Billing is not available` | None | No |
| `data/lib/src/services/google_play_billing_platform.dart:59` | `warning` | `Google Play product query failed: ${response.error}` | `response.error` | No |
| `data/lib/src/services/google_play_billing_platform.dart:64` | `warning` | `Google Play products not found: ${response.notFoundIDs.join(', ')}` | `notFoundIDs` | No |
| `data/lib/src/services/google_play_billing_platform.dart:197` | `warning` | `Google Play past purchase query failed: ${response.error!.message}` | `error.message` | No |
| `data/lib/src/services/google_play_billing_platform.dart:225` | `warning` | `Google Play past purchase query failed: $error` | `error` | No |
| `data/lib/src/services/stub_ad_service.dart:23` | `warning` | `[Monetization] Rewarded ad failed: contour=${contourId ?? 'unknown'}, error=ads are not supported...` | `contourId` | No |
| `data/lib/src/services/supabase_refund_monitor.dart:95` | `warning` | `[Monetization] realtime refund channel disconnected, will retry` | None | No |
| `data/lib/src/services/yandex_ad_service.dart:91` | `warning` | `YANDEX_ADS_REWARDED_UNIT_ID is empty; rewarded ads are disabled` | None | No |
| `data/lib/src/services/yandex_ad_service.dart:94` | `warning` | `YANDEX_ADS_BANNER_UNIT_ID is empty; banner ads are disabled` | None | No |
| `data/lib/src/services/yandex_ad_service.dart:161` | `debug` | `[Monetization] Rewarded ad started: contour=$contour` | `contour` | No |
| `data/lib/src/services/yandex_ad_service.dart:169` | `warning` | `[Monetization] Rewarded ad failed: contour=$contour, error=ads are not ready` | `contour` | No |
| `data/lib/src/services/yandex_banner_ad_view.dart:64` | `warning` | `[Monetization] Banner ad failed: error=${error.description}` | `error.description` | No |
| `features/canvas/lib/src/bloc/canvas_bloc.dart:263` | `debug` | `[Monetization] canvas switched to view-only: contour=$_contourId, reason=${event.reason.name}` | `_contourId`, `reason` | No |
| `features/canvas/lib/src/bloc/canvas_bloc.dart:283` | `debug` | `[Monetization] canvas unlocked from view-only mode: contour=$_contourId` | `_contourId` | No |
| `features/gallery/lib/src/bloc/gallery_bloc.dart:327` | `debug` | `[Monetization] Access check: contour=${contour.id}, type=${contour.accessType.name}, result=${access.name}` | `contour.id`, `accessType`, `access` | No |
| `features/subscription/lib/src/bloc/subscription_bloc.dart:98` | `warning` | `[Monetization] Failed to load subscription prices: $e` | `e` | No |
| `features/subscription/lib/src/bloc/subscription_bloc.dart:159` | `warning` | `[Monetization] Failed to refresh subscription screen: $e` | `e` | No |
| `features/subscription/lib/src/bloc/subscription_bloc.dart:214` | `debug` | `[Monetization] Subscription purchase initiated: product=${plan.dbValue}, basePlan=${interval.dbValue}` | `plan.dbValue`, `interval.dbValue` | No |
| `lib/error_handler/error_reporting.dart:12` | `error` | `message ?? 'Reporting error: $error'` | Custom message or `error.toString()`, `stackTrace` | **PII Risk** |
| `lib/refunds/refund_observer.dart:147` | `debug` | `[Monetization] refund dialog shown: count=${batch.length}` | `batch.length` | No |
| `lib/refunds/refund_observer.dart:159` | `debug` | `[Monetization] refund acknowledged: token=${_lastTokenChars(refund.purchaseToken)}` | Truncated token | No |

---

## 5. AnalyticsService calls

| File:Line | Event | Payload / Parameters | PII Risk? |
| :--- | :--- | :--- | :---: |
| `data/lib/src/repositories/monetization_repository_impl.dart:80` | `subscriptionExpired` | `{'plan_type': previous.planType, 'product_id': previous.productId}` | No |
| `data/lib/src/repositories/monetization_repository_impl.dart:564` | `purchasePending` | `{'product_id': errorProductId, 'reason': 'already_owned'}` | No |
| `data/lib/src/repositories/monetization_repository_impl.dart:590` | `purchaseFailed` | `{'product_id': errorProductId, 'reason': purchase.error?.message}` | No |
| `data/lib/src/repositories/monetization_repository_impl.dart:608` | `purchaseCanceled` | `{'product_id': productId}` | No |
| `data/lib/src/repositories/monetization_repository_impl.dart:691` | `purchaseCompleted` | `{'product_id': purchase.productID, 'base_plan_id': basePlanId, 'contour_id': contourId, 'is_restore': isRestore}` | No |
| `data/lib/src/repositories/monetization_repository_impl.dart:721` | `purchasePending` | `{'product_id': purchase.productID, 'base_plan_id': ..., 'reason': error.toString()}` | No |
| `data/lib/src/repositories/monetization_repository_impl.dart:750` | `purchaseFailed` | `{'product_id': purchase.productID, 'base_plan_id': ..., 'contour_id': contourId, 'reason': error.toString()}` | No |
| `data/lib/src/repositories/monetization_repository_impl.dart:778` | `purchaseStarted` | `{'type': 'subscription', 'product_id': product.productId, 'base_plan_id': product.basePlanId, 'plan_type': plan.dbValue, 'interval': interval.dbValue}` | No |
| `data/lib/src/repositories/monetization_repository_impl.dart:876` | `purchaseStarted` | `{'type': 'product', 'product_id': resolvedProductId, 'contour_id': contourId}` | No |
| `data/lib/src/repositories/monetization_repository_impl.dart:908` | `purchaseStarted` | `{'type': 'credits', 'product_id': 'unlock_credit', 'contour_id': contourId}` | No |
| `data/lib/src/services/yandex_ad_service.dart:173` | `rewardedAdUnavailable` | `{'reason': 'not_ready'}` | No |
| `data/lib/src/services/yandex_ad_service.dart:196` | `rewardedAdUnavailable` | `{'reason': 'failed_to_load', 'error': _loadError}` | No |
| `data/lib/src/services/yandex_ad_service.dart:206` | `rewardedAdShown` | `{'contour_id': contour}` | No |
| `data/lib/src/services/yandex_ad_service.dart:243` | `rewardedAdCompleted` | `{'contour_id': contour}` | No |
| `data/lib/src/services/yandex_ad_service.dart:249` | `rewardedAdSkipped` | `{'contour_id': contour}` | No |
| `data/lib/src/services/yandex_ad_service.dart:254` | `rewardedAdSkipped` | `{'contour_id': contour}` | No |
| `data/lib/src/services/yandex_ad_service.dart:265` | `rewardedAdUnavailable` | `{'contour_id': contour, 'reason': error.description}` | No |
| `data/lib/src/services/yandex_ad_service.dart:273` | `rewardedAdUnavailable` | `{'contour_id': contour, 'reason': error.toString()}` | No |

---

## 6. Swallowed errors

| File:Line | Code Snippet | Note & Assessment |
| :--- | :--- | :--- |
| `core/lib/src/utils/svg_utils.dart:34` | `} catch (_) { return null; }` | Network SVG download error swallowed silently. Acceptable fallback to placeholder, but hides network timeouts. |
| `data/lib/src/cache/subscription_cache.dart:134` | `} catch (_) { _subscription = null; }` | SharedPreferences JSON parse error swallowed. Prevents crash on corrupted local cache, resets cache gracefully. |
| `data/lib/src/providers/auth_remote_provider.dart:56` | `} catch (_) { return false; }` | Silent session refresh failure swallowed. Returns `false` so `AuthGuard` triggers interactive login fallback. |
| `data/lib/src/repositories/gallery_repository_impl.dart:30` | `} catch (_) { final cached = ... }` | Remote contour fetch failure swallowed silently to fallback to offline Drift DB. |
| `data/lib/src/repositories/gallery_repository_impl.dart:58` | `} catch (_) { final cached = ... }` | Remote contour lookup by IDs swallowed silently to fallback to offline Drift DB. |
| `data/lib/src/repositories/gallery_repository_impl.dart:105` | `} catch (e) { debugPrint('Failed to fetch favorite IDs: $e'); }` | Favorite IDs fetch error printed with `debugPrint` instead of `ErrorHandler.report`. |
| `data/lib/src/repositories/gallery_repository_impl.dart:151` | `} catch (_) { return local; }` | Work in progress remote fetch error swallowed silently to fallback to local Drift DB. |
| `data/lib/src/repositories/gallery_repository_impl.dart:165` | `} catch (e) { debugPrint('Error getting contour by ID: $e'); }` | Local contour lookup exception logged via `debugPrint` instead of `ErrorHandler.report`. |
| `data/lib/src/repositories/gallery_repository_impl.dart:175` | `} catch (_) { final cached = ... }` | Remote used categories fetch error swallowed silently to fallback to local Drift DB. |
| `features/gallery/lib/src/bloc/gallery_bloc.dart:314` | `} catch (_) { }` | Secondary favorite re-sync failure inside toggle catch block swallowed silently. |
| `features/gallery/lib/src/widgets/user_avatar_button.dart:53` | `} catch (_) { }` | Current user load exception swallowed silently to display default avatar icon. |
| `navigation/lib/src/guards/auth_guard.dart:36` | `} catch (_) { }` | Silent sign-in failure swallowed to fall through to interactive sign-in attempt. |
| `navigation/lib/src/guards/auth_guard.dart:45` | `} catch (_) { }` | Interactive sign-in failure swallowed to fall through to Splash route redirect. |

---

## 7. PII RISK Section

1. **`lib/error_handler/error_reporting.dart:12`** — **PII RISK**
   - **Explanation:** `ErrorReporting.report(error, stackTrace, message)` passes raw `error.toString()` and `stackTrace` to `AppLogger.error()`. If an exception includes user email (e.g. `AuthException` from Supabase Auth during login), database queries containing user IDs, or full network URL parameters, raw PII will be printed to stdout.
2. **`data/lib/src/providers/database_provider.dart` & `subscription_cache.dart`** — **PII RISK**
   - **Explanation:** User ID (`userId`) and email (`userEmail`) are stored unencrypted in local SQLite (`Projects` table) and `SharedPreferences`. While not sent to third parties, local device backups or rooted devices could expose these identifiers.
3. **`data/lib/src/repositories/monetization_repository_impl.dart:721,750`** — **PII RISK**
   - **Explanation:** In `_analytics.logEvent(AnalyticsEvents.purchaseFailed, parameters: {'reason': error.toString()})`, raw exception strings from Supabase or `in_app_purchase` are passed into analytics parameter maps. If an error string contains raw token fragments or platform account identifiers, it will be formatted into the analytics log output.

---

## 8. Edge Functions logging

- **Files scanned:**
  - `supabase/functions/verify-purchase/index.ts`
  - `supabase/functions/google-play-webhook/index.ts`
  - `supabase/functions/_shared/google_play_auth.ts`
  - `supabase/functions/_shared/supabase.ts`

- **Log inventory:**
  - `verify-purchase/index.ts:206`: `console.error('[verify-purchase] failed to read credits balance: ${error.message}')`
  - `verify-purchase/index.ts:240`: `console.error('[verify-purchase] failed to resolve pending purchase: ${error.message}')`
  - `verify-purchase/index.ts:266`: `console.error('[verify-purchase] failed to reject pending purchase: ${error.message}')`
  - `verify-purchase/index.ts:392`: `console.error('[verify-purchase] failed to record subscription purchase: ${error.message}')`
  - `verify-purchase/index.ts:452`: `console.log('[verify-purchase] subscription product=${actualProductId}, basePlan=${basePlanId ?? "unknown"}')`
  - `verify-purchase/index.ts:566`: `console.error('[verify-purchase] Google Play API error: ${error.message}')`
  - `verify-purchase/index.ts:573`: `console.error('[verify-purchase] unexpected error:', error)`
  - `google-play-webhook/index.ts:167`: `console.log('[webhook] ${message}')` (logs sanitized token suffixes via `tokenLabel` / `purchaseToken.slice(-8)`).
  - `google-play-webhook/index.ts:174`: `console.error('[webhook] ${message}: ${describeError(error)}')`

- **Sensitive Data & Credential Review in Edge Functions:**
  - **Service Role Key & JWTs:** `SUPABASE_SERVICE_ROLE_KEY` and `Authorization` Bearer JWTs are read from environment variables and HTTP headers (`_shared/supabase.ts`), but **are not printed** to `console.log`.
  - **Purchase Tokens:** Tokens in `google-play-webhook` logs are masked to the last 8 characters via `tokenLabel(purchaseToken)`. Full tokens are passed to database queries and Google Play API endpoints.
  - **User IDs:** `user_id` values are passed in database payloads and error messages without explicit masking in server-side logs.

---

## 9. Crashlytics readiness

- **Existing Hooks:**
  - `AppErrorHandlerProvider` (`lib/error_handler/provider/app_error_handler_provider.dart`) sets up global listeners for `FlutterError.onError`, `PlatformDispatcher.instance.onError`, and `Bloc.observer.onError`.
  - All three global hooks delegate directly to `ErrorReporting.report(error, stackTrace)`.
- **Gaps for Production Crash Reporting Integration:**
  1. **No SDK Dependency:** `pubspec.yaml` across root and all sub-modules contains no `firebase_crashlytics`, `sentry_flutter`, or similar crash reporter dependency.
  2. **No User Context:** No calls to set user IDs or user emails (e.g. `setCustomKey`, `setUserIdentifier`) exist in `ErrorHandler` or `ErrorReporting`.
  3. **No Non-Fatal vs Fatal Flag:** All errors are dispatched identically to `AppLogger.error()` regardless of severity or context.
  4. **No Breadcrumbs:** No navigation or action breadcrumbs are recorded or attached to error reporting calls.

---

## 10. Open questions

1. **Production Remote Log Sink:** In release builds (`main_prod.dart`), all logs print to local device stdout via `logger`. Is there an external log aggregator or backend proxy planned to receive production diagnostics?
2. **Data Processing Agreements (DPA):** Are DPAs established for third-party endpoints processing user purchase events and diagnostic data (Supabase Cloud, Yandex Mobile Ads)?
3. **Google Play Data Safety Declaration:** Google Play requires declaring data collected or shared (e.g. Financial Info for purchases, User IDs for auth, App Diagnostics for crash logs). Has the Data Safety form been populated to reflect local auth and billing processing?
