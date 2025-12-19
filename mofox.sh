#!/bin/bash

# ============================================
# Armbian软件自动安装脚本（优化版）
# 适用于基于Debian 11的Armbian系统
# 作者：牡丹江市第一高级中学ACG社2023级社长越渊
# 创建日期：$(date +%Y-%m-%d)
# 版本：2.2.0
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
PROGRESS_BAR_WIDTH=50

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
SCRIPT_VERSION="2.1.0"
INSTALL_LOG="/var/log/armbian_install_$(date +%Y%m%d_%H%M%S).log"
TEMP_DIR="/tmp/armbian_install"

# 软件安装选项
INSTALL_MOFOX=true
INSTALL_NAPCATQQ=true
INSTALL_1PANLE=false
INSTALL_COPLAR=false

# 进度跟踪
TOTAL_STEPS=0
CURRENT_STEP=0
CURRENT_SECTION=""
SECTION_STEPS=0
SECTION_CURRENT=0

# ============================================
# 函数定义
# ============================================

# 初始化进度系统
init_progress() {
    TOTAL_STEPS=$1
    CURRENT_STEP=0
    echo ""
}

# 显示主进度条
show_main_progress() {
    local step=$1
    local total=$2
    local description=$3
    local percentage=$((step * 100 / total))
    local filled=$((percentage * PROGRESS_BAR_WIDTH / 100))
    local empty=$((PROGRESS_BAR_WIDTH - filled))
    
    printf "\r${BLUE}["
    printf "%${filled}s" "" | tr ' ' '='
    printf "%${empty}s" "" | tr ' ' ' '
    printf "] ${percentage}%% - ${description}${NC}"
    
    if [ $percentage -eq 100 ]; then
        echo ""
    fi
}

# 显示小节进度
show_section_progress() {
    local step=$1
    local total=$2
    local description=$3
    
    if [ $step -eq $total ]; then
        printf "\r${GREEN}  ✓ ${description} 完成${NC}\n"
    else
        printf "\r${BLUE}  ↳ ${description}${NC}"
    fi
}

# 开始新小节
start_section() {
    CURRENT_SECTION="$1"
    SECTION_STEPS="$2"
    SECTION_CURRENT=0
    echo ""
    print_message "$CYAN" "┌──────────────────────────────────────┐"
    print_message "$CYAN" "│ $CURRENT_SECTION"
    print_message "$CYAN" "└──────────────────────────────────────┘"
}

# 更新小节进度
update_section_progress() {
    SECTION_CURRENT=$((SECTION_CURRENT + 1))
    show_section_progress $SECTION_CURRENT $SECTION_STEPS "$1"
}

# 完成小节
end_section() {
    echo ""
    if [ "$1" = "success" ]; then
        print_message "$GREEN" "✓ $CURRENT_SECTION 完成"
    else
        print_message "$RED" "✗ $CURRENT_SECTION 失败"
    fi
    echo ""
}

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
    echo -n "检查root权限... "
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}✗${NC}"
        print_message "$RED" "错误：此脚本必须以root权限运行！"
        print_message "$YELLOW" "请使用 'sudo bash $0' 或 'su -c \"bash $0\"'"
        exit 1
    fi
    echo -e "${GREEN}✓${NC}"
}

#系统性能检查
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
    start_section "系统更新" 3
    
    update_section_progress "更新软件包列表"
    retry_command $MAX_RETRIES $RETRY_DELAY "apt-get update" "更新软件包列表" || {
        end_section "error"
        return 1
    }
    
    update_section_progress "升级软件包"
    silent_install "apt-get upgrade -y" "升级软件包" || {
        end_section "error"
        return 1
    }
    
    update_section_progress "清理系统"
    silent_install "apt-get autoremove -y && apt-get clean" "清理系统" || {
        end_section "error"
        return 1
    }
    
    end_section "success"
    return 0
}

# 安装依赖包
install_dependencies() {
    start_section "安装依赖包" 1
    
    update_section_progress "安装基础依赖"
    silent_install "apt-get install -y curl wget git sudo build-essential software-properties-common apt-transport-https ca-certificates gnupg lsb-release net-tools htop vim nano" "安装基础依赖" || {
        end_section "error"
        return 1
    }
    
    end_section "success"
    return 0
}

