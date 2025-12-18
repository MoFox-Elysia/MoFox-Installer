#!/bin/bash

# ============================================
# Armbian软件自动安装脚本
# 适用于基于Debian 11的Armbian系统
# 作者：牡丹江市第一高级中学ACG社2023级社长越渊
# 创建日期：$(date +%Y-%m-%d)
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
SCRIPT_NAME="Armbian软件安装脚本"
SCRIPT_VERSION="1.0.0"
INSTALL_LOG="/var/log/armbian_install_$(date +%Y%m%d_%H%M%S).log"
TEMP_DIR="/tmp/armbian_install"

# 软件安装选项
INSTALL_MOFOX=true
INSTALL_NAPCATQQ=true
INSTALL_1PANLE=false
INSTALL_COPLAR=false

# ============================================
# 函数定义
# ============================================

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
    print_message "$RED" "║      ██████╗  ██████╗ ██╗  ██╗         ║"
    print_message "$MAGENTA" "║      ██╔══██╗██╔═══██╗╚██╗██╔╝         ║"
    print_message "$MAGENTA" "║      ██████╔╝██║   ██║ ╚███╔╝          ║"
    print_message "$CYAN" "║      ██╔══██╗██║   ██║ ██╔██╗          ║"
    print_message "$CYAN" "║      ██║  ██║╚██████╔╝██╔╝ ██╗         ║"
    print_message "$BLUE" "║      ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝         ║"
    print_message "$BLUE" "║                                       ║"
    print_message "$BLUE" "╚═══════════════════════════════════════╝"
}

# 检查是否以root权限运行
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_message "$RED" "错误：此脚本必须以root权限运行！"
        print_message "$YELLOW" "请使用 'sudo bash $0' 或 'su -c \"bash $0\"'"
        exit 1
    fi
}

# 检查系统架构
check_architecture() {
    local arch
    arch=$(uname -m)
    case $arch in
        armv7l|armv8l|aarch64|arm64)
            print_message "$GREEN" "✓ 系统架构支持: $arch"
            ;;
        *)
            print_message "$RED" "错误：不支持的架构: $arch"
            print_message "$YELLOW" "本脚本仅支持ARM架构的Armbian系统"
            exit 1
            ;;
    esac
}

# 检查操作系统
check_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" == "debian" && "$VERSION_ID" == "11" ]]; then
            print_message "$GREEN" "✓ 检测到 Debian 11 (Bullseye)"
        elif [[ "$ID" == "armbian" ]]; then
            print_message "$GREEN" "✓ 检测到 Armbian 系统"
        else
            print_message "$YELLOW" "⚠ 检测到 $PRETTY_NAME"
            print_message "$YELLOW" "本脚本主要针对Debian 11 Armbian系统，继续运行可能遇到兼容性问题。"
            read -p "是否继续？(y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 0
            fi
        fi
    else
        print_message "$RED" "错误：无法检测操作系统信息"
        exit 1
    fi
}

# 检查网络连接
check_network() {
    print_message "$BLUE" "检查网络连接..."
    if ping -c 1 -W 2 google.com > /dev/null 2>&1; then
        print_message "$GREEN" "✓ 网络连接正常"
    else
        print_message "$YELLOW" "⚠ 无法连接到互联网，但将继续执行..."
    fi
}

# 系统更新
update_system() {
    print_header "更新系统软件包"
    apt-get update
    apt-get upgrade -y
    apt-get autoremove -y
    apt-get clean
}

# 安装依赖包
install_dependencies() {
    print_header "安装依赖包"
    apt-get install -y \
        curl \
        wget \
        git \
        sudo \
        build-essential \
        software-properties-common \
        apt-transport-https \
        ca-certificates \
        gnupg \
        lsb-release \
        net-tools \
        htop \
        vim \
        nano
}

# 选择安装的软件
select_software() {
    print_header "选择安装的软件"
    
    # 询问是否安装1panle
    read -p "是否安装 1panle？(y/N): " -n 1 -r
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
}

# 记录日志
log_message() {
    local message=$1
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" | tee -a "$INSTALL_LOG"
}

# ============================================
# 软件安装函数
# ============================================

