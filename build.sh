arm-none-eabi-gcc -mcpu=arm7tdmi -nostartfiles -nodefaultlibs -marm -fPIC  -mpic-data-is-text-relative -mno-single-pic-base -Os -fno-toplevel-reorder -Wall -Wextra -Wshadow  payload.c -T payload.ld -o payload.elf


arm-none-eabi-objcopy -O binary payload.elf payload.bin
xxd -i payload.bin > payload_bin.c 

# 获取当前git提交哈希值（短版本）
if command -v git >/dev/null 2>&1 && git rev-parse --git-dir >/dev/null 2>&1; then
    GIT_HASH=$(git rev-parse --short HEAD 2>/dev/null)
    if [ -z "$GIT_HASH" ]; then
        GIT_HASH="nogit"
    fi
else
    GIT_HASH="nogit"
fi

# 检测是否在Windows环境下（MSYS2/MinGW/Cygwin）
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$MSYSTEM" == "MINGW64" || "$MSYSTEM" == "MINGW32" ]]; then
    # Windows环境：添加编码参数，源文件UTF-8，输出GBK
    echo "Building for Windows environment with encoding support..."
    gcc -g -finput-charset=UTF-8 -fexec-charset=GBK patcher.c payload_bin.c -o patcher
    gcc -g -finput-charset=UTF-8 -fexec-charset=GBK patcher.c payload_bin.c -o patcher_${GIT_HASH}
    echo "Built: patcher.exe and patcher_${GIT_HASH}.exe"
else
    # Linux/Unix环境：使用默认编码
    echo "Building for Unix/Linux environment..."
    gcc -g patcher.c payload_bin.c -o patcher
    gcc -g patcher.c payload_bin.c -o patcher_${GIT_HASH}
    echo "Built: patcher and patcher_${GIT_HASH}"
fi