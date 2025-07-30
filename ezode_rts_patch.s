@;--------------------------------------------------------------------
@; GBA即时存档(RTS)补丁 - Real Time Save Patch for GBA
@; 功能: 在GBA游戏运行时提供存档、读档、金手指和睡眠功能
@; 作者: EZ-FLASH团队
@;--------------------------------------------------------------------
	.section   	.iwram,"ax",%progbits
		
	.global  RTS_ReplaceIRQ_start		@; RTS中断替换代码起始位置
	.global  RTS_ReplaceIRQ_end		@; RTS中断替换代码结束位置
	.global  RTS_Return_address_L		@; 返回地址标签
	.global  RTS_Sleep_key			@; 睡眠模式按键组合
	.global  RTS_Reset_key			@; 重启按键组合
	@;.global  RTS_Wakeup_key		@; 唤醒按键组合
	.global	 RTS_switch			@; RTS功能开关
	.global	 Cheat_count			@; 金手指条目数量
	.global	 CHEAT				@; 金手指数据存储区
	.global  no_CHEAT_end			@; 无金手指模式结束标志
	@;.global  ASCII			@; ASCII字符数据
	
@; GBA硬件寄存器地址定义
@; I/O寄存器基址和各种硬件控制寄存器偏移量
@; 使用时，直接BASE+偏移量即可访问对应寄存器
REG_BASE		= 0x4000000	@; I/O寄存器基地址
REG_DISPCNT		= 0x00		@; 显示控制寄存器
REG_DISPSTAT	= 0x04		@; 显示状态寄存器
REG_VCOUNT		= 0x06		@; 垂直计数器寄存器
REG_BG0CNT		= 0x08		@; 背景层0控制寄存器
REG_BG1CNT		= 0x0A		@; 背景层1控制寄存器
REG_BG2CNT		= 0x0C		@; 背景层2控制寄存器
REG_BG3CNT		= 0x0E		@; 背景层3控制寄存器
REG_BG0HOFS		= 0x10		@; 背景层0水平滚动偏移
REG_BG0VOFS		= 0x12		@; 背景层0垂直滚动偏移
REG_BG1HOFS		= 0x14		@; 背景层1水平滚动偏移
REG_BG1VOFS		= 0x16		@; 背景层1垂直滚动偏移
REG_BG2HOFS		= 0x18		@; 背景层2水平滚动偏移
REG_BG2VOFS		= 0x1A		@; 背景层2垂直滚动偏移
REG_BG3HOFS		= 0x1C		@; 背景层3水平滚动偏移
REG_BG3VOFS		= 0x1E		@; 背景层3垂直滚动偏移
REG_WIN0H		= 0x40		@; 窗口0水平范围
REG_WIN1H		= 0x42		@; 窗口1水平范围
REG_WIN0V		= 0x44		@; 窗口0垂直范围
REG_WIN1V		= 0x46		@; 窗口1垂直范围
REG_WININ		= 0x48		@; 窗口内效果控制
REG_WINOUT		= 0x4A		@; 窗口外效果控制
REG_BLDCNT		= 0x50		@; 颜色混合控制
REG_BLDALPHA	= 0x52		@; Alpha混合系数
REG_BLDY		= 0x54		@; 亮度调节
@; 音频寄存器定义
REG_SOUND1CNT_L	= 0x60		@; 声道1扫描控制
REG_SOUND1CNT_H	= 0x62		@; 声道1波形控制
REG_SOUND1CNT_X	= 0x64		@; 声道1频率控制
REG_SOUND2CNT_L	= 0x68		@; 声道2波形控制  
REG_SOUND2CNT_H	= 0x6C		@; 声道2频率控制
REG_SOUND3CNT_L	= 0x70		@; 声道3开关控制
REG_SOUND3CNT_H	= 0x72		@; 声道3音量控制
REG_SOUND3CNT_X	= 0x74		@; 声道3频率控制
REG_SOUND4CNT_L	= 0x78		@; 声道4音量控制
REG_SOUND4CNT_H	= 0x7c		@; 声道4频率控制
REG_SOUNDCNT_L		= 0x80		@; 主音量控制
REG_SOUND2CNT_H		= 0x82		@; DMA音频控制
REG_SOUNDCNT_X		= 0x84		@; 主音频开关
REG_SOUNDBIAS		= 0x88		@; 音频偏置
REG_WAVE_RAM0_L		= 0x90		@; 波形RAM起始
REG_FIFO_A_L	= 0xA0		@; DMA音频FIFO A低位
REG_FIFO_A_H	= 0xA2		@; DMA音频FIFO A高位
REG_FIFO_B_L	= 0xA4		@; DMA音频FIFO B低位
REG_FIFO_B_H	= 0xA6		@; DMA音频FIFO B高位
@; DMA传输寄存器定义
REG_DM0SAD		= 0xB0		@; DMA0源地址
REG_DM0DAD		= 0xB4		@; DMA0目标地址
REG_DM0CNT_L	= 0xB8		@; DMA0传输计数
REG_DM0CNT_H	= 0xBA		@; DMA0控制寄存器
REG_DM1SAD		= 0xBC		@; DMA1源地址
REG_DM1DAD		= 0xC0		@; DMA1目标地址
REG_DM1CNT_L	= 0xC4		@; DMA1传输计数
REG_DM1CNT_H	= 0xC6		@; DMA1控制寄存器
REG_DM2SAD		= 0xC8		@; DMA2源地址
REG_DM2DAD		= 0xCC		@; DMA2目标地址
REG_DM2CNT_L	= 0xD0		@; DMA2传输计数
REG_DM2CNT_H	= 0xD2		@; DMA2控制寄存器
REG_DM3SAD		= 0xD4		@; DMA3源地址
REG_DM3DAD		= 0xD8		@; DMA3目标地址
REG_DM3CNT_L	= 0xDC		@; DMA3传输计数
REG_DM3CNT_H	= 0xDE		@; DMA3控制寄存器
@; 定时器和中断寄存器
REG_TM0D		= 0x100		@; 定时器0数据
REG_TM0CNT		= 0x102		@; 定时器0控制
REG_IE			= 0x200		@; 中断使能寄存器
REG_IF			= 0x202		@; 中断标志寄存器
REG_P1			= 0x130		@; 按键状态寄存器
REG_P1CNT		= 0x132		@; 按键中断控制
REG_WAITCNT		= 0x204		@; 等待状态控制

