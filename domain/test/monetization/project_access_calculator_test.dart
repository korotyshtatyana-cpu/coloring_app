import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProjectAccessCalculator', () {
    // MONETIZATION.md §3 "Access Logic".

    test('1. free project is unlocked regardless of subscription state', () {
      expect(
        _calculate(contour: _contour(ContourAccessType.free)),
        ProjectAccess.unlocked,
      );
      expect(
        _calculate(
          contour: _contour(ContourAccessType.free),
          activeSubscription: _subscription(SubscriptionPlanType.premium),
        ),
        ProjectAccess.unlocked,
      );
    });

    test('2. paid project with an individual purchase is unlocked', () {
      expect(
        _calculate(
          contour: _contour(ContourAccessType.paid),
          entitlement: _purchaseEntitlement(),
        ),
        ProjectAccess.unlocked,
      );
    });

    test(
      '3. rewarded project with an active No Ads subscription is unlocked',
      () {
        expect(
          _calculate(
            contour: _contour(ContourAccessType.rewarded),
            activeSubscription: _subscription(SubscriptionPlanType.noAds),
          ),
          ProjectAccess.unlocked,
        );
      },
    );

    test(
      '4. rewarded project with an active Premium subscription is unlocked',
      () {
        expect(
          _calculate(
            contour: _contour(ContourAccessType.rewarded),
            activeSubscription: _subscription(SubscriptionPlanType.premium),
          ),
          ProjectAccess.unlocked,
        );
      },
    );

    test('5. rewarded project without a subscription is locked', () {
      expect(
        _calculate(contour: _contour(ContourAccessType.rewarded)),
        ProjectAccess.locked,
      );
    });

    test('6. paid project with a Premium subscription is unlocked', () {
      expect(
        _calculate(
          contour: _contour(ContourAccessType.paid),
          activeSubscription: _subscription(SubscriptionPlanType.premium),
        ),
        ProjectAccess.unlocked,
      );
    });

    test('7. paid project with only a No Ads subscription is locked', () {
      expect(
        _calculate(
          contour: _contour(ContourAccessType.paid),
          activeSubscription: _subscription(SubscriptionPlanType.noAds),
        ),
        ProjectAccess.locked,
      );
    });

    test('8. paid project without a subscription is locked', () {
      expect(
        _calculate(contour: _contour(ContourAccessType.paid)),
        ProjectAccess.locked,
      );
    });

    // Additional edge cases.

    test('9. an expired subscription behaves as no subscription', () {
      final SubscriptionEntity expired = _subscription(
        SubscriptionPlanType.premium,
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(
        _calculate(
          contour: _contour(ContourAccessType.paid),
          activeSubscription: expired,
        ),
        ProjectAccess.locked,
      );
      expect(
        _calculate(
          contour: _contour(ContourAccessType.rewarded),
          activeSubscription: expired,
        ),
        ProjectAccess.locked,
      );
    });

    test(
      '10. an entitlement with expires_at in the past is treated as expired',
      () {
        final DateTime past = DateTime.now().subtract(const Duration(days: 1));
        expect(
          _calculate(
            contour: _contour(ContourAccessType.paid),
            entitlement: _purchaseEntitlement(expiresAt: past),
          ),
          ProjectAccess.locked,
        );
        expect(
          _calculate(
            contour: _contour(ContourAccessType.rewarded),
            entitlement: _rewardedEntitlement(expiresAt: past),
          ),
          ProjectAccess.locked,
        );
      },
    );

    test('11. an unknown access_type is not representable by the enum', () {
      // ContourAccessType is closed, so the calculator can never receive an
      // unknown value. The defensive fallback lives in the data layer: unknown
      // DB values are rejected by fromDb and the column defaults to "free".
      expect(ContourAccessType.fromDb('unknown'), isNull);
      expect(
        _calculate(contour: _contour(ContourAccessType.free)),
        ProjectAccess.unlocked,
      );
    });

    // Behavior that follows from the same decision table.

    test('an inactive subscription does not grant access', () {
      expect(
        _calculate(
          contour: _contour(ContourAccessType.paid),
          activeSubscription: _subscription(
            SubscriptionPlanType.premium,
            isActive: false,
          ),
        ),
        ProjectAccess.locked,
      );
    });

    test(
      'an expired Premium keeps view-only access to a started paid project',
      () {
        expect(
          _calculate(
            contour: _contour(ContourAccessType.paid),
            activeSubscription: _subscription(
              SubscriptionPlanType.premium,
              expiresAt: DateTime.now().subtract(const Duration(days: 1)),
            ),
            hasProgress: true,
          ),
          ProjectAccess.viewOnly,
        );
      },
    );

    test('No Ads does not upgrade a started paid project past view-only', () {
      expect(
        _calculate(
          contour: _contour(ContourAccessType.paid),
          noAdsPurchased: true,
          hasProgress: true,
        ),
        ProjectAccess.viewOnly,
      );
    });
  });
}

ProjectAccess _calculate({
  required ContourEntity contour,
  SubscriptionEntity? activeSubscription,
  bool noAdsPurchased = false,
  UserEntitlementEntity? entitlement,
  bool hasProgress = false,
}) {
  return ProjectAccessCalculator.calculate(
    contour: contour,
    activeSubscription: activeSubscription,
    noAdsPurchased: noAdsPurchased,
    entitlement: entitlement,
    hasProgress: hasProgress,
  );
}

ContourEntity _contour(ContourAccessType accessType) {
  return ContourEntity(
    id: 'contour_1',
    title: 'Test Contour',
    categories: const <ContourCategory>[ContourCategory.animals],
    svgUrl: 'https://example.com/contour.svg',
    previewUrl: 'https://example.com/preview.png',
    accessType: accessType,
  );
}

SubscriptionEntity _subscription(
  SubscriptionPlanType planType, {
  bool isActive = true,
  DateTime? expiresAt,
}) {
  final DateTime now = DateTime.now();
  return SubscriptionEntity(
    id: 'sub_1',
    userId: 'user_1',
    productId: planType.dbValue,
    planType: planType,
    isActive: isActive,
    startedAt: now.subtract(const Duration(days: 1)),
    expiresAt: expiresAt ?? now.add(const Duration(days: 30)),
  );
}

UserEntitlementEntity _purchaseEntitlement({DateTime? expiresAt}) {
  return UserEntitlementEntity(
    id: 'ent_purchase',
    userId: 'user_1',
    contourId: 'contour_1',
    type: EntitlementType.purchase,
    grantedAt: DateTime.now(),
    expiresAt: expiresAt,
  );
}

UserEntitlementEntity _rewardedEntitlement({required DateTime expiresAt}) {
  return UserEntitlementEntity(
    id: 'ent_rewarded',
    userId: 'user_1',
    contourId: 'contour_1',
    type: EntitlementType.rewardedUnlock,
    grantedAt: DateTime.now().subtract(const Duration(hours: 1)),
    expiresAt: expiresAt,
  );
}
