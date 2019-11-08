//
//  Client.swift
//  kassensichv-client-ios
//
//  Created by Benjamin Müllner on 31.10.19.
//  Copyright © 2019 fiskaly. All rights reserved.
//

import Foundation
import FiskalyKassensichvSma

public enum DataConvertionError: Error {
    case failedToConvertData2String
    case failedToConvertString2Data
    case dictionaryFormatMismatch
}

public enum SMAServiceError: Error {
    case failedToExtractSignedData
}

public enum AuthError: Error {
    case authenticationFailed
}

typealias HTTPRequestCompletionHandler = (Result<(Data, URLResponse?), Error>) -> Void

final class HTTPService {
    
    @discardableResult
    static func perform(request: URLRequest,
                        on session: URLSession = URLSession.shared,
                        completion: @escaping HTTPRequestCompletionHandler) -> URLSessionDataTask {
        let dataTask = session.dataTask(with: request) { (data, urlResponse, error) in
            DispatchQueue.main.async {
                if let data = data {
                    completion(.success((data, urlResponse)))
                } else if let error = error {
                    completion(.failure(error))
                }
            }
        }
        dataTask.resume()
        return dataTask
    }
}

public class Client {
    
    let baseURL = URL(string: "https://kassensichv.io/api/v0/")!
    let apiKey: String
    let apiSecret: String
    var accessToken: String?
    var refreshToken: String?
    var retryCounter: Int
    
    public init(apiKey: String, apiSecret: String) {
        self.apiKey = apiKey
        self.apiSecret = apiSecret
        self.retryCounter = 0
    }
    
    public func send( method: String,
                      path: String,
                      completion: @escaping (Result<(Data, URLResponse?), Error>) -> Void) throws {
        try self.send(method: method, path: path, query: nil, headers: nil, body: nil, completion: completion)
    }
    
    public func send( method: String,
                      path: String,
                      query: [String: String]?,
                      completion: @escaping (Result<(Data, URLResponse?), Error>) -> Void) throws {
        try self.send(method: method, path: path, query: query, headers: nil, body: nil, completion: completion)
    }
    
