#!/bin/bash

# Go Training App Test Runner
# Simple shell script for running tests by category

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_usage() {
    echo "Flutter Test Runner for Go Training App"
    echo ""
    echo "Usage: ./scripts/run_tests.sh [category|options]"
    echo ""
    echo "Categories:"
    echo "  models      - Data model tests (13 files)"
    echo "  services    - Service layer tests (6 files)"
    echo "  core        - Core business logic tests (5 files)"
    echo "  widgets     - UI widget tests (5 files)"
    echo "  themes      - Theme system tests (4 files)"
    echo "  integration - Integration tests (7 files)"
    echo ""
    echo "Options:"
    echo "  all         - Run all tests"
    echo "  parallel    - Run all categories in parallel"
    echo "  coverage    - Generate coverage report"
    echo "  help        - Show this help"
    echo ""
    echo "Examples:"
    echo "  ./scripts/run_tests.sh models"
    echo "  ./scripts/run_tests.sh all"
    echo "  ./scripts/run_tests.sh parallel"
}

run_category() {
    local category=$1
    local coverage_flag=$2

    echo -e "${BLUE}🧪 Running $category tests...${NC}"

    case $category in
        "models")
            flutter test $coverage_flag test/models/
            ;;
        "services")
            flutter test $coverage_flag test/services/
            ;;
        "core")
            flutter test $coverage_flag test/core/
            ;;
        "widgets")
            flutter test $coverage_flag test/widgets/
            ;;
        "themes")
            flutter test $coverage_flag test/themes/
            ;;
        "integration")
            flutter test $coverage_flag test/integration/
            ;;
        *)
            echo -e "${RED}❌ Unknown category: $category${NC}"
            exit 1
            ;;
    esac

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $category tests passed${NC}"
    else
        echo -e "${RED}❌ $category tests failed${NC}"
        exit 1
    fi
}

run_parallel() {
    local coverage_flag=$1
    echo -e "${BLUE}🚀 Running all test categories in parallel...${NC}"

    (run_category "models" "$coverage_flag") &
    (run_category "services" "$coverage_flag") &
    (run_category "core" "$coverage_flag") &
    (run_category "widgets" "$coverage_flag") &
    (run_category "themes" "$coverage_flag") &
    (run_category "integration" "$coverage_flag") &

    wait
    echo -e "${GREEN}✅ All parallel tests completed${NC}"
}

run_all() {
    local coverage_flag=$1
    echo -e "${BLUE}🧪 Running all test categories sequentially...${NC}"

    for category in "models" "services" "core" "widgets" "themes" "integration"; do
        run_category "$category" "$coverage_flag"
    done

    echo -e "${GREEN}✅ All tests completed successfully${NC}"
}

# Main script logic
if [ $# -eq 0 ] || [ "$1" = "help" ]; then
    print_usage
    exit 0
fi

# Check for coverage flag
coverage_flag=""
if [[ "$*" == *"coverage"* ]]; then
    coverage_flag="--coverage"
    echo -e "${YELLOW}📊 Coverage reporting enabled${NC}"
fi

case $1 in
    "all")
        run_all "$coverage_flag"
        ;;
    "parallel")
        run_parallel "$coverage_flag"
        ;;
    "models"|"services"|"core"|"widgets"|"themes"|"integration")
        run_category "$1" "$coverage_flag"
        ;;
    *)
        echo -e "${RED}❌ Invalid option: $1${NC}"
        print_usage
        exit 1
        ;;
esac