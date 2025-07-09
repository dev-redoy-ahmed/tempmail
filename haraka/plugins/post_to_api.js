const axios = require('axios');

exports.register = function () {
  this.register_hook('data_post', 'hook_data_post');
};

exports.hook_data_post = function (next, connection) {
  const txn = connection.transaction;
  const plugin = this;

  if (!txn) {
    plugin.logerror('❌ No transaction found.');
    return next();
  }

  // Extract complete email data using multiple methods
  const emailData = extractCompleteEmailData(txn, plugin);
  
  // Log extracted data for debugging
  plugin.loginfo('📧 Complete email data extracted:');
  plugin.loginfo(`From: ${emailData.from}`);
  plugin.loginfo(`To: ${emailData.to.join(', ')}`);
  plugin.loginfo(`Subject: ${emailData.subject}`);
  plugin.loginfo(`Body length: ${emailData.body.length}`);
  plugin.loginfo(`HTML length: ${emailData.html.length}`);
  plugin.loginfo(`Attachments: ${emailData.attachments.length}`);

  axios.post('http://178.128.222.199:3001/api/receive-mail?key=supersecretapikey123', emailData)
    .then(() => {
      plugin.loginfo('📬 Mail POSTed successfully');
      next();
    })
    .catch(err => {
      plugin.logerror(`❌ POST error: ${err.message}`);
      next();
    });
};

// Comprehensive email data extraction function
function extractCompleteEmailData(txn, plugin) {
  let bodyText = '';
  let htmlContent = '';
  let attachments = [];
  let rawContent = '';

  // Method 1: Extract from txn.body (most reliable)
  if (txn.body) {
    plugin.loginfo('🔍 Method 1: Extracting from txn.body');
    
    if (txn.body.children && txn.body.children.length > 0) {
      // Multipart message
      txn.body.children.forEach((part, index) => {
        plugin.loginfo(`📎 Processing part ${index}: ${part.ct_type}`);
        
        if (part.ct_type === 'text/plain' && part.bodytext) {
          bodyText = part.bodytext;
          plugin.loginfo(`📄 Text content found (${bodyText.length} chars)`);
        }
        else if (part.ct_type === 'text/html' && part.bodytext) {
          htmlContent = part.bodytext;
          plugin.loginfo(`🌐 HTML content found (${htmlContent.length} chars)`);
        }
        else if (part.ct_type && part.ct_type.startsWith('application/') || part.ct_type && part.ct_type.startsWith('image/')) {
          // Handle attachments
          attachments.push({
            filename: part.filename || `attachment_${index}`,
            contentType: part.ct_type,
            size: part.body_encoding ? part.body_encoding.length : 0
          });
          plugin.loginfo(`📎 Attachment found: ${part.filename || 'unnamed'}`);
        }
      });
    }
    else if (txn.body.bodytext) {
      // Single part message
      bodyText = txn.body.bodytext;
      plugin.loginfo(`📝 Single part body found (${bodyText.length} chars)`);
    }
  }

  // Method 2: Fallback to raw message data
  if (!bodyText && !htmlContent && txn.data_lines) {
    plugin.loginfo('🔍 Method 2: Extracting from raw data_lines');
    rawContent = txn.data_lines.join('\n');
    
    // Simple text extraction from raw data
    const lines = rawContent.split('\n');
    let inBody = false;
    let tempBody = [];
    
    for (let line of lines) {
      if (line.trim() === '' && !inBody) {
        inBody = true;
        continue;
      }
      if (inBody) {
        tempBody.push(line);
      }
    }
    
    if (tempBody.length > 0) {
      bodyText = tempBody.join('\n');
      plugin.loginfo(`📄 Raw body extracted (${bodyText.length} chars)`);
    }
  }

  // Method 3: Extract all available headers
  const allHeaders = {};
  if (txn.header && txn.header.headers) {
    Object.keys(txn.header.headers).forEach(key => {
      allHeaders[key] = txn.header.get(key);
    });
  }

  // Construct comprehensive email object
  const emailData = {
    // Basic info
    from: txn.mail_from ? txn.mail_from.address() : '',
    to: txn.rcpt_to ? txn.rcpt_to.map(r => r.address()) : [],
    subject: txn.header ? (txn.header.get('subject') || '(no subject)') : '(no subject)',
    
    // Content
    body: bodyText,
    html: htmlContent,
    rawContent: rawContent,
    
    // Metadata
    date: txn.header ? (txn.header.get('date') || new Date().toISOString()) : new Date().toISOString(),
    messageId: txn.header ? txn.header.get('message-id') : '',
    
    // All headers
    headers: allHeaders,
    
    // Additional info
    attachments: attachments,
    contentType: txn.header ? txn.header.get('content-type') : '',
    mimeVersion: txn.header ? txn.header.get('mime-version') : '',
    
    // Technical details
    receivedAt: new Date().toISOString(),
    bodySize: bodyText.length,
    htmlSize: htmlContent.length,
    totalAttachments: attachments.length
  };

  return emailData;
}
