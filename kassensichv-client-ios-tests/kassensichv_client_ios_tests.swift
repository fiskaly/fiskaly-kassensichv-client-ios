//
//  kassensichv_client_ios_tests.swift
//  kassensichv_client_ios_tests
//
//  Created by Benjamin Müllner on 07.11.19.
//  Copyright © 2019 fiskaly. All rights reserved.
//

import XCTest
import kassensichv_client_ios

class kassensichv_client_ios_tests: XCTestCase {
    
    let expectationTSS = XCTestExpectation(description: "Finish TSS Clall to API")
    let expectationClient = XCTestExpectation(description: "Finish Client Call to API")
    let expectationTX = XCTestExpectation(description: "Finish TX Call to API")
    let expectationTX2 = XCTestExpectation(description: "Finish TX2 Call to API")
    let expectationExport = XCTestExpectation(description: "Finish Export Call to API")
    let expectation = XCTestExpectation(description: "Finish Client Call to API")
    let client = {
        return Client(
            apiKey: ProcessInfo.processInfo.environment["api_key"]!,
            apiSecret: ProcessInfo.processInfo.environment["api_secret"]!)
    }
    let tssUUID = UUID().uuidString
    let clientUUID = UUID().uuidString
    let transactionUUID = UUID().uuidString
    let exportID = UUID().uuidString
    
    public func test01_createTss(){
        
        self.upsertTss()
        
    }
    
    public func test02_createClient(){
        
        self.upsertTss()
        self.upsertClient()
        
    }
    
    public func test03_createTransaction(){
        
        self.upsertTss()
        self.upsertClient()
        self.startTransaction()
        
    }
    
    /*
     * TSS Functions
     * https://kassensichv.io/api/docs/#tag/Technical-Security-Systems
     */
    
    //https://kassensichv.io/api/docs/#operation/upsertTss
    public func upsertTss(){
                
        do {
            try client().send(
                method: "PUT",
                path: "tss/\(tssUUID)",
                body: ["description":"CodeExampleTSS", "state":"INITIALIZED"],
                completion: { (result) in
                    switch result {
                    case .success(_, let response):
                        XCTAssert((response as? HTTPURLResponse)?.statusCode == 200)
                        self.expectationTSS.fulfill()
                        break;
                    case .failure(let error):
                        print("Error: \(error)")
                        XCTFail()
                        break;
                    }
            })
        } catch {
            print("Error while sending: \(error).")
            XCTFail()
        }
        
        wait(for: [expectationTSS], timeout: 5.0)
        
    }
    
    //https://kassensichv.io/api/docs/#operation/listTss
    public func listTss(){
        
        do {
            try client().send(
                method: "GET",
                path: "tss",
                completion: { (result) in
                    switch result {
                    case .success(_, let response):
                        XCTAssert((response as? HTTPURLResponse)?.statusCode == 200)
                        self.expectation.fulfill()
                        break;
                    case .failure(let error):
                        print("Error: \(error)")
                        XCTFail()
                        break;
                    }
            })
        } catch {
            print("Error while sending: \(error).")
            XCTFail()
        }
        
        wait(for: [expectation], timeout: 5.0)
        
    }
    
    /*
     * Client Functions
     * https://kassensichv.io/api/docs/#tag/Clients
     */
    
    //https://kassensichv.io/api/docs/#operation/upsertClient
    public func upsertClient(){
                
        do {
            try client().send(
                method: "PUT",
                path: "tss/\(tssUUID)/client/\(clientUUID)",
                body:["serial_number":UUID().uuidString],
                completion: { (result) in
                    switch result {
                    case .success(_, let response):
                        XCTAssert((response as? HTTPURLResponse)?.statusCode == 200)
                        self.expectationClient.fulfill()
                        break;
                    case .failure(let error):
                        print("Error: \(error)")
                        XCTFail()
                        break;
                    }
            })
        } catch {
            print("Error while sending: \(error).")
            XCTFail()
        }
        
        wait(for: [expectationClient], timeout: 5.0)
        
    }
    
