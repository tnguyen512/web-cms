# Directus Extension - Hello World

Demo custom API endpoint extension for Directus.

## Features

This extension provides simple REST API endpoints to demonstrate how to create custom endpoints in Directus.

## Endpoints

### 1. Basic Hello World
```
GET /hello-world
```

**Response:**
```json
{
  "message": "Hello World!",
  "timestamp": "2024-01-01T00:00:00.000Z",
  "method": "GET"
}
```

### 2. Personalized Greeting
```
GET /hello-world/greet/:name
```

**Example:**
```
GET /hello-world/greet/John
```

**Response:**
```json
{
  "message": "Hello, John!",
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

### 3. Extension Info
```
GET /hello-world/info
```

**Response:**
```json
{
  "extension": "directus-extension-hello-world",
  "version": "1.0.0",
  "description": "Demo custom API endpoint",
  "endpoints": [
    "GET /hello-world",
    "GET /hello-world/greet/:name",
    "GET /hello-world/info"
  ]
}
```

## Installation

This extension is already included in the project. After starting Directus, the endpoints will be automatically available.

## Testing

After starting Directus (either locally or via Docker), test the endpoints:

```bash
# Basic hello world
curl http://localhost:8055/hello-world
# Response: {"message":"Hello World!","timestamp":"2026-03-05T08:58:32.409Z","method":"GET"}

# Personalized greeting
curl http://localhost:8055/hello-world/greet/YourName
# Response: {"message":"Hello, YourName!","timestamp":"2026-03-05T08:58:48.652Z"}

# Extension info
curl http://localhost:8055/hello-world/info
# Response: {"extension":"directus-extension-hello-world","version":"1.0.0",...}
```

Or open in browser:
- http://localhost:8055/hello-world
- http://localhost:8055/hello-world/greet/YourName
- http://localhost:8055/hello-world/info

## Development

To modify this extension:

1. Edit files in `src/index.js`
2. Restart Directus to see changes:
   ```bash
   npm run dev
   ```

## Structure

```
directus-extension-hello-world/
├── package.json          # Extension configuration
├── src/
│   └── index.js         # Main endpoint logic
└── README.md            # This file
```
