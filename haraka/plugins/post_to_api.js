const axios = require('axios');

exports.register = function () {
  this.register_hook('data_post', 'hook_data_post');
};

exports.hook_data_post = function (next, connection) {
  const txn = connection.transaction;
  const plugin = this;

  if (!txn) {
    plugin.logerror('❌ No transaction found.');
    return next();
  }

  // Extract complete email data using multiple methods
  const emailData = extractCompleteEmailData(txn, plugin);
  
  // Log extracted data for debugging
  plugin.loginfo('📧 Complete email data extracted:');
  plugin.loginfo(`From: ${emailData.from}`);
  plugin.loginfo(`To: ${emailData.to.join(', ')}`);
  plugin.loginfo(`Subject: ${emailData.subject}`);
  plugin.loginfo(`Body length: ${emailData.body.length}`);
  plugin.loginfo(`HTML length: ${emailData.html.length}`);
  plugin.loginfo(`Raw content length: ${emailData.rawContent.length}`);
  plugin.loginfo(`All found content pieces: ${emailData.allFoundContent.length}`);
  plugin.loginfo(`Attachments: ${emailData.attachments.length}`);
  
  // Log actual content for debugging (first 200 chars)
  if (emailData.body) {
    plugin.loginfo(`📄 Body preview: ${emailData.body.substring(0, 200)}...`);
  }
  if (emailData.html) {
    plugin.loginfo(`🌐 HTML preview: ${emailData.html.substring(0, 200)}...`);
  }
  if (emailData.rawContent) {
    plugin.loginfo(`📋 Raw preview: ${emailData.rawContent.substring(0, 200)}...`);
  }

  axios.post('http://178.128.222.199:3001/api/receive-mail?key=supersecretapikey123', emailData)
    .then(() => {
      plugin.loginfo('📬 Mail POSTed successfully');
      next();
    })
    .catch(err => {
      plugin.logerror(`❌ POST error: ${err.message}`);
      next();
    });
};

