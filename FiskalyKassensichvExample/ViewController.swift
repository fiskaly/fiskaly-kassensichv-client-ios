import Foundation
import UIKit
import FiskalyKassensichvSma

struct TxDataAeaoAmountPerVatRate: Codable {
    let vatRate: String
    let amount: String
}

struct TxDataAeaoAmountPerPaymentType: Codable {
    let paymentType: String
    let amount: String
}

struct TxDataAeaoAmount: Codable {
    let vatRate: String
    let amount: String
}

struct TxDataAeao: Codable {
    let receiptType: String
    let amountsPerVatRate: [TxDataAeaoAmountPerVatRate]
    let amountPerPaymentType: [TxDataAeaoAmountPerPaymentType]
}

struct TxData: Codable {
    let aeao: TxDataAeao
}

struct Tx: Codable {
    let clientId: String
    let state: String
    let type: String
    let data: TxData
}

class FiskalyKassensichvClient {
    struct AuthRequest: Codable {
        let apiKey: String
        let apiSecret: String
    }
    struct AuthResponse: Codable {
        let accessToken: String
    }
    
    static let baseURL = URL(string: "https://kassensichv.fiskaly.com/api/v0/")!
    static let authURL = baseURL.appendingPathComponent("auth")
    public static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()
    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    
    let apiKey: String
    let apiSecret: String
    let urlSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = [
            "content-type": "application/json",
            "accept": "application/json"
        ]
        return URLSession(configuration: configuration)
    }()
    
    var accessToken: String?
    
    init(apiKey: String, apiSecret: String) {
        self.apiKey = apiKey
        self.apiSecret = apiSecret
    }
    
    func startTx(tssId: String, clientId: String, data: TxData, completionHandler: @escaping (Data?, Error?) -> Void) {
        let tx = Tx(
            clientId: clientId,
            state: "ACTIVE",
            type: "RECEIPT",
            data: data
        )
        let txData = try! FiskalyKassensichvClient.encoder.encode(tx)
        let txDataDict = try! JSONSerialization.jsonObject(with: txData, options: .allowFragments) as! [String: Any]
        let resultObj = invokeSma(method: "sign-transaction", params: [txDataDict])
        let resultData = try! JSONSerialization.data(withJSONObject: resultObj)
        let txId = UUID().uuidString
        let txPath = "tss/\(tssId)/tx/\(txId)/log"
        fetch(
            method: "PUT",
            path: txPath,
            body: resultData,
            completionHandler: completionHandler
        )
    }
    
    func fetch<Body: Codable>(method: String, path: String, body: Body, completionHandler: @escaping (Data?, Error?) -> Void) {
        var data: Data
        do {
            data = try FiskalyKassensichvClient.encoder.encode(body)
        } catch {
            return completionHandler(nil, error)
        }
        fetch(
            method: method,
            path: path,
            body: data,
            completionHandler: completionHandler
        )
    }
    
    func fetch(method: String, path: String, body: Data, completionHandler: @escaping (Data?, Error?) -> Void) {
        let url = FiskalyKassensichvClient.baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        if let accessToken = self.accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "authorization")
        }
        doFetch(request, completionHandler: completionHandler)
    }
    
    func doFetch(_ request: URLRequest, completionHandler: @escaping (Data?, Error?) -> Void) {
        let task = self.urlSession.dataTask(
            with: request,
            completionHandler: { (data, response, error) in
                if let error = error {
                    completionHandler(nil, error)
                } else if let data = data {
                    completionHandler(data, nil)
                } else {
                    completionHandler(nil, nil)
                }
        }
        )
        task.resume()
    }
    
    func auth(_ completionHandler: @escaping (Error?) -> Void) {
        var request = URLRequest(url: FiskalyKassensichvClient.authURL)
        request.httpMethod = "POST"
        request.httpBody = try! FiskalyKassensichvClient.encoder.encode(AuthRequest(apiKey: apiKey, apiSecret: apiSecret))
        doFetch(request) { (data, error) in
            do {
                let authRes = try FiskalyKassensichvClient.decoder.decode(AuthResponse.self, from: data!)
                self.accessToken = authRes.accessToken
                completionHandler(nil)
            } catch {
                completionHandler(error)
            }
        }
    }
    
    func invokeSma(method: String, params: [[String: Any]]) -> Any {
        let smaReqDict: [String : Any] = [
            "jsonrpc": "2.0",
            "method": method,
            "params": params
        ]
        let smaReqData = try! JSONSerialization.data(withJSONObject: smaReqDict)
        let smaReqStr = String(data: smaReqData, encoding: .utf8)!
        let smaResStr = FiskalyKassensichvSmaInvoke(smaReqStr)
        let smaResData = smaResStr.data(using: .utf8)!
        let smaResObj = try! JSONSerialization.jsonObject(with: smaResData) as! [String: AnyObject]
        let resultObj = smaResObj["result"]
        return resultObj!
    }
}

class ViewController: UIViewController {
    @IBOutlet weak var request: UITextView!
    @IBOutlet weak var response: UITextView!
    
    let tssId = ""    // TODO: insert your TSS UUID here!
    let clientId = "" // TODO: insert your Client UUID here!
    let client = FiskalyKassensichvClient(
        apiKey: "",   // TODO: insert your API Key here!
        apiSecret: "" // TODO: insert your API Secret here!
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        let smaVersion = client.invokeSma(method: "version", params: [])
        response.text = "SMA Version \(smaVersion)"
        request.text = """
        {
          "aeao": {
            "receipt_type": "RECEIPT",
            "amounts_per_vat_rate" : [
              {
                "vat_rate": "19",
                "amount": "10.00"
              }
            ],
            "amount_per_payment_type" : [
              {
                "payment_type": "CASH",
                "amount" : "10.00"
              }
            ]
          }
        }
        """
    }

    @IBAction func invoke(_ sender: Any) {
        let textData = request.text!.data(using: .utf8)!
        let data = try! FiskalyKassensichvClient.decoder.decode(TxData.self, from: textData)
        client.auth { (error) in
            self.client.startTx(
                tssId: self.tssId,
                clientId: self.clientId,
                data: data
            ) { (data, error) in
                DispatchQueue.main.async {
                    self.response.text = String(data: data!, encoding: .utf8)!
                }
            }
        }
    }
}
