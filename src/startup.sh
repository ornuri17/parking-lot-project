#!/bin/bash

# Update system packages
yum update -y

# Install Node.js 18.x
curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
yum install -y nodejs

# Create app directory
mkdir -p /opt/parking-app
cd /opt/parking-app

# Copy the application files from /tmp/app (will be uploaded via terraform)
cp -r /tmp/app/* .

# Install dependencies
npm install

# Install PM2 globally
npm install -g pm2

# Build the application
npm run build

# Start the application with PM2
pm2 start dist/app.js --name parking-app

# Set PM2 to start on boot
env PATH=$PATH:/usr/bin pm2 startup systemd -u ec2-user --hp /home/ec2-user 