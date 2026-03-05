# Requirement
- Node version: 22 (`nvm install 22 && nvm use 22`)

# Before commit (Important!!!!)
- Run `npm run export`

# CMS Service

This service manages content and configurations for the Cms application, handling various data collections including products, stores, and master data.

## Project Structure

```
.
├── Dockerfile              # Container configuration
├── index.js               # Main application entry point
├── snapshot.yaml          # Base snapshot configuration
├── merged-snapshot.yaml   # Combined snapshot configuration
├── extensions/            # Service extensions
├── scripts/
│   ├── apply.js          # Script to apply configurations
│   ├── merge-snapshot.js # Script to merge snapshot files
│   └── split-snapshot.js # Script to split snapshot files
└── snapshot/             # Configuration snapshots
    ├── relations.yaml    # Relationship definitions
    ├── collections/      # Collection configurations
    └── fields/           # Field definitions
```

## Features

-   Centralized content management system
-   Support for multiple data collections (products, stores, cities, countries)
-   Configuration management with snapshot system
-   Relationship management between different data entities

## Getting Started

### Prerequisites

-   Node.js (22 is preferred)
-   Docker & Docker Compose
-   npm or yarn package manager

### Quick Start with run.sh Script

The easiest way to start the project is using the `run.sh` script:

```bash
# Make script executable (first time only)
chmod +x run.sh

# Local development mode
./run.sh local start

# Docker mode
./run.sh docker start

# Show all available commands
./run.sh
```

**Available commands:**

```bash
# LOCAL MODE (requires Node.js 22)
./run.sh local start      # Start local development
./run.sh local stop       # Stop services
./run.sh local build      # Build extensions
./run.sh local status     # Show service status
./run.sh local clean      # Clean up everything
./run.sh local test       # Test API endpoints

# DOCKER MODE
./run.sh docker start     # Start all services in Docker
./run.sh docker stop      # Stop Docker services
./run.sh docker restart   # Restart Docker services
./run.sh docker build     # Build Docker image
./run.sh docker logs      # Show logs (Ctrl+C to exit)
./run.sh docker status    # Show service status
./run.sh docker clean     # Remove containers and volumes
./run.sh docker test      # Test API endpoints
```

### Manual Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd <project-directory>
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Setup Environment Variables**
   
   Copy the sample environment file and configure it:
   ```bash
   cp .env.sample .env
   ```
   
   Review and update the `.env` file if needed. Default values work for local development.

### Running the Service

#### Option 1: Development Mode (Recommended for Development)

Run Directus locally with Docker services for database and storage:

1. **Start Database & Storage Services**
   
   Start Postgres and MinIO using Docker Compose:
   ```bash
   docker-compose up -d postgres minio
   ```
   
   Verify services are running:
   ```bash
   docker-compose ps
   ```

2. **Initialize and Start Directus**
   
   Bootstrap the database and start the development server:
   ```bash
   npx directus bootstrap

   npm run dev
   ```
   This will:
   - Build extensions
   
   - Bootstrap the database (create tables, admin user)
   - Apply schema snapshots
   - Start the Directus server on http://localhost:8055

3. **Access the Application**
   - Admin Panel: http://localhost:8055
   - MinIO Console: http://localhost:9001
   - Default credentials (from `.env`):
     - Admin: admin@example.com / admin
     - MinIO: minioadmin / minioadmin

#### Option 2: Full Docker Mode

Run everything in Docker containers:

1. **Start All Services**
   ```bash
   docker-compose up -d
   ```
   
   This will:
   - Build the Docker image (including building all extensions)
   - Start PostgreSQL database
   - Start MinIO object storage
   - Start Directus CMS application

2. **Check Logs**
   ```bash
   docker-compose logs -f cms-service
   ```

3. **Access the Application**
   - Admin Panel: http://localhost:8055
   - MinIO Console: http://localhost:9001

**Docker Build Process:**

The Dockerfile uses multi-stage build:

1. **Build Stage:**
   - Install all dependencies (including devDependencies)
   - Build all extensions in `extensions/` folder
   - Each extension is built with `npm run build` (creates `dist/` folder)

2. **Runtime Stage:**
   - Install only production dependencies
   - Copy built extensions (with `dist/` folders) from build stage
   - Copy application code
   - Start Directus

**Rebuild Docker image after adding/modifying extensions:**
```bash
docker-compose build cms-service
docker-compose up -d cms-service
```

### Stopping Services

Stop all Docker services:
```bash
docker-compose down
```

Stop and remove volumes (⚠️ this will delete all data):
```bash
docker-compose down -v
```

## Troubleshooting

### Extensions not loading

If extensions are not working after Docker build:

1. **Check if extension is loaded:**
   ```bash
   docker-compose logs cms-service | grep "Loaded extensions"
   ```
   Should show: `Loaded extensions: directus-extension-hello-world`

2. **Verify extension is built:**
   ```bash
   docker-compose exec cms-service ls -la /app/extensions/directus-extension-hello-world/dist/
   ```
   Should show `index.js` file

