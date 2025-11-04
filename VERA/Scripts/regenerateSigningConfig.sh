mkdir -p Config
echo "DEVELOPMENT_TEAM = $DEVELOPMENT_TEAM" > Config/Signing.xcconfig
echo "MARKETING_VERSION = 1.0" >> Config/Signing.xcconfig
echo "CURRENT_PROJECT_VERSION = $CURRENT_PROJECT_VERSION" >> Config/Signing.xcconfig