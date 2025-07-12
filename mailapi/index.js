const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const redis = require('redis');
const { MongoClient } = require('mongodb');
const cors = require('cors');
const bodyParser = require('body-parser');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const util = require('util');
const writeFile = util.promisify(fs.writeFile);
const appendFile = util.promisify(fs.appendFile);

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: "*" }
});

// === CONFIG ===
const PORT = 3000;

// DUAL DATABASE ARCHITECTURE:
// Redis: Handles received emails, real-time operations, and API responses
const REDIS_URL = process.env.REDIS_URL || 'redis://178.128.213.160:6379';

// MongoDB Atlas: Stores generated/custom emails for app integration and analytics
const MONGODB_URL = process.env.MONGODB_URL || 'mongodb+srv://turbomail:we1we2we3@turbomail.gjohjma.mongodb.net/tempmail?retryWrites=true&w=majority&appName=turbomail';
const MONGODB_DB_NAME = 'tempmail';
let API_KEY = 'supersecretapikey123'; // Made mutable for updates
const ALLOWED_DOMAINS = ['oplex.online', 'worldwides.help', 'agrovia.store', 'tempbox.pro'];
const HARAKA_HOST_LIST_PATH = path.join(__dirname, '../haraka/config/host_list');
const FAILED_EMAILS_LOG = path.join(__dirname, 'failed_emails.log');

// === REDIS SETUP ===
const redisClient = redis.createClient({
  url: 'redis://178.128.213.160:6379'
});

let redisConnected = false;

redisClient.on('error', (err) => {
  console.error('❌ Redis Client Error:', err);
  redisConnected = false;
});

redisClient.on('connect', () => {
  console.log('📦 Connected to Redis');
  redisConnected = true;
});

redisClient.on('ready', () => {
  console.log('✅ Redis is ready');
  redisConnected = true;
});

// Connect to Redis with retry
async function connectRedis() {
  try {
    await redisClient.connect();
    console.log('✅ Successfully connected to Redis');
  } catch (err) {
    console.error('❌ Failed to connect to Redis:', err.message);
    console.log('⚠️  Server will continue without Redis. Some features may be limited.');
    console.log('💡 To fix this, configure Redis on your VPS to accept external connections:');
    console.log('   1. Edit /etc/redis/redis.conf');
    console.log('   2. Change "bind 127.0.0.1" to "bind 0.0.0.0"');
    console.log('   3. Restart Redis: sudo systemctl restart redis-server');
    console.log('   4. Ensure firewall allows port 6379');
  }
}

connectRedis();

// Helper function to check Redis connection
function isRedisConnected() {
  return redisConnected && redisClient.isOpen;
}

// === MONGODB SETUP ===
let mongoClient;
let mongoDb;
let mongoConnected = false;

// Connect to MongoDB
async function connectMongoDB() {
  try {
    mongoClient = new MongoClient(MONGODB_URL);
    await mongoClient.connect();
    mongoDb = mongoClient.db(MONGODB_DB_NAME);
    mongoConnected = true;
    console.log('📦 Connected to MongoDB');
    
    // Create indexes for better performance
    await mongoDb.collection('emails').createIndex({ deviceId: 1, email: 1 });
    await mongoDb.collection('emails').createIndex({ createdAt: 1 }, { expireAfterSeconds: 86400 }); // 24 hours TTL
    
    console.log('✅ MongoDB indexes created successfully');
  } catch (err) {
    console.error('❌ Failed to connect to MongoDB:', err.message);
    console.log('⚠️  Server will continue without MongoDB. Device-based features may be limited.');
    mongoConnected = false;
  }
}

connectMongoDB();

// Helper function to check MongoDB connection
function isMongoConnected() {
  return mongoConnected && mongoClient;
}

// === REDIS DATA STRUCTURE ===
// emails:{email} -> List of email objects (JSON strings)
// device_emails:{deviceId} -> List of email objects (JSON strings)
// generated_emails:{deviceId} -> Set of generated email addresses
// email_stats -> Hash with counters
// device_stats:{deviceId} -> Hash with device statistics

// === MIDDLEWARE ===
app.use(cors());
app.use(bodyParser.json());
app.use(express.static('public'));

// === ROUTES ===

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    redis: isRedisConnected() ? 'connected' : 'disconnected',
    mongodb: isMongoConnected() ? 'connected' : 'disconnected',
    timestamp: new Date().toISOString()
  });
});

// === API KEY PROTECTOR ===
function authKey(req, res, next) {
  if (req.query.key !== API_KEY) {
    return res.status(403).send('Forbidden: Invalid API Key');
  }
  next();
}

// === SOCKET.IO CONNECTION ===
io.on('connection', (socket) => {
  console.log('👤 User connected via WebSocket');
});

// === HELPER FUNCTIONS ===
async function generateUniqueId() {
  return crypto.randomBytes(12).toString('hex');
}

async function incrementCounter(key) {
  if (!isRedisConnected()) {
    console.log('⚠️  Redis not connected, counter not incremented:', key);
    return;
  }
  
  try {
    await redisClient.hIncrBy('email_stats', key, 1);
  } catch (err) {
    console.error('Error incrementing counter:', err);
  }
}

async function getCounter(key) {
  if (!isRedisConnected()) {
    console.log('⚠️  Redis not connected, returning 0 for counter:', key);
    return 0;
  }
  
  try {
    const count = await redisClient.hGet('email_stats', key);
    return parseInt(count) || 0;
  } catch (err) {
    console.error('Error getting counter:', err);
    return 0;
  }
}

