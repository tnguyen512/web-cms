#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored message
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_header() {
    echo ""
    print_message "$BLUE" "=========================================="
    print_message "$BLUE" "$1"
    print_message "$BLUE" "=========================================="
    echo ""
}

print_success() {
    print_message "$GREEN" "✓ $1"
}

print_error() {
    print_message "$RED" "✗ $1"
}

print_warning() {
    print_message "$YELLOW" "⚠ $1"
}

# Show usage
show_usage() {
    cat << EOF
Usage: ./run.sh [MODE] [COMMAND]

MODES:
  local     Run Directus locally (requires Node.js 22)
  docker    Run everything in Docker containers

COMMANDS:
  start     Start services
  stop      Stop services
  restart   Restart services
  build     Build extensions (local) or Docker image (docker)
  logs      Show logs
  clean     Clean up (stop and remove volumes)
  status    Show service status
  test      Test API endpoints

EXAMPLES:
  ./run.sh local start      # Start local development
  ./run.sh docker start     # Start with Docker
  ./run.sh local build      # Build extensions locally
  ./run.sh docker build     # Build Docker image
  ./run.sh docker logs      # Show Docker logs
  ./run.sh local test       # Test API endpoints

EOF
}

# Check if Node.js is installed
check_node() {
    if ! command -v node &> /dev/null; then
        print_error "Node.js is not installed"
        print_warning "Please install Node.js 22: nvm install 22 && nvm use 22"
        exit 1
    fi
    
    local node_version=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$node_version" -lt 22 ]; then
        print_warning "Node.js version is $node_version, recommended version is 22"
        print_warning "Run: nvm install 22 && nvm use 22"
    fi
}

# Check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed"
        print_warning "Please install Docker: https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed"
        exit 1
    fi
}

# Check if .env file exists
check_env() {
    if [ ! -f .env ]; then
        print_warning ".env file not found, creating from .env.sample"
        cp .env.sample .env
        print_success "Created .env file"
    fi
}

# Test API endpoints
test_endpoints() {
    print_header "Testing API Endpoints"
    
    local base_url="http://localhost:8055"
    
    print_message "$YELLOW" "Waiting for server to be ready..."
    sleep 3
    
    # Test hello-world endpoint
    print_message "$YELLOW" "\n1. Testing GET /hello-world"
    if curl -s -f "$base_url/hello-world" > /dev/null; then
        local response=$(curl -s "$base_url/hello-world")
        print_success "Response: $response"
    else
        print_error "Failed to connect to $base_url/hello-world"
    fi
    
    # Test greet endpoint
    print_message "$YELLOW" "\n2. Testing GET /hello-world/greet/TestUser"
    if curl -s -f "$base_url/hello-world/greet/TestUser" > /dev/null; then
        local response=$(curl -s "$base_url/hello-world/greet/TestUser")
        print_success "Response: $response"
    else
        print_error "Failed to connect to $base_url/hello-world/greet/TestUser"
    fi
    
    # Test info endpoint
    print_message "$YELLOW" "\n3. Testing GET /hello-world/info"
    if curl -s -f "$base_url/hello-world/info" > /dev/null; then
        local response=$(curl -s "$base_url/hello-world/info")
        print_success "Response: $response"
    else
        print_error "Failed to connect to $base_url/hello-world/info"
    fi
    
    echo ""
    print_success "All endpoints tested!"
}

###########################################
# LOCAL MODE FUNCTIONS
###########################################

local_start() {
    print_header "Starting Local Development"
    
    check_node
    check_env
    
    # Start Docker services (postgres & minio)
    print_message "$YELLOW" "Starting Postgres and MinIO..."
    docker-compose up -d postgres minio
    
    # Wait for services
    print_message "$YELLOW" "Waiting for services to be ready..."
    sleep 5
    
    # Check if node_modules exists
    if [ ! -d "node_modules" ]; then
        print_message "$YELLOW" "Installing dependencies..."
        npm install
    fi
    
    # Build extensions
    print_message "$YELLOW" "Building extensions..."
    npm run build-extensions || print_warning "No extensions to build or build failed"
    
    # Bootstrap and start
    print_message "$YELLOW" "Bootstrapping Directus..."
    npx directus bootstrap || print_warning "Bootstrap already completed"
    
    print_message "$YELLOW" "Importing schema..."
    npm run import || print_warning "Schema already imported"
    
    print_success "Services started!"
    print_message "$GREEN" "\nDirectus Admin: http://localhost:8055"
    print_message "$GREEN" "MinIO Console: http://localhost:9001"
    
    print_message "$YELLOW" "\nStarting Directus server..."
    print_message "$YELLOW" "Press Ctrl+C to stop\n"
    
    npm run dev
}

