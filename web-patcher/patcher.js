// GBA RTS Patcher Web版 - 主要逻辑
class GBAPatcher {
    constructor() {
        this.romData = null;
        this.rtsData = null;
        this.romFileName = '';
        this.rtsFileName = '';
        this.detectedSaveSize = 0x20000; // 默认128KB
        this.saveTypeInfo = '';

        // 存档函数签名（从patcher.c移植）
        this.signatures = {
            write_sram: [0x30, 0xB5, 0x05, 0x1C, 0x0C, 0x1C, 0x13, 0x1C, 0x0B, 0x4A, 0x10, 0x88, 0x0B, 0x49, 0x08, 0x40],
            write_sram2: [0x80, 0xb5, 0x83, 0xb0, 0x6f, 0x46, 0x38, 0x60, 0x79, 0x60, 0xba, 0x60, 0x09, 0x48, 0x09, 0x49],
            write_sram_ram: [0x04, 0xC0, 0x90, 0xE4, 0x01, 0xC0, 0xC1, 0xE4, 0x2C, 0xC4, 0xA0, 0xE1, 0x01, 0xC0, 0xC1, 0xE4],
            write_eeprom: [0x70, 0xB5, 0x00, 0x04, 0x0A, 0x1C, 0x40, 0x0B, 0xE0, 0x21, 0x09, 0x05, 0x41, 0x18, 0x07, 0x31, 0x00, 0x23, 0x10, 0x78],
            write_flash: [0x70, 0xB5, 0x00, 0x03, 0x0A, 0x1C, 0xE0, 0x21, 0x09, 0x05, 0x41, 0x18, 0x01, 0x23, 0x1B, 0x03],
            write_flash2: [0x7C, 0xB5, 0x90, 0xB0, 0x00, 0x03, 0x0A, 0x1C, 0xE0, 0x21, 0x09, 0x05, 0x09, 0x18, 0x01, 0x23],
            write_flash3: [0xF0, 0xB5, 0x90, 0xB0, 0x0F, 0x1C, 0x00, 0x04, 0x04, 0x0C, 0x03, 0x48, 0x00, 0x68, 0x40, 0x89],
            write_eepromv111: [0x0A, 0x88, 0x80, 0x21, 0x09, 0x06, 0x0A, 0x43, 0x02, 0x60, 0x07, 0x48, 0x00, 0x47, 0x00, 0x00]
        };

        this.initEventListeners();
    }

    initEventListeners() {
        const romFile = document.getElementById('romFile');
        const rtsFile = document.getElementById('rtsFile');
        const patchButton = document.getElementById('patchButton');

        if (!romFile || !rtsFile || !patchButton) {
            console.error('无法找到必要的DOM元素');
            return;
        }

        romFile.addEventListener('change', (e) => this.handleRomFile(e));
        rtsFile.addEventListener('change', (e) => this.handleRtsFile(e));
        patchButton.addEventListener('click', () => this.startPatching());

        console.log('事件监听器已初始化');
    }

    resetState() {
        // 重置数据状态
        this.detectedSaveSize = 0x20000; // 默认128KB
        this.saveTypeInfo = '';

        // 重置UI状态
        // 隐藏配置区域
        const configSection = document.getElementById('configSection');
        if (configSection) {
            configSection.style.display = 'none';
        }

        // 隐藏检测信息
        const detectedInfo = document.getElementById('detectedInfo');
        if (detectedInfo) {
            detectedInfo.style.display = 'none';
        }

        // 隐藏操作区域
        const actionSection = document.getElementById('actionSection');
        if (actionSection) {
            actionSection.style.display = 'none';
        }

        // 隐藏进度区域
        const progressSection = document.getElementById('progressSection');
        if (progressSection) {
            progressSection.style.display = 'none';
        }

        // 隐藏结果区域
        const resultSection = document.getElementById('resultSection');
        if (resultSection) {
            resultSection.style.display = 'none';
        }

        // 重置进度条
        const progressFill = document.getElementById('progressFill');
        const progressText = document.getElementById('progressText');
        if (progressFill) {
            progressFill.style.width = '0%';
        }
        if (progressText) {
            progressText.textContent = '准备中...';
        }

        // 清空日志
        const logOutput = document.getElementById('logOutput');
        if (logOutput) {
            logOutput.innerHTML = '';
        }

        // 重新启用补丁按钮
        const patchButton = document.getElementById('patchButton');
        if (patchButton) {
            patchButton.disabled = false;
        }

        // 重置配置值为默认值
        const wbufSize = document.getElementById('wbufSize');
        const sectorSize = document.getElementById('sectorSize');
        if (wbufSize) {
            wbufSize.value = '512';
        }
        if (sectorSize) {
            sectorSize.value = '0x10000';
        }

        console.log('状态已重置');
    }