3. **Rebuild Docker image:**
   ```bash
   docker-compose build cms-service
   docker-compose up -d cms-service
   ```

4. **Check extension logs:**
   ```bash
   docker-compose logs -f cms-service
   ```

### Extension returns 404

- Ensure extension ID in `package.json` matches the endpoint path
- Check that `dist/index.js` exists (extension must be built)
- Verify the export format in `src/index.js` uses ES6 modules with `id` and `handler`

### Database connection issues

```bash
# Check if postgres is running
docker-compose ps postgres

# Check postgres logs
docker-compose logs postgres

# Restart postgres
docker-compose restart postgres
```

### MinIO connection issues

```bash
# Check if minio is running
docker-compose ps minio

# Access MinIO console
open http://localhost:9001
# Login: minioadmin / minioadmin
```

## Schema Management

### Export & Import Workflow

Directus schema (collections, fields, relations) được quản lý thông qua snapshot files để đảm bảo đồng bộ giữa các môi trường và version control.

#### Export Schema (npm run export)

**Khi nào cần chạy:**
- Sau khi thay đổi schema trong Directus Admin UI (tạo/sửa collections, fields, relations)
- Trước khi commit code lên Git
- Khi muốn backup cấu hình hiện tại

**Lệnh:**
```bash
npm run export
```

**Quá trình thực hiện:**
1. Xóa thư mục `snapshot/` cũ
2. Export toàn bộ schema từ database ra file `snapshot.yaml`
3. Tự động split file lớn thành các file nhỏ trong `snapshot/`:
   - `snapshot/collections/` - Định nghĩa các collections
   - `snapshot/fields/` - Định nghĩa các fields
   - `snapshot/relations.yaml` - Định nghĩa relationships

**Lưu ý quan trọng:**
- ⚠️ **LUÔN chạy lệnh này trước khi commit** để đảm bảo schema trong code đồng bộ với database
- File `snapshot.yaml` được tạo ra nhưng không cần commit (đã có trong `.gitignore`)
- Chỉ commit các file trong thư mục `snapshot/`

#### Import Schema (npm run import)

**Khi nào cần chạy:**
- Sau khi pull code mới từ Git có thay đổi schema
- Khi setup môi trường mới (dev, staging, production)
- Khi muốn đồng bộ schema từ code vào database

**Lệnh:**
```bash
npm run import
```

**Quá trình thực hiện:**
1. Xóa file `merged-snapshot.yaml` cũ (nếu có)
2. Merge tất cả files trong `snapshot/` thành một file `merged-snapshot.yaml`
3. Apply schema từ `merged-snapshot.yaml` vào database

**Lưu ý:**
- Lệnh này được tự động chạy khi start app với `npm run bootstrap-dev` hoặc `npm run start:prod`
- Nếu có conflict, Directus sẽ báo lỗi và cần resolve manually

### Workflow Thực Tế

**Khi phát triển feature mới:**
```bash
# 1. Thay đổi schema trong Directus Admin UI
# 2. Export schema
npm run export

# 3. Commit changes
git add snapshot/
git commit -m "feat: add new collection for products"
git push
```

**Khi pull code từ team member:**
```bash
# 1. Pull code
git pull

# 2. Import schema changes vào database
npm run import

# 3. Restart Directus nếu đang chạy
npm run dev
```

**Khi deploy lên production:**
```bash
# Schema sẽ tự động được import khi start
npm run start:prod
```

## More information

### Scripts

-   `scripts/apply.js`: Applies configuration changes
-   `scripts/merge-snapshot.js`: Merges multiple snapshot files into one
-   `scripts/split-snapshot.js`: Splits large snapshot file into organized structure
-   `scripts/build-extensions.js`: Builds all extensions in the extensions folder
-   `scripts/clean-extensions.js`: Cleans built extension files


### How to write a Extension

All Extensions stored in folder: `extensions`

**Create new extension:**
```bash
cd extensions
npx create-directus-extension@latest
```

**Naming convention:**
- Recommend naming: Should start with `directus-extension-[your_scope_business]`
- Example: `directus-extension-hello-world`, `directus-extension-voucher-api`

**Build extensions:**

For local development:
```bash
# Build all extensions
npm run build-extensions

# Clean built files
npm run clean-extensions

# Rebuild all extensions
npm run rebuild-extensions
```

For individual extension:
```bash
cd extensions/directus-extension-hello-world
npm install
npm run build
```

**Extension structure:**
```
extensions/
└── directus-extension-hello-world/
    ├── package.json          # Extension config with build scripts
    ├── src/
    │   └── index.js         # Source code
    └── dist/                # Built files (auto-generated)
        └── index.js
```

**Important notes:**
- Extensions must be built before Directus can load them
- The `dist/` folder is auto-generated and should not be edited manually
- When building Docker image, extensions are automatically built in the build stage
- Built extensions are copied to the runtime container

