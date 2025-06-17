#!/bin/bash

echo "Testing Swift Calculator v2.0"
echo "=============================="

# Build the calculator
echo "Building calculator..."
swift build

if [ $? -ne 0 ]; then
    echo "Build failed!"
    exit 1
fi

echo "Build successful!"
echo ""

# Test basic operations
echo "Testing basic operations..."

# Test 1: Basic arithmetic
echo "Test 1: Basic arithmetic (2 + 3 * 4)"
echo "2 + 3 * 4" | .build/debug/Cal

echo ""

# Test 2: Mathematical functions
echo "Test 2: Mathematical functions (sqrt(16))"
echo -e "sqrt(16)\nquit" | .build/debug/Cal

echo ""

# Test 3: Variables
echo "Test 3: Variables (let x = 5, then x * 2)"
echo -e "let x = 5\nx * 2\nquit" | .build/debug/Cal

echo ""

# Test 4: Scientific notation
echo "Test 4: Scientific notation (1.5e3)"
echo -e "1.5e3\nquit" | .build/debug/Cal

echo ""

# Test 5: Constants
echo "Test 5: Constants (pi)"
echo -e "pi\nquit" | .build/debug/Cal

echo ""

# Test 6: Error handling
echo "Test 6: Error handling (invalid expression: 2++3)"
echo -e "2++3\nquit" | .build/debug/Cal

echo ""
echo "All tests completed!"