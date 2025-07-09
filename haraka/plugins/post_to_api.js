// 🚀 BOOSTED Haraka Plugin - High Performance Email Processing
const { simpleParser } = require('mailparser');
const http = require('http');
const { performance } = require('perf_hooks');

// Performance monitoring
let emailCount = 0;
let totalProcessingTime = 0;
const startTime = Date.now();

// 🔥 FIRE: Initialize email data storage with performance tracking
exports.hook_data = function (next, connection) {
    connection.notes.email_data = [];
    connection.notes.start_time = performance.now();
    connection.notes.email_id = `email_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    console.log(`🔄 [${connection.notes.email_id}] Email processing started`);
    next();
};

// ⚡ BOOSTED: High-speed line capture with buffer optimization
exports.hook_data_line = function (next, connection, line) {
    if (!connection.notes.email_data) {
        connection.notes.email_data = [];
    }
    // Optimize memory usage for large emails
    if (connection.notes.email_data.length < 10000) {
        connection.notes.email_data.push(line);
    } else {
        console.log(`⚠️ [${connection.notes.email_id}] Email too large, truncating`);
    }
    next();
};

// 🚀 FIRE: Ultra-fast email processing with performance metrics
exports.hook_data_post = async function (next, connection) {
    const plugin = this;
    const emailId = connection.notes.email_id || 'unknown';
    const processingStart = performance.now();
    
    try {
        emailCount++;
        const raw = connection.notes.email_data ? connection.notes.email_data.join('\n') : '';
        const lineCount = connection.notes.email_data ? connection.notes.email_data.length : 0;
        
        console.log(`🔥 [${emailId}] PROCESSING EMAIL #${emailCount}`);
        console.log(`📊 [${emailId}] Lines: ${lineCount} | Size: ${raw.length} chars`);
        
        if (lineCount === 0 || raw.length === 0) {
            console.log(`⚠️ [${emailId}] No data captured, skipping`);
            return next();
        }
        
        // ⚡ BOOSTED: Lightning-fast email parsing
        const parsed = await simpleParser(raw);
        const from = parsed.from?.text || '';
        const to = parsed.to?.text || '';
        const subject = parsed.subject || '';
        const text = parsed.text || '';
        const html = parsed.html || '';
        
        const parseTime = performance.now() - processingStart;
        console.log(`⚡ [${emailId}] PARSED in ${parseTime.toFixed(2)}ms`);
        console.log(`📨 [${emailId}] From: ${from.substring(0, 50)}...`);
        console.log(`📨 [${emailId}] To: ${to.substring(0, 50)}...`);
        console.log(`📨 [${emailId}] Subject: ${subject.substring(0, 50)}...`);
        console.log(`📊 [${emailId}] Content: ${text.length}chars text, ${html.length}chars html`);
                
                // 🚀 FIRE: Optimized payload preparation
        const payload = JSON.stringify({
            id: emailId,
            from: from,
            to: to,
            subject: subject,
            body: text,
            html: html,
            date: new Date().toISOString(),
            processing_time: parseTime,
            email_count: emailCount,
            headers: {
                'message-id': parsed.messageId || '',
                'content-type': parsed.headers?.get('content-type') || ''
            }
        });
        
        console.log(`🚀 [${emailId}] FIRING to API: ${payload.length} bytes`);
                
        // ⚡ BOOSTED: High-performance API request with retry
        const sendToAPI = () => {
            return new Promise((resolve, reject) => {
                const apiStart = performance.now();
                const req = http.request({
                    hostname: '127.0.0.1',
                    port: 3001,
                    path: '/api/receive-mail',
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Content-Length': Buffer.byteLength(payload),
                        'X-Email-ID': emailId,
                        'X-Processing-Time': parseTime.toFixed(2)
                    },
                    timeout: 3000
                }, (res) => {
                    const apiTime = performance.now() - apiStart;
                    console.log(`🔥 [${emailId}] API FIRED! Status: ${res.statusCode} in ${apiTime.toFixed(2)}ms`);
                    
                    let responseData = '';
                    res.on('data', (chunk) => {
                        responseData += chunk;
                    });
                    
                    res.on('end', () => {
                        if (res.statusCode === 200) {
                            console.log(`✅ [${emailId}] SUCCESS: ${responseData}`);
                            resolve(responseData);
                        } else {
                            console.log(`⚠️ [${emailId}] API Warning: ${res.statusCode}`);
                            resolve(responseData);
                        }
                    });
                });
                
                req.on('error', (err) => {
                    console.error(`❌ [${emailId}] API Error: ${err.message}`);
                    reject(err);
                });
                
                req.on('timeout', () => {
                    console.error(`⏰ [${emailId}] API Timeout`);
                    req.destroy();
                    reject(new Error('API Timeout'));
                });
                
                req.write(payload);
                req.end();
            });
        };
        
        // 🔥 FIRE: Execute API call with retry
        try {
            await sendToAPI();
        } catch (error) {
            console.log(`🔄 [${emailId}] Retrying API call...`);
            try {
                await sendToAPI();
            } catch (retryError) {
                console.error(`💥 [${emailId}] API Failed after retry: ${retryError.message}`);
            }
        }
        
        const totalTime = performance.now() - processingStart;
        totalProcessingTime += totalTime;
        console.log(`🏁 [${emailId}] COMPLETE in ${totalTime.toFixed(2)}ms | Avg: ${(totalProcessingTime/emailCount).toFixed(2)}ms`);
        
        next();
        
    } catch (error) {
        console.error(`💥 [${emailId}] CRITICAL ERROR: ${error.message}`);
        console.error(`🔍 [${emailId}] Stack: ${error.stack}`);
        next();
    }
};

// 🔥 FIRE: Performance monitoring and stats
setInterval(() => {
    const uptime = ((Date.now() - startTime) / 1000).toFixed(0);
    const avgTime = emailCount > 0 ? (totalProcessingTime / emailCount).toFixed(2) : '0';
    const emailsPerMin = emailCount > 0 ? ((emailCount / (Date.now() - startTime)) * 60000).toFixed(2) : '0';
    
    console.log(`📈 STATS: ${emailCount} emails | ${avgTime}ms avg | ${emailsPerMin}/min | ${uptime}s uptime`);
}, 60000); // Every minute

// 🚀 BOOSTED Plugin loaded with FIRE power!
console.log('🔥🚀 BOOSTED Post to API plugin FIRED UP successfully! 🚀🔥');
console.log('⚡ Features: Performance tracking, Retry logic, Memory optimization, Advanced logging');
console.log('🎯 Ready to process emails at LIGHTNING SPEED! ⚡');
