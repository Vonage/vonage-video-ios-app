#!/bin/bash

# Okta Authentication Setup
# Usage:
#   1. cp Scripts/setUpOkta.example.sh Scripts/setUpOkta.sh
#   2. Fill in your Okta credentials below
#   3. ./Scripts/setUpOkta.sh  (from VERA/)

export OKTA_ISSUER_URL=https://your-org.okta.com
export OKTA_CLIENT_ID=your_okta_client_id
export OKTA_REDIRECT_URI=https://your-app.example.com/api/auth/callback/okta
export OKTA_LOGOUT_REDIRECT_URI=https://your-app.example.com
export OKTA_SCOPE="openid profile offline_access"

# Enable authentication in app-config.json
jq '.authSettings.allowAuthentication = true | .authSettings.idProviders |= (if contains(["okta"]) then . else . + ["okta"] end)' Config/app-config.json > Config/app-config.tmp && mv Config/app-config.tmp Config/app-config.json
echo "✅ Authentication enabled in Config/app-config.json"

./Scripts/generateOktaConfig.sh
python3 ./Scripts/generate-app-config.py