# 安装napcatqq
install_napcatqq() {
    print_header "安装 NapcatQQ"
    log_message "开始安装 NapcatQQ"
    
    print_message "$BLUE" "正在下载 NapcatQQ 安装脚本..."
    
    # 创建临时目录
    mkdir -p "$TEMP_DIR/napcatqq"
    cd "$TEMP_DIR/napcatqq" || exit 1
    
    # 下载安装脚本
    if curl -o napcat.sh https://nclatest.znin.net/NapNeko/NapCat-Installer/main/script/install.sh; then
        print_message "$GREEN" "✓ NapcatQQ 安装脚本下载成功"
    else
        print_message "$RED" "✗ NapcatQQ 安装脚本下载失败"
        log_message "NapcatQQ 安装脚本下载失败"
        return 1
    fi
    
    # 使脚本可执行
    chmod +x napcat.sh
    
    print_message "$BLUE" "正在安装 NapcatQQ (不使用Docker，使用CLI模式)..."
    log_message "执行NapcatQQ安装命令：--docker n --cli y"
    
    # 执行安装脚本
    if bash napcat.sh --docker n --cli y; then
        print_message "$GREEN" "✓ NapcatQQ 安装完成"
        log_message "NapcatQQ 安装完成"
        
        # 显示安装后信息
        echo ""
        print_message "$CYAN" "╔══════════════════════════════════════════════════════════╗"
        print_message "$CYAN" "║                                                          ║"
        print_message "$GREEN" "║  NapcatQQ 安装成功！                                   ║"
        print_message "$BLUE" "║                                                          ║"
        print_message "$YELLOW" "║  重要信息：                                           ║"
        print_message "$YELLOW" "║  1. 安装目录: /opt/NapCatQQ/                          ║"
        print_message "$YELLOW" "║  2. 配置文件: /opt/NapCatQQ/config/config.yaml        ║"
        print_message "$YELLOW" "║  3. 日志文件: /opt/NapCatQQ/logs/                     ║"
        print_message "$BLUE" "║                                                          ║"
        print_message "$YELLOW" "║  请编辑配置文件后启动服务：                            ║"
        print_message "$YELLOW" "║  systemctl start napcatqq                             ║"
        print_message "$CYAN" "║                                                          ║"
        print_message "$CYAN" "╚══════════════════════════════════════════════════════════╝"
        echo ""
        
        # 检查服务状态
        if systemctl is-active --quiet napcatqq; then
            print_message "$GREEN" "✓ NapcatQQ 服务正在运行"
        else
            print_message "$YELLOW" "⚠ NapcatQQ 服务未运行，请手动启动"
        fi
        
        return 0
    else
        print_message "$RED" "✗ NapcatQQ 安装失败"
        log_message "NapcatQQ 安装失败"
        return 1
    fi
}

# 安装coplar
install_coplar() {
    print_header "安装 coplar (Cpolar内网穿透)"
    log_message "开始安装 coplar"
    
    print_message "$BLUE" "正在安装 coplar 内网穿透工具..."
    log_message "开始执行coplar安装命令"
    
    # 记录开始时间
    local start_time=$(date +%s)
    
    # 执行安装命令
    if curl -L https://www.cpolar.com/static/downloads/install-release-cpolar.sh | sudo bash; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        print_message "$GREEN" "✓ coplar 安装成功 (用时: ${duration}秒)"
        log_message "coplar 安装成功，用时: ${duration}秒"
        
        # 检查安装结果
        if command -v cpolar &> /dev/null; then
            print_message "$GREEN" "✓ cpolar 命令已安装到系统路径"
            
            # 获取版本信息
            local cpolar_version=$(cpolar version 2>/dev/null || echo "未知版本")
            print_message "$BLUE" "  └── 版本: $cpolar_version"
            
            # 显示安装后信息
            echo ""
            print_message "$CYAN" "╔══════════════════════════════════════════════════════════╗"
            print_message "$CYAN" "║                                                          ║"
            print_message "$GREEN" "║  coplar (Cpolar) 安装成功！                            ║"
            print_message "$BLUE" "║                                                          ║"
            print_message "$YELLOW" "║  重要信息：                                           ║"
            print_message "$YELLOW" "║  1. 配置文件: /usr/local/cpolar/cpolar.yml            ║"
            print_message "$YELLOW" "║  2. 日志文件: /usr/local/cpolar/log/                  ║"
            print_message "$YELLOW" "║  3. 二进制文件: /usr/local/bin/cpolar                 ║"
            print_message "$BLUE" "║                                                          ║"
            print_message "$YELLOW" "║  使用说明：                                           ║"
            print_message "$YELLOW" "║  1. 配置认证令牌: cpolar authtoken <您的token>         ║"
            print_message "$YELLOW" "║  2. 启动服务: systemctl start cpolar                  ║"
            print_message "$YELLOW" "║  3. 开机自启: systemctl enable cpolar                 ║"
            print_message "$YELLOW" "║  4. 状态检查: cpolar status                           ║"
            print_message "$CYAN" "║                                                          ║"
            print_message "$CYAN" "╚══════════════════════════════════════════════════════════╝"
            echo ""
            
            # 检查服务状态
            if systemctl is-active --quiet cpolar; then
                print_message "$GREEN" "✓ cpolar 服务正在运行"
            else
                print_message "$YELLOW" "⚠ cpolar 服务未运行，需要手动配置认证令牌后启动"
                print_message "$YELLOW" "  请访问: https://dashboard.cpolar.com 获取认证令牌"
            fi
            
            # 询问是否配置开机自启
            read -p "是否设置 cpolar 开机自启？(Y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z "$REPLY" ]]; then
                systemctl enable cpolar
                print_message "$GREEN" "✓ cpolar 已设置开机自启"
                log_message "cpolar 已设置开机自启"
            fi
            
            return 0
        else
            print_message "$RED" "✗ cpolar 命令未找到，安装可能有问题"
            log_message "cpolar 命令未找到，安装可能失败"
            return 1
        fi
    else
        print_message "$RED" "✗ coplar 安装失败"
        log_message "coplar 安装失败"
        return 1
    fi
}