// === BACKUP FUNCTIONS ===
async function logFailedEmail(mail, error, timestamp) {
  try {
    const logEntry = {
      timestamp,
      mail,
      error: error.message,
      status: 'failed_to_save'
    };
    
    await appendFile(FAILED_EMAILS_LOG, JSON.stringify(logEntry) + '\n');
    console.log('📝 Failed email logged to backup file');
  } catch (logErr) {
    console.error('❌ Failed to log failed email:', logErr.message);
  }
}

// Function to retry failed emails from log
async function retryFailedEmails() {
  try {
    if (!fs.existsSync(FAILED_EMAILS_LOG)) {
      return { message: 'No failed emails log found' };
    }
    
    const logContent = fs.readFileSync(FAILED_EMAILS_LOG, 'utf8');
    const lines = logContent.trim().split('\n').filter(line => line);
    
    let retried = 0;
    let successful = 0;
    
    for (const line of lines) {
      try {
        const logEntry = JSON.parse(line);
        const emailData = {
          id: await generateUniqueId(),
          ...logEntry.mail,
          date: logEntry.mail.date || new Date().toISOString()
        };
        
        // Store in Redis
        const recipients = Array.isArray(logEntry.mail.to) ? logEntry.mail.to : [logEntry.mail.to];
        for (const recipient of recipients) {
          if (recipient) {
            await redisClient.lPush(`emails:${recipient}`, JSON.stringify(emailData));
          }
        }
        
        await incrementCounter('total_emails');
        successful++;
      } catch (err) {
        console.error('❌ Retry failed for email:', err.message);
      }
      retried++;
    }
    
    // Clear the log file after processing
    if (successful > 0) {
      await writeFile(FAILED_EMAILS_LOG, '');
    }
    
    return { retried, successful, failed: retried - successful };
  } catch (err) {
    console.error('❌ Error retrying failed emails:', err.message);
    return { error: err.message };
  }
}

// === 📥 RECEIVE MAIL FROM HARAKA ===
app.post('/api/receive-mail', authKey, async (req, res) => {
  const mail = req.body;
  
  try {
    // Log raw email data for debugging
    console.log('📧 Raw email received:', {
      from: mail.from,
      to: mail.to,
      messageId: mail.messageId,
      timestamp: mail.timestamp,
      rawSize: mail.raw ? mail.raw.length : 0,
      hasRawData: !!mail.raw
    });
    
    // Additional validation
    if (!mail.raw || mail.raw.length === 0) {
      console.warn('⚠️ Warning: No raw email data received or empty raw data');
    } else {
      console.log(`✅ Raw email data successfully received: ${mail.raw.length} bytes`);
    }
    
    // Parse basic email information from raw content
    let subject = '(no subject)';
    let body = '';
    
    if (mail.raw) {
      const lines = mail.raw.split('\n');
      let inHeaders = true;
      
      for (const line of lines) {
        if (inHeaders) {
          if (line.trim() === '') {
            inHeaders = false;
            continue;
          }
          if (line.startsWith('Subject: ')) {
            subject = line.substring(9).trim();
          }
        } else {
          body += line + '\n';
        }
      }
      body = body.trim();
    }
    
    // Store received email in Redis for each recipient
    const recipients = Array.isArray(mail.to) ? mail.to : [mail.to];
    
    for (const recipient of recipients) {
      if (recipient) {
        // Find devices that have generated this email
        const deviceIds = await redisClient.sMembers(`email_devices:${recipient}`);
        
        console.log(`📧 Found ${deviceIds.length} devices with email: ${recipient}`);
        
        for (const deviceId of deviceIds) {
          const emailData = {
            id: await generateUniqueId(),
            deviceId: deviceId,
            email: recipient,
            type: 'received',
            from: mail.from || '',
            to: recipient,
            subject: subject,
            body: body,
            raw: mail.raw, // Store complete raw email content
            messageId: mail.messageId,
            timestamp: mail.timestamp || new Date().toISOString(),
            received: new Date().toISOString(),
            createdAt: new Date().toISOString()
          };
          
          // Store in device emails list
          await redisClient.lPush(`device_emails:${deviceId}`, JSON.stringify(emailData));
          
          // Store in general emails list for the recipient
          await redisClient.lPush(`emails:${recipient}`, JSON.stringify(emailData));
          
          // Update device statistics
          await redisClient.hIncrBy(`device_stats:${deviceId}`, 'received_count', 1);
          
          console.log(`💾 Email stored in Redis for device: ${deviceId}`);
        }
        
        // If no devices found with this email, still store it for debugging
        if (deviceIds.length === 0) {
          console.log(`⚠️ No devices found for email: ${recipient}, storing anyway for debugging`);
          const debugEmailData = {
            id: await generateUniqueId(),
            deviceId: 'unknown',
            email: recipient,
            type: 'received',
            from: mail.from || '',
            to: recipient,
            subject: subject,
            body: body,
            raw: mail.raw,
            messageId: mail.messageId,
            timestamp: mail.timestamp || new Date().toISOString(),
            received: new Date().toISOString(),
            createdAt: new Date().toISOString()
          };
          
          await redisClient.lPush(`emails:${recipient}`, JSON.stringify(debugEmailData));
          console.log(`💾 Debug email stored for unknown device`);
        }
      }
    }
    
    // Update global statistics
    await incrementCounter('total_emails');
    await incrementCounter('received_emails');
    
    // 🚀 Send complete raw email data to frontend via real-time socket
    io.emit('new_mail', {
      from: mail.from,
      to: mail.to,
      subject: subject,
      body: body,
      raw: mail.raw, // 100% raw email content as received
      timestamp: mail.timestamp || new Date().toISOString(),
      messageId: mail.messageId,
      received: new Date().toISOString()
    });
    
    console.log('📡 Raw email data stored in Redis and sent to frontend via socket');
    
    res.json({ 
      success: true, 
      message: 'Raw email data stored in database and sent via socket',
      messageId: mail.messageId,
      recipients: recipients.length
    });
    
  } catch (err) {
    console.error('❌ Error processing raw email:', err);
    
    // Log failed email for retry
    await logFailedEmail(mail, err, new Date().toISOString());
    
    res.status(500).json({ 
      success: false, 
      error: 'Error processing raw email',
      message: err.message 
    });
  }
});

