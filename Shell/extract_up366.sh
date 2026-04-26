#!/system/bin/sh

# UP366 答案提取工具
# 从 up366 应用的加密文件中解密并提取答案

SELECTED_PATH=""
DECRYPT_METHOD=""
PYTHON_CMD=""
AES_KEY="QJBNiBmV55PDrewyne3GsA=="
FLIPBOOK_BASE="/data/data/com.up366.mobile/files/flipbook"
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
OUTPUT_FILE="$SCRIPT_DIR/answer.txt"
TEMP_PREFIX="/tmp/up366_$$"
PRIV_MODE=""  # root | shizuku | unknown

echo "========================================"
echo "   UP366 答案提取工具"
echo "   (支持 Root / Shizuku)"
echo "========================================"

# 权限与环境检测: 支持 Root 和 Shizuku
detect_priv() {
    local uid=$(id -u 2>/dev/null || echo "")

    # Root 模式: uid=0
    if [ "$uid" = "0" ]; then
        PRIV_MODE="root"
        echo "[OK] Root 权限通过"
        return 0
    fi

    # Shizuku 模式: 通过 adb shell 运行, uid=2000(shell) 或 >=10000(app)
    # 关键特征: 能访问 /data/data/ 目录但不是 root
    if [ -n "$uid" ]; then
        # 检测是否在 Shizuku 环境中运行
        if [ "$uid" = "2000" ] || [ "${uid:-0}" -ge "10000" ] 2>/dev/null; then
            # 尝试访问目标目录验证权限
            if [ -d "$FLIPBOOK_BASE" ] && ls "$FLIPBOOK_BASE" >/dev/null 2>&1; then
                PRIV_MODE="shizuku"
                echo "[OK] Shizuku 权限通过 (UID=$uid)"
                return 0
            fi
            # 或者检查是否有 adb 标记
            if [ -n "$ANDROID_ROOT" ] || [ -n "$SHIZUKU_ENV" ]; then
                PRIV_MODE="shizuku"
                echo "[OK] Shizuku 环境 (UID=$uid)"
                return 0
            fi
        fi
        # 非 root 非 shizuku 的其他情况也尝试一下
        if [ -d "$FLIPBOOK_BASE" ] && ls "$FLIPBOOK_BASE" >/dev/null 2>&1; then
            PRIV_MODE="shizuku"
            echo "[OK] 有足够权限访问目标目录 (UID=$uid)"
            return 0
        fi
    fi

    PRIV_MODE=""
    echo "[X] 无权限: 需要 Root 或 Shizuku (当前 UID=${uid:-unknown})"
    return 1
}

# 执行权限检查
if ! detect_priv; then
    echo ""
    echo "请确保:"
    echo "  1. Root 设备 → 用 su 执行此脚本"
    echo "  2. 无 Root → 安装 Shizuku 并用其终端执行"
    echo "     https://github.com/RikkaApps/Shizuku"
    exit 1
fi

# 检测 Python
detect_python() {
    # 检查 PATH 中的 python
    for cmd in python3 python; do
        if command -v "$cmd" >/dev/null 2>&1; then
            p=$(command -v "$cmd")
            if "$cmd" -c "from Crypto.Cipher import AES" 2>/dev/null; then
                PYTHON_CMD="$p"; DECRYPT_METHOD="python"
                echo "[OK] Python: $p"; return 0
            fi
        fi
    done
    
    # 检查 Termux 路径
    for p in /data/data/com.termux/files/usr/bin/python3 /data/data/com.termux/files/usr/bin/python; do
        [ -x "$p" ] && {
            if "$p" -c "from Crypto.Cipher import AES" 2>/dev/null; then
                PYTHON_CMD="$p"; DECRYPT_METHOD="python"
                echo "[OK] Python (Termux): $p"; return 0
            fi
        }
    done
    
    return 1
}

# 检测 OpenSSL
detect_openssl() {
    command -v openssl >/dev/null 2>&1 && {
        DECRYPT_METHOD="openssl"
        echo "[OK] OpenSSL: $(openssl version | head -1)"
        return 0
    }
    return 1
}

