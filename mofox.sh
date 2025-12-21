#!/bin/bash

# ============================================
# Armbian软件自动安装脚本（简洁版）
# 适用于基于Debian 11的Armbian系统
# 作者：牡丹江市第一高级中学ACG社2023级社长越渊
# 创建日期：$(date +%Y-%m-%d)
# 版本：2.7.5
# ============================================

# 脚本功能说明：
# 本脚本用于在Armbian系统上自动安装以下软件：
# 1. MoFox-Core - 核心框架
# 2. NapcatQQ - QQ机器人框架
# 3. 1panel - Web管理面板（可选）
# 4. coplar - 内网穿透工具（可选）
#
# 系统要求：
# - 理论适用于所有主流Linux发行版
# - 脚本优化和构建基于Debian 11 Armbian
# - 已连接互联网
# - 具有root权限或sudo权限

# ============================================
# 配置参数
# ============================================
MAX_RETRIES=3
RETRY_DELAY=2

# ============================================
# 颜色定义
# ============================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ============================================
# 变量定义
# ============================================
SCRIPT_NAME="Armbian软件自动安装脚本"
SCRIPT_VERSION="2.7.5"
INSTALL_LOG="/var/log/armbian_install_$(date +%Y%m%d_%H%M%S).log"
TEMP_DIR="/tmp/armbian_install"

# 软件安装选项
INSTALL_MOFOX=true
INSTALL_NAPCATQQ=true
INSTALL_1PANLE=false
INSTALL_COPLAR=false

# 新增标志变量
MOFOX_EXISTS=false
NAPCAT_EXISTS=false
SKIP_SYSTEM_CHECK=false
# ============================================
# 函数定义
# ============================================

# 自动重试函数
retry_command() {
    local max_retries=$1
    local delay=$2
    local cmd="$3"
    local description="$4"
    local retry_count=0
    
    while [ $retry_count -lt $max_retries ]; do
        if [ $retry_count -eq 0 ]; then
            echo -n "  ↳ $description... "
        else
            echo -n "  ↳ $description (重试 $retry_count/$max_retries)... "
        fi
        
        # 执行命令，隐藏输出，只捕获错误
        if eval "$cmd" >> "$INSTALL_LOG" 2>&1; then
            echo -e "${GREEN}✓${NC}"
            return 0
        fi
        
        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $max_retries ]; then
            sleep $delay
        fi
    done
    
    echo -e "${RED}✗${NC}"
    return 1
}

# 静默安装函数（隐藏输出）
silent_install() {
    local cmd="$1"
    local description="$2"
    
    echo -n "  ↳ $description... "
    if eval "$cmd" >> "$INSTALL_LOG" 2>&1; then
        echo -e "${GREEN}✓${NC}"
        return 0
    else
        echo -e "${RED}✗${NC}"
        return 1
    fi
}

# 打印带颜色的消息
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# 打印章节标题
print_header() {
    echo ""
    print_message "$BLUE" "============================================"
    print_message "$BLUE" "$1"
    print_message "$BLUE" "============================================"
    echo ""
}

# 显示MoFox ASCII艺术字
print_mofox_ascii() {
    echo ""
    print_message "$BLUE" "╔═══════════════════════════════════════╗"
    print_message "$BLUE" "║                                       ║"
    print_message "$BLUE" "║          ███╗   ███╗ ██████╗          ║"
    print_message "$GREEN" "║          ████╗ ████║██╔═══██╗         ║"
    print_message "$GREEN" "║          ██╔████╔██║██║   ██║         ║"
    print_message "$YELLOW" "║          ██║╚██╔╝██║██║   ██║         ║"
    print_message "$YELLOW" "║          ██║ ╚═╝ ██║╚██████╔╝         ║"
    print_message "$RED" "║          ╚═╝     ╚═╝ ╚═════╝          ║"
    print_message "$RED" "║         ███████╗ ██████╗ ██╗  ██╗     ║"
    print_message "$MAGENTA" "║         ██╔════╝██╔═══██╗╚██╗██╔╝     ║"
    print_message "$MAGENTA" "║         █████╗  ██║   ██║ ╚███╔╝      ║"
    print_message "$CYAN" "║         ██╔══╝  ██║   ██║ ██╔██╗      ║"
    print_message "$CYAN" "║         ██║     ╚██████╔╝██╔╝ ██╗     ║"
    print_message "$BLUE" "║         ╚═╝      ╚═════╝ ╚═╝  ╚═╝     ║"
    print_message "$BLUE" "║                                       ║"
    print_message "$BLUE" "╚═══════════════════════════════════════╝"

}
# ============================================
# 新增：检查MoFox目录函数
# ============================================

# 检查MoFox_Bot_Deployment文件夹是否存在
check_mofox_directory() {
    print_message "$CYAN" "检查MoFox安装状态..."
    
    local mofox_dir="$HOME/MoFox_Bot_Deployment"
    local mofox_core_dir="$mofox_dir/MoFox-Core"
    
    if [ -d "$mofox_dir" ]; then
        MOFOX_EXISTS=true
        
        echo ""
        print_message "$YELLOW" "╔══════════════════════════════════════════════════════════╗"
        print_message "$YELLOW" "║                检测到现有MoFox安装                      ║"
        print_message "$YELLOW" "╠══════════════════════════════════════════════════════════╣"
        print_message "$GREEN" "║  目录: $mofox_dir                          ║"
        
        if [ -d "$mofox_core_dir" ]; then
            print_message "$GREEN" "║  MoFox-Core: 已存在                                     ║"
            
            # 检查虚拟环境
            if [ -d "$mofox_core_dir/.venv" ]; then
                print_message "$GREEN" "║  虚拟环境: 已创建                                     ║"
                # 检查Python版本
                if [ -f "$mofox_core_dir/.venv/bin/python" ]; then
                    local python_version
                    python_version=$("$mofox_core_dir/.venv/bin/python" --version 2>&1 || echo "未知")
                    print_message "$GREEN" "║  Python版本: $python_version                    ║"
                fi
            else
                print_message "$YELLOW" "║  虚拟环境: 未找到                                     ║"
            fi
            
            # 检查配置文件
            if [ -f "$mofox_core_dir/.env" ]; then
                print_message "$GREEN" "║  环境配置: 已创建                                     ║"
            fi
        else
            print_message "$YELLOW" "║  MoFox-Core: 不存在                                     ║"
        fi
        
        print_message "$YELLOW" "╚══════════════════════════════════════════════════════════╝"
        echo ""
        
        # 询问用户操作选项
        print_message "$CYAN" "请选择操作："
        echo -e "${CYAN}1) 重新安装MoFox-Core (删除现有目录并重新安装)"
        echo -e "${CYAN}2) 继续使用现有目录安装 (仅更新/修复)"
        echo -e "${CYAN}3) 跳过系统检查，直接从软件选择开始"
        echo -e "${CYAN}4) 正常完整安装 (忽略现有目录)"
        
        while true; do
            read -p "请选择 [1/2/3/4]: " choice
            case $choice in
                1)
                    print_message "$YELLOW" "您选择了重新安装MoFox-Core"
                    print_message "$RED" "警告：这将删除现有MoFox目录并重新安装！"
                    read -p "确认删除 $mofox_dir ？(y/N): " -n 1 -r
                    echo
                    if [[ $REPLY =~ ^[Yy]$ ]]; then
                        echo -n "删除现有目录... "
                        rm -rf "$mofox_dir" 2>/dev/null
                        MOFOX_EXISTS=false
                        echo -e "${GREEN}✓${NC}"
                        print_message "$GREEN" "已删除现有目录，将继续正常安装流程"
                        sleep 2
                    else
                        print_message "$YELLOW" "取消删除，继续使用现有目录"
                        return 1
                    fi
                    ;;
                2)
                    print_message "$GREEN" "您选择了继续使用现有目录安装"
                    print_message "$YELLOW" "注意：如果安装失败，可能需要清理现有目录"
                    SKIP_SYSTEM_CHECK=true
                    return 2
                    ;;
                3)
                    print_message "$GREEN" "您选择了跳过系统检查"
                    SKIP_SYSTEM_CHECK=true
                    return 3
                    ;;
                4)
                    print_message "$GREEN" "您选择了正常完整安装"
                    return 0
                    ;;
                *)
                    echo -e "${RED}无效选择，请输入1-4${NC}"
                    ;;
            esac
        done
    else
        print_message "$GREEN" "未检测到现有MoFox安装，将进行全新安装"
        MOFOX_EXISTS=false
        return 0
    fi
}

