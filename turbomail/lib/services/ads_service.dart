import 'dart:convert';
import 'dart:ui';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

class AdsService {
  static final AdsService _instance = AdsService._internal();
  factory AdsService() => _instance;
  AdsService._internal();

  final Dio _dio = Dio();
  
  // Ad IDs from database only (no test IDs)
  Map<String, String> _adIds = {};
  
  Map<String, bool> _adStatus = {
    'banner': false,
    'interstitial': false,
    'native': false,
    'appOpen': false,
    'rewarded': false,
    'rewardedInterstitial': false,
  };

  // Ad instances
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  NativeAd? _nativeAd;
  AppOpenAd? _appOpenAd;
  RewardedAd? _rewardedAd;
  RewardedInterstitialAd? _rewardedInterstitialAd;

  // Loading states
  bool _isBannerAdLoaded = false;
  bool _isInterstitialAdLoaded = false;
  bool _isNativeAdLoaded = false;
  bool _isAppOpenAdLoaded = false;
  bool _isRewardedAdLoaded = false;
  bool _isRewardedInterstitialAdLoaded = false;

  // Admin panel API URL
  String get _adminApiUrl => 'http://165.22.109.153:3003/api/ads-config'; // Production admin panel URL

  // Initialize ads service
  Future<void> initialize() async {
    try {
      print('🚀 Initializing Ads Service...');
      
      // Initialize Mobile Ads SDK
      await MobileAds.instance.initialize();
      print('✅ Mobile Ads SDK initialized');
      
      // Fetch ads config from admin panel
      await _fetchAdsConfig();
      
      // Load ads only if we have valid configurations
      if (_adIds.isNotEmpty) {
        await _loadAllAds();
      } else {
        print('⚠️ No ad configurations found. Ads will not be loaded.');
      }
      
      print('✅ Ads Service initialized successfully');
    } catch (error) {
      print('❌ Error initializing Ads Service: $error');
    }
  }

  // Fetch ads configuration from admin panel
  Future<void> _fetchAdsConfig() async {
    try {
      print('📡 Fetching ads config from admin panel...');
      
      final response = await _dio.get(_adminApiUrl);
      
      if (response.statusCode == 200 && response.data['success']) {
        final adsConfig = response.data['data'] as Map<String, dynamic>;
        
        // Clear existing configurations
        _adIds.clear();
        
        // Update ad IDs and status from admin panel
        adsConfig.forEach((adType, config) {
          if (config != null && config['adId'] != null && config['adId'].toString().isNotEmpty) {
            _adIds[adType] = config['adId'];
            _adStatus[adType] = config['isActive'] ?? false;
            print('✅ Updated $adType: ${config['adId']} (${config['isActive'] ? 'Active' : 'Inactive'})');
          } else {
            _adStatus[adType] = false;
            print('⚠️ No valid ad ID for $adType');
          }
        });
        
        // Save to local storage for offline use
        await _saveAdsConfigLocally(adsConfig);
        
        print('✅ Ads config fetched successfully');
      } else {
        throw Exception('Failed to fetch ads config');
      }
    } catch (error) {
      print('⚠️ Error fetching ads config: $error');
      print('📱 Loading ads config from local storage...');
      await _loadAdsConfigLocally();
    }
  }