# 尝试自动安装 (MT/Termux/MuMu 通用)
auto_install() {
    echo ""
    echo "--- 安装解密环境 ---"
    
    T="/data/data/com.termux/files/usr"
    TP="$T/bin/pkg"
    TPY="$T/bin/python3"

    # Termux 已装 → 直接装 python
    if [ -x "$TP" ]; then
        echo "[OK] Termux 已存在"
        export PATH="$T/bin:$PATH"; export LD_LIBRARY_PATH="$T/lib"; export TMPDIR="$T/tmp"
        echo "[1/2] pkg install python..."
        "$TP" install -y python 2>&1 | tail -1
        if [ -x "$TPY" ]; then
            echo "[2/2] pip install pycryptodome..."
            "$TPY" -m pip install pycryptodome 2>&1 | tail -1
            if "$TPY" -c "from Crypto.Cipher import AES" 2>/dev/null; then
                PYTHON_CMD="$TPY"; DECRYPT_METHOD="python"; echo "[OK] 完成"; return 0
            fi
        fi
        echo "[X] 安装失败"; return 1
    fi

    # Termux 未装 → 尝试多种方式安装
    echo "[!] 需要安装 Termux"
    
    dl_dir="/data/local/tmp"
    apk="$dl_dir/termux.apk"
    
    # 方式A: 用 am 打开浏览器下载 (通用)
    if command -v am >/dev/null 2>&1; then
        echo ""
        echo "即将打开浏览器下载 Termux..."
        echo "下载完成后点击通知栏的 termux.apk 安装"
        echo "然后重新运行此脚本"
        echo ""
        
        am start -a android.intent.action.VIEW \
            -d "https://github.com/termux/termux-app/releases/download/v0.118.1/termux-app_v0.118.1+github-debug.apk" \
            >/dev/null 2>&1
        
        echo -n "已打开浏览器, 安装好 Termux 后按回车继续..."
        read dummy
        
        # 用户按回车后再次检查
        if [ -x "$TP" ]; then
            auto_install; return $?
        else
            echo "[!] 仍未检测到 Termux, 请确认已安装并重启脚本"
            exit 0
        fi
    
    # 方式B: 检查本地是否有 APK
    elif [ -f "/sdcard/Download/termux.apk" ] || [ -f "$SCRIPT_DIR/termux.apk" ]; then
        local_apk="/sdcard/Download/termux.apk"
        [ ! -f "$local_apk" ] && local_apk="$SCRIPT_DIR/termux.apk"
        echo "[OK] 找到本地 APK: $local_apk"
        pm install -r "$local_apk" 2>&1 | tail -1
        if [ -x "$TP" ]; then
            auto_install; return $?
        else
            echo "[!] 安装后未检测到, 请重启脚本"; exit 0
        fi
    
    else
        echo "[X] 无法自动安装 (无 am 命令)"
        return 1
    fi
}

# 导出模式: 复制 u3enc 文件到 SD 卡供电脑解密
export_mode() {
    echo ""
    echo "--- 导出模式 ---"
    echo "将 .u3enc 文件复制到 SD 卡, 用电脑解密"
    echo ""
    
    navigate
    
    out_dir="$SCRIPT_DIR/u3enc_export"
    mkdir -p "$out_dir"
    
    count=0
    for n in 1 2; do
        d="$target_dir/$n"
        [ -d "$d" ] || continue
        
        for f in "$d"/*.u3enc; do
            [ -f "$f" ] || continue
            bn=$(basename "$f")
            cp "$f" "$out_dir/${n}_$bn"
            count=$((count+1))
            echo "  [$count] ${n}_$bn ($(du -h "$f" | cut -f1))"
        done
    done
    
    echo ""
    if [ $count -gt 0 ]; then
        echo "[OK] 已导出 $count 个文件到:"
        echo "  $out_dir"
        echo ""
        echo "下一步: 将整个 u3enc_export 文件夹复制到电脑"
        echo "  然后运行: python Examples/decrypt_u3enc.py <文件>"
    else
        echo "[X] 未找到 u3enc 文件"
    fi
}

# 主检测
echo ""
echo "--- 检测解密工具 ---"
if ! detect_openssl; then
    if ! detect_python; then
        echo ""
        echo "[!] 无解密工具 (python/openssl)"
        echo ""
        echo "  [1] 自动安装 Termux+Python (推荐)"
        echo "  [2] 导出 u3enc 文件, 用电脑解密"
        echo "  [3] 退出"
        echo ""
        echo -n ">> 选择: "
        read ans
        case "$ans" in
            1) auto_install && echo "" || { echo ""; echo "[X] 安装失败"; echo ""; echo "备选: 选择 [2] 导出到电脑解密"; exit 1; } ;;
            2) export_mode; exit 0 ;;
            3|*) exit 1 ;;
        esac
    fi
fi

# 工具函数
is_num() { case "$1" in ''|*[!0-9]*) return 1;; *) return 0;; esac; }
is_hidden() { case "$1" in .*) return 0;; *) return 1;; esac; }

# 目录选择
select_dir() {
    d="$1"; msg="$2"
    echo ""
    echo "== $msg =="
    echo "路径: $d"
    echo ""
    
    df="${TEMP_PREFIX}_dirs.txt"
    : > "$df"; c=0
    
    for i in "$d"/*/; do
        [ -d "$i" ] || continue
        n=$(basename "$i")
        is_hidden "$n" && continue
        [ "$n" = "lost+found" ] && continue
        c=$((c+1)); echo "$n" >> "$df"
        printf "  [%2d] %s\n" "$c" "$n"
    done
    
    [ $c -eq 0 ] && { echo "[!] 无子目录"; rm -f "$df"; SELECTED_PATH=""; return 1; }
    
    echo ""
    echo -n ">> 选择 (1-$c): "
    read ch
    
    is_num "$ch" || { echo "[!] 需要数字"; rm -f "$df"; SELECTED_PATH=""; return 1; }
    [ "$ch" -lt 1 ] || [ "$ch" -gt "$c" ] 2>/dev/null && { echo "[!] 超出范围"; rm -f "$df"; SELECTED_PATH=""; return 1; }
    
    s=$(sed -n "${ch}p" "$df"); rm -f "$df"
    SELECTED_PATH="$d/$s"
    echo "[OK] $s"
    return 0
}