# ============================================
# 新增：检查Napcat目录函数
# ============================================

# 检查NapcatQQ文件夹是否存在
# ============================================
# 修正：检查NapcatQQ目录函数（更全面的检测）
# ============================================

# 检查NapcatQQ文件夹是否存在
check_napcat_directory() {
    print_message "$CYAN" "检查NapcatQQ安装状态..."
    
    local found_dirs=()
    local napcat_dir=""
    
    # 扩展搜索路径，包含更多可能的目录
    local search_paths=(
        "/opt/NapCatQQ"
        "/opt/napcatqq"
        "/opt/Napcat"
        "/usr/local/NapCatQQ"
        "/usr/local/napcatqq"
        "/usr/local/Napcat"
        "$HOME/NapCatQQ"
        "$HOME/napcatqq"
        "$HOME/Napcat"
        "/root/NapCatQQ"
        "/root/napcatqq"
        "/root/Napcat"
        "/home/$USER/NapCatQQ"
        "/home/$USER/napcatqq"
        "/home/$USER/Napcat"
        "/var/lib/NapCatQQ"
        "/srv/NapCatQQ"
        "/data/NapCatQQ"
    )
    
    # 使用find命令进行更广泛的搜索
    echo -n "搜索NapcatQQ目录... "
    for path in "${search_paths[@]}"; do
        if [ -d "$path" ]; then
            found_dirs+=("$path")
        fi
    done
    
    # 使用find命令搜索包含"napcat"或"NapCat"的目录
    if [ ${#found_dirs[@]} -eq 0 ]; then
        echo -n "(使用find搜索)... "
        # 搜索根目录下包含napcat的目录
        local found_by_find
        found_by_find=$(find / -type d -name "*napcat*" -o -name "*NapCat*" 2>/dev/null | head -5)
        
        if [ -n "$found_by_find" ]; then
            while IFS= read -r dir; do
                if [ -d "$dir" ]; then
                    found_dirs+=("$dir")
                fi
            done <<< "$found_by_find"
        fi
    fi
    
    # 检查进程
    if pgrep -f "napcat\|NapCat" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ (检测到运行中的进程)${NC}"
        NAPCAT_EXISTS=true
    elif [ ${#found_dirs[@]} -gt 0 ]; then
        echo -e "${GREEN}✓ (找到 ${#found_dirs[@]} 个目录)${NC}"
        NAPCAT_EXISTS=true
    else
        echo -e "${YELLOW}✗${NC}"
        print_message "$GREEN" "未检测到现有NapcatQQ安装，将进行全新安装"
        NAPCAT_EXISTS=false
        return 0
    fi
    
    if [ "$NAPCAT_EXISTS" = true ]; then
        echo ""
        print_message "$YELLOW" "╔══════════════════════════════════════════════════════════╗"
        print_message "$YELLOW" "║                检测到现有NapcatQQ安装                   ║"
        print_message "$YELLOW" "╠══════════════════════════════════════════════════════════╣"
        
        # 显示找到的目录
        for dir in "${found_dirs[@]}"; do
            print_message "$GREEN" "║  目录: $dir"
        done
        
        # 检查服务状态
        if systemctl is-active --quiet napcatqq 2>/dev/null; then
            print_message "$GREEN" "║  服务状态: 运行中                                    ║"
        elif systemctl is-enabled --quiet napcatqq 2>/dev/null 2>/dev/null; then
            print_message "$YELLOW" "║  服务状态: 已启用但未运行                           ║"
        fi
        
        # 检查配置文件
        for dir in "${found_dirs[@]}"; do
            if [ -f "$dir/config/config.yaml" ] || [ -f "$dir/config.yaml" ]; then
                print_message "$GREEN" "║  配置文件: 存在                                    ║"
                break
            fi
        done
        
        print_message "$YELLOW" "╚══════════════════════════════════════════════════════════╝"
        echo ""
        
        # 询问用户操作选项
        print_message "$CYAN" "请选择NapcatQQ安装操作："
        echo -e "${CYAN}1) 重新安装NapcatQQ (删除现有目录并重新安装)"
        echo -e "${CYAN}2) 升级/修复安装 (保留配置文件)"
        echo -e "${CYAN}3) 跳过安装NapcatQQ"
        echo -e "${CYAN}4) 正常安装 (忽略现有目录，可能覆盖)"
        
        while true; do
            read -p "请选择 [1/2/3/4]: " choice
            case $choice in
                1)
                    print_message "$YELLOW" "您选择了重新安装NapcatQQ"
                    print_message "$RED" "警告：这将删除现有NapcatQQ目录并重新安装！"
                    
                    # 停止服务
                    echo -n "停止NapcatQQ服务... "
                    systemctl stop napcatqq 2>/dev/null
                    systemctl disable napcatqq 2>/dev/null
                    echo -e "${GREEN}✓${NC}"
                    
                    # 删除找到的所有目录
                    echo -n "删除NapcatQQ目录... "
                    for dir in "${found_dirs[@]}"; do
                        if [ -d "$dir" ]; then
                            rm -rf "$dir" 2>/dev/null
                            echo -e "\n  删除: $dir"
                        fi
                    done
                    
                    # 清理服务文件
                    echo -n "清理服务文件... "
                    rm -f /etc/systemd/system/napcatqq.service 2>/dev/null
                    rm -f /lib/systemd/system/napcatqq.service 2>/dev/null
                    systemctl daemon-reload 2>/dev/null
                    echo -e "${GREEN}✓${NC}"
                    
                    print_message "$GREEN" "已清理现有安装，将重新安装NapcatQQ"
                    NAPCAT_EXISTS=false
                    sleep 2
                    return 1
                    ;;
                2)
                    print_message "$GREEN" "您选择了升级/修复安装"
                    print_message "$YELLOW" "将尝试升级现有NapcatQQ安装"
                    NAPCAT_EXISTS=true  # 标记为存在，后续会尝试升级
                    
                    # 设置主目录
                    if [ ${#found_dirs[@]} -gt 0 ]; then
                        NAPCAT_DIR="${found_dirs[0]}"
                        export NAPCAT_DIR
                        print_message "$GREEN" "将使用目录: $NAPCAT_DIR"
                    fi
                    
                    return 2
                    ;;
                3)
                    print_message "$YELLOW" "您选择了跳过安装NapcatQQ"
                    INSTALL_NAPCATQQ=false
                    return 3
                    ;;
                4)
                    print_message "$GREEN" "您选择了正常安装"
                    print_message "$YELLOW" "注意：如果安装失败，可能需要清理现有目录"
                    return 4
                    ;;
                *)
                    echo -e "${RED}无效选择，请输入1-4${NC}"
                    ;;
            esac
        done
    fi
}

# ============================================
# 新增：快速安装模式
# ============================================

quick_install_mode() {
    print_header "快速安装模式"
    
    print_message "$GREEN" "检测到现有目录，启用快速安装模式"
    print_message "$YELLOW" "将跳过系统检查、更新和依赖安装"
    
    # 如果用户之前跳过了Napcat安装，重新询问
    if [ "$INSTALL_NAPCATQQ" = false ]; then
        read -p "是否安装NapcatQQ？(y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            INSTALL_NAPCATQQ=true
            # 在快速模式下也检查Napcat目录
            check_napcat_directory
        fi
    fi
    
    # 直接进入软件选择
    select_software
    
    # 直接安装软件
    print_header "软件安装"
    
    # 先安装其他软件
    [ "$INSTALL_COPLAR" = true ] && install_coplar
    [ "$INSTALL_1PANLE" = true ] && install_1panle
    
    # 安装NapcatQQ（如果选择了）
    if [ "$INSTALL_NAPCATQQ" = true ]; then
        if ! install_napcatqq; then
            print_message "$RED" "✗ NapcatQQ安装失败"
            log_message "NapcatQQ安装失败"
        fi
    fi
    
    # 最后安装MoFox（如果选择了）
    if [ "$INSTALL_MOFOX" = true ]; then
        if ! install_mofox; then
            print_message "$RED" "✗ MoFox-Core安装失败"
            log_message "MoFox-Core安装失败"
            exit 1
        fi
    fi
    
    return 0
}
# ============================================
# 新增：配置现有MoFox的函数
# ============================================

configure_existing_mofox() {
    print_message "$GREEN" "配置现有MoFox-Core安装..."
    
    cd ~/MoFox_Bot_Deployment/MoFox-Core || return 1
    
    # 检查虚拟环境
    if [ ! -d ".venv" ] || [ ! -f ".venv/bin/python" ]; then
        print_message "$RED" "虚拟环境不存在或损坏，需要重新安装"
        return 1
    fi
    
    # 验证虚拟环境
    echo -n "验证虚拟环境... "
    if .venv/bin/python -c "import sys; print('Python', sys.version)" >> "$INSTALL_LOG" 2>&1; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
        print_message "$RED" "虚拟环境验证失败"
        return 1
    fi
    
    # 检查配置文件
    if [ ! -f ".env" ]; then
        print_message "$YELLOW" "环境文件不存在，创建默认配置"
        cp template/template.env .env 2>> "$INSTALL_LOG" || echo -e "${YELLOW}⚠ 环境文件创建失败${NC}"
        sed -i 's/^EULA_CONFIRMED=.*/EULA_CONFIRMED=true/' .env
    fi
    
    # 检查插件配置
    if [ ! -d "config/plugins/napcat_adapter" ]; then
        echo -n "配置Napcat插件... "
        mkdir -p config/plugins/napcat_adapter
        if [ -f "template/plugins/napcat_adapter/config.toml" ]; then
            cp template/plugins/napcat_adapter/config.toml config/plugins/napcat_adapter/
            sed -i 's/enabled = false/enabled = true/' config/plugins/napcat_adapter/config.toml 2>> "$INSTALL_LOG"
            echo -e "${GREEN}✓${NC}"
        fi
    fi
    
    # 配置端口
    echo ""
    read -p "请输入Napcat服务器端口 (默认: 8080): " port
    port=${port:-8080}
    
    if [[ "$port" =~ ^[0-9]+$ ]] && [ "$port" -ge 1024 ] && [ "$port" -le 65535 ]; then
        local plugin_config="config/plugins/napcat_adapter/config.toml"
        if [ -f "$plugin_config" ]; then
            sed -i "s/port = .*/port = $port/" "$plugin_config" 2>> "$INSTALL_LOG"
            echo -e "${GREEN}✓ 端口配置成功: $port${NC}"
        fi
    fi
    
    print_message "$GREEN" "✓ 现有MoFox-Core配置完成"
    return 0
}

# ============================================
# 新增：跳转到完成部分
# ============================================

goto_installation_complete() {
    # ============================================
    # 安装完成
    # ============================================
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))

    print_header "安装完成"

    echo ""
    print_message "$GREEN" "╔══════════════════════════════════════════════════════════╗"
    print_message "$GREEN" "║                     安装完成总结                         ║"
    print_message "$GREEN" "╠══════════════════════════════════════════════════════════╣"
    print_message "$CYAN" "║  总用时: $DURATION 秒                                    ║"
    print_message "$CYAN" "║  日志文件: $INSTALL_LOG                           ║"
    print_message "$CYAN" "║  脚本版本: $SCRIPT_VERSION                               ║"
    print_message "$CYAN" "║                                                          ║"
