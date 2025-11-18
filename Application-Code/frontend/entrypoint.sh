#!/bin/sh
# Entrypoint script to inject runtime configuration

# Replace placeholder with actual environment variable value
sed -i "s|__REACT_APP_BACKEND_URL__|${REACT_APP_BACKEND_URL}|g" /usr/share/nginx/html/config.js

# Start nginx
exec nginx -g "daemon off;"
