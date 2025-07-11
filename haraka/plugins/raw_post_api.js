// Raw Email Forwarding Plugin - Sends complete raw email data
const http = require('http');

exports.hook_data = function (next, connection) {
    const txn = connection.transaction;
    if (!txn) return next();

    // Collect raw email data
    let rawEmailData = '';
    
    // Get the raw email content
    const originalData = txn.data_lines.join('\r\n');
    
    const postData = {
        from: txn.mail_from ? txn.mail_from.address() : '',
        to: txn.rcpt_to ? txn.rcpt_to.map(r => r.address()) : [],
        raw: originalData,
        timestamp: new Date().toISOString(),
        messageId: txn.uuid
    };

    // Send to backend API with API key
    const options = {
        hostname: '127.0.0.1',
        port: 3001,
        path: '/api/receive-mail?key=supersecretapikey123',
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Content-Length': Buffer.byteLength(JSON.stringify(postData))
        }
    };

    const req = http.request(options, res => {
        let responseData = '';
        res.on('data', chunk => {
            responseData += chunk;
        });
        res.on('end', () => {
            connection.loginfo(this, `✅ Raw email sent: status ${res.statusCode}`);
            return next();
        });
    });

    req.on('error', error => {
        connection.logerror(this, `❌ Failed to send raw email: ${error.message}`);
        return next();
    });

    req.write(JSON.stringify(postData));
    req.end();
};