    resetProgressAndResults() {
        // 重置进度条
        const progressFill = document.getElementById('progressFill');
        const progressText = document.getElementById('progressText');
        if (progressFill) {
            progressFill.style.width = '0%';
        }
        if (progressText) {
            progressText.textContent = '准备中...';
        }

        // 清空日志
        const logOutput = document.getElementById('logOutput');
        if (logOutput) {
            logOutput.innerHTML = '';
        }

        // 隐藏结果区域
        const resultSection = document.getElementById('resultSection');
        if (resultSection) {
            resultSection.style.display = 'none';
        }

        console.log('进度和结果已重置');
    }

    async handleRomFile(event) {
        const file = event.target.files[0];
        if (!file) return;

        console.log('选择的ROM文件:', file.name, '大小:', file.size);

        // 重置状态和UI
        this.resetState();

        if (!file.name.toLowerCase().endsWith('.gba')) {
            this.showError('请选择 .gba 格式的ROM文件');
            return;
        }

        try {
            this.romData = new Uint8Array(await file.arrayBuffer());
            this.romFileName = file.name;

            console.log('ROM文件读取成功，数据长度:', this.romData.length);

            // 更新UI显示
            const label = event.target.closest('.file-label');
            if (label) {
                label.classList.add('has-file');
                const textSpan = label.querySelector('span:nth-child(2)'); // 第二个span元素
                if (textSpan) {
                    textSpan.textContent = `已选择: ${file.name}`;
                } else {
                    console.warn('未找到文本显示span元素');
                }
            } else {
                console.warn('未找到文件标签元素');
            }

            // 验证ROM并检测存档类型
            this.validateRom();
            this.detectSaveType();

            // 显示配置区域
            const configSection = document.getElementById('configSection');
            if (configSection) {
                configSection.style.display = 'block';
                configSection.classList.add('fade-in');
            }

        } catch (error) {
            this.showError('读取ROM文件失败: ' + error.message);
        }
    }

    async handleRtsFile(event) {
        const file = event.target.files[0];
        if (!file) {
            this.rtsData = null;
            this.rtsFileName = '';
            // 重置UI显示
            const label = event.target.closest('.file-label');
            if (label) {
                label.classList.remove('has-file');
                const textSpan = label.querySelector('span:nth-child(2)');
                if (textSpan) {
                    textSpan.textContent = '选择 RTS 存档文件 (.rts) - 可选';
                }
            }

            // 如果之前有结果，需要重置结果区域（因为RTS状态改变了）
            const resultSection = document.getElementById('resultSection');
            if (resultSection && resultSection.style.display !== 'none') {
                resultSection.style.display = 'none';
                console.log('RTS文件已清除，结果区域已重置');
            }
            return;
        }

        if (!file.name.toLowerCase().endsWith('.rts')) {
            this.showError('请选择 .rts 格式的存档文件');
            return;
        }

        const RTS_SIZE = 448 * 1024; // 448KB
        if (file.size !== RTS_SIZE) {
            this.showError(`RTS文件大小必须为 ${RTS_SIZE} 字节，当前为 ${file.size} 字节`);
            return;
        }

        try {
            this.rtsData = new Uint8Array(await file.arrayBuffer());
            this.rtsFileName = file.name;

            // 更新UI显示
            const label = event.target.closest('.file-label');
            if (label) {
                label.classList.add('has-file');
                const textSpan = label.querySelector('span:nth-child(2)'); // 第二个span元素
                if (textSpan) {
                    textSpan.textContent = `已选择: ${file.name}`;
                }
            }
        } catch (error) {
            this.showError('读取RTS文件失败: ' + error.message);
        }
    }

