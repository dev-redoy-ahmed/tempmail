// Minimal Verified Haraka Plugin
const { simpleParser } = require('mailparser');
const http = require('http');

// Initialize email data storage
exports.hook_data = function (next, connection) {
    connection.notes.email_data = [];
    console.log('🔄 Email data hook initialized');
    next();
};

// Capture each line of email data
exports.hook_data_line = function (next, connection, line) {
    if (!connection.notes.email_data) {
        connection.notes.email_data = [];
    }
    connection.notes.email_data.push(line);
    next();
};

// Process complete email after all data received
exports.hook_data_post = function (next, connection) {
    const plugin = this;
    
    try {
        const raw = connection.notes.email_data ? connection.notes.email_data.join('\n') : '';
        const lineCount = connection.notes.email_data ? connection.notes.email_data.length : 0;
        
        console.log(`📊 Captured ${lineCount} email lines`);
        console.log(`📏 Raw data length: ${raw.length} characters`);
        
        if (lineCount === 0 || raw.length === 0) {
            console.log('⚠️ No email data captured, skipping processing');
            return next();
        }
        
        // Parse email using mailparser
        simpleParser(raw)
            .then(parsed => {
                const from = parsed.from?.text || '';
                const to = parsed.to?.text || '';
                const subject = parsed.subject || '';
                const text = parsed.text || '';
                const html = parsed.html || '';
                
                console.log('📨 Email parsed successfully:');
                console.log(`From: ${from}`);
                console.log(`To: ${to}`);
                console.log(`Subject: ${subject}`);
                console.log(`Text length: ${text.length}`);
                console.log(`HTML length: ${html.length}`);
                
                // Prepare payload for API
                const payload = JSON.stringify({
                    from: from,
                    to: to,
                    subject: subject,
                    body: text,
                    html: html,
                    date: new Date().toISOString(),
                    headers: {
                        'message-id': parsed.messageId || '',
                        'content-type': parsed.headers?.get('content-type') || ''
                    }
                });
                
                console.log(`📤 Sending to API: ${payload.length} bytes`);
                
                // Send to API
                const req = http.request({
                    hostname: '127.0.0.1',
                    port: 3001,
                    path: '/api/receive-mail',
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Content-Length': Buffer.byteLength(payload)
                    },
                    timeout: 5000
                }, (res) => {
                    console.log(`✅ API Response: ${res.statusCode}`);
                    res.on('data', (chunk) => {
                        console.log(`📥 API Response data: ${chunk}`);
                    });
                });
                
                req.on('error', (err) => {
                    console.error('❌ API Request Error:', err.message);
                });
                
                req.on('timeout', () => {
                    console.error('⏰ API Request Timeout');
                    req.destroy();
                });
                
                req.write(payload);
                req.end();
                
                next();
            })
            .catch(err => {
                console.error('❌ Email parsing error:', err.message);
                next();
            });
            
    } catch (error) {
        console.error('💥 Plugin error:', error.message);
        next();
    }
};

// Plugin info
console.log('🚀 Post to API plugin loaded successfully');
