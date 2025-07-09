const axios = require('axios');
const { simpleParser } = require('mailparser');

exports.register = function () {
  this.register_hook('queue', 'hook_queue');
};

exports.hook_queue = function (next, connection) {
  const txn = connection.transaction;
  const plugin = this;

  if (!txn) {
    plugin.logerror('❌ No transaction found.');
    return next();
  }

  // Function to process parsed email data
  const processEmailData = (bodyText, htmlContent) => {
    const mail = {
      from: txn.mail_from.address(),
      to: txn.rcpt_to.map(r => r.address()),
      subject: txn.header.get('subject') || '(no subject)',
      body: bodyText,
      html: htmlContent,
      date: txn.header.get('date') || new Date().toISOString(),
      headers: {
        'message-id': txn.header.get('message-id'),
        'content-type': txn.header.get('content-type'),
        'mime-version': txn.header.get('mime-version')
      }
    };

    axios.post('http://178.128.222.199:3001/api/receive-mail?key=supersecretapikey123', mail)
      .then(() => {
        plugin.loginfo('✅ Mail POSTed to API successfully.');
        next(OK);
      })
      .catch(err => {
        plugin.logerror(`❌ Failed to POST to API: ${err.message}`);
        next(DENYSOFT);
      });
  };

  // Get body content from transaction notes (processed by body plugin)
  let bodyText = '';
  let htmlContent = '';
  
  // First try to get from transaction notes (preferred method)
  if (txn.notes.email_body) {
    bodyText = txn.notes.email_body.text_content || '';
    htmlContent = txn.notes.email_body.html_content || '';
    plugin.loginfo(`📧 Body found in notes - Text: ${bodyText.length} chars, HTML: ${htmlContent.length} chars`);
    processEmailData(bodyText, htmlContent);
  }
  // Fallback to message_stream parsing with mailparser
  else if (txn.message_stream) {
    plugin.loginfo('📧 Parsing email from message_stream with mailparser...');
    
    // Collect raw email data from message_stream
    let rawEmailData = '';
    
    // Read the message stream
    txn.message_stream.on('data', (chunk) => {
      rawEmailData += chunk.toString();
    });
    
    txn.message_stream.on('end', () => {
      // Parse with mailparser
      simpleParser(rawEmailData)
        .then(parsed => {
          bodyText = parsed.text || '';
          htmlContent = parsed.html || '';
          
          plugin.loginfo(`📧 Mailparser success - Text: ${bodyText.length} chars, HTML: ${htmlContent.length} chars`);
          processEmailData(bodyText, htmlContent);
        })
        .catch(parseErr => {
          plugin.logerror(`❌ Mailparser failed: ${parseErr.message}`);
          // Fallback to direct body access
          plugin.loginfo('📧 Falling back to direct body access...');
          
          if (txn.body) {
            if (txn.body.children && txn.body.children.length > 0) {
              txn.body.children.forEach((part) => {
                if (part.ct_type === 'text/plain' && part.bodytext) {
                  bodyText = part.bodytext;
                } else if (part.ct_type === 'text/html' && part.bodytext) {
                  htmlContent = part.bodytext;
                }
              });
            } else if (txn.body.bodytext) {
              bodyText = txn.body.bodytext;
            }
          }
          
          processEmailData(bodyText, htmlContent);
        });
    });
    
    txn.message_stream.on('error', (streamErr) => {
      plugin.logerror(`❌ Message stream error: ${streamErr.message}`);
      processEmailData('', '');
    });
  }
  // Final fallback to direct body access
  else if (txn.body) {
    plugin.loginfo('📧 Processing email body directly...');
    
    if (txn.body.children && txn.body.children.length > 0) {
      plugin.loginfo(`📧 Multipart email with ${txn.body.children.length} parts`);
      
      txn.body.children.forEach((part, index) => {
        plugin.loginfo(`📧 Part ${index}: ${part.ct_type}`);
        
        if (part.ct_type === 'text/plain' && part.bodytext) {
          bodyText = part.bodytext;
          plugin.loginfo(`📧 Found text content: ${bodyText.substring(0, 100)}...`);
        } else if (part.ct_type === 'text/html' && part.bodytext) {
          htmlContent = part.bodytext;
          plugin.loginfo(`📧 Found HTML content: ${htmlContent.substring(0, 100)}...`);
        }
      });
    } else if (txn.body.bodytext) {
      bodyText = txn.body.bodytext;
      plugin.loginfo(`📧 Single part email: ${bodyText.substring(0, 100)}...`);
    }
    
    processEmailData(bodyText, htmlContent);
  } else {
    plugin.logwarn('📧 No body found in transaction, notes, or message_stream');
    processEmailData('', '');
  }
};
