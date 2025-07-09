module.exports = {
  apps: [{
    name: 'sbf-backend',
    script: './server.js',
    instances: 1,
    exec_mode: 'fork',
    watch: false,
    max_memory_restart: '1G',
    env_production: {
      NODE_ENV: 'production',
      PORT: 5001
    },
    error_file: '/var/log/sbf/error.log',
    out_file: '/var/log/sbf/out.log',
    time: true,
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    merge_logs: true,
    max_restarts: 10,
    restart_delay: 4000,
    wait_ready: true,
    kill_timeout: 3000,
    autorestart: true
  }]
}; 