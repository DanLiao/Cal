#!/bin/bash

# 定义变量
APP_NAME="Cal"
APP_BUNDLE="$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

# 确保目录存在
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# 编译Swift包
echo "编译 Swift 包..."
swift build -c release

# 检查构建是否成功
if [ $? -ne 0 ]; then
    echo "编译失败，请检查错误信息"
    exit 1
fi

# 复制可执行文件
cp .build/release/Cal "$MACOS_DIR/$APP_NAME"

# 检查复制是否成功
if [ $? -ne 0 ]; then
    echo "文件复制失败，请检查错误信息"
    exit 1
fi

# 设置可执行权限
chmod +x "$MACOS_DIR/$APP_NAME"

# 创建启动脚本
cat > "$MACOS_DIR/launch.sh" << EOL
#!/bin/bash
# 设置环境变量
export APP_PATH="\$0"
# 启动应用程序在终端中
open -a Terminal.app "\$(dirname "\$0")/$APP_NAME"
EOL

chmod +x "$MACOS_DIR/launch.sh"

# 设置可执行文件
cp Info.plist "$CONTENTS_DIR/"

# 修改Info.plist，指向launch.sh
/usr/libexec/PlistBuddy -c "Set :CFBundleExecutable launch.sh" "$CONTENTS_DIR/Info.plist"

# 复制图标文件
if [ -f "calculator.icns" ]; then
    cp calculator.icns "$RESOURCES_DIR/"
else
    echo "警告：找不到图标文件 calculator.icns"
fi

# 复制本地化字符串
mkdir -p "$RESOURCES_DIR/zh_CN.lproj"
cp InfoPlist.strings "$RESOURCES_DIR/zh_CN.lproj/"

# 完成
echo "应用程序构建完成：$APP_BUNDLE"

# 创建record目录（如果不存在）
mkdir -p "record" 