  // Save ads config to local storage
  Future<void> _saveAdsConfigLocally(Map<String, dynamic> adsConfig) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ads_config', jsonEncode(adsConfig));
    } catch (error) {
      print('❌ Error saving ads config locally: $error');
    }
  }

  // Load ads config from local storage
  Future<void> _loadAdsConfigLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final adsConfigString = prefs.getString('ads_config');
      
      if (adsConfigString != null) {
        final adsConfig = jsonDecode(adsConfigString) as Map<String, dynamic>;
        
        // Clear existing configurations
        _adIds.clear();
        
        adsConfig.forEach((adType, config) {
          if (config != null && config['adId'] != null && config['adId'].toString().isNotEmpty) {
            _adIds[adType] = config['adId'];
            _adStatus[adType] = config['isActive'] ?? false;
          } else {
            _adStatus[adType] = false;
          }
        });
        
        print('✅ Ads config loaded from local storage');
      } else {
        print('⚠️ No ads config found in local storage');
      }
    } catch (error) {
      print('❌ Error loading ads config locally: $error');
    }
  }

  // Load all ads
  Future<void> _loadAllAds() async {
    await Future.wait([
      loadBannerAd(),
      loadInterstitialAd(),
      loadNativeAd(),
      loadAppOpenAd(),
      loadRewardedAd(),
      loadRewardedInterstitialAd(),
    ]);
  }

  // Banner Ad Methods (PUBLIC)
  Future<BannerAd?> loadBannerAd() async {
    if (!_adStatus['banner']! || !_adIds.containsKey('banner')) {
      print('⚠️ Banner ad not enabled or no ad ID configured');
      return null;
    }
    
    try {
      _bannerAd = BannerAd(
        adUnitId: _adIds['banner']!,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            _isBannerAdLoaded = true;
            print('✅ Banner ad loaded');
          },
          onAdFailedToLoad: (ad, error) {
            print('❌ Banner ad failed to load: $error');
            ad.dispose();
            _isBannerAdLoaded = false;
          },
        ),
      );
      
      await _bannerAd!.load();
      return _isBannerAdLoaded ? _bannerAd : null;
    } catch (error) {
      print('❌ Error loading banner ad: $error');
      return null;
    }
  }

  BannerAd? get bannerAd => _isBannerAdLoaded ? _bannerAd : null;

  // Interstitial Ad Methods
  Future<void> loadInterstitialAd() async {
    if (!_adStatus['interstitial']! || !_adIds.containsKey('interstitial')) {
      print('⚠️ Interstitial ad not enabled or no ad ID configured');
      return;
    }
    
    try {
      await InterstitialAd.load(
        adUnitId: _adIds['interstitial']!,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _isInterstitialAdLoaded = true;
            print('✅ Interstitial ad loaded');
            
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                _isInterstitialAdLoaded = false;
                loadInterstitialAd(); // Load next ad
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                print('❌ Interstitial ad failed to show: $error');
                ad.dispose();
                _isInterstitialAdLoaded = false;
                loadInterstitialAd(); // Load next ad
              },
            );
          },
          onAdFailedToLoad: (error) {
            print('❌ Interstitial ad failed to load: $error');
            _isInterstitialAdLoaded = false;
          },
        ),
      );
    } catch (error) {
      print('❌ Error loading interstitial ad: $error');
    }
  }

  Future<void> showInterstitialAd() async {
    if (_isInterstitialAdLoaded && _interstitialAd != null) {
      await _interstitialAd!.show();
    } else {
      print('⚠️ Interstitial ad not ready');
      await loadInterstitialAd(); // Try to load if not ready
    }
  }

  // Native Ad Methods (PUBLIC)
  Future<NativeAd?> loadNativeAd() async {
    if (!_adStatus['native']! || !_adIds.containsKey('native')) {
      print('⚠️ Native ad not enabled or no ad ID configured');
      return null;
    }
    
    try {
      _nativeAd = NativeAd(
        adUnitId: _adIds['native']!,
        request: const AdRequest(),
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            _isNativeAdLoaded = true;
            print('✅ Native ad loaded');
          },
          onAdFailedToLoad: (ad, error) {
            print('❌ Native ad failed to load: $error');
            ad.dispose();
            _isNativeAdLoaded = false;
          },
        ),
        nativeTemplateStyle: NativeTemplateStyle(
          templateType: TemplateType.medium,
          mainBackgroundColor: const Color(0xFFFFFFFF),
          cornerRadius: 10.0,
          callToActionTextStyle: NativeTemplateTextStyle(
            textColor: const Color(0xFFFFFFFF),
            backgroundColor: const Color(0xFF667eea),
            style: NativeTemplateFontStyle.bold,
            size: 16.0,
          ),
          primaryTextStyle: NativeTemplateTextStyle(
            textColor: const Color(0xFF000000),
            style: NativeTemplateFontStyle.bold,
            size: 16.0,
          ),
          secondaryTextStyle: NativeTemplateTextStyle(
            textColor: const Color(0xFF666666),
            style: NativeTemplateFontStyle.normal,
            size: 14.0,
          ),
          tertiaryTextStyle: NativeTemplateTextStyle(
            textColor: const Color(0xFF999999),
            style: NativeTemplateFontStyle.normal,
            size: 12.0,
          ),
        ),
      );
      
      await _nativeAd!.load();
      return _isNativeAdLoaded ? _nativeAd : null;
    } catch (error) {
      print('❌ Error loading native ad: $error');
      return null;
    }
  }

  NativeAd? get nativeAd => _isNativeAdLoaded ? _nativeAd : null;

  // App Open Ad Methods
  Future<void> loadAppOpenAd() async {
    if (!_adStatus['appOpen']! || !_adIds.containsKey('appOpen')) {
      print('⚠️ App open ad not enabled or no ad ID configured');
      return;
    }
    
    try {
      await AppOpenAd.load(
        adUnitId: _adIds['appOpen']!,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            _appOpenAd = ad;
            _isAppOpenAdLoaded = true;
            print('✅ App open ad loaded');
            
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                _isAppOpenAdLoaded = false;
                loadAppOpenAd(); // Load next ad
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                print('❌ App open ad failed to show: $error');
                ad.dispose();
                _isAppOpenAdLoaded = false;
                loadAppOpenAd(); // Load next ad
              },
            );
          },
          onAdFailedToLoad: (error) {
            print('❌ App open ad failed to load: $error');
            _isAppOpenAdLoaded = false;
          },
        ),
      );
    } catch (error) {
      print('❌ Error loading app open ad: $error');
    }
  }

  Future<void> showAppOpenAd() async {
    if (_isAppOpenAdLoaded && _appOpenAd != null) {
      await _appOpenAd!.show();
    } else {
      print('⚠️ App open ad not ready');
    }
  }

  // Reward Ad Methods
  Future<void> loadRewardedAd() async {
    if (!_adStatus['rewarded']! || !_adIds.containsKey('rewarded')) {
      print('⚠️ Rewarded ad not enabled or no ad ID configured');
      return;
    }
    
    try {
      await RewardedAd.load(
        adUnitId: _adIds['rewarded']!,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _isRewardedAdLoaded = true;
            print('✅ Rewarded ad loaded');
            
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                _isRewardedAdLoaded = false;
                loadRewardedAd(); // Load next ad
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                print('❌ Rewarded ad failed to show: $error');
                ad.dispose();
                _isRewardedAdLoaded = false;
                loadRewardedAd(); // Load next ad
              },
            );
          },
          onAdFailedToLoad: (error) {
            print('❌ Rewarded ad failed to load: $error');
            _isRewardedAdLoaded = false;
          },
        ),
      );
    } catch (error) {
      print('❌ Error loading rewarded ad: $error');
    }
  }

  Future<bool> showRewardedAd() async {
    if (_isRewardedAdLoaded && _rewardedAd != null) {
      bool rewardEarned = false;
      
      await _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          rewardEarned = true;
          print('✅ User earned reward: ${reward.amount} ${reward.type}');
        },
      );
      
      return rewardEarned;
    } else {
      print('⚠️ Rewarded ad not ready');
      await loadRewardedAd(); // Try to load if not ready
      return false;
    }
  }

  // Rewarded Interstitial Ad Methods
  Future<void> loadRewardedInterstitialAd() async {
    if (!_adStatus['rewardedInterstitial']! || !_adIds.containsKey('rewardedInterstitial')) {
      print('⚠️ Rewarded interstitial ad not enabled or no ad ID configured');
      return;
    }
    
    try {
      await RewardedInterstitialAd.load(
        adUnitId: _adIds['rewardedInterstitial']!,
        request: const AdRequest(),
        rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedInterstitialAd = ad;
            _isRewardedInterstitialAdLoaded = true;
            print('✅ Rewarded interstitial ad loaded');
            
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                _isRewardedInterstitialAdLoaded = false;
                loadRewardedInterstitialAd(); // Load next ad
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                print('❌ Rewarded interstitial ad failed to show: $error');
                ad.dispose();
                _isRewardedInterstitialAdLoaded = false;
                loadRewardedInterstitialAd(); // Load next ad
              },
            );
          },
          onAdFailedToLoad: (error) {
            print('❌ Rewarded interstitial ad failed to load: $error');
            _isRewardedInterstitialAdLoaded = false;
          },
        ),
      );
    } catch (error) {
      print('❌ Error loading rewarded interstitial ad: $error');
    }
  }

  Future<bool> showRewardedInterstitialAd() async {
    if (_isRewardedInterstitialAdLoaded && _rewardedInterstitialAd != null) {
      bool rewardEarned = false;
      
      await _rewardedInterstitialAd!.show(
        onUserEarnedReward: (ad, reward) {
          rewardEarned = true;
          print('✅ User earned reward: ${reward.amount} ${reward.type}');
        },
      );
      
      return rewardEarned;
    } else {
      print('⚠️ Rewarded interstitial ad not ready');
      await loadRewardedInterstitialAd(); // Try to load if not ready
      return false;
    }
  }

  // Refresh ads config (call this periodically or when app resumes)
  Future<void> refreshAdsConfig() async {
    await _fetchAdsConfig();
    if (_adIds.isNotEmpty) {
      await _loadAllAds();
    }
  }

  // Check if specific ad type is enabled
  bool isAdEnabled(String adType) {
    return _adStatus[adType] ?? false && _adIds.containsKey(adType);
  }

  // Get ad ID for specific type
  String? getAdId(String adType) {
    return _adIds[adType];
  }

  // Check if ads are configured
  bool get hasAdsConfigured => _adIds.isNotEmpty;

  // Dispose all ads
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _nativeAd?.dispose();
    _appOpenAd?.dispose();
    _rewardedAd?.dispose();
    _rewardedInterstitialAd?.dispose();
  }
}