print_message "$GREEN" "║  安装的软件:                                          ║"
[ "$INSTALL_MOFOX" = true ] && print_message "$YELLOW" "║    • MoFox-Core                                      ║"
[ "$INSTALL_NAPCATQQ" = true ] && print_message "$YELLOW" "║    • NapcatQQ                                       ║"
[ "$INSTALL_1PANLE" = true ] && print_message "$YELLOW" "║    • 1Panel                                         ║"
[ "$INSTALL_COPLAR" = true ] && print_message "$YELLOW" "║    • Cpolar                                         ║"

# 如果检测到存在但跳过了安装，显示特殊提示
if [ "$NAPCAT_EXISTS" = true ] && [ "$INSTALL_NAPCATQQ" = false ]; then
    print_message "$YELLOW" "║    • NapcatQQ (已存在，跳过安装)                       ║"
fi
    print_message "$GREEN" "╚══════════════════════════════════════════════════════════╝"
    echo ""
    echo "安装完成！请按照以下步骤操作："
    echo ""
    [ "$INSTALL_MOFOX" = true ] && echo "1. MoFox-Core: 进入 ~/MoFox_Bot_Deployment/MoFox-Core 目录"
    [ "$INSTALL_MOFOX" = true ] && echo "   激活虚拟环境: source .venv/bin/activate"
    [ "$INSTALL_MOFOX" = true ] && echo "   启动机器人: python bot.py"
    echo ""
    [ "$INSTALL_NAPCATQQ" = true ] && echo "2. NapcatQQ: 编辑 /opt/NapCatQQ/config/config.yaml 配置文件"
    [ "$INSTALL_NAPCATQQ" = true ] && echo "   启动服务: systemctl start napcatqq"
    echo ""
    [ "$INSTALL_1PANLE" = true ] && echo "3. 1Panel: 访问 http://<服务器IP>:目标端口"
    [ "$INSTALL_1PANLE" = true ] && echo "   使用安装时设置的用户名和密码登录"
    echo ""
    [ "$INSTALL_COPLAR" = true ] && echo "4. Cpolar: 配置认证令牌: cpolar authtoken <您的token>"
    [ "$INSTALL_COPLAR" = true ] && echo "   启动服务: systemctl start cpolar"
    echo ""
    print_message "$YELLOW" "建议重启系统以确保所有服务正常运行。"
    echo ""

    log_message "脚本执行完成，总用时: $DURATION 秒"

    # 询问是否重启
    read -p "是否现在重启系统？(y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_message "$YELLOW" "系统将在5秒后重启..."
        sleep 5
        reboot
    fi

    exit 0
}

# 检查是否以root权限运行
check_root() {
    echo -n "检查root权限... "
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}✗${NC}"
        print_message "$RED" "错误：此脚本必须以root权限运行！"
        print_message "$YELLOW" "请使用 'sudo bash $0' 或 'su -c \"bash $0\"'"
        exit 1
    fi
    echo -e "${GREEN}✓${NC}"
}

