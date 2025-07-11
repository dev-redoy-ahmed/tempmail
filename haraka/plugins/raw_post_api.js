// Raw Email Forwarding Plugin - Sends complete raw email data
const http = require('http');

exports.hook_data_post = function (next, connection) {
    const txn = connection.transaction;

    if (!txn) {
        connection.logerror('raw_post_api', '❌ No transaction found.');
        return next();
    }

    // Use data_lines as a safe fallback for raw email
    const rawEmail = txn.data_lines ? txn.data_lines.join('\n') : '';
    const rawSize = Buffer.byteLength(rawEmail, 'utf8');

    const emailData = {
        from: txn.mail_from ? txn.mail_from.address() : '',
        to: txn.rcpt_to ? txn.rcpt_to.map(rcpt => rcpt.address()) : [],
        subject: txn.header ? txn.header.get('subject') : '',
        raw: rawEmail,
        messageId: txn.header ? txn.header.get('message-id') : '',
        timestamp: new Date().toISOString(),
        rawSize: rawSize
    };

    const postData = JSON.stringify(emailData);

    const req = http.request({
        hostname: '127.0.0.1',
        port: 3000,
        path: '/api/receive-mail?key=supersecretapikey123',
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Content-Length': Buffer.byteLength(postData)
        }
    }, (res) => {
        let responseData = '';
        res.on('data', (chunk) => { responseData += chunk; });
        res.on('end', () => {
            connection.loginfo('raw_post_api', '✅ Raw email sent to API successfully');
            return next();
        });
    });

    req.on('error', (err) => {
        connection.logerror('raw_post_api', `❌ Failed to send raw email: ${err.message}`);
        return next();
    });

    req.write(postData);
    req.end();
};