# 导航到目标
navigate() {
    cur="$FLIPBOOK_BASE"
    [ -d "$cur" ] || { echo "[X] flipbook 目录不存在: $cur"; exit 1; }
    
    while true; do
        [ -d "$cur/1" ] && [ -d "$cur/2" ] && { target_dir="$cur"; echo ""; echo "[OK] 找到目标"; return 0; }
        select_dir "$cur" "选择文件夹" || exit 1
        cur="$SELECTED_PATH"
    done
}

# 清理 HTML
clean_html() {
    t="$1"
    t=$(echo "$t" | sed 's/<[^>]*>//g')
    t=$(echo "$t" | sed 's/&amp;/\&/g;s/&lt;/</g;s/&gt;/>/g;s/&quot;/"/g')
    t=$(echo "$t" | sed "s/&apos;/'/g;s/&nbsp;/ /g")
    echo "$t"
}

# 解密 (OpenSSL)
dec_ssl() {
    inp="$1"; out="$2"
    [ ! -f "$inp" ] && return 1
    sz=$(wc -c < "$inp")
    [ "$sz" -le 32 ] 2>/dev/null && return 1
    
    iv=$(head -c 16 "$inp" | xxd -p | tr -d '\n')
    key=$(printf "%s" "$AES_KEY" | base64 -d | xxd -p | tr -d '\n')
    
    tail -c +17 "$inp" | openssl enc -aes-128-cbc -d -K "$key" -iv "$iv" -nosalt -out "$out" 2>/dev/null
    [ $? -eq 0 ] && [ -s "$out" ]
}

# 解密 (Python)
dec_py() {
    inp="$1"; out="$2"
    [ -z "$PYTHON_CMD" ] && return 1
    [ ! -f "$inp" ] && return 1
    
    ps="${TEMP_PREFIX}_d.py"
    cat > "$ps" << 'EOF'
import sys, base64
from Crypto.Cipher import AES
key = base64.b64decode("QJBNiBmV55PDrewyne3GsA==")
with open(sys.argv[1], 'rb') as f:
    d = f.read()
iv, ct = d[:16], d[16:]
pt = AES.new(key, AES.MODE_CBC, iv).decrypt(ct)
try:
    pad = pt[-1]
    if 1 <= pad <= 16 and all(b == pad for b in pt[-pad:]):
        pt = pt[:-pad]
except:
    pass
open(sys.argv[2], 'wb').write(pt)
EOF
    "$PYTHON_CMD" "$ps" "$inp" "$out" 2>/dev/null
    r=$?; rm -f "$ps"
    [ $r -eq 0 ] && [ -s "$out" ]
}

decrypt() {
    case "$DECRYPT_METHOD" in
        openssl) dec_ssl "$1" "$2" ;;
        python)  dec_py "$1" "$2" ;;
        *)       return 1 ;;
    esac
}

