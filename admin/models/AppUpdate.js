const mongoose = require('mongoose');

const appUpdateSchema = new mongoose.Schema({
  versionName: {
    type: String,
    required: true,
    unique: true,
    trim: true
  },
  versionCode: {
    type: Number,
    required: true,
    unique: true
  },
  isForceUpdate: {
    type: Boolean,
    default: false
  },
  isNormalUpdate: {
    type: Boolean,
    default: false
  },
  isActive: {
    type: Boolean,
    default: false
  },
  updateMessage: {
    type: String,
    default: null
  },
  updateLink: {
    type: String,
    default: null
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
appUpdateSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

// Static methods
appUpdateSchema.statics.getActiveUpdate = async function() {
  try {
    return await this.findOne({ isActive: true }).sort({ versionCode: -1 });
  } catch (error) {
    throw error;
  }
};

appUpdateSchema.statics.getAllUpdates = async function() {
  try {
    return await this.find({}).sort({ versionCode: -1 });
  } catch (error) {
    throw error;
  }
};

appUpdateSchema.statics.createOrUpdateVersion = async function(updateData) {
  try {
    const { versionName, versionCode } = updateData;
    
    // Check if version already exists
    const existingUpdate = await this.findOne({
      $or: [
        { versionName: versionName },
        { versionCode: versionCode }
      ]
    });
    
    if (existingUpdate) {
      // Update existing version
      Object.assign(existingUpdate, updateData);
      return await existingUpdate.save();
    } else {
      // Create new version
      const newUpdate = new this(updateData);
      return await newUpdate.save();
    }
  } catch (error) {
    throw error;
  }
};

appUpdateSchema.statics.deactivateAllUpdates = async function() {
  try {
    return await this.updateMany({}, { isActive: false });
  } catch (error) {
    throw error;
  }
};

appUpdateSchema.statics.activateUpdate = async function(updateId) {
  try {
    // First deactivate all updates
    await this.deactivateAllUpdates();
    
    // Then activate the selected update
    return await this.findByIdAndUpdate(
      updateId,
      { isActive: true },
      { new: true }
    );
  } catch (error) {
    throw error;
  }
};

appUpdateSchema.statics.deleteUpdate = async function(updateId) {
  try {
    return await this.findByIdAndDelete(updateId);
  } catch (error) {
    throw error;
  }
};

const AppUpdate = mongoose.model('AppUpdate', appUpdateSchema);

module.exports = AppUpdate;