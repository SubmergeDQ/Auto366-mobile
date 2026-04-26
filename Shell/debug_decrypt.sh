#!/system/bin/sh

# Up366 解密诊断工具
# 用于诊断 page1.js.u3enc 文件和解密参数

SELECTED_PATH=""
AES_KEY="QJBNiBmV55PDrewyne3GsA=="
TEMP_PREFIX="/tmp/up366_debug_$$"

echo "========================================"
echo "   UP366 解密诊断工具"
echo "========================================"
echo ""

# ========== 权限检查 ==========
if [ "$(id -u)" -ne 0 ]; then
    echo "[错误] 需要 root 权限"
    exit 1
fi
echo "[OK] Root 权限通过"

# ========== 让用户选择 u3enc 文件 ==========
select_u3enc_file() {
    echo ""
    echo "请输入要诊断的 page1.js.u3enc 文件的完整路径:"
    echo "例如: /data/data/com.up366.mobile/files/flipbook/.../1/page1.js.u3enc"
    echo ""
    echo -n ">> 路径: "
    read filepath

    if [ ! -f "$filepath" ]; then
        echo "[错误] 文件不存在: $filepath"
        return 1
    fi

    SELECTED_PATH="$filepath"
    return 0
}

# 选择文件
if ! select_u3enc_file; then
    exit 1
fi

U3ENC_FILE="$SELECTED_PATH"

echo ""
echo "========================================"
echo "  文件信息"
echo "========================================"

# 显示文件大小
file_size=$(wc -c < "$U3ENC_FILE" 2>/dev/null)
echo "文件路径: $U3ENC_FILE"
echo "文件大小: $file_size 字节 ($(echo "$file_size" | awk '{printf "%.1f KB", $1/1024}') )"

# 显示前64字节的十六进制（用于分析格式）
echo ""
echo "========================================"
echo "  文件头部 (前64字节 Hex)"
echo "========================================"
head -c 64 "$U3ENC_FILE" | xxd | head -4

echo ""
echo "========================================"
echo "  密钥信息"
echo "========================================"
echo "Base64密钥: $AES_KEY"
key_hex=$(printf "%s" "$AES_KEY" | base64 -d 2>/dev/null | xxd -p | tr -d '\n')
echo "Hex密钥: $key_hex"
echo "密钥长度: $(echo -n "$key_hex" | wc -c) 个十六进制字符 ($(($(echo -n "$key_hex" | wc -c) / 2)) 字节)"

# 提取 IV
echo ""
echo "========================================"
echo "  IV (初始化向量)"
echo "========================================"
iv_hex=$(head -c 16 "$U3ENC_FILE" | xxd -p | tr -d '\n')
echo "IV (Hex): $iv_hex"
echo "IV 长度: $(echo -n "$iv_hex" | wc -c) 个字符 (应为32)"

# 密文部分
echo ""
echo "========================================"
echo "  密文部分"
echo "========================================"
cipher_size=$((file_size - 16))
echo "密文大小: $cipher_size 字节"
echo "密文开头 (前32字节):"
tail -c +17 "$U3ENC_FILE" | head -c 32 | xxd

# ========== 尝试多种解密方式 ==========
echo ""
echo "========================================"
echo "  解密测试"
echo "========================================"

decrypted_file="${TEMP_PREFIX}_test.bin"

# 方法1: 标准方式（当前使用的方式）
echo ""
echo "[测试1] 标准 AES-128-CBC 解密..."
echo "  参数: IV=前16字节, Key=$AES_KEY"
if tail -c +17 "$U3ENC_FILE" | openssl enc -aes-128-cbc -d \
    -K "$key_hex" \
    -iv "$iv_hex" \
    -nosalt \
    -out "$decrypted_file" 2>/dev/null; then
    if [ -s "$decrypted_file" ]; then
        echo "  结果: ✓ 成功!"
        echo "  解密后大小: $(wc -c < "$decrypted_file") 字节"
        echo "  内容预览 (前200字符):"
        head -c 200 "$decrypted_file" | strings | head -5
        rm -f "$decrypted_file"
    else
        echo "  结果: ✗ 失败 (输出文件为空)"
    fi
