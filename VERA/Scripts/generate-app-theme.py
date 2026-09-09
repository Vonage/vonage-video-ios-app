#!/usr/bin/env python3

import json
import os

def generate_semantic_colors(light_colors, dark_colors, output_dir):
    """Generate SemanticColors.xcassets from light and dark color dictionaries"""

    # Validate that light and dark have the same keys
    light_keys = set(light_colors.keys())
    dark_keys = set(dark_colors.keys())

    if light_keys != dark_keys:
        missing_in_light = dark_keys - light_keys
        missing_in_dark = light_keys - dark_keys

        if missing_in_light:
            print(f"❌ Error: colors.light missing keys present in colors.dark: {', '.join(sorted(missing_in_light))}")
        if missing_in_dark:
            print(f"❌ Error: colors.dark missing keys present in colors.light: {', '.join(sorted(missing_in_dark))}")
        exit(1)

    # Clean up existing .colorset directories to avoid phantom assets
    if os.path.exists(output_dir):
        for item in os.listdir(output_dir):
            if item.endswith('.colorset'):
                colorset_path = os.path.join(output_dir, item)
                import shutil
                shutil.rmtree(colorset_path)

    # Create output directory
    os.makedirs(output_dir, exist_ok=True)

    # Generate Contents.json for the color set
    contents_json = {
        "info": {
            "author": "xcode",
            "version": 1
        }
    }

    with open(os.path.join(output_dir, 'Contents.json'), 'w') as f:
        json.dump(contents_json, f, indent=2)

    def hex_to_rgba_components(hex_color, token_name=""):
        """Convert hex color to RGBA components for Xcode with 3-decimal precision"""
        # Validate hex color format
        if not isinstance(hex_color, str) or not hex_color.startswith('#'):
            print(f"❌ Error: Invalid color format for {token_name}: {hex_color} (must start with #)")
            exit(1)

        hex_color = hex_color.lstrip('#')

        # Validate hex characters
        if not all(c in '0123456789ABCDEFabcdef' for c in hex_color):
            print(f"❌ Error: Invalid hex characters in color {token_name}: #{hex_color}")
            exit(1)

        # Support both 6-character (#RRGGBB) and 8-character (#RRGGBBAA) formats
        if len(hex_color) == 6:
            r = int(hex_color[0:2], 16) / 255.0
            g = int(hex_color[2:4], 16) / 255.0
            b = int(hex_color[4:6], 16) / 255.0
            a = 1.0
        elif len(hex_color) == 8:
            r = int(hex_color[0:2], 16) / 255.0
            g = int(hex_color[2:4], 16) / 255.0
            b = int(hex_color[4:6], 16) / 255.0
            a = int(hex_color[6:8], 16) / 255.0
        else:
            print(f"❌ Error: Invalid color format for {token_name}: #{hex_color} (expected 6 or 8 hex digits)")
            exit(1)

        # Return components with 3 decimal places
        return {
            "red": f"{r:.3f}",
            "green": f"{g:.3f}",
            "blue": f"{b:.3f}",
            "alpha": f"{a:.3f}"
        }

    def create_color_set(name, light_hex, dark_hex):
        """Create a .colorset directory with Contents.json"""
        color_dir = os.path.join(output_dir, f"{name}.colorset")
        os.makedirs(color_dir, exist_ok=True)

        light_components = hex_to_rgba_components(light_hex, f"{name} (light)")
        dark_components = hex_to_rgba_components(dark_hex, f"{name} (dark)")

        color_json = {
            "colors": [
                {
                    "color": {
                        "color-space": "srgb",
                        "components": {
                            "red": light_components["red"],
                            "green": light_components["green"],
                            "blue": light_components["blue"],
                            "alpha": light_components["alpha"]
                        }
                    },
                    "idiom": "universal"
                },
                {
                    "appearances": [
                        {
                            "appearance": "luminosity",
                            "value": "dark"
                        }
                    ],
                    "color": {
                        "color-space": "srgb",
                        "components": {
                            "red": dark_components["red"],
                            "green": dark_components["green"],
                            "blue": dark_components["blue"],
                            "alpha": dark_components["alpha"]
                        }
                    },
                    "idiom": "universal"
                }
            ],
            "info": {
                "author": "xcode",
                "version": 1
            }
        }

        with open(os.path.join(color_dir, 'Contents.json'), 'w') as f:
            json.dump(color_json, f, indent=2)

    # Generate color sets for each semantic color
    generated_count = 0
    for semantic_name, light_hex in light_colors.items():
        # Convert semantic name to valid Swift identifier (replace - with _)
        swift_name = semantic_name.replace('-', '_')

        # Get corresponding dark color
        dark_hex = dark_colors.get(semantic_name, light_hex)

        create_color_set(swift_name, light_hex, dark_hex)
        generated_count += 1

    print(f"✅ Generated SemanticColors.xcassets")

