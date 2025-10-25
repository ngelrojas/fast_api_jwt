#!/bin/bash
# Terragrunt Deployment Script for Fast API JWT Project
# Usage: ./deploy.sh [init|plan|apply|destroy|output]

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if terragrunt is installed
if ! command -v terragrunt &> /dev/null; then
    print_error "Terragrunt is not installed. Please install it first:"
    echo "  brew install terragrunt"
    exit 1
fi

# Check if .env file exists
if [ ! -f ".env" ]; then
    print_warning ".env file not found. Creating from .env.example..."
    if [ -f ".env.example" ]; then
        cp .env.example .env
        print_info "Please edit .env with your actual values before deploying"
        exit 1
    else
        print_error ".env.example not found"
        exit 1
    fi
fi

# Load environment variables
print_info "Loading environment variables from .env..."
export $(cat .env | grep -v '^#' | xargs)

# Change to production directory
PRODUCTION_DIR="terraform/production"
if [ ! -d "$PRODUCTION_DIR" ]; then
    print_error "Production directory not found: $PRODUCTION_DIR"
    exit 1
fi

cd "$PRODUCTION_DIR"
print_info "Working directory: $(pwd)"

# Get command from argument
COMMAND=${1:-plan}

case $COMMAND in
    init)
        print_info "Initializing all Terragrunt modules..."
        terragrunt run-all init
        print_info "✅ Initialization complete!"
        ;;

    plan)
        print_info "Planning all Terragrunt modules..."
        terragrunt run-all plan
        print_info "✅ Plan complete!"
        ;;

    apply)
        print_warning "This will apply changes to your AWS infrastructure!"
        read -p "Are you sure you want to continue? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            print_info "Applying all Terragrunt modules..."
            terragrunt run-all apply
            print_info "✅ Apply complete!"
        else
            print_info "Deployment cancelled."
            exit 0
        fi
        ;;

    destroy)
        print_error "This will DESTROY all your infrastructure!"
        read -p "Are you ABSOLUTELY sure? (type 'destroy' to confirm): " confirm
        if [ "$confirm" = "destroy" ]; then
            print_warning "Destroying all Terragrunt modules..."
            terragrunt run-all destroy
            print_info "✅ Destroy complete!"
        else
            print_info "Destroy cancelled."
            exit 0
        fi
        ;;

    output)
        print_info "Getting outputs from all modules..."
        terragrunt run-all output
        ;;

    validate)
        print_info "Validating all Terragrunt configurations..."
        terragrunt run-all validate
        print_info "✅ Validation complete!"
        ;;

    clean)
        print_info "Cleaning Terragrunt cache..."
        find . -type d -name ".terragrunt-cache" -exec rm -rf {} + 2>/dev/null || true
        find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
        print_info "✅ Cache cleaned!"
        ;;

    graph)
        print_info "Generating dependency graph..."
        terragrunt graph-dependencies | dot -Tpng > dependency-graph.png
        print_info "✅ Graph saved to dependency-graph.png"
        ;;

    *)
        print_error "Unknown command: $COMMAND"
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Available commands:"
        echo "  init      - Initialize all modules"
        echo "  plan      - Plan all modules"
        echo "  apply     - Apply all modules (deploys infrastructure)"
        echo "  destroy   - Destroy all modules"
        echo "  output    - Show outputs from all modules"
        echo "  validate  - Validate all configurations"
        echo "  clean     - Clean Terragrunt cache"
        echo "  graph     - Generate dependency graph (requires graphviz)"
        exit 1
        ;;
esac

print_info "Done! 🎉"
