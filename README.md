# TempMail - Complete Email Management System

A comprehensive temporary email management system built with Haraka mail server, Node.js admin panel, and Flutter mobile application.

## 🚀 Features

### Core Email System
- **Haraka Mail Server** - High-performance SMTP server
- **Real-time Email Processing** - Instant email delivery via Socket.IO
- **MongoDB Integration** - Reliable email storage and retrieval
- **Device-based Email Management** - Track emails per device/user

### Advanced Admin Panel
- **Dashboard** - System overview with statistics
- **Domain Management** - Add/remove email domains
- **API Management** - Comprehensive API endpoint management
- **Ads Management** - Configure Android app advertisements
- **Ads Settings** - Manage ad configurations
- **App Updates** - Control app version updates
- **Email Logs & Analytics** - Comprehensive email tracking
- **System Health Monitoring** - Real-time status checks

### Mobile Application (Flutter)
- **Cross-platform Support** - iOS, Android, Web, Desktop
- **Modern UI/UX** - Clean and intuitive interface with animations
- **Real-time Email Reception** - Live email updates via Socket.IO
- **Email Generation** - Create temporary emails instantly
- **Premium Features** - In-app purchases for enhanced functionality
- **Custom Domain Support** - Use custom domains for emails
- **Email History** - View detailed email history
- **Ads Integration** - Monetization through advertisements
- **Auto-update System** - Automatic app update checking

## 📁 Project Structure

```
tempmail/
├── admin/                  # Admin panel (Node.js + Express)
│   ├── models/            # MongoDB models
│   │   ├── AdsConfig.js   # Ads configuration model
│   │   ├── AdsSettings.js # Ads settings model
│   │   └── AppUpdate.js   # App update model
│   ├── views/             # EJS templates
│   │   ├── dashboard.ejs  # Main dashboard
│   │   ├── domains.ejs    # Domain management
│   │   ├── api-management.ejs # API management
│   │   ├── ads-management.ejs # Ads management
│   │   ├── ads-settings.ejs   # Ads settings
│   │   └── app-updates.ejs    # App updates
│   ├── public/            # Static assets
│   ├── server.js          # Main server file
│   └── package.json       # Dependencies
├── haraka/                # Mail server configuration
│   ├── config/           # Server settings
│   ├── plugins/          # Custom plugins
│   └── package.json      # Dependencies
├── mailapi/              # Node.js API server
│   ├── index.js         # Main API server
│   ├── public/          # Admin panel files
│   └── package.json     # Dependencies
├── rmail/               # Original Flutter app
└── turbomail/           # Enhanced Flutter app
    ├── lib/
    │   ├── main.dart    # App entry point
    │   ├── providers/   # State management
    │   ├── screens/     # UI screens
    │   ├── services/    # API and business logic
    │   └── widgets/     # Reusable UI components
    ├── android/         # Android configuration
    ├── ios/            # iOS configuration
    └── pubspec.yaml    # Flutter dependencies
```

## 🛠️ Installation & Setup

### Prerequisites
- Node.js (v14 or higher)
- MongoDB
- Flutter SDK
- Git

### 1. Clone Repository
```bash
git clone https://github.com/dev-redoy-ahmed/tempmail.git
cd tempmail
```

### 2. Setup Admin Panel
```bash
cd admin
npm install
node server.js
```

### 3. Setup Mail API Server
```bash
cd mailapi
npm install
node index.js
```

### 4. Setup Haraka Mail Server
```bash
cd haraka
npm install
node haraka.js
```

### 5. Setup Flutter App
```bash
cd turbomail
flutter pub get
flutter run
```

## 🔧 Configuration

### Environment Variables
Create `.env` file in respective directories:

**Admin Panel (.env):**
```
MONGO_URI=mongodb://localhost:27017/tempmail
PORT=3003
ADMIN_API_KEY=your_admin_api_key
```