# 系统性能检查
check_system_resources_strict() {
    local required_storage=8  # 8GB
    local required_memory=1024  # 1024MB
    local has_error=0
    
    echo "检查系统资源（严格模式）..."
    
    # 检查存储空间
    echo -n "  检查存储空间 (最低 ${required_storage}GB)... "
    local available_kb
    available_kb=$(df -k / | awk 'NR==2 {print $4}')
    local available_gb=$((available_kb / 1024 / 1024))
    
    if [ "$available_gb" -lt "$required_storage" ]; then
        echo -e "${RED}✗${NC}"
        echo -e "  ${RED}错误：可用存储空间不足 ${required_storage}GB${NC}"
        echo -e "  ${RED}当前可用: ${available_gb}GB${NC}"
        has_error=1
    else
        echo -e "${GREEN}✓${NC}"
    fi
    
    # 检查可用内存
    echo -n "  检查可用内存 (最低 ${required_memory}MB)... "
    local available_memory_kb
    local available_memory_mb
    
    if [ -f /proc/meminfo ]; then
        available_memory_kb=$(grep -E 'MemAvailable' /proc/meminfo | awk '{print $2}')
        if [ -z "$available_memory_kb" ]; then
            # 如果MemAvailable不存在，使用MemFree + Buffers + Cached作为近似值
            local memfree buffers cached
            memfree=$(grep 'MemFree' /proc/meminfo | awk '{print $2}')
            buffers=$(grep 'Buffers' /proc/meminfo | awk '{print $2}')
            cached=$(grep '^Cached' /proc/meminfo | awk '{print $2}')
            available_memory_kb=$((memfree + buffers + cached))
        fi
        
        available_memory_mb=$((available_memory_kb / 1024))
        
        if [ "$available_memory_mb" -lt "$required_memory" ]; then
            echo -e "${RED}✗${NC}"
            echo -e "  ${RED}错误：可用内存不足 ${required_memory}MB${NC}"
            echo -e "  ${RED}当前可用: ${available_memory_mb}MB${NC}"
            has_error=1
        else
            echo -e "${GREEN}✓${NC}"
        fi
    else
        echo -e "${YELLOW}⚠${NC}"
        echo -e "  ${YELLOW}警告：无法检查内存信息${NC}"
    fi
    
    echo ""
    
    if [ "$has_error" -eq 1 ]; then
        echo -e "${RED}===============================================${NC}"
        echo -e "${RED}              系统资源不足                     ${NC}"
        echo -e "${RED}===============================================${NC}"
        echo -e "${RED}请确保系统满足以下最低要求：${NC}"
        echo -e "${RED}• 可用存储空间: ${required_storage}GB${NC}"
        echo -e "${RED}• 可用内存: ${required_memory}MB${NC}"
        echo -e "${RED}安装程序将退出${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}系统资源检查通过 ✓${NC}"
}

# 检查系统架构
check_architecture() {
    echo -n "检查系统架构... "
    local arch
    arch=$(uname -m)
    
    case $arch in
        armv7l|armv8l|aarch64|arm64)
            echo -e "${GREEN}✓ ($arch)${NC}"
            return 0
            ;;
        x86_64|i386|i686|amd64)
            echo -e "${YELLOW}⚠ ($arch)${NC}"
            print_message "$YELLOW" "警告：检测到x86/x64架构，本脚本主要针对ARM架构优化"
            print_message "$YELLOW" "在x86系统上运行可能存在兼容性问题或功能限制"
            ;;
        *)
            echo -e "${YELLOW}⚠ ($arch)${NC}"
            print_message "$YELLOW" "警告：检测到非常用架构，可能存在兼容性问题"
            ;;
    esac
    
    # 询问用户是否继续
    echo ""
    print_message "$YELLOW" "您希望继续安装吗？"
    echo -e "${YELLOW}1) 继续安装（自行承担兼容性风险）${NC}"
    echo -e "${YELLOW}2) 退出安装${NC}"
    
    while true; do
        read -p "请选择 [1/2]: " choice
        case $choice in
            1)
                print_message "$YELLOW" "警告：您选择继续安装，请注意兼容性问题"
                echo -e "${YELLOW}如果遇到问题，请参考相关文档或联系支持${NC}"
                sleep 2
                return 1
                ;;
            2)
                print_message "$BLUE" "安装已取消"
                exit 0
                ;;
            *)
                echo -e "${RED}无效选择，请输入1或2${NC}"
                ;;
        esac
    done
}

# 检查网络连接
check_network() {
    echo -n "检查网络连接... "
    if ping -c 1 -W 2 baidu.com > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${YELLOW}⚠${NC}"
        print_message "$YELLOW" "⚠ 网络连接可能存在问题，但将继续执行..."
    fi
}

# 系统更新
update_system() {
    print_header "系统更新"
    
    echo -n "更新软件包列表... "
    retry_command $MAX_RETRIES $RETRY_DELAY "apt-get update" "更新软件包列表" || return 1
    
    echo -n "升级软件包... "
    silent_install "apt-get upgrade -y" "升级软件包" || return 1
    
    echo -n "清理系统... "
    silent_install "apt-get autoremove -y && apt-get clean" "清理系统" || return 1
    
    print_message "$GREEN" "✓ 系统更新完成"
    return 0
}

# 安装依赖包
install_dependencies() {
    print_header "安装依赖包"
    
    echo -n "安装基础依赖... "
    silent_install "apt-get install -y curl wget git sudo build-essential " "安装基础依赖" || return 1
    
    print_message "$GREEN" "✓ 依赖包安装完成"
    return 0
}

# 选择安装的软件

select_software() {
    print_header "选择安装的软件"
    
    # 如果之前已经询问过NapcatQQ，跳过询问
    if [ "$INSTALL_NAPCATQQ" = false ] && [ "$NAPCAT_EXISTS" = false ]; then
        read -p "是否安装 NapcatQQ？(y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            INSTALL_NAPCATQQ=true
        else
            print_message "$YELLOW" "✗ 跳过安装 NapcatQQ"
        fi
    fi
    
    # 询问是否安装1panle
    read -p "是否安装 1panle？-暂时无法使用，请选择不安装(y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        INSTALL_1PANLE=true
        print_message "$GREEN" "✓ 已选择安装 1panle"
    else
        print_message "$YELLOW" "✗ 跳过安装 1panle"
    fi
    
    # 询问是否安装coplar
    read -p "是否安装 coplar？(y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        INSTALL_COPLAR=true
        print_message "$GREEN" "✓ 已选择安装 coplar"
    else
        print_message "$YELLOW" "✗ 跳过安装 coplar"
    fi
    
    print_message "$GREEN" "✓ 软件选择完成"
}

# 记录日志
log_message() {
    local message=$1
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" | tee -a "$INSTALL_LOG"
}

# ============================================
# 软件安装函数
# ============================================

#安装napcatQQ
install_napcatqq() {
    print_header "安装 NapcatQQ"
    
    # 如果用户选择了跳过安装
    if [ "$INSTALL_NAPCATQQ" = false ]; then
        print_message "$YELLOW" "用户选择跳过NapcatQQ安装"
        return 0
    fi
    
    # 检查是否已存在且选择升级模式
    if [ "$NAPCAT_EXISTS" = true ] && [ -n "${NAPCAT_DIR:-}" ] && [ -d "$NAPCAT_DIR" ]; then
        print_message "$YELLOW" "检测到现有NapcatQQ安装，尝试升级/修复..."
        
        cd "$NAPCAT_DIR" || return 1
        
        # 备份配置文件
        echo -n "备份配置文件... "
        if [ -f "config/config.yaml" ]; then
            cp -f config/config.yaml config/config.yaml.backup.$(date +%Y%m%d_%H%M%S)
            echo -e "${GREEN}✓${NC}"
        else
            echo -e "${YELLOW}⚠${NC}"
        fi
        
        # 执行升级
        echo -n "执行升级... "
        if [ -f "update.sh" ] || [ -f "update" ]; then
            # 使用现有的更新脚本
            bash update.sh 2>/dev/null || bash update 2>/dev/null || true
            echo -e "${GREEN}✓${NC}"
            print_message "$GREEN" "✓ NapcatQQ升级完成"
            return 0
        else
            echo -e "${YELLOW}⚠${NC}"
            print_message "$YELLOW" "未找到升级脚本，将尝试重新安装"
        fi
    fi
    
    # 如果存在但没有指定目录，检查标准位置
    if [ "$NAPCAT_EXISTS" = true ] && [ -z "${NAPCAT_DIR:-}" ]; then
        local standard_dirs=(
            "/opt/NapCatQQ"
            "/root/Napcat"
            "/root/NapCatQQ"
        )
        
        for dir in "${standard_dirs[@]}"; do
            if [ -d "$dir" ]; then
                NAPCAT_DIR="$dir"
                print_message "$YELLOW" "使用现有目录: $NAPCAT_DIR"
                
                # 询问是否删除后重新安装
                read -p "是否删除现有目录并重新安装？(y/N): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    echo -n "删除目录... "
                    rm -rf "$NAPCAT_DIR"
                    echo -e "${GREEN}✓${NC}"
                    NAPCAT_EXISTS=false
                else
                    # 尝试升级
                    cd "$NAPCAT_DIR" || return 1
                    if [ -f "update.sh" ]; then
                        bash update.sh >> "$INSTALL_LOG" 2>&1
                        print_message "$GREEN" "✓ NapcatQQ升级完成"
                        return 0
                    fi
                fi
                break
            fi
        done
    fi
    
    # 全新安装或重新安装
    echo -n "创建临时目录... "
    mkdir -p "$TEMP_DIR/napcatqq"
    cd "$TEMP_DIR/napcatqq" || return 1
    echo -e "${GREEN}✓${NC}"
    
    echo -n "下载安装脚本... "
    retry_command $MAX_RETRIES $RETRY_DELAY "curl -o napcat.sh https://nclatest.znin.net/NapNeko/NapCat-Installer/main/script/install.sh" "下载NapcatQQ安装脚本" || return 1
    
    echo -n "设置执行权限... "
    chmod +x napcat.sh
    echo -e "${GREEN}✓${NC}"
    
    echo -n "执行安装... "
    silent_install "bash napcat.sh --docker n --cli n" "安装NapcatQQ" || return 1
    
    print_message "$GREEN" "✓ NapcatQQ安装完成"
    
    return 0
}
# 安装coplar
install_coplar() {
    print_header "安装 Cpolar"
    
    echo -n "下载安装脚本... "
    retry_command $MAX_RETRIES $RETRY_DELAY "curl -L https://www.cpolar.com/static/downloads/install-release-cpolar.sh -o /tmp/install-cpolar.sh" "下载Cpolar安装脚本" || return 1
    
    echo -n "执行安装... "
    silent_install "bash /tmp/install-cpolar.sh" "安装Cpolar" || return 1
    
    print_message "$GREEN" "✓ Cpolar安装完成"
    return 0
}

