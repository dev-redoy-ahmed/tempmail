const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const mongoose = require('mongoose');
const cors = require('cors');
const bodyParser = require('body-parser');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: "*" }
});

// === CONFIG ===
const PORT = 3001;
const MONGO_URI = 'mongodb+srv://tempmail:we1we2we3@turbomail.gjohjma.mongodb.net/temp-mail?retryWrites=true&w=majority&appName=turbomail';
let API_KEY = 'supersecretapikey123'; // Made mutable for updates
const ALLOWED_DOMAINS = ['oplex.online', 'worldwides.help', 'agrovia.store'];
const HARAKA_HOST_LIST_PATH = path.join(__dirname, '../haraka/config/host_list');

// === DB SETUP ===
mongoose.connect(MONGO_URI).then(() => {
  console.log('📦 Connected to MongoDB');
}).catch(console.error);

const EmailSchema = new mongoose.Schema({
  from: String,
  to: String,
  subject: String,
  body: String,
  date: String,
});
const Email = mongoose.model('Email', EmailSchema);

// Device-based email storage schema
const DeviceEmailSchema = new mongoose.Schema({
  deviceId: { type: String, required: true, index: true },
  email: { type: String, required: true },
  type: { type: String, enum: ['generated', 'received'], required: true },
  createdAt: { type: Date, default: Date.now },
  // For received emails
  from: String,
  subject: String,
  body: String,
  receivedAt: Date
});
const DeviceEmail = mongoose.model('DeviceEmail', DeviceEmailSchema);

// === MIDDLEWARE ===
app.use(cors());
app.use(bodyParser.json());
app.use(express.static('public'));

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

// === 📥 RECEIVE MAIL FROM HARAKA ===
app.post('/api/receive-mail', authKey, async (req, res) => {
  const mail = req.body;
  try {
    io.emit('new_mail', mail);                // 👈 Send to frontend first
    await Email.create(mail);                 // 👈 Then store in MongoDB
    
    // Also store in device-based collection for all devices that have this email
    const recipientEmail = Array.isArray(mail.to) ? mail.to[0] : mail.to;
    const devicesWithEmail = await DeviceEmail.find({ 
      email: recipientEmail, 
      type: 'generated' 
    });
    
    // Store received email for each device that has generated this email
    for (const deviceEmail of devicesWithEmail) {
      await DeviceEmail.create({
        deviceId: deviceEmail.deviceId,
        email: recipientEmail,
        type: 'received',
        from: mail.from,
        subject: mail.subject,
        body: mail.body,
        receivedAt: new Date(mail.date)
      });
    }
    
    res.send('✅ Mail sent via socket and saved');
  } catch (err) {
    console.error(err);
    res.status(500).send('❌ Error storing mail');
  }
});

// === 📩 RANDOM EMAIL GENERATOR ===
app.get('/generate', authKey, async (req, res) => {
  const randomUser = crypto.randomBytes(4).toString('hex');
  const domain = ALLOWED_DOMAINS[Math.floor(Math.random() * ALLOWED_DOMAINS.length)];
  const email = `${randomUser}@${domain}`;
  
  // Store generated email for device if deviceId is provided
  const { deviceId } = req.query;
  if (deviceId) {
    try {
      await DeviceEmail.create({
        deviceId,
        email,
        type: 'generated'
      });
    } catch (err) {
      console.error('Error storing generated email:', err);
    }
  }
  
  res.send({ email });
});

// === ✍️ MANUAL EMAIL GENERATOR ===
app.get('/generate/manual', authKey, async (req, res) => {
  const { username, domain, deviceId } = req.query;
  if (!username || !domain) return res.status(400).send('username and domain required');
  if (!ALLOWED_DOMAINS.includes(domain)) return res.status(400).send('domain not allowed');
  
  const email = `${username}@${domain}`;
  
  // Store generated email for device if deviceId is provided
  if (deviceId) {
    try {
      await DeviceEmail.create({
        deviceId,
        email,
        type: 'generated'
      });
    } catch (err) {
      console.error('Error storing generated email:', err);
    }
  }
  
  res.send({ email });
});

// === 📬 GET INBOX FOR EMAIL ===
app.get('/inbox/:email', authKey, async (req, res) => {
  const email = req.params.email;
  const messages = await Email.find({ to: email }).sort({ date: -1 });
  res.send(messages);
});

// === 📄 GET SPECIFIC MESSAGE BY INDEX ===
app.get('/inbox/:email/:index', authKey, async (req, res) => {
  const email = req.params.email;
  const index = parseInt(req.params.index);
  const messages = await Email.find({ to: email }).sort({ date: -1 });
  if (index < 0 || index >= messages.length) {
    return res.status(404).send('Message not found');
  }
  res.send(messages[index]);
});

