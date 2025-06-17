#!/bin/bash

# 测试计算器功能的简单脚本

echo "开始测试Swift计算器..."
echo

# 检查Cal.app是否存在
if [ ! -d "Cal.app" ]; then
    echo "错误：找不到Cal.app，请先构建应用程序"
    exit 1
fi

# 检查Cal可执行文件是否存在
if [ ! -f "Cal.app/Contents/MacOS/Cal" ]; then
    echo "错误：找不到Cal可执行文件"
    exit 1
fi

# 创建临时输入文件
cat > test_input.txt << EOL
1+2
5-3
4*5
10/2
sqrt(16)
pow(2,3)
log(10)
q
EOL

echo "测试命令:"
cat test_input.txt
echo

# 运行计算器并提供输入
echo "执行计算器并测试基本计算..."
(cat test_input.txt | Cal.app/Contents/MacOS/Cal > test_output.txt) || true

# 检查输出
echo "测试完成！"
echo "结果摘要:"
grep -E '^[0-9]' test_output.txt

# 清理临时文件
echo
echo "清理临时文件..."
rm test_input.txt
rm test_output.txt

echo
echo "测试完成！您可以现在直接运行Cal.app应用程序。" 