    validateRom() {
        const signature = "<3 from Maniac";
        const signatureBytes = new TextEncoder().encode(signature);

        // 检查ROM是否已经打过补丁
        if (this.findBytes(this.romData, signatureBytes) !== -1) {
            throw new Error('ROM已经打过补丁了！');
        }

        // 检查ROM大小
        if (this.romData.length > 32 * 1024 * 1024) {
            throw new Error('ROM文件过大，不是有效的GBA ROM');
        }

        this.log('ROM验证通过');
    }

    detectSaveType() {
        this.log('正在扫描ROM以检测存档类型...');

        let foundSaveFunction = false;

        // 扫描ROM寻找存档函数签名
        for (let i = 0; i < this.romData.length - 64; i += 2) {
            // 检测SRAM写函数
            if (this.matchSignatureAt(i, this.signatures.write_sram) ||
                this.matchSignatureAt(i, this.signatures.write_sram2) ||
                this.matchSignatureAt(i, this.signatures.write_sram_ram)) {
                this.detectedSaveSize = 0x8000; // 32KB SRAM
                this.saveTypeInfo = `SRAM存档函数 (偏移: 0x${i.toString(16)}) - 存档大小: 32KB`;
                foundSaveFunction = true;
                break;
            }
            // 检测EEPROM写函数
            else if (this.matchSignatureAt(i, this.signatures.write_eeprom) ||
                this.matchSignatureAt(i, this.signatures.write_eepromv111)) {
                this.detectedSaveSize = 0x2000; // 8KB EEPROM
                this.saveTypeInfo = `EEPROM存档函数 (偏移: 0x${i.toString(16)}) - 存档大小: 8KB`;
                foundSaveFunction = true;
                break;
            }
            // 检测Flash写函数
            else if (this.matchSignatureAt(i, this.signatures.write_flash) ||
                this.matchSignatureAt(i, this.signatures.write_flash2)) {
                this.detectedSaveSize = 0x10000; // 64KB Flash
                this.saveTypeInfo = `Flash存档函数 (偏移: 0x${i.toString(16)}) - 存档大小: 64KB`;
                foundSaveFunction = true;
                break;
            }
            // 检测Flash 128KB写函数
            else if (this.matchSignatureAt(i, this.signatures.write_flash3)) {
                this.detectedSaveSize = 0x20000; // 128KB Flash
                this.saveTypeInfo = `Flash存档函数 (偏移: 0x${i.toString(16)}) - 存档大小: 128KB`;
                foundSaveFunction = true;
                break;
            }
        }

        if (!foundSaveFunction) {
            this.saveTypeInfo = '未检测到存档函数签名，使用默认大小: 128KB';
            this.log('未检测到存档函数签名，使用默认大小');
        } else {
            this.log(this.saveTypeInfo);
        }

        // 显示检测信息
        const detectedInfo = document.getElementById('detectedInfo');
        const saveTypeInfo = document.getElementById('saveTypeInfo');
        saveTypeInfo.innerHTML = `
            <p><strong>检测结果:</strong> ${this.saveTypeInfo}</p>
            <p><strong>存档大小:</strong> ${this.detectedSaveSize / 1024} KB (0x${this.detectedSaveSize.toString(16)})</p>
        `;
        detectedInfo.style.display = 'block';

        // 显示开始按钮
        document.getElementById('actionSection').style.display = 'block';
        document.getElementById('actionSection').classList.add('fade-in');
    }

    matchSignatureAt(offset, signature) {
        if (offset + signature.length > this.romData.length) return false;

        for (let i = 0; i < signature.length; i++) {
            if (this.romData[offset + i] !== signature[i]) {
                return false;
            }
        }
        return true;
    }

    findBytes(haystack, needle) {
        for (let i = 0; i <= haystack.length - needle.length; i += 4) {
            let match = true;
            for (let j = 0; j < needle.length; j++) {
                if (haystack[i + j] !== needle[j]) {
                    match = false;
                    break;
                }
            }
            if (match) return i;
        }
        return -1;
    }

