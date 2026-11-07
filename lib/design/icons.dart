import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/constants.dart';

/// Named icon registry: accounts and categories store an icon *key* in the DB.
abstract final class BIcons {
  static const Map<String, IconData> byKey = {
    'wallet': LucideIcons.wallet,
    'banknote': LucideIcons.banknote,
    'landmark': LucideIcons.landmark,
    'smartphone': LucideIcons.smartphone,
    'credit_card': LucideIcons.creditCard,
    'piggy_bank': LucideIcons.piggyBank,
    'coins': LucideIcons.coins,
    'building': LucideIcons.building2,
    'bus': LucideIcons.bus,
    'train': LucideIcons.train,
    'car': LucideIcons.car,
    'fuel': LucideIcons.fuel,
    'plane': LucideIcons.plane,
    'utensils': LucideIcons.utensils,
    'coffee': LucideIcons.coffee,
    'cart': LucideIcons.shoppingCart,
    'bag': LucideIcons.shoppingBag,
    'shirt': LucideIcons.shirt,
    'house': LucideIcons.house,
    'zap': LucideIcons.zap,
    'wifi': LucideIcons.wifi,
    'phone': LucideIcons.phone,
    'tv': LucideIcons.tv,
    'film': LucideIcons.film,
    'music': LucideIcons.music,
    'gamepad': LucideIcons.gamepad2,
    'heart': LucideIcons.heartPulse,
    'pill': LucideIcons.pill,
    'dumbbell': LucideIcons.dumbbell,
    'graduation': LucideIcons.graduationCap,
    'book': LucideIcons.book,
    'gift': LucideIcons.gift,
    'baby': LucideIcons.baby,
    'dog': LucideIcons.dog,
    'receipt': LucideIcons.receipt,
    'briefcase': LucideIcons.briefcase,
    'hand_coins': LucideIcons.handCoins,
    'trending_up': LucideIcons.trendingUp,
    'repeat': LucideIcons.repeat,
    'droplet': LucideIcons.droplet,
    'flame': LucideIcons.flame,
    'lightbulb': LucideIcons.lightbulb,
    'scissors': LucideIcons.scissors,
    'wrench': LucideIcons.wrench,
    'umbrella': LucideIcons.umbrella,
    'package': LucideIcons.package,
    'store': LucideIcons.store,
    'sparkles': LucideIcons.sparkles,
  };

  static IconData of(String? key, {IconData fallback = LucideIcons.circleDollarSign}) => byKey[key] ?? fallback;

  static String defaultForAccount(AccountType t) => switch (t) {
        AccountType.cash => 'banknote',
        AccountType.bank => 'landmark',
        AccountType.upi => 'smartphone',
        AccountType.wallet => 'wallet',
        AccountType.creditCard => 'credit_card',
        AccountType.savings => 'piggy_bank',
      };

  static IconData tier(Tier t) => switch (t) {
        Tier.income => LucideIcons.trendingUp,
        Tier.priority => LucideIcons.handCoins,
        Tier.savings => LucideIcons.piggyBank,
        Tier.fixed => LucideIcons.receipt,
        Tier.daily => LucideIcons.coffee,
        Tier.variable => LucideIcons.shoppingCart,
      };
}