# 选择安装的软件
select_software() {
    print_header "选择安装的软件"
    
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
    
    # 计算总步骤数
    TOTAL_STEPS=4  # 系统检查、更新、依赖、MoFox-Core
    if [ "$INSTALL_NAPCATQQ" = true ]; then TOTAL_STEPS=$((TOTAL_STEPS + 1)); fi
    if [ "$INSTALL_COPLAR" = true ]; then TOTAL_STEPS=$((TOTAL_STEPS + 1)); fi
    if [ "$INSTALL_1PANLE" = true ]; then TOTAL_STEPS=$((TOTAL_STEPS + 1)); fi
    
    init_progress $TOTAL_STEPS
}

# 记录日志
log_message() {
    local message=$1
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" | tee -a "$INSTALL_LOG"
}

# ============================================
# 软件安装函数（优化版）
# ============================================

# 安装napcatqq
install_napcatqq() {
    start_section "安装 NapcatQQ" 4
    
    update_section_progress "创建临时目录"
    mkdir -p "$TEMP_DIR/napcatqq"
    cd "$TEMP_DIR/napcatqq" || return 1
    
    update_section_progress "下载安装脚本"
    retry_command $MAX_RETRIES $RETRY_DELAY "curl -o napcat.sh https://nclatest.znin.net/NapNeko/NapCat-Installer/main/script/install.sh" "下载NapcatQQ安装脚本" || {
        end_section "error"
        return 1
    }
    
    update_section_progress "设置执行权限"
    chmod +x napcat.sh
    
    update_section_progress "执行安装"
    silent_install "bash napcat.sh --docker n --cli n" "安装NapcatQQ" || {
        end_section "error"
        return 1
    }
    
    end_section "success"
    
    # 显示安装后信息
    echo ""
    print_message "$CYAN" "╔══════════════════════════════════════════════════════════╗"
    print_message "$CYAN" "║                    NapcatQQ 安装成功                    ║"
    print_message "$CYAN" "╚══════════════════════════════════════════════════════════╝"
    echo ""
    
    return 0
}

# 安装coplar
install_coplar() {
    start_section "安装 Cpolar" 2
    
    update_section_progress "下载安装脚本"
    retry_command $MAX_RETRIES $RETRY_DELAY "curl -L https://www.cpolar.com/static/downloads/install-release-cpolar.sh -o /tmp/install-cpolar.sh" "下载Cpolar安装脚本" || {
        end_section "error"
        return 1
    }
    
    update_section_progress "执行安装"
    silent_install "bash /tmp/install-cpolar.sh" "安装Cpolar" || {
        end_section "error"
        return 1
    }
    
    end_section "success"
    return 0
}

# 安装1panle
install_1panle() {
    start_section "安装 1Panel" 2
    
    # 检查现有服务
    if systemctl is-active --quiet 1panel; then
        print_message "$YELLOW" "⚠ 检测到1Panel服务已在运行"
        end_section "skipped"
        return 0
    fi
    
    update_section_progress "下载安装脚本"
    retry_command $MAX_RETRIES $RETRY_DELAY "curl -sSL https://resource.fit2cloud.com/1panel/package/v2/quick_start.sh -o /tmp/1panel-install.sh" "下载1Panel安装脚本" || {
        end_section "error"
        return 1
    }
    
    # 使脚本可执行
    chmod +x /tmp/1panel-install.sh
    
    update_section_progress "准备安装"
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
        end_section "success"
        return 0
    else
        stty "$old_stty"  # 恢复终端设置
        echo ""
        end_section "error"
        return 1
    fi
}

