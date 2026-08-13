#!/bin/bash

# Okta Authentication Setup
# --------------------------
# The Okta authentication module is disabled by default in app-config.json.
# To enable it for local development, run this script from the VERA/ directory
# before running `tuist generate`.
#
# Usage:
#   1. Copy this file: cp Scripts/setUpOkta.example.sh Scripts/setUpOkta.sh
#   2. Fill in your Okta credentials below
#   3. Run: ./Scripts/setUpOkta.sh
#
# This will:
#   - Enable the authentication flag in app-config.json so Tuist includes the VERAOKTA module
#   - Generate Okta.plist with your OIDC configuration

# --- Okta OIDC credentials ---
export OKTA_ISSUER_URL=https://your-org.okta.com
export OKTA_CLIENT_ID=your_okta_client_id
export OKTA_REDIRECT_URI=https://your-app.example.com/api/auth/callback/okta
export OKTA_LOGOUT_REDIRECT_URI=https://your-app.example.com
export OKTA_SCOPE="openid profile offline_access"

# --- Enable authentication and ensure Okta is listed as an ID provider ---
jq '.authSettings.allowAuthentication = true | .authSettings.idProviders |= (if contains(["okta"]) then . else . + ["okta"] end)' Config/app-config.json > Config/app-config.tmp && mv Config/app-config.tmp Config/app-config.json
echo "✅ Authentication enabled with Okta provider in Config/app-config.json"

# --- Generate Okta.plist ---
./Scripts/generateOktaConfig.sh

# --- Regenerate AppConfig.swift with authentication enabled ---
python3 ./Scripts/generate-app-config.py
