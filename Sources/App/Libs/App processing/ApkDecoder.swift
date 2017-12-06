//
//  ApkDecoder.swift
//  Boost
//
//  Created by Ondrej Rafaj on 02/12/2016.
//  Copyright © 2016 manGoweb UK Ltd. All rights reserved.
//

import Foundation
import Vapor


final class ApkDecoder: Decoder, DecoderProtocol {
    
    
    // MARK: Protocol data
    
    private(set) var iconData: Data?
    private(set) var appName: String?
    private(set) var appIdentifier: String?
    private(set) var platform: Platform?
    private(set) var versionShort: String?
    private(set) var versionLong: String?
    
    private(set) var appPermissions: [String] = []
    private(set) var appFeatures: [String] = []
    
    // MARK: URL's
    
    var manifestFileUrl: URL {
        get {
            var manifestFileUrl: URL = self.extractedApkFolder
            manifestFileUrl.appendPathComponent("AndroidManifest.xml")
            return manifestFileUrl
        }
    }
    
    var extractedApkFolder: URL {
        get {
            var url: URL = self.archiveFolderUrl
            url.appendPathComponent("Decoded")
            return url
        }
    }
    
    var binUrl: URL {
        get {
            var url: URL = URL(fileURLWithPath: drop.resourcesDir)
            url.appendPathComponent("bin")
            return url
        }
    }
    
    var apktoolUrl: URL {
        get {
            var url: URL = self.binUrl
            url.appendPathComponent("apktool_2.2.1.jar")
            return url
        }
    }
    
    var xml2jsonUrl: URL {
        get {
            var url: URL = self.binUrl
            url.appendPathComponent("xml2json.py")
            return url
        }
    }
    
    // MARK: Parsing
    
    func prepare() throws {
        self.platform = .android
        
        try super.saveToArchive()
        
        // Extract archive
        let result: TerminalResult = Terminal.execute("java", "-jar", self.apktoolUrl.path, "d", self.archiveFileUrl.path, "-o", self.extractedApkFolder.path, "-f")
        
        if result.exitCode != 0 {
            throw BoostError(.unarchivingFailed)
        }
    }
    
    private func getApplicationName() throws {
        var pathUrl: URL = self.extractedApkFolder
        pathUrl.appendPathComponent("res")
        pathUrl.appendPathComponent("values")
        
        var xmlUrl = pathUrl
        xmlUrl.appendPathComponent("strings.xml")
        if FileManager.default.fileExists(atPath:xmlUrl.path) {
            var jsonUrl = pathUrl
            jsonUrl.appendPathComponent("strings.json")
            
            // Convert XML to JSON
            let _ = Terminal.execute(self.xml2jsonUrl.path, "-t", "xml2json", "-o", jsonUrl.path, xmlUrl.path)
            
            
            
//            let data = try! Data.init(contentsOf: xmlUrl)
//            guard let strings = XML(data: data) else {
//                throw BoostError(.invalidAppContent)
//            }
//            for string: XML in strings.children {
//                if string["@name"].string == "app_name" {
//                    self.appName = string.string
//                }
//            }
        }
        //*/
        if self.appName == nil {
            let file: Multipart.File = self.multiPartFile.file!
            self.appName = file.name?.replacingOccurrences(of: ".apk", with: "")
        }
    }
    
    private func getApplicationIcon() throws {
        var pathUrl: URL = self.extractedApkFolder
        pathUrl.appendPathComponent("res")
        let folders: [String] = try FileManager.default.contentsOfDirectory(atPath: pathUrl.path)
        let ici: [String]? = self.appIconId?.components(separatedBy: "/")
        guard let iconInfo: [String] = ici else {
            return
        }
        for folder: String in folders {
            if folder.contains(iconInfo[0]) {
                var iconBaseUrl: URL = pathUrl
                iconBaseUrl.appendPathComponent(folder)
                
                // Search for rounded icon first
                var iconUrl: URL = iconBaseUrl
                iconUrl.appendPathComponent(iconInfo[1] + "_round")
                iconUrl.appendPathExtension("png")
                
                if FileManager.default.fileExists(atPath: iconUrl.path) {
                    let data: Data = try Data.init(contentsOf: iconUrl)
                    if data.count > (self.iconData?.count ?? 0) {
                        self.iconData = data
                    }
                }
                else {
                    // If not found, look for normal one
                    iconUrl = iconBaseUrl
                    iconUrl.appendPathComponent(iconInfo[1])
                    iconUrl.appendPathExtension("png")
                    
                    if FileManager.default.fileExists(atPath: iconUrl.path) {
                        let data: Data = try Data.init(contentsOf: iconUrl)
                        if data.count > (self.iconData?.count ?? 0) {
                            self.iconData = data
                        }
                    }
                }
            }
        }
    }
    
    private var appIconId: String?
    private var appNameId: String?
    
    /*
    private func parseApplicationNode(_ node: XMLNode) {
        if let name = node.attributes["android:label"] {
            self.appNameId = name.replacingOccurrences(of: "@string/", with: "")
        }
        if let icon = node.attributes["android:icon"] {
            self.appIconId = icon.replacingOccurrences(of: "@", with: "")
        }
    }
    
    private func parsePermission(_ node: XMLNode) {
        if let value: String = node.attributes["android:name"] {
            self.appPermissions.append(value)
        }
    }
    
    private func parseFeature(_ node: XMLNode) {
        if let value: String = node.attributes["android:name"] {
            self.appFeatures.append(value)
        }
    }
    */
    func parse() throws {
        guard FileManager.default.fileExists(atPath: self.manifestFileUrl.path) else {
            throw BoostError(.missingManifestFile)
        }
        /*
        let manifestXml = XML(contentsOf: self.manifestFileUrl)
        guard let manifestContent = manifestXml?["manifest"] else {
            throw BoostError(.corruptedManifestFile)
        }
        
        for node: XMLNode in manifestContent.children {
            if node.name == "application" {
                self.parseApplicationNode(node)
            }
            else if node.name == "uses-permission" {
                self.parsePermission(node)
            }
            else if node.name == "uses-feature" {
                self.parseFeature(node)
            }
        }
        
        for nodeKey: String in manifestContent.attributes.keys {
            let nodeValue: String = manifestContent.attributes[nodeKey]!
            if nodeKey == "platformBuildVersionCode" {
                self.versionShort = nodeValue
            }
            if nodeKey == "platformBuildVersionName" {
                self.versionLong = nodeValue
            }
            if nodeKey == "package" {
                self.appIdentifier = nodeValue
            }
        }
        
        */
        try self.getApplicationName()
        //try self.getApplicationIcon()
    }
    
    // MARK: Data conversion
    
    func toJSON() throws -> JSON {
        var data: Node = try Decoder.basicData(decoder: self)
        data["permissions"] = try self.appPermissions.makeNode()
        data["features"] = try self.appFeatures.makeNode()
        return JSON(data)
    }
    
}