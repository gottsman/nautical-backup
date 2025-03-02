#!/usr/bin/env bash

# Function to display help information
show_help() {
    cecho CYAN "Nautical Backup Developer Commands:"
    echo "  build          - Build Nautical container"
    echo "  run            - Run already built Nautical container"
    echo "  build-run      - Build and run Nautical container"
    echo ""
    echo "  unit-test      - Run Unit tests locally using mounts"
    echo "  integration    - Build and run integration tests locally"
    # echo "  build-test     - Build and run Nautical Testing container"
    echo "  test           - Run already built test Nautical container"
    # echo "  build-test-run - Build and run Nautical Testing container"
    echo ""
    # echo "  dev            - Run Nautical Development container"
    # echo "  build-dev      - Build and run Nautical Development container"
    echo "  api            - Run the Python API locally"
    echo "  pytest         - Pytest locally and capture coverage"
    echo "  format         - Format all python code with black"
    echo ""
    echo "  docs           - Run the Nautical documentation locally"
}

APP_HOME="/workspaces/nautical-backup"
export APP_HOME

# Function to execute commands
execute_command() {
    case $1 in
    build)
        clear
        cecho CYAN "Building Nautical..."
        cd $APP_HOME
        docker build -t nautical-backup -t nautical-backup:test --no-cache --progress=plain --build-arg='NAUTICAL_VERSION=testing' .
        ;;
    build-run)
        cd $APP_HOME
        nb build
        cecho CYAN "Running Nautical..."
        cd dev
        docker-compose up
        ;;
    run)
        cecho CYAN "Running Nautical..."
        cd $APP_HOME/dev
        docker-compose up
        ;;
    unit-test)
        cd $APP_HOME/tests
        docker compose run nautical-backup-test4 --exit-code-from nautical-backup-test4
        ;;
    unit-test-full)
        cd $APP_HOME
        nb build-test
        cd $APP_HOME/tests
        docker compose run nautical-backup-test4 --exit-code-from nautical-backup-test4
        ;;
    # dev)
    #     cd $APP_HOME/tests
    #     docker compose run nautical-backup-test5 --exit-code-from nautical-backup-test5
    #     ;;
    # build-test)
    #     clear
    #     cecho CYAN "Building Test Nautical container..."
    #     cd $APP_HOME
    #     docker build -t minituff/nautical-test --no-cache --progress=plain --build-arg='NAUTICAL_VERSION=testing' --build-arg='TEST_MODE=0' .
    #     ;;
    # build-dev)
    #     cd $APP_HOME
    #     nb build-test
    #     ;;
    integration)
        cecho CYAN "Running Nautical integration tests..."
        cd $APP_HOME
        
        ./tests/_validate_dockerfile.sh
        
        cd $APP_HOME/tests

        cecho CYAN "Running integration test #1"
        docker compose run nautical-backup-test1 --exit-code-from nautical-backup-test1
        
        cecho CYAN "Running integration test #2"
        docker compose run nautical-backup-test2 --exit-code-from nautical-backup-test2
        
        # Staging integration test #3
        rm -rf source destination config
        mkdir -p source/watchtower-test
        echo "This is a test file" >> source/watchtower-test/test-file.txt

        cecho CYAN "Running integration test #3"
        docker compose -f watchtower.yml up -d
        docker compose run nautical-backup-test3
        docker compose -f watchtower.yml down

        cecho CYAN "Validating Nautical completed a successful backup..."

        ./_validate_rsync.sh
        exit_code=$?

        if [ $exit_code -eq 0 ]; then
            cecho GREEN "All tests passed!"
        else
            cecho RED "One or more tests failed!"
        fi

        rm -rf source destination config

        ;;
    # build-test-run)
    #     nb build-test
    #     clear
    #     nb test
    #     ;;
    api)
        cd $APP_HOME
        cecho CYAN "Running Nautical API locally..."
        cecho GREEN "Viewable at http://localhost:8069/docs"
        python3 -m uvicorn app.api.main:app --host 0.0.0.0 --port 8069 --lifespan on --use-colors --reload
        ;;
    pytest)
        cd $APP_HOME
        clear
        cecho CYAN "Running Pytest..."
        python3 -m pytest --cov app --cov-report html --cov-report term
        ;;
    docs)
        cd $APP_HOME
        clear
        cecho CYAN "Running Nautical documentation locally..."
        python3 -m mkdocs serve
        ;;
    format)
        cd $APP_HOME
        clear
        cecho CYAN "Formatting Python code with Black..."
        python3 -m black --line-length 120 app tests
        ;;
    *)
        cecho RED "Unknown command: $1"
        show_help
        # echo "Use 'nb --help' for a list of available commands."
        ;;
    esac
}

# Check for --help argument
if [ -z "$1" ] || [ "$1" == "--help" ]; then
    show_help
else
    execute_command "$1"
fi
