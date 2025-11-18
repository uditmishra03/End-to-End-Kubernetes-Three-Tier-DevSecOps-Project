#!/bin/sh
# Entrypoint script to inject runtime configuration

echo "Injecting backend URL: ${REACT_APP_BACKEND_URL}"

# Inject runtime config by replacing the empty script tag
sed -i "s|<script id=\"runtime-config\"></script>|<script id=\"runtime-config\">window.ENV={REACT_APP_BACKEND_URL:\"${REACT_APP_BACKEND_URL}\"}</script>|g" /usr/share/nginx/html/index.html

# Verify injection worked
if grep -q "window.ENV" /usr/share/nginx/html/index.html; then
    echo "✓ Config injection successful"
    grep "window.ENV" /usr/share/nginx/html/index.html
else
    echo "✗ Config injection failed - check logs"
    cat /usr/share/nginx/html/index.html | grep -A 2 -B 2 "runtime-config" || echo "runtime-config tag not found"
fi

# Start nginx
exec nginx -g "daemon off;"
