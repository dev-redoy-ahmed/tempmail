# MongoDB Atlas Integration for TempMail API

## Overview

The TempMail API now supports a dual-database architecture:
- **Redis**: Used for real-time email reception and temporary storage
- **MongoDB Atlas**: Used for persistent email generation and device-based management

## Database Roles

### Redis (Real-time Email Reception)
- Stores incoming emails temporarily
- Handles real-time Socket.IO notifications
- Manages email queues and statistics
- Provides fast access for email retrieval
- Stores received email content

### MongoDB Atlas (Email Generation & Device Management)
- Stores generated email addresses with device associations
- Tracks email statistics per device
- Provides persistent storage for device-based features
- Maintains email generation history

## New API Endpoints

### Email Generation (Enhanced)
```
GET /generate?deviceId=<device_id>
Headers: Authorization: supersecretapikey123
```
Now requires a `deviceId` parameter and stores the generated email in MongoDB.

### Device Management

#### Get Device Emails
```
GET /device/:deviceId/emails/mongo?limit=50&skip=0
Headers: Authorization: supersecretapikey123
```
Retrieve all emails generated for a specific device.

#### Get Device Statistics
```
GET /device/:deviceId/stats/mongo
Headers: Authorization: supersecretapikey123
```
Get statistics for a specific device including total emails and recent activity.

#### Delete Device Emails
```
DELETE /device/:deviceId/emails/mongo
Headers: Authorization: supersecretapikey123
```
Delete all emails associated with a specific device.

### Health Check (Enhanced)
```
GET /health
```
Now shows both Redis and MongoDB connection status.

## MongoDB Collections

### `emails` Collection
Stores generated email addresses with device tracking:
```json
{
  "_id": "ObjectId",
  "deviceId": "unique-device-identifier",
  "email": "generated@domain.com",
  "type": "generated|custom",
  "emailCount": 0,
  "lastActivity": "2024-01-01T00:00:00.000Z",
  "createdAt": "2024-01-01T00:00:00.000Z"
}
```

**Note**: Received emails are stored in Redis for real-time access and temporary storage.

## Configuration

### Environment Variables
Set the following environment variables or create a `.env` file:

```bash
# MongoDB Atlas Connection
MONGODB_URL=mongodb+srv://<username>:<password>@<cluster-name>.mongodb.net/tempmail?retryWrites=true&w=majority

# Redis Connection (existing)
REDIS_URL=redis://178.128.213.160:6379

# API Configuration
PORT=3000
API_KEY=supersecretapikey123
```

### MongoDB Atlas Setup
1. Create a MongoDB Atlas account at https://www.mongodb.com/atlas
2. Create a new cluster
3. Create a database user with read/write permissions
4. Whitelist your server's IP address
5. Get your connection string and replace the placeholders in MONGODB_URL

### Database Names
- MongoDB Database: `tempmail`
- Redis: Uses default database

## Email Flow

1. **Email Generation**: 
   - Client requests email with device ID
   - Email stored in both Redis (for real-time) and MongoDB (for persistence)
   - Device association created

2. **Email Reception**:
   - Haraka receives email and stores in Redis
   - API processes email and updates MongoDB statistics
   - Real-time notifications sent via Socket.IO
   - Device-specific email counts updated

3. **Email Retrieval**:
   - Real-time emails: Retrieved from Redis
   - Device management: Retrieved from MongoDB
   - Statistics and history: MongoDB

## Benefits

- **Scalability**: Redis handles high-frequency operations, MongoDB provides persistent storage
- **Device Management**: Track emails per device across sessions
- **Analytics**: Detailed statistics and usage patterns
- **Reliability**: Dual storage ensures data persistence
- **Performance**: Fast real-time operations with Redis, complex queries with MongoDB

## Usage Examples

### Generate Email for Device
```bash
curl -X GET "http://localhost:3000/generate?deviceId=mobile123" \
  -H "Authorization: supersecretapikey123"
```

### Get Device Statistics
```bash
curl -X GET "http://localhost:3000/device/mobile123/stats/mongo" \
  -H "Authorization: supersecretapikey123"
```

### Get Device Emails
```bash
curl -X GET "http://localhost:3000/device/mobile123/emails/mongo?limit=10" \
  -H "Authorization: supersecretapikey123"
```