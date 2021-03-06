//
//  UploadKey.swift
//  App
//
//  Created by Ondrej Rafaj on 11/12/2017.
//

import Foundation
import Vapor
import Fluent
import FluentPostgreSQL
import DbCore
import ApiCore


public typealias UploadKeys = [UploadKey]


final public class UploadKey: DbCoreModel {
    
    public static var idKey: WritableKeyPath<UploadKey, DbCoreIdentifier?> = \UploadKey.id
    
    public var id: DbCoreIdentifier?
    public var teamId: DbCoreIdentifier
    public var team: Team? = nil
    public var name: String
    public var expires: Date?
    public var token: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case teamId = "team_id"
        case team
        case name
        case expires
        case token
    }
    
    init(id: DbCoreIdentifier?, teamId: DbCoreIdentifier, name: String, expires: Date?, token: String) {
        self.id = id
        self.teamId = teamId
        self.name = name
        self.expires = expires
        self.token = token
    }
    
}

// MARK: - Migrations

extension UploadKey: Migration {
    
    public static func prepare(on connection: DbCoreConnection) -> Future<Void> {
        return Database.create(self, on: connection) { (schema) in
            schema.addField(type: DbCoreColumnType.id(), name: CodingKeys.id.stringValue, isIdentifier: true)
            schema.addField(type: DbCoreColumnType.id(), name: CodingKeys.teamId.stringValue)
            schema.addField(type: DbCoreColumnType.varChar(60), name: CodingKeys.name.stringValue)
            schema.addField(type: DbCoreColumnType.datetime(), name: CodingKeys.expires.stringValue, isOptional: true)
            schema.addField(type: DbCoreColumnType.varChar(64), name: CodingKeys.token.stringValue)
        }
    }
    
    public static func revert(on connection: DbCoreConnection) -> Future<Void> {
        return Database.delete(UploadKey.self, on: connection)
    }
    
}