// Comprehensive email data extraction function
function extractCompleteEmailData(txn, plugin) {
  let bodyText = '';
  let htmlContent = '';
  let attachments = [];
  let rawContent = '';
  let allFoundContent = [];

  plugin.loginfo('🔍 Starting comprehensive email extraction...');
  
  // Method 1: Extract from txn.body (most reliable)
  if (txn.body) {
    plugin.loginfo('🔍 Method 1: Extracting from txn.body');
    
    // Log all available properties of txn.body for debugging
    plugin.loginfo(`Body object keys: ${Object.keys(txn.body).join(', ')}`);
    
    if (txn.body.children && txn.body.children.length > 0) {
      // Multipart message
      plugin.loginfo(`Found ${txn.body.children.length} body parts`);
      
      txn.body.children.forEach((part, index) => {
        plugin.loginfo(`📎 Processing part ${index}: ${part.ct_type}`);
        plugin.loginfo(`Part keys: ${Object.keys(part).join(', ')}`);
        
        // Try multiple properties for body text
        let partContent = part.bodytext || part.body || part.content || part.data || '';
        
        if (partContent) {
          allFoundContent.push(`Part ${index} (${part.ct_type}): ${partContent}`);
          
          if (part.ct_type === 'text/plain' || !part.ct_type) {
            bodyText = partContent;
            plugin.loginfo(`📄 Text content found (${bodyText.length} chars)`);
          }
          else if (part.ct_type === 'text/html') {
            htmlContent = partContent;
            plugin.loginfo(`🌐 HTML content found (${htmlContent.length} chars)`);
          }
        }
        
        // Handle attachments
        if (part.ct_type && (part.ct_type.startsWith('application/') || part.ct_type.startsWith('image/'))) {
          attachments.push({
            filename: part.filename || `attachment_${index}`,
            contentType: part.ct_type,
            size: partContent.length || 0
          });
          plugin.loginfo(`📎 Attachment found: ${part.filename || 'unnamed'}`);
        }
      });
    }
    else if (txn.body.bodytext || txn.body.body || txn.body.content) {
      // Single part message - try multiple properties
      bodyText = txn.body.bodytext || txn.body.body || txn.body.content || '';
      plugin.loginfo(`📝 Single part body found (${bodyText.length} chars)`);
      allFoundContent.push(`Single body: ${bodyText}`);
    }
  }

  // Method 2: Extract from message_stream if available
  if ((!bodyText && !htmlContent) && txn.message_stream) {
    plugin.loginfo('🔍 Method 2: Trying message_stream extraction');
    try {
      if (txn.message_stream.get_data) {
        const streamData = txn.message_stream.get_data();
        if (streamData) {
          rawContent = streamData.toString();
          plugin.loginfo(`📄 Stream data extracted (${rawContent.length} chars)`);
          allFoundContent.push(`Stream data: ${rawContent}`);
        }
      }
    } catch (err) {
      plugin.logwarn(`Stream extraction failed: ${err.message}`);
    }
  }

  // Method 3: Fallback to raw message data
  if ((!bodyText && !htmlContent) && txn.data_lines) {
    plugin.loginfo('🔍 Method 3: Extracting from raw data_lines');
    rawContent = txn.data_lines.join('\n');
    
    // Simple text extraction from raw data
    const lines = rawContent.split('\n');
    let inBody = false;
    let tempBody = [];
    let headerEnded = false;
    
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      
      // Look for empty line that separates headers from body
      if (line.trim() === '' && !headerEnded) {
        headerEnded = true;
        inBody = true;
        continue;
      }
      
      if (inBody) {
        tempBody.push(line);
      }
    }
    
    if (tempBody.length > 0) {
      const extractedBody = tempBody.join('\n').trim();
      if (extractedBody) {
        bodyText = extractedBody;
        plugin.loginfo(`📄 Raw body extracted (${bodyText.length} chars)`);
        allFoundContent.push(`Raw extraction: ${bodyText}`);
      }
    }
  }

  // Method 4: Emergency fallback - use any available content
  if (!bodyText && !htmlContent && allFoundContent.length === 0) {
    plugin.loginfo('🔍 Method 4: Emergency content extraction');
    
    // Try to extract from transaction notes
    if (txn.notes && Object.keys(txn.notes).length > 0) {
      plugin.loginfo(`Transaction notes available: ${Object.keys(txn.notes).join(', ')}`);
      
      // Look for any content in notes
      Object.keys(txn.notes).forEach(key => {
        const noteValue = txn.notes[key];
        if (typeof noteValue === 'string' && noteValue.length > 10) {
          allFoundContent.push(`Note ${key}: ${noteValue}`);
          if (!bodyText) bodyText = noteValue;
        }
      });
    }
    
    // If still no content, use raw data as is
    if (!bodyText && rawContent) {
      bodyText = rawContent;
      plugin.loginfo(`📄 Using raw content as body (${bodyText.length} chars)`);
    }
  }

  // Method 3: Extract all available headers
  const allHeaders = {};
  if (txn.header && txn.header.headers) {
    Object.keys(txn.header.headers).forEach(key => {
      allHeaders[key] = txn.header.get(key);
    });
  }

  // Final content validation and fallback
  if (!bodyText && !htmlContent && allFoundContent.length > 0) {
    // Use the first found content as body
    bodyText = allFoundContent[0].split(': ').slice(1).join(': ');
    plugin.loginfo(`📄 Using first found content as body (${bodyText.length} chars)`);
  }
  
  // If still no content, create a summary of what was found
  if (!bodyText && !htmlContent) {
    bodyText = `[No body content found. Available data: ${allFoundContent.length > 0 ? allFoundContent.join(' | ') : 'None'}]`;
    plugin.logwarn('⚠️ No body content extracted, using summary');
  }

  // Construct comprehensive email object
  const emailData = {
    // Basic info
    from: txn.mail_from ? txn.mail_from.address() : '',
    to: txn.rcpt_to ? txn.rcpt_to.map(r => r.address()) : [],
    subject: txn.header ? (txn.header.get('subject') || '(no subject)') : '(no subject)',
    
    // Content
    body: bodyText,
    html: htmlContent,
    rawContent: rawContent,
    allFoundContent: allFoundContent,
    
    // Metadata
    date: txn.header ? (txn.header.get('date') || new Date().toISOString()) : new Date().toISOString(),
    messageId: txn.header ? txn.header.get('message-id') : '',
    
    // All headers
    headers: allHeaders,
    
    // Additional info
    attachments: attachments,
    contentType: txn.header ? txn.header.get('content-type') : '',
    mimeVersion: txn.header ? txn.header.get('mime-version') : '',
    
    // Technical details
    receivedAt: new Date().toISOString(),
    bodySize: bodyText.length,
    htmlSize: htmlContent.length,
    totalAttachments: attachments.length,
    extractionMethods: {
      bodyFound: !!bodyText,
      htmlFound: !!htmlContent,
      rawContentFound: !!rawContent,
      totalContentPieces: allFoundContent.length
    }
  };

  return emailData;
}
