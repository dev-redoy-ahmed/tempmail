// Raw Email Redis Storage Plugin - Stores emails directly to Redis with persistent connection
const redis = require('redis');
const http = require('http');

// Global Redis client with persistent connection
let redisClient = null;
let isRedisConnected = false;

// Initialize Redis connection once
function initializeRedis() {
    if (!redisClient) {
        redisClient = redis.createClient({
            url: 'redis://178.128.213.160:6379',
            socket: {
                reconnectStrategy: (retries) => {
                    if (retries > 10) {
                        return new Error('Redis connection failed after 10 retries');
                    }
                    return Math.min(retries * 50, 500);
                }
            }
        });

        redisClient.on('connect', () => {
            console.log('🔗 Haraka Redis: Connecting to Redis...');
        });

        redisClient.on('ready', () => {
            console.log('✅ Haraka Redis: Connected and ready');
            isRedisConnected = true;
        });

        redisClient.on('error', (err) => {
            console.error('❌ Haraka Redis Error:', err.message);
            isRedisConnected = false;
        });

        redisClient.on('end', () => {
            console.log('🔌 Haraka Redis: Connection closed');
            isRedisConnected = false;
        });

        redisClient.on('reconnecting', () => {
            console.log('🔄 Haraka Redis: Reconnecting...');
            isRedisConnected = false;
        });

        // Connect to Redis
        redisClient.connect().catch(err => {
            console.error('❌ Haraka Redis: Failed to connect:', err.message);
        });
    }
}

// Initialize Redis when plugin loads
initializeRedis();

// Store email to Redis
async function storeEmailToRedis(emailData, connection) {
    if (!isRedisConnected || !redisClient) {
        connection.logerror('raw_post_api', '❌ Redis not connected, cannot store email');
        return false;
    }

    try {
        // Store email for each recipient
        for (const recipient of emailData.to) {
            const emailKey = `emails:${recipient}`;
            const emailId = `${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
            
            // Store individual email
            await redisClient.hSet(`email:${emailId}`, {
                from: emailData.from,
                to: recipient,
                subject: emailData.subject,
                raw: emailData.raw,
                messageId: emailData.messageId,
                timestamp: emailData.timestamp,
                rawSize: emailData.rawSize.toString()
            });
            
            // Add to recipient's email list
            await redisClient.lPush(emailKey, emailId);
            
            // Increment counter
            await redisClient.incr('email_counter');
        }
        
        connection.loginfo('raw_post_api', `✅ Email stored to Redis for ${emailData.to.length} recipient(s)`);
        
        // Notify API about new email via HTTP (non-blocking)
        notifyAPI(emailData, connection);
        
        return true;
    } catch (error) {
        connection.logerror('raw_post_api', `❌ Redis storage error: ${error.message}`);
        return false;
    }
}

// Notify API about new email (non-blocking)
function notifyAPI(emailData, connection) {
    const notificationData = JSON.stringify({
        action: 'new_email',
        recipients: emailData.to,
        from: emailData.from,
        subject: emailData.subject,
        timestamp: emailData.timestamp
    });

    const req = http.request({
        hostname: '127.0.0.1',
        port: 3000,
        path: '/api/email-notification?key=supersecretapikey123',
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Content-Length': Buffer.byteLength(notificationData)
        },
        timeout: 5000
    }, (res) => {
        connection.loginfo('raw_post_api', '📧 API notified about new email');
    });

    req.on('error', (err) => {
        connection.logwarn('raw_post_api', `⚠️ API notification failed: ${err.message}`);
    });

    req.on('timeout', () => {
        connection.logwarn('raw_post_api', '⚠️ API notification timeout');
        req.destroy();
    });

    req.write(notificationData);
    req.end();
}

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

    // Store email to Redis first, then notify API
    storeEmailToRedis(emailData, connection).then((success) => {
        if (success) {
            connection.loginfo('raw_post_api', '✅ Email processing completed successfully');
        } else {
            connection.logerror('raw_post_api', '❌ Email processing failed');
        }
        return next();
    }).catch((error) => {
        connection.logerror('raw_post_api', `❌ Email processing error: ${error.message}`);
        return next();
    });
};
