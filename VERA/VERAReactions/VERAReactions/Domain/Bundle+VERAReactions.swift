//
//  Bundle+VERAReactions.swift
//  VERAReactions
//

import Foundation

/// Marker class used to locate the VERAReactions bundle
final class VERAReactionsBundle {}

extension Bundle {
    /// The bundle containing VERAReactions resources
    static var veraReactions: Bundle {
        Bundle(for: VERAReactionsBundle.self)
    }
}
