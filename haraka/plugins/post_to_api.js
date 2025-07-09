const axios = require('axios');

exports.register = function () {
  this.register_hook('queue', 'hook_queue');
};

exports.hook_queue = function (next, connection) {
  const txn = connection.transaction;
  const plugin = this;

  if (!txn) {
    plugin.logerror('❌ No transaction found.');
    return next();
  }

  let bodyText = '';
  let htmlContent = '';

  // Extract body content directly from txn.body
  if (txn.body) {
    plugin.loginfo('✅ Extracting body content directly from txn.body');
    
    // Handle multipart messages
    if (txn.body.children && txn.body.children.length > 0) {
      txn.body.children.forEach(part => {
        if (part.ct_type === 'text/plain' && part.bodytext) {
          bodyText = part.bodytext;
          plugin.loginfo(`📄 Text part found: ${bodyText.substring(0, 100)}...`);
        }
        if (part.ct_type === 'text/html' && part.bodytext) {
          htmlContent = part.bodytext;
          plugin.loginfo(`🌐 HTML part found: ${htmlContent.substring(0, 100)}...`);
        }
      });
    } 
    // Handle single part messages
    else if (txn.body.bodytext) {
      bodyText = txn.body.bodytext;
      plugin.loginfo(`📝 Single part body found: ${bodyText.substring(0, 100)}...`);
    }
  } else {
    plugin.logwarn('⚠️ No body found in transaction.');
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
      plugin.loginfo('📬 Mail POSTed successfully');
      next(OK);
    })
    .catch(err => {
      plugin.logerror(`❌ POST error: ${err.message}`);
      next(DENYSOFT);
    });
};
