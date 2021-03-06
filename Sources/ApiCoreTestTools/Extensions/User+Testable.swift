//
//  User+Testable.swift
//  ApiCoreTestTools
//
//  Created by Ondrej Rafaj on 28/02/2018.
//

import Foundation
import DbCore
import ApiCore
import Vapor
import Fluent
import VaporTestTools


extension TestableProperty where TestableType == User {
    
    @discardableResult public static func createSu(on app: Application) -> User {
        let req = app.testable.fakeRequest()
        let user = try! User(firstname: "Super", lastname: "Admin", email: "admin@liveui.io", password: ("admin").passwordHash(req), token: nil, expires: nil, disabled: false, su: true)
        return create(user: user, on: app)
    }
    
    @discardableResult public static func create(firstname: String? = nil, lastname: String? = nil, email: String? = nil, password: String? = nil, token: String? = nil, expires: Date? = nil, disabled: Bool = true, su: Bool = false, on app: Application) -> User {
        let req = app.testable.fakeRequest()
        let user = try! User(firstname: firstname ?? "Ondrej", lastname: lastname ?? "Rafaj", email: email ?? "dev@liveui.io", password: (password ?? "sup3rS3cr3t").passwordHash(req), token: token, expires: expires, disabled: disabled, su: su)
        return create(user: user, on: app)
    }
    
    @discardableResult public static func create(user: User, on app: Application) -> User {
        let req = app.testable.fakeRequest()
        return try! user.save(on: req).await(on: req)
    }
    
}