@;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
@; RTS中断替换入口点 - 将原游戏的IRQ处理程序替换为RTS处理程序
@;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	.arm
RTS_ReplaceIRQ_start:
	MOV             R0, #0x4000000		@; 加载I/O寄存器基地址
	ADR             R1, RTS_irq		@; 获取RTS中断处理程序地址
	STR             R1, [R0,#-4] 		@; 将RTS_irq地址写入0x3FFFFFC (中断向量表)
	LDR             R0, =0x12345678		@; 加载返回地址 (需要在运行时修改)
	BX              R0			@; 跳转返回原程序
	.align
RTS_Return_address_L:
	.ltorg 				@; 返回地址标签，需要在运行时修改
@;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
@; 临时数据存储区地址 - 用于保存游戏状态和寄存器
@;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
spend_0x80:
	.word 0x0203FE00   		@; 默认临时存储地址 (EWRAM区域)
						    @; 0203FFFF - 0203FE00 = 0x1FF, 512字节的空闲区域，这是认为，至少，EWRAM会有这么多的可用空间
@;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
@; RTS自定义中断处理程序 - 处理按键检测和功能调用
@;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RTS_irq:
@BIOS在中断时，会将R0设置为0x4000000
	LDR			R1, [R0,#0x200]		@; 读取中断使能寄存器 4000200h
	TST			R1, #0x10000		@; 测试按键中断标志
	TSTEQ		R1, #0x10000000		@; 测试卡带中断标志
	LDREQ		PC, [R0,#-0xC]		@; 如果不是按键/卡带中断，跳转到原中断处理程序

	ldr 		r2,[r0,#REG_P1]		@; 读取按键状态寄存器
	bic 		r2,r2,#0xFF000000	@; 清除高位，保留按键状态
	bic 		r2,r2,#0x00FF0000
	
	@; 检查是否按下游戏内菜单组合键 (L+R+Start)
	adr 		r3,RTS_Reset_key 	@; 获取重启按键组合
	ldr 		r3,[r3]
	cmp 		r2,r3			@; 比较当前按键状态		
	bne			check_sleep		@; 如果不匹配，检查睡眠按键
	
	@; 进入游戏内菜单前的寄存器保存
	adrl		r12, spend_0x80		@; 获取临时存储ingamemenu_now区地址
	ldr			r12,[r12]			@ r12 = *(&spend_0x80)
	stmia		r12!,{r4-r11,sp,lr} 	@; 保存通用寄存器、栈指针和链接寄存器
	mrs	 		r2,SPSR			@; 获取SPSR状态寄存器
	stmia		r12!,{r2}       	@; 保存SPSR
	
	stmfd   SP!, {LR}  			@; 保护返回地址	
	bl 			ingamemenu_now		@; 调用游戏内菜单功能
	ldmfd   SP!, {LR}			@; 恢复返回地址
	
	@; 检查睡眠模式按键组合 (L+R+Select)
check_sleep:
	adr 		r3,RTS_Sleep_key 		@; 获取睡眠按键组合地址
	ldr 		r3,[r3]			@; 加载睡眠按键组合值
	cmp 		r2,r3 			@; 比较当前按键状态
	beq 		sleep_now		@; 如果匹配，进入睡眠模式
	
	@; 检查金手指功能是否启用
	adrl 		r2,CheatONOFF		@; 获取金手指开关地址
	ldr 		r2,[r2]			@; 加载开关地址
	ldr 		r2,[r2] 		@; 读取开关状态	
	cmp 		r2,#1			@; 检查是否启用金手指
	bne 		nocheat			@; 如果未启用，跳过金手指处理
	
	@; 执行金手指代码
	stmfd   SP!, {r4-r6}		@; 保存寄存器状态	
	adrl 		r5,CHEAT		@; 获取金手指数据地址
	adrl		r6,Cheat_count		@; 获取金手指条目计数地址
	ldr			r2,[r6]		@; 加载金手指条目数量
cheat_loop:
	cmp			r2,#0		@; 检查是否还有金手指条目
	beq			cheat_loop_end	@; 如果没有，结束循环	
	ldmia   r5!,{r3-r4}		@; 加载金手指地址和数值
	strb		r4,[r3]		@; 将数值写入目标地址
	sub 		r2,#0x01	@; 减少计数器
	b				cheat_loop	@; 继续循环
cheat_loop_end:
	ldmfd   SP!, {r4-r6}		@; 恢复寄存器状态
nocheat:
	ldr 		pc,[r0,#-(0x04000000-0x03FFFFF4)] @; 跳转到原游戏的IRQ处理程序									
@;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
@; 系统重启功能 - 软重启GBA系统
@;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
reset_now:
	adr r1,reset_code		@; 获取重启代码地址
	adr r3,reset_end		@; 获取重启代码结束地址
	mov r2,#0x02000000		@; 设置目标地址为EWRAM起始
copy_loop:
	ldr r0,[r1],#4			@; 从源地址加载4字节并递增指针
	str r0,[r2],#4			@; 写入目标地址并递增指针
	cmp r1,r3			@; 比较是否复制完成
	blt copy_loop			@; 如果未完成，继续复制
	mov r0,#0x02000000		@; 设置跳转地址
	add r0,r0,#1			@; 设置THUMB模式标志
	bx r0				@; 跳转执行重启代码
@;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
@; 按键组合定义 - 用于触发不同功能的按键组合
@;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RTS_Sleep_key:
	.word 0xFB 		@; 睡眠模式按键: L+R+Select (按位取反后的值)
RTS_Reset_key:
	.word 0xF7 		@; 游戏内菜单按键: L+R+Start (按位取反后的值)
@;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
@; THUMB模式重启代码 - 在EWRAM中执行的系统重启代码
@;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	.align	
	.thumb
reset_code:
	mov r0,#0x20
	lsl r3,r0,#22 @;#0x8000000 r3
	lsl r0,r0,#12 @;#0x0020000
	add r4,r3,r0  @;#0x8020000 r4
	add r5,r4,r0  @;#0x8040000 r5
	lsl r1,r0,#8  @;#0x2000000
	add r2,r3,r1  @;#0xa000000
	lsr r1,r3,#4  @;#0x0800000
	sub r6,r2,r1  @;#0x9800000
	lsr r1,r1,#4  @;#0x0080000
	add r6,r6,r1  @;#0x9880000 r6
	sub r2,r2,r0  @;#0x9fe0000 r2
	sub r7,r2,r0  @;#0x9fc0000 r7

	mov r0,#210
	lsl r0,r0,#8  @;0xd200 r0
	mov r1,#21
	lsl r1,r1,#8  @;0x1500 r1

	strh r0,[r2]
	strh r1,[r3]
	strh r0,[r4]
	strh r1,[r5]

	lsr r0,r3,#12 @;#0x0008000 r0
	add r0,#2 		@;#0x0008002 r0

	strh r0,[r6]
	strh r1,[r7]

	lsl r1,r0,#11 @;#0x4000000
	sub r1,r1,#8  @;#0x3FFFFFA
	mov r0,#0xfc  @;#252 r0
	str r0,[r1]   @;#0x3FFFFFA (mirror of #0x3007FFA
	swi 0x01
	swi 0x00
	.align	
reset_end:
@;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
@; 睡眠模式功能 - 降低功耗并等待唤醒按键
@;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	.arm
sleep_now:
	stmfd sp!,{r4-r11,lr}		@; 保存寄存器状态
	add r1,r0,#REG_SOUND1CNT_L	@; 获取音频寄存器地址
	
	@; 保存音频寄存器状态 (32字节)
	ldmia r1!,{r2-r9}		@; 加载8个寄存器值
	stmfd sp!,{r2-r9}		@; 保存到栈
	@; 保存更多音频寄存器 (32字节)
	ldmia r1!,{r2-r9}		@; 继续加载下一组寄存器
	stmfd sp!,{r2-r9}		@; 保存到栈

	@; 保存关键I/O寄存器的原始值
	add r1,r0,#REG_IE		@; 中断使能寄存器地址
	ldrh r4,[r1]			@; 保存中断使能状态
	ldr r5,[r0,#REG_P1]		@; 保存按键寄存器状态
	ldrh r6,[r0,#REG_DISPCNT]	@; 保存显示控制寄存器

	@; 配置睡眠模式中断
	ldr r1,=0xFFFF1000		@; 设置中断使能值
	str r1,[r0,#REG_IE]		@; 启用按键和卡带中断
	mov r1,#0xC0000000		@; 基础按键中断配置
	adr r2,RTS_Wakeup_key		@; 获取唤醒按键组合
	ldr r2,[r2]			@; 加载唤醒按键值
	MVN R2,R2			@; 按位取反
	lsl	r2,r2,#0x10		@; 左移到正确位置
	orr r1,r1,r2			@; 合并按键配置
	str r1,[r0,#REG_P1]		@; 设置按键中断
	strh r0,[r0,#REG_SOUNDCNT_X]	@; 关闭音频
	orr r1,r6,#0x80			@; 设置LCD关闭标志
	strh r1,[r0,#REG_DISPCNT]	@; 关闭LCD降低功耗

	swi 0x030000			@; 系统调用: 进入停止模式

	@;Loop to wait for letting go of Sel+start
loop:
	mov r0,#REG_BASE
	ldr r1,[r0,#REG_P1]
	adr r7,RTS_Wakeup_key
	ldr r7,[r7]
	and r1,r1,r7
	@;cmp r1,#0x000C
	cmp r1,r7
	bne loop

	@;spin until VCOUNT==159
spin2:
	ldrh r1,[r0,#REG_VCOUNT]
	cmp r1,#159
	bne spin2
	@;spin until VCOUNT==160
spin4:
	ldrh r1,[r0,#REG_VCOUNT]
	cmp r1,#160
	bne spin4
	@;spin until VCOUNT==159
spin5:
	ldrh r1,[r0,#REG_VCOUNT]
	cmp r1,#159
	bne spin5
	@;spin until VCOUNT==160
spin6:
	ldrh r1,[r0,#REG_VCOUNT]
	cmp r1,#160
	bne spin6
	@;spin until VCOUNT==159
spin7:
	ldrh r1,[r0,#REG_VCOUNT]
	cmp r1,#159
	bne spin7

	@;restore interrupts
	add r1,r0,#REG_IE
	strh r4,[r1]
	@;restore joystick interrupt
	str r5,[r0,#REG_P1]
	mov r4,#0x1000 @;clear the damn joystick interrupt
	strh r4,[r1,#2]

	@;restore screen
	strh r6,[r0,#REG_DISPCNT]
	ldmfd sp!,{r2-r9}
	@;restore sound state
	str r3,[r0,#REG_SOUNDCNT_X]
	add r1,r0,#0x80
	stmia r1!,{r2-r9}
	add r1,r0,#0x60
	ldmfd sp!,{r2-r9}
	stmia r1!,{r2-r9}
	ldmfd sp!,{r4-r11,lr}
	@;spin until VCOUNT==160, triggers next vblank
spin3:
	ldrh r1,[r0,#REG_VCOUNT]
	cmp r1,#160
	bne spin3  @<insert ytmnd cliche here>
	@;all done!
	ldr pc,[r0,#-(0x04000000-0x03FFFFF4)] @to IRQ routine
	@b b_pressed_quit
	.align
RTS_Wakeup_key:
	.word 0x3F3 		@; 唤醒按键组合: Start + Select (按位取反后的值)
	.ltorg
@;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
@; 屏幕清除和SRAM读写函数区域
@;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	.arm
@;------------------------------------------------------
@; 清除屏幕函数 - 清空VRAM显示内容
@;------------------------------------------------------
clean_screen:
	stmfd	sp!,{r0-r3}		@; 保存寄存器
	mov		r2,#0x6000000		@; VRAM起始地址
	add		r3,r2,#0x12C00		@; VRAM结束地址
	mov		r0,#0			@; 清零值
clearLCD:
	str		r0,[r2],#+4		@; 写入0并递增地址
	cmp		r2,r3			@; 检查是否清除完毕
	blt		clearLCD		@; 如果未完成，继续清除
	
	ldmfd	sp!,{r0-r3}		@; 恢复寄存器
	bx		lr			@; 返回		
@;------------------------------------------------------
@; 设置闪存卡页面切换 - 控制闪存卡内存页面映射
@;------------------------------------------------------
SetRampage:
	ldr 	r1,=0xD200		@; 页面切换控制值
	ldr 	r2,=0x1500		@; 页面启用值
	ldr 	r3,=0x9fe0000		@; 闪存卡控制寄存器地址
	strh 	r1,[r3]			@; 设置页面切换控制
	mov 	r3,#0x8000000		@; ROM区域地址
	strh  r2,[r3]			@; 启用页面切换
	ldr 	r3,=0x8020000		@; ROM区域地址2
	strh 	r1,[r3]			@; 设置页面切换控制
	ldr 	r3,=0x8040000		@; ROM区域地址3
	strh  r2,[r3]			@; 启用页面切换
	ldr 	r3,=0x9C00000		@; 页面选择寄存器地址
	strh  r0,[r3]			@; 写入页面号(r0参数)
	ldr 	r3,=0x9FC0000		@; 最终控制寄存器
	strh  r2,[r3]			@; 确认页面切换
	bx		lr			@; 返回
@;------------------------------------------------------
@;------------------------------------------------------
@;WriteSram_val:        @; sram address, val
@;	STRB    R1, [R0],#1
@;	LSR     R1, R1, #0x8
@;	STRB    R1, [R0],#1
@;	LSR     R1, R1, #0x8
@;	STRB    R1, [R0],#1
@;	LSR     R1, R1, #0x8
@;	STRB    R1, [R0]
@;	BX      LR
@;------------------------------------------------------
WriteSram: @;(u32 address, u8 *data, u32 size)
	ADD 		R2,R2,R0
	SUB 		R1,R1,R0
wSram_loop1:
	CMP     R0, R2
	BNE     wSram_loop
	BX      LR
wSram_loop:
	LDR     R3, [R1,R0]
	STRB    R3, [R0],#1
	LSR     R3, R3, #0x8
	STRB    R3, [R0],#1
	LSR     R3, R3, #0x8
	STRB    R3, [R0],#1
	LSR     R3, R3, #0x8
	STRB    R3, [R0],#1	
	B       wSram_loop1
@;------------------------------------------------------
ReadSram: @;(u32 address, u8 *data, u32 size)
	ADDS    R2, R2, R0
	SUBS    R1, R1, R0
rSram_loop1:
	CMP     R0, R2
	BNE     rSram_loop
	BX      LR
rSram_loop:
	LDRB    R3, [R0]
	LSL 		R4,R3,#0
	LDRB    R3, [R0,#1]
	LSL 		R5,R3,#8
	ORR			R4,R5
	LDRB    R3, [R0,#2]
	LSL 		R5,R3,#16
	ORR			R4,R5
	LDRB    R3, [R0,#3]
	LSL 		R5,R3,#24
	ORR			R4,R5
	STR     R4, [R1,R0]
	ADDS    R0, #4
	B       rSram_loop1
@;------------------------------------------------------
backup_LCD:
	stmfd	sp!,{r0-r7,lr}
	mov 	r0,#0x20	@; 临时存储页，不会进RTS
	bl 		SetRampage	
	mov 	r0,#0x0E000000
	mov 	r1,#0x6000000
	mov 	r2,#0x10000		@;0x12C00
	bl 		WriteSram   	@;(u32 address, u8 *data, u32 size)
	mov 	r0,#0x30    @; 临时存储页，不会进RTS
	bl 		SetRampage	
	mov 	r0,#0x0E000000
	ldr 	r1,=0x6010000
	ldr 	r2,=0x2C00
	bl 		WriteSram   	@;(u32 address, u8 *data, u32 size)
	
	ldmfd	sp!,{r0-r7,PC}

@;------------------------------------------------------
restore_LCD:
	stmfd	sp!,{r0-r7,lr}
	mov 	r0,#0x20
	bl 		SetRampage
	mov r0,#0x0E000000
	mov r1,#0x6000000
	mov r2,#0x10000		@;0x12C00
	bl  ReadSram    	@;(u32 address, u8 *data, u32 size)  
	mov 	r0,#0x30
	bl 		SetRampage	
	mov r0,#0x0E000000
	ldr r1,=0x6010000
	ldr r2,=0x2C00
	bl 	ReadSram   	 @;(u32 address, u8 *data, u32 size)


	ldmfd	sp!,{r0-r7,PC}
@;------------------------------------------------------
restore2_IO:        @; IOaddress, offset
	LDRB    R3, [R1]
	LSL 		R4,R3,#0
	LDRB    R3, [R1,#1]
	LSL 		R5,R3,#8
	ORR			R4,R5
	STRH    R4, [R0]
	bx lr
@;restore4_IO:        @; IOaddress, offset
@;	LDRB    R3, [R1]
@;	LSL 		R4,R3,#0
@;	LDRB    R3, [R1,#1]
@;	LSL 		R5,R3,#8
@;	ORR			R4,R5	
@;	LDRB    R3, [R1,#2]
@;	LSL 		R5,R3,#16
@;	ORR			R4,R5
@;	LDRB    R3, [R1,#3]
@;	LSL 		R5,R3,#24
@;	ORR			R4,R5
@;	STR     R4, [R0]
@;	bx lr
@;------------------------------------------------------
@;------------------------------------------------------
ingamemenu_now:
	stmfd	sp!,{r0-r12,lr}
	
	mov 	r7,#0x4000000
	add 	r1,r7,#REG_SOUND1CNT_L
	adrl	r11, spend_0x80
	ldr		r11,[r11]  		
	add		r11,#0x40     @;0x3007EC0
  
	add   r3,r11,#0x32 	@; IO 0x60-0x90 offset 0x100-130
	@;音频寄存器是从4000060h开始，到 4000090h结束
	@;要拷贝到r11到r3的地址，也就是0x40一直到0x70的地址

	@; r2 = reg_val,专门用于中转用
loopbak:
	ldrh  r2,[r1],#2
	strh  r2,[r11],#2
	cmp   r11,r3
	bne   loopbak	@;这一段就是在循环将4000060h开始，到 4000090h结束的音频，拷贝到0x40到0x70偏移的地址


	ldrh r2,[r7,#0xBA]@;DMA0CNT_H
	strh  r2,[r11],#2 @;offset 0x72
	ldrh r2,[r7,#0xC6]@;DMA1CNT_H	
	strh  r2,[r11],#2 @;offset 0x74	
	ldrh r2,[r7,#0xD2]@;DMA2CNT_H	
	strh  r2,[r11],#2 @;offset 0x76
	ldrh r2,[r7,#0xDE]@;DMA3CNT_H	
	strh  r2,[r11],#2 @;offset 0x78	
		
	mov		r7,#0x4000000
	ldrh 	r3,[r7,#REG_SOUNDCNT_L]  @;san guo
	stmfd	sp!,{r3}		
	ldrh 	r3,[r7,#REG_SOUNDCNT_X]  @;bak
	stmfd	sp!,{r3}		
	
	ldrh  r6,[r7]     @;Displaly Control
	stmfd	sp!,{r6}
	
	mov 	r3,#0x0100
	strh 	r3,[r7,#0x20]	@;Rotation/Scaling BG2P
	strh 	r3,[r7,#0x26]			
	mov 	r3,#0x0	
	strh 	r3,[r7,#0x22]	
	strh 	r3,[r7,#0x24]		
	str 	r3,[r7,#0x28]	@;BG2X/Y
	str 	r3,[r7,#0x2c]	
	
	strh 	r3,[r7,#0x54]	@;Bldy Brightness

	strh 	r3,[r7,#0xBA]	@;DMA0CNT_H	0086game
	strh 	r3,[r7,#0xC6]	@;DMA1CNT_H		
	strh 	r3,[r7,#0xD2]	@;DMA2CNT_H	
	strh 	r3,[r7,#0xDE]	@;DMA3CNT_H	
	ldr  	r6,=0x403 		@;MODE_3 | BG2_ENABLE
	strh 	r6,[r7]	
	@;mov 	r2,#0	
	strh 	r3,[r7,#208]  @;IME =0 Disable

	strh 	r3,[r7,#REG_SOUNDCNT_X] @;sound off
			
	bl 		backup_LCD
	bl 		clean_screen

@; start
	mov		r11,#0	
begin_show:
	mov		r12,#0
	@;cmp		r11,#0
	@;movlt	r11,#0
	
	adrl  r8,ingameMENU
	mov		r9,#40		 @;Y
	mov		r10,#86    @;X	
	
showAll:	
	adrl  r7,Cheat_count
	ldr		r7,[r7]
	cmp 	r7,#0x0
	beq   no_cheat  
	cmp		r11,#0
	movlt	r11,#4
	cmp		r11,#5
	@;movge	r11,#4
	moveq	r11,#0
	ldrb	r0,[r8],#+1
	cmp		r0,#0xA5
	beq		waitSeletc	
	b  		showMENU
no_cheat:
	cmp		r11,#0
	movlt	r11,#2
	cmp		r11,#3
	@;movge	r11,#2
	moveq	r11,#0
	ldrb	r0,[r8],#+1
	cmp		r0,#0x43 @;'C'
	beq		waitSeletc
		
showMENU:
	cmp		r0,#0
	addeq	r9,#16
	moveq	r10,#86
	addeq	r12,#1
	beq		showAll
	mov		r1,r10
	add		r2,r9,#0
	cmp		r12,r11
	ldreq		r3,=0x6A80 @;select
	ldrne		r3,=0x7FFF 
	bl		printchar    @; r0 ch�� r1, X  �� r2, Y , r3 color

	add		r10,#8
	b			showAll

waitSeletc:
	ldr		r0,=0x3FF		@;No key press
	ldr		r8,=0x4000130
	ldrh	r9,[r8]
	cmp		r9,r0
	beq		waitSeletc	
pressdown:
	mov		r12,r9
	ldrh	r9,[r8]
	cmp		r9,r0
	bne		pressdown
	
	ldr		r0,=0x3BF		;@up
	cmp		r12,r0
	subeq	r11,#1
	beq		begin_show
	ldr		r0,=0x37F		;@down
	cmp		r12,r0
	addeq	r11,#1
	beq		begin_show
	ldr		r0,=0x3FE		;@A
	cmp		r12,r0
	beq		A_pressed
	ldr		r0,=0x3FD		;@B 
	cmp		r12,r0
	moveq	r11,#5
	beq		b_pressed_quit
	b		waitSeletc
A_pressed:	
	cmp			r11,#0 
	beq			reset_now	
	cmp			r11,#1	
	beq			call_Save
	cmp			r11,#2
	beq			call_Load
	cmp			r11,#3
	beq			call_CheatON
	cmp			r11,#4
	beq			call_CheatOFF
	@;-------------------------------------
@;ingamemenu_exit:
b_pressed_quit:	
	ldmfd	sp!,{r6}
	mov		r7,#0x4000000
	strh 	r6,[r7] @;re Displaly Control
	bl 		restore_LCD	
save_exit:
		
	mov		r7,#0x4000000
	mov 	r2,#1
	strh 	r2,[r7,#208]
	
	ldmfd	sp!,{r3}
	strh 	r3,[r7,#REG_SOUNDCNT_X]
	
	ldmfd	sp!,{r3}	
	strh 	r3,[r7,#REG_SOUNDCNT_L]  @;san guo
	
	adrl	r11, spend_0x80
	ldr		r11,[r11]  
	add		r0,r11,#0x40 @;0x3007EC0
	
	ldrh  r3,[r0],#2
	strh 	r3,[r7,#0x60]	@;SOUND1CNT_L
	ldrh  r3,[r0],#6
	strh 	r3,[r7,#0x62]	@;SOUND1CNT_H
	ldrh  r3,[r0],#8
	strh 	r3,[r7,#0x68]	@;SOUND2CNT_L
	ldrh  r3,[r0],#8
	strh 	r3,[r7,#0x70]	@;SOUND3CNT_L
	ldrh  r3,[r0],#8
	strh 	r3,[r7,#0x78]	@;SOUND3CNT_L
	
	add		r11,#0x70   @;0x3007EC0+0x30
	add 	r11,#2
	ldrh  r3,[r11],#2
	strh 	r3,[r7,#0xBA]	@;DMA0CNT_H
	ldrh  r3,[r11],#2
	strh 	r3,[r7,#0xC6]	@;DMA1CNT_H	
	ldrh  r3,[r11],#2	
	strh 	r3,[r7,#0xD2]	@;DMA2CNT_H	
	ldrh  r3,[r11],#2
	strh 	r3,[r7,#0xDE]	@;DMA3CNT_H	
		
	mov 	r0,#0x00
	bl 		SetRampage		
	
	ldmfd	sp!,{r0-r12,PC}
	.ltorg		
	@;===================================================	
	@; 即时存档功能 - 将当前游戏状态保存到闪存卡
	@;===================================================	
call_Save:	
	adrl	r7,RTS_switch		@; 检查RTS功能是否启用
	ldr		r7,[r7]
	cmp 	r7,#1			@; RTS开关状态检查
	bne 	errorRTS		@; 如果未启用，显示错误信息
	
	@; 保存外部工作RAM (02000000-0203FFFF, 256KB)
	@; 分4个64KB页面保存，使用闪存卡页面切换
	mov		r8,#0x40   		@; 起始页面号: 0x40, 0x50, 0x60, 0x70
	mov   r9,#0x2000000		@; EWRAM起始地址
wram_2000000:
	mov 	r0,r8			@; 设置闪存卡页面
	bl 		SetRampage		@; 切换到指定页面	
	mov 	r0,#0x0E000000		@; 闪存卡存储区地址
	mov 	r1,r9			@; 源地址(EWRAM)
	mov		r2,#0x10000		@; 传输大小(64KB)
	bl 		WriteSram		@; 写入闪存卡
	add 	r8,#0x10		@; 下一个页面
	add 	r9,#0x10000		@; 下一段EWRAM地址
	cmp 	r8,#0x80		@; 检查是否完成所有页面	
	bne 	wram_2000000		@; 如果未完成，继续循环
	
	@; 保存内部工作RAM (03000000-03007FFF, 32KB)
	mov 	r0,#0x80		@; 切换到页面0x80
	bl 		SetRampage	
	mov r0,#0x0E000000		@; 闪存卡地址
	mov r1,#0x3000000		@; IWRAM地址
	mov r2,#0x8000			@; 大小: 32KB
	bl 	WriteSram		@; 写入闪存卡
	
	@; 保存调色板RAM (05000000-050003FF, 1KB)
	ldr r0,=0x0E008000		@; 闪存卡偏移地址
	mov r1,#0x5000000		@; 调色板RAM地址
	mov r2,#0x400			@; 大小: 1KB
	bl 	WriteSram		@; 写入调色板数据
	
	@; 保存视频RAM (06000000-06017FFF, 96KB)
	ldmfd	sp!,{r6}		@; 恢复显示控制寄存器
	ldr		r7,=0x4000000		@; I/O基地址
	strh 	r6,[r7] 		@; 恢复显示设置
	bl 		restore_LCD		@; 恢复LCD状态
		
	mov 	r0,#0x90		@; 切换到页面0x90
	bl 		SetRampage	
	mov r0,#0x0E000000		@; 闪存卡地址
	mov r1,#0x6000000		@; VRAM起始地址
	mov r2,#0x10000			@; 大小: 64KB
	bl 	WriteSram		@; 写入VRAM前半部分
	
	mov 	r0,#0xA0		@; 切换到页面0xA0
	bl 		SetRampage	
	mov r0,#0x0E000000		@; 闪存卡地址
	ldr r1,=0x6010000		@; VRAM后半部分地址
	mov r2,#0x8000			@; 大小: 32KB
	bl 	WriteSram		@; 写入VRAM后半部分
	
	@; 保存OAM精灵属性 (07000000-070003FF, 1KB)
	ldr r0,=0x0E008000		@; 闪存卡偏移地址
	mov r1,#0x7000000		@; OAM地址
	mov r2,#0x400			@; 大小: 1KB
	bl 	WriteSram		@; 写入OAM数据

	@;R4-R11
	mrs	  r0,CPSR    @;Back up
	adrl	r7, spend_0x80
	ldr		r7,[r7]
	add		r7,#0x30  @;{r4-r11,sp,lr} SPSR  0x28+4
		
	@ r0 = CPSR, R7 = 0x0203FE30
	mov		r1, #0xDF		@; Switch to systme Mode
	msr		cpsr_cf, r1
	NOP
	mov		r6,sp
	stmia r7!,{r6,lr}	
	@于系统模式下，将sp和lr寄存器的值存储到闪存卡的0x0203FE30地址处
	
	msr 	cpsr_cf,r0	;@return IRQ mode	
	NOP
	
	ldr 	r0,=0x0E008400
	adrl 	r1, spend_0x80
	ldr		r1,[r1]
	mov 	r2,#0x80
	bl 		WriteSram	
	
	@;04000000-040003FE   I/O Registers
	ldr r0,=0x0E009000
	mov r1,#0x4000000
	mov r2,#0x60					@;0x0-0x60
	bl 	WriteSram
	
	ldr 	r0,=0x0E009060
	adrl 	r1, spend_0x80
	ldr		r1,[r1] 
	add 	r1,#0x40	
	@;ldr 	r1,=0x2010000
	mov 	r2,#0x30   				@;0x60-0x90
	bl 		WriteSram		
	
	ldr r0,=0x0E009090
	mov r1,#0x4000000
	add r1,#0x90          @;0x90-0x3FE
	mov r2,#0x370
	bl 	WriteSram
	
	@;FLAG	
	ldr r0,=0x0E00FFF0
	adrl r1,S_RTS_FLAG
	mov r2,#0x10
	bl 	WriteSram	
		
	mov r7,#0x50000
delay_loop:
	cmp			r7,#0
	beq			save_exit	
	nop
	sub 		r7,#0x01
	b				delay_loop
	
	b save_exit	
	@;===================================================		
	@;===================================================	
	@; 即时读档功能 - 从闪存卡恢复保存的游戏状态
	@;===================================================	
call_Load:
	@; 验证存档文件完整性标志
	mov 	r0,#0xA0		@; 切换到页面0xA0
	bl 		SetRampage
	ldr 	r0,=0x0E00FFF0		@; 存档标志在闪存卡中的地址
	adrl 	r1, spend_0x80  	@; 临时缓冲区地址
	ldr 	r1,[r1]
	mov 	r2,#0x10		@; 标志长度16字节
	bl 		ReadSram		@; 读取存档标志
	
	@; 比较存档标志与预期值
	adrl 	r1,S_RTS_FLAG		@; 预期的RTS标志字符串地址
	adrl 	r2, spend_0x80 		@; 从闪存卡读取的标志地址
	ldr 	r2,[r2]
	mov 	r3,#0			@; 比较计数器
loop_check:
	ldr 	r4,[r1],#4		@; 读取预期标志的4字节
	ldr 	r5,[r2],#4		@; 读取实际标志的4字节
	cmp 	r4,r5			@; 比较是否匹配
	@;bne errorRTS		@; 如果不匹配，跳转错误处理(已注释)
	add 	r3,#1			@; 增加计数器
	cmp 	r3,#4			@; 检查是否完成4次比较(16字节)
	bne 	loop_check		@; 如果未完成，继续比较
	
	@;02000000-0203FFFF   WRAM - On-board Work RAM  (256 KBytes)
	mov		r8,#0x40   @; 0x40 0x50 0x60 0x70
	mov   r9,#0x2000000
wram_2000000_Load:
	mov 	r0,r8
	bl 		SetRampage	
	mov 	r0,#0x0E000000
	mov 	r1,r9
	mov		r2,#0x10000
	bl 		ReadSram
	add 	r8,#0x10
	add 	r9,#0x10000
	cmp 	r8,#0x80	
	bne 	wram_2000000_Load

	@;03000000-03007FFF   WRAM - On-chip Work RAM   (32 KBytes)
	mov 	r0,#0x80
	bl 		SetRampage	
	mov r0,#0x0E000000
	mov r1,#0x3000000
	mov r2,#0x8000
	bl 	ReadSram
	
	@;05000000-050003FF   BG/OBJ Palette RAM        (1 Kbyte)
	ldr r0,=0x0E008000
	mov r1,#0x5000000
	mov r2,#0x400
	bl 	ReadSram

	@;06000000-06017FFF   VRAM - Video RAM          (96 KBytes)
	mov 	r0,#0x90
	bl 		SetRampage	
	mov r0,#0x0E000000
	mov r1,#0x6000000
	mov r2,#0x10000
	bl 	ReadSram
	mov 	r0,#0xA0
	bl 		SetRampage	
	mov r0,#0x0E000000
	ldr r1,=0x6010000
	mov r2,#0x8000
	bl 	ReadSram
	
	@;07000000-070003FF   OAM - OBJ Attributes      (1 Kbyte)
	ldr r0,=0x0E008000
	mov r1,#0x7000000
	mov r2,#0x400
	bl 	ReadSram
	
	@;-------------------------------------
	mov r10,#0x4000000
	LDR r11,=0x0E009000
	
	adr r9,register_list
register_list_loop:
	ldrh r2,[r9],#2
	cmp r2 ,#0xFF00
	beq register_list_end

	add r0,r10,r2   @;0x4000000  0x4000002 0x4000004
	add r1,r11,r2
	bl  restore2_IO
	b 	register_list_loop
register_list_end:

	@;mov r10,#0x4000000
	LDR r11,=0x0E008500		
@;	add r0,r10,#0xBA  @;0x40000BA  DMA
@;	add r1,r11,#0x32
@;	bl  restore2_IO	
	add r0,r10,#0xC6  @;0x40000C6
	add r1,r11,#0x34
	bl  restore2_IO	
@;	add r0,r10,#0xD2  @;0x40000D2
@;	add r1,r11,#0x36
@;	bl  restore2_IO	
@;	add r0,r10,#0xDE  @;0x40000DE
@;	add r1,r11,#0x38
@;	bl  restore2_IO	
	
	@;mov   r4,#0x8F
	@;mov   r7,#0x4000000
	@;strh 	r4,[r7,#REG_SOUNDCNT_X]
	
	ldr r0,=0x4000202   @;0x4000202
	mov r1,#0
	strh r1,[r0]
	

	ldr 	r0,=0x0E008400
	adrl 	r1, spend_0x80 @;temp buff
	ldr		r1,[r1] 
	mov 	r2,#0x80
	bl 		ReadSram	
	
	mrs	  r0,CPSR
	adrl	r7, spend_0x80
	ldr		r7,[r7] 
	add		r7,#0x28      @;SPSR offset
	
	ldmia	r7!,{r2}			@;r7=0x2C
	msr		SPSR_cxsf,r2	@;restore SPSR_irq  

	mov		r1, #0xDF		  @;Switch to systme Mode
	msr		cpsr_cf, r1
	NOP
	add		r7,#0x4					@;offset 0x30
	ldmia r7!,{r13-r14}

	msr 	cpsr_cf,r0	  @;restore IRQ	
	NOP

	mov 	r0,#0x0
	bl 		SetRampage
	
	@;spin until VCOUNT==160, triggers next vblank
	mov 	r0,#0x4000000 
spin3_load:
	ldrh 	r1,[r0,#REG_VCOUNT]
	cmp 	r1,#160
	bne 	spin3_load  
	
	adrl	r12, spend_0x80
	ldr		r12,[r12] 
	ldmia r12!,{r4-r11,sp,lr}
	
	ldr 	pc,[r0,#-(0x04000000-0x03FFFFF4)] @;to normal IRQ routine		

	@;===================================================	
errorRTS:
	adrl  r8,s_badRTS
	mov		r9,#145	   @;Y
	mov		r10,#64    @;X
showerror:	
	ldrb	r0,[r8],#+1
	cmp		r0,#0x00
	beq		enderror
	mov		r1,r10
	add		r2,r9,#0
	mov	  r3,#0x1F  @;red
	bl		printchar    @; r0 char�� r1, X  �� r2, Y , r3 color
	add		r10,#8
	b			showerror
enderror:	
waitB:
	ldr		r0,=0x3FF		@;No key press
	ldr		r8,=0x4000130
	ldrh	r9,[r8]
	cmp		r9,r0
	beq		waitB	
pressB:
	mov		r12,r9
	ldrh	r9,[r8]
	cmp		r9,r0
	bne		pressB
	
	ldr		r0,=0x3FD		;@B 
	cmp		r12,r0
	moveq	r11,#5
	beq		b_pressed_quit
	b		waitB

	
	
	@;===================================================		
call_CheatON:
	mov r3,#1
set_Cheat:
	ADR r2,CheatONOFF
	ldr	r2,[r2]
	str r3,[r2]
	b b_pressed_quit
	@;===================================================		
call_CheatOFF:
	mov r3,#0
	b   set_Cheat

	
	.ltorg	
	@;--------------
CheatONOFF:	
	.word	 0x03007FE0
	@;===================================================	
draw_plot:
	MOV     R11, #0xF0
	MLA     R3, R1, R11, R0
	MOV     R3, R3,LSL#1
	ADD     R3, R3, #0x6000000
	STRH    R2, [R3]
	BX			LR
		@;===================================================	
printchar:	@; r0 ��ӡ���ַ��� r1, X  �� r2, Y , r3 ��ɫ
	STMFD   SP!, {R8-R11,LR}
	MOV     R8, R1
	MOV     R6, R2
	MOV     R9, R3
	MOV     R10, #0x80
	ADRL     R4, ASCII
	SUB     R0, R0, #0x41
	ADD     R4, R4, R0,LSL#4
	ADD     R7, R4, #0x10

loc_A0DD7C:                             
	MOV     R5, #0
loc_A0DD80:
	LDRB    R3, [R4]
	ANDS    R3, R3, R10,ASR R5
	MOVNE   R2, R9
	MOVNE   R1, R6
	ADDNE   R0, R5, R8
	BLNE    draw_plot
	ADD     R5, R5, #1
	CMP     R5, #8
	BNE     loc_A0DD80
	ADD     R4, R4, #1
	CMP     R4, R7
	ADD     R6, R6, #1
	BNE     loc_A0DD7C

	LDMFD   SP!, {R8-R11,PC}
	.align
register_list:
	.hword 0x0000,0x0002,0x0004,0x0008,0x000A,0x000C,0x000E,0x0048
	.hword 0x004A,0x0050,0x0052
	.hword 0x0084
	.hword 0x0060,0x0062,0x0068,0x0070,0x0072,0x0078
	.hword 0x0080,0x0082,0x0088                 @;0x008C,0x008E,
	.hword 0x0090,0x0092,0x0094,0x0096,0x0098,0x009A,0x009C,0x009E
	
	.hword 0x00B8,0x00C4,0x00D0,0x00DC  @;DMA
	.hword 0x0120,0x0122,0x0124,0x0126,0x0128,0x012A,0x012C,0x0132,0x0134
	.hword 0x0140,0x0150,0x0154,0x0200,0x0204,0x0208,0xFF00
	.align
@;------------------------------------------------	
ASCII:	
	.byte		0x00,0x00,0x10,0x38,0x6C,0xC6,0xC6,0xFE  @;// -A-
	.byte		0xC6,0xC6,0xC6,0xC6,0x00,0x00,0x00,0x00

	.byte		0x00,0x00,0xFC,0x66,0x66,0x66,0x7C,0x66  @;// -B-
	.byte		0x66,0x66,0x66,0xFC,0x00,0x00,0x00,0x00

	.byte		0x00,0x00,0x3C,0x66,0xC2,0xC0,0xC0,0xC0  @;// -C-
	.byte		0xC0,0xC2,0x66,0x3C,0x00,0x00,0x00,0x00

	.byte		0x00,0x00,0xF8,0x6C,0x66,0x66,0x66,0x66  @; // -D-
	.byte		0x66,0x66,0x6C,0xF8,0x00,0x00,0x00,0x00

	.byte		0x00,0x00,0xFE,0x66,0x62,0x68,0x78,0x68  @;// -E-
	.byte		0x60,0x62,0x66,0xFE,0x00,0x00,0x00,0x00

	.byte		0x00,0x00,0xFE,0x66,0x62,0x68,0x78,0x68  @;// -F-
	.byte		0x60,0x60,0x60,0xF0,0x00,0x00,0x00,0x00

	.byte		0x00,0x00,0x3C,0x66,0xC2,0xC0,0xC0,0xDE  @;// -G-
	.byte		0xC6,0xC6,0x66,0x3A,0x00,0x00,0x00,0x00

	.byte		0x00,0x00,0xC6,0xC6,0xC6,0xC6,0xFE,0xC6  @;// -H-
	.byte		0xC6,0xC6,0xC6,0xC6,0x00,0x00,0x00,0x00

	.byte		0x00,0x00,0x3C,0x18,0x18,0x18,0x18,0x18  @;// -I-
	.byte		0x18,0x18,0x18,0x3C,0x00,0x00,0x00,0x00

	.byte		0x00,0x00,0x1E,0x0C,0x0C,0x0C,0x0C,0x0C  @;// -J-
	.byte		0xCC,0xCC,0xCC,0x78,0x00,0x00,0x00,0x00

	.byte		0x00,0x00,0xE6,0x66,0x6C,0x6C,0x78,0x78  @;// -K-
	.byte		0x6C,0x66,0x66,0xE6,0x00,0x00,0x00,0x00

	.byte		0x00,0x00,0xF0,0x60,0x60,0x60,0x60,0x60  @;// -L-
	.byte		0x60,0x62,0x66,0xFE,0x00,0x00,0x00,0x00

	.byte		0x00,0x00,0xC6,0xEE,0xFE,0xFE,0xD6,0xC6  @;// -M-
	.byte		0xC6,0xC6,0xC6,0xC6,0x00,0x00,0x00,0x00

	.byte		0x00,0x00,0xC6,0xE6,0xF6,0xFE,0xDE,0xCE  @;// -N-
	.byte		0xC6,0xC6,0xC6,0xC6,0x00,0x00,0x00,0x00

	.byte		0x00,0x00,0x38,0x6C,0xC6,0xC6,0xC6,0xC6  @;// -O-
	.byte		0xC6,0xC6,0x6C,0x38,0x00,0x00,0x00,0x00

	.byte		0x00,0x00,0xFC,0x66,0x66,0x66,0x7C,0x60  @;// -P-
	.byte		0x60,0x60,0x60,0xF0,0x00,0x00,0x00,0x00

	.byte		0x00,0x00,0x7C,0xC6,0xC6,0xC6,0xC6,0xC6  @;// -Q-
	.byte		0xC6,0xD6,0xDE,0x7C,0x0C,0x0E,0x00,0x00

	.byte		0x00,0x00,0xFC,0x66,0x66,0x66,0x7C,0x6C  @;// -R-
	.byte		0x66,0x66,0x66,0xE6,0x00,0x00,0x00,0x00

	.byte		0x00,0x00,0x7C,0xC6,0xC6,0x60,0x38,0x0C  @;// -S-
	.byte		0x06,0xC6,0xC6,0x7C,0x00,0x00,0x00,0x00

	.byte		0x00,0x00,0x7E,0x7E,0x5A,0x18,0x18,0x18  @;// -T-
	.byte		0x18,0x18,0x18,0x3C,0x00,0x00,0x00,0x00

	.byte		0x00,0x00,0xC6,0xC6,0xC6,0xC6,0xC6,0xC6  @;// -U-
	.byte		0xC6,0xC6,0xC6,0x7C,0x00,0x00,0x00,0x00

	.byte		0x00,0x00,0xC6,0xC6,0xC6,0xC6,0xC6,0xC6 @;// -V-
	.byte		0xC6,0x6C,0x38,0x10,0x00,0x00,0x00,0x00
	
	.byte		0x00,0x00,0xC6,0xC6,0xC6,0xC6,0xC6,0xD6 @;// -W-
	.byte		0xD6,0xFE,0x6C,0x6C,0x00,0x00,0x00,0x00
	
	.byte		0x00,0x00,0xC6,0xC6,0x6C,0x6C,0x38,0x38  @;// -X-
	.byte		0x6C,0x6C,0xC6,0xC6,0x00,0x00,0x00,0x00

	.byte		0x00,0x00,0x66,0x66,0x66,0x66,0x3C,0x18  @;// -Y-
	.byte		0x18,0x18,0x18,0x3C,0x00,0x00,0x00,0x00

	.byte		0x00,0x00,0xFE,0xC6,0x86,0x0C,0x18,0x30  @;// -Z- 0x5A
	.byte		0x60,0xC2,0xC6,0xFE,0x00,0x00,0x00,0x00
	
	.align
@;------------------------------------------------------
@; 游戏内菜单文本定义
@;------------------------------------------------------
ingameMENU:
s_reset:
 	.byte  'R','E','S','E','T',0x0		@; "重启"菜单项
s_save:
 	.byte  'S','A','V','E',0x0		@; "存档"菜单项
s_load:
 	.byte  'L','O','A','D',0x0		@; "读档"菜单项
s_cheatON:
 	.byte  'C','H','E','A','T','O','N',0x0	@; "开启金手指"菜单项
s_cheatOFF:
 	.byte  'C','H','E','A','T','O','F','F',0x0	@; "关闭金手指"菜单项
	.byte  0xA5  			@; 菜单结束标志
	.align	
@;------------------------------------------------------
@; RTS存档完整性标志 - 用于验证存档文件有效性
@;------------------------------------------------------
S_RTS_FLAG:
 	.byte  'E','Z','-','O','m','e','g','a','R','T','C','F','I','L','E','.'
	.align	
@;------------------------------------------------------
@; 错误信息文本
@;------------------------------------------------------
s_badRTS:
 	.byte  'R','T','S','F','I','L','E','D','A','M','A','G','E','D',0x00	@; "RTS文件损坏"
	.align	
@;------------------------------------------------------
@; 全局变量定义
@;------------------------------------------------------
RTS_switch: 
	.word 0x00000000		@; RTS功能开关状态 (0=关闭, 1=开启)
Cheat_count:
	.word 0x00000000		@; 金手指条目数量	
no_CHEAT_end:				@; 无金手指模式结束标志
CHEAT:
	.space 0x400			@; 金手指数据存储区 (1024字节)
	.align
@;------------------------------------------------------
@; RTS补丁代码结束标志
@;------------------------------------------------------
RTS_ReplaceIRQ_end:
   .end
