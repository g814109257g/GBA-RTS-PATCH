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
