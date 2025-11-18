#!/bin/sh
# Entrypoint script to inject runtime configuration

# Inject runtime config directly into index.html before React loads
sed -i "s|<!-- Runtime config will be injected here by entrypoint.sh -->|<script>window.ENV={REACT_APP_BACKEND_URL:\"${REACT_APP_BACKEND_URL}\"}</script>|g" /usr/share/nginx/html/index.html

# Start nginx
exec nginx -g "daemon off;"
