// swiftlint:disable:this file_name
// swiftlint:disable all
// swift-format-ignore-file
// swiftformat:disable all
//
// SPM-compatible asset accessors for VERACommonUI.
// Mirrors the Tuist-generated TuistAssets+VERACommonUI.swift API
// so that source code works unchanged under both build systems.
//
// This file is compiled ONLY when building with Swift Package Manager.
// During Tuist builds, the equivalent code is auto-generated in Derived/Sources/.

#if SWIFT_PACKAGE

#if os(macOS)
  import AppKit
#elseif os(iOS)
  import UIKit
#elseif os(tvOS) || os(watchOS)
  import UIKit
#endif
#if canImport(SwiftUI)
  import SwiftUI
#endif

// MARK: - Asset Catalogs

public enum VERACommonUIAsset: Sendable {
  public enum Colors {
  public static let vGray0 = VERACommonUIColors(name: "vGray0")
    public static let vGray1 = VERACommonUIColors(name: "vGray1")
    public static let vGray2 = VERACommonUIColors(name: "vGray2")
    public static let vGray3 = VERACommonUIColors(name: "vGray3")
    public static let vGray4 = VERACommonUIColors(name: "vGray4")
    public static let videoBackground = VERACommonUIColors(name: "videoBackground")
  }
  public enum Images {
  public static let callKitIcon = VERACommonUIImages(name: "CallKitIcon")
    public static let appsSolid = VERACommonUIImages(name: "apps-solid")
    public static let arrowBoldLeftLine = VERACommonUIImages(name: "arrow-bold-left-line")
    public static let audioMaxSolidOff = VERACommonUIImages(name: "audio-max-solid-off")
    public static let audioMaxSolid = VERACommonUIImages(name: "audio-max-solid")
    public static let audioMidLine = VERACommonUIImages(name: "audio-mid-line")
    public static let blurLine = VERACommonUIImages(name: "blur-line")
    public static let blurSolid = VERACommonUIImages(name: "blur-solid")
    public static let cameraSwitchLine = VERACommonUIImages(name: "camera-switch-line")
    public static let chartSolid = VERACommonUIImages(name: "chart-solid")
    public static let chat2Solid = VERACommonUIImages(name: "chat-2-solid")
    public static let checkCircleLine = VERACommonUIImages(name: "check-circle-line")
    public static let closedCaptioningOffSolid = VERACommonUIImages(name: "closed-captioning-off-solid")
    public static let closedCaptioningSolid = VERACommonUIImages(name: "closed-captioning-solid")
    public static let downloadLine = VERACommonUIImages(name: "download-line")
    public static let emojiSolid = VERACommonUIImages(name: "emoji-solid")
    public static let endCallSolid = VERACommonUIImages(name: "end-call-solid")
    public static let enterLine = VERACommonUIImages(name: "enter-line")
    public static let errorLine = VERACommonUIImages(name: "error-line")
    public static let feedbackLine = VERACommonUIImages(name: "feedback-line")
    public static let gallerySolid = VERACommonUIImages(name: "gallery-solid")
    public static let gearLine = VERACommonUIImages(name: "gear-line")
    public static let gearSolid = VERACommonUIImages(name: "gear-solid")
    public static let group2Solid = VERACommonUIImages(name: "group-2-solid")
    public static let infoLine = VERACommonUIImages(name: "info-line")
    public static let layout2Solid = VERACommonUIImages(name: "layout-2-solid")
    public static let menuSolid = VERACommonUIImages(name: "menu-solid")
    public static let messageSentSolid = VERACommonUIImages(name: "message-sent-solid")
    public static let micMuteLine = VERACommonUIImages(name: "mic-mute-line")
    public static let micMuteSolid = VERACommonUIImages(name: "mic-mute-solid")
    public static let microphone2Solid = VERACommonUIImages(name: "microphone-2-solid")
    public static let microphoneLine = VERACommonUIImages(name: "microphone-line")
    public static let moreVerticalSolid = VERACommonUIImages(name: "more-vertical-solid")
    public static let noiseSuppressionDisabled = VERACommonUIImages(name: "noise-suppression-disabled")
    public static let noiseSuppressionEnabled = VERACommonUIImages(name: "noise-suppression-enabled")
    public static let pin2OffSolid = VERACommonUIImages(name: "pin-2-off-solid")
    public static let pin2Solid = VERACommonUIImages(name: "pin-2-solid")
    public static let plusLine = VERACommonUIImages(name: "plus-line")
    public static let radioChecked2Line = VERACommonUIImages(name: "radio-checked-2-line")
    public static let radioChecked2Solid = VERACommonUIImages(name: "radio-checked-2-solid")
    public static let removeLine = VERACommonUIImages(name: "remove-line")
    public static let screenShareSolid = VERACommonUIImages(name: "screen-share-solid")
    public static let shareLine = VERACommonUIImages(name: "share-line")
    public static let videoActiveLine = VERACommonUIImages(name: "video-active-line")
    public static let videoLine = VERACommonUIImages(name: "video-line")
    public static let videoOffLine = VERACommonUIImages(name: "video-off-line")
    public static let videoOffSolid = VERACommonUIImages(name: "video-off-solid")
    public static let videoSolid = VERACommonUIImages(name: "video-solid")
    public static let warningLine = VERACommonUIImages(name: "warning-line")
  }
  public enum SemanticColors {
  public static let accent = VERACommonUIColors(name: "accent")
    public static let background = VERACommonUIColors(name: "background")
    public static let border = VERACommonUIColors(name: "border")
    public static let disabled = VERACommonUIColors(name: "disabled")
    public static let error = VERACommonUIColors(name: "error")
    public static let errorHover = VERACommonUIColors(name: "error_hover")
    public static let onAccent = VERACommonUIColors(name: "on_accent")
    public static let onBackground = VERACommonUIColors(name: "on_background")
    public static let onError = VERACommonUIColors(name: "on_error")
    public static let onPrimary = VERACommonUIColors(name: "on_primary")
    public static let onSecondary = VERACommonUIColors(name: "on_secondary")
    public static let onSuccess = VERACommonUIColors(name: "on_success")
    public static let onSurface = VERACommonUIColors(name: "on_surface")
    public static let onTertiary = VERACommonUIColors(name: "on_tertiary")
    public static let onWarning = VERACommonUIColors(name: "on_warning")
    public static let primary = VERACommonUIColors(name: "primary")
    public static let primaryHover = VERACommonUIColors(name: "primary_hover")
    public static let secondary = VERACommonUIColors(name: "secondary")
    public static let success = VERACommonUIColors(name: "success")
    public static let successHover = VERACommonUIColors(name: "success_hover")
    public static let surface = VERACommonUIColors(name: "surface")
    public static let tertiary = VERACommonUIColors(name: "tertiary")
    public static let textDisabled = VERACommonUIColors(name: "text_disabled")
    public static let textPrimary = VERACommonUIColors(name: "text_primary")
    public static let textSecondary = VERACommonUIColors(name: "text_secondary")
    public static let textTertiary = VERACommonUIColors(name: "text_tertiary")
    public static let warning = VERACommonUIColors(name: "warning")
    public static let warningHover = VERACommonUIColors(name: "warning_hover")
  }
}