# 安装1panle
install_1panle() {
    print_header "安装 1Panel"
    
    # 检查现有服务
    if systemctl is-active --quiet 1panel; then
        print_message "$YELLOW" "⚠ 检测到1Panel服务已在运行"
        return 0
    fi
    
    echo -n "下载安装脚本... "
    retry_command $MAX_RETRIES $RETRY_DELAY "curl -sSL https://resource.fit2cloud.com/1panel/package/v2/quick_start.sh -o /tmp/1panel-install.sh" "下载1Panel安装脚本" || return 1
    
    # 使脚本可执行
    chmod +x /tmp/1panel-install.sh
    
    echo ""
    print_message "$YELLOW" "注意：即将开始安装1Panel，安装过程需要用户交互"
    print_message "$YELLOW" "请按照提示完成安装配置"
    echo ""
    print_message "$CYAN" "按 Enter 键开始安装..."
    read -r
    
    # 保存当前终端设置
    local old_stty
    old_stty=$(stty -g)
    
    # 执行安装脚本（交互式）
    if /tmp/1panel-install.sh; then
        stty "$old_stty"  # 恢复终端设置
        echo ""
        print_message "$GREEN" "✓ 1Panel安装完成"
        return 0
    else
        stty "$old_stty"  # 恢复终端设置
        echo ""
        print_message "$RED" "✗ 1Panel安装失败"
        return 1
    fi
}

# 分步安装依赖函数
install_dependencies_step_by_step() {
    echo "  ↳ 尝试分步安装依赖..."
    
    # 创建一个临时requirements.txt，逐个安装
    local temp_req="/tmp/requirements_step.txt"
    
    # 首先尝试安装小包
    echo "asyncio" > "$temp_req"
    echo "aiohttp" >> "$temp_req"
    
    if timeout 180 .venv/bin/pip install --default-timeout=60 -r "$temp_req"; then
        # 安装剩余的依赖
        rm -f "$temp_req"
        # 排除已经安装的包
        grep -v -E "^(asyncio|aiohttp)" requirements.txt > "$temp_req"
        
        if timeout 600 .venv/bin/pip install --default-timeout=120 -r "$temp_req"; then
            rm -f "$temp_req"
            return 0
        else
            rm -f "$temp_req"
            return 1
        fi
    else
        rm -f "$temp_req"
        return 1
    fi
}

# 安装mofox-core
install_mofox() {
    print_header "安装 MoFox-Core"
    
    local start_time=$(date +%s)
    
    # ============================================
    # 新增：检查现有目录
    # ============================================
    
    local mofox_dir="$HOME/MoFox_Bot_Deployment"
    local mofox_core_dir="$mofox_dir/MoFox-Core"
    
    if [ -d "$mofox_core_dir" ] && [ "$SKIP_SYSTEM_CHECK" = false ]; then
        print_message "$YELLOW" "检测到现有MoFox-Core目录，跳过克隆步骤"
        cd "$mofox_core_dir" || return 1
        
        # 检查是否需要重新安装依赖
        if [ ! -d ".venv" ] || [ ! -f ".venv/bin/python" ]; then
            print_message "$YELLOW" "虚拟环境不存在或损坏，需要重新安装依赖"
        else
            print_message "$GREEN" "虚拟环境已存在，跳过依赖安装"
            # 直接进入配置步骤
            if configure_existing_mofox; then
                local end_time=$(date +%s)
                local duration=$((end_time - start_time))
                print_message "$GREEN" "✓ MoFox-Core配置完成 (用时: ${duration}秒)"
                return 0
            else
                print_message "$RED" "✗ 现有MoFox-Core配置失败"
                return 1
            fi
        fi
    fi
    
    # 步骤1：安装系统依赖
    echo -n "安装系统依赖包... "
    silent_install "apt update && apt install -y sudo git curl python3 python3-pip python3-venv build-essential screen" "安装系统依赖包" || return 1
    
    # 步骤2：安装uv
    echo -n "安装UV包管理器... "
    silent_install "pip3 install uv --break-system-packages -i https://repo.huaweicloud.com/repository/pypi/simple" "安装UV包管理器" || return 1
    
    # 步骤3：配置环境变量
    echo -n "配置环境变量... "
    if ! grep -q "\.local/bin" ~/.bashrc; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    fi
    export PATH="$HOME/.local/bin:$PATH"
    echo -e "${GREEN}✓${NC}"
    
    # 步骤4：验证依赖版本
    echo -n "验证依赖版本... "
    local python_version
    python_version=$(python3 --version 2>&1 | cut -d' ' -f2)
    local python_major
    python_major=$(echo "$python_version" | cut -d'.' -f1)
    local python_minor
    python_minor=$(echo "$python_version" | cut -d'.' -f2)
    
    if [ "$python_major" -eq 3 ] && [ "$python_minor" -ge 11 ]; then
        echo -e "${GREEN}✓ Python版本满足要求: $python_version${NC}"
    else
        echo -e "${RED}✗ Python版本不满足要求 (需要 >= 3.11, 当前: $python_version)${NC}"
        return 1
    fi
    
    if ! command -v git &> /dev/null; then
        echo -e "${RED}✗ Git未正确安装${NC}"
        return 1
    fi
    echo -e "${GREEN}✓ Git安装成功${NC}"
    
    if ! command -v uv &> /dev/null; then
        echo -e "${RED}✗ UV未正确安装${NC}"
        return 1
    fi
    echo -e "${GREEN}✓ UV安装成功${NC}"
    
    # 步骤5：创建工作目录
    echo -n "创建工作目录... "
    cd ~ || return 1
    mkdir -p MoFox_Bot_Deployment
    cd MoFox_Bot_Deployment || return 1
    echo -e "${GREEN}✓${NC}"

   # 步骤6：智能克隆MoFox-Core仓库
    echo -n "克隆MoFox-Core仓库... "
    
    # GitHub源测速
    declare -A github_sources=(
        ["direct"]="https://github.com/MoFox-Studio/MoFox-Core.git"
        ["ghproxy"]="https://ghproxy.com/https://github.com/MoFox-Studio/MoFox-Core.git"
    )
    
    # 测速函数
    test_github_speed() {
        local source_name=$1
        local test_url=""
        
        case $source_name in
            "direct") test_url="https://github.com" ;;
            "ghproxy") test_url="https://ghproxy.com" ;;
        esac
        
        local speed
        speed=$(curl -o /dev/null -s -w "%{time_connect}\n" --connect-timeout 5 "$test_url" 2>/dev/null || echo "9999")
        local speed_ms
        speed_ms=$(echo "$speed * 1000" | bc 2>/dev/null | cut -d'.' -f1)
        echo "${speed_ms:-9999}"
    }
    
    # 测速选择
    local best_source="direct"
    local best_speed=9999
    
    for source_name in "${!github_sources[@]}"; do
        local speed
        speed=$(test_github_speed "$source_name")
        if [ "$speed" -lt "$best_speed" ]; then
            best_speed="$speed"
            best_source="$source_name"
        fi
    done
    
    local selected_url="${github_sources[$best_source]}"
    
    # 克隆仓库
    if ! git clone "$selected_url"; then
        echo -e "${RED}✗ MoFox-Core仓库克隆失败${NC}"
        return 1
    fi
    echo -e "${GREEN}✓ MoFox-Core仓库克隆成功${NC}"    