    async startPatching() {
        if (!this.romData) {
            this.showError('请先选择ROM文件');
            return;
        }

        try {
            // 重置进度和结果区域
            this.resetProgressAndResults();

            // 显示进度区域
            document.getElementById('progressSection').style.display = 'block';
            document.getElementById('progressSection').classList.add('fade-in');

            // 禁用按钮
            document.getElementById('patchButton').disabled = true;

            await this.performPatching();

        } catch (error) {
            this.showError('打补丁过程中发生错误: ' + error.message);
            document.getElementById('patchButton').disabled = false;
        }
    }

    async performPatching() {
        this.updateProgress(10, '准备打补丁...');

        // 获取配置参数
        const wbufSize = parseInt(document.getElementById('wbufSize').value) || 0;
        const sectorSizeStr = document.getElementById('sectorSize').value;
        const sectorSize = parseInt(sectorSizeStr);

        this.log(`配置参数: 写缓冲区=${wbufSize}, 扇区大小=${sectorSizeStr}`);

        // 复制ROM数据以进行修改
        let patchedRom = new Uint8Array(this.romData);
        let romSize = patchedRom.length;

        this.updateProgress(20, '检查ROM对齐...');

        // 检查ROM是否256KB对齐，如果不是则补齐
        if (romSize & 0x3ffff) {
            this.log('ROM大小未对齐，正在补齐到256KB边界');
            romSize &= ~0x3ffff;
            romSize += 0x40000;
            const alignedRom = new Uint8Array(romSize);
            alignedRom.set(patchedRom);
            // 其余部分保持为0
            patchedRom = alignedRom;
        }

        this.updateProgress(30, '查找并修改IRQ处理器地址引用...');

        // 查找并替换IRQ handler地址引用
        const oldIrqAddr = new Uint8Array([0xfc, 0x7f, 0x00, 0x03]);
        const newIrqAddr = new Uint8Array([0xf4, 0x7f, 0x00, 0x03]);
        let foundIrq = 0;

        for (let i = 0; i < romSize - 4; i += 4) {
            let match = true;
            for (let j = 0; j < 4; j++) {
                if (patchedRom[i + j] !== oldIrqAddr[j]) {
                    match = false;
                    break;
                }
            }
            if (match) {
                foundIrq++;
                this.log(`找到IRQ处理器地址引用，偏移: 0x${i.toString(16)}`);
                for (let j = 0; j < 4; j++) {
                    patchedRom[i + j] = newIrqAddr[j];
                }
            }
        }

        if (foundIrq === 0) {
            throw new Error('未找到IRQ处理器地址引用，ROM可能已经打过补丁');
        }

        this.updateProgress(50, '计算payload位置...');

        // 计算所需的保留空间
        const reservedSpace = this.calculateReservedSpace(sectorSize);

        // 查找插入payload的位置
        const payloadLength = getPayloadLength();
        if (payloadLength === 0) {
            throw new Error('Payload数据未加载，请确保已生成payload二进制文件');
        }

        const payloadBase = this.findPayloadLocation(patchedRom, romSize, reservedSpace, payloadLength);

        // 如果需要扩展ROM
        if (payloadBase < 0) {
            this.log('ROM空间不足，正在扩展ROM');
            if (romSize + reservedSpace > 32 * 1024 * 1024) {
                throw new Error('ROM已达到最大大小，无法扩展');
            }

            romSize += reservedSpace;
            const expandedRom = new Uint8Array(romSize);
            expandedRom.set(patchedRom);
            patchedRom = expandedRom;

            const newPayloadBase = romSize - reservedSpace - payloadLength;
            this.log(`ROM已扩展，Payload位置: 0x${newPayloadBase.toString(16)}`);
        }

        this.updateProgress(70, '安装payload...');

        const finalPayloadBase = payloadBase >= 0 ? payloadBase : romSize - reservedSpace - payloadLength;

        // 复制payload数据
        const payloadData = new Uint8Array(getPayloadData());
        patchedRom.set(payloadData, finalPayloadBase);

        this.log(`Payload已安装，位置: 0x${finalPayloadBase.toString(16)}`);
        this.log(`Payload ROM地址: 0x${(0x08000000 + finalPayloadBase).toString(16)}`);

        this.updateProgress(80, '更新payload配置...');

        // 更新payload header
        this.updatePayloadConfiguration(patchedRom, finalPayloadBase, reservedSpace, wbufSize);

        this.updateProgress(90, '修改ROM入口点...');

        // 修改ROM入口点
        this.updateRomEntrypoint(patchedRom, finalPayloadBase);

        // 如果有RTS文件，嵌入到ROM中
        if (this.rtsData) {
            this.updateProgress(95, '嵌入RTS存档文件...');
            const sramSaveBase = finalPayloadBase + payloadLength;
            patchedRom.set(this.rtsData, sramSaveBase);
            this.log(`RTS文件已嵌入，位置: 0x${sramSaveBase.toString(16)}`);
        }

        this.updateProgress(100, '补丁完成！');

        // 显示结果
        this.showResult(patchedRom, finalPayloadBase, reservedSpace, wbufSize);
    }

