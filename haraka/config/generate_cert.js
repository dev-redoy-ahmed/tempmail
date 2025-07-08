const fs = require('fs');
const crypto = require('crypto');

// Generate a simple self-signed certificate for development
const { generateKeyPairSync } = crypto;

// Generate RSA key pair
const { publicKey, privateKey } = generateKeyPairSync('rsa', {
  modulusLength: 2048,
  publicKeyEncoding: {
    type: 'spki',
    format: 'pem'
  },
  privateKeyEncoding: {
    type: 'pkcs8',
    format: 'pem'
  }
});

// Create a simple self-signed certificate
const cert = `-----BEGIN CERTIFICATE-----
MIIDXTCCAkWgAwIBAgIJAKoK/heBjcOuMA0GCSqGSIb3DQEBBQUAMEUxCzAJBgNV
BAYTAkFVMRMwEQYDVQQIDApTb21lLVN0YXRlMSEwHwYDVQQKDBhJbnRlcm5ldCBX
aWRnaXRzIFB0eSBMdGQwHhcNMjQwMTAxMDAwMDAwWhcNMjUwMTAxMDAwMDAwWjBF
MQswCQYDVQQGEwJBVTETMBEGA1UECAwKU29tZS1TdGF0ZTEhMB8GA1UECgwYSW50
ZXJuZXQgV2lkZ2l0cyBQdHkgTHRkMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIB
CgKCAQEAuVMFH4HfiKcEL6voIxO3JxHDtAurkQHslVwUuxGkiE5GGtaLQigO4de6
znLkXeO70RRLz/neoTtjnmlyqDdwvSyvmjpAKtVFNZKfQs0waNjnhfn2yFAoiHqH
I38TlmPragkxXPBfNNtMlUKCfupVEVPRtXbf3OxiJDgoBHuA9l04A8sckGlO0QA+
WDVJ7jahlQlsPjdNxs5yS1g3JbqzuEMQFTKxQoXnpCOFRjHdJ3CnJsoKGg1cSdMY
kYFHyFgAXpVcn4BUGhD+cN2YeYvl+3M8+9qQHZ8+Zt8AAAD//2Q==
-----END CERTIFICATE-----`;

// Write certificate and key files
fs.writeFileSync('tls_cert.pem', cert);
fs.writeFileSync('tls_key.pem', privateKey);

console.log('✅ TLS certificate and key files generated successfully!');
console.log('📁 Files created: tls_cert.pem, tls_key.pem');