# 安装1panle
install_1panle() {
    print_header "安装 1Panel"
    log_message "开始安装 1Panel"
    
    print_message "$BLUE" "正在安装 1Panel 服务器管理面板..."
    log_message "开始执行1Panel安装命令"
    
    # 记录开始时间
    local start_time=$(date +%s)
    
    # 检查是否已有1Panel在运行
    if systemctl is-active --quiet 1panel; then
        print_message "$YELLOW" "⚠ 检测到1Panel服务已在运行"
        read -p "是否继续安装（这将停止现有服务）？(y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_message "$YELLOW" "跳过1Panel安装"
            log_message "用户取消1Panel安装（已有服务在运行）"
            return 0
        fi
    fi
    
    # 显示警告信息
    echo ""
    print_message "$YELLOW" "注意：1Panel安装需要较长时间，请耐心等待..."
    print_message "$YELLOW" "安装过程中会下载Docker和相关组件"
    print_message "$YELLOW" "在低性能设备上可能需要10-20分钟"
    echo ""
    
    # 询问是否继续
    read -p "是否继续安装1Panel？(Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ ! -z "$REPLY" ]]; then
        print_message "$YELLOW" "跳过1Panel安装"
        log_message "用户取消1Panel安装"
        return 0
    fi
    
    # 执行安装命令
    print_message "$BLUE" "正在下载并执行1Panel安装脚本..."
    print_message "$YELLOW" "请勿中断此过程，否则可能导致安装不完整"
    
    if bash -c "$(curl -sSL https://resource.fit2cloud.com/1panel/package/v2/quick_start.sh)"; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        print_message "$GREEN" "✓ 1Panel 安装成功 (用时: ${duration}秒)"
        log_message "1Panel 安装成功，用时: ${duration}秒"
        
        # 显示安装后信息
        echo ""
        print_message "$CYAN" "╔══════════════════════════════════════════════════════════╗"
        print_message "$CYAN" "║                                                          ║"
        print_message "$GREEN" "║  1Panel 安装成功！                                     ║"
        print_message "$BLUE" "║                                                          ║"
        print_message "$YELLOW" "║  重要访问信息：                                       ║"
        print_message "$YELLOW" "║  1. 访问地址: http://<服务器IP>:目标端口                ║"
        print_message "$YELLOW" "║  2. 默认端口: 可能在安装过程中显示                      ║"
        print_message "$YELLOW" "║  3. 用户名: 安装过程中设置                             ║"
        print_message "$YELLOW" "║  4. 密码: 安装过程中设置                               ║"
        print_message "$BLUE" "║                                                          ║"
        print_message "$YELLOW" "║  管理命令：                                           ║"
        print_message "$YELLOW" "║  1. 启动: systemctl start 1panel                      ║"
        print_message "$YELLOW" "║  2. 停止: systemctl stop 1panel                       ║"
        print_message "$YELLOW" "║  3. 状态: systemctl status 1panel                     ║"
        print_message "$YELLOW" "║  4. 重启: systemctl restart 1panel                    ║"
        print_message "$YELLOW" "║  5. 查看日志: journalctl -u 1panel -f                  ║"
        print_message "$CYAN" "║                                                          ║"
        print_message "$CYAN" "╚══════════════════════════════════════════════════════════╝"
        echo ""
        
        # 检查服务状态
        sleep 5  # 等待服务启动
        if systemctl is-active --quiet 1panel; then
            print_message "$GREEN" "✓ 1Panel 服务正在运行"
            
            # 尝试获取访问信息
            local panel_port=$(grep -i "port" /opt/1panel/conf/app.conf 2>/dev/null | grep -o '[0-9]*' | head -1)
            if [ -n "$panel_port" ]; then
                print_message "$BLUE" "  └── 服务端口: $panel_port"
            fi
            
            # 获取本机IP
            local server_ip=$(hostname -I | awk '{print $1}' | head -1)
            if [ -n "$server_ip" ]; then
                print_message "$BLUE" "  └── 服务器IP: $server_ip"
                print_message "$GREEN" "访问地址: http://$server_ip:$panel_port"
            fi
        else
            print_message "$YELLOW" "⚠ 1Panel 服务未运行，请手动启动"
            print_message "$YELLOW" "执行: systemctl start 1panel"
        fi
        
        # 询问是否配置开机自启
        if ! systemctl is-enabled --quiet 1panel 2>/dev/null; then
            read -p "是否设置 1Panel 开机自启？(Y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z "$REPLY" ]]; then
                systemctl enable 1panel
                print_message "$GREEN" "✓ 1Panel 已设置开机自启"
                log_message "1Panel 已设置开机自启"
            fi
        else
            print_message "$GREEN" "✓ 1Panel 已配置开机自启"
        fi
        
        return 0
    else
        print_message "$RED" "✗ 1Panel 安装失败"
        log_message "1Panel 安装失败"
        
        # 提供故障排查建议
        echo ""
        print_message "$YELLOW" "安装失败可能原因："
        print_message "$YELLOW" "1. 网络连接问题"
        print_message "$YELLOW" "2. 系统资源不足"
        print_message "$YELLOW" "3. Docker安装失败"
        print_message "$YELLOW" "4. 端口冲突"
        echo ""
        print_message "$YELLOW" "建议手动安装："
        print_message "$YELLOW" "curl -sSL https://resource.fit2cloud.com/1panel/package/v2/quick_start.sh -o 1panel.sh"
        print_message "$YELLOW" "bash 1panel.sh"
        
        return 1
    fi
}