// === 🧹 DELETE ALL MESSAGES ===
app.delete('/delete/:email', authKey, async (req, res) => {
  const email = req.params.email;
  await Email.deleteMany({ to: email });
  res.send('🗑️ All messages deleted');
});

// === ❌ DELETE SPECIFIC MESSAGE ===
app.delete('/delete/:email/:index', authKey, async (req, res) => {
  const email = req.params.email;
  const index = parseInt(req.params.index);
  const messages = await Email.find({ to: email }).sort({ date: -1 });
  if (index < 0 || index >= messages.length) {
    return res.status(404).send('Message not found');
  }
  await Email.findByIdAndDelete(messages[index]._id);
  res.send('🗑️ Message deleted');
});

// === 📱 DEVICE-BASED EMAIL MANAGEMENT ===

// Get all emails for a device
app.get('/device/:deviceId/emails', authKey, async (req, res) => {
  const deviceId = req.params.deviceId;
  try {
    const emails = await DeviceEmail.find({ deviceId }).sort({ createdAt: -1 });
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
    const emails = await DeviceEmail.find({ 
      deviceId, 
      type: 'generated' 
    }).sort({ createdAt: -1 });
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
    const emails = await DeviceEmail.find({ 
      deviceId, 
      type: 'received' 
    }).sort({ receivedAt: -1 });
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
    const emails = await DeviceEmail.find({ 
      deviceId, 
      email, 
      type: 'received' 
    }).sort({ receivedAt: -1 });
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
    await DeviceEmail.deleteMany({ deviceId });
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
    const result = await DeviceEmail.findOneAndDelete({ 
      _id: emailId, 
      deviceId 
    });
    if (!result) {
      return res.status(404).send('Email not found');
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
    res.send('Domain added successfully');
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

// Get admin statistics
app.get('/admin/stats', authKey, async (req, res) => {
  try {
    const totalEmails = await Email.countDocuments();
    
    let totalDomains = 0;
    if (fs.existsSync(HARAKA_HOST_LIST_PATH)) {
      const hostListContent = fs.readFileSync(HARAKA_HOST_LIST_PATH, 'utf8');
      const domains = hostListContent
        .split('\n')
        .map(line => line.trim())
        .filter(line => line && !line.startsWith('#'));
      totalDomains = domains.length;
    }
    
    // Get unique email addresses from last 24 hours (as active users)
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    
    const recentEmails = await Email.find({
      date: { $gte: yesterday.toISOString() }
    });
    
    const uniqueRecipients = new Set();
    recentEmails.forEach(email => {
      if (Array.isArray(email.to)) {
        email.to.forEach(recipient => uniqueRecipients.add(recipient));
      } else {
        uniqueRecipients.add(email.to);
      }
    });
    
    const activeUsers = uniqueRecipients.size;
    
    res.json({
      totalEmails,
      totalDomains,
      activeUsers
    });
  } catch (err) {
    console.error('Error getting stats:', err);
    res.status(500).send('Error getting statistics');
  }
});

// Get recent emails for monitoring
app.get('/admin/recent-emails', authKey, async (req, res) => {
  try {
    const recentEmails = await Email.find()
      .sort({ date: -1 })
      .limit(50);
    res.json(recentEmails);
  } catch (err) {
    console.error('Error getting recent emails:', err);
    res.status(500).send('Error getting recent emails');
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

// Test MongoDB connection
app.get('/admin/test-mongo', authKey, async (req, res) => {
  try {
    // Try to perform a simple database operation
    await mongoose.connection.db.admin().ping();
    res.json({ status: 'connected', message: 'MongoDB connection is healthy' });
  } catch (err) {
    console.error('MongoDB test failed:', err);
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
  
  // Test MongoDB
  try {
    await mongoose.connection.db.admin().ping();
    results.tests.push({ component: 'MongoDB', status: 'success', message: 'Connected' });
  } catch (err) {
    results.tests.push({ component: 'MongoDB', status: 'error', message: err.message });
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
    const emailCount = await Email.countDocuments();
    results.tests.push({ component: 'Email System', status: 'success', message: `${emailCount} emails in database` });
  } catch (err) {
    results.tests.push({ component: 'Email System', status: 'error', message: err.message });
  }
  
  res.json(results);
});

// === START SERVER ===
server.listen(PORT, () => {
  console.log(`🚀 API & Socket.IO server running on port ${PORT}`);
  console.log(`📊 Admin panel available at: http://localhost:${PORT}/admin`);
});
