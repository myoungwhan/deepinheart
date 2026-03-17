# WebRTC Signaling Server Deployment Guide

## Production Deployment on Linux Server

### Prerequisites

- **Node.js** 16+ 
- **Nginx** (recommended for reverse proxy)
- **SSL Certificate** (Let's Encrypt recommended)
- **PM2** (process manager)

### Step 1: Server Setup

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install PM2
sudo npm install -g pm2

# Install Nginx
sudo apt install nginx -y

# Install Certbot for SSL
sudo apt install certbot python3-certbot-nginx -y
```

### Step 2: Deploy Application

```bash
# Create application directory
sudo mkdir -p /var/www/webrtc-signaling
cd /var/www/webrtc-signaling

# Copy application files (or clone from git)
sudo cp -r /path/to/webrtc-signaling-server/* .

# Install dependencies
npm ci --only=production

# Set permissions
sudo chown -R www-data:www-data /var/www/webrtc-signaling
sudo chmod -R 755 /var/www/webrtc-signaling
```

### Step 3: Configure Environment

```bash
# Create environment file
sudo nano .env
```

Add:
```env
NODE_ENV=production
PORT=3000
```

### Step 4: Start with PM2

```bash
# Start application
pm2 start server.js --name "webrtc-signaling" --env production

# Save PM2 configuration
pm2 save

# Setup PM2 startup
pm2 startup
```

### Step 5: Configure Nginx

```bash
# Create Nginx config
sudo nano /etc/nginx/sites-available/webrtc-signaling
```

Add configuration:
```nginx
server {
    listen 80;
    server_name your-domain.com;

    # Redirect to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name your-domain.com;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
    
    # SSL Settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Security Headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # Main proxy
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Socket.IO specific
    location /socket.io/ {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Socket.IO specific timeouts
        proxy_connect_timeout 7d;
        proxy_send_timeout 7d;
        proxy_read_timeout 7d;
    }

    # Health check
    location /health {
        proxy_pass http://localhost:3000/health;
        access_log off;
    }
}
```

### Step 6: Enable Site and SSL

```bash
# Enable site
sudo ln -s /etc/nginx/sites-available/webrtc-signaling /etc/nginx/sites-enabled/

# Test Nginx config
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx

# Get SSL certificate
sudo certbot --nginx -d your-domain.com

# Test SSL renewal
sudo certbot renew --dry-run
```

### Step 7: Setup Monitoring

```bash
# Setup log rotation
sudo nano /etc/logrotate.d/webrtc-signaling
```

Add:
```
/var/www/webrtc-signaling/logs/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 644 www-data www-data
    postrotate
        pm2 reloadLogs
    endscript
}
```

### Step 8: Firewall Setup

```bash
# Configure UFW
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'
sudo ufw enable
```

## Docker Deployment

### Dockerfile

```dockerfile
FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production && npm cache clean --force

# Copy application code
COPY . .

# Create non-root user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nodejs -u 1001

# Change ownership
RUN chown -R nodejs:nodejs /app
USER nodejs

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node healthcheck.js

# Start application
CMD ["npm", "start"]
```

### docker-compose.yml

```yaml
version: '3.8'

services:
  webrtc-signaling:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - PORT=3000
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    volumes:
      - ./logs:/app/logs
    networks:
      - webrtc-network

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/ssl/certs
    depends_on:
      - webrtc-signaling
    restart: unless-stopped
    networks:
      - webrtc-network

networks:
  webrtc-network:
    driver: bridge
```

### Deploy with Docker

```bash
# Build and start
docker-compose up -d

# View logs
docker-compose logs -f webrtc-signaling

# Scale if needed
docker-compose up -d --scale webrtc-signaling=3
```

## Monitoring and Maintenance

### PM2 Monitoring

```bash
# View process status
pm2 status

# View logs
pm2 logs webrtc-signaling

# Monitor
pm2 monit

# Restart
pm2 restart webrtc-signaling

# Reload (zero downtime)
pm2 reload webrtc-signaling
```

### Health Checks

```bash
# Check server health
curl https://your-domain.com/health

# Monitor with cron
*/5 * * * * curl -f https://your-domain.com/health || pm2 restart webrtc-signaling
```

### Log Monitoring

```bash
# View real-time logs
tail -f /var/www/webrtc-signaling/logs/combined.log

# Monitor errors
grep "ERROR" /var/www/webrtc-signaling/logs/combined.log
```

## Performance Tuning

### Node.js Optimization

```bash
# Set Node.js options
export NODE_OPTIONS="--max-old-space-size=2048"

# Enable clustering in PM2
pm2 start server.js --name "webrtc-signaling" -i max
```

### Nginx Optimization

```nginx
# Add to nginx config
worker_processes auto;
worker_connections 1024;

# Enable gzip
gzip on;
gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

# Enable caching
location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

## Security Hardening

### SSL Security

```bash
# Test SSL configuration
https://www.ssllabs.com/ssltest/

# Enable HTTP/2
# Already included in Nginx config above
```

### Application Security

```bash
# Install fail2ban
sudo apt install fail2ban -y

# Configure fail2ban for Nginx
sudo nano /etc/fail2ban/jail.local
```

Add:
```ini
[nginx-http-auth]
enabled = true
filter = nginx-http-auth
logpath = /var/log/nginx/error.log
maxretry = 3
bantime = 600

[nginx-limit-req]
enabled = true
filter = nginx-limit-req
logpath = /var/log/nginx/error.log
maxretry = 10
bantime = 600
```

### Firewall Rules

```bash
# Rate limiting
sudo ufw limit ssh

# Allow only necessary ports
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

## Backup and Recovery

### Backup Script

```bash
#!/bin/bash
# backup.sh

BACKUP_DIR="/backup/webrtc-signaling"
DATE=$(date +%Y%m%d_%H%M%S)

# Create backup
mkdir -p $BACKUP_DIR
tar -czf $BACKUP_DIR/webrtc-signaling_$DATE.tar.gz /var/www/webrtc-signaling

# Keep only last 7 days
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "Backup completed: $BACKUP_DIR/webrtc-signaling_$DATE.tar.gz"
```

### Automated Backup

```bash
# Add to crontab
crontab -e

# Daily backup at 2 AM
0 2 * * * /path/to/backup.sh
```

## Troubleshooting

### Common Issues

**High CPU usage:**
```bash
# Check Node.js process
pm2 monit

# Enable clustering
pm2 delete webrtc-signaling
pm2 start server.js --name "webrtc-signaling" -i max
```

**Memory leaks:**
```bash
# Monitor memory
pm2 show webrtc-signaling

# Restart periodically
pm2 restart webrtc-signaling
```

**Connection issues:**
```bash
# Check Nginx status
sudo systemctl status nginx

# Check logs
sudo tail -f /var/log/nginx/error.log
```

**SSL issues:**
```bash
# Test certificate
sudo certbot certificates

# Renew manually
sudo certbot renew
```

This deployment guide provides a production-ready setup for the WebRTC signaling server with security, monitoring, and maintenance procedures.
