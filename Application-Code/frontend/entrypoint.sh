#!/bin/sh
set -e

echo "Creating runtime config..."
echo "Backend URL: ${REACT_APP_BACKEND_URL}"

# Create config.js in the nginx html directory  
cat > /usr/share/nginx/html/env-config.js << 'EOF'
window._env_ = {
  REACT_APP_BACKEND_URL: "BACKEND_URL_PLACEHOLDER"
};
EOF

# Replace placeholder with actual value
sed -i "s|BACKEND_URL_PLACEHOLDER|${REACT_APP_BACKEND_URL}|g" /usr/share/nginx/html/env-config.js

echo "Config created successfully:"
cat /usr/share/nginx/html/env-config.js

# Start nginx
exec nginx -g "daemon off;"
