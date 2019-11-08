# fiskaly KassenSichV client for iOS

The fiskaly KassenSichV client is an HTTP client that is needed<sup>[1](#fn1)</sup> for accessing the [kassensichv.io](https://kassensichv.io) API that implements a cloud-based, virtual **CTSS** (~Certified~ Technical Security System) / **TSE** (Technische Sicherheitseinrichtung) as defined by the German **KassenSichV** ([Kassen­sich­er­ungsver­ord­nung](https://www.bundesfinanzministerium.de/Content/DE/Downloads/Gesetze/2017-10-06-KassenSichV.pdf)).

## Build project

First of all, you have to initialize the required git submodule(s) using:

```
$ git submodule update --init
```

After that you need to extract the .tgz file to access the sma-Framework.

```
$ tar -xvzf ./sma/dist/com.fiskaly.kassensichv.sma-ios.tgz
```

Once the Framework is extracted, open the .xcodeproj-File with XCode. Now you have to add the Framework as a library to be able to use it.

1. Select the project file from the project navigator on the left side of the project window.
 
2. Select the target for where you want to add frameworks in the project settings editor.
 
3. Select the “Build Phases” tab, and click the small triangle next to “Link Binary With Libraries” to view all of the frameworks in your application.
 
4. To Add frameworks, click the “+” below the list of frameworks.

5. Add Other - Add Files - Select extracted sma-Framework

Now you can build the project and run the tests provided (⌘B ⌘U).