    public func send( method: String,
                      path: String,
                      body: Data,
                      completion: @escaping (Result<(Data, URLResponse?), Error>) -> Void) throws {
        let bodyDic = try JSONSerialization.jsonObject(with: body, options:JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
        try self.send(method: method, path: path, query: nil, headers: nil, body: bodyDic as? Dictionary, completion: completion)
    }
    
    public func send( method: String,
                      path: String,
                      body: [String:Any]?,
                      completion: @escaping (Result<(Data, URLResponse?), Error>) -> Void) throws {
        
        try self.send(method: method, path: path, query: nil, headers: nil, body: body, completion: completion)
    }
    
    public func send( method: String,
                      path: String,
                      query: [String: String]?,
                      body: Data,
                      completion: @escaping (Result<(Data, URLResponse?), Error>) -> Void) throws {
        let bodyDic = try JSONSerialization.jsonObject(with: body, options:JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
        try self.send(method: method, path: path, query: query, headers: nil, body: bodyDic as? Dictionary, completion: completion)
    }
    
    public func send( method: String,
                      path: String,
                      query: [String: String]?,
                      body: [String:Any]?,
                      completion: @escaping (Result<(Data, URLResponse?), Error>) -> Void) throws {
        try self.send(method: method, path: path, query: query, headers: nil, body: body, completion: completion)
    }
    
    public func send( method: String,
                      path: String,
                      query: [String: String]?,
                      headers: [String:String]?,
                      body: Data,
                      completion: @escaping (Result<(Data, URLResponse?), Error>) -> Void) throws {
        let bodyDic = try JSONSerialization.jsonObject(with: body, options:JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
        try self.send(method: method, path: path, query: query, headers: headers, body: bodyDic as? Dictionary, completion: completion)
    }
    
    public func send( method: String,
                      path: String,
                      query: [String: String]?,
                      headers: [String:String]?,
                      body: [String:Any]?,
                      completion: @escaping (Result<(Data, URLResponse?), Error>) -> Void) throws {
        
        let range = NSRange(location: 0, length: path.utf8.count)
        let regex = try! NSRegularExpression(pattern: #"^tss\/.+\/tx\/.+"#,
                                             options: NSRegularExpression.Options.caseInsensitive)
        var finalBody: Data?
        var url = self.baseURL.appendingPathComponent(path)
        
        if body != nil && method.caseInsensitiveCompare("PUT") == .orderedSame &&
            regex.firstMatch(in: path, options: [], range: range) != nil {
            
            let smaReqDict: [String:Any] = [
                "jsonrpc": "2.0",
                "method": "sign-transaction",
                "params": [body]
            ]
            
            let smaReqStr = try self.convertDictionaryToUTF8String(dictionary: smaReqDict)
            let smaResStr: String = FiskalyKassensichvSmaInvoke(smaReqStr)
            let smaResObj = try self.convertUTF8StringToDictionary(string: smaResStr)
            guard let signedBody = smaResObj["result"] else {
                throw SMAServiceError.failedToExtractSignedData
            }
            finalBody = try JSONSerialization.data(withJSONObject: signedBody)
            url = url.appendingPathComponent("log")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        if let query = query {
            var components = URLComponents(string: "\(url)")!
            components.queryItems = query.map { (arg) -> URLQueryItem in
                let (key, value) = arg
                return URLQueryItem(name: key, value: value)
            }
            components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
            request = URLRequest(url: components.url!)
        }
        
        if let body = body {
            request.addValue("application/json", forHTTPHeaderField: "content-type")
            if(finalBody != nil){
                request.httpBody = finalBody
            } else {
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
            }
        }
        if let headers = headers {
            for (key, value) in headers {
                request.addValue("\(key)", forHTTPHeaderField: "\(value)")
            }
        }
        
        try self.authenticate(request: request) { (authResult) in
            switch authResult {
            case .failure(let error):
                completion(.failure(error))
                break
            case .success(let authenticatedRequest):
                HTTPService.perform(request: authenticatedRequest, completion: { (result) in
                    switch result {
                    case .success(let responseData, let response):
                        if let httpResponse = response as? HTTPURLResponse {
                            if httpResponse.statusCode == 401 && self.retryCounter < 5 {
                                self.retryCounter += 1
                                self.accessToken = nil
                                do {
                                    try self.send(method: method, path: path, query: query, headers: headers, body: body, completion: { (retryResult) in
                                        switch retryResult {
                                        case .success(let retryData, let retryResponse):
                                            completion(.success((retryData, retryResponse)))
                                            break
                                        case .failure(let error):
                                            completion(.failure(error))
                                            break
                                        }
                                    })
                                } catch {
                                    completion(.failure(error))
                                }
                            } else if self.retryCounter >= 5 {
                                completion(.failure(AuthError.authenticationFailed))
                            } else {
                                self.retryCounter = 0
                                completion(.success((responseData, response)))
                            }
                        }
                        completion(.success((responseData, response)))
                        break
                    case .failure(let error):
                        completion(.failure(error))
                        break
                    }
                })
                break
            }
        }
    }
    
    private func authenticate(request: URLRequest, completion: @escaping (Result<URLRequest, Error>) -> Void) throws {
        if self.accessToken == nil {
            try performAuthentication { (result) in
                if let _ = try? result.get() {
                    let authorizedRequest = self.authorize(request)
                    completion(.success(authorizedRequest))
                } else {
                    completion(.failure(AuthError.authenticationFailed))
                }
            }
        } else {
            let authorizedRequest = self.authorize(request)
            completion(.success(authorizedRequest))
        }
    }
    
    private func performAuthentication(completion: @escaping(Result<Bool, Error>) -> Void) throws {
        
        var authRequest = URLRequest(url: self.baseURL.appendingPathComponent("auth"))
        authRequest.addValue("application/json", forHTTPHeaderField: "content-type")
        authRequest.httpMethod = "POST"
        
        if refreshToken == nil {
            authRequest.httpBody = try JSONSerialization.data(withJSONObject:
                ["api_key":self.apiKey, "api_secret":self.apiSecret])
        } else {
            authRequest.httpBody = try JSONSerialization.data(withJSONObject: ["refresh_token":self.refreshToken])
        }
        
        HTTPService.perform(request: authRequest) { (result) in
            switch result {
            case .success(let data, _):
                do {
                    let jsonResult = try JSONSerialization.jsonObject(with: data, options:JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
                    self.accessToken = jsonResult.value(forKey: "access_token") as? String
                    self.refreshToken = jsonResult.value(forKey: "refresh_token") as? String
                    completion(.success(true))
                } catch {
                    completion(.failure(error))
                }
                break
            case .failure(let error):
                completion(.failure(error))
                break
            }
        }
    }
    
    private func authorize(_ request: URLRequest) -> URLRequest {
        var copyRequest = request
        if let accessToken = self.accessToken {
            copyRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        return copyRequest
    }
    
    private func convertDictionaryToUTF8String(dictionary: [String: Any]) throws -> String {
        let data = try JSONSerialization.data(withJSONObject: dictionary)
        
        guard let utf8string = String(data: data, encoding: .utf8) else {
            throw DataConvertionError.failedToConvertData2String
        }
        
        return utf8string
    }
    
    private func convertUTF8StringToDictionary(string: String) throws -> [String: AnyObject] {
        guard let data = string.data(using: .utf8) else {
            throw DataConvertionError.failedToConvertString2Data
        }
        
        let dict = try JSONSerialization.jsonObject(with: data)
        
        guard let formatDict = dict as? [String: AnyObject] else {
            throw DataConvertionError.dictionaryFormatMismatch
        }
        
        return formatDict
    }
    
}
