const axios = require('axios');

exports.register = function () {
  this.register_hook('queue', 'hook_queue');
};

exports.hook_queue = function (next, connection) {
  const txn = connection.transaction;

  if (!txn || !txn.body) {
    this.logerror('❌ No transaction body found.');
    return next();
  }

  const mail = {
    from: txn.mail_from.address(),
    to: txn.rcpt_to.map(r => r.address()),
    subject: txn.header.get('subject') || '(no subject)',
    body: txn.body.bodytext || '',
    date: txn.header.get('date') || new Date().toISOString()
  };

  axios.post('http://146.190.107.33:3001/api/receive-mail?key=supersecretapikey123', mail)
    .then(() => {
      this.loginfo('✅ Mail POSTed to API successfully.');
      next(OK);
    })
    .catch(err => {
      this.logerror(`❌ Failed to POST to API: ${err.message}`);
      next(DENYSOFT);
    });
};