# 安装mofox-core
install_mofox() {
    start_section "安装 MoFox-Core" 21
    
    local start_time=$(date +%s)
    
    # 步骤1：安装系统依赖
    update_section_progress "安装系统依赖包"
    silent_install "apt update && apt install -y sudo git curl python3 python3-pip python3-venv build-essential screen" "安装系统依赖包" || return 1
    
    # 步骤2：安装uv
    update_section_progress "安装UV包管理器"
    silent_install "pip3 install uv --break-system-packages -i https://repo.huaweicloud.com/repository/pypi/simple" "安装UV包管理器" || return 1
    
    # 步骤3：配置环境变量
    update_section_progress "配置环境变量"
    if ! grep -q "\.local/bin" ~/.bashrc; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    fi
    export PATH="$HOME/.local/bin:$PATH"
    
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
    
    # 步骤5：创建工作目录
    update_section_progress "创建工作目录"
    cd ~ || return 1
    mkdir -p MoFox_Bot_Deployment
    cd MoFox_Bot_Deployment || return 1
    
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
  
    # 步骤7：进入项目目录
    update_section_progress "进入项目目录"
    cd MoFox-Core || return 1
    
    # 步骤8：创建虚拟环境（关键步骤）
    update_section_progress "创建虚拟环境"
    echo -n "  ↳ 创建Python虚拟环境... "
    if uv venv --python python3 >> "$INSTALL_LOG" 2>&1; then
        echo -e "${GREEN}✓${NC}"
        echo -e "\r${GREEN}  ✓ 虚拟环境创建成功: .venv/${NC}"
    else
        echo -e "${RED}✗${NC}"
        print_message "$RED" "虚拟环境创建失败"
        return 1
    fi
    
    # 步骤9：在虚拟环境中安装Python依赖（关键修正！）
    update_section_progress "安装Python依赖"
    echo -n "  ↳ 在虚拟环境中安装Python依赖... "
    
    # 方法1：使用 uv run 在虚拟环境中运行 pip
    if uv run --virtualenv .venv pip install -r requirements.txt -i https://mirrors.aliyun.com/pypi/simple >> "$INSTALL_LOG" 2>&1; then
        echo -e "${GREEN}✓${NC}"
        echo -e "\r${GREEN}  ✓ 依赖安装成功 (使用虚拟环境)${NC}"
    else
        echo -e "${RED}✗${NC}"
        
        # 方法2：使用 uv 直接安装到虚拟环境
        echo -n "  ↳ 尝试使用 uv 直接安装到虚拟环境... "
        if uv pip install --python .venv/bin/python -r requirements.txt -i https://mirrors.aliyun.com/pypi/simple >> "$INSTALL_LOG" 2>&1; then
            echo -e "${GREEN}✓${NC}"
            echo -e "\r${GREEN}  ✓ 依赖安装成功 (使用--python参数)${NC}"
        else
            echo -e "${RED}✗${NC}"
            
            # 方法3：直接使用虚拟环境中的pip
            echo -n "  ↳ 尝试使用虚拟环境中的pip... "
            if .venv/bin/pip install -r requirements.txt -i https://mirrors.aliyun.com/pypi/simple >> "$INSTALL_LOG" 2>&1; then
                echo -e "${GREEN}✓${NC}"
                echo -e "\r${GREEN}  ✓ 依赖安装成功 (使用.venv/bin/pip)${NC}"
            else
                echo -e "${RED}✗${NC}"
                print_message "$RED" "依赖安装完全失败"
                return 1
            fi
        fi
    fi
    
    # 步骤10：配置环境文件（使用虚拟环境中的Python）
    update_section_progress "配置环境文件"
    cp template/template.env .env 2>> "$INSTALL_LOG"
    if [ $? -eq 0 ]; then
        echo -e "\r${GREEN}  ✓ 环境文件创建成功${NC}"
    else
        echo -e "\r${RED}  ✗ 环境文件创建失败${NC}"
        print_message "$YELLOW" "继续安装，但部分配置可能需要手动完成"
    fi
    
    # 步骤11：用户协议确认
    update_section_progress "确认用户协议"
    sed -i 's/^EULA_CONFIRMED=.*/EULA_CONFIRMED=true/' .env
    echo -e "\r${GREEN}  ✓ 用户协议已确认${NC}"
    
    # 步骤12：创建config目录
    update_section_progress "创建配置目录"
    mkdir -p config
    echo -e "\r${GREEN}  ✓ config目录创建成功${NC}"
    
    # 步骤13：配置机器人文件
    update_section_progress "配置机器人文件"
    if [ -f "template/bot_config_template.toml" ]; then
        cp template/bot_config_template.toml config/bot_config.toml 2>> "$INSTALL_LOG"
        echo -e "\r${GREEN}  ✓ 机器人配置文件创建成功${NC}"
    else
        echo -e "\r${YELLOW}  ⚠ 未找到机器人配置模板${NC}"
    fi
    
    # 步骤14：配置QQ账号
    update_section_progress "配置机器人QQ"
    echo ""
    read -p "请输入机器人的QQ号 (9-11位数字): " qq_number
    
    if [[ "$qq_number" =~ ^[0-9]{9,11}$ ]]; then
        local config_file="config/bot_config.toml"
        if [ -f "$config_file" ]; then
            sed -i "s/^\s*qq_account\s*=.*/qq_account = $qq_number/" "$config_file" 2>> "$INSTALL_LOG"
            sed -i "s/^\s*platform\s*=.*/platform = \"qq\"/" "$config_file" 2>> "$INSTALL_LOG"
            echo -e "\r${GREEN}  ✓ 机器人QQ号配置成功: $qq_number${NC}"
        else
            echo -e "\r${YELLOW}  ⚠ 配置文件不存在，跳过QQ配置${NC}"
        fi
    else
        echo -e "\r${YELLOW}  ⚠ QQ号格式错误，跳过配置${NC}"
    fi
    
    # 步骤15：配置主人QQ
    update_section_progress "配置主人QQ"
    echo ""
    read -p "请输入主人QQ号 (9-11位数字): " master_qq
    
    if [[ "$master_qq" =~ ^[0-9]{9,11}$ ]]; then
        local new_master_config="master_users = [[\"qq\", \"$master_qq\"]]"
        if grep -q "^\s*\[permission\]" "$config_file"; then
            sed -i "/^\s*\[permission\]/a $new_master_config" "$config_file" 2>> "$INSTALL_LOG"
        else
            echo -e "\n[permission]\n$new_master_config" >> "$config_file"
        fi
        echo -e "\r${GREEN}  ✓ 主人QQ号配置成功: $master_qq${NC}"
    else
        echo -e "\r${YELLOW}  ⚠ 主人QQ号格式错误，跳过配置${NC}"
    fi
    
    # 步骤16：配置模型文件
    update_section_progress "配置模型文件"
    if [ -f "template/model_config_template.toml" ]; then
        cp template/model_config_template.toml config/model_config.toml 2>> "$INSTALL_LOG"
        echo -e "\r${GREEN}  ✓ 模型配置文件创建成功${NC}"
    else
        echo -e "\r${YELLOW}  ⚠ 未找到模型配置模板${NC}"
    fi
    
    # 步骤17：配置API密钥
    update_section_progress "配置API密钥"
    echo ""
    read -p "请输入硅基流动API密钥 (输入'skip'跳过): " api_key
    
    if [ "$api_key" != "skip" ] && [ "$api_key" != "SKIP" ] && [ -n "$api_key" ]; then
        if [ -f "config/model_config.toml" ]; then
            # 简化API密钥配置
            sed -i '0,/api_key\s*=/s/api_key\s*=.*/api_key = "'"$api_key"'"/' config/model_config.toml 2>> "$INSTALL_LOG"
            echo -e "\r${GREEN}  ✓ API密钥配置成功${NC}"
        else
            echo -e "\r${YELLOW}  ⚠ 模型配置文件不存在，跳过API配置${NC}"
        fi
    else
        echo -e "\r${YELLOW}  ⚠ 跳过API密钥配置${NC}"
    fi
    
    # 步骤18：验证环境
    update_section_progress "验证安装环境"
    if [ -f ".venv/bin/python" ] && [ -f "pyproject.toml" ]; then
        # 使用虚拟环境中的Python验证版本
        local venv_python_version=$(.venv/bin/python --version 2>&1 | cut -d' ' -f2)
        echo -e "\r${GREEN}  ✓ 虚拟环境Python版本: $venv_python_version${NC}"
        echo -e "\r${GREEN}  ✓ 项目目录验证通过${NC}"
    else
        echo -e "\r${YELLOW}  ⚠ 环境验证警告${NC}"
    fi
    
    # 步骤19：配置Napcat插件
    update_section_progress "配置Napcat插件"
    mkdir -p config/plugins/napcat_adapter
    if [ -f "template/plugins/napcat_adapter/config.toml" ]; then
        cp template/plugins/napcat_adapter/config.toml config/plugins/napcat_adapter/
        sed -i 's/enabled = false/enabled = true/' config/plugins/napcat_adapter/config.toml 2>> "$INSTALL_LOG"
        echo -e "\r${GREEN}  ✓ Napcat插件配置成功${NC}"
    elif [ -f "plugins/napcat_adapter/template_config.toml" ]; then
        cp plugins/napcat_adapter/template_config.toml config/plugins/napcat_adapter/config.toml
        echo -e "\r${GREEN}  ✓ Napcat插件配置成功${NC}"
    else
        echo -e "\r${YELLOW}  ⚠ 未找到Napcat插件模板，跳过配置${NC}"
    fi
    
    # 步骤20：配置端口
    update_section_progress "配置服务端口"
    echo ""
    read -p "请输入Napcat服务器端口 (默认: 8080): " port
    port=${port:-8080}
    
    if [[ "$port" =~ ^[0-9]+$ ]] && [ "$port" -ge 1024 ] && [ "$port" -le 65535 ]; then
        local plugin_config="config/plugins/napcat_adapter/config.toml"
        if [ -f "$plugin_config" ]; then
            sed -i "s/port = .*/port = $port/" "$plugin_config" 2>> "$INSTALL_LOG"
            echo -e "\r${GREEN}  ✓ 端口配置成功: $port${NC}"
        else
            echo -e "\r${YELLOW}  ⚠ 插件配置文件不存在，端口配置失败${NC}"
        fi
    else
        echo -e "\r${YELLOW}  ⚠ 端口号无效，使用默认端口: 8080${NC}"
    fi
    
    # 步骤21：测试虚拟环境（新增）
    update_section_progress "测试虚拟环境"
    echo -n "  ↳ 验证虚拟环境是否可以运行Python... "
    if .venv/bin/python -c "import sys; print('Python', sys.version)" >> "$INSTALL_LOG" 2>&1; then
        echo -e "${GREEN}✓${NC}"
        echo -e "\r${GREEN}  ✓ 虚拟环境测试通过${NC}"
    else
        echo -e "${RED}✗${NC}"
        echo -e "\r${YELLOW}  ⚠ 虚拟环境测试失败${NC}"
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    end_section "success"
    
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

# 显示优化说明
echo ""
print_message "$CYAN" "╔══════════════════════════════════════════════════════════╗"
print_message "$CYAN" "║                     优化功能说明                         ║"
print_message "$CYAN" "╠══════════════════════════════════════════════════════════╣"
print_message "$GREEN" "║  ✓ 自动重试机制 (最大重试: $MAX_RETRIES 次)              ║"
print_message "$GREEN" "║  ✓ 进度条显示 (总进度 + 小节进度)                        ║"
print_message "$GREEN" "║  ✓ 静默安装 (依赖安装输出已隐藏)                         ║"
print_message "$GREEN" "║  ✓ 详细日志记录: $INSTALL_LOG                     ║"
print_message "$GREEN" "║  ✓ 虚拟环境支持 (自动创建和配置)                         ║"
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
# 系统检查和准备
# ============================================
print_header "系统检查"

CURRENT_STEP=1
show_main_progress $CURRENT_STEP $TOTAL_STEPS "系统检查"

check_root
check_os
check_architecture
check_network

# 选择安装软件
select_software

# ============================================
# 系统更新
# ============================================
CURRENT_STEP=$((CURRENT_STEP + 1))
show_main_progress $CURRENT_STEP $TOTAL_STEPS "系统更新"
update_system || {
    print_message "$RED" "系统更新失败，安装终止"
    exit 1
}

# ============================================
# 安装依赖
# ============================================
CURRENT_STEP=$((CURRENT_STEP + 1))
show_main_progress $CURRENT_STEP $TOTAL_STEPS "安装依赖包"
install_dependencies || {
    print_message "$RED" "依赖安装失败，安装终止"
    exit 1
}

# ============================================
# 软件安装
# ============================================
print_header "软件安装"

# 安装NapcatQQ
if [ "$INSTALL_NAPCATQQ" = true ]; then
    CURRENT_STEP=$((CURRENT_STEP + 1))
    show_main_progress $CURRENT_STEP $TOTAL_STEPS "安装 NapcatQQ"
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
    CURRENT_STEP=$((CURRENT_STEP + 1))
    show_main_progress $CURRENT_STEP $TOTAL_STEPS "安装 Cpolar"
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
    CURRENT_STEP=$((CURRENT_STEP + 1))
    show_main_progress $CURRENT_STEP $TOTAL_STEPS "安装 1Panel"
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
    CURRENT_STEP=$((CURRENT_STEP + 1))
    show_main_progress $CURRENT_STEP $TOTAL_STEPS "安装 MoFox-Core"
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
show_main_progress $TOTAL_STEPS $TOTAL_STEPS "安装完成"

echo ""
print_message "$GREEN" "╔══════════════════════════════════════════════════════════╗"
print_message "$GREEN" "║                     安装完成总结                         ║"
print_message "$GREEN" "╠══════════════════════════════════════════════════════════╣"
print_message "$CYAN" "║  总用时: $DURATION 秒                                    ║"
print_message "$CYAN" "║  日志文件: $INSTALL_LOG                           ║"
print_message "$CYAN" "║                                                          ║"
print_message "$YELLOW" "║  安装的软件:                                          ║"
[ "$INSTALL_MOFOX" = true ] && print_message "$YELLOW" "║    • MoFox-Core                                      ║"
[ "$INSTALL_NAPCATQQ" = true ] && print_message "$YELLOW" "║    • NapcatQQ                                       ║"
[ "$INSTALL_1PANLE" = true ] && print_message "$YELLOW" "║    • 1Panel                                         ║"
[ "$INSTALL_COPLAR" = true ] && print_message "$YELLOW" "║    • Cpolar                                         ║"
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