# VERA Dynamic Configuration System

This system allows enabling or disabling VERA application features through JSON configuration, specifically the chat module.

## Important Files

- `./Config/app-config.json`: Main configuration file
- `Scripts/generate-app-config.py`: Generates Swift code from JSON configuration
- `VERAConfiguration/VERAConfiguration/Generated/AppConfig.swift`: Auto-generated code (do not edit manually)

## How It Works

1. **Build time**: The Python script reads `app-config.json` and generates Swift code
2. **Conditional dependencies**: `Project.swift` reads the configuration and adds dependencies only if chat is enabled
3. **Conditional compilation**: Code uses `#if CHAT_ENABLED` to include or exclude chat functionality

## Chat Configuration

In `app-config.json`, the chat configuration is located at:

```json
{
  "meetingRoomSettings": {
    "allowChat": true  // true = enables chat, false = disables chat
  }
}
```

## Usage

### Enable/Disable Chat

Manually edit the `app-config.json` file:

```json
{
  "meetingRoomSettings": {
    "allowChat": true  // change to false to disable
  }
}
```

Then regenerate the project:
```bash
tuist generate
```

### Complete Workflow

1. Change configuration in `app-config.json` manually
2. Run `tuist generate` to regenerate the project
3. The system automatically:
   - Includes or excludes chat dependencies
   - Generates appropriate compilation flags
   - Compiles only necessary code

## Effects When Chat Is Disabled

- ❌ `VERAChat` and `VERAOpenTokChatPlugin` are not included as dependencies
- ❌ Chat-related code is not compiled
- ❌ Chat button does not appear in the interface
- ✅ Application works normally without chat functionality
- ✅ Build size is smaller

## Adding New Configurations

To add new configurable features:

1. Add the configuration to `app-config.json`
2. Update `Scripts/generate-app-config.py` to read the new configuration
3. Modify `Project.swift` to handle conditional dependencies
4. Use `#if FEATURE_ENABLED` in Swift code for conditional compilation

## Example of New Feature

```json
{
  "meetingRoomSettings": {
    "allowScreenShare": false
  }
}
```

Then in the code:
```swift
#if SCREENSHARE_ENABLED
import VERAScreenShare
#endif
```

## Accessing Configuration in Code

The generated configuration is available as static properties:

```swift
// Access chat setting
let chatEnabled = AppConfig.MeetingRoomSettings.allowChat

// Access other settings
let videoOnJoin = AppConfig.VideoSettings.allowVideoOnJoin
let defaultLayout = AppConfig.MeetingRoomSettings.defaultLayoutMode
let allowScreenShare = AppConfig.MeetingRoomSettings.allowScreenShare
```

## Troubleshooting

### Verify Generation Works
```bash
# Test the generation script
python3 Scripts/generate-app-config.py
```

### If `tuist generate` fails
1. Verify that `app-config.json` is valid JSON
2. Test the generation script manually: `python3 Scripts/generate-app-config.py`
3. Verify that the file `VERAConfiguration/VERAConfiguration/Generated/AppConfig.swift` has been created

### Build Settings Not Applied
1. Check that `CHAT_ENABLED` appears in **Swift Compiler - Custom Flags** → **Active Compilation Conditions**
2. Verify the script output shows "Chat enabled: true" during `tuist generate`
3. Clean and regenerate: `tuist clean && tuist generate`

## Important Notes

- The file `VERAConfiguration/VERAConfiguration/Generated/AppConfig.swift` is regenerated automatically on each build
- Never manually edit files in the `Generated/` folder
- Always run `tuist generate` after changing `app-config.json`
- Compilation flags are set automatically based on configuration
- The system has multiple fallbacks for maximum compatibility
- All configuration properties are static and can be accessed directly without instantiation