// swift-format-ignore-file
//
// BorderRadius.swift
// Generated from theme.json - DO NOT EDIT MANUALLY
//
import SwiftUI

public enum BorderRadius {
    case none
    case extraSmall
    case small
    case medium
    case large
    case extraLarge

    public var value: CGFloat {
        switch self {
        case .none:       return 0
        case .extraSmall: return 2
        case .small:      return 4
        case .medium:     return 8
        case .large:      return 12
        case .extraLarge: return 24
        }
    }
}

public extension View {
    func cornerRadius(_ radius: BorderRadius) -> some View {
        clipShape(RoundedRectangle(cornerRadius: radius.value, style: .continuous))
    }
}
