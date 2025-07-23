const mongoose = require('mongoose');

const adsConfigSchema = new mongoose.Schema({
  adType: {
    type: String,
    required: true,
    enum: ['banner', 'interstitial', 'native', 'appopen', 'reward'],
    unique: true
  },
  adId: {
    type: String,
    required: true,
    trim: true
  },
  isActive: {
    type: Boolean,
    default: true
  },
  platform: {
    type: String,
    enum: ['android', 'ios', 'both'],
    default: 'both'
  },
  description: {
    type: String,
    default: ''
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
adsConfigSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

// Static method to get all ads config
adsConfigSchema.statics.getAllAdsConfig = async function() {
  try {
    const ads = await this.find({}).sort({ adType: 1 });
    const adsConfig = {};
    
    ads.forEach(ad => {
      adsConfig[ad.adType] = {
        id: ad.adId,
        isActive: ad.isActive,
        platform: ad.platform,
        description: ad.description
      };
    });
    
    return adsConfig;
  } catch (error) {
    console.error('Error getting ads config:', error);
    return {};
  }
};

// Static method to update or create ad config
adsConfigSchema.statics.updateAdConfig = async function(adType, adId, options = {}) {
  try {
    const updateData = {
      adId: adId,
      ...options,
      updatedAt: Date.now()
    };
    
    const result = await this.findOneAndUpdate(
      { adType: adType },
      updateData,
      { upsert: true, new: true }
    );
    
    return result;
  } catch (error) {
    console.error('Error updating ad config:', error);
    throw error;
  }
};

// Static method to get specific ad config
adsConfigSchema.statics.getAdConfig = async function(adType) {
  try {
    const ad = await this.findOne({ adType: adType });
    if (!ad) return null;
    
    return {
      id: ad.adId,
      isActive: ad.isActive,
      platform: ad.platform,
      description: ad.description
    };
  } catch (error) {
    console.error('Error getting ad config:', error);
    return null;
  }
};

module.exports = mongoose.model('AdsConfig', adsConfigSchema);