fi    # 步骤7：进入项目目录
    echo -n "进入项目目录... "
    cd MoFox-Core || return 1
    echo -e "${GREEN}✓${NC}"
    
    # 步骤8：创建虚拟环境（关键步骤）
    echo -n "创建虚拟环境... "
    if uv venv --python python3 >> "$INSTALL_LOG" 2>&1; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
        print_message "$RED" "虚拟环境创建失败"
        return 1
    fi
    
# 步骤8.5：为llvmlite创建独立的Python 3.9环境
setup_python39_for_llvmlite() {
    echo "为llvmlite创建独立的Python 3.9环境..."
    
    # 检查是否已安装Python 3.9
    if ! command -v python3.9 &> /dev/null; then
        echo "未找到Python 3.9，开始安装..."
        
        # 根据不同系统安装Python 3.9
        if [ -f /etc/debian_version ] || [ -f /etc/debian_release ]; then
            # Debian/Ubuntu
            apt-get update
            apt-get install -y python3.9 python3.9-venv python3.9-dev
        elif [ -f /etc/redhat-release ] || [ -f /etc/centos-release ]; then
            # RHEL/CentOS
            yum install -y python39 python39-devel
        elif [ -f /etc/arch-release ]; then
            # Arch Linux
            pacman -S python39 --noconfirm
        elif [ -f /etc/alpine-release ]; then
            # Alpine Linux
            apk add python39 py3-pip
        else
            echo "无法自动安装Python 3.9，请手动安装"
            echo "可以尝试: https://www.python.org/downloads/"
            return 1
        fi
    fi
    
    # 创建独立的Python 3.9虚拟环境
    echo "创建独立的Python 3.9虚拟环境..."
    python3.9 -m venv .venv-llvmlite
    
    # 激活环境并安装llvmlite
    echo "在Python 3.9环境中安装llvmlite..."
    if source .venv-llvmlite/bin/activate && \
       .venv-llvmlite/bin/pip install llvmlite==0.36.0; then
        echo "✅ Python 3.9环境中llvmlite安装成功"
        deactivate
        return 0
    else
        echo "❌ Python 3.9环境中llvmlite安装失败"
        deactivate
        return 1
    fi
}

# 步骤9：在虚拟环境中安装Python依赖（带重试机制）
echo "安装Python依赖..."

# 检查是否需要使用独立的Python 3.9环境
check_python_version_for_llvmlite() {
    local python_version
    python_version=$(python --version 2>&1 | awk '{print $2}')
    
    # 检查是否是Python 3.12或更高版本（llvmlite 0.36.0不支持）
    local major
    local minor
    major=$(echo "$python_version" | cut -d. -f1)
    minor=$(echo "$python_version" | cut -d. -f2)
    
    if [ "$major" -eq 3 ] && [ "$minor" -ge 12 ]; then
        echo "检测到Python $python_version，llvmlite 0.36.0需要Python 3.9"
        return 0  # 需要独立环境
    else
        echo "Python $python_version 兼容llvmlite 0.36.0"
        return 1  # 不需要独立环境
    fi
}

# 如果Python版本>=3.12，设置独立环境
if check_python_version_for_llvmlite; then
    echo "当前Python版本不兼容llvmlite 0.36.0"
    
    # 询问用户是否要使用独立环境
    read -p "是否要为llvmlite创建独立的Python 3.9环境？(y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # 方案1：使用独立的Python 3.9环境
        setup_python39_for_llvmlite
        
        # 修改requirements.txt，排除llvmlite
        echo "修改requirements.txt，排除llvmlite..."
        if [ -f requirements.txt ]; then
            # 备份原文件
            cp requirements.txt requirements.txt.backup
            
            # 创建不包含llvmlite的requirements
            grep -v llvmlite requirements.txt > requirements_no_llvmlite.txt
            
            # 安装其他依赖
            echo "安装其他Python依赖..."
        fi
    else
        # 方案2：尝试安装兼容版本
        echo "尝试安装兼容的llvmlite版本..."
        if ! .venv/bin/pip install llvmlite==0.41.1 2>/dev/null; then
            echo "尝试从源码安装llvmlite..."
            .venv/bin/pip install --no-binary llvmlite llvmlite
        fi
    fi
fi

# 方法1：使用uv指定Python路径（重试3次）
echo -n "  ↳ 尝试方法1 (使用uv指定python路径)... "

# 如果有修改后的requirements文件，使用它
if [ -f requirements_no_llvmlite.txt ]; then
    REQUIREMENTS_FILE="requirements_no_llvmlite.txt"
else
    REQUIREMENTS_FILE="requirements.txt"
fi

if retry_command $MAX_RETRIES $RETRY_DELAY "UV_LINK_MODE=copy uv pip install --python .venv/bin/python -r $REQUIREMENTS_FILE" "方法1: uv安装依赖"; then
    echo -e "\r${GREEN}  ✓ 依赖安装成功 (使用uv指定python路径)${NC}"
    
    # 如果使用了独立的llvmlite环境，添加环境变量
    if [ -d ".venv-llvmlite" ]; then
        echo "设置LLVM环境变量..."
        export LLVM_CONFIG=$(pwd)/.venv-llvmlite/bin/llvm-config
    fi
else
    echo -e "\r${RED}  ✗ 方法1失败${NC}"
    
    # 方法2：先激活虚拟环境再使用uv（重试3次）
    echo -n "  ↳ 尝试方法2 (激活环境后使用uv)... "
    if retry_command $MAX_RETRIES $RETRY_DELAY "source .venv/bin/activate && uv pip install -r $REQUIREMENTS_FILE" "方法2: 激活环境后uv安装"; then
        echo -e "\r${GREEN}  ✓ 依赖安装成功 (激活环境后使用uv)${NC}"
        
        # 如果使用了独立的llvmlite环境，添加环境变量
        if [ -d ".venv-llvmlite" ]; then
            echo "设置LLVM环境变量..."
            export LLVM_CONFIG=$(pwd)/.venv-llvmlite/bin/llvm-config
            # 写入激活脚本，使环境变量永久生效
            echo "export LLVM_CONFIG=$(pwd)/.venv-llvmlite/bin/llvm-config" >> .venv/bin/activate
        fi
    else
        echo -e "\r${RED}  ✗ 方法2失败${NC}"
        print_message "$RED" "依赖安装完全失败"
        return 1
    fi
fi

# 清理临时文件
if [ -f requirements_no_llvmlite.txt ]; then
    rm -f requirements_no_llvmlite.txt
