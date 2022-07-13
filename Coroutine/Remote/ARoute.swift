//
//  ARoute.swift
//  Coroutine
//
//  Created by ACI on 06/07/22.
//

import Foundation

enum ARoute: ApiConfig {
    case a
}
    
extension ARoute {
    var baseUrl: String { return "https://wendei.id/" }
    var header: [String: String] {
        switch self {
        default:
            return [
                "Accept": "application/json",
                "Content-Type": ContentType.json
            ]
        }
    }
    var method: HttpMethod {
        switch self {
        case .a:
            return .get
        }
    }
    var path: String {
        switch self {
        case .a:
            return ""
        }
    }
    var body: [String : Any] {
        return [:]
    }
    var parameter: [String : Any] {
        return [:]
    }
}