else
    echo "  结果: ✗ OpenSSL 返回错误"
    # 显示详细错误
    tail -c +17 "$U3ENC_FILE" | openssl enc -aes-128-cbc -d \
        -K "$key_hex" \
        -iv "$iv_hex" \
        -nosalt 2>&1 | head -3
fi

# 方法2: 尝试不跳过前16字节（整个文件作为密文）
echo ""
echo "[测试2] 整个文件作为密文 (无IV前缀)..."
if openssl enc -aes-128-cbc -d \
    -in "$U3ENC_FILE" \
    -K "$key_hex" \
    -iv "$iv_hex" \
    -nosalt \
    -out "$decrypted_file" 2>/dev/null; then
    if [ -s "$decrypted_file" ]; then
        echo "  结果: ✓ 成功!"
        echo "  解密后大小: $(wc -c < "$decrypted_file") 字节"
        echo "  内容预览:"
        head -c 200 "$decrypted_file" | strings | head -5
        rm -f "$decrypted_file"
    else
        echo "  结果: ✗ 失败 (输出为空)"
    fi
else
    echo "  结果: ✗ 失败"
fi

# 方法3: 使用全零IV
echo ""
echo "[测试3] 使用全零 IV (00000000000000000000000000000000)..."
zero_iv="00000000000000000000000000000000"
if tail -c +17 "$U3ENC_FILE" | openssl enc -aes-128-cbc -d \
    -K "$key_hex" \
    -iv "$zero_iv" \
    -nosalt \
    -out "$decrypted_file" 2>/dev/null; then
    if [ -s "$decrypted_file" ]; then
        echo "  结果: ✓ 成功!"
        echo "  内容预览:"
        head -c 200 "$decrypted_file" | strings | head -5
        rm -f "$decrypted_file"
    else
        echo "  结果: ✗ 失败"
    fi
else
    echo "  结果: ✗ 失败"
fi

# 方法4: 尝试 AES-256-CBC
echo ""
echo "[测试4] 尝试 AES-256-CBC (可能是256位密钥)..."
if tail -c +17 "$U3ENC_FILE" | openssl enc -aes-256-cbc -d \
    -K "${key_hex}${key_hex}" \
    -iv "$iv_hex" \
    -nosalt \
    -out "$decrypted_file" 2>/dev/null; then
    if [ -s "$decrypted_file" ]; then
        echo "  结果: ✓ 成功!"
        echo "  内容预览:"
        head -c 200 "$decrypted_file" | strings | head -5
        rm -f "$decrypted_file"
    else
        echo "  结果: ✗ 失败"
    fi
else
    echo "  结果: ✗ 失败"
fi

# 方法5: 检查是否是 gzip 压缩
echo ""
echo "[测试5] 检查是否是压缩文件..."
file_type=$(file "$U3ENC_FILE" 2>/dev/null)
echo "  file命令识别: $file_type"

# 检查 magic bytes
magic_bytes=$(head -c 4 "$U3ENC_FILE" | xxd -p)
echo "  Magic Bytes: $magic_bytes"
case "$magic_bytes" in
    89504e47*) echo "  → 这是 PNG 图片文件!";;
    504b0304*) echo "  → 这是 ZIP 压缩包!";;
    1f8b*)     echo "  → 这是 GZIP 压缩文件!";;
    7f454c46*) echo "  → 这是 ELF 二进制文件!";;
    *)         echo "  → 未知的文件格式";;
esac

# 最终建议
echo ""
echo "========================================"
echo "  诊断总结与建议"
echo "========================================"

# 检查 OpenSSL 版本
openssl_version=$(openssl version 2>/dev/null)
echo "OpenSSL版本: $openssl_version"

echo ""
echo "如果所有解密方法都失败，可能的原因:"
echo "  1. 应用使用了不同的加密密钥（版本更新）"
echo "  2. 加密算法不是标准的 AES-128-CBC"
echo "  3. 文件可能有额外的封装层"
echo "  4. 密钥可能需要从其他地方获取"
echo ""
echo "建议操作:"
echo "  1. 将此诊断结果反馈给开发者"
echo "  2. 检查 Auto366 桌面版是否能正常解密相同文件"
echo "  3. 如果桌面版可以，对比两者的解密流程"

# 清理
rm -f ${TEMP_PREFIX}_* 2>/dev/null

echo ""
echo "诊断完成！"
