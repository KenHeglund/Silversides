/*===========================================================================
 URL+Demo.swift
 SilversidesDemo
 Copyright (c) 2019 OrderedBytes. All rights reserved.
 ===========================================================================*/

import Foundation

extension URL {
    
    /// Returns `true` if the URL represents the root URL of a volume.
    var isVolumeRoot: Bool {
        let lastPathComponent = self.lastPathComponent
        let relativePath = self.relativePath
        if lastPathComponent == relativePath {
            return true
        }
        
        let shortenedPath = self.deletingLastPathComponent().path
        if shortenedPath == "/Volumes" {
            return true
        }
        
        return false
    }
    
    /// Returns `true` if the receiver is a container (a directory that is not a bundle).
    var isContainer: Bool {
        
        guard let resourceValues = try? (self as NSURL).resourceValues( forKeys: [.isDirectoryKey, .isPackageKey] ) else {
            return false
        }
        
        guard
            let isDirectory = resourceValues[URLResourceKey.isDirectoryKey] as? Bool,
            let isPackage = resourceValues[URLResourceKey.isPackageKey] as? Bool
        else {
            return false
        }
        
        return isDirectory && isPackage == false
    }
    
    /// Returns descendant URLs of the receiver, or `nil` if the receiver is not a container.
    var descendantURLs: [URL]? {
        
        guard self.isContainer else {
            return nil
        }
        
        let directoryOptions: FileManager.DirectoryEnumerationOptions = [
            .skipsSubdirectoryDescendants,
            .skipsPackageDescendants,
            .skipsHiddenFiles,
        ]
        
        guard let enumerator = FileManager.default.enumerator(at: self, includingPropertiesForKeys: nil, options: directoryOptions, errorHandler: nil) else {
            return nil
        }
        
        guard let urlArray = enumerator.allObjects as? [URL] else {
            return nil
        }
        
        let sortedArray = urlArray.sorted(by: {
            return $0.path.caseInsensitiveCompare($1.path) == .orderedAscending
        })
        
        return sortedArray
    }
}
