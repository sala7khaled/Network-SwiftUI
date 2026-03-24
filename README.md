<p align="center">
  <img src="Screenshots/Cover.png" height="400">
</p>

# 🛜 Network SwiftUI
A fully SwiftUI-based iOS networking layer with robust API handling, live image caching, and integrated Sentry logging for monitoring requests and errors. Designed to simplify API calls, provide detailed console logs, and handle errors gracefully.

## Features
- [x] 📡 **Async/Await Networking**: Modern Swift concurrency support.
- [x] 📦 **Automatic JSON encoding/decoding**: Uses `Encodable` and `Decodable`.
- [x] 🚩 **Error handling**: Unified APIError mapping and logging.
- [x] 📝 **Sentry Integration**: Logs API calls, responses, and errors for monitoring.
- [x] 🏁 **Pagination support**: Efficiently loads more data when scrolling.
- [x] 💿 **Request caching**: Handles offline scenarios automatically.
- [x] 🖼 **Image caching**: Async image loading with in-memory caching.

<br>

#### Project Structure
```sql
Network-SwiftUI
│
├── Network/
│   │
│   ├── Core/
│   │   ├── API.swift                  # Defines API endpoints and request configurations
│   │   ├── Components.swift           # Reusable networking components (headers, params, etc.)
│   │   ├── Generic.swift              # Generic models or helpers for network responses
│   │   ├── Network.swift              # Handles requests, response decoding, error mapping, and caching
│   │   └── Network + Image.swift      # Networking utilities specific to image downloading
│   │
│   ├── Extensions/
│   │   ├── Extensions.swift           # Common Swift extensions used across the network layer
│   │   └── URLRequest.swift           # Extension for building URLRequests & URLComponents
│   │
│   ├── Helpers/
│   │   ├── Connectivity.swift         # Checks device's internet connection status
│   │   ├── Console.swift              # Logs requests, responses, errors, Sentry entry, and images
│   │   └── Sentry.swift               # API requests reporting / crash logging
│   │
│   └── UseCase/
│       ├── Repo.swift                 # Repository layer for data fetching & abstraction
│       └── Service.swift              # Implementation of service calls for each endpoint
│
├── App/
├── Assets/
├── Scenes/
└── Etc...
```

<br>
<br>
<br>


## Example

```swift
// View

struct ContentView: View {
    var body: some View {

      List(viewModel.list) { item in
      // ...
      }
      .refreshable { Task { await viewModel.fetchExample() } }
      .task { await viewModel.fetchExample() }
    }
}
```
```swift
// View Model

func fetchExample async {
  let result = await repo.fetchExample(params: _)

  switch result {
  case .success(let response):
    // ...
  case .failure(let error):
    // ...
  }
}
```


```swift
// Repository

class MyRepo: Repo {
    func fetchExample(params: Param) async -> Result<BaseResponse<[Model]>, APIError> {
        do {
            let response: BaseResponse<[Model]> = try await network.call(Service.getExample(params))
            return .success(response)
        } catch {
            return .failure(network.mapError(error))
        }
    }
}
```
```swift
// Service

enum Service: ServiceProtocol {
    case getExample(_ params: Param)
    var url: String { API.baseUrl }
    var path: String { "example" }
    var method: HTTPMethod { .GET }
    var parameters: Parameters? { params }
    var headers: Headers? { nil }
    var body: Encodable? { nil }
}
```

<br>
<br>
<br>

### Screenshots

#### Network
<p align="start">
  <img src="Screenshots/1.png" width="250">
  &nbsp;&nbsp;&nbsp;
  <img src="Screenshots/2.png" width="250">
</p>


<br>
<br>
<br>


## Sentry Integration 
All API calls, responses, and errors are automatically logged to **Sentry** via the `SentryManager`.
<br>
This provides full observability for networking in development environments.

- [x] 🚀 API success/failure events
- [x] 🕒 Request durations
- [x] 📊 Statistics with chart
- [x] 🐞 Errors and backend failure messages
- [x] 📦 Response payloads


#### Sentry
<p align="start">
  <img src="Screenshots/3.png" width="250">
  &nbsp;&nbsp;&nbsp;
  <img src="Screenshots/4.png" width="250">
  &nbsp;&nbsp;&nbsp;
  <img src="Screenshots/5.png" width="250">
  &nbsp;&nbsp;&nbsp;
  <img src="Screenshots/6.png" width="250">
  &nbsp;&nbsp;&nbsp;
  <img src="Screenshots/7.png" width="250">
  &nbsp;&nbsp;&nbsp;
  <img src="Screenshots/8.png" width="250">
</p>

---

#### Images
<p align="start">
  <img src="Screenshots/16.png" width="250">
  &nbsp;&nbsp;&nbsp;
  <img src="Screenshots/17.png" width="250">
</p>

---

#### Detail (Success)
<p align="start">
  <img src="Screenshots/9.png" width="250">
  &nbsp;&nbsp;&nbsp;
  <img src="Screenshots/11.png" width="250">
  &nbsp;&nbsp;&nbsp;
  <img src="Screenshots/10.png" width="250">
</p>

---

#### Detail (Failed)

All network errors are mapped into `APIError` with types:
<br>
`.url` `.request` `.network` `.parsing` `.unauthorized` `.server` `.backend` `.unknown`
<br>
Use `error.localize()` to get a user-friendly localized string.
<br>


<p align="start">
  <img src="Screenshots/12.png" width="250">
  &nbsp;&nbsp;&nbsp;
  <img src="Screenshots/13.png" width="250">
  &nbsp;&nbsp;&nbsp;
  <img src="Screenshots/14.png" width="250">
    &nbsp;&nbsp;&nbsp;
  <img src="Screenshots/15.png" width="250">
</p>
