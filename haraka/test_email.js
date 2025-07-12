const nodemailer = require('nodemailer');

// Create a test transport
const transporter = nodemailer.createTransport({
  host: '178.128.213.160',
  port: 2525,
  secure: false,
  tls: {
    rejectUnauthorized: false
  }
});

// Test email
const mailOptions = {
  from: 'test@example.com',
  to: 'user@domain.com',
  subject: 'Test Email with Body Plugin',
  text: 'This is a plain text body for testing the body plugin.',
  html: '<h1>HTML Body Test</h1><p>This is an <strong>HTML body</strong> for testing the body plugin.</p>'
};

// Send test email
transporter.sendMail(mailOptions, (error, info) => {
  if (error) {
    console.log('Error:', error);
  } else {
    console.log('Email sent successfully:', info.response);
  }
  process.exit();
});

console.log('Sending test email to Haraka server...');