// test_delivery.js - Simple plugin to accept emails without delivering

const constants = require('haraka-constants');
const OK = constants.OK;

exports.register = function () {
    this.loginfo('Test delivery plugin loaded');
    this.register_hook('queue', 'hook_queue');
};

exports.hook_queue = function (next, connection) {
    const plugin = this;
    const transaction = connection.transaction;
    
    plugin.loginfo('📧 Email accepted for testing purposes');
    plugin.loginfo(`From: ${transaction.mail_from}`);
    plugin.loginfo(`To: ${transaction.rcpt_to.map(r => r.address()).join(', ')}`);
    plugin.loginfo(`Subject: ${transaction.header.get('Subject')}`);
    
    // Accept the email without actually delivering it
    return next(OK, 'Email accepted for testing');
};