// === 📩 RANDOM EMAIL GENERATOR ===
app.get('/generate', authKey, async (req, res) => {
  const { deviceId } = req.query;
  let email;
  let attempts = 0;
  const maxAttempts = 10;
  
  // Keep generating until we find a unique email for this device
  do {
    const randomUser = crypto.randomBytes(4).toString('hex');
    const domain = ALLOWED_DOMAINS[Math.floor(Math.random() * ALLOWED_DOMAINS.length)];
    email = `${randomUser}@${domain}`;
    attempts++;
    
    // Check if email already exists for this device
    if (deviceId) {
      const exists = await redisClient.sIsMember(`generated_emails:${deviceId}`, email);
      
      if (!exists) {
        // Email is unique, store it and break
        try {
          const emailData = {
            id: await generateUniqueId(),
            deviceId,
            email,
            type: 'generated',
            createdAt: new Date().toISOString()
          };
          
          // Add to generated emails set for this device
          await redisClient.sAdd(`generated_emails:${deviceId}`, email);
          
          // Add to device emails list
          await redisClient.lPush(`device_emails:${deviceId}`, JSON.stringify(emailData));
          
          // Map email to device for incoming mail routing
          await redisClient.sAdd(`email_devices:${email}`, deviceId);
          
          // Update device statistics
          await redisClient.hIncrBy(`device_stats:${deviceId}`, 'generated_count', 1);
          
          // Store in MongoDB for device-based management
          if (isMongoConnected()) {
            const mongoEmailDoc = {
              email: email,
              deviceId: deviceId,
              type: 'generated',
              createdAt: new Date(),
              domain: domain,
              username: randomUser,
              emailCount: 0,
              lastActivity: new Date()
            };
            
            await mongoDb.collection('emails').insertOne(mongoEmailDoc);
            console.log(`📧 Generated email ${email} for device ${deviceId} stored in MongoDB`);
          }
          
          // Update global statistics
          await incrementCounter('generated_emails');
          
          break;
        } catch (err) {
          console.error('Error storing generated email:', err);
        }
      }
    } else {
      // No device ID provided, just return the email
      break;
    }
  } while (attempts < maxAttempts);
  
  res.send({ email });
});

// === ✍️ MANUAL EMAIL GENERATOR ===
app.get('/generate/manual', authKey, async (req, res) => {
  const { username, domain, deviceId } = req.query;
  if (!username || !domain) return res.status(400).send('username and domain required');
  if (!ALLOWED_DOMAINS.includes(domain)) return res.status(400).send('domain not allowed');
  
  const email = `${username}@${domain}`;
  
  // Check if email already exists for this device
  if (deviceId) {
    try {
      const exists = await redisClient.sIsMember(`generated_emails:${deviceId}`, email);
      
      if (exists) {
        return res.status(409).json({
          error: 'Email already exists',
          message: 'This email name already exists for your device. Please use a different name.',
          email: email
        });
      }
      
      // Email is unique, store it
      const emailData = {
        id: await generateUniqueId(),
        deviceId,
        email,
        type: 'generated',
        createdAt: new Date().toISOString()
      };
      
      // Add to generated emails set for this device
      await redisClient.sAdd(`generated_emails:${deviceId}`, email);
      
      // Add to device emails list
      await redisClient.lPush(`device_emails:${deviceId}`, JSON.stringify(emailData));
      
      // Map email to device for incoming mail routing
      await redisClient.sAdd(`email_devices:${email}`, deviceId);
      
      // Update device statistics
      await redisClient.hIncrBy(`device_stats:${deviceId}`, 'generated_count', 1);
      
      // Store in MongoDB for device-based management
      if (isMongoConnected()) {
        const mongoEmailDoc = {
          email: email,
          deviceId: deviceId,
          type: 'generated',
          createdAt: new Date(),
          domain: domain,
          username: username,
          emailCount: 0,
          lastActivity: new Date()
        };
        
        await mongoDb.collection('emails').insertOne(mongoEmailDoc);
        console.log(`📧 Manual email ${email} for device ${deviceId} stored in MongoDB`);
      }
      
      // Update global statistics
      await incrementCounter('generated_emails');
      
    } catch (err) {
      console.error('Error storing generated email:', err);
      return res.status(500).send('Error creating email');
    }
  }
  
  res.send({ email });
});

// === 📬 GET INBOX FOR EMAIL ===
app.get('/inbox/:email', authKey, async (req, res) => {
  const email = req.params.email;
  
  if (!isRedisConnected()) {
    console.log('⚠️  Redis not connected, returning empty inbox for:', email);
    return res.send([]);
  }
  
  try {
    const emailStrings = await redisClient.lRange(`emails:${email}`, 0, -1);
    const messages = emailStrings.map(str => JSON.parse(str)).sort((a, b) => new Date(b.date || b.timestamp) - new Date(a.date || a.timestamp));
    res.send(messages);
  } catch (err) {
    console.error('Error fetching inbox:', err);
    res.status(500).send('Error fetching inbox');
  }
});

