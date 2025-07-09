const { simpleParser } = require('mailparser');
const http = require('http');

exports.hook_data = function (next, connection) {
    connection.notes.email_data = [];
    next();
};

exports.hook_data_line = function (next, connection, line) {
    connection.notes.email_data.push(line);
    next();
};

exports.hook_data_post = function (next, connection) {
    const raw = connection.notes.email_data.join('\n');
    console.log("📊 Captured", connection.notes.email_data.length, "email lines");

    simpleParser(raw)
        .then(parsed => {
            const from = parsed.from?.text || '';
            const to = parsed.to?.text || '';
            const subject = parsed.subject || '';
            const text = parsed.text || '';
            const html = parsed.html || '';

            const payload = JSON.stringify({
                from,
                to,
                subject,
                body: text,
                html: html,
                date: new Date().toISOString(),
                headers: {
                    'message-id': parsed.messageId || '',
                    'content-type': parsed.headers.get('content-type') || ''
                }
            });

            const req = http.request({
                hostname: '127.0.0.1',
                port: 3001,
                path: '/api/receive-mail',
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Content-Length': payload.length
                }
            });

            req.write(payload);
            req.end();

            req.on('error', err => {
                console.error('❌ API POST error:', err);
            });

            next();
        })
        .catch(err => {
            console.error('❌ Error parsing email:', err);
            next();
        });
};
