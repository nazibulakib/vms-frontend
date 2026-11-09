# VMS Frontend (Vehicle Management System)

A responsive **Flutter Web** client for the Vehicle Management System (VMS). Vehicle data is loaded and changed through the separate Spring Boot REST API.

---

## Project boundaries

This system consists of **TWO completely independent projects**:
1. **`vms-frontend`**: Flutter Web application (presentation, UI state, routing, and HTTP client).
2. **`vms-backend`**: Java Spring Boot application (REST API, domain logic, JPA persistence, database).

### Current UI scope
- `vms-frontend` and `vms-backend` are independent projects with separate version control and dependencies.
- This frontend demonstrates Login → Vehicle List → Register/Edit with live vehicle records from the backend.
- Login uses the backend's `/auth/login` endpoint and stores only its short-lived Bearer token in tab-scoped session storage.
- Create, edit, delete, list, and read actions use the backend API.
- Passwords are sent only to the configured backend over HTTP and are not saved in browser storage.

---

## Directory structure

```
vms-frontend/
├── assets/                       # Static image and icon asset locations
├── lib/
│   ├── app/                      # Application shell and app configuration
│   ├── core/                     # API URL config, constants, and theme
│   ├── features/
│   │   ├── auth/                 # Login UI, API client, and tab session token
│   │   └── vehicles/             # Vehicle model, API/repository, list, and form
│   ├── shared/widgets/           # Shared loading and error widgets
│   └── main.dart                 # Application entry point
├── test/                         # Flutter widget tests
├── web/                          # Flutter Web entry point and manifest
├── analysis_options.yaml         # Linter rules
└── pubspec.yaml                  # Dependencies and Flutter metadata
```

---

## Getting started

### Prerequisites
- **Flutter SDK**: `>=3.24.0` (Dart `>=3.5.0`)
- Google Chrome or Chromium-based browser for web debugging

### Development
Start the Spring Boot backend and configure its database first. Then launch Flutter Web with the API base URL:
```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080/api/v1
```

The default API base URL is `http://localhost:8080/api/v1`. For a deployed frontend, pass the deployment API URL at build time:
```bash
flutter build web --release --dart-define=API_BASE_URL=https://your-api.example.com/api/v1
```

### Netlify deployment
The repository includes `netlify.toml`; its publish directory is `build/web`. The build script installs the Flutter revision pinned in `.metadata`, then builds the release app with `API_BASE_URL` from the Netlify build environment.

After deploying `vms-backend` to Render, set the Netlify build variable `API_BASE_URL` to the Render service's public HTTPS URL followed by `/api/v1`. This URL is compiled into the public Flutter bundle, so it must not contain credentials or other secrets. The script stops the deploy build if the variable is missing or is not an HTTPS `/api/v1` URL. Set the backend's `CORS_ALLOWED_ORIGIN_PATTERNS` to the Netlify site origin.

The current app keeps screen navigation inside Flutter and does not use path-based routes, so a Netlify SPA rewrite is not needed. If path-based deep links are introduced later, add a rewrite to `index.html` for those routes.

For browser requests, configure the backend's `CORS_ALLOWED_ORIGIN_PATTERNS` environment variable to include the frontend origin. Its local defaults allow `localhost` and `127.0.0.1` origins.

Create the local course login in the backend's ignored `.env` file using `VMS_AUTH_USERNAME` and `VMS_AUTH_PASSWORD`. See the backend `docs/auth-api.md` contract for details.

### Static analysis and tests
```bash
flutter analyze
flutter test
```

### Web build
```bash
flutter build web --release
```
The compiled static assets will be output to `build/web/`.
