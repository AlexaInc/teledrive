#!/bin/sh

# Replace placeholders in the built JS files with environment variables
# We use a pattern that is unlikely to occur naturally

echo "Injecting runtime configuration..."

# Replace REACT_APP_TG_API_ID
if [ -n "$REACT_APP_TG_API_ID" ]; then
  find /apps/web/build -name "*.js" -exec sed -i "s/999123456789/$REACT_APP_TG_API_ID/g" {} +
fi

# Replace REACT_APP_TG_API_HASH
if [ -n "$REACT_APP_TG_API_HASH" ]; then
  find /apps/web/build -name "*.js" -exec sed -i "s/REPLACE_ME_API_HASH_PLACEHOLDER/$REACT_APP_TG_API_HASH/g" {} +
fi

# Start the application
exec yarn start
