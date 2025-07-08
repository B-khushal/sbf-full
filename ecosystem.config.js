module.exports = {
  apps: [
    {
      name: 'sbf-backend',
      script: './server/server.js',
      instances: 1, // or 'max' for all CPU cores
      exec_mode: 'cluster',
      env: {
        NODE_ENV: 'production',
        PORT: 5000
      },
      env_production: {
        NODE_ENV: 'production',
        PORT: 5000
      },
      env_development: {
        NODE_ENV: 'development',
        PORT: 5000
      },
      // Logging
      error_file: '/var/log/sbf-florist/backend-error.log',
      out_file: '/var/log/sbf-florist/backend-out.log',
      log_file: '/var/log/sbf-florist/backend-combined.log',
      time: true,
      
      // Process management
      watch: false,
      ignore_watch: [
        'node_modules',
        'uploads',
        'logs',
        '.git'
      ],
      max_memory_restart: '1G',
      min_uptime: '10s',
      max_restarts: 10,
      
      // Node.js specific
      node_args: '--max-old-space-size=1024',
      
      // Auto restart settings
      autorestart: true,
      restart_delay: 4000,
      
      // Health monitoring
      health_check_grace_period: 3000,
      health_check_fatal_exceptions: true,
      
      // Advanced PM2 features
      merge_logs: true,
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      
      // Instance management
      listen_timeout: 8000,
      kill_timeout: 5000
    }
  ],

  // PM2 deploy configuration
  deploy: {
    production: {
      user: 'deploy',
      host: ['your-server-ip'],
      ref: 'origin/main',
      repo: 'https://github.com/your-username/your-repo.git',
      path: '/var/www/sbf-florist',
      'pre-deploy-local': '',
      'post-deploy': 'cd server && npm install --production && cd ../sbf-main && npm install && npm run build && pm2 reload ecosystem.config.js --env production',
      'pre-setup': ''
    }
  }
}; 