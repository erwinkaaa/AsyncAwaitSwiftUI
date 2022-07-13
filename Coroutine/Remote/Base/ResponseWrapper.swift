//
//  ResponseWrapper.swift
//  Coroutine
//
//  Created by ACI on 06/07/22.
//

import Foundation

// UI / VM LEVEL =============================================
struct ResponseWrapperObject<T: Codable> : Codable {
    let success: Bool
    let description: String
    var value: ResponseObject<T>? = nil
}

struct ResponseWrapperList<T: Codable> : Codable {
    let success: Bool
    let description: String
    var value: ResponseArray<T>? = nil
}
// UI / VM LEVEL =============================================

// API RESPONSE ==============================================
struct ResponseArray<T : Codable> : Codable {
    let rc: Int
    let rd: String
    let data: [T]?
}
struct ResponseObject<T : Codable> : Codable {
    let rc: Int
    let rd: String
    let data: T?
    // -- login need
    let access_token: String?
}
// API RESPONSE ==============================================


// DECODE LEVEL =============================================
struct DecodeWrapper<T : Codable> {
    var success: Bool
    var description: String = ""
    var data: T? = nil
}
// DECODE LEVEL =============================================

// NETWORK LEVEL =============================================
struct NetworkWrapper {
    var success: Bool
    var description: String
    var data: Data? = nil
}
// NETWORK LEVEL =============================================
