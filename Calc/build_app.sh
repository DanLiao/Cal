#!/bin/bash

# 编译 Swift 文件
swiftc Cal.swift -o SwiftCalculator

# 创建应用程序包结构
app_name="SwiftCalculator.app"
app_contents="$app_name/Contents"
app_macos="$app_contents/MacOS"
app_resources="$app_contents/Resources"

# 创建目录结构
mkdir -p "$app_macos"
mkdir -p "$app_resources"

# 复制可执行文件
cp SwiftCalculator "$app_macos/"

# 复制资源文件
cp calculator.icns "$app_resources/"
cp Info.plist "$app_contents/"
cp InfoPlist.strings "$app_resources/"

# 设置权限
chmod +x "$app_macos/SwiftCalculator"

echo "应用程序包已创建：$app_name"
