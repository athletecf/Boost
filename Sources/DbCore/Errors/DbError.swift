//
//  DbError.swift
//  DbCore
//
//  Created by Ondrej Rafaj on 14/01/2018.
//

import Foundation
import Vapor
import ApiErrors


public enum DbError: FrontendError {
    
    case missingLastInsertedId

    public var code: String {
        return "db_error"
    }
    
    public var status: HTTPStatus {
        return .internalServerError
    }
    
    public var description: String {
        switch self {
        case .missingLastInsertedId:
            return "Last inserted ID is missing"
        }
    }
    
}