fi
    # 步骤10：配置环境文件（使用虚拟环境中的Python）
    echo -n "配置环境文件... "
    cp template/template.env .env 2>> "$INSTALL_LOG"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${YELLOW}⚠${NC}"
        print_message "$YELLOW" "环境文件创建失败，继续安装"
    fi
    
    # 步骤11：用户协议确认
    echo -n "确认用户协议... "
    sed -i 's/^EULA_CONFIRMED=.*/EULA_CONFIRMED=true/' .env
    echo -e "${GREEN}✓${NC}"
    
    # 步骤12：创建config目录
    echo -n "创建配置目录... "
    mkdir -p config
    echo -e "${GREEN}✓${NC}"
    
    # 步骤13：配置机器人文件
    echo -n "配置机器人文件... "
    if [ -f "template/bot_config_template.toml" ]; then
        cp template/bot_config_template.toml config/bot_config.toml 2>> "$INSTALL_LOG"
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${YELLOW}⚠${NC}"
        print_message "$YELLOW" "未找到机器人配置模板"
    fi
    
    # 步骤14：配置QQ账号
    echo ""
    read -p "请输入机器人的QQ号 (9-11位数字): " qq_number
    
    if [[ "$qq_number" =~ ^[0-9]{9,11}$ ]]; then
        local config_file="config/bot_config.toml"
        if [ -f "$config_file" ]; then
            sed -i "s/^\s*qq_account\s*=.*/qq_account = $qq_number/" "$config_file" 2>> "$INSTALL_LOG"
            sed -i "s/^\s*platform\s*=.*/platform = \"qq\"/" "$config_file" 2>> "$INSTALL_LOG"
            echo -e "${GREEN}✓ 机器人QQ号配置成功: $qq_number${NC}"
        else
            echo -e "${YELLOW}⚠ 配置文件不存在，跳过QQ配置${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ QQ号格式错误，跳过配置${NC}"
    fi
    
    # 步骤15：配置主人QQ
    echo ""
    read -p "请输入主人QQ号 (9-11位数字): " master_qq
    
    if [[ "$master_qq" =~ ^[0-9]{9,11}$ ]]; then
        local config_file="config/bot_config.toml"
        
        # 直接替换注释掉的示例配置
        sed -i "s/^master_users = \[\]# \[.*\]/master_users = [[\"qq\", \"$master_qq\"]]/" "$config_file" 2>> "$INSTALL_LOG"
        
        # 如果上面的替换没匹配到（可能是空数组）
        sed -i "s/^master_users = \[\]/master_users = [[\"qq\", \"$master_qq\"]]/" "$config_file" 2>> "$INSTALL_LOG"
        
        echo -e "${GREEN}✓ 主人QQ号配置成功: $master_qq${NC}"
    else
        echo -e "${YELLOW}⚠ 主人QQ号格式错误，跳过配置${NC}"
    fi
    
    # 步骤16：配置模型文件
    echo -n "配置模型文件... "
    if [ -f "template/model_config_template.toml" ]; then
        cp template/model_config_template.toml config/model_config.toml 2>> "$INSTALL_LOG"
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${YELLOW}⚠${NC}"
        print_message "$YELLOW" "未找到模型配置模板"
    fi
    
    # 步骤17：配置API密钥
    echo ""
    read -p "请输入硅基流动API密钥 (输入'skip'跳过): " api_key
    
    if [ "$api_key" != "skip" ] && [ "$api_key" != "SKIP" ] && [ -n "$api_key" ]; then
        if [ -f "config/model_config.toml" ]; then
            # 简化API密钥配置
            sed -i '0,/api_key\s*=/s/api_key\s*=.*/api_key = "'"$api_key"'"/' config/model_config.toml 2>> "$INSTALL_LOG"
            echo -e "${GREEN}✓ API密钥配置成功${NC}"
        else
            echo -e "${YELLOW}⚠ 模型配置文件不存在，跳过API配置${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ 跳过API密钥配置${NC}"
    fi
    
    # 步骤18：验证环境
    echo -n "验证安装环境... "
    if [ -f ".venv/bin/python" ] && [ -f "pyproject.toml" ]; then
        # 使用虚拟环境中的Python验证版本
        local venv_python_version
        venv_python_version=$(.venv/bin/python --version 2>&1 | cut -d' ' -f2)
        echo -e "${GREEN}✓${NC}"
        echo -e "${GREEN}虚拟环境Python版本: $venv_python_version${NC}"
    else
        echo -e "${YELLOW}⚠${NC}"
        echo -e "${YELLOW}环境验证警告${NC}"
    fi
    
    # 步骤19：首次启动以生成配置文件
    echo ""
    print_message "$YELLOW" "即将首次启动MoFox-Core以生成插件配置文件..."
    print_message "$YELLOW" "这可能需要几分钟时间，请耐心等待..."
    echo ""
    
    # 确保在MoFox-Core目录中
    cd ~/MoFox_Bot_Deployment/MoFox-Core || return 1
    
    # 创建日志文件用于监控
    local first_run_log="/tmp/mofox_first_run_$(date +%Y%m%d_%H%M%S).log"
    
    # 启动前的准备工作
    echo -n "准备启动环境... "
    
    # 检查虚拟环境是否存在
    if [ ! -f ".venv/bin/python" ]; then
        echo -e "${RED}✗${NC}"
        print_message "$RED" "虚拟环境不存在，无法启动"
        return 1
    fi
    
    echo -e "${GREEN}✓${NC}"
    
    # 使用虚拟环境中的Python运行bot.py
    echo -n "启动MoFox-Core... "
    nohup .venv/bin/python bot.py > "$first_run_log" 2>&1 &
    local mofox_pid=$!
    echo -e "${GREEN}✓${NC} (PID: $mofox_pid)"
    
    # 等待并监控日志
    echo -n "等待配置文件生成... "
    local timeout=300  # 5分钟超时
    local start_time2=$(date +%s)
    local found_success=false
    
    while true; do
        # 检查进程是否还在运行
        if ! kill -0 $mofox_pid 2>/dev/null; then
            echo -e "\r${YELLOW}⚠ MoFox-Core进程已意外停止${NC}"
            break
        fi
        
        # 检查是否超时
        local current_time=$(date +%s)
        local elapsed_time=$((current_time - start_time2))
        
        if [ $elapsed_time -ge $timeout ]; then
            echo -e "\r${YELLOW}⚠ 等待超时（${timeout}秒）${NC}"
            break
        fi
        
        # 检查日志中是否有成功信息
        if grep -q "程序执行完成，按 Ctrl+C 退出" "$first_run_log" 2>/dev/null; then
            found_success=true
            break
        fi
        
        # 显示等待进度
        local progress=$((elapsed_time * 100 / timeout))
        printf "\r${BLUE}等待配置文件生成... %d%%${NC}" "$progress"
        
        sleep 2
    done
    
    # 停止MoFox-Core进程
    echo -n "停止MoFox-Core... "
    kill $mofox_pid 2>/dev/null
    wait $mofox_pid 2>/dev/null
    echo -e "${GREEN}✓${NC}"
    
    # 检查结果
    if [ "$found_success" = true ]; then
        echo -e "${GREEN}✓ 配置文件生成成功${NC}"
        
        # 显示生成的文件信息
        echo ""
        print_message "$CYAN" "已生成以下配置文件："
        
        if [ -d "config/plugins" ]; then
            local plugin_count
            plugin_count=$(find config/plugins -name "*.toml" -o -name "*.yaml" -o -name "*.yml" 2>/dev/null | wc -l)
            if [ $plugin_count -gt 0 ]; then
                echo "  - 插件配置文件: $plugin_count 个"
                find config/plugins -name "*.toml" -o -name "*.yaml" -o -name "*.yml" 2>/dev/null | head -5 | while read file; do
                    echo "    * $(basename "$file")"
                done
            fi
        fi
        
        if [ -d "config" ]; then
            local config_count
            config_count=$(find config -maxdepth 1 -name "*.toml" -o -name "*.json" -o -name "*.yaml" 2>/dev/null | wc -l)
            if [ $config_count -gt 0 ]; then
                echo "  - 主要配置文件: $config_count 个"
            fi
        fi
    else
        echo -e "${YELLOW}⚠ 配置文件生成可能未完全完成${NC}"
        echo -e "${YELLOW}但将继续进行后续安装步骤...${NC}"
    fi
    
    # 显示最后几行日志供用户参考
    echo ""
    print_message "$CYAN" "最后几行启动日志："
    tail -n 10 "$first_run_log" 2>/dev/null | while read line; do
        echo "  $line"
    done
    echo ""
    
    # 清理临时日志文件
    rm -f "$first_run_log"
    
    # 步骤20：配置Napcat插件
    echo -n "配置Napcat插件... "
    mkdir -p config/plugins/napcat_adapter
    if [ -f "template/plugins/napcat_adapter/config.toml" ]; then
        cp template/plugins/napcat_adapter/config.toml config/plugins/napcat_adapter/
        sed -i 's/enabled = false/enabled = true/' config/plugins/napcat_adapter/config.toml 2>> "$INSTALL_LOG"
        echo -e "${GREEN}✓${NC}"
    elif [ -f "plugins/napcat_adapter/template_config.toml" ]; then
        cp plugins/napcat_adapter/template_config.toml config/plugins/napcat_adapter/config.toml
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${YELLOW}⚠${NC}"
        echo -e "${YELLOW}未找到Napcat插件模板，跳过配置${NC}"
    fi
    
    # 步骤21：配置端口
    echo ""
    read -p "请输入Napcat服务器端口 (默认: 8080): " port
    port=${port:-8080}
    
    if [[ "$port" =~ ^[0-9]+$ ]] && [ "$port" -ge 1024 ] && [ "$port" -le 65535 ]; then
        local plugin_config="config/plugins/napcat_adapter/config.toml"
        if [ -f "$plugin_config" ]; then
            sed -i "s/port = .*/port = $port/" "$plugin_config" 2>> "$INSTALL_LOG"
            echo -e "${GREEN}✓ 端口配置成功: $port${NC}"
        else
            echo -e "${YELLOW}⚠ 插件配置文件不存在，端口配置失败${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ 端口号无效，使用默认端口: 8080${NC}"
    fi
    
    # 步骤22：测试虚拟环境
    echo -n "测试虚拟环境... "
    if .venv/bin/python -c "import sys; print('Python', sys.version)" >> "$INSTALL_LOG" 2>&1; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
        echo -e "${YELLOW}虚拟环境测试失败${NC}"
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    print_message "$GREEN" "✓ MoFox-Core安装完成"
    
    # 显示完成信息
    echo ""
    print_message "$CYAN" "╔══════════════════════════════════════════════════════════╗"
    print_message "$CYAN" "║                    MoFox-Core 安装完成                   ║"
    print_message "$CYAN" "╠══════════════════════════════════════════════════════════╣"
    print_message "$GREEN" "║  总用时: ${duration}秒                                 ║"
    print_message "$GREEN" "║  项目目录: $(pwd)                                     ║"
    print_message "$GREEN" "║  虚拟环境: .venv/                                      ║"
    print_message "$CYAN" "║                                                          ║"
    print_message "$YELLOW" "║  重要: 所有依赖已安装在虚拟环境中                    ║"
    print_message "$YELLOW" "║                                                          ║"
    print_message "$YELLOW" "║  启动方式:                                            ║"
    print_message "$YELLOW" "║  1. 手动激活虚拟环境: source .venv/bin/activate        ║"
    print_message "$YELLOW" "║  2. 然后运行: python bot.py                            ║"
    print_message "$YELLOW" "║                                                          ║"
    print_message "$YELLOW" "║  或使用完整路径直接运行:                              ║"
    print_message "$YELLOW" "║  .venv/bin/python bot.py                               ║"
    print_message "$CYAN" "╚══════════════════════════════════════════════════════════╝"
    echo ""
    
    return 0
}

