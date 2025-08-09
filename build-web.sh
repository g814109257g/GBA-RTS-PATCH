#!/bin/bash

# Web版构建脚本 - 生成payload数据并更新web-patcher

set -e

echo "正在构建GBA RTS Patcher Web版..."

# 确保我们在项目根目录
cd "$(dirname "$0")"

# 1. 构建payload
echo "1. 构建payload..."
if ! ./build.sh; then
    echo "错误: payload构建失败"
    exit 1
fi

# 2. 检查生成的文件
if [ ! -f "payload_bin.c" ]; then
    echo "错误: payload_bin.c 未生成"
    exit 1
fi

echo "2. 转换payload数据为JavaScript格式..."

# 3. 从payload_bin.c提取数据并转换为JavaScript
python3 << 'EOF'
import re
import sys

try:
    # 读取payload_bin.c
    with open('payload_bin.c', 'r') as f:
        content = f.read()
    
    # 提取数组数据
    array_match = re.search(r'unsigned char payload_bin\[\] = \{([^}]+)\};', content)
    if not array_match:
        print("错误: 无法在payload_bin.c中找到payload_bin数组")
        sys.exit(1)
    
    array_data = array_match.group(1)
    
    # 提取长度
    len_match = re.search(r'unsigned int payload_bin_len = (\d+);', content)
    if not len_match:
        print("错误: 无法在payload_bin.c中找到payload_bin_len")
        sys.exit(1)
    
    payload_len = int(len_match.group(1))
    
    # 解析数组数据
    hex_values = re.findall(r'0x[0-9a-fA-F]+', array_data)
    
    if len(hex_values) != payload_len:
        print(f"警告: 数组长度不匹配 (expected: {payload_len}, found: {len(hex_values)})")
    
    # 生成JavaScript数组
    js_array = "[\n"
    for i, hex_val in enumerate(hex_values):
        if i > 0:
            js_array += ","
        if i % 16 == 0:
            js_array += "\n    "
        else:
            js_array += " "
        js_array += hex_val
    js_array += "\n]"
    
    # 生成新的payload-data.js
    js_content = f'''// Payload数据 - 从payload_bin.c自动生成
// 此文件由build-web.sh自动生成，请勿手动编辑

const PAYLOAD_DATA = new Uint8Array({js_array});

// PayloadHeader结构体偏移定义（对应payload_header.h）
const PAYLOAD_HEADER_OFFSETS = {{
    original_entrypoint: 0,        // 游戏原始入口点地址
    ctrl_flag: 4,                  // 控制标志  
    rts_size: 8,                   // RTS(包含存档)大小
    save_size: 12,                 // 存档大小
    wbuf_size: 16,                 // 写缓冲区大小
    patched_entrypoint_addr: 20    // 补丁入口点函数地址
}};

// 获取payload数据
function getPayloadData() {{
    return PAYLOAD_DATA;
}}

// 获取payload长度
function getPayloadLength() {{
    return PAYLOAD_DATA.length;
}}

// 更新payload header中的字段
function updatePayloadHeader(payloadData, originalEntrypoint, rtsSize, saveSize, wbufSize) {{
    const view = new DataView(payloadData.buffer);
    
    // 更新original_entrypoint
    view.setUint32(PAYLOAD_HEADER_OFFSETS.original_entrypoint, originalEntrypoint, true);
    
    // 更新rts_size（保留空间大小：448KB + save_size，并按扇区对齐）
    view.setUint32(PAYLOAD_HEADER_OFFSETS.rts_size, rtsSize, true);
    
    // 更新save_size（存档大小）
    view.setUint32(PAYLOAD_HEADER_OFFSETS.save_size, saveSize, true);
    
    // 更新wbuf_size（写缓冲区大小）
    view.setUint32(PAYLOAD_HEADER_OFFSETS.wbuf_size, wbufSize, true);
    
    return payloadData;
}}

console.log('Payload数据已加载，大小:', PAYLOAD_DATA.length, '字节');
'''
    
    # 写入文件
    with open('web-patcher/payload-data.js', 'w') as f:
        f.write(js_content)
    
    print(f"✓ payload-data.js 已生成，包含 {payload_len} 字节的payload数据")
    
except Exception as e:
    print(f"错误: {e}")
    sys.exit(1)
EOF

if [ $? -ne 0 ]; then
    echo "错误: JavaScript数据生成失败"
    exit 1
fi

# 4. 创建web目录的README
echo "3. 创建使用说明..."
cat > web-patcher/README.md << 'EOF'
# GBA RTS Patcher - Web版

这是GBA RTS Patcher的Web版本，可以在浏览器中直接使用，无需安装任何软件。

## 使用方法

1. 用现代浏览器打开 `index.html`
2. 选择要打补丁的 `.gba` ROM文件
3. （可选）选择要嵌入的 `.rts` 存档文件
4. 配置写缓冲区大小和扇区大小
5. 点击"开始打补丁"
6. 等待处理完成后下载补丁后的ROM文件

## 功能特性

- ✅ 纯前端实现，无需服务器
- ✅ 自动检测存档类型（SRAM/EEPROM/Flash）
- ✅ 支持嵌入RTS存档文件
- ✅ 实时进度显示和日志输出
- ✅ 响应式设计，支持移动设备
- ✅ 完整的错误处理和验证

## 支持的操作

- **RTS存档**: L + R + Start
- **RTS读档**: A + B + Select

## 技术说明

此Web版本将原C语言patcher的所有逻辑移植到了JavaScript中，包括：
- ROM验证和对齐
- 存档函数签名检测
- IRQ处理器地址替换
- Payload注入和配置
- ROM入口点修改

## 浏览器兼容性

需要支持以下特性的现代浏览器：
- File API
- ArrayBuffer
- Blob
- ES6+

推荐使用 Chrome 88+、Firefox 78+、Safari 14+ 或 Edge 88+。
EOF

echo "4. 创建部署脚本..."
cat > web-patcher/deploy.sh << 'EOF'
#!/bin/bash

# 简单的HTTP服务器启动脚本，用于本地测试

echo "启动本地Web服务器..."
echo "访问地址: http://localhost:8000"
echo "按 Ctrl+C 停止服务器"

# 尝试使用Python3
if command -v python3 &> /dev/null; then
    python3 -m http.server 8000
# 或者Python2
elif command -v python &> /dev/null; then
    python -m SimpleHTTPServer 8000
# 或者Node.js
elif command -v npx &> /dev/null; then
    npx http-server -p 8000
else
    echo "错误: 未找到Python或Node.js，无法启动HTTP服务器"
    echo "请手动启动Web服务器或直接用浏览器打开index.html"
    exit 1
fi
EOF

chmod +x web-patcher/deploy.sh

echo "✅ Web版构建完成！"
echo ""
echo "使用方法："
echo "1. 进入 web-patcher 目录: cd web-patcher"
echo "2. 启动本地服务器: ./deploy.sh"
echo "3. 或者直接用浏览器打开 index.html"
echo ""
echo "文件结构："
echo "  web-patcher/"
echo "  ├── index.html       # 主页面"
echo "  ├── style.css        # 样式文件"
echo "  ├── patcher.js       # 主要逻辑"
echo "  ├── payload-data.js   # Payload数据"
echo "  ├── README.md        # 使用说明"
echo "  └── deploy.sh        # 部署脚本"