// === 📄 GET SPECIFIC MESSAGE BY INDEX ===
app.get('/inbox/:email/:index', authKey, async (req, res) => {
  const email = req.params.email;
  const index = parseInt(req.params.index);
  
  if (!isRedisConnected()) {
    console.log('⚠️  Redis not connected, cannot fetch message for:', email);
    return res.status(503).send('Database not available');
  }
  
  try {
    const emailStrings = await redisClient.lRange(`emails:${email}`, 0, -1);
    const messages = emailStrings.map(str => JSON.parse(str)).sort((a, b) => new Date(b.date || b.timestamp) - new Date(a.date || a.timestamp));
    if (index < 0 || index >= messages.length) {
      return res.status(404).send('Message not found');
    }
    res.send(messages[index]);
  } catch (err) {
    console.error('Error fetching message:', err);
    res.status(500).send('Error fetching message');
  }
});

// Get emails by device ID from MongoDB
app.get('/device/:deviceId/emails/mongo', authKey, async (req, res) => {
  try {
    const { deviceId } = req.params;
    const { limit = 50, skip = 0 } = req.query;
    
    if (!isMongoConnected()) {
      return res.status(503).json({ error: 'MongoDB connection unavailable' });
    }
    
    const emails = await mongoDb.collection('emails')
      .find({ deviceId: deviceId })
      .sort({ createdAt: -1 })
      .limit(parseInt(limit))
      .skip(parseInt(skip))
      .toArray();
    
    res.json({ emails, deviceId, total: emails.length });
  } catch (error) {
    console.error('Error fetching device emails:', error);
    res.status(500).json({ error: 'Failed to fetch device emails' });
  }
});

// Get device statistics from MongoDB
app.get('/device/:deviceId/stats/mongo', authKey, async (req, res) => {
  try {
    const { deviceId } = req.params;
    
    if (!isMongoConnected()) {
      return res.status(503).json({ error: 'MongoDB connection unavailable' });
    }
    
    const totalEmails = await mongoDb.collection('emails').countDocuments({ deviceId: deviceId });
    const recentEmails = await mongoDb.collection('emails')
      .find({ deviceId: deviceId })
      .sort({ createdAt: -1 })
      .limit(5)
      .toArray();
    
    const stats = {
      deviceId: deviceId,
      totalEmails: totalEmails,
      recentEmails: recentEmails,
      lastActivity: recentEmails.length > 0 ? recentEmails[0].lastActivity : null
    };
    
    res.json(stats);
  } catch (error) {
    console.error('Error fetching device stats:', error);
    res.status(500).json({ error: 'Failed to fetch device stats' });
  }
});

// Delete device emails from MongoDB
app.delete('/device/:deviceId/emails/mongo', authKey, async (req, res) => {
  try {
    const { deviceId } = req.params;
    
    if (!isMongoConnected()) {
      return res.status(503).json({ error: 'MongoDB connection unavailable' });
    }
    
    const result = await mongoDb.collection('emails').deleteMany({ deviceId: deviceId });
    
    res.json({ 
      message: `Deleted ${result.deletedCount} emails for device ${deviceId}`,
      deletedCount: result.deletedCount 
    });
  } catch (error) {
    console.error('Error deleting device emails:', error);
    res.status(500).json({ error: 'Failed to delete device emails' });
  }
});

// === 🧹 DELETE ALL MESSAGES ===
app.delete('/delete/:email', authKey, async (req, res) => {
  const email = req.params.email;
  
  if (!isRedisConnected()) {
    console.log('⚠️  Redis not connected, cannot delete messages for:', email);
    return res.status(503).send('Database not available');
  }
  
  try {
    await redisClient.del(`emails:${email}`);
    res.send('🗑️ All messages deleted');
  } catch (err) {
    console.error('Error deleting messages:', err);
    res.status(500).send('Error deleting messages');
  }
});

// === ❌ DELETE SPECIFIC MESSAGE ===
app.delete('/delete/:email/:index', authKey, async (req, res) => {
  const email = req.params.email;
  const index = parseInt(req.params.index);
  
  if (!isRedisConnected()) {
    console.log('⚠️  Redis not connected, cannot delete message for:', email);
    return res.status(503).send('Database not available');
  }
  
  try {
    const emailStrings = await redisClient.lRange(`emails:${email}`, 0, -1);
    const messages = emailStrings.map(str => JSON.parse(str)).sort((a, b) => new Date(b.date || b.timestamp) - new Date(a.date || a.timestamp));
    if (index < 0 || index >= messages.length) {
      return res.status(404).send('Message not found');
    }
    
    // Remove the specific message
    const messageToDelete = messages[index];
    await redisClient.lRem(`emails:${email}`, 1, JSON.stringify(messageToDelete));
    res.send('🗑️ Message deleted');
  } catch (err) {
    console.error('Error deleting message:', err);
    res.status(500).send('Error deleting message');
  }
});

// === 📱 DEVICE-BASED EMAIL MANAGEMENT ===

// Get all emails for a device
app.get('/device/:deviceId/emails', authKey, async (req, res) => {
  const deviceId = req.params.deviceId;
  try {
    const emailStrings = await redisClient.lRange(`device_emails:${deviceId}`, 0, -1);
    const emails = emailStrings.map(str => JSON.parse(str)).sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    res.json(emails);
  } catch (err) {
    console.error('Error fetching device emails:', err);
    res.status(500).send('Error fetching emails');
  }
});

