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

  let bodyText = '';
  let htmlContent = '';

  if (txn.notes.email_body) {
    bodyText = txn.notes.email_body.text_content || '';
    htmlContent = txn.notes.email_body.html_content || '';
    plugin.loginfo(`📧 Body found in notes - Text: ${bodyText.length} chars, HTML: ${htmlContent.length} chars`);
    processEmailData(bodyText, htmlContent);
  }
  else if (txn.message_stream && typeof txn.message_stream.on === 'function' && !txn.message_stream.destroyed) {
    plugin.loginfo('📧 Parsing email from message_stream with mailparser...');
    
    let rawEmailData = '';
    let streamEnded = false;
    let streamTimeout;

    // Set a timeout to prevent hanging
    streamTimeout = setTimeout(() => {
      if (!streamEnded) {
        plugin.logwarn('📧 message_stream timeout, falling back to direct body access');
        streamEnded = true;
        fallbackDirectBody();
      }
    }, 10000); // 10 second timeout

    txn.message_stream.on('data', (chunk) => {
      try {
        if (chunk && !streamEnded) {
          rawEmailData += chunk.toString();
        }
      } catch (err) {
        plugin.logerror(`❌ Error processing message_stream chunk: ${err.message}`);
        if (!streamEnded) {
          streamEnded = true;
          clearTimeout(streamTimeout);
          fallbackDirectBody();
        }
      }
    });

    txn.message_stream.on('end', () => {
      if (streamEnded) return;
      streamEnded = true;
      clearTimeout(streamTimeout);
      
      if (!rawEmailData) {
        plugin.logwarn('📧 message_stream ended but no data found.');
        return fallbackDirectBody();
      }

      simpleParser(rawEmailData)
        .then(parsed => {
          bodyText = parsed.text || '';
          htmlContent = parsed.html || '';
          plugin.loginfo(`📧 Mailparser success - Text: ${bodyText.length} chars, HTML: ${htmlContent.length} chars`);
          processEmailData(bodyText, htmlContent);
        })
        .catch(parseErr => {
          plugin.logerror(`❌ Mailparser failed: ${parseErr.message}`);
          plugin.loginfo('📧 Falling back to direct body access...');
          fallbackDirectBody();
        });
    });

    txn.message_stream.on('error', (err) => {
      if (streamEnded) return;
      streamEnded = true;
      clearTimeout(streamTimeout);
      plugin.logerror(`❌ message_stream error: ${err.message}`);
      fallbackDirectBody();
    });
  }
  else {
    fallbackDirectBody();
  }

  function fallbackDirectBody() {
    if (txn.body) {
      plugin.loginfo('📧 Processing email body directly...');
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
    } else {
      plugin.logwarn('📧 No body found in transaction.');
    }

    processEmailData(bodyText, htmlContent);
  }
};
