/*===========================================================================
 String+OBWExtension.swift
 Silversides
 Copyright (c) 2021 Ken Heglund. All rights reserved.
 ===========================================================================*/

import Foundation

extension String {
	/// Returns an array of ranges within the receiver that match the characters
	/// (in order) of a given string.  If any character in the given string does
	/// not match a character in the receiver, then an empty array is returned.
	///
	/// - Parameters:
	///   - string: A string containing the characters to search for within the
	///   receiver.
	///   - options: Options used to compare strings.  See
	///   `NSString.CompareOptions`.
	///
	/// - Returns: Ranges within the receiver that match the characters of
	/// `string`.
	func rangesOfCharacters(in string: String, options: NSString.CompareOptions) -> [Range<Index>] {
		// A private error that is used to terminate a `map` call early.
		enum RangesOfCharactersError: Error {
			case characterNotFound
		}
		
		var searchRange = self.startIndex ..< self.endIndex
		
		guard let individualRanges = try? string.map({ (character) throws -> Range<Index> in
			guard let caseInsensitiveRange = self.range(of: String(character), options: options, range: searchRange, locale: nil) else {
				throw RangesOfCharactersError.characterNotFound
			}
			
			searchRange = caseInsensitiveRange.upperBound ..< self.endIndex
			
			return caseInsensitiveRange
		})
		else {
			return []
		}
		
		let contiguousRanges: [Range<Index>] = individualRanges.reduce(into: []) { result, range in
			if let previous = result.last, previous.upperBound == range.lowerBound {
				let newPrevious = previous.lowerBound ..< range.upperBound
				result[result.index(before: result.endIndex)] = newPrevious
			}
			else {
				result.append(range)
			}
		}
		
		return contiguousRanges
	}
}