    calculateReservedSpace(sectorSize) {
        let reservedSpace = 0x70000; // 448KB
        reservedSpace += this.detectedSaveSize;

        if (reservedSpace % sectorSize) {
            reservedSpace -= reservedSpace % sectorSize;
            reservedSpace += sectorSize;
            this.log(`保留空间已对齐到扇区边界: 0x${reservedSpace.toString(16)}`);
        }

        return reservedSpace;
    }

    findPayloadLocation(rom, romSize, reservedSpace, payloadLength) {
        for (let payloadBase = romSize - reservedSpace - payloadLength; payloadBase >= 0; payloadBase -= 0x40000) {
            let isAllZeroes = true;
            let isAllOnes = true;

            for (let i = 0; i < reservedSpace + payloadLength; i++) {
                if (rom[payloadBase + i] !== 0) {
                    isAllZeroes = false;
                }
                if (rom[payloadBase + i] !== 0xFF) {
                    isAllOnes = false;
                }
            }

            if (isAllZeroes || isAllOnes) {
                return payloadBase;
            }
        }

        return -1; // 需要扩展ROM
    }

    updatePayloadConfiguration(rom, payloadBase, reservedSpace, wbufSize) {
        // 更新payload header中的配置
        const payloadView = new DataView(rom.buffer, rom.byteOffset + payloadBase);

        // 解析原始入口点
        const originalEntrypointOffset = rom[0] | (rom[1] << 8) | (rom[2] << 16);
        const originalEntrypoint = 0x08000000 + 8 + (originalEntrypointOffset << 2);

        // 使用正确的PAYLOAD_HEADER_OFFSETS更新各个字段
        payloadView.setUint32(PAYLOAD_HEADER_OFFSETS.original_entrypoint, originalEntrypoint, true);
        payloadView.setUint32(PAYLOAD_HEADER_OFFSETS.rts_size, reservedSpace, true);
        payloadView.setUint32(PAYLOAD_HEADER_OFFSETS.save_size, this.detectedSaveSize, true);
        payloadView.setUint32(PAYLOAD_HEADER_OFFSETS.wbuf_size, wbufSize, true);

        this.log(`Payload配置已更新:`);
        this.log(`  原始入口点: 0x${originalEntrypoint.toString(16)}`);
        this.log(`  保留空间: ${reservedSpace / 1024} KB`);
        this.log(`  存档大小: ${this.detectedSaveSize / 1024} KB`);
        this.log(`  写缓冲区: ${wbufSize} 字节`);
    }

    updateRomEntrypoint(rom, payloadBase) {
        // 检查入口点指令
        if (rom[3] !== 0xea) {
            throw new Error('意外的入口点指令格式');
        }

        // 计算新入口点地址（需要根据实际payload结构调整）
        // 这里假设patched_entrypoint在payload开始处
        const newEntrypointAddress = 0x08000000 + payloadBase + 16; // 跳过header

        // 修改ROM入口跳转指令
        const jumpOffset = (newEntrypointAddress - 0x08000008) >> 2;
        const jumpInstruction = 0xea000000 | (jumpOffset & 0x00ffffff);

        const view = new DataView(rom.buffer, rom.byteOffset);
        view.setUint32(0, jumpInstruction, true);

        this.log(`ROM入口点已修改，跳转到: 0x${newEntrypointAddress.toString(16)}`);
    }

