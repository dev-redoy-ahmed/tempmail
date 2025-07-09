const axios = require('axios');

// Haraka constants
const OK = 906;
const DENYSOFT = 904;

exports.register = function () {
  this.register_hook('data_post', 'hook_data_post');
};

exports.hook_data_post = function (next, connection) {
  const plugin = this;
  const txn = connection.transaction;

  if (!txn) {
    this.logerror('❌ No transaction found.');
    return next();
  }

  // Get body content from transaction body and notes
  let bodyText = '';
  let htmlContent = '';
  
  plugin.loginfo('📧 Processing email body...');
  console.log('📧 Processing email body...');
  plugin.loginfo(`📧 Transaction body exists: ${!!txn.body}`);
  plugin.loginfo(`📧 Transaction notes exists: ${!!txn.notes}`);
  
  // First try to get body from transaction notes (set by body plugin)
  if (txn.notes && txn.notes.email_body) {
    plugin.loginfo('📧 Found body in transaction notes');
    bodyText = txn.notes.email_body.text_content || txn.notes.email_body.raw_content || '';
    plugin.loginfo(`📧 Body from notes: ${bodyText.substring(0, 100)}...`);
  }
  
  // If no body from notes, try transaction.body
  if (!bodyText && txn.body) {
    plugin.loginfo(`📧 Body object keys: ${Object.keys(txn.body)}`);
    
    // Check if body has children (multipart)
    if (txn.body.children && txn.body.children.length > 0) {
      plugin.loginfo(`📧 Multipart email with ${txn.body.children.length} parts`);
      
      txn.body.children.forEach((part, index) => {
        plugin.loginfo(`📧 Part ${index}: ${part.ct_type}`);
        plugin.loginfo(`📧 Part ${index} has bodytext: ${!!part.bodytext}`);
        
        if (part.ct_type === 'text/plain' && part.bodytext) {
          bodyText = part.bodytext;
          plugin.loginfo(`📧 Found text content: ${bodyText.substring(0, 100)}...`);
        } else if (part.ct_type === 'text/html' && part.bodytext) {
          htmlContent = part.bodytext;
          plugin.loginfo(`📧 Found HTML content: ${htmlContent.substring(0, 100)}...`);
        }
      });
    } else if (txn.body.bodytext) {
      // Single part email
      bodyText = txn.body.bodytext;
      plugin.loginfo(`📧 Single part email: ${bodyText.substring(0, 100)}...`);
    } else {
      // Try alternative body access methods
      plugin.loginfo('📧 Trying alternative body access methods...');
      
      // Check if body is a string
      if (typeof txn.body === 'string') {
        bodyText = txn.body;
        plugin.loginfo(`📧 Body is string: ${bodyText.substring(0, 100)}...`);
      }
      
      // Check message_stream
      if (txn.message_stream && txn.message_stream.get_data) {
        const messageData = txn.message_stream.get_data();
        if (messageData) {
          bodyText = messageData.toString();
          plugin.loginfo(`📧 Got body from message_stream: ${bodyText.substring(0, 100)}...`);
        }
      }
    }
  } else {
    plugin.logwarn('📧 No body found in transaction');
    
    // Try to get body from message_stream as fallback
    if (txn.message_stream) {
      plugin.loginfo('📧 Trying to get body from message_stream...');
      try {
        const messageData = txn.message_stream.get_data();
        if (messageData) {
          bodyText = messageData.toString();
          plugin.loginfo(`📧 Got body from message_stream fallback: ${bodyText.substring(0, 100)}...`);
        }
      } catch (err) {
        plugin.logwarn(`📧 Error getting message_stream data: ${err.message}`);
      }
    }
  }

  const mail = {
    from: txn.mail_from.address(),
    to: txn.rcpt_to.map(r => r.address()),
    subject: txn.header.get('subject') || '(no subject)',
    body: bodyText,
    html: htmlContent,
    date: txn.header.get('date') || new Date().toISOString(),
    headers: {
      'message-id': txn.header.get('message-id'),
      'content-type': txn.header.get('content-type'),
      'mime-version': txn.header.get('mime-version')
    }
  };

  axios.post('http://178.128.222.199:3001/api/receive-mail?key=supersecretapikey123', mail)
    .then(() => {
      plugin.loginfo('✅ Mail POSTed to API successfully.');
      next(OK);
    })
    .catch(err => {
      plugin.logerror(`❌ Failed to POST to API: ${err.message}`);
      next(DENYSOFT);
    });
};