// Get generated emails for a device
app.get('/device/:deviceId/generated', authKey, async (req, res) => {
  const deviceId = req.params.deviceId;
  try {
    const emailStrings = await redisClient.lRange(`device_emails:${deviceId}`, 0, -1);
    const emails = emailStrings.map(str => JSON.parse(str))
      .filter(email => email.type === 'generated')
      .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    res.json(emails);
  } catch (err) {
    console.error('Error fetching generated emails:', err);
    res.status(500).send('Error fetching generated emails');
  }
});

// Get received emails for a device
app.get('/device/:deviceId/received', authKey, async (req, res) => {
  const deviceId = req.params.deviceId;
  try {
    const emailStrings = await redisClient.lRange(`device_emails:${deviceId}`, 0, -1);
    const emails = emailStrings.map(str => JSON.parse(str))
      .filter(email => email.type === 'received')
      .sort((a, b) => new Date(b.receivedAt || b.received || b.createdAt) - new Date(a.receivedAt || a.received || a.createdAt));
    res.json(emails);
  } catch (err) {
    console.error('Error fetching received emails:', err);
    res.status(500).send('Error fetching received emails');
  }
});

// Get received emails for a specific generated email
app.get('/device/:deviceId/inbox/:email', authKey, async (req, res) => {
  const { deviceId, email } = req.params;
  try {
    const emailStrings = await redisClient.lRange(`device_emails:${deviceId}`, 0, -1);
    const emails = emailStrings.map(str => JSON.parse(str))
      .filter(emailObj => emailObj.email === email && emailObj.type === 'received')
      .sort((a, b) => new Date(b.receivedAt || b.received || b.createdAt) - new Date(a.receivedAt || a.received || a.createdAt));
    res.json(emails);
  } catch (err) {
    console.error('Error fetching inbox emails:', err);
    res.status(500).send('Error fetching inbox emails');
  }
});

// Delete all emails for a device
app.delete('/device/:deviceId/clear', authKey, async (req, res) => {
  const deviceId = req.params.deviceId;
  try {
    // Get all generated emails for this device to clean up mappings
    const generatedEmails = await redisClient.sMembers(`generated_emails:${deviceId}`);
    
    // Remove device from email mappings
    for (const email of generatedEmails) {
      await redisClient.sRem(`email_devices:${email}`, deviceId);
    }
    
    // Delete all device data
    await redisClient.del(`device_emails:${deviceId}`);
    await redisClient.del(`generated_emails:${deviceId}`);
    await redisClient.del(`device_stats:${deviceId}`);
    
    res.send('🗑️ All device emails deleted');
  } catch (err) {
    console.error('Error clearing device emails:', err);
    res.status(500).send('Error clearing emails');
  }
});

// Delete a specific email for a device
app.delete('/device/:deviceId/email/:emailId', authKey, async (req, res) => {
  const { deviceId, emailId } = req.params;
  try {
    const emailStrings = await redisClient.lRange(`device_emails:${deviceId}`, 0, -1);
    const emails = emailStrings.map(str => JSON.parse(str));
    const emailToDelete = emails.find(email => email.id === emailId);
    
    if (!emailToDelete) {
      return res.status(404).send('Email not found');
    }
    
    // Remove from device emails list
    await redisClient.lRem(`device_emails:${deviceId}`, 1, JSON.stringify(emailToDelete));
    
    // If it's a generated email, clean up mappings
    if (emailToDelete.type === 'generated') {
      await redisClient.sRem(`generated_emails:${deviceId}`, emailToDelete.email);
      await redisClient.sRem(`email_devices:${emailToDelete.email}`, deviceId);
    }
    
    res.send('🗑️ Email deleted');
  } catch (err) {
    console.error('Error deleting email:', err);
    res.status(500).send('Error deleting email');
  }
});

// === 🔧 ADMIN PANEL ROUTES ===

// Serve admin panel
app.get('/admin', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'admin.html'));
});

// Get domains from Haraka host_list
app.get('/admin/domains', authKey, (req, res) => {
  try {
    if (fs.existsSync(HARAKA_HOST_LIST_PATH)) {
      const hostListContent = fs.readFileSync(HARAKA_HOST_LIST_PATH, 'utf8');
      const domains = hostListContent
        .split('\n')
        .map(line => line.trim())
        .filter(line => line && !line.startsWith('#'));
      res.json(domains);
    } else {
      res.json([]);
    }
  } catch (err) {
    console.error('Error reading host_list:', err);
    res.status(500).send('Error reading domains');
  }
});

// Add domain to Haraka host_list
app.post('/admin/domains/add', authKey, (req, res) => {
  const { domain } = req.body;
  
  if (!domain) {
    return res.status(400).send('Domain is required');
  }
  
  try {
    let hostListContent = '';
    if (fs.existsSync(HARAKA_HOST_LIST_PATH)) {
      hostListContent = fs.readFileSync(HARAKA_HOST_LIST_PATH, 'utf8');
    }
    
    const domains = hostListContent
      .split('\n')
      .map(line => line.trim())
      .filter(line => line && !line.startsWith('#'));
    
    if (domains.includes(domain)) {
      return res.status(400).send('Domain already exists');
    }
    
    // Add domain to the list
    domains.push(domain);
    
    // Write back to file
    const newContent = domains.join('\n') + '\n';
    fs.writeFileSync(HARAKA_HOST_LIST_PATH, newContent, 'utf8');
    
    console.log(`✅ Domain '${domain}' added to host_list`);
    res.send(`✅ Domain '${domain}' added successfully`);
  } catch (err) {
    console.error('Error adding domain:', err);
    res.status(500).send('Error adding domain');
  }
});

