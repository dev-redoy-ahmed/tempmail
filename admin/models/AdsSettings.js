const mongoose = require('mongoose');

const adsSettingsSchema = new mongoose.Schema({
  bannerAd: {
    type: String,
    default: null,
    trim: true
  },
  nativeAd: {
    type: String,
    default: null,
    trim: true
  },
  interstitialAd: {
    type: String,
    default: null,
    trim: true
  },
  rewardedAd: {
    type: String,
    default: null,
    trim: true
  },
  appOpenAd: {
    type: String,
    default: null,
    trim: true
  },
  rewardedInterstitialAd: {
    type: String,
    default: null,
    trim: true
  },
  // Ad status flags
  bannerAdActive: {
    type: Boolean,
    default: false
  },
  nativeAdActive: {
    type: Boolean,
    default: false
  },
  interstitialAdActive: {
    type: Boolean,
    default: false
  },
  rewardedAdActive: {
    type: Boolean,
    default: false
  },
  appOpenAdActive: {
    type: Boolean,
    default: false
  },
  rewardedInterstitialAdActive: {
    type: Boolean,
    default: false
  },
  // Global settings
  adsEnabled: {
    type: Boolean,
    default: true
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
});

// Update the updatedAt field before saving
adsSettingsSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

// Static methods
adsSettingsSchema.statics.getAdsSettings = async function() {
  try {
    let settings = await this.findOne({});
    
    // If no settings exist, create default settings
    if (!settings) {
      settings = new this({});
      await settings.save();
    }
    
    return settings;
  } catch (error) {
    throw error;
  }
};

adsSettingsSchema.statics.updateAdsSettings = async function(updateData) {
  try {
    let settings = await this.findOne({});
    
    if (!settings) {
      // Create new settings if none exist
      settings = new this(updateData);
    } else {
      // Update existing settings
      Object.assign(settings, updateData);
    }
    
    return await settings.save();
  } catch (error) {
    throw error;
  }
};

adsSettingsSchema.statics.updateAdUnit = async function(adType, adId, isActive = true) {
  try {
    const updateData = {};
    updateData[adType] = adId;
    updateData[`${adType}Active`] = isActive;
    
    return await this.updateAdsSettings(updateData);
  } catch (error) {
    throw error;
  }
};

adsSettingsSchema.statics.toggleAdStatus = async function(adType, isActive) {
  try {
    const updateData = {};
    updateData[`${adType}Active`] = isActive;
    
    return await this.updateAdsSettings(updateData);
  } catch (error) {
    throw error;
  }
};

adsSettingsSchema.statics.getFormattedAdsConfig = async function() {
  try {
    const settings = await this.getAdsSettings();
    
    return {
      banner: {
        adId: settings.bannerAd,
        isActive: settings.bannerAdActive
      },
      native: {
        adId: settings.nativeAd,
        isActive: settings.nativeAdActive
      },
      interstitial: {
        adId: settings.interstitialAd,
        isActive: settings.interstitialAdActive
      },
      rewarded: {
        adId: settings.rewardedAd,
        isActive: settings.rewardedAdActive
      },
      appOpen: {
        adId: settings.appOpenAd,
        isActive: settings.appOpenAdActive
      },
      rewardedInterstitial: {
        adId: settings.rewardedInterstitialAd,
        isActive: settings.rewardedInterstitialAdActive
      },
      globalSettings: {
        adsEnabled: settings.adsEnabled
      }
    };
  } catch (error) {
    throw error;
  }
};

const AdsSettings = mongoose.model('AdsSettings', adsSettingsSchema);

module.exports = AdsSettings;