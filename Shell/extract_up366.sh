#!/system/bin/sh

# Up366 答案提取脚本 - Shell 版本 (v2.1 - 完美兼容版)
# 功能：从 up366 应用的加密文件中解密并提取答案
# 特性: 自动检测 OpenSSL/Python (支持 Termux/MT管理器/系统终端)
# 兼容: 所有 Android 环境

SELECTED_PATH=""
DECRYPT_METHOD=""
PYTHON_CMD=""  # 存储找到的 python 命令完整路径

AES_KEY="QJBNiBmV55PDrewyne3GsA=="
FLIPBOOK_BASE="/data/data/com.up366.mobile/files/flipbook"
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
OUTPUT_FILE="$SCRIPT_DIR/answers_$(date +%Y%m%d_%H%M%S).txt"
TEMP_PREFIX="/tmp/up366_extract_$$"

echo "========================================"
echo "   Up366 答案提取工具"
echo "   v2.1 - 终极兼容版"
echo "========================================"

# ========== 权限检查 ==========
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "[错误] 需要 root 权限！"
        exit 1
    fi
    echo "[OK] Root 权限通过"
}

# ========== 智能检测 Python (核心改进) ==========
detect_python() {
    echo ""
    echo "搜索 Python 解释器..."

    # 按优先级顺序检查多个可能的路径

    # 1. 标准 PATH 中的命令
    for cmd in python3 python; do
        if command -v "$cmd" >/dev/null 2>&1; then
            full_path=$(command -v "$cmd")
            version=$("$cmd" --version 2>&1 | head -1)
            echo "[候选] $full_path ($version)"

            # 检查 pycryptodome
            if "$cmd" -c "from Crypto.Cipher import AES" 2>/dev/null; then
                PYTHON_CMD="$full_path"
                DECRYPT_METHOD="python"
                echo "[✓] 使用: $full_path (已安装 pycryptodome)"
                return 0
            else
                echo "  [!] 缺少 pycryptodome 库"
            fi
        fi
    done

    # 2. Termux 标准路径 (关键！MT管理器需要这个)
    termux_paths="
        /data/data/com.termux/files/usr/bin/python3
        /data/data/com.termux/files/usr/bin/python
        /sdcard/usr/bin/python3
        /sdcard/usr/bin/python
    "

    for py_path in $termux_paths; do
        if [ -x "$py_path" ]; then
            version=$("$py_path" --version 2>&1 | head -1)
            echo "[候选] $py_path ($version)"

            if "$py_path" -c "from Crypto.Cipher import AES" 2>/dev/null; then
                PYTHON_CMD="$py_path"
                DECRYPT_METHOD="python"
                echo "[✓] 使用: $py_path (Termux路径 + pycryptodome)"
                return 0
            else
                echo "  [!] 缺少 pycryptodome"
            fi
        fi
    done

    # 3. 使用 which/whereis 进一步查找
    if which python3 >/dev/null 2>&1; then
        py_path=$(which python3)
        echo "[候选] $py_path (from which)"
        if [ -x "$py_path" ]; then
            PYTHON_CMD="$py_path"
            DECRYPT_METHOD="python"
            echo "[✓] 使用: $py_path"
            return 0
        fi
    fi

    # 4. 最后尝试：查找所有可执行文件
    echo ""
    echo "正在扫描常见位置..."
    
    search_dirs="
        /system/bin
        /vendor/bin
        /data/local/tmp
        $PREFIX/bin
        /sdcard
        $HOME
        $(dirname "$0")
    "

    for dir in $search_dirs; do
        [ ! -d "$dir" ] && continue
        for f in "$dir"/python3 "$dir"/python; do
            if [ -x "$f" ]; then
                echo "  发现: $f"
            fi
        done
    done

    return 1
}

# ========== 检测 OpenSSL ==========
detect_openssl() {
    if command -v openssl >/dev/null 2>&1; then
        ver=$(openssl version 2>/dev/null | head -1)
        DECRYPT_METHOD="openssl"
        echo "[✓] 找到 OpenSSL: $ver"
        return 0
    fi
    return 1
}

# ========== 主检测函数 ==========
detect_decrypt_method() {
    echo ""
    echo "========================================"
    echo "  检测解密工具"
    echo "========================================"

    # 先检测 OpenSSL (更快更轻量)
    if detect_openssl; then
        return 0
    fi

    # 再检测 Python (功能更强)
    if detect_python; then
        return 0
    fi

    # 都没找到
    echo ""
    echo "╔══════════════════════════════════════╗"
    echo "║  [错误] 未找到解密工具！              ║"
    echo "╠══════════════════════════════════════╣"
    echo "║                                      ║"
    echo "║  当前环境: $(basename "$SHELL" 2>/dev/null || echo 'unknown')              ║"
    echo "║  PATH: $(echo "$PATH" | tr ':' '\n' | head -3 | sed 's/^/  /')... ║"
    echo "║                                      ║"
    echo "║  解决方案 (任选其一):                 ║"
    echo "║                                      ║"
    echo "║  A) 在 Termux 中运行此脚本:          ║"
    echo "║     termux → su → 运行脚本           ║"
    echo "║                                      ║"
    echo "║  B) 在 Termux 中安装依赖后用MT运行: ║"
    echo "║     pkg install python               ║"
    echo "║     pip install pycryptodome         ║"
    echo "║                                      ║"
    echo "║  C) 复制到电脑用Python解密:           ║"
    echo "║     Examples/decrypt_u3enc.py        ║"
    echo "╚══════════════════════════════════════╝"
    exit 1
}

