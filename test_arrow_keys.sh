#!/bin/bash

# 测试方向键历史功能的脚本
echo "测试计算器的方向键历史功能"
echo "构建项目..."
swift build

if [ $? -eq 0 ]; then
    echo "✅ 构建成功"
    echo ""
    echo "运行程序进行手动测试:"
    echo "1. 输入一些计算表达式，如: 2+3, 5*7, sqrt(16)"
    echo "2. 使用↑↓方向键浏览历史命令"
    echo "3. 使用←→方向键移动光标"
    echo "4. 按 Ctrl+C 或输入 quit 退出"
    echo ""
    echo "启动计算器..."
    .build/debug/Cal
else
    echo "❌ 构建失败"
    exit 1
fi