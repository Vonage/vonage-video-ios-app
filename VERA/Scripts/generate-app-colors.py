#!/usr/bin/env python3

import json
import os

def generate_semantic_colors():
    semantics_path = "./Config/semantics.json"
    output_dir = "./VERACommonUI/VERACommonUI/Resources/SemanticColors.xcassets"
    
    # Read semantics file
    try:
        with open(semantics_path, 'r') as f:
            semantics_data = json.load(f)
    except FileNotFoundError as e:
        print(f"❌ Error: Missing file - {e}")
        exit(1)
    except json.JSONDecodeError as e:
        print(f"❌ Error parsing JSON: {e}")
        exit(1)

    light_colors = semantics_data['themes']['vonage']['colors']['light']
    dark_colors = semantics_data['themes']['vonage']['colors']['dark']

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

    def hex_to_rgba_components(hex_color):
        """Convert hex color to RGBA components for Xcode"""
        hex_color = hex_color.lstrip('#')
        
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
            r, g, b, a = 1.0, 1.0, 1.0, 1.0
            
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

        light_components = hex_to_rgba_components(light_hex)
        dark_components = hex_to_rgba_components(dark_hex)

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

    print(f"✅ Generated {generated_count} semantic colors in SemanticColors.xcassets")

if __name__ == "__main__":
    generate_semantic_colors()