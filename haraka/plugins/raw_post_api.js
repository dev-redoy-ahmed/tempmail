// Raw Email Forwarding Plugin - Sends complete raw email data
const http = require('http');

exports.hook_data_post = function (next, connection) {
    const txn = connection.transaction;
    
    // ✅ Null checking to prevent crashes
    if (!txn || !txn.message_stream) {
        connection.logerror('raw_post_api', '❌ message_stream is null, skipping.');
        return next();
    }
    
    let chunks = [];
    let rawSize = 0;
    
    txn.message_stream.on('data', (chunk) => {
        chunks.push(chunk);
        rawSize += chunk.length;
    });
    
    txn.message_stream.on('end', () => {
        const rawEmail = Buffer.concat(chunks).toString('utf8');
        connection.loginfo('raw_post_api', `📧 Email received (${rawEmail.length} chars)`);
        
        const emailData = {
            from: txn.mail_from ? txn.mail_from.address() : '',
            to: txn.rcpt_to ? txn.rcpt_to.map(rcpt => rcpt.address()) : [],
            subject: txn.header ? txn.header.get('subject') : '',
            body: rawEmail,
            timestamp: new Date().toISOString(),
            rawSize: rawSize
        };
        
        const postData = JSON.stringify(emailData);
        
        const req = http.request({
            hostname: '127.0.0.1',
            port: 3000,
            path: '/api/receive-mail',
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Content-Length': Buffer.byteLength(postData)
            }
        }, (res) => {
            let responseData = '';
            res.on('data', (chunk) => {
                responseData += chunk;
            });
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
    });
    
    txn.message_stream.on('error', (err) => {
        connection.logerror('raw_post_api', `❌ Stream error: ${err.message}`);
        return next();
    });
};
