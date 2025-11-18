#!/bin/sh
# Entrypoint script to inject runtime configuration

# Create config.js with the actual environment variable value
cat > /usr/share/nginx/html/config.js << EOF
window.ENV = {
  REACT_APP_BACKEND_URL: "${REACT_APP_BACKEND_URL}"
};
EOF

# Start nginx
exec nginx -g "daemon off;"