// Delete domain from Haraka host_list
app.delete('/admin/domains/delete', authKey, (req, res) => {
  const { domain } = req.body;
  
  if (!domain) {
    return res.status(400).send('Domain is required');
  }
  
  try {
    if (!fs.existsSync(HARAKA_HOST_LIST_PATH)) {
      return res.status(404).send('Host list file not found');
    }
    
    const hostListContent = fs.readFileSync(HARAKA_HOST_LIST_PATH, 'utf8');
    const domains = hostListContent
      .split('\n')
      .map(line => line.trim())
      .filter(line => line && !line.startsWith('#'));
    
    const filteredDomains = domains.filter(d => d !== domain);
    
    if (domains.length === filteredDomains.length) {
      return res.status(404).send('Domain not found');
    }
    
    // Write back to file
    const newContent = filteredDomains.join('\n') + '\n';
    fs.writeFileSync(HARAKA_HOST_LIST_PATH, newContent, 'utf8');
    
    console.log(`🗑️ Domain '${domain}' removed from host_list`);
    res.send('Domain deleted successfully');
  } catch (err) {
    console.error('Error deleting domain:', err);
    res.status(500).send('Error deleting domain');
  }
});

// === 🔍 SYSTEM MONITORING & RECOVERY ENDPOINTS ===

// System health check
app.get('/admin/health', authKey, async (req, res) => {
  try {
    const health = {
      timestamp: new Date().toISOString(),
      database: 'unknown',
      failedEmailsLog: fs.existsSync(FAILED_EMAILS_LOG),
      totalEmails: 0,
      totalDeviceEmails: 0,
      connectedClients: io.engine.clientsCount || 0
    };
    
    // Check Redis connection
    try {
      await redisClient.ping();
      health.database = 'connected';
      
      // Get email counts
      health.totalEmails = await getCounter('total_emails');
      health.totalDeviceEmails = await getCounter('generated_emails');
    } catch (dbErr) {
      health.database = 'disconnected';
      health.databaseError = dbErr.message;
    }
    
    // Check failed emails log size
    if (health.failedEmailsLog) {
      try {
        const stats = fs.statSync(FAILED_EMAILS_LOG);
        health.failedEmailsLogSize = stats.size;
        
        if (stats.size > 0) {
          const logContent = fs.readFileSync(FAILED_EMAILS_LOG, 'utf8');
          const lines = logContent.trim().split('\n').filter(line => line);
          health.failedEmailsCount = lines.length;
        } else {
          health.failedEmailsCount = 0;
        }
      } catch (logErr) {
        health.failedEmailsLogError = logErr.message;
      }
    }
    
    res.json(health);
  } catch (err) {
    console.error('Error checking system health:', err);
    res.status(500).json({ error: 'Error checking system health', message: err.message });
  }
});