    //https://kassensichv.io/api/docs/#operation/listAllClients
    public func listAllClients(){
        
        do {
            try client().send(
                method: "GET",
                path: "client",
                query:["order_by":"time_creation", "order":"asc"],
                completion: { (result) in
                    switch result {
                    case .success(_, let response):
                        self.expectation.fulfill()
                        XCTAssert((response as? HTTPURLResponse)?.statusCode == 200)
                        break;
                    case .failure(let error):
                        print("Error: \(error)")
                        XCTFail()
                        break;
                    }
            })
        } catch {
            print("Error while sending: \(error).")
            XCTFail()
        }
        
        wait(for: [expectation], timeout: 5.0)
        
    }
    
    /*
     * Transaction Functions
     * https://kassensichv.io/api/docs/#tag/Transactions
     */
    
    //https://kassensichv.io/api/docs/#operation/upsertTransaction
    public func startTransaction(){
        
        // Start a new Transaction
        do {
            try client().send(
                method: "PUT",
                path: "tss/\(tssUUID)/tx/\(transactionUUID)",
                body:["state":"ACTIVE", "client_id":clientUUID],
                completion: { (result) in
                    switch result {
                    case .success(_, let response):
                        XCTAssert((response as? HTTPURLResponse)?.statusCode == 200)
                        self.expectationTX.fulfill()
                        break;
                    case .failure(let error):
                        print("Error: \(error)")
                        XCTFail()
                        break;
                    }
            })
        } catch {
            print("Error while sending: \(error).")
            XCTFail()
        }
        
        wait(for: [expectationTX], timeout: 5.0)
        
    }
    
    public func finishTransaction(){
        
        // Finish a new Transaction
        do {
            try client().send(
                method: "PUT",
                path: "tss/\(tssUUID)/tx/\(transactionUUID)",
                query: ["last_revision":"1"],
                body:["state":"FINISHED", "client_id":clientUUID, "type":"TEST"],
                completion: { (result) in
                    switch result {
                    case .success(_, let response):
                        XCTAssert((response as? HTTPURLResponse)?.statusCode == 200)
                        self.expectationTX2.fulfill()
                        break;
                    case .failure(let error):
                        print("Error: \(error)")
                        XCTFail()
                        break;
                    }
            })
        } catch {
            print("Error while sending: \(error).")
            XCTFail()
        }
        
        wait(for: [expectationTX2], timeout: 5.0)
        
    }
    
    //https://kassensichv.io/api/docs/#operation/listAllTransactions
    public func listAllTransactions(){
        
        do {
            try client().send(
                method: "GET",
                path: "tx",
                query:["order_by":"state", "order":"asc"],
                completion: { (result) in
                    switch result {
                    case .success(_, let response):
                        XCTAssert((response as? HTTPURLResponse)?.statusCode == 200)
                        self.expectation.fulfill()
                        break;
                    case .failure(let error):
                        print("Error: \(error)")
                        XCTFail()
                        break;
                    }
            })
        } catch {
            print("Error while sending: \(error).")
            XCTFail()
        }
        
        wait(for: [expectation], timeout: 5.0)
        
    }
    
    /*
     * Export Functions
     * https://kassensichv.io/api/docs/#tag/Data-Exports
     */
    
    //https://kassensichv.io/api/docs/#operation/triggerExport
    public func triggerExport(){
        
        do {
            try client().send(
                method: "PUT",
                path: "tss/\(tssUUID)/export/\(exportID)",
                query:["client_id":clientUUID],
                completion: { (result) in
                    switch result {
                    case .success(_, let response):
                        XCTAssert((response as? HTTPURLResponse)?.statusCode == 200)
                        self.expectationExport.fulfill()
                        break;
                    case .failure(let error):
                        print("Error: \(error)")
                        XCTFail()
                        break;
                    }
            })
        } catch {
            print("Error while sending: \(error).")
            XCTFail()
        }
        
        wait(for: [expectationExport], timeout: 5.0)
        
    }
    
    //https://kassensichv.io/api/docs/#operation/retrieveExport
    public func retrieveExport(){
        
        do {
            try client().send(
                method: "GET",
                path: "tss/\(tssUUID)/export/\(exportID)",
                completion: { (result) in
                    switch result {
                    case .success(_, let response):
                        XCTAssert((response as? HTTPURLResponse)?.statusCode == 200)
                        self.expectation.fulfill()
                        break;
                    case .failure(let error):
                        print("Error: \(error)")
                        XCTFail()
                        break;
                    }
            })
        } catch {
            print("Error while sending: \(error).")
            XCTFail()
        }
        
        wait(for: [expectation], timeout: 5.0)
        
    }
    
}