# 提取答案
extract() {
    jf="$1"; out="$2"; name="$3"
    
    echo "" >> "$out"
    echo "========================================" >> "$out"
    echo " 文件夹: $name" >> "$out"
    echo "========================================" >> "$out"
    
    # 用 Python 提取
    pe="${TEMP_PREFIX}_e.py"
    cat > "$pe" << 'PYEOF'
import sys, re, json

with open(sys.argv[1], 'r', encoding='utf-8', errors='ignore') as f:
    content = f.read()

# 找 questionObj
m = re.search(r'questionObj\s*=\s*(\[.*?\]);', content, re.DOTALL)
if not m:
    m = re.search(r'(?:var\s+)?questions?\s*=\s*(\[.*?\]);', content, re.DOTALL)

if not m:
    open(sys.argv[2], 'a').write("\n[!] 未找到题目结构\n")
    sys.exit(1)

try:
    qs = json.loads(m.group(1))
except:
    open(sys.argv[2], 'a').write("\n[!] JSON解析失败\n")
    sys.exit(1)

out = open(sys.argv[2], 'a')
cnt = 0
for q in qs:
    cnt += 1
    qt = q.get('questionText', q.get('question', '')).strip()
    ans = q.get('answerText', q.get('answer', '')).strip()
    pat = q.get('pattern', '')
    qt = re.sub(r'<[^>]+>', '', qt)
    qt = qt.replace('&amp;', '&').replace('&lt;', '<').replace('&gt;', '>')
    
    if qt or ans:
        out.write(f"\n问题 {cnt}: {qt}\n")
        out.write(f"答案: {ans}\n")
        if pat:
            out.write(f"类型: {pat}\n")

out.close()
sys.exit(0 if cnt > 0 else 1)
PYEOF

    r=1
    if [ -n "$PYTHON_CMD" ] && [ -x "$PYTHON_CMD" ]; then
        "$PYTHON_CMD" "$pe" "$jf" "$out" 2>/dev/null; r=$?
    fi
    rm -f "$pe"
    
    # 备用: shell 提取
    [ $r -ne 0 ] && {
        echo "" >> "$out"
        echo "--- 备用模式 ---" >> "$out"
        n=0
        cat "$jf" | tr ',' '\n' | grep "question_text" | while IFS=: read -r k v; do
            v=$(echo "$v" | sed 's/^ *"//;s/" *$//')
            n=$((n+1))
            cv=$(clean_html "$v")
            echo "" >> "$out"; echo "问题 $n: $cv" >> "$out"
        done
        cat "$jf" | tr ',' '\n' | grep "answer_text" | while IFS=: read -r k v; do
            v=$(echo "$v" | sed 's/^ *"//;s/" *$//')
            echo "答案: $v" >> "$out"
        done
    }
}

# 处理文件夹
process() {
    path="$1"; name="$2"; out="$3"
    enc="$path/page1.js.u3enc"
    dec="${TEMP_PREFIX}_${name}.js"
    
    echo ""
    echo ">>> [$name]"
    echo "    $path"
    
    [ ! -f "$enc" ] && { for f in "$path"/*.u3enc; do [ -f "$f" ] && enc="$f" && break; done; }
    [ ! -f "$enc" ] && { echo "    [X] 无u3enc文件"; return 1; }
    
    sz=$(du -h "$enc" 2>/dev/null | cut -f1)
    echo "    $(basename "$enc") ($sz)"
    echo -n "    解密... "
    
    decrypt "$enc" "$dec" && {
        echo "OK"
        extract "$dec" "$out" "$name"
        echo "    [OK] 已提取"
        rm -f "$dec"
        return 0
    } || {
        echo "FAIL"
        rm -f "$dec"
        return 1
    }
}

# 主流程
main() {
    navigate

    # Shizuku 模式下, 确保输出目录可写
    if [ "$PRIV_MODE" = "shizuku" ]; then
        # 尝试写入测试, 失败则回退到 /sdcard
        if ! touch "$OUTPUT_FILE" 2>/dev/null; then
            OUTPUT_FILE="/sdcard/answer_up366.txt"
            echo "[!] 脚本目录不可写, 输出改为: $OUTPUT_FILE"
        fi
    fi

    echo ""
    echo "========================================"
    echo "  目标: $target_dir"
    echo "  权限: $PRIV_MODE"
    echo "  方式: $DECRYPT_METHOD"
    echo "  输出: $OUTPUT_FILE"
    echo "========================================"

    {
        echo "========================================"
        echo "  UP366 答案提取结果"
        echo "========================================"
        echo "时间: $(date '+%F %T')"
        echo "源: $target_dir"
        echo "权限模式: $PRIV_MODE"
        echo ""
    } > "$OUTPUT_FILE"
    
    ok=0; fail=0
    
    for n in 1 2; do
        echo "--- [$n] ---"
        if [ -d "$target_dir/$n" ]; then
            process "$target_dir/$n" "$n" "$OUTPUT_FILE" && ok=$((ok+1)) || fail=$((fail+1))
        else
            echo "[$n] 不存在"; fail=$((fail+1))
        fi
    done
    
    ans=0
    [ -f "$OUTPUT_FILE" ] && ans=$(grep -c "^答案:" "$OUTPUT_FILE" 2>/dev/null || echo 0)
    
    {
        echo ""
        echo "========================================"
        echo "  完成: 成功=$ok 失败=$fail 答案=$ans"
        echo "========================================"
    } >> "$OUTPUT_FILE"
    
    echo ""
    echo "========================================"
    echo "  [完成] 成功=$ok 失败=$fail 答案=$ans"
    echo "  文件: answer.txt"
    echo "  路径: $SCRIPT_DIR/"
    echo "========================================"
    echo ""
    
    rm -f ${TEMP_PREFIX}_* 2>/dev/null
}

main "$@"
