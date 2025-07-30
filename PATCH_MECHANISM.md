# GBA RTS补丁工作原理详解

## 1. 补丁注入和劫持机制

### 1.1 入口点劫持

GBA游戏的执行流程通常是：
```
ROM头部(0x8000000) -> 游戏入口点(通常0x80000C0) -> 游戏主逻辑
```

补丁通过修改这个流程来实现功能注入：
```
ROM头部 -> patched_entrypoint -> 初始化RTS系统 -> 原游戏入口点
```

具体实现：
```c
// payload头部结构（必须在文件最开始）
const uint32_t original_entrypoint = 0x080000c0;  // 保存原始入口点
const uint32_t patched_entrypoint_addr = (uint32_t)patched_entrypoint;
```

patcher.c会：
1. 读取原始ROM的入口点
2. 将payload代码追加到ROM末尾
3. 修改ROM头部的入口点指向`patched_entrypoint`
4. 在payload中保存原始入口点地址

### 1.2 中断向量劫持

GBA的中断系统：
- 中断向量表位于 0x3FFFFFC (IRQ处理程序地址)
- 发生中断时，CPU自动跳转到该地址指向的处理程序

补丁的劫持过程：
```c
// 在patched_entrypoint中
volatile uint32_t *irq_vector = (volatile uint32_t*)0x03FFFFFC;
*irq_vector = irq_handler_addr;  // 指向我们的keypad_irq_handler
```

当按键中断发生时：
```
按键中断 -> keypad_irq_handler -> 检测组合键 -> 原始IRQ处理程序
                                        |
                                   L+R+START/SELECT
                                        |
                                    存档/读档
```

## 2. 位置无关代码(PIC)实现

### 2.1 为什么需要PIC

补丁代码被patcher追加到ROM的末尾，具体位置取决于原ROM大小。代码必须能在任意地址正确运行。

### 2.2 相对地址获取

使用特殊的宏来获取运行时地址：

```c
// 获取符号的运行时地址
#define GET_REL_ADDR(symbol, var) \
    asm volatile("adrl %0, " #symbol : "=r"(var))

// 获取符号处的值
#define GET_REL_VALUE(symbol, var) \
    asm volatile("ldr %0, " #symbol : "=r"(var))
```

`adrl`是一个伪指令，编译器会将其展开为：
- 在近距离时：`add rd, pc, #offset`
- 在远距离时：两条指令的组合

### 2.3 使用示例

```c
// 获取keypad_irq_handler的实际运行地址
uint32_t irq_handler_addr;
GET_REL_ADDR(keypad_irq_handler, irq_handler_addr);

// 获取保存的原始入口点值
uint32_t original_entry_addr;
GET_REL_VALUE(original_entrypoint, original_entry_addr);
```

### 2.4 避免GOT依赖

不使用全局变量的直接引用，而是通过基地址+偏移的方式访问：
```c
// 错误：会生成GOT引用
extern uint32_t flash_fn_table[];
uint32_t addr = flash_fn_table[0];

// 正确：使用相对寻址
flash_functions_t *flash_funcs;
GET_REL_ADDR(flash_fn_table, flash_funcs);
uint32_t addr = flash_funcs[0].identify_start;
```

## 3. 栈上执行Flash操作

### 3.1 问题背景

Flash编程时的限制：
- 编程Flash时，Flash内容不可读
- 如果代码在Flash(ROM)中运行，会导致崩溃
- 必须将Flash操作代码复制到RAM执行

### 3.2 run_thumb_from_ram实现

```c
int run_thumb_from_ram(uint32_t arg0, uint32_t arg1, 
                      uint32_t func_start, uint32_t func_end)
{
    // 1. 切换到系统模式（获得更大的栈空间）
    // 2. 将函数代码从ROM复制到栈
    // 3. 执行栈上的代码
    // 4. 清理栈并返回
}
```

关键步骤：
1. **保存当前栈指针**：用于后续恢复
2. **复制代码到栈**：从函数末尾向前复制（栈向下增长）
3. **设置Thumb位**：`add r2, sp, #1` 确保BX指令切换到Thumb模式
4. **恢复栈**：执行完后恢复原始栈指针

### 3.3 Flash操作函数的特殊要求

```c
int __attribute__((target("thumb"), aligned(4))) identify_flash_1()
{
    // 只能使用局部变量和立即数
    // 不能调用其他函数
    // 不能访问全局变量
}
```

要求说明：
- `target("thumb")`：必须是Thumb代码（16位指令，更紧凑）
- `aligned(4)`：4字节对齐，确保正确复制
- 自包含：不依赖外部符号

### 3.4 Flash函数表结构

```c
typedef struct {
    uint32_t identify_start;   // 识别函数起始地址（相对）
    uint32_t identify_end;     // 识别函数结束地址（相对）
    uint32_t erase_start;      // 擦除函数起始地址（相对）
    uint32_t erase_end;        // 擦除函数结束地址（相对）
    uint32_t program_start;    // 编程函数起始地址（相对）
    uint32_t program_end;      // 编程函数结束地址（相对）
} flash_functions_t;
```

使用时需要加上基地址：
```c
uint32_t identify_start = flash_funcs[i].identify_start + original_entry_addr;
```

## 4. 特殊技术细节

### 4.1 内联汇编标签

在C文件中嵌入汇编标签，用于标记函数结束位置：
```c
void identify_flash_1() { /* ... */ }
asm(".align 2\n"
    "identify_flash_1_end:");
```

这允许我们精确计算函数大小。

### 4.2 369in1 Mapper锁定

```c
// 锁定369in1 mapper，防止游戏切换bank
*(volatile uint8_t*)(0x0E000000 + 3) = 0x80;
```

### 4.3 编译器优化控制

- 使用`volatile`防止编译器优化掉关键操作
- 使用`__asm("nop")`确保指令执行顺序
- 使用内存屏障`asm volatile("" ::: "memory")`

## 5. 总结

整个补丁机制通过精巧的设计实现了：
1. 不修改游戏代码的情况下注入功能
2. 在任意位置都能正确运行的位置无关代码
3. 安全的Flash操作（通过栈执行）
4. 最小的性能影响（只在按键中断时激活）

这种设计既保证了兼容性，又实现了强大的即时存档功能。