**Mail API (.env):**
```
MONGO_URI=mongodb://localhost:27017/tempmail
PORT=3001
API_KEY=your_api_key
```

### Haraka Configuration
- Edit `haraka/config/` files as needed
- Configure domains in `haraka/config/host_list`
- Set up plugins in `haraka/config/plugins`

## 📊 Admin Panel

Access the admin panel at: `http://localhost:3003`

### Features:
- **Dashboard** - System overview and statistics
- **Domain Management** - Add/remove email domains
- **API Management** - Manage API endpoints and keys
- **Ads Management** - Configure mobile app ads
- **Ads Settings** - Manage ad configurations
- **App Updates** - Control app version updates

## 🔌 API Endpoints

### Email Management
- `POST /api/generate-email` - Generate new email
- `GET /api/emails/:deviceId` - Get device emails
- `POST /api/receive-mail` - Receive incoming mail
- `DELETE /api/emails/:deviceId` - Clear device emails

### Admin Endpoints
- `GET /admin/health` - System health check
- `GET /admin/stats` - System statistics
- `GET /api/ads-config` - Get ads configuration
- `GET /api/app-update` - Get app update info
- `POST /admin/retry-failed-emails` - Retry failed emails

## 🔄 Real-time Features

### Socket.IO Events
- `new-mail` - New email received
- `email-status` - Email processing status
- `system-alert` - System notifications

## 🛡️ Security Features
- API Key Authentication - Secure admin access
- Input Validation - Prevent malicious inputs
- Error Handling - Comprehensive error management
- Logging - Detailed audit trails

## 📱 Mobile App Features

### Core Features
- Email Generation - Create temporary emails
- Real-time Reception - Instant email delivery
- Email Management - View, delete, organize emails
- Cross-platform - Works on all devices

### Premium Features
- Custom Domains - Use your own domains
- Extended Email Retention - Keep emails longer
- Priority Support - Get help faster
- Ad-free Experience - Remove advertisements

### Monetization
- In-app Purchases - Premium feature unlocking
- Advertisement Integration - Banner, interstitial, and native ads
- Subscription Model - Monthly/yearly premium plans

## 🔧 Development

### Running in Development Mode
```bash
# Start Admin Panel
cd admin && npm run dev

# Start API server
cd mailapi && npm run dev

# Start Haraka server
cd haraka && npm start

# Start Flutter app
cd turbomail && flutter run
```

### Testing
```bash
# Test API endpoints
cd mailapi && npm test

# Test Flutter app
cd turbomail && flutter test
```

## 📈 Monitoring & Analytics
- Email Statistics - Track email volumes
- Device Analytics - Per-device usage stats
- System Health - Monitor server performance
- Failed Email Tracking - Identify and resolve issues
- Revenue Analytics - Track premium subscriptions and ad revenue

## 🚀 Deployment

### Production Setup
1. Configure environment variables
2. Set up MongoDB cluster
3. Configure reverse proxy (nginx)
4. Set up SSL certificates
5. Configure domain DNS
6. Deploy to VPS/Cloud

### VPS Deployment Example
```bash
# Clone repository
git clone https://github.com/dev-redoy-ahmed/tempmail.git
cd tempmail

# Install dependencies
cd admin && npm install
cd ../mailapi && npm install
cd ../haraka && npm install

# Start services with PM2
pm2 start admin/server.js --name admin
pm2 start mailapi/index.js --name mailapi
pm2 start haraka/haraka.js --name haraka
```

## 🤝 Contributing
1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## 📄 License
This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support
For support and questions:
- Create an issue on GitHub
- Check the documentation
- Review the admin panel logs

## 🔗 Links
- **GitHub Repository**: https://github.com/dev-redoy-ahmed/tempmail
- **Live Demo**: http://165.22.109.153:3003 (Admin Panel)
- **API Documentation**: Available in admin panel

---

Built with ❤️ using Node.js, Flutter, and Haraka

**Version**: 2.0.0  
**Last Updated**: December 2024