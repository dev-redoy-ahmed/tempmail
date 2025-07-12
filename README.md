# RedsMail - Complete Email Management System

A comprehensive email management system built with Haraka mail server, Node.js API, and Flutter mobile application.

## 🚀 Features

### Core Email System
- **Haraka Mail Server** - High-performance SMTP server
- **Real-time Email Processing** - Instant email delivery via Socket.IO
- **MongoDB Integration** - Reliable email storage and retrieval
- **Device-based Email Management** - Track emails per device/user

### Advanced Admin Panel
- **Email Logs & Analytics** - Comprehensive email tracking
- **System Health Monitoring** - Real-time status checks
- **Failed Email Recovery** - Automatic retry mechanisms
- **Device Analytics** - Per-user/device email statistics
- **Activity Logging** - Detailed audit trails

### Mobile Application (Flutter)
- **Cross-platform Support** - iOS, Android, Web, Desktop
- **Real-time Email Reception** - Live email updates
- **Email Generation** - Create temporary emails
- **Modern UI/UX** - Clean and intuitive interface

## 📁 Project Structure

```
redsmail/
├── haraka/                 # Mail server configuration
│   ├── config/            # Server settings
│   ├── plugins/           # Custom plugins
│   └── package.json       # Dependencies
├── mailapi/               # Node.js API server
│   ├── index.js          # Main API server
│   ├── public/           # Admin panel files
│   └── package.json      # Dependencies
└── rmail/                 # Flutter mobile app
    ├── lib/              # Dart source code
    ├── android/          # Android configuration
    ├── ios/              # iOS configuration
    └── pubspec.yaml      # Flutter dependencies
```

## 🛠️ Installation & Setup

### Prerequisites
- Node.js (v14 or higher)
- MongoDB
- Flutter SDK
- Git

### 1. Clone Repository
```bash
git clone https://github.com/YOUR_USERNAME/redsmail.git
cd redsmail
```

### 2. Setup Mail API Server
```bash
cd mailapi
npm install
node index.js
```

### 3. Setup Haraka Mail Server
```bash
cd haraka
npm install
node haraka.js
```

### 4. Setup Flutter App
```bash
cd rmail
flutter pub get
flutter run
```

## 🔧 Configuration

### Environment Variables
Create `.env` file in `mailapi/` directory:
```env
MONGO_URI=mongodb://178.128.213.160:27017/redsmail
PORT=3000
API_KEY=your_admin_api_key
```

### Haraka Configuration
- Edit `haraka/config/` files as needed
- Configure domains in `haraka/config/host_list`
- Set up plugins in `haraka/config/plugins`

## 📊 Admin Panel

Access the admin panel at: `http://178.128.213.160:3000/admin`

### Features:
- **Dashboard** - System overview and statistics
- **Domain Management** - Add/remove email domains
- **Email Logs** - Comprehensive email tracking
- **System Health** - Monitor server status
- **Failed Email Recovery** - Retry failed operations

## 🔌 API Endpoints

### Email Management
- `POST /api/generate-email` - Generate new email
- `GET /api/emails/:deviceId` - Get device emails
- `POST /api/receive-mail` - Receive incoming mail
- `DELETE /api/emails/:deviceId` - Clear device emails

### Admin Endpoints
- `GET /admin/health` - System health check
- `GET /admin/stats` - System statistics
- `POST /admin/retry-failed-emails` - Retry failed emails
- `GET /admin/activity` - Activity logs

## 🔄 Real-time Features

### Socket.IO Events
- `new-mail` - New email received
- `email-status` - Email processing status
- `system-alert` - System notifications

## 🛡️ Security Features

- **API Key Authentication** - Secure admin access
- **Input Validation** - Prevent malicious inputs
- **Error Handling** - Comprehensive error management
- **Logging** - Detailed audit trails

## 📱 Mobile App Features

- **Email Generation** - Create temporary emails
- **Real-time Reception** - Instant email delivery
- **Email Management** - View, delete, organize emails
- **Cross-platform** - Works on all devices

## 🔧 Development

### Running in Development Mode
```bash
# Start API server
cd mailapi && npm run dev

# Start Haraka server
cd haraka && npm start

# Start Flutter app
cd rmail && flutter run
```

### Testing
```bash
# Test API endpoints
cd mailapi && npm test

# Test Flutter app
cd rmail && flutter test
```

## 📈 Monitoring & Analytics

- **Email Statistics** - Track email volumes
- **Device Analytics** - Per-device usage stats
- **System Health** - Monitor server performance
- **Failed Email Tracking** - Identify and resolve issues

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support and questions:
- Create an issue on GitHub
- Check the documentation
- Review the admin panel logs

## 🚀 Deployment

### Production Setup
1. Configure environment variables
2. Set up MongoDB cluster
3. Configure reverse proxy (nginx)
4. Set up SSL certificates
5. Configure domain DNS

### Docker Support (Coming Soon)
```bash
docker-compose up -d
```

---

**Built with ❤️ using Node.js, Flutter, and Haraka**