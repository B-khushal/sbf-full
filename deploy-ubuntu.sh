#!/bin/bash

echo "🔄 Starting deployment process..."

# Create log directory if it doesn't exist
sudo mkdir -p /var/log/sbf
sudo chown -R $USER:$USER /var/log/sbf

# Stop all running processes
echo "⏹️ Stopping all PM2 processes..."
pm2 stop all
pm2 delete all

# Kill any remaining Node.js processes
echo "🔍 Checking for remaining Node.js processes..."
pkill node

# Wait for processes to fully stop
echo "⏳ Waiting for processes to stop..."
sleep 5

# Start the server with PM2
echo "▶️ Starting server with PM2..."
pm2 start ecosystem.config.js --env production

# Save PM2 configuration
echo "💾 Saving PM2 configuration..."
pm2 save

# Display status
echo "📊 Current PM2 status:"
pm2 status

echo "📝 Tailing logs for any errors..."
pm2 logs --lines 20

echo "✅ Deployment complete!" 