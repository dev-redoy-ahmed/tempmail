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
    
    // Extract body from raw email data
    let body = '';
    let html = '';
    
    if (rawEmailData) {
      const lines = rawEmailData.split('\n');
      let inBody = false;
      let bodyLines = [];
      
      // Find where headers end and body begins
      for (let i = 0; i < lines.length; i++) {
        if (lines[i].trim() === '' && !inBody) {
          inBody = true;
          continue;
        }
        if (inBody) {
          bodyLines.push(lines[i]);
        }
      }
      
      body = bodyLines.join('\n').trim();
      
      // Check if it's HTML content
      if (body.includes('<html') || body.includes('<!DOCTYPE') || body.includes('<body')) {
        html = body;
      }
    }
    
    // Create email data object compatible with API schema
    const emailData = {
      // Basic email info
      from: txn.mail_from ? txn.mail_from.address() : '',
      to: txn.rcpt_to ? txn.rcpt_to.map(r => r.address()) : [],
      subject: txn.header ? (txn.header.get('subject') || '(no subject)') : '(no subject)',
      date: txn.header ? (txn.header.get('date') || new Date().toISOString()) : new Date().toISOString(),
      
      // Email content
      body: body,
      html: html,
      
      // Headers (compatible with API schema)
      headers: {
        messageId: headers['message-id'] || '',
        contentType: headers['content-type'] || '',
        mimeVersion: headers['mime-version'] || ''
      },
      
      // Raw email data for debugging
      rawEmailData: rawEmailData
    };
    
    // Log basic info
    plugin.loginfo(`📧 Email captured:`);
    plugin.loginfo(`From: ${emailData.from}`);
    plugin.loginfo(`To: ${emailData.to.join(', ')}`);
    plugin.loginfo(`Subject: ${emailData.subject}`);
    plugin.loginfo(`Body length: ${body.length} characters`);
    plugin.loginfo(`HTML length: ${html.length} characters`);
    plugin.loginfo(`Raw data length: ${rawEmailData.length} characters`);
    
    // Log content preview for debugging
    if (body) {
      plugin.loginfo(`📄 Body preview: ${body.substring(0, 200)}...`);
    }
    if (html) {
      plugin.loginfo(`🌐 HTML preview: ${html.substring(0, 200)}...`);
    }
    
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
