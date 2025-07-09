const { simpleParser } = require('mailparser');
const http = require('http');

exports.register = function() {
  this.loginfo('📧 Post to API plugin loaded');
  this.register_hook('data', 'hook_data');
  this.register_hook('data_line', 'hook_data_line');
  this.register_hook('data_post', 'hook_data_post');
};

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

            console.log("📨 Parsed email:");
            console.log("From:", from);
            console.log("To:", to);
            console.log("Subject:", subject);
            console.log("Text length:", text.length);
            console.log("HTML length:", html.length);

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
                hostname: '178.128.222.199',
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