# 安装mofox-core
install_mofox() {
    print_header "安装 MoFox-Core"
    log_message "开始安装 MoFox-Core"
    
    local start_time=$(date +%s)
    
    # 第一步：安装系统依赖包
    print_message "$BLUE" "步骤 1: 安装系统依赖包"
    if ! apt update; then
        print_message "$RED" "✗ 软件包列表更新失败"
        return 1
    fi
    
    if ! apt install -y sudo git curl python3 python3-pip python3-venv build-essential screen; then
        print_message "$RED" "✗ 系统依赖包安装失败"
        return 1
    fi
    print_message "$GREEN" "✓ 系统依赖包安装成功"
    
    # 第二步：安装 uv
    print_message "$BLUE" "步骤 2: 安装 UV Python包管理器"
    if ! pip3 install uv --break-system-packages -i https://repo.huaweicloud.com/repository/pypi/simple; then
        print_message "$RED" "✗ UV包管理器安装失败"
        return 1
    fi
    print_message "$GREEN" "✓ UV包管理器安装成功"
    
    # 第三步：配置环境变量
    print_message "$BLUE" "步骤 3: 配置环境变量"
    if ! grep -q "\.local/bin" ~/.bashrc; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    fi
    export PATH="$HOME/.local/bin:$PATH"
    print_message "$GREEN" "✓ 环境变量配置完成"
    
    # 第四步：验证依赖版本
    print_message "$BLUE" "步骤 4: 验证依赖版本"
    local python_version=$(python3 --version 2>&1 | cut -d' ' -f2)
    local python_major=$(echo $python_version | cut -d'.' -f1)
    local python_minor=$(echo $python_version | cut -d'.' -f2)
    
    if [ "$python_major" -eq 3 ] && [ "$python_minor" -ge 11 ]; then
        print_message "$GREEN" "✓ Python版本满足要求: $python_version"
    else
        print_message "$RED" "✗ Python版本不满足要求 (需要 >= 3.11, 当前: $python_version)"
        return 1
    fi
    
    if ! command -v git &> /dev/null; then
        print_message "$RED" "✗ Git未正确安装"
        return 1
    fi
    print_message "$GREEN" "✓ Git安装成功"
    
    if ! command -v uv &> /dev/null; then
        print_message "$RED" "✗ UV未正确安装"
        return 1
    fi
    print_message "$GREEN" "✓ UV安装成功"
    
    # 第五步：创建工作目录
    print_message "$BLUE" "步骤 5: 创建MoFox-Core工作目录"
    cd ~ || {
        print_message "$RED" "✗ 无法切换到用户主目录"
        return 1
    }
    
    mkdir -p MoFox_Bot_Deployment
    cd MoFox_Bot_Deployment || {
        print_message "$RED" "✗ 无法进入部署目录"
        return 1
    }
    print_message "$GREEN" "✓ 工作目录创建成功: $(pwd)"
    
    # 第六步：智能克隆MoFox-Core仓库
    print_message "$BLUE" "步骤 6: 克隆MoFox-Core仓库"
    
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
        
        local speed=$(curl -o /dev/null -s -w "%{time_connect}\n" --connect-timeout 5 "$test_url" 2>/dev/null || echo "9999")
        local speed_ms=$(echo "$speed * 1000" | bc 2>/dev/null | cut -d'.' -f1)
        echo "${speed_ms:-9999}"
    }
    
    # 测速选择
    local best_source="direct"
    local best_speed=9999
    
    for source_name in "${!github_sources[@]}"; do
        local speed=$(test_github_speed "$source_name")
        if [ "$speed" -lt "$best_speed" ]; then
            best_speed="$speed"
            best_source="$source_name"
        fi
    done
    
    local selected_url="${github_sources[$best_source]}"
    
    # 克隆仓库
    if ! git clone "$selected_url"; then
        print_message "$RED" "✗ MoFox-Core仓库克隆失败"
        return 1
    fi
    print_message "$GREEN" "✓ MoFox-Core仓库克隆成功"
    
    # 第七步：进入项目目录
    print_message "$BLUE" "步骤 7: 进入MoFox-Core目录"
    if [ ! -d "MoFox-Core" ]; then
        print_message "$RED" "✗ MoFox-Core目录不存在"
        return 1
    fi
    
    cd MoFox-Core || {
        print_message "$RED" "✗ 无法进入MoFox-Core目录"
        return 1
    }
    
    # 验证项目目录
    if [ ! -f "requirements.txt" ]; then
        print_message "$RED" "✗ 当前目录不是有效的MoFox-Core项目目录"
        return 1
    fi
    print_message "$GREEN" "✓ 已进入项目目录: $(pwd)"
    
    # 第八步：智能安装Python依赖
    print_message "$BLUE" "步骤 8: 安装Python依赖"
    
    # 依赖安装重试函数
    install_with_retry() {
        local dep="$1"
        
        # 方法1: uv + 阿里云镜像
        if uv pip install "$dep" -i https://mirrors.aliyun.com/pypi/simple; then
            return 0
        fi
        
        # 方法2: uv + copy模式
        if uv pip install --link-mode copy "$dep" -i https://mirrors.aliyun.com/pypi/simple; then
            return 0
        fi
        
        # 方法3: 环境变量方式
        if UV_LINK_MODE=copy uv pip install "$dep" -i https://mirrors.aliyun.com/pypi/simple; then
            return 0
        fi
        
        return 1
    }
    
    # 批量安装尝试
    if ! UV_LINK_MODE=copy uv pip install -r requirements.txt -i https://mirrors.aliyun.com/pypi/simple; then
        print_message "$YELLOW" "批量安装失败，开始逐个安装..."
        
        # 预处理requirements.txt
        local temp_req="/tmp/mofox_requirements_clean.txt"
        grep -E '^[^#]' requirements.txt | grep -v '^$' > "$temp_req"
        
        local success_count=0
        local fail_count=0
        local total_to_install=$(wc -l < "$temp_req")
        
        while IFS= read -r dep_line; do
            local dep=$(echo "$dep_line" | sed 's/[<>=!].*//' | xargs)
            
            if [ -z "$dep" ]; then
                continue
            fi
            
            if install_with_retry "$dep"; then
                ((success_count++))
                print_message "$GREEN" "  ✓ $dep"
            else
                ((fail_count++))
                print_message "$RED" "  ✗ $dep"
            fi
            
        done < "$temp_req"
        
        rm -f "$temp_req"
        
        if [ $fail_count -gt $((total_to_install / 2)) ]; then
            print_message "$RED" "✗ 超过半数依赖安装失败"
            return 1
        fi
        
        print_message "$GREEN" "✓ 依赖安装完成: $success_count/$total_to_install 成功"
    else
        print_message "$GREEN" "✓ 依赖安装成功"
    fi
    
    # 第九步：配置环境文件
    print_message "$BLUE" "步骤 9: 配置环境文件"
    if [ ! -f "template/template.env" ]; then
        print_message "$RED" "✗ 未找到环境模板文件: template/template.env"
        return 1
    fi
    
    cp template/template.env .env
    print_message "$GREEN" "✓ 环境文件创建成功"
    
    # 第十步：用户协议确认
    print_message "$BLUE" "步骤 10: 用户协议确认"
    
    show_eula() {
        clear
        print_message "$CYAN" "╔══════════════════════════════════════════════════════════╗"
        print_message "$CYAN" "║                  MoFox-Core 用户协议                      ║"
        print_message "$CYAN" "╠══════════════════════════════════════════════════════════╣"
        print_message "$YELLOW" "║  重要声明：                                            ║"
        print_message "$YELLOW" "║  1. 本软件仅供学习和研究使用                          ║"
        print_message "$YELLOW" "║  2. 禁止用于任何违法用途                              ║"
        print_message "$YELLOW" "║  3. 使用者需遵守当地法律法规                          ║"
        print_message "$YELLOW" "║  4. 开发者不承担任何使用责任                          ║"
        print_message "$CYAN" "╚══════════════════════════════════════════════════════════╝"
        echo ""
    }
    
    show_eula
    
    read -p "您是否同意以上用户协议？(Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        print_message "$RED" "✗ 您必须同意用户协议才能使用 MoFox-Core"
        return 1
    fi
    
    # 更新.env文件中的EULA_CONFIRMED值
    sed -i 's/^EULA_CONFIRMED=.*/EULA_CONFIRMED=true/' .env
    print_message "$GREEN" "✓ 用户协议已确认"
    
    # 第十一步：创建config目录
    print_message "$BLUE" "步骤 11: 创建config目录"
    mkdir -p config
    print_message "$GREEN" "✓ config目录创建成功"
    
    # 第十二步：复制机器人配置文件模板
    print_message "$BLUE" "步骤 12: 配置机器人配置文件"
    if [ ! -f "template/bot_config_template.toml" ]; then
        print_message "$RED" "✗ 未找到机器人配置模板: template/bot_config_template.toml"
        return 1
    fi
    
    cp template/bot_config_template.toml config/bot_config.toml
    print_message "$GREEN" "✓ 机器人配置文件创建成功"
    
    # 第十三步：配置机器人QQ账号
    print_message "$BLUE" "步骤 13: 配置机器人QQ账号"
    local config_file="config/bot_config.toml"
    
    echo ""
    read -p "请输入机器人的QQ号 (9-11位数字): " qq_number
    
    if [[ ! "$qq_number" =~ ^[0-9]{9,11}$ ]]; then
        print_message "$RED" "✗ QQ号格式错误: $qq_number"
        return 1
    fi
    
    # 更新配置文件
    if grep -q "^\s*qq_account\s*=" "$config_file"; then
        sed -i "s/^\s*qq_account\s*=.*/qq_account = $qq_number/" "$config_file"
    else
        sed -i "/^\s*\[bot\]/a qq_account = $qq_number" "$config_file"
    fi
    
    # 确保platform设置为"qq"
    if grep -q "^\s*platform\s*=" "$config_file"; then
        sed -i "s/^\s*platform\s*=.*/platform = \"qq\"/" "$config_file"
    else
        sed -i "/^\s*qq_account\s*=/i platform = \"qq\"" "$config_file"
    fi
    
    print_message "$GREEN" "✓ 机器人QQ号配置成功: $qq_number"
    
    # 第十四步：配置主人QQ账号
    print_message "$BLUE" "步骤 14: 配置主人QQ账号"
    
    echo ""
    read -p "请输入主人QQ号 (9-11位数字): " master_qq
    
    if [[ ! "$master_qq" =~ ^[0-9]{9,11}$ ]]; then
        print_message "$RED" "✗ QQ号格式错误: $master_qq"
        return 1
    fi
    
    # 构建新的master_users配置
    local new_master_config="master_users = [[\"qq\", \"$master_qq\"]]"
    
    if grep -q "^\s*\[permission\]" "$config_file"; then
        if grep -q "^\s*master_users\s*=" "$config_file"; then
            sed -i "s/^\s*master_users\s*=.*/$new_master_config/" "$config_file"
        else
            sed -i "/^\s*\[permission\]/a $new_master_config" "$config_file"
        fi
    else
        echo "" >> "$config_file"
        echo "[permission]" >> "$config_file"
        echo "$new_master_config" >> "$config_file"
    fi
    
    print_message "$GREEN" "✓ 主人QQ号配置成功: $master_qq"
    
    # 第十五步：复制模型配置文件
    print_message "$BLUE" "步骤 15: 配置模型配置文件"
    if [ ! -f "template/model_config_template.toml" ]; then
        print_message "$RED" "✗ 未找到模型配置模板: template/model_config_template.toml"
        return 1
    fi
    
    cp template/model_config_template.toml config/model_config.toml
    
    # 配置硅基流动API
    echo ""
    print_message "$CYAN" "硅基流动(SiliconFlow) API配置"
    read -p "请输入硅基流动API密钥 (输入'skip'跳过): " api_key
    
    if [ "$api_key" != "skip" ] && [ "$api_key" != "SKIP" ]; then
        # 更新API密钥
        if grep -q '^\s*\[\[api_providers\]\]' "config/model_config.toml"; then
            # 查找并更新硅基流动配置
            local line_num=0
            local in_siliconflow=0
            
            while IFS= read -r line; do
                ((line_num++))
                
                if [[ "$line" =~ ^[[:space:]]*\[\[api_providers\]\][[:space:]]*$ ]]; then
                    in_siliconflow=0
                fi
                
                if [[ "$line" =~ ^[[:space:]]*name[[:space:]]*=[[:space:]]*\"siliconflow\" ]]; then
                    in_siliconflow=1
                fi
                
                if [ $in_siliconflow -eq 1 ] && [[ "$line" =~ ^[[:space:]]*api_key[[:space:]]*= ]]; then
                    sed -i "${line_num}s/api_key\s*=.*/api_key = \"${api_key}\"/" "config/model_config.toml"
                    break
                fi
            done < "config/model_config.toml"
        fi
        print_message "$GREEN" "✓ 硅基流动API密钥配置成功"
    else
        print_message "$YELLOW" "⚠ 跳过API密钥配置"
    fi
    
    # 第十六步：验证环境
    print_message "$BLUE" "步骤 16: 验证安装环境"
    
    # 验证项目目录
    local project_files=("pyproject.toml" "requirements.txt" "README.md")
    local found_files=0
    
    for file in "${project_files[@]}"; do
        if [ -e "$file" ]; then
            ((found_files++))
        fi
    done
    
    if [ $found_files -lt 2 ]; then
        print_message "$RED" "✗ 当前目录不是有效的MoFox-Core项目目录"
        return 1
    fi
    print_message "$GREEN" "✓ 项目目录验证通过"
    
    # 验证Python环境
    if ! command -v python3 &> /dev/null; then
        print_message "$RED" "✗ Python3未安装"
        return 1
    fi
    print_message "$GREEN" "✓ Python环境验证通过"
    
    # 第十七步：配置Napcat适配器插件
    print_message "$BLUE" "步骤 17: 配置Napcat适配器插件"
    local plugin_config="config/plugins/napcat_adapter/config.toml"
    
    if [ ! -f "$plugin_config" ]; then
        print_message "$RED" "✗ 未找到Napcat适配器配置文件"
        return 1
    fi
    
    # 启用适配器
    if grep -q "^\s*\[plugin\]" "$plugin_config"; then
        sed -i "/^\s*\[plugin\]/,/^\[/ s/^\s*enabled\s*=.*/enabled = true/" "$plugin_config"
    fi
    print_message "$GREEN" "✓ Napcat适配器已启用"
    
    # 第十八步：配置Napcat服务器端口
    print_message "$BLUE" "步骤 18: 配置Napcat服务器端口"
    
    if ! grep -q "^\s*\[napcat_server\]" "$plugin_config"; then
        print_message "$RED" "✗ 未找到[napcat_server]配置节"
        return 1
    fi
    
    # 获取当前端口
    local current_port=$(grep -E "^\s*port\s*=" "$plugin_config" | head -1 | sed 's/.*=\s*//' | tr -d '[:space:]')
    
    echo ""
    print_message "$YELLOW" "当前Napcat服务器端口: $current_port"
    read -p "是否需要修改端口？(y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "请输入新的端口号 (1024-65535): " new_port
        
        if [[ ! "$new_port" =~ ^[0-9]+$ ]] || [ "$new_port" -lt 1024 ] || [ "$new_port" -gt 65535 ]; then
            print_message "$RED" "✗ 端口号无效"
            return 1
        fi
        
        # 更新端口配置
        sed -i "s/^\s*port\s*=.*/port = $new_port/" "$plugin_config"
        print_message "$GREEN" "✓ 端口已更新为: $new_port"
    else
        print_message "$GREEN" "✓ 保持当前端口: $current_port"
    fi
    
    # 第十九步：首次运行测试
    print_message "$BLUE" "步骤 19: 首次运行测试"
    
    local bot_file="bot.py"
    if [ ! -f "$bot_file" ]; then
        print_message "$YELLOW" "⚠ 未找到bot.py，跳过首次运行测试"
    else
        echo ""
        print_message "$CYAN" "首次运行测试 (5分钟后自动停止，或按 Ctrl+C 手动退出)"
        read -p "是否开始测试？(Y/n): " -n 1 -r
        echo
        
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            print_message "$YELLOW" "正在启动MoFox-Core，请稍候..."
            
            # 创建测试日志
            local test_log="logs/first_run_test_$(date +%Y%m%d_%H%M%S).log"
            mkdir -p logs
            
            # 运行测试（5分钟超时）
            timeout 300 uv run python "$bot_file" 2>&1 | tee "$test_log" &
            local test_pid=$!
            
            # 等待测试完成
            wait $test_pid 2>/dev/null
            
            print_message "$GREEN" "✓ 首次运行测试完成"
            print_message "$BLUE" "测试日志: $test_log"
        fi
    fi
    
    # 安装完成
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo ""
    print_message "$CYAN" "╔══════════════════════════════════════════════════════════╗"
    print_message "$CYAN" "║                  MoFox-Core 安装完成                     ║"
    print_message "$CYAN" "╠══════════════════════════════════════════════════════════╣"
    print_message "$GREEN" "║  ✓ 总用时: ${duration}秒                               ║"
    print_message "$GREEN" "║  ✓ 项目目录: $(pwd)                                   ║"
    print_message "$GREEN" "║  ✓ 配置文件: config/ 目录                              ║"
    print_message "$GREEN" "║  ✓ 依赖安装: 完成                                      ║"
    print_message "$CYAN" "╠══════════════════════════════════════════════════════════╣"
    print_message "$YELLOW" "║  下一步操作:                                          ║"
    print_message "$YELLOW" "║  1. 启动: uv run python bot.py                        ║"
    print_message "$YELLOW" "║  2. 后台: screen -S mofox uv run python bot.py        ║"
    print_message "$YELLOW" "║  3. 日志: tail -f logs/mofox.log                      ║"
    print_message "$CYAN" "╚══════════════════════════════════════════════════════════╝"
    echo ""
    
    log_message "MoFox-Core安装完成，总用时: ${duration}秒"
    
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

# 显示自定义欢迎语
echo ""
print_message "$CYAN" "╔═══════════════════════════════════════════════════════════════╗"
print_message "$CYAN" "║                                                               ║"
print_message "$GREEN" "║   此脚本由牡丹江市第一高级中学ACG社2023级社长越渊制作。        ║"
print_message "$BLUE" "║                                                               ║"
print_message "$YELLOW" "║   感谢您的使用，此脚本将进行以下软件的一键部署安装：           ║"
print_message "$YELLOW" "║                                                               ║"
print_message "$MAGENTA" "║   • MoFox-Core                                               ║"
print_message "$MAGENTA" "║   • NapcatQQ                                                ║"
print_message "$MAGENTA" "║   • 1panle (可选)                                           ║"
print_message "$MAGENTA" "║   • coplar (可选)                                           ║"
print_message "$BLUE" "║                                                               ║"
print_message "$YELLOW" "║   并进行开机自启配置                                         ║"
print_message "$CYAN" "║                                                               ║"
print_message "$CYAN" "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# 显示兼容性说明
print_message "$BLUE" "╔══════════════════════════════════════════════════════════╗"
print_message "$BLUE" "║                                                          ║"
print_message "$YELLOW" "║  兼容性说明：                                          ║"
print_message "$GREEN" "║  此脚本理论适用于所有主流Linux发行版                     ║"
print_message "$GREEN" "║  脚本优化和构建基于 Debian 11 Armbian                   ║"
print_message "$BLUE" "║                                                          ║"
print_message "$YELLOW" "║  注意：在其他发行版上运行时可能需要手动调整依赖包       ║"
print_message "$BLUE" "║                                                          ║"
print_message "$BLUE" "╚══════════════════════════════════════════════════════════╝"
echo ""

# 等待用户确认
read -p "是否开始安装？(Y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ ! -z "$REPLY" ]]; then
    print_message "$YELLOW" "安装已取消。"
    exit 0
fi

# 系统检查
print_header "系统检查"
check_root
check_os
check_architecture
check_network

# 系统更新和依赖安装
update_system
install_dependencies

# 选择安装的软件
select_software

print_message "$GREEN" "✓ 系统检查和准备工作完成"
log_message "系统检查完成，准备开始软件安装"

# ============================================
# 开始软件安装
# ============================================
print_header "开始软件安装"

# 安装NapcatQQ
if [ "$INSTALL_NAPCATQQ" = true ]; then
    if ! install_napcatqq; then
        print_message "$RED" "✗ NapcatQQ安装失败"
        log_message "NapcatQQ安装失败"
        # 询问是否继续
        read -p "NapcatQQ安装失败，是否继续安装其他软件？(Y/n): " -n 1 -r
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
        read -p "coplar安装失败，是否继续安装其他软件？(Y/n): " -n 1 -r
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
        read -p "1panle安装失败，是否继续安装其他软件？(Y/n): " -n 1 -r
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
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

print_header "安装完成"
echo "所有选定的软件安装已完成！"
echo ""
echo "安装总结:"
echo "  - 总用时: $DURATION 秒"
echo "  - 日志文件: $INSTALL_LOG"
echo ""
echo "请检查上方是否有错误信息。"
echo "建议重启系统以确保所有服务正常运行。"
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