# ========== 工具函数 ==========
is_number() {
    case "$1" in
        ''|*[!0-9]*) return 1 ;;
        *) return 0 ;;
    esac
}

is_hidden_dir() {
    case "$1" in
        .*) return 0 ;;
        *) return 1 ;;
    esac
}

select_directory() {
    current_dir="$1"
    prompt_msg="$2"

    echo ""
    echo "=== $prompt_msg ==="
    echo "路径: $current_dir"
    echo ""

    dirs_file="${TEMP_PREFIX}_dirs.txt"
    : > "$dirs_file"
    count=0

    for item in "$current_dir"/*/; do
        if [ -d "$item" ]; then
            dirname=$(basename "$item")
            if ! is_hidden_dir "$dirname" && [ "$dirname" != "lost+found" ]; then
                count=$((count + 1))
                echo "$dirname" >> "$dirs_file"
                printf "  [%2d] %s\n" "$count" "$dirname"
            fi
        fi
    done

    if [ $count -eq 0 ]; then
        echo "[!] 无子文件夹"
        rm -f "$dirs_file"
        SELECTED_PATH=""
        return 1
    fi

    echo ""
    echo -n ">> 选择 (1-$count): "
    read choice

    if ! is_number "$choice" || [ "$choice" -lt 1 ] || [ "$choice" -gt "$count" ] 2>/dev/null; then
        echo "[!] 无效输入"
        rm -f "$dirs_file"
        SELECTED_PATH=""
        return 1
    fi

    selected_dir=$(sed -n "${choice}p" "$dirs_file")
    full_path="$current_dir/$selected_dir"
    rm -f "$dirs_file"

    SELECTED_PATH="$full_path"
    echo "[OK] $selected_dir"
    return 0
}

check_target_folders() {
    [ -d "$1/1" ] && [ -d "$1/2" ]
}

navigate_to_target() {
    current_dir="$FLIPBOOK_BASE"

    [ ! -d "$FLIPBOOK_BASE" ] && { echo "[错误] flipbook目录不存在"; exit 1; }

    echo "扫描目录..."

    while true; do
        if check_target_folders "$current_dir"; then
            echo ""
            echo "[✓] 找到目标!"
            target_dir="$current_dir"
            return 0
        fi

        select_directory "$current_dir" "选择文件夹"
        [ $? -ne 0 ] || [ -z "$SELECTED_PATH" ] && exit 1
        current_dir="$SELECTED_PATH"
    done
}

clean_html_text() {
    text="$1"
    text=$(echo "$text" | sed 's/<[^>]*>//g')
    text=$(echo "$text" | sed 's/&amp;/\&/g;s/&lt;</</g;s/&gt;/>/g;s/&quot;/"/g')
    text=$(echo "$text" | sed "s/&apos;/'/g;s/&nbsp;/ /g")
    text=$(echo "$text" | sed 's/\\//g')
    echo "$text"
}

# ========== 解密实现 ==========
decrypt_with_openssl() {
    input="$1"
    output="$2"

    [ ! -f "$input" ] && return 1

    size=$(wc -c < "$input")
    [ "$size" -le 32 ] 2>/dev/null && return 1

    iv_hex=$(head -c 16 "$input" | xxd -p | tr -d '\n')
    key_hex=$(printf "%s" "$AES_KEY" | base64 -d | xxd -p | tr -d '\n')

    tail -c +17 "$input" | openssl enc -aes-128-cbc -d \
        -K "$key_hex" -iv "$iv_hex" -nosalt \
        -out "$output" 2>/dev/null

    [ $? -eq 0 ] && [ -s "$output" ]
}

decrypt_with_python() {
    input="$1"
    output="$2"

    [ ! -f "$input" ] && return 1
    [ -z "$PYTHON_CMD" ] && return 1

    py_script="${TEMP_PREFIX}_dec.py"

    cat > "$py_script" << 'PYEOF'
import sys, base64
try:
    from Crypto.Cipher import AES
except ImportError:
    from Cryptodome.Cipher import AES

def main():
    if len(sys.argv) != 3:
        sys.exit(1)

    key = base64.b64decode("QJBNiBmV55PDrewyne3GsA==")

    with open(sys.argv[1], 'rb') as f:
        data = f.read()

    if len(data) < 16:
        sys.exit(1)

    iv, ct = data[:16], data[16:]
    aes = AES.new(key, AES.MODE_CBC, iv)
    pt = aes.decrypt(ct)

    try:
        pad = pt[-1]
        if 1 <= pad <= 16 and all(b == pad for b in pt[-pad:]):
            pt = pt[:-pad]
    except:
        pass

    with open(sys.argv[2], 'wb') as f:
        f.write(pt)

if __name__ == '__main__':
    main()
PYEOF

    "$PYTHON_CMD" "$py_script" "$input" "$output" 2>/dev/null
    result=$?
    rm -f "$py_script"

    [ $result -eq 0 ] && [ -s "$output" ]
}

decrypt_u3enc() {
    case "$DECRYPT_METHOD" in
        openssl) decrypt_with_openssl "$1" "$2" ;;
        python)  decrypt_with_python "$1" "$2" ;;
        *)       return 1 ;;
    esac
}

extract_answers() {
    json_file="$1"
    output="$2"
    name="$3"

    echo "" >> "$output"
    echo "----------------------------------------" >> "$output"
    echo " [$name]" >> "$output"
    echo "----------------------------------------" >> "$output"
    echo "" >> "$output"

    q_num=0
    cat "$json_file" | tr ',' '\n' | grep "question_text" | while IFS=: read -r k v; do
        v=$(echo "$v" | sed 's/^ *"//;s/" *$//')
        q_num=$((q_num+1))
        echo "" >> "$output"
        echo "【问题$q_num】" >> "$output"
        cv=$(clean_html_text "$v")
        echo "  $cv" >> "$output"
    done

    cat "$json_file" | tr ',' '\n' | grep "answer_text" | while IFS=: read -r k v; do
        v=$(echo "$v" | sed 's/^ *"//;s/" *$//')
        echo "" >> "$output"
        echo "  >>> 答案: $v" >> "$output"
    done

    if ! grep -q "【问题" "$output" 2>/dev/null; then
        echo "--- 原始数据 ---" >> "$output"
        head -100 "$json_file" >> "$output"
    fi
}

process_folder() {
    path="$1"
    name="$2"
    out="$3"

    u3enc="$path/page1.js.u3enc"
    dec="${TEMP_PREFIX}_${name}.js"

    echo ""
    echo ">>> [$name]"
    echo "    $path"

    [ ! -f "$u3enc" ] && { 
        for f in "$path"/*.u3enc; do [ -f "$f" ] && u3enc="$f" && break; done
    }

    [ ! -f "$u3enc" ] && { echo "    [!] 无u3enc文件"; return 1; }

    sz=$(du -h "$u3enc" 2>/dev/null | cut -f1)
    echo "    $(basename "$u3enc") ($sz)"
    echo -n "    解密($DECRYPT_METHOD)... "

    if decrypt_u3enc "$u3enc" "$dec"; then
        echo "成功!"

        hd=$(head -c 200 "$dec" 2>/dev/null)
        if echo "$hd" | grep -qi "pageConfig\|var\|{"; then
            echo "    [✓] 格式正确"
        else
            echo "    [?] 格式未知"
        fi

        extract_answers "$dec" "$out" "$name"
        echo "    [✓] 已提取"
        rm -f "$dec"
        return 0
    else
        echo "失败!"
        rm -f "$dec"
        return 1
    fi
}

main() {
    check_root
    detect_decrypt_method
    navigate_to_target

    echo ""
    echo "============================================"
    echo "  目标: $target_dir"
    echo "  方式: $DECRYPT_METHOD"
    echo "  输出: $OUTPUT_FILE"
    echo "============================================"

    {
        echo "================================================================================"
        echo "                    Ciallo～ (∠・ω< )⌒★"
        echo "================================================================================"
        echo "时间: $(date '+%F %T')"
        echo "源: $target_dir"
        echo "方式: $DECRYPT_METHOD ($PYTHON_CMD)"
        echo ""
    } > "$OUTPUT_FILE"

    ok=0; fail=0

    for n in 1 2; do
        echo "--- [$n] ---"
        if [ -d "$target_dir/$n" ]; then
            if process_folder "$target_dir/$n" "$n" "$OUTPUT_FILE"; then
                ok=$((ok+1))
            else
                fail=$((fail+1))
            fi
        else
            echo "[$n] 不存在"; fail=$((fail+1))
        fi
    done

    ans=0
    [ -f "$OUTPUT_FILE" ] && ans=$(grep -c ">>> 答案:" "$OUTPUT_FILE" 2>/dev/null || echo 0)

    {
        echo ""; echo "================================================================================"
        echo "完成: $ok 成功 / $fail 失败 / ~ans 条答案"
        echo "================================================================================"
    } >> "$OUTPUT_FILE"

    echo ""
    echo "╔═══════════════════════════════╗"
    echo "║      ✅ 完成！               ║"
    echo "║  成功:$ok  失败:$fail  答案:~$ans     ║"
    echo "║  方式: $DECRYPT_METHOD             ║"
    echo "╠═══════════════════════════════╣"
    echo "║  $OUTPUT_FILE"
    echo "╚═══════════════════════════════╝"
    echo ""

    rm -f ${TEMP_PREFIX}_* 2>/dev/null
}

main "$@"
