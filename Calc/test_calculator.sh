#!/bin/bash

# 测试基本运算
echo "2+2" | ./SwiftCalculator
echo "10-5" | ./SwiftCalculator
echo "4*3" | ./SwiftCalculator
echo "15/3" | ./SwiftCalculator

# 测试函数
echo "sqrt(16)" | ./SwiftCalculator
echo "pow(2,3)" | ./SwiftCalculator
echo "sin(0)" | ./SwiftCalculator
echo "cos(0)" | ./SwiftCalculator

# 测试复杂表达式
echo "2+2*3" | ./SwiftCalculator
echo "(2+2)*3" | ./SwiftCalculator
echo "sqrt(16)+pow(2,3)" | ./SwiftCalculator