    showResult(patchedRom, payloadBase, reservedSpace, wbufSize) {
        // 生成输出文件名
        const baseName = this.romFileName.replace(/\.gba$/i, '');
        const outputFileName = `${baseName}_rts_keypad_wb${wbufSize}.gba`;

        // 显示结果信息
        const resultInfo = document.getElementById('resultInfo');
        resultInfo.innerHTML = `
            <h4>补丁信息</h4>
            <ul>
                <li><span class="highlight">输出文件:</span> ${outputFileName}</li>
                <li><span class="highlight">Payload位置:</span> 0x${payloadBase.toString(16)} (ROM地址: 0x${(0x08000000 + payloadBase).toString(16)})</li>
                <li><span class="highlight">保留空间:</span> ${reservedSpace / 1024} KB</li>
                <li><span class="highlight">存档大小:</span> ${this.detectedSaveSize / 1024} KB</li>
                <li><span class="highlight">写缓冲区:</span> ${wbufSize} 字节</li>
                <li><span class="highlight">最终ROM大小:</span> ${(patchedRom.length / 1024).toFixed(0)} KB</li>
                ${this.rtsData ? '<li><span class="highlight">RTS存档:</span> 已嵌入</li>' : ''}
            </ul>
        `;

        // 准备下载
        const blob = new Blob([patchedRom], { type: 'application/octet-stream' });
        const url = URL.createObjectURL(blob);

        const downloadButton = document.getElementById('downloadButton');
        downloadButton.style.display = 'block';
        downloadButton.onclick = () => {
            const a = document.createElement('a');
            a.href = url;
            a.download = outputFileName;
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
        };

        // 显示结果区域
        document.getElementById('resultSection').style.display = 'block';
        document.getElementById('resultSection').classList.add('fade-in');

        this.log(`补丁完成！输出文件: ${outputFileName}`);
    }

    updateProgress(percent, text) {
        document.getElementById('progressFill').style.width = percent + '%';
        document.getElementById('progressText').textContent = text;
    }

    log(message) {
        const logOutput = document.getElementById('logOutput');
        const timestamp = new Date().toLocaleTimeString();
        // 使用<br>标签进行换行，而不是\n
        logOutput.innerHTML += `[${timestamp}] ${message}<br>`;
        logOutput.scrollTop = logOutput.scrollHeight;
        console.log(message);
    }

    showError(message) {
        console.error('错误:', message);
        alert('错误: ' + message);

        // 添加错误日志到页面
        const logOutput = document.getElementById('logOutput');
        if (logOutput) {
            const timestamp = new Date().toLocaleTimeString();
            logOutput.innerHTML += `<span style="color: #ff6b6b;">[${timestamp}] 错误: ${message}</span><br>`;
            logOutput.scrollTop = logOutput.scrollHeight;
        }
    }
}

// 初始化应用
document.addEventListener('DOMContentLoaded', () => {
    console.log('DOM已加载');

    // 检查payload数据是否加载
    try {
        const payloadLength = getPayloadLength();
        console.log('Payload数据已加载，长度:', payloadLength);
    } catch (error) {
        console.error('Payload数据加载失败:', error.message);
    }

    // 检查关键DOM元素
    const requiredElements = ['romFile', 'rtsFile', 'patchButton', 'configSection', 'progressSection', 'resultSection'];
    const missingElements = [];

    requiredElements.forEach(id => {
        const element = document.getElementById(id);
        if (!element) {
            missingElements.push(id);
        }
    });

    if (missingElements.length > 0) {
        console.error('缺少DOM元素:', missingElements);
    } else {
        console.log('所有必需的DOM元素都存在');
    }

    // 初始化patcher
    window.patcher = new GBAPatcher();
});