def generate_border_radius(border_radius, output_path):
    """Generate BorderRadius.swift from borderRadius dictionary"""
    # Validate borderRadius numeric values
    for key, value in border_radius.items():
        if not isinstance(value, (int, float)):
            print(f"❌ Error: borderRadius values must be numeric for {key}: {value}")
            exit(1)

    # Ensure output directory exists
    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    swift_code = f'''//
// BorderRadius.swift
// Generated from theme.json - DO NOT EDIT MANUALLY
//
import SwiftUI

public enum BorderRadius {{
    case none
    case extraSmall
    case small
    case medium
    case large
    case extraLarge

    public var value: CGFloat {{
        switch self {{
        case .none:       return {border_radius['none']}
        case .extraSmall: return {border_radius['extra-small']}
        case .small:      return {border_radius['small']}
        case .medium:     return {border_radius['medium']}
        case .large:      return {border_radius['large']}
        case .extraLarge: return {border_radius['extra-large']}
        }}
    }}
}}

public extension View {{
    func cornerRadius(_ radius: BorderRadius) -> some View {{
        clipShape(RoundedRectangle(cornerRadius: radius.value, style: .continuous))
    }}
}}
'''

    with open(output_path, 'w') as f:
        f.write(swift_code)

    print("✅ Generated BorderRadius.swift")

