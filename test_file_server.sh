#!/bin/bash
# Test script to check file server connection
# Usage: ./test_file_server.sh [username] [password]

SERVER_URL="http://192.168.0.10:8080/files/"
USERNAME="${1:-}"
PASSWORD="${2:-}"

echo "Testing file server connection..."
echo "URL: $SERVER_URL"
echo ""

if [ -z "$USERNAME" ] || [ -z "$PASSWORD" ]; then
    echo "Testing without authentication..."
    curl -v "$SERVER_URL" 2>&1
else
    echo "Testing with authentication..."
    echo "Username: $USERNAME"
    curl -u "$USERNAME:$PASSWORD" -v "$SERVER_URL" 2>&1
fi

echo ""
echo "---"
echo "To test with credentials, run:"
echo "./test_file_server.sh your_username your_password"

