// body.js - Plugin to read email body content

exports.register = function () {
    this.loginfo('Body plugin loaded');
    this.register_hook('data_post', 'hook_data_post');
};

exports.hook_data_post = function (next, connection) {
    const plugin = this;
    const transaction = connection.transaction;
    
    if (!transaction || !transaction.message_stream) {
        plugin.logwarn('No transaction or message stream found');
        return next();
    }

    // Get the email body
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

// Hook to process body before other plugins
exports.hook_data = function (next, connection) {
    const plugin = this;
    plugin.loginfo('Processing email data for body extraction');
    return next();
};