// Retry failed emails
app.post('/admin/retry-failed-emails', authKey, async (req, res) => {
  try {
    const result = await retryFailedEmails();
    res.json({
      success: true,
      result,
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error('Error retrying failed emails:', err);
    res.status(500).json({ error: 'Error retrying failed emails', message: err.message });
  }
});

// Get failed emails log
app.get('/admin/failed-emails', authKey, (req, res) => {
  try {
    if (!fs.existsSync(FAILED_EMAILS_LOG)) {
      return res.json({ emails: [], count: 0 });
    }
    
    const logContent = fs.readFileSync(FAILED_EMAILS_LOG, 'utf8');
    const lines = logContent.trim().split('\n').filter(line => line);
    
    const emails = lines.map(line => {
      try {
        return JSON.parse(line);
      } catch (parseErr) {
        return { error: 'Invalid JSON', line };
      }
    });
    
    res.json({ emails, count: emails.length });
  } catch (err) {
    console.error('Error reading failed emails log:', err);
    res.status(500).json({ error: 'Error reading failed emails log', message: err.message });
  }
});

// Clear failed emails log
app.delete('/admin/failed-emails', authKey, async (req, res) => {
  try {
    await writeFile(FAILED_EMAILS_LOG, '');
    res.json({ success: true, message: 'Failed emails log cleared', timestamp: new Date().toISOString() });
  } catch (err) {
    console.error('Error clearing failed emails log:', err);
    res.status(500).json({ error: 'Error clearing failed emails log', message: err.message });
  }
});

// Get system statistics
app.get('/admin/stats', authKey, async (req, res) => {
  try {
    // Get unique device count
    const deviceKeys = await redisClient.keys('device_stats:*');
    const uniqueDevices = deviceKeys.length;
    
    let mongoStatus = { connected: false };
    if (isMongoConnected()) {
      try {
        const emailsCount = await mongoDb.collection('emails').countDocuments();
        mongoStatus = {
          connected: true,
          collections: {
            emails: emailsCount
          }
        };
      } catch (error) {
        mongoStatus = { connected: false, error: error.message };
      }
    } else {
      mongoStatus = { connected: false, error: 'Not connected' };
    }
    
    const stats = {
      timestamp: new Date().toISOString(),
      emails: {
        total: await getCounter('total_emails'),
        today: 0 // Redis doesn't have date-based queries, would need additional implementation
      },
      deviceEmails: {
        total: await getCounter('total_emails'),
        generated: await getCounter('generated_emails'),
        received: await getCounter('received_emails'),
        uniqueDevices: uniqueDevices
      },
      domains: ALLOWED_DOMAINS.length,
      connectedClients: io.engine.clientsCount || 0,
      mongodb: mongoStatus
    };
    
    res.json(stats);
   } catch (err) {
     console.error('Error getting system stats:', err);
     res.status(500).json({ error: 'Error getting system stats', message: err.message });
   }
 });

// Get recent emails for monitoring
app.get('/admin/recent-emails', authKey, async (req, res) => {
  try {
    // Get all device keys and collect recent received emails
    const deviceKeys = await redisClient.keys('device_emails:*');
    let recentEmails = [];
    
    for (const deviceKey of deviceKeys.slice(0, 20)) { // Limit to first 20 devices for performance
      const emailStrings = await redisClient.lRange(deviceKey, 0, 10); // Get last 10 emails per device
      const emails = emailStrings.map(str => {
        try {
          return JSON.parse(str);
        } catch (err) {
          return null;
        }
      }).filter(email => email && email.type === 'received');
      
      recentEmails = recentEmails.concat(emails);
    }
    
    // Sort by creation time and limit to 50
    recentEmails.sort((a, b) => new Date(b.createdAt || b.received) - new Date(a.createdAt || a.received));
    recentEmails = recentEmails.slice(0, 50);
    
    res.json(recentEmails);
  } catch (err) {
    console.error('Error getting recent emails:', err);
    res.status(500).send('Error getting recent emails');
  }
});

// Get detailed email with raw data
app.get('/admin/email/:emailId/raw', authKey, async (req, res) => {
  try {
    const emailId = req.params.emailId;
    
    // Search through all device emails to find the email with this ID
    const deviceKeys = await redisClient.keys('device_emails:*');
    let foundEmail = null;
    
    for (const deviceKey of deviceKeys) {
      const emailStrings = await redisClient.lRange(deviceKey, 0, -1);
      const emails = emailStrings.map(str => {
        try {
          return JSON.parse(str);
        } catch (err) {
          return null;
        }
      }).filter(email => email);
      
      foundEmail = emails.find(email => email.id === emailId);
      if (foundEmail) break;
    }
    
    if (!foundEmail) {
      return res.status(404).json({ error: 'Email not found' });
    }
    
    res.json({
      id: foundEmail.id,
      from: foundEmail.from,
      to: foundEmail.to,
      subject: foundEmail.subject,
      body: foundEmail.body,
      raw: foundEmail.raw,
      timestamp: foundEmail.timestamp,
      received: foundEmail.received,
      deviceId: foundEmail.deviceId,
      messageId: foundEmail.messageId
    });
  } catch (err) {
    console.error('Error getting email raw data:', err);
    res.status(500).json({ error: 'Error getting email raw data' });
  }
});

// Device analytics endpoint
app.get('/api/device-emails/analytics', authKey, async (req, res) => {
  try {
    const deviceKeys = await redisClient.keys('device_stats:*');
    const deviceStats = [];
    
    for (const deviceKey of deviceKeys) {
      const deviceId = deviceKey.replace('device_stats:', '');
      const stats = await redisClient.hGetAll(deviceKey);
      
      // Get last activity from device emails
      const emailStrings = await redisClient.lRange(`device_emails:${deviceId}`, 0, 0);
      let lastActivity = null;
      if (emailStrings.length > 0) {
        try {
          const lastEmail = JSON.parse(emailStrings[0]);
          lastActivity = lastEmail.createdAt;
        } catch (err) {
          // Ignore parse errors
        }
      }
      
      deviceStats.push({
        deviceId: deviceId,
        generatedCount: parseInt(stats.generated_count) || 0,
        receivedCount: parseInt(stats.received_count) || 0,
        lastActivity: lastActivity,
        totalEmails: (parseInt(stats.generated_count) || 0) + (parseInt(stats.received_count) || 0)
      });
    }
    
    // Sort by total emails
    deviceStats.sort((a, b) => b.totalEmails - a.totalEmails);
    
    res.json(deviceStats);
  } catch (err) {
    console.error('Error getting device analytics:', err);
    res.status(500).send('Error getting device analytics');
  }
});

// Activity logs endpoint
app.get('/admin/activity', authKey, async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 50;
    const filter = req.query.filter || 'all';
    
    let activities = [];
    
    // Get recent device emails
    const deviceKeys = await redisClient.keys('device_emails:*');
    
    for (const deviceKey of deviceKeys.slice(0, 20)) { // Limit for performance
      const deviceId = deviceKey.replace('device_emails:', '');
      const emailStrings = await redisClient.lRange(deviceKey, 0, limit);
      
      const emails = emailStrings.map(str => {
        try {
          return JSON.parse(str);
        } catch (err) {
          return null;
        }
      }).filter(email => email);
      
      // Filter emails based on type
      const filteredEmails = filter === 'all' ? emails : 
        filter === 'generated' ? emails.filter(e => e.type === 'generated') :
        filter === 'received' ? emails.filter(e => e.type === 'received') : emails;
      
      // Transform to activity format
      const emailActivities = filteredEmails.map(email => ({
        type: email.type,
        description: email.type === 'generated' 
          ? `Email ${email.email} generated by device ${email.deviceId}`
          : `Email received for ${email.email} (device ${email.deviceId})`,
        timestamp: email.createdAt || email.received,
        deviceId: email.deviceId,
        email: email.email
      }));
      
      activities = activities.concat(emailActivities);
    }
    
    // Sort by timestamp
    activities.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));
    
    res.json(activities.slice(0, limit));
  } catch (err) {
    console.error('Error getting activity logs:', err);
    res.status(500).json({ error: 'Error getting activity logs', message: err.message });
  }
});

// === 🔑 API KEY MANAGEMENT ===

// Get current API key
app.get('/admin/current-api-key', authKey, (req, res) => {
  res.json({ apiKey: API_KEY });
});

// Update API key
app.post('/admin/update-api-key', authKey, (req, res) => {
  const { newApiKey } = req.body;
  
  if (!newApiKey) {
    return res.status(400).send('New API key is required');
  }
  
  if (newApiKey.length < 8) {
    return res.status(400).send('API key must be at least 8 characters long');
  }
  
  // Update the API key
  API_KEY = newApiKey;
  
  console.log(`🔑 API key updated successfully`);
  res.send('API key updated successfully');
});

