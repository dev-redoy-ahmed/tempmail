// Raw Email Forwarding Plugin - Streams raw email content without parsing
const http = require('http');

exports.hook_queue = function (next, connection) {
    const txn = connection.transaction;
    if (!txn) return next();

    let rawEmail = '';
    txn.message_stream.on('data', chunk => {
        rawEmail += chunk;
    });

    txn.message_stream.on('end', () => {
        const postData = {
            from: txn.mail_from.address(),
            to: txn.rcpt_to.map(r => r.address()),
            headers: txn.header.headers_decoded,
            raw: rawEmail
        };

        // Send to your backend API
        const options = {
            hostname: '127.0.0.1',
            port: 3001,
            path: '/api/receive-mail',
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            }
        };

        const req = http.request(options, res => {
            res.on('data', d => {});
            res.on('end', () => {
                connection.loginfo(this, `✅ Mail POSTed: status ${res.statusCode}`);
                return next(OK);
            });
        });

        req.on('error', error => {
            connection.logerror(this, `❌ POST failed: ${error.message}`);
            return next(DENYSOFT, 'Failed to deliver email');
        });

        req.write(JSON.stringify(postData));
        req.end();
    });
};
