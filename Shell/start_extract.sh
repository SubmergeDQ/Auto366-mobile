#!/system/bin/sh

# ============================================
#   UP366 一键启动器 (MT/Termux 通用版)
#   功能: 自动检测环境并调用正确的解密工具
#   用法: 在 MT 或 Termux 中以 root 运行此脚本
# ============================================

echo "╔══════════════════════════════════════╗"
echo "║     UP366 答案提取 - 智能启动器      ║"
echo "╚══════════════════════════════════════╝"
echo ""

# ========== Root 检查 ==========
if [ "$(id -u)" -ne 0 ]; then
    echo "[错误] 需要 root 权限！"
    echo "请先执行 'su' 切换到 root"
    exit 1
fi
echo "[✓] Root 权限 OK"

# ========== 脚本目录 ==========
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MAIN_SCRIPT="$SCRIPT_DIR/extract_up366.sh"

if [ ! -f "$MAIN_SCRIPT" ]; then
    # 尝试其他可能的位置
    for candidate in \
        "$0.extract_up366.sh" \
        "$(dirname "$0")/../extract_up366.sh" \
        "/storage/emulated/0/Download/MiShare/extract_up366.sh" \
        "/sdcard/Download/MiShare/extract_up366.sh"; do
        if [ -f "$candidate" ]; then
            MAIN_SCRIPT="$candidate"
            break
        fi
    done
fi

if [ ! -f "$MAIN_SCRIPT" ]; then
    echo "[错误] 找不到 extract_up366.sh 主脚本！"
    echo "请确保此启动器和主脚本在同一目录"
    exit 1
fi

echo "[✓] 主脚本: $MAIN_SCRIPT"
echo ""

# ========== 环境检测与自动配置 ==========
echo "========================================"
echo "  环境检测"
echo "========================================"

TERMUX_PYTHON="/data/data/com.termux/files/usr/bin/python3"
HAS_TERMUX_PY="no"
HAS_PYTHON_CMD="no"

# 检测 Termux Python
if [ -x "$TERMUX_PYTHON" ]; then
    if "$TERMUX_PYTHON" -c "from Crypto.Cipher import AES" 2>/dev/null; then
        HAS_TERMUX_PY="yes"
        echo "[✓] Termux Python 可用 (带 pycryptodome)"
    else
        echo "[!] Termux Python 存在但缺少 pycryptodome"
    fi
else
    echo "[-] 未找到 Termux Python"
fi

# 检测 PATH 中的 Python
if command -v python3 >/dev/null 2>&1; then
    HAS_PYTHON_CMD="yes"
    if python3 -c "from Crypto.Cipher import AES" 2>/dev/null; then
        echo "[✓] 系统 PATH 中的 Python3 可用"
    else
        echo "[!] PATH 中有 Python3 但缺少 pycryptodome"
    fi
else
    echo "[-] PATH 中无 Python3"
fi

# 检测 OpenSSL
if command -v openssl >/dev/null 2>&1; then
    echo "[✓] OpenSSL 可用"
else
    echo "[-] 无 OpenSSL"
fi

echo ""

# ========== 决定运行策略 ==========
CURRENT_SHELL=$(basename "$SHELL" 2>/dev/null || echo "unknown")

case "$HAS_TERMUX_PY$HAS_PYTHON_CMD" in
    yes*)
        # 有可用的 Python，直接运行主脚本
        echo "========================================"
        echo "  ✅ 环境就绪，开始运行..."
        echo "========================================"
        echo ""
        
        # 设置必要的环境变量（确保能找到 Termux 工具）
        export PATH="/data/data/com.termux/files/usr/bin:$PATH"
        export LD_LIBRARY_PATH=/data/data/com.termux/files/usr/lib
        
        exec sh "$MAIN_SCRIPT" "$@"
        ;;
    
    *)
        # 没有 Python/OpenSSL，提供安装选项
        echo "╔══════════════════════════════════════╗"
        echo "║  需要先安装解密工具                  ║"
        echo "╠══════════════════════════════════════╣"
        echo "║                                      ║"
        echo "║  当前Shell: $CURRENT_SHELL                ║"
        echo "║                                      ║"
        if [ "$HAS_TERMUX_PY" = "no" ]; then
            echo "║  [!] Termux 中未安装 Python          ║"
        else
            echo "║  [!] Termux 缺少 pycryptodome 库     ║"
        fi
        echo "║                                      ║"
        echo "║  请选择操作:                          ║"
        echo "║                                      ║"
        echo "║  [1] 自动安装 (推荐)                  ║"
        echo "║      → 启动 Termux 并自动安装         ║"
        echo "║                                      ║"
        echo "║  [2] 显示手动安装命令                 ║"
        echo "║      → 复制命令到 Termux 执行          ║"
        echo "║                                      ║"
        echo "║  [3] 强制运行 (可能失败)              ║"
        echo "║      → 尝试用当前环境运行             ║"
        echo "╚══════════════════════════════════════╝"
        echo ""
        echo -n ">> 请选择 (1-3): "
        read choice
        
        case "$choice" in
            1)
                echo ""
                echo "正在启动 Termux 安装..."
                
                # 创建 Termux 安装脚本
                INSTALL_SCRIPT="/tmp/up366_install.sh"
                cat > "$INSTALL_SCRIPT" << 'INSEOF'