def generate_typography(typography, output_path):
    """Generate TypographyStyle.swift from typography dictionary"""
    # Ensure output directory exists
    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    mobile = typography['mobile']
    desktop = typography['desktop']
    font_family = typography['font-family']

    def px(val):
        """Strip 'px' suffix from size values"""
        return val.replace('px', '')

    def weight_to_swift(weight_val):
        """Map font-weight value to Swift Font.Weight"""
        weight_map = {
            400: '.regular',
            500: '.medium',
            600: '.semibold'
        }
        return weight_map.get(weight_val, '.regular')

    # Style definitions
    style_names = [
        'headline', 'subtitle', 'heading-1', 'heading-2', 'heading-3', 'heading-4',
        'body-extended', 'body-extended-semibold', 'body-base', 'body-base-semibold',
        'caption', 'caption-semibold'
    ]

    swift_style_names = {
        'headline': 'headline',
        'subtitle': 'subtitle',
        'heading-1': 'heading1',
        'heading-2': 'heading2',
        'heading-3': 'heading3',
        'heading-4': 'heading4',
        'body-extended': 'bodyExtended',
        'body-extended-semibold': 'bodyExtendedSemibold',
        'body-base': 'bodyBase',
        'body-base-semibold': 'bodyBaseSemibold',
        'caption': 'caption',
        'caption-semibold': 'captionSemibold'
    }

    # Generate enum cases
    cases = '\n'.join([f'    case {swift_style_names[name]}' for name in style_names])

    # Generate mobile config cases
    mobile_cases = []
    for name in style_names:
        swift_name = swift_style_names[name]
        style = mobile[name]
        font_size = px(style['font-size'])
        line_height = px(style['line-height'])
        weight = weight_to_swift(style['font-weight'])
        line_spacing = f'{float(line_height) - float(font_size):.1f}'

        mobile_cases.append(
            f'        case .{swift_name}: return TypographyConfig('
            f'fontSize: {font_size}, lineHeight: {line_height}, '
            f'weight: {weight}, lineSpacing: {line_spacing})'
        )

    mobile_config_code = '\n'.join(mobile_cases)

    # Generate desktop config cases
    desktop_cases = []
    for name in style_names:
        swift_name = swift_style_names[name]
        style = desktop[name]
        font_size = px(style['font-size'])
        line_height = px(style['line-height'])
        weight = weight_to_swift(style['font-weight'])
        line_spacing = f'{float(line_height) - float(font_size):.1f}'

        desktop_cases.append(
            f'        case .{swift_name}: return TypographyConfig('
            f'fontSize: {font_size}, lineHeight: {line_height}, '
            f'weight: {weight}, lineSpacing: {line_spacing})'
        )

    desktop_config_code = '\n'.join(desktop_cases)

    swift_code = f'''//
// TypographyStyle.swift
// Generated from theme.json - DO NOT EDIT MANUALLY
//
import SwiftUI

public struct TypographyConfig {{
    public let fontSize: CGFloat
    public let lineHeight: CGFloat
    public let weight: Font.Weight
    public let lineSpacing: CGFloat

    public init(fontSize: CGFloat, lineHeight: CGFloat, weight: Font.Weight, lineSpacing: CGFloat) {{
        self.fontSize = fontSize
        self.lineHeight = lineHeight
        self.weight = weight
        self.lineSpacing = lineSpacing
    }}
}}

public enum TypographyStyle {{
{cases}

    public var mobileConfig: TypographyConfig {{
        switch self {{
{mobile_config_code}
        }}
    }}

    public var desktopConfig: TypographyConfig {{
        switch self {{
{desktop_config_code}
        }}
    }}
}}

public extension View {{
    func adaptiveFont(_ style: TypographyStyle) -> some View {{
        self.modifier(AdaptiveFontModifier(style: style))
    }}
}}

private struct AdaptiveFontModifier: ViewModifier {{
    let style: TypographyStyle
    @Environment(\\.horizontalSizeClass) var sizeClass

    func body(content: Content) -> some View {{
        let config = sizeClass == .compact ? style.mobileConfig : style.desktopConfig
        content
            .font(.system(size: config.fontSize, weight: config.weight))
            .lineSpacing(config.lineSpacing)
    }}
}}
'''

    with open(output_path, 'w') as f:
        f.write(swift_code)

    print("✅ Generated TypographyStyle.swift")

def main():
    # Read theme.json
    theme_path = "./Config/theme.json"

    try:
        with open(theme_path, 'r') as f:
            theme_data = json.load(f)
    except FileNotFoundError:
        print(f"❌ Error: theme.json not found at {theme_path}")
        exit(1)
    except json.JSONDecodeError as e:
        print(f"❌ Error: Invalid JSON in theme.json: {e}")
        exit(1)

    # Task 7.5: Validate required top-level keys
    required_keys = ['colors', 'borderRadius', 'typography']
    for key in required_keys:
        if key not in theme_data:
            print(f"❌ Error: Missing required section: {key}")
            exit(1)

    # Extract data from flat theme.json structure (not nested under themes.vonage)
    light_colors = theme_data['colors']['light']
    dark_colors = theme_data['colors']['dark']
    border_radius = theme_data['borderRadius']
    typography = theme_data['typography']

    # Task 7.6: Call generation functions with new JSON paths

    # 1. Generate semantic colors (xcassets)
    generate_semantic_colors(
        light_colors,
        dark_colors,
        "./VERACommonUI/VERACommonUI/Resources/SemanticColors.xcassets"
    )

    # 2. Generate border radius enum
    generate_border_radius(
        border_radius,
        "./VERACommonUI/VERACommonUI/UI/BorderRadius.swift"
    )

    # 3. Generate typography enum
    generate_typography(
        typography,
        "./VERACommonUI/VERACommonUI/UI/TypographyStyle.swift"
    )

if __name__ == "__main__":
    main()