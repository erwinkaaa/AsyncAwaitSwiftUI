//
//  ARepository.swift
//  Coroutine
//
//  Created by ACI on 06/07/22.
//

import Foundation

class ARepository: BaseRepository {
    
    static let shared = ARepository()
    
    func test() async -> ResponseWrapperObject<EmptyResponse> {
        return await urlRequest(route: ARoute.a).unWrapToObject(model: EmptyResponse.self)
    }
    
}