// === 🧪 SYSTEM TESTING ===

// Test Redis connection
app.get('/admin/test-redis', authKey, async (req, res) => {
  try {
    // Try to perform a simple Redis operation
    await redisClient.ping();
    res.json({ status: 'connected', message: 'Redis connection is healthy' });
  } catch (err) {
    console.error('Redis test failed:', err);
    res.status(500).json({ status: 'error', message: err.message });
  }
});

// Test Haraka integration
app.get('/admin/test-haraka', authKey, (req, res) => {
  try {
    // Check if Haraka host_list file exists and is readable
    if (fs.existsSync(HARAKA_HOST_LIST_PATH)) {
      const stats = fs.statSync(HARAKA_HOST_LIST_PATH);
      if (stats.isFile()) {
        // Try to read the file
        const content = fs.readFileSync(HARAKA_HOST_LIST_PATH, 'utf8');
        const domains = content.split('\n').filter(line => line.trim() && !line.startsWith('#'));
        res.json({ 
          status: 'active', 
          message: `Haraka integration active with ${domains.length} domains`,
          domains: domains.length
        });
      } else {
        res.status(500).json({ status: 'error', message: 'Host list path is not a file' });
      }
    } else {
      res.status(500).json({ status: 'error', message: 'Haraka host_list file not found' });
    }
  } catch (err) {
    console.error('Haraka test failed:', err);
    res.status(500).json({ status: 'error', message: err.message });
  }
});

// Test all system components
app.get('/admin/test-system', authKey, async (req, res) => {
  const results = {
    timestamp: new Date().toISOString(),
    tests: []
  };
  
  // Test Redis
  try {
    await redisClient.ping();
    results.tests.push({ component: 'Redis', status: 'success', message: 'Connected' });
  } catch (err) {
    results.tests.push({ component: 'Redis', status: 'error', message: err.message });
  }
  
  // Test Haraka integration
  try {
    if (fs.existsSync(HARAKA_HOST_LIST_PATH)) {
      const content = fs.readFileSync(HARAKA_HOST_LIST_PATH, 'utf8');
      const domains = content.split('\n').filter(line => line.trim() && !line.startsWith('#'));
      results.tests.push({ component: 'Haraka', status: 'success', message: `${domains.length} domains configured` });
    } else {
      results.tests.push({ component: 'Haraka', status: 'error', message: 'Host list file not found' });
    }
  } catch (err) {
    results.tests.push({ component: 'Haraka', status: 'error', message: err.message });
  }
  
  // Test email count
  try {
    const emailCount = await getCounter('total_emails');
    results.tests.push({ component: 'Email System', status: 'success', message: `${emailCount} emails in database` });
  } catch (err) {
    results.tests.push({ component: 'Email System', status: 'error', message: err.message });
  }
  
  res.json(results);
});

// Email notification endpoint for Haraka
app.post('/api/email-notification', authKey, async (req, res) => {
  try {
    const { action, recipients, from, subject, timestamp } = req.body;
    
    if (action === 'new_email') {
      console.log(`📧 New email notification: ${from} -> ${recipients.join(', ')} | Subject: ${subject}`);
      
      // Emit real-time notification to connected clients
      for (const recipient of recipients) {
        // Find devices that have generated this email
        const deviceIds = await redisClient.sMembers(`email_devices:${recipient}`);
        
        // Update device stats in Redis
        for (const deviceId of deviceIds) {
          await redisClient.hIncrBy(`device_stats:${deviceId}`, 'received_count', 1);
          
          // Emit to specific device room
          io.to(deviceId).emit('newEmail', {
            email: recipient,
            from: from,
            subject: subject,
            timestamp: timestamp
          });
          
          console.log(`📱 Real-time notification sent to device: ${deviceId}`);
        }
        
        // Update MongoDB email count for generated emails only
         if (isMongoConnected() && deviceIds.length > 0) {
           for (const deviceId of deviceIds) {
             try {
               // Update email count and last activity for this device's generated emails
               await mongoDb.collection('emails').updateMany(
                 { deviceId: deviceId, email: recipient },
                 { 
                   $inc: { emailCount: 1 },
                   $set: { lastActivity: new Date() }
                 }
               );
               console.log(`📦 Updated email count in MongoDB for device: ${deviceId}`);
             } catch (mongoError) {
               console.error(`Error updating MongoDB for device ${deviceId}:`, mongoError);
             }
           }
         }
        
        // Also emit to general email room for admin panel
        io.to(`email_${recipient}`).emit('newEmail', {
          email: recipient,
          from: from,
          subject: subject,
          timestamp: timestamp
        });
      }
      
      res.json({ success: true, message: 'Notification processed' });
    } else {
      res.status(400).json({ error: 'Unknown action' });
    }
  } catch (error) {
    console.error('❌ Email notification error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// === START SERVER ===
server.listen(PORT, () => {
  console.log(`🚀 API & Socket.IO server running on port ${PORT}`);
  console.log(`📊 Admin panel available at: http://178.128.213.160:${PORT}/admin`);
  console.log(`📦 Using Redis database at: ${REDIS_URL}`);
});

// Graceful shutdown
process.on('SIGINT', async () => {
  console.log('\n🛑 Shutting down gracefully...');
  try {
    await redisClient.quit();
    console.log('📦 Redis connection closed');
  } catch (err) {
    console.error('Error closing Redis connection:', err);
  }
  process.exit(0);
});
