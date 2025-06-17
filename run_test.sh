#!/bin/bash

# 计算器测试脚本

# 检查输入参数
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "使用方法: ./run_test.sh [表达式]"
    echo "如果提供表达式，将直接计算并显示结果"
    echo "如果不提供表达式，将打开交互式计算器"
    exit 0
fi

# 确保应用程序存在
if [ ! -f "Cal.app/Contents/MacOS/Cal" ]; then
    echo "错误: 找不到计算器应用程序，请先运行 ./build_app.sh"
    exit 1
fi

# 如果提供了表达式参数，直接计算
if [ -n "$1" ]; then
    echo "$1" | Cal.app/Contents/MacOS/Cal | grep -v "^>>>"
    exit 0
fi

# 否则，打开交互式计算器
Cal.app/Contents/MacOS/Cal 