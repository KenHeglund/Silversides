/*===========================================================================
OBWUserInterfaceLayoutDirection.swift
OBWControls
Copyright (c) 2021 OrderedBytes. All rights reserved.
===========================================================================*/

import AppKit

infix operator +>>: AdditionPrecedence
/// Layout direction-aware addition.  This combines two numbers such that a
/// positive addend generates a result that is on the trailing side of the
/// augend.
///
/// - Parameters:
///   - lhs: Augend
///   - rhs: Addend
///
/// - Returns: Returns the result of adding `rhs` to `lhs` toward the “trailing”
/// direction.  For positive `rhs` values, the result is greater than `lhs` in a
/// left-to-right layout, and less than `lhs` in a right-to-left layout.  For
/// negative `rhs` values, the relationships are reversed.
func +>> <T>(lhs: T, rhs: T) -> T where T: SignedNumeric {
	switch NSApp.userInterfaceLayoutDirection {
		case .rightToLeft:
			return lhs - rhs
			
		case .leftToRight:
			fallthrough
		@unknown default:
			return lhs + rhs
	}
}

infix operator ->>: AdditionPrecedence
/// Layout direction-aware subtraction.  This combines two numbers such that a
/// positive subtrahend generates a result that is on the leading side of the
/// minuend.
///
/// - Parameters:
///   - lhs: Minuend
///   - rhs: Subtrahend
///
/// - Returns: Returns the result of subtracting `rhs` from `lhs` toward the
/// “leading” direction.  For positive `rhs` values, the result is less than
/// `lhs` in a left-to-right layout, and greater than `lhs` in a right-to-left
/// layout.  For negative `rhs` values, the relationships are reversed.
func ->> <T>(lhs: T, rhs: T) -> T where T: SignedNumeric {
	lhs +>> -rhs
}

infix operator +=>>: AdditionPrecedence
/// Layout direction-aware addition.  This combines two numbers such that a
/// positive addend generates a result that is on the trailing side of the
/// augend.  The result is stored in the augend.
///
/// - Parameters:
///   - lhs: Augend
///   - rhs: Addend
///
/// - Returns: Returns the result of adding `rhs` to `lhs` toward the “trailing”
/// direction.  For positive `rhs` values, the result is greater than `lhs` in a
/// left-to-right layout, and less than `lhs` in a right-to-left layout.  For
/// negative `rhs` values, the relationships are reversed.
func +=>> <T>(lhs: inout T, rhs: T) where T: SignedNumeric {
	switch NSApp.userInterfaceLayoutDirection {
		case .rightToLeft:
			lhs -= rhs
			
		case .leftToRight:
			fallthrough
		@unknown default:
			lhs = lhs + rhs
	}
}

infix operator -=>>: AdditionPrecedence
/// Layout direction-aware subtraction.  This combines two numbers such that a
/// positive subtrahend generates a result that is on the leading side of the
/// minuend.  The result is stored in the minuend.
///
/// - Parameters:
///   - lhs: Minuend
///   - rhs: Subtrahend
///
/// - Returns: Returns the result of subtracting `rhs` from `lhs` toward the
/// “leading” direction.  For positive `rhs` values, the result is less than
/// `lhs` in a left-to-right layout, and greater than `lhs` in a right-to-left
/// layout.  For negative `rhs` values, the relationships are reversed.
func -=>> <T>(lhs: inout T, rhs: T) where T: SignedNumeric {
	lhs +=>> -rhs
}
