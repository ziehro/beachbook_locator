import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobService {
  String getAdMobAppId() {
    if (kReleaseMode) {
      return 'ca-app-pub-3170667552847591~8931330231';
    } else {
      return 'ca-app-pub-3170667552847591~8931330231';
    }
  }

  String getBannerAdUnitId() {
    if (kReleaseMode) {
      return 'ca-app-pub-3170667552847591/6139862976';
    } else {
      return 'ca-app-pub-3940256099942544/6300978111';  // This is a provided test ID by AdMob
    }
  }

// Add similar methods for other ad types if needed
}
