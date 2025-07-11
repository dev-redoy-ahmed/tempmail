// Raw Email Forwarding Plugin - Sends complete raw email data
const http = require('http');

exports.hook_data_post = function (next, connection) {
    const txn = connection.transaction;
    
    if (!txn) return next();

    let raw = '';
    const stream = txn.message_stream;

    stream.on('data', (chunk) => {
        raw += chunk;
    });

    stream.on('end', () => {
        const payload = {
            from: txn.mail_from ? txn.mail_from.address() : '',
            to: txn.rcpt_to ? txn.rcpt_to.map(r => r.address()) : [],
            messageId: txn.uuid,
            timestamp: new Date().toISOString(),
            rawSize: raw.length,
            raw: raw
        };

        console.log(`📧 Raw email captured: rawSize=${raw.length}, from=${payload.from}`);

        // Send to backend API with API key
        const options = {
            hostname: '127.0.0.1',
            port: 3001,
            path: '/api/receive-mail?key=supersecretapikey123',
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Content-Length': Buffer.byteLength(JSON.stringify(payload))
            }
        };

        const req = http.request(options, res => {
            let responseData = '';
            res.on('data', chunk => {
                responseData += chunk;
            });
            res.on('end', () => {
                connection.loginfo(this, `✅ Raw email sent: status ${res.statusCode}, rawSize=${raw.length}`);
            });
        });

        req.on('error', error => {
            connection.logerror(this, `❌ Failed to send raw email: ${error.message}`);
        });

        req.write(JSON.stringify(payload));
        req.end();
    });

    return next();
};