local_stop() {
    print_header "Stopping Local Services"
    
    print_message "$YELLOW" "Stopping Postgres and MinIO..."
    docker-compose stop postgres minio
    
    print_success "Services stopped!"
}

local_build() {
    print_header "Building Extensions Locally"
    
    check_node
    
    print_message "$YELLOW" "Cleaning old builds..."
    npm run clean-extensions || true
    
    print_message "$YELLOW" "Building extensions..."
    npm run build-extensions
    
    print_success "Extensions built successfully!"
}

local_status() {
    print_header "Local Services Status"
    
    docker-compose ps postgres minio
}

local_clean() {
    print_header "Cleaning Local Environment"
    
    print_message "$YELLOW" "Stopping services..."
    docker-compose down -v
    
    print_message "$YELLOW" "Cleaning extensions..."
    npm run clean-extensions || true
    
    print_message "$YELLOW" "Removing merged snapshot..."
    rm -f merged-snapshot.yaml
    
    print_success "Cleanup completed!"
}

###########################################
# DOCKER MODE FUNCTIONS
###########################################

docker_start() {
    print_header "Starting Docker Services"
    
    check_docker
    check_env
    
    print_message "$YELLOW" "Starting all services..."
    docker-compose up -d
    
    print_message "$YELLOW" "Waiting for services to be ready..."
    sleep 10
    
    print_success "Services started!"
    print_message "$GREEN" "\nDirectus Admin: http://localhost:8055"
    print_message "$GREEN" "MinIO Console: http://localhost:9001"
    
    print_message "$YELLOW" "\nTo view logs, run: ./run.sh docker logs"
}

docker_stop() {
    print_header "Stopping Docker Services"
    
    docker-compose stop
    
    print_success "Services stopped!"
}

docker_restart() {
    print_header "Restarting Docker Services"
    
    docker-compose restart
    
    print_success "Services restarted!"
}

docker_build() {
    print_header "Building Docker Image"
    
    check_docker
    
    print_message "$YELLOW" "Building cms-service image..."
    docker-compose build cms-service
    
    print_success "Docker image built successfully!"
    print_message "$YELLOW" "\nTo start services, run: ./run.sh docker start"
}

docker_logs() {
    print_header "Docker Logs"
    
    if [ -z "$3" ]; then
        print_message "$YELLOW" "Showing logs for all services (Ctrl+C to exit)..."
        docker-compose logs -f
    else
        print_message "$YELLOW" "Showing logs for $3 (Ctrl+C to exit)..."
        docker-compose logs -f "$3"
    fi
}

docker_status() {
    print_header "Docker Services Status"
    
    docker-compose ps
}

docker_clean() {
    print_header "Cleaning Docker Environment"
    
    print_warning "This will remove all containers and volumes (all data will be lost)"
    read -p "Are you sure? (y/N) " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_message "$YELLOW" "Stopping and removing containers..."
        docker-compose down -v
        
        print_message "$YELLOW" "Removing Docker image..."
        docker rmi cms-service-cms-service 2>/dev/null || true
        
        print_success "Cleanup completed!"
    else
        print_warning "Cleanup cancelled"
    fi
}

###########################################
# MAIN SCRIPT
###########################################

MODE=$1
COMMAND=$2

if [ -z "$MODE" ] || [ -z "$COMMAND" ]; then
    show_usage
    exit 1
fi

case "$MODE" in
    local)
        case "$COMMAND" in
            start)
                local_start
                ;;
            stop)
                local_stop
                ;;
            restart)
                local_stop
                sleep 2
                local_start
                ;;
            build)
                local_build
                ;;
            status)
                local_status
                ;;
            clean)
                local_clean
                ;;
            test)
                test_endpoints
                ;;
            *)
                print_error "Unknown command: $COMMAND"
                show_usage
                exit 1
                ;;
        esac
        ;;
    docker)
        case "$COMMAND" in
            start)
                docker_start
                ;;
            stop)
                docker_stop
                ;;
            restart)
                docker_restart
                ;;
            build)
                docker_build
                ;;
            logs)
                docker_logs "$@"
                ;;
            status)
                docker_status
                ;;
            clean)
                docker_clean
                ;;
            test)
                test_endpoints
                ;;
            *)
                print_error "Unknown command: $COMMAND"
                show_usage
                exit 1
                ;;
        esac
        ;;
    *)
        print_error "Unknown mode: $MODE"
        show_usage
        exit 1
        ;;
esac
