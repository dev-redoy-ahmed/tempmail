const axios = require('axios');

exports.register = function () {
  this.register_hook('queue', 'hook_queue');
};

exports.hook_queue = function (next, connection) {
  const txn = connection.transaction;

  if (!txn) {
    this.logerror('❌ No transaction found.');
    return next();
  }

  // Get body content from transaction body
  let bodyText = '';
  let htmlContent = '';
  
  if (txn.body) {
    this.loginfo('📧 Processing email body...');
    
    // Check if body has children (multipart)
    if (txn.body.children && txn.body.children.length > 0) {
      this.loginfo(`📧 Multipart email with ${txn.body.children.length} parts`);
      
      txn.body.children.forEach((part, index) => {
        this.loginfo(`📧 Part ${index}: ${part.ct_type}`);
        
        if (part.ct_type === 'text/plain' && part.bodytext) {
          bodyText = part.bodytext;
          this.loginfo(`📧 Found text content: ${bodyText.substring(0, 100)}...`);
        } else if (part.ct_type === 'text/html' && part.bodytext) {
          htmlContent = part.bodytext;
          this.loginfo(`📧 Found HTML content: ${htmlContent.substring(0, 100)}...`);
        }
      });
    } else if (txn.body.bodytext) {
      // Single part email
      bodyText = txn.body.bodytext;
      this.loginfo(`📧 Single part email: ${bodyText.substring(0, 100)}...`);
    }
  } else {
    this.logwarn('📧 No body found in transaction');
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
      this.loginfo('✅ Mail POSTed to API successfully.');
      next(OK);
    })
    .catch(err => {
      this.logerror(`❌ Failed to POST to API: ${err.message}`);
      next(DENYSOFT);
    });
};
