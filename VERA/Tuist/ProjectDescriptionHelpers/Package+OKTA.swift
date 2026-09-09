import ProjectDescription

extension Package {
    public static let oktaMobileSwift = Package.package(
        url: "https://github.com/okta/okta-mobile-swift.git",
        .upToNextMajor(from: "2.1.5")
    )
}

extension TargetDependency {
    public static let oktaAuthFoundation = TargetDependency.package(product: "AuthFoundation")
    public static let oktaBrowserSignin = TargetDependency.package(product: "BrowserSignin")
}
