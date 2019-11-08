# fiskaly KassenSichV client for iOS

The fiskaly KassenSichV client is an HTTP client that is used for accessing the [kassensichv.io](https://kassensichv.io) API that implements a cloud-based, virtual **CTSS** (~Certified~ Technical Security System) / **TSE** (Technische Sicherheitseinrichtung) as defined by the German **KassenSichV** ([Kassen­sich­er­ungsver­ord­nung](https://www.bundesfinanzministerium.de/Content/DE/Downloads/Gesetze/2017-10-06-KassenSichV.pdf)).

## Build project

First of all, you have to initialize the required git submodule(s) using:

```
$ git submodule update --init
```

After that you need to extract the .tgz file to access the SMA-Framework.

```
$ tar -xvzf ./sma/dist/com.fiskaly.kassensichv.sma-ios.tgz
```

Once the Framework is extracted, open the .xcodeproj-File with XCode. Now you have to add the Framework as a library to be able to use it.

1. Select the project file from the project navigator on the left side of the project window.
 
2. Select the target for where you want to add frameworks in the project settings editor.
 
3. Select the “Build Phases” tab, and click the small triangle next to “Link Binary With Libraries” to view all of the frameworks in your application.
 
4. To Add frameworks, click the “+” below the list of frameworks.

5. Add Other - Add Files - Select extracted SMA-Framework

If you don't have an account on the [fiskaly Dashboard](https://dashboard.fiskaly.com/) already you will need to create one and create an API-Key and -Secret pair.

If you want to run the tests provided, you need to first add your API-Credentials as Environment-Variables or directly in the code. As soon as you have done that you can build and run the tests (⌘B ⌘U).

## Working with the client

Currently the client takes your parameters and handles the HTTPRequest with the KassensichV API. 

### Creating a client 

```Swift
import FiskalyKassensichvClient

let client = Client(
                apiKey: "Your API-Key",
                apiSecret: "Your API-Secret"
            )
```

### Sending a request to the API

```Swift
let tssUUID = UUID().uuidString

do {
    try client.request(
        method: "PUT",
        path: "tss/\(tssUUID)",
        body: ["description":"CodeExampleTSS", "state":"INITIALIZED"],
        completion: { (result) in
            switch result {
            case .success(let data, _):
                // work with the response data 
                break;
            case .failure(let error):
                print("Error: \(error)")
                break;
            }
    })
} catch {
    print("Error while sending: \(error).")
}
```

### Method signature of the request-function

```Swift
public func request(method: String,             // (required)   the method of the request "GET", "POST", "PUT"
                    path: String,               // (required)   the path for the request
                    query: [String: String]?,   // (optional)   any query parameters for the request
                    headers: [String:String]?,  // (optional)   additional headers you want to add
                    body: [String:Any]?,        // (optional)   data for the request body
                //  body: Data                                  you may also use the Data-Type
                    completion: @escaping (Result<(Data, URLResponse?), Error>) -> Void) 
                                                // completes with .success or .failure
                    throws                      // can throw different errors
```