// MARK: - Implementation Details

public final class VERACommonUIColors: Sendable {
  public let name: String

  #if os(macOS)
  public typealias Color = NSColor
  #elseif os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
  public typealias Color = UIColor
  #endif

  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, visionOS 1.0, *)
  public var color: Color {
    guard let color = Color(asset: self) else {
      fatalError("Unable to load color asset named \(name).")
    }
    return color
  }

  #if canImport(SwiftUI)
  @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
  public var swiftUIColor: SwiftUI.Color {
      return SwiftUI.Color(asset: self)
  }
  #endif

  fileprivate init(name: String) {
    self.name = name
  }
}

public extension VERACommonUIColors.Color {
  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, visionOS 1.0, *)
  convenience init?(asset: VERACommonUIColors) {
    let bundle = Bundle.module
    #if os(iOS) || os(tvOS) || os(visionOS)
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    self.init(named: NSColor.Name(asset.name), bundle: bundle)
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.Color {
  init(asset: VERACommonUIColors) {
    let bundle = Bundle.module
    self.init(asset.name, bundle: bundle)
  }
}
#endif

public struct VERACommonUIImages: Sendable {
  public let name: String

  #if os(macOS)
  public typealias Image = NSImage
  #elseif os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
  public typealias Image = UIImage
  #endif

  public var image: Image {
    let bundle = Bundle.module
    #if os(iOS) || os(tvOS) || os(visionOS)
    let image = Image(named: name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    let image = bundle.image(forResource: NSImage.Name(name))
    #elseif os(watchOS)
    let image = Image(named: name)
    #endif
    guard let result = image else {
      fatalError("Unable to load image asset named \(name).")
    }
    return result
  }

  #if canImport(SwiftUI)
  @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
  public var swiftUIImage: SwiftUI.Image {
    SwiftUI.Image(asset: self)
  }
  #endif
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.Image {
  init(asset: VERACommonUIImages) {
    let bundle = Bundle.module
    self.init(asset.name, bundle: bundle)
  }

  init(asset: VERACommonUIImages, label: Text) {
    let bundle = Bundle.module
    self.init(asset.name, bundle: bundle, label: label)
  }

  init(decorative asset: VERACommonUIImages) {
    let bundle = Bundle.module
    self.init(decorative: asset.name, bundle: bundle)
  }
}
#endif

#endif // SWIFT_PACKAGE

// swiftlint:enable all
// swiftformat:enable all
