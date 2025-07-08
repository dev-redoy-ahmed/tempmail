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

  // Get body content from body plugin notes or fallback to direct body access
  let bodyText = '';
  let htmlContent = '';
  
  if (txn.notes && txn.notes.email_body) {
    // Use content extracted by body plugin
    bodyText = txn.notes.email_body.text_content || '';
    htmlContent = txn.notes.email_body.html_content || '';
    this.loginfo('📧 Using body content from body plugin');
  } else if (txn.body) {
    // Fallback to direct body access
    bodyText = txn.body.bodytext || '';
    this.loginfo('📧 Using fallback body content');
  }

  const mail = {
    from: txn.mail_from.address(),
    to: txn.rcpt_to.map(r => r.address()).join(', '),
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
