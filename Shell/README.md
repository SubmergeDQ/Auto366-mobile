# Up366 答案提取工具 (Shell 版)

从 up366 移动应用的加密数据中解密并提取答案。

## 功能特性

- ✅ Root 权限检查
- ✅ 交互式目录导航和选择
- ✅ AES-128-CBC 解密 (u3enc 格式)
- ✅ 自动识别 pageConfig 结构
- ✅ 提取选择题、填空题等答案
- ✅ HTML 标签清理
- ✅ 结果保存为文本文件

## 使用前提

1. **Android 设备**（已 root 或已获取 root 权限）
2. **已安装 up366 应用**（优366/UP366）
3. **终端环境**：Termux 或其他支持 bash 的终端

## 快速使用

### 1. 传输脚本到手机

```bash
# 方法一：通过 ADB
adb push extract_up366.sh /sdcard/

# 方法二：通过 QQ/微信发送到手机文件管理器
```

### 2. 在手机上运行

```bash
# 进入 Termux 或终端模拟器
# 切换到 root
su

# 给脚本执行权限
chmod +x /path/to/extract_up366.sh

# 运行脚本
./extract_up366.sh
```

### 3. 按照提示操作

```
1. 脚本会自动检查 root 权限
2. 显示 flipbook 目录下的文件夹列表
3. 选择你要提取的课程/试卷文件夹
4. 继续选择子文件夹，直到找到包含 "1" 和 "2" 文件夹的目录
5. 脚本会自动解密并提取答案
6. 完成后显示输出文件路径
```

## 输出文件

答案文件保存在**脚本同目录**下，命名格式：
```
answers_YYYYMMDD_HHMMSS.txt
```

文件内容包括：
- 提取时间和源目录信息
- 从文件夹 "1" 和 "2" 中提取的所有答案
- 问题文本、选项、正确答案
- 处理统计信息

## 技术细节

### 加密格式 (u3enc)

```
┌─────────────┬──────────────────────────┐
│   IV (16B)  │  AES-128-CBC 密文        │
└─────────────┴──────────────────────────┘
```

- **算法**: AES-128-CBC
- **填充**: PKCS7
- **密钥**: `QJBNiBmV55PDrewyne3GsA==` (Base64)
- **IV**: 文件前 16 字节

### 解密流程

1. 读取 u3enc 文件前 16 字节作为 IV
2. 使用 AES-128-CBC 解密剩余数据
3. 解析解密后的 JavaScript (pageConfig)
4. 提取 questionObj 中的问题、选项、答案
5. 清理 HTML 标签和特殊字符
6. 格式化输出到文本文件

### 支持的题型

- **选择题**: 提取 question_text, options, answer_text
- **填空题**: 提取 questions_list, answers_list
- **听后回答**: 提取 record_speak 内容
- **复述题**: 提取 OriginalReference

## 常见问题

### Q: 提示 "需要 root 权限"
A: 请在 Termux 中输入 `su` 切换到 root 用户后再运行脚本。

### Q: 找不到 flipbook 目录
A: 确保：
  - 已安装 up366 应用
  - 已至少打开过一次应用（生成数据）
  - 有正确的文件系统访问权限

### Q: 解密失败
A: 可能原因：
  - 文件损坏或不完整
  - 应用版本更新导致加密方式变化
  - 权限不足无法读取文件

### Q: 提取的答案是乱码
A: 脚本会自动清理 HTML 标签，如果仍有乱码可能是编码问题。

## 依赖项

脚本依赖以下命令行工具（通常 Android/Termux 已内置）：

- `bash` - Shell 解释器
- `openssl` - AES 解密
- `xxd` - 十六进制转换
- `base64` - Base64 编解码
- `sed`, `awk`, `grep` - 文本处理

如缺少某些工具，可在 Termux 中安装：
```bash
pkg install openssl xxd coreutils
```

## 参考项目

- [ExtractUp366](../ExtractUp366/) - Python 版本
- [Auto366](../Auto366/) - Electron 桌面版

## 许可证

MIT License

---

**提示**: 如遇到问题，请检查：
1. Root 权限是否正常
2. up366 应用是否有缓存数据
3. 设备存储空间是否充足
