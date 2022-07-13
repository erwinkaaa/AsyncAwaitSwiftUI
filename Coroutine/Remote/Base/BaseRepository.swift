//
//  BaseRepository.swift
//  Coroutine
//
//  Created by ACI on 06/07/22.
//

import Foundation
import SwiftUI

protocol ApiConfig {
    var baseUrl: String { get }
    var path: String { get }
    var parameter: [String: Any] { get }
    var header: [String: String] { get }
    var method: HttpMethod { get }
    var body: [String: Any] { get }
}

enum HttpMethod: String {
    case post  = "POST"
    case get   = "GET"
    case del   = "DELETE"
    case put   = "PUT"
    case patch = "PATCH"
}

struct ContentType {
    static let json = "application/json"
    static let urlEncoded = "application/x-www-form-urlencoded"
}

fileprivate let isLoggingApiEnabled = true

class BaseRepository {
    
    func urlRequest(route: ApiConfig) async -> NetworkWrapper {
        var completeUrl = route.baseUrl + route.path
        
        var urlRequest = URLRequest(url: URL(string: completeUrl)!, timeoutInterval: 60)
        urlRequest.allHTTPHeaderFields = route.header
        
        if route.method == .get {
            
            if isLoggingApiEnabled {
                print("------------------------------- START -----------------------------------------")
                print("Accessing URL : \(completeUrl)")
                print("Header : \(route.header)")
                print("Method : \(route.method.rawValue)")
                print("Parameters : \(route.parameter.stringToHttpParameters())")
            }
            
            completeUrl += route.parameter.stringToHttpParameters()
            
            urlRequest.url = URL(string: completeUrl)!
        } else {
            
            if isLoggingApiEnabled {
                print("------------------------------- START -----------------------------------------")
                print("Accessing URL : \(completeUrl)")
                print("Header : \(route.header)")
                print("Method : \(route.method.rawValue)")
            }
            
            if route.header.values.contains(ContentType.urlEncoded) {
                urlRequest.httpBody = getPostEncodedString(params: route.body).data(using: .utf8)
                print("Request Body : \(getPostEncodedString(params: route.body))")
            } else {
                urlRequest.httpBody = try? JSONSerialization.data(withJSONObject: route.body, options: .prettyPrinted)
                print("Request Body : \n\(String(data: urlRequest.httpBody!, encoding: .utf8)!)")
            }
        }
        
        urlRequest.httpMethod = route.method.rawValue
        
        if isLoggingApiEnabled {
            print("--------------------------------- END -----------------------------------------")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            if let response = response as? HTTPURLResponse {
                if !(200...299).contains(response.statusCode) {
                    
                    if isLoggingApiEnabled {
                        print("Response Http Code: \(completeUrl) - (\(response.statusCode))")
                        print("Response Http Data: \(String(data: data, encoding: .utf8)!)")
                    }
                    
                    switch response.statusCode {
                    case 400:
                        let errorResponse = await data.decodeTo(ResponseObject<EmptyResponse>.self)
                        return NetworkWrapper(success: false, description: errorResponse.data!.rd)
                    case 401:
                        return NetworkWrapper(success: false, description: "401")
                    case 404:
                        return NetworkWrapper(success: false, description: "NotFound, \(response.statusCode)")
                    case 500:
                        return NetworkWrapper(success: false, description: "Internal Server Error, \(response.statusCode)")
                    default:
                        return NetworkWrapper(success: false, description: " Other, \(response.statusCode))")
                    }
                }
                
                if isLoggingApiEnabled {
                    print("Response Http Code: \(completeUrl) - (\(response.statusCode))")
                    print("Response Http Data: \(String(data: data, encoding: .utf8)!)")
                }
                
                return NetworkWrapper(success: true, description: "Success", data: data)
            } else {
                return NetworkWrapper(success: false, description: "HTTPURLResponse error!")
            }
        }
        catch {
            return NetworkWrapper(success: false, description: error.localizedDescription)
        }
    }
    
    private func getPostEncodedString(params:[String:Any]) -> String {
        var data = [String]()
        for(key, value) in params {
            data.append(key + "=\(value)")
        }
        return data.map { String($0) }.joined(separator: "&")
        // value1=data1&value2=data2
    }
}

extension Dictionary {
    
    /// Build string representation of HTTP parameter dictionary of keys and objects
    ///
    /// :returns: String representation in the form of key1=value1&key2=value2 where the keys and values are percent escaped

    func stringToHttpParameters() -> String {
        if self.isEmpty {
            return ""
        }
        
        var parametersString = ""
        for (key, value) in self {
            if let key = key as? String,
               let value = value as? String {
                parametersString = parametersString + key + "=" + value + "&"
            }
        }
        parametersString = parametersString.substring(to: parametersString.index(before: parametersString.endIndex))
        return "?" + parametersString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
    }
}

extension Data {
    func decodeTo<T: Codable>(_ type: T.Type) async -> DecodeWrapper<T> {
        do {
            let result = try JSONDecoder().decode(T.self, from: self)
            return DecodeWrapper(success: true, data: result)
        } catch let DecodingError.dataCorrupted(context) {
            return DecodeWrapper(success: false, description: "\(context)")
        } catch let DecodingError.keyNotFound(key, context) {
            print("Key '\(key)' not found:", context.debugDescription)
            print("codingPath:", context.codingPath)
            return DecodeWrapper(success: false, description: "\(context)")
        } catch let DecodingError.valueNotFound(value, context) {
            print("Value '\(value)' not found:", context.debugDescription)
            print("codingPath:", context.codingPath)
            return DecodeWrapper(success: false, description: "\(context)")
        } catch let DecodingError.typeMismatch(type, context)  {
            print("Type '\(type)' mismatch:", context.debugDescription)
            print("codingPath:", context.codingPath)
            return DecodeWrapper(success: false, description: "\(context)")
        } catch {
            print("error: ", error)
            return DecodeWrapper(success: false, description: "\(error)")
        }
    }
}

extension NetworkWrapper {
    func unWrapToObject<T: Codable>(model: T.Type) async -> ResponseWrapperObject<T>  {
        if self.success, let data = self.data {
            let resultDecode = await data.decodeTo(ResponseObject<T>.self)
            if resultDecode.success {
                if isLoggingApiEnabled {
                    dump(data)
                }
                return ResponseWrapperObject<T>(success: true, description: self.description, value: resultDecode.data)
            } else {
                return ResponseWrapperObject<T>(success: false, description: resultDecode.description)
            }
        } else {
            return ResponseWrapperObject<T>(success: false, description: self.description)
        }
    }
    
    func unWrapToList<T: Codable>(model: T.Type) async -> ResponseWrapperList<T> {
        if self.success, let data = self.data {
            let resultDecode = await data.decodeTo(ResponseArray<T>.self)
            if resultDecode.success {
                if isLoggingApiEnabled {
                    dump(data)
                }
                return ResponseWrapperList<T>(success: true, description: self.description, value: resultDecode.data)
            } else {
                return ResponseWrapperList<T>(success: false, description: resultDecode.description)
            }
        } else {
            return ResponseWrapperList<T>(success: false, description: self.description)
        }
    }
}
