# UP366 Shell 脚本 - Python 环境安装指南

## 问题说明

Android 设备默认**没有安装 `openssl`**，导致 AES 解密失败。

## 解决方案

### 方案 A: 安装 Python + pycryptodome（推荐 ✅）

在 **Termux** 中执行：

```bash
# 1. 更新包管理器
pkg update && pkg upgrade -y

# 2. 安装 Python
pkg install python -y

# 3. 安装加密库
pip install pycryptodome

# 4. 验证安装
python --version
python -c "from Crypto.Cipher import AES; print('✓ pycryptodome OK')"
```

**预期输出：**
```
Python 3.x.x
✓ pycryptodome OK
```

安装完成后，重新运行 `extract_up366.sh` 即可！

---

### 方案 B: 仅安装 OpenSSL（备选）

```bash
# Termux 中安装 openssl
pkg install openssl -y

# 验证
openssl version
```

---

## 完整运行流程（方案A）

```bash
# 1. 进入 Termux
termux

# 2. 切换到 root
su

# 3. 安装依赖（首次运行需要）
pkg install python -y && pip install pycryptodome

# 4. 运行脚本
chmod +x /storage/emulated/0/Download/MiShare/extract_up366.sh
/storage/emulated/0/Download/MiShare/extract_up366.sh
```

**预期成功输出：**
```
========================================
   Up366 答案提取工具 (Shell版)
   v2.0 - 支持 OpenSSL/Python 双模式
========================================

[OK] Root 权限检查通过

检测解密工具...
[OK] 找到 Python3: Python 3.x.x
[OK] pycryptodome 库已安装

开始扫描目录...
...
    解密中 (python)... 成功!
    [OK] 格式正确
    [OK] 已提取

╔══════════════════════════════════════╗
║          ✅ 完成！                   ║
║  成功: 2  |  失败: 0                ║
║  答案: ~15 条                       ║
║  方式: python                       ║
╚══════════════════════════════════════╝
```

---

## 常见问题

### Q1: `pkg command not found`
**A:** 你可能不在 Termux 环境中。请确保从 Termux 应用启动终端。

### Q2: `pip: command not found`
**A:** 先执行 `pkg install python -y`，pip 会随 Python 一起安装。

### Q3: `pycryptodome` 安装失败
**A:** 尝试使用：
```bash
pip install pycryptodome --index-url https://pypi.org/simple/
```

### Q4: 已安装但仍提示 "未找到解密工具"
**A:** 检查路径：
```bash
which python3
which python
```
如果显示 `/data/data/com.termux/files/usr/bin/python3` 则正常。

---

## 技术细节

### 为什么需要 Python？

- Android 的 shell 环境**不包含** `openssl` 命令
- Python 的 `pycryptodome` 库提供纯 Python 的 AES 实现
- 无需系统级依赖，安装简单

### Python 解密流程

```
.u3enc 文件
   ↓ 读取二进制
[16字节 IV] + [AES-128-CBC 密文]
   ↓ Crypto.Cipher.AES.new(key, MODE_CBC, iv)
解密后的 JavaScript (pageConfig)
   ↓ 提取 question_text, answer_text
答案文本 (.txt)
```

---

## 对比表

| 特性 | OpenSSL | Python (pycryptodome) |
|------|---------|----------------------|
| 安装难度 | ⭐⭐ 简单 | ⭐⭐⭐ 需要两步 |
| 性能 | ⭐⭐⭐ 快 | ⭐⭐⭐ 同样快 |
| 兼容性 | ⭐⭐ 需额外安装 | ⭐⭐⭐ 跨平台 |
| 依赖大小 | ~2MB | ~20MB (含Python) |
| 推荐度 | ✅ 有则优先用 | ✅ 默认推荐 |

---

## 下一步

安装完 Python 后，直接运行 `extract_up366.sh v2.0` 即可！
