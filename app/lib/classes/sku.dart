class InAppProductsPurchaseSku {
  static get emeralds_100 {
    return "emeralds_100";
  }

  static get emeralds_200 {
    return "emeralds_200";
  }

  static get emeralds_500 {
    return "emeralds_500";
  }

  static get emeralds_1000 {
    return "emeralds_1000";
  }

  static List<String> get emeralds {
    return [
      emeralds_100,
      emeralds_200,
      emeralds_500,
      emeralds_1000,
    ];
  }
}

class InAppSubscriptionsPurchaseSku {
  static get epic {
    return "tier_epic";
  }

  static get premium {
    return "tier_premium";
  }

  static Set<String> get tiers {
    return {
      premium,
      epic,
    };
  }
}
