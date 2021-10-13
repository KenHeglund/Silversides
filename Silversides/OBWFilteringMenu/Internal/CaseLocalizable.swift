/*===========================================================================
CaseLocalizable.swift
Silversides
Copyright (c) 2021 Ken Heglund. All rights reserved.
===========================================================================*/

import Foundation

/// A type that provides localized strings for its values.
///
/// Types that conform to the `CaseLocalizable` protocol are typically
/// enumerations with cases that represent entries in localized `.strings`
/// files.
///
/// For example, the `CompassDirection` enumeration declared in this example
/// conforms to `CaseLocalizable`.  The cases represent entries in a `.strings`
/// file localized in German.
///
///     class Route {
///         public enum CompassDirection: CaseLocalizable, CaseIterable {
///             case north, south, east, west
///         }
///
///         let caseList = CompassDirection.allCases
///                                        .map(\.localized)
///                                        .joined(separator: ", ")
///         // caseList == "Nord, Süd, Ost, West"
///     }
///
/// Types conforming to `CaseLocalizable` should have `public` visibility to use
/// default keys and bundles.
///
/// Strings Files
/// =============
///
/// The default bundle that is searched for a `.strings` file is based on the
/// enclosing type of the `CaseLocalizable` type.  If the `CaseLocalizable` type
/// is a subtype of a class, then the bundle that loaded that class will be
/// searched.  If the `CaseLocalizable` type is not enclosed in a class type,
/// then the main bundle is searched.
///
/// The default `.strings` file keys used to locate localized strings are based
/// on the names of cases and their fully-qualified types.
///
/// For `CaseLocalizable` types that are subtypes of class types, the default
/// key is the qualified name of the `CaseLocalizable`’s enclosing type rooted
/// at the class type concatenated with the case name separated by a dot.
///
///     let northKey = CompassDirection.north.localizationKey
///     // northKey == "Route.north"
///
/// For `CaseLocalizable` types that are not subtypes of class types, the
/// default key is the fully-qualified name of the `CaseLocalizable` type
/// concatenated with the case name separated by a dot.
///
/// The example below demonstrates the localization that would be used for
/// `CompassDirection` cases if the `Route` type was a struct in the `Travel`
/// module.
///
///     let northKey = CompassDirection.north.localizationKey
///     // northKey = "Travel.Route.CompassDirection.north"
///
protocol CaseLocalizable {
	/// A localized string representation of this value.
	var localized: String { get }
	
	/// The key that is used to obtain the localized string representation of
	/// this value from the `.strings` file.
	///
	/// The default key is the concatenation of `localizationKeyPrefix` and the
	/// receiver’s name separated by a dot.
	var localizationKey: String { get }
	
	/// The prefix string that is used to build the `localizationKey` property.
	///
	/// By default, if the type adopting `CaseLocalizable` is enclosed anywhere
	/// within in a class type, then `localizationKeyPrefix` is the
	/// fully-qualified name of the `CaseLocalizable`’s immediate enclosing type
	/// (which may or may not be the class).  Otherwise, `localizationKeyPrefix`
	/// is the fully-qualified name of the `CaseLocalizable` type.
	var localizationKeyPrefix: String? { get }
	
	/// The bundle the localized `.strings` files are located.
	///
	/// By default, if the type adopting `CaseLocalizable` is enclosed in a
	/// class type, then `localizationBundle` is the bundle that class type is
	/// loaded from.  Otherwise, `localizationBundle` is the main bundle.
	var localizationBundle: Bundle { get }
}

extension CaseLocalizable {
	var localized: String {
		NSLocalizedString(self.localizationKey, tableName: nil, bundle: self.localizationBundle, value: "", comment: "")
	}
	
	var localizationKey: String {
		let suffix = Self.basicTypeName(of: self)
		if let prefix = self.localizationKeyPrefix {
			return prefix + Self.localizationKeySeparator + suffix
		}
		else {
			return suffix
		}
	}
	
	var localizationKeyPrefix: String? {
		let fullyQualifiedType = Self.fullyQualifiedTypeName(of: Self.self)
		guard !fullyQualifiedType.isEmpty else {
			return nil
		}
		
		// If the type adopting `CaseLocalizable` has no enclosing class type, then the entire type is the prefix.
		guard let enclosingClass = Self.enclosingClass else {
			return fullyQualifiedType
		}
		
		let enclosingClassName = Self.basicTypeName(of: enclosingClass)
		let caseTypeComponents = fullyQualifiedType.components(separatedBy: Self.typeNameSeparator)
		let abbreviatedTypeComponents = caseTypeComponents.drop(while: { $0 != enclosingClassName })
		
		// The abbreviated type is expected to have at least two components: the enclosing class type and the type that conforms to `CaseLocalizable`.
		guard abbreviatedTypeComponents.count >= 2 else {
			assertionFailure("`CaseLocalizable` appears to be adopted by a class type (“\(fullyQualifiedType)”).  This is unexpected.")
			return nil
		}
		
		return abbreviatedTypeComponents.dropLast().joined(separator: Self.localizationKeySeparator)
	}
	
	var localizationBundle: Bundle {
		if let enclosingClass = Self.enclosingClass {
			return Bundle(for: enclosingClass)
		}
		else {
			return .main
		}
	}
	
	/// The nearest parent type of the receiver that is a class.
	private static var enclosingClass: AnyClass? {
		let fullyQualifiedCaseType = self.fullyQualifiedTypeName(of: self)
		guard !fullyQualifiedCaseType.isEmpty else {
			return nil
		}
		
		let caseTypeHierarchy = fullyQualifiedCaseType.components(separatedBy: Self.typeNameSeparator)
		
		let enclosingClass: AnyClass? = caseTypeHierarchy.indices.lazy.reversed().compactMap({
			NSClassFromString(caseTypeHierarchy.prefix(through: $0).joined(separator: self.localizationKeySeparator))
		}).first
		
		return enclosingClass
	}
	
	/// The string that separates the components of a fully-qualified type name.
	private static var typeNameSeparator: String { "." }
	
	/// The string that separates the components of a localization key.
	private static var localizationKeySeparator: String { "." }
	
	/// Returns the basic type name of the receiver.
	/// - Parameter instance: The instance, class, or case to return the basic
	/// type name of.
	/// - Returns: The basic type name of `instance`.
	private static func basicTypeName(of instance: Any) -> String {
		"\(instance)"
	}
	
	/// Returns the fully qualified type name of the receiver.
	/// - Parameter instance: The instance, class, or case to return the fully
	/// qualified type name of.
	/// - Returns: The fully qualified type name of `instance`.
	private static func fullyQualifiedTypeName(of instance: Any) -> String {
		// Currently (Xcode 12.4, Swift 5), `String(reflecting:)` returns a string containing the fully-qualified type of the argument.  If that changes in a future Swift, then this will probably break.
		let typeName = String(reflecting: instance)
		guard !typeName.isEmpty else {
			assertionFailure("No `CaseLocalizable` type information available.  Check the behavior of `String(reflecting:)`.")
			return ""
		}
		
		return typeName
	}
}