#!/data/data/com.termux/files/usr/bin/sh
echo "========================================"
echo "  UP366 依赖安装器"
echo "========================================"
echo ""
echo "[1/3] 更新包列表..."
pkg update -y >/dev/null 2>&1
echo "[✓] 完成"
echo ""
echo "[2/3] 安装 Python..."
pkg install python -y 2>&1 | tail -3
echo ""
echo "[3/3] 安装 pycryptodome..."
pip install pycryptodome 2>&1 | tail -5
echo ""
echo "========================================"
echo "  验证安装..."
echo "========================================"
python --version
python -c "from Crypto.Cipher import AES; print('[✓] pycryptodome OK')"
echo ""
echo "========================================"
echo "  安装完成！"
echo "  现在请重新运行启动器脚本"
echo "========================================"
INSEOF
                
                chmod +x "$INSTALL_SCRIPT"
                
                # 尝试通过 am 命令启动 Termux
                if command -v am >/dev/null 2>&1; then
                    # 方法1: 通过 Intent 启动 Termux
                    am start --user 0 \
                        -n com.termux/.app.TermuxOpenReceiver \
                        -a android.intent.action.VIEW \
                        -d "file://$INSTALL_SCRIPT" \
                        --es com.termux.OPEN_METHOD run_command >/dev/null 2>&1
                    
                    echo ""
                    echo "[已发送] 已请求 Termux 执行安装脚本"
                    echo ""
                    echo "如果 Termux 没有自动打开，请:"
                    echo "  1. 手动打开 Termux 应用"
                    echo "  2. 输入以下命令:"
                    echo "     sh $INSTALL_SCRIPT"
                    echo ""
                    echo "安装完成后，重新运行本启动器即可！"
                else
                    echo ""
                    echo "[!] 无法自动启动 Termux"
                    echo ""
                    echo "请手动操作:"
                    echo "  1. 打开 Termux 应用"
                    echo "  2. 复制并执行以下命令:"
                    echo ""
                    echo "sh $INSTALL_SCRIPT"
                    echo ""
                    echo "或者直接执行:"
                    echo "pkg install python -y && pip install pycryptodome"
                fi
                ;;
            
            2)
                echo ""
                echo "========================================"
                echo "  手动安装指南"
                echo "========================================"
                echo ""
                echo "请在 Termux 中依次执行以下命令:"
                echo ""
                echo "  # 第1步: 更新包管理器"
                echo "pkg update -y"
                echo ""
                echo "  # 第2步: 安装 Python"
                echo "pkg install python -y"
                echo ""
                echo "  # 第3步: 安装加密库"
                echo "pip install pycryptodome"
                echo ""
                echo "  # 第4步: 验证安装"
                echo "python -c \"from Crypto.Cipher import AES; print('OK')\""
                echo ""
                echo "完成后重新运行此启动器即可！"
                echo "========================================"
                ;;
            
            3)
                echo ""
                echo "强制运行中... (可能会失败)"
                export PATH="/data/data/com.termux/files/usr/bin:$PATH" 2>/dev/null
                sh "$MAIN_SCRIPT" "$@"
                exit $?
                ;;
            
            *)
                echo "[!] 无效选择"
                exit 1
                ;;
        esac
        ;;
esac
