#!/bin/bash

# Generates Okta.plist in the VERAApp main bundle with OIDC configuration.
# Usage:
#   export OKTA_ISSUER_URL=https://your-org.okta.com
#   export OKTA_CLIENT_ID=your_client_id
#   export OKTA_REDIRECT_URI=https://your-app.example.com/api/auth/callback/okta
#   export OKTA_LOGOUT_REDIRECT_URI=https://your-app.example.com
#   export OKTA_SCOPE="openid profile offline_access"
#   ./Scripts/generateOktaConfig.sh
#
# All variables except OKTA_SCOPE are required.
# OKTA_SCOPE defaults to "openid profile offline_access" if not set.

set -e  # Exit on error

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERA_DIR="$SCRIPT_DIR/.."

# Validate VERA directory exists
if [ ! -d "$VERA_DIR/VERAOKTA" ]; then
    echo "❌ Error: VERAOKTA directory not found at $VERA_DIR/VERAOKTA"
    exit 1
fi

cd "$VERA_DIR"

# Validate required environment variables
MISSING_VARS=()

if [ -z "$OKTA_ISSUER_URL" ]; then
    MISSING_VARS+=("OKTA_ISSUER_URL")
fi

if [ -z "$OKTA_CLIENT_ID" ]; then
    MISSING_VARS+=("OKTA_CLIENT_ID")
fi

if [ -z "$OKTA_REDIRECT_URI" ]; then
    MISSING_VARS+=("OKTA_REDIRECT_URI")
fi

if [ -z "$OKTA_LOGOUT_REDIRECT_URI" ]; then
    MISSING_VARS+=("OKTA_LOGOUT_REDIRECT_URI")
fi

if [ ${#MISSING_VARS[@]} -ne 0 ]; then
    echo "❌ Error: The following required environment variables are not set:"
    for var in "${MISSING_VARS[@]}"; do
        echo "   - $var"
    done
    echo ""
    echo "Usage:"
    echo "  export OKTA_ISSUER_URL=https://your-org.okta.com"
    echo "  export OKTA_CLIENT_ID=your_client_id"
    echo "  export OKTA_REDIRECT_URI=https://your-app.example.com/api/auth/callback/okta"
    echo "  export OKTA_LOGOUT_REDIRECT_URI=https://your-app.example.com"
    echo "  export OKTA_SCOPE=\"openid profile offline_access\"  # optional"
    echo "  ./Scripts/generateOktaConfig.sh"
    exit 1
fi

# Default scope if not provided
OKTA_SCOPE="${OKTA_SCOPE:-openid profile offline_access}"

# Output path — must be in the app target so it ends up in the main bundle
OUTPUT_DIR="VERAApp/VERA/Resources"
OUTPUT_FILE="$OUTPUT_DIR/Okta.plist"

# Create Resources directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Generate Okta.plist
cat > "$OUTPUT_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>issuer_url</key>
    <string>${OKTA_ISSUER_URL}</string>
    <key>client_id</key>
    <string>${OKTA_CLIENT_ID}</string>
    <key>redirect_uri</key>
    <string>${OKTA_REDIRECT_URI}</string>
    <key>logout_redirect_uri</key>
    <string>${OKTA_LOGOUT_REDIRECT_URI}</string>
    <key>scope</key>
    <string>${OKTA_SCOPE}</string>
</dict>
</plist>
EOF

echo "✅ Okta.plist generated"
echo "   Output: $OUTPUT_FILE"
