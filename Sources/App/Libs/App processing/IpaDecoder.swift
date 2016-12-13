//
//  IpaDecoder.swift
//  Boost
//
//  Created by Ondrej Rafaj on 02/12/2016.
//
//

import Foundation
import Vapor


final class IpaDecoder: Decoder, DecoderProtocol {
    
    
    // MARK: Protocol data
    
    private(set) var iconData: Data?
    private(set) var appName: String?
    private(set) var appIdentifier: String?
    private(set) var platform: Platform? = .iOS
    private(set) var versionShort: String?
    private(set) var versionLong: String?
    
    private(set) var data: [String: Node] = [:]
    
    
    // MARK: URL's
    
    var _extractedIpaFolder: URL?
    
    var extractedIpaFolder: URL {
        get {
            if _extractedIpaFolder == nil {
                var url: URL = self.archiveFolderUrl
                url.appendPathComponent("Payload")
                
                // TODO: Secure this a bit more!!!
                if let appName: String = try! FileManager.default.contentsOfDirectory(atPath: url.path).first {
                    url.appendPathComponent(appName)
                }
                self._extractedIpaFolder = url
            }
            return self._extractedIpaFolder!
        }
    }
    
    // MARK: Prepare
    
    func prepare() throws {
        try super.saveToArchive()
        
        // Extract archive
        let result: TerminalResult = Terminal.execute("/usr/bin/env", "unzip", self.archiveFileUrl.path, "-d", self.archiveFolderUrl.path)
        if result.exitCode != 0 {
            throw BoostError(.unarchivingFailed)
        }
        
        let _ = Terminal.execute("open", self.archiveFolderUrl.path)
    }
    
    // MARK: Parse
    
    private func parseProvisioning() throws {
        var embeddedFile: URL = self.extractedIpaFolder
        embeddedFile.appendPathComponent("embedded.mobileprovision")
        let provisioning: String = try String.init(contentsOfFile: embeddedFile.path, encoding: String.Encoding.utf8)
        if provisioning.contains("ProvisionsAllDevices") {
            self.data["provisioning"] = "enterprise"
        }
        else if provisioning.contains("ProvisionedDevices") {
            self.data["provisioning"] = "adhoc"
        }
        else {
            self.data["provisioning"] = "appstore"
        }
    }
    
    private func parseInfoPlistFile() throws {
        var embeddedFile: URL = self.extractedIpaFolder
        embeddedFile.appendPathComponent("Info.plist")
        
        guard let plist: NSDictionary = NSDictionary(contentsOfFile: embeddedFile.path) else {
            throw BoostError(.invalidAppContent)
        }
        
        // Bundle ID
        guard let bundleId = plist["CFBundleIdentifier"] as? String else {
            throw BoostError(.invalidAppContent)
        }
        self.appIdentifier = bundleId
        
        // Name
        self.appName = plist["CFBundleDisplayName"] as? String
        
        // Versions
        self.versionLong = plist["CFBundleShortVersionString"] as? String
        self.versionShort = plist["CFBundleVersion"] as? String
        
        // Other plist data
        if let minOS: String = plist["MinimumOSVersion"] as? String {
            self.data["minOS"] = minOS.makeNode()
        }
        if let orientationPhone: [String] = plist["UISupportedInterfaceOrientations"] as? [String] {
            self.data["orientationPhone"] = try orientationPhone.makeNode()
        }
        if let orientationTablet: [String] = plist["UISupportedInterfaceOrientations~ipad"] as? [String] {
            self.data["orientationTablet"] = try orientationTablet.makeNode()
        }
        if let deviceCapabilities: [String] = plist["UIRequiredDeviceCapabilities"] as? [String] {
            self.data["deviceCapabilities"] = try deviceCapabilities.makeNode()
        }
        if let deviceFamily: [String] = plist["UIDeviceFamily"] as? [String] {
            self.data["deviceFamily"] = try deviceFamily.makeNode()
        }
    }
    
    private func parseIcon() throws {
        let files: [String] = try FileManager.default.contentsOfDirectory(atPath: self.extractedIpaFolder.path)
        
    }
    
    func parse() throws {
        //try self.parseProvisioning()
        try self.parseInfoPlistFile()
        try self.parseIcon()
    }
    
    // MARK: Data conversion
    
    func toJSON() throws -> JSON {
        var data: Node = try Decoder.basicData(decoder: self)
        data["data"] = try self.data.makeNode()
        return JSON(data)
    }
    
}