# ============================================
# 主脚本开始
# ============================================

# 创建日志文件
mkdir -p "$(dirname "$INSTALL_LOG")"
touch "$INSTALL_LOG"

# 记录开始时间
START_TIME=$(date +%s)
log_message "脚本开始执行"

# 显示欢迎信息
clear
print_mofox_ascii
print_header "$SCRIPT_NAME v$SCRIPT_VERSION"

# 首先检查MoFox目录
check_mofox_directory
check_mofox_result=$?

# 然后检查Napcat目录（如果用户选择了安装NapcatQQ）
if [ "$INSTALL_NAPCATQQ" = true ]; then
    check_napcat_directory
    check_napcat_result=$?
fi

# 根据检查结果决定流程
if [ "$SKIP_SYSTEM_CHECK" = true ] && [ $check_mofox_result -eq 3 ]; then
    # 快速安装模式
    # ... 快速安装代码 ...
    # 快速安装模式
    echo ""
    print_message "$CYAN" "╔══════════════════════════════════════════════════════════╗"
    print_message "$CYAN" "║                     快速安装模式                         ║"
    print_message "$CYAN" "╠══════════════════════════════════════════════════════════╣"
    print_message "$GREEN" "║  ✓ 跳过系统检查                                        ║"
    print_message "$GREEN" "║  ✓ 跳过系统更新                                        ║"
    print_message "$GREEN" "║  ✓ 直接进入软件安装                                    ║"
    print_message "$CYAN" "╚══════════════════════════════════════════════════════════╝"
    echo ""
    
    # 等待用户确认
    read -p "是否开始快速安装？(Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ ! -z "$REPLY" ]]; then
        print_message "$YELLOW" "安装已取消。"
        exit 0
    fi
    
    # 执行快速安装
    quick_install_mode
    
    # 快速安装完成后，跳到完成部分
    goto_installation_complete
    exit $?
fi

# 正常安装流程（原有流程）
echo ""
print_message "$CYAN" "╔══════════════════════════════════════════════════════════╗"
print_message "$CYAN" "║                     正常安装模式                         ║"
print_message "$CYAN" "╠══════════════════════════════════════════════════════════╣"
print_message "$GREEN" "║  ✓ 自动重试机制 (最大重试: $MAX_RETRIES 次)              ║"
print_message "$GREEN" "║  ✓ 详细日志记录: $INSTALL_LOG                     ║"
print_message "$GREEN" "║  ✓ 虚拟环境支持 (自动创建和配置)                         ║"
print_message "$GREEN" "║  ✓ 增强网络测速 (智能选择最快GitHub源)                   ║"
print_message "$CYAN" "╚══════════════════════════════════════════════════════════╝"
echo ""

# 等待用户确认
read -p "是否开始安装？(Y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ ! -z "$REPLY" ]]; then
    print_message "$YELLOW" "安装已取消。"
    exit 0
fi

# ============================================
# 系统检查和准备（正常模式）
# ============================================
print_header "系统检查"

print_message "$BLUE" "正在进行系统检查..."
check_root
check_architecture
check_network

# 选择安装软件
select_software

# ============================================
# 系统更新
# ============================================
if ! update_system; then
    print_message "$RED" "系统更新失败，安装终止"
    exit 1
fi

# ============================================
# 安装依赖
# ============================================
if ! install_dependencies; then
    print_message "$RED" "依赖安装失败，安装终止"
    exit 1
fi

# ============================================
# 软件安装
# ============================================
print_header "软件安装"

# 安装NapcatQQ
if [ "$INSTALL_NAPCATQQ" = true ]; then
    if ! install_napcatqq; then
        print_message "$RED" "✗ NapcatQQ安装失败"
        log_message "NapcatQQ安装失败"
        # 询问是否继续
        read -p "是否继续安装其他软件？(Y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            exit 1
        fi
    fi
fi

# 安装coplar
if [ "$INSTALL_COPLAR" = true ]; then
    if ! install_coplar; then
        print_message "$RED" "✗ coplar安装失败"
        log_message "coplar安装失败"
        # 询问是否继续
        read -p "是否继续安装其他软件？(Y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            exit 1
        fi
    fi
fi

# 安装1panle
if [ "$INSTALL_1PANLE" = true ]; then
    if ! install_1panle; then
        print_message "$RED" "✗ 1panle安装失败"
        log_message "1panle安装失败"
        # 询问是否继续
        read -p "是否继续安装其他软件？(Y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            exit 1
        fi
    fi
fi

# 安装MoFox-Core
if [ "$INSTALL_MOFOX" = true ]; then
    if ! install_mofox; then
        print_message "$RED" "✗ MoFox-Core安装失败"
        log_message "MoFox-Core安装失败"
        exit 1
    fi
fi

# ============================================
# 安装完成
# ============================================
goto_installation_complete

# 询问是否重启
read -p "是否现在重启系统？(y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_message "$YELLOW" "系统将在5秒后重启..."
    sleep 5
    reboot
fi

exit 0
