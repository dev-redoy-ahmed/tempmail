// body.js - Plugin to read email body content

exports.register = function () {
    this.loginfo('Body plugin loaded');
    this.register_hook('data_post', 'hook_data_post');
};

exports.hook_data_post = function (next, connection) {
    const plugin = this;
    const transaction = connection.transaction;
    
    plugin.loginfo('🔍 Body plugin: Processing email body...');
    console.log('🔍 Body plugin: Processing email body...');
    
    if (!transaction) {
        plugin.logwarn('No transaction found');
        return next();
    }

    // Parse the message body from message_stream
    if (transaction.message_stream) {
        try {
            const messageData = transaction.message_stream.get_data();
            if (messageData) {
                const messageString = messageData.toString();
                plugin.loginfo(`📧 Raw message data: ${messageString.substring(0, 200)}...`);
                
                // Simple body extraction - find content after headers
                const headerEndIndex = messageString.indexOf('\r\n\r\n');
                if (headerEndIndex !== -1) {
                    const bodyContent = messageString.substring(headerEndIndex + 4);
                    plugin.loginfo(`📧 Extracted body: ${bodyContent.substring(0, 100)}...`);
                    
                    // Store body in transaction for other plugins
                    if (!transaction.notes) transaction.notes = {};
                    transaction.notes.email_body = {
                        text_content: bodyContent,
                        raw_content: bodyContent
                    };
                }
            }
        } catch (err) {
            plugin.logwarn(`📧 Error parsing message stream: ${err.message}`);
        }
    }

    // Get the email body (if already parsed)
    const body = transaction.body;
    
    if (body) {
        // Log body information
        plugin.loginfo('Email body detected:');
        plugin.loginfo(`Body parts: ${body.children ? body.children.length : 0}`);
        
        // Process text parts
        if (body.children && body.children.length > 0) {
            body.children.forEach((child, index) => {
                if (child.ct_type === 'text/plain') {
                    plugin.loginfo(`Text part ${index}: ${child.bodytext ? child.bodytext.substring(0, 100) : 'No text'}`);
                } else if (child.ct_type === 'text/html') {
                    plugin.loginfo(`HTML part ${index}: ${child.bodytext ? child.bodytext.substring(0, 100) : 'No HTML'}`);
                }
            });
        } else {
            // Single part message
            if (body.bodytext) {
                plugin.loginfo(`Single part body: ${body.bodytext.substring(0, 100)}`);
            }
        }
        
        // Store body content in transaction notes for other plugins
        if (!transaction.notes) transaction.notes = {};
        transaction.notes.email_body = {
            full_body: body,
            text_content: extractTextContent(body),
            html_content: extractHtmlContent(body)
        };
    } else {
        plugin.logwarn('No body found in transaction');
    }
    
    return next();
};

// Helper function to extract text content
function extractTextContent(body) {
    if (!body) return '';
    
    if (body.children && body.children.length > 0) {
        for (let child of body.children) {
            if (child.ct_type === 'text/plain' && child.bodytext) {
                return child.bodytext;
            }
        }
    } else if (body.bodytext) {
        return body.bodytext;
    }
    
    return '';
}

// Helper function to extract HTML content
function extractHtmlContent(body) {
    if (!body) return '';
    
    if (body.children && body.children.length > 0) {
        for (let child of body.children) {
            if (child.ct_type === 'text/html' && child.bodytext) {
                return child.bodytext;
            }
        }
    }
    
    return '';
}