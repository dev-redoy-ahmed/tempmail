# RedsMail Admin Panel

## Overview
The RedsMail Admin Panel is a web-based interface for managing your temporary email system. It features a deep black theme and provides comprehensive control over domains, email monitoring, and system statistics.

## Features

### 🎨 **Deep Black Theme Design**
- Modern dark interface with green accent colors
- Responsive layout with sidebar navigation
- Real-time updates and notifications

### 🌐 **Domain Management**
- Add new domains to Haraka's host_list
- Delete existing domains
- Real-time domain validation
- Automatic sync with Haraka configuration

### 📊 **Dashboard Statistics**
- Total emails received
- Active domains count
- Active users (24-hour period)
- Auto-refresh every 30 seconds

### 📧 **Email Monitoring**
- Real-time email notifications via WebSocket
- Live email feed display
- Email details (from, to, subject, date)
- Last 50 emails history

### ⚙️ **System Settings**
- API key management
- System status monitoring
- Connection status indicator

## Installation & Setup

### 1. Start the Mail API Server
```bash
cd mail-api
npm install
node index.js
```

### 2. Access Admin Panel
Open your browser and navigate to:
```
http://localhost:3000/admin
```

## Usage

### Adding a Domain
1. Go to "Manage Domains" page
2. Enter domain name (e.g., `newdomain.com`)
3. Click "Add Domain" button
4. Domain will be automatically added to Haraka's `host_list` file

### Deleting a Domain
1. Go to "Manage Domains" page
2. Find the domain in the list
3. Click the "Delete" button
4. Confirm deletion
5. Domain will be removed from Haraka's `host_list` file

### Monitoring Emails
1. Go to "Email Monitor" page
2. View real-time incoming emails
3. See email details including sender, recipient, subject, and timestamp

### Viewing Statistics
1. Dashboard shows key metrics:
   - **Total Emails**: All emails in the database
   - **Active Domains**: Number of configured domains
   - **Active Users**: Unique recipients in last 24 hours

## API Endpoints

All admin endpoints require the API key parameter: `?key=supersecretapikey123`

### Domain Management
- `GET /admin/domains` - Get all domains
- `POST /admin/domains/add` - Add new domain
- `DELETE /admin/domains/delete` - Delete domain

### Statistics
- `GET /admin/stats` - Get system statistics
- `GET /admin/recent-emails` - Get recent emails

## File Structure
```
mail-api/
├── public/
│   ├── admin.html     # Admin panel HTML
│   ├── admin.css      # Deep black theme styles
│   └── admin.js       # Admin panel functionality
├── index.js           # Main API server with admin routes
└── package.json       # Dependencies
```

## Security
- All admin endpoints are protected with API key authentication
- Domain validation prevents invalid entries
- File system operations are safely handled
- Real-time updates via secure WebSocket connection

## Technical Details

### Technologies Used
- **Frontend**: HTML5, CSS3, JavaScript (ES6+)
- **Backend**: Node.js, Express.js
- **Database**: MongoDB with Mongoose
- **Real-time**: Socket.IO
- **File Operations**: Node.js fs module

### Domain File Integration
The admin panel directly reads and writes to Haraka's `host_list` file:
- **Path**: `../haraka/config/host_list`
- **Format**: One domain per line
- **Comments**: Lines starting with `#` are ignored

### Real-time Features
- WebSocket connection for live email notifications
- Auto-refresh statistics every 30 seconds
- Instant domain list updates
- Connection status monitoring

## Troubleshooting

### Admin Panel Not Loading
- Ensure mail-api server is running on port 3000
- Check that `public` folder exists with admin files
- Verify API key is correct

### Domain Management Issues
- Ensure Haraka `host_list` file exists and is writable
- Check file path configuration in `index.js`
- Verify domain format (valid domain names only)

### Real-time Updates Not Working
- Check WebSocket connection in browser console
- Ensure Socket.IO is properly connected
- Verify server is running and accessible

## Customization

### Changing Theme Colors
Edit `admin.css` and modify these CSS variables:
- Primary color: `#00ff88` (green accent)
- Background: `#0a0a0a` (deep black)
- Secondary: `#1a1a1a` (dark gray)

### Adding New Features
1. Add new routes in `index.js`
2. Update admin panel HTML structure
3. Implement frontend functionality in `admin.js`
4. Style new components in `admin.css`

---

**Note**: This admin panel is designed for VPS deployment and integrates seamlessly with the Haraka SMTP server configuration.