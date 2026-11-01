# Aero

A lightweight **REST API client for macOS**, built with SwiftUI and SwiftData.
Inspired by tools like Insomnia, Aero focuses on a fast, native workflow for
testing backend APIs.

## Features

### Requests
- HTTP methods: `GET`, `POST`, `PUT`, `PATCH`, `DELETE`, `HEAD`, `OPTIONS`
- URL with query parameters and custom headers (per-row enable/disable)
- Request bodies: **None**, **JSON** (with validation + pretty-print), **Raw**,
  **Form URL-Encoded**, and **multipart/form-data** (text fields and files)
- Authentication: **No Auth**, **Bearer Token**, **Basic**, and **OAuth 2.0**
  (client-credentials and authorization-code via `ASWebAuthenticationSession`)

### Responses
- Status code (color-coded), elapsed time, and payload size
- `Preview` (pretty JSON), `Raw`, and `Headers` tabs
- In-body search with match highlighting, plus one-click copy

### Workspace
- Collections and requests, persisted with SwiftData
- Multiple open requests in **tabs**, each with its own response
- **Environments** with `{{variable}}` substitution and quick dev/prod switching
- **History** of executed requests, with review and re-send
- **cURL** import (paste a command) and export (copy as cURL)
- **Postman Collection v2.1** import and export

## Requirements

- macOS 26 (Tahoe) or later
- Xcode 16 or later (Swift 5)

## Building

```sh
git clone git@github.com:EugeneKwasny/aero.git
cd aero
open aero.xcodeproj
```

Then build and run the `aero` scheme (⌘R).

### App Sandbox

Aero runs sandboxed. The following capabilities are enabled
(Signing & Capabilities → App Sandbox):

- **Outgoing Connections (Client)** — required to reach APIs
- **User Selected File → Read/Write** — for multipart file uploads and
  Postman import/export

## Architecture

```
aero/
├── Models/        SwiftData models, enums, schema versions, persistence
├── Networking/    HTTPClient, RequestBuilder, OAuth2Service, stores
├── Utilities/     JSON, variable resolver, cURL + Postman converters
└── Views/         Sidebar, Editor, Response, Environments, History
```

- **Data** — SwiftData (`@Model`), with a versioned schema (`SchemaV1`) and a
  `SchemaMigrationPlan` for safe future migrations.
- **Networking** — plain `async/await` over `URLSession` (no Combine).
- **UI** — SwiftUI with a three-column `NavigationSplitView`.

## Roadmap

- Code generation (snippets for other languages)
- GraphQL and WebSocket support
- App icon, code signing, and notarization for distribution

## License

Not yet specified.
