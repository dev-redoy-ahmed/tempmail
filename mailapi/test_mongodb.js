const { MongoClient } = require('mongodb');
const axios = require('axios');

// Test MongoDB connection and API endpoints
async function testMongoDB() {
  console.log('🧪 Testing MongoDB Integration...');
  
  try {
    // Test MongoDB connection
    const client = new MongoClient('mongodb://178.128.213.160:27017');
    await client.connect();
    const db = client.db('tempmail');
    
    console.log('✅ MongoDB connection successful');
    
    // Test collections
    const collections = await db.listCollections().toArray();
    console.log('📦 Available collections:', collections.map(c => c.name));
    
    await client.close();
    
    // Test API endpoints
    console.log('\n🌐 Testing API endpoints...');
    
    // Test health endpoint
    try {
      const healthResponse = await axios.get('http://178.128.213.160:3000/health');
      console.log('✅ Health check:', healthResponse.data);
    } catch (error) {
      console.log('❌ Health check failed:', error.message);
    }
    
    // Test email generation with device ID
    try {
      const generateResponse = await axios.get('http://178.128.213.160:3000/generate?deviceId=test123', {
        headers: { 'Authorization': 'supersecretapikey123' }
      });
      console.log('✅ Email generation:', generateResponse.data);
      
      // Test device stats
      const statsResponse = await axios.get('http://178.128.213.160:3000/device/test123/stats/mongo', {
        headers: { 'Authorization': 'supersecretapikey123' }
      });
      console.log('✅ Device stats:', statsResponse.data);
      
    } catch (error) {
      console.log('❌ API test failed:', error.response?.data || error.message);
    }
    
  } catch (error) {
    console.error('❌ Test failed:', error.message);
  }
}

testMongoDB();