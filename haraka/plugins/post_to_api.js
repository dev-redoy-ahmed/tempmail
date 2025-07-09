const axios = require('axios');

exports.register = function() {
  this.loginfo('📧 Post to API plugin loaded');
  this.register_hook('data', 'hook_data');
};

exports.hook_data = function(next, connection, data) {
  const plugin = this;
  const txn = connection.transaction;
  
  try {
    // Simple raw email data capture
    plugin.loginfo('📧 Capturing raw email data...');
    
    // Get raw email data from data parameter (complete email content)
     const rawEmailData = data ? data.toString() : '';
    
    // Extract basic headers
    const headers = {};
    if (txn.header && txn.header.headers) {
      Object.keys(txn.header.headers).forEach(key => {
        headers[key] = txn.header.get(key);
      });
    }
    
    // Create simple email data object
    const emailData = {
      // Basic email info
      from: txn.mail_from ? txn.mail_from.address() : '',
      to: txn.rcpt_to ? txn.rcpt_to.map(r => r.address()) : [],
      subject: txn.header ? (txn.header.get('subject') || '(no subject)') : '(no subject)',
      
      // Raw email data (complete email as received)
      rawEmailData: rawEmailData,
      
      // All headers
      headers: headers,
      
      // Server info
      receivedAt: new Date().toISOString(),
      serverInfo: {
        remoteIP: connection.remote.ip,
        localIP: connection.local.ip,
        port: connection.local.port
      }
    };
    
    // Log basic info
    plugin.loginfo(`📧 Email captured:`);
    plugin.loginfo(`From: ${emailData.from}`);
    plugin.loginfo(`To: ${emailData.to.join(', ')}`);
    plugin.loginfo(`Subject: ${emailData.subject}`);
    plugin.loginfo(`Raw data length: ${rawEmailData.length} characters`);
    
    // Send raw data to API
    axios.post('http://178.128.222.199:3001/api/receive-mail?key=supersecretapikey123', emailData)
      .then(response => {
        plugin.loginfo(`✅ Raw email data sent to API successfully: ${response.status}`);
      })
      .catch(error => {
        plugin.logerror(`❌ Failed to send email data to API: ${error.message}`);
      });
    
  } catch (error) {
    plugin.logerror(`💥 Error in data_post hook: ${error.message}`);
  }
  
  next();
};
