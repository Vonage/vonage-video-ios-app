import ProjectDescription

public func orientationPlistValues() -> [String: ProjectDescription.Plist.Value] {
    [
        "UISupportedInterfaceOrientations~iphone": .array([
            "UIInterfaceOrientationPortrait",
            "UIInterfaceOrientationLandscapeLeft",
            "UIInterfaceOrientationLandscapeRight",
        ]),
        "UISupportedInterfaceOrientations~ipad": .array([
            "UIInterfaceOrientationPortrait",
            "UIInterfaceOrientationPortraitUpsideDown",
            "UIInterfaceOrientationLandscapeLeft",
            "UIInterfaceOrientationLandscapeRight",
        ]),
    ]
}

public func launchScreenPlistValues() -> [String: ProjectDescription.Plist.Value] {
    ["UILaunchScreen": ["UIColorName": "", "UIImageName": ""]]
}

public func combinedPlistValues() -> [String: ProjectDescription.Plist.Value] {
    orientationPlistValues().merging(launchScreenPlistValues(), uniquingKeysWith: { _, new in new })
}
