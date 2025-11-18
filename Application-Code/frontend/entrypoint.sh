#!/bin/sh
# Entrypoint script to inject runtime configuration

echo "Injecting backend URL: ${REACT_APP_BACKEND_URL}"

# Inject runtime config directly into index.html before React loads
sed -i "s|<!-- Runtime config will be injected here by entrypoint.sh -->|<script>window.ENV={REACT_APP_BACKEND_URL:\"${REACT_APP_BACKEND_URL}\"}</script>|g" /usr/share/nginx/html/index.html

# Verify injection worked
if grep -q "window.ENV" /usr/share/nginx/html/index.html; then
    echo "✓ Config injection successful"
else
    echo "✗ Config injection failed - using fallback"
fi

# Start nginx
exec nginx -g "daemon off;"
