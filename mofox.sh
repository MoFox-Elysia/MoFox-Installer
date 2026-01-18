#!/bin/bash

# ============================================
# Armbian软件自动安装脚本
# 适用于基于Debian 11的Armbian系统
# 作者：牡丹江市第一高级中学ACG社2023级社长越渊
# 创建日期：26.1.1
# 版本：2.7.6
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
SCRIPT_VERSION="2.7.6"
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

# Napcat配置相关变量
NAPCAT_CONFIG_DIR="/root/Napcat/opt/QQ/resources/app/app_launcher/napcat/config"
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
    echo "作者：牡丹江市第一高级中学ACG社2023级社长越渊"
}

# ============================================
# 新增：Napcat配置函数组
# ============================================

# 修改webui.json配置文件中的token
configure_napcat_token() {
    local config_file="$NAPCAT_CONFIG_DIR/webui.json"
    
    # 检查配置文件是否存在
    if [ ! -f "$config_file" ]; then
        echo -e "${YELLOW}⚠ 配置文件不存在: $config_file${NC}"
        return 1
    fi
    
    echo -e "${CYAN}正在检查Napcat配置文件...${NC}"
    
    # 查找并提取当前token
    local current_token=$(grep -o '"token": *"[^"]*"' "$config_file" | head -1 | sed 's/"token": *"\([^"]*\)"/\1/')
    
    if [ -z "$current_token" ]; then
        echo -e "${YELLOW}⚠ 未找到token字段${NC}"
        echo "当前文件内容:"
        cat "$config_file"
        echo ""
        
        read -p "是否要手动添加token字段？(y/N): " add_token
        if [[ "$add_token" =~ ^[Yy]$ ]]; then
            read -p "请输入新的token值: " new_token
            # 这里需要根据实际JSON结构添加token字段
            echo -e "${YELLOW}注意: 请根据JSON结构手动添加token字段${NC}"
        fi
        return 0
    fi
    
    echo -e "${GREEN}当前token: $current_token${NC}"
    echo ""
    
    # 询问用户是否修改token
    read -p "是否要修改token？(y/N，直接回车跳过): " modify_choice
    
    if [[ "$modify_choice" =~ ^[Yy]$ ]]; then
        read -p "请输入新的token值: " new_token
        
        if [ -n "$new_token" ]; then
            # 备份原文件
            local backup_file="${config_file}.backup.$(date +%Y%m%d_%H%M%S)"
            cp "$config_file" "$backup_file"
            echo -e "${GREEN}已创建备份: $backup_file${NC}"
            
            # 使用sed替换token值，确保保持JSON格式
            sed -i "s/\"token\": *\"$current_token\"/\"token\": \"$new_token\"/g" "$config_file"
            
            # 验证替换是否成功
            local updated_token=$(grep -o '"token": *"[^"]*"' "$config_file" | head -1 | sed 's/"token": *"\([^"]*\)"/\1/')
            
            if [ "$updated_token" = "$new_token" ]; then
                echo -e "${GREEN}✓ token已成功修改为: $updated_token${NC}"
            else
                echo -e "${RED}✗ token修改失败，正在恢复备份...${NC}"
                cp "$backup_file" "$config_file"
                echo -e "${YELLOW}已恢复备份文件${NC}"
                return 1
            fi
        else
            echo -e "${YELLOW}未输入新的token值，保持原样${NC}"
        fi
    else
        echo -e "${GREEN}保持当前token: $current_token${NC}"
    fi
    
    return 0
}

# 在screen中运行napcatqq
run_napcat_in_screen() {
    local screen_name="napcat_qq"
    local napcat_cmd="xvfb-run -a /root/Napcat/opt/QQ/qq --no-sandbox"
    
    echo ""
    echo -e "${CYAN}正在启动Napcat QQ...${NC}"
    echo -e "${YELLOW}命令行: $napcat_cmd${NC}"
    
    # 检查screen是否已安装
    if ! command -v screen &> /dev/null; then
        echo -e "${YELLOW}screen未安装，尝试安装...${NC}"
        if command -v apt-get &> /dev/null; then
            apt-get update && apt-get install -y screen
        elif command -v yum &> /dev/null; then
            yum install -y screen
        elif command -v apt &> /dev/null; then
            apt update && apt install -y screen
        else
            echo -e "${RED}无法确定包管理器，请手动安装screen${NC}"
            return 1
        fi
    fi
    
    # 检查是否已经存在同名的screen会话
    if screen -list | grep -q "$screen_name"; then
        echo -e "${YELLOW}检测到已存在的screen会话: $screen_name，正在停止...${NC}"
        screen -S "$screen_name" -X quit
        sleep 2
    fi
    
    # 创建并运行screen会话
    echo -e "${CYAN}正在创建screen会话: $screen_name${NC}"
    screen -dmS "$screen_name" bash -c "$napcat_cmd; echo 'Napcat QQ进程已退出，按回车键关闭此窗口...'; read"
    
    # 等待一下确保screen会话启动
    sleep 3
    
    # 检查是否成功启动
    if screen -list | grep -q "$screen_name"; then
        echo -e "${GREEN}✓ screen会话 '$screen_name' 已成功启动${NC}"
        echo -e "${YELLOW}提示: 使用 'screen -r $screen_name' 查看运行状态${NC}"
    else
        echo -e "${YELLOW}✗ screen会话启动失败，尝试直接运行...${NC}"
        eval "$napcat_cmd &"
        echo -e "${GREEN}Napcat QQ已在后台运行${NC}"
    fi
    
    return 0
}

# 显示最新日志函数
show_napcat_latest_log() {
    local log_dir="/root/Napcat/opt/QQ/resources/app/app_launcher/napcat/logs"
    
    # 检查日志目录是否存在
    if [ ! -d "$log_dir" ]; then
        echo -e "${RED}错误: 日志目录不存在: $log_dir${NC}"
        return 1
    fi
    
    # 查找最新的log文件
    local latest_log=$(find "$log_dir" -name "*.log" -type f | sort -r | head -1)
    
    if [ -z "$latest_log" ]; then
        echo -e "${YELLOW}警告: 在 $log_dir 中未找到任何.log文件${NC}"
        echo -e "${YELLOW}尝试查找其他日志文件...${NC}"
        latest_log=$(find "$log_dir" -type f | grep -i log | sort -r | head -1)
        
        if [ -z "$latest_log" ]; then
            echo -e "${YELLOW}未找到任何日志文件${NC}"
            return 1
        fi
    fi
    
    echo -e "${GREEN}找到最新日志文件: $latest_log${NC}"
    echo -e "${CYAN}显示最后23行日志:${NC}"
    echo -e "${BLUE}========================================${NC}"
    tail -23 "$latest_log"
    echo -e "${BLUE}========================================${NC}"
    
    return 0
}

# 检查登录状态并询问用户
check_napcat_login_status() {
    local max_attempts=10
    local attempt=1
    
    echo ""
    echo -e "${CYAN}等待Napcat QQ启动...${NC}"
    sleep 5  # 等待程序启动
    
    while [ $attempt -le $max_attempts ]; do
        echo ""
        echo -e "${YELLOW}检查日志 (尝试 $attempt/$max_attempts):${NC}"
        
        # 显示最新日志
        if ! show_napcat_latest_log; then
            echo -e "${YELLOW}无法读取日志，等待5秒后重试...${NC}"
            sleep 5
            attempt=$((attempt + 1))
            continue
        fi
        
        # 询问用户是否登录完成
        echo ""
        read -p "是否已登录完成？(Y/n，或输入 'r' 重新显示日志): " login_choice
        
        case $login_choice in
            [Yy]|"")
                echo -e "${GREEN}✓ 登录完成确认${NC}"
                return 0
                ;;
            [Nn])
                echo -e "${YELLOW}等待10秒后再次检查...${NC}"
                sleep 10
                attempt=$((attempt + 1))
                ;;
            [Rr])
                echo -e "${CYAN}重新显示日志...${NC}"
                # 继续循环，不增加尝试次数
                continue
                ;;
            *)
                echo -e "${YELLOW}请输入 Y/n/r，输入无效，等待10秒后继续...${NC}"
                sleep 10
                attempt=$((attempt + 1))
                ;;
        esac
    done
    
    echo -e "${YELLOW}已达到最大检查次数 ($max_attempts 次)，跳过登录确认${NC}"
    return 1
}

# 提取QQ号并更新autoLoginAccount
update_napcat_auto_login_account() {
    local webui_file="$NAPCAT_CONFIG_DIR/webui.json"
    
    echo ""
    echo -e "${CYAN}正在查找Napcat生成的QQ配置文件...${NC}"
    
    # 查找napcat_*.json文件
    local napcat_files=$(find "$NAPCAT_CONFIG_DIR" -maxdepth 1 -name "napcat_*.json" -type f)
    
    if [ -z "$napcat_files" ]; then
        echo -e "${YELLOW}未找到napcat_*.json文件${NC}"
        echo -e "${YELLOW}可能原因：${NC}"
        echo -e "${YELLOW}  1. Napcat QQ尚未登录成功${NC}"
        echo -e "${YELLOW}  2. 配置文件在其他位置${NC}"
        echo -e "${YELLOW}  3. 文件名格式不符${NC}"
        return 1
    fi
    
    # 取最新的一个文件（按修改时间排序）
    local latest_file=$(ls -t $NAPCAT_CONFIG_DIR/napcat_*.json 2>/dev/null | head -1)
    
    if [ -z "$latest_file" ] || [ ! -f "$latest_file" ]; then
        echo -e "${YELLOW}无法找到最新的napcat配置文件${NC}"
        return 1
    fi
    
    echo -e "${GREEN}找到配置文件: $latest_file${NC}"
    
    # 从文件名中提取QQ号
    # 文件名格式：napcat_2254836913.json
    local qq_number=$(basename "$latest_file" | sed -n 's/napcat_\([0-9]*\)\.json/\1/p')
    
    if [ -z "$qq_number" ]; then
        echo -e "${RED}无法从文件名中提取QQ号${NC}"
        echo -e "${YELLOW}文件名: $(basename "$latest_file")${NC}"
        return 1
    fi
    
    echo -e "${GREEN}提取到QQ号: $qq_number${NC}"
    
    # 检查webui.json文件是否存在
    if [ ! -f "$webui_file" ]; then
        echo -e "${RED}错误: webui.json文件不存在: $webui_file${NC}"
        return 1
    fi
    
    # 备份原文件
    local backup_file="${webui_file}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$webui_file" "$backup_file"
    echo -e "${GREEN}已创建备份: $backup_file${NC}"
    
    # 检查autoLoginAccount字段是否存在
    if grep -q '"autoLoginAccount":' "$webui_file"; then
        # 字段存在，获取当前值
        local current_qq=$(grep -o '"autoLoginAccount": *"[^"]*"' "$webui_file" | head -1 | sed 's/"autoLoginAccount": *"\([^"]*\)"/\1/')
        
        if [ -n "$current_qq" ] && [ "$current_qq" != "null" ]; then
            echo -e "${GREEN}当前autoLoginAccount: $current_qq${NC}"
            read -p "是否要更新为 $qq_number ？(Y/n): " update_choice
            
            if [[ "$update_choice" =~ ^[Nn]$ ]]; then
                echo -e "${YELLOW}保持原QQ号: $current_qq${NC}"
                rm -f "$backup_file"
                return 0
            fi
        fi
        
        # 更新autoLoginAccount字段
        sed -i "s/\"autoLoginAccount\": *\"[^\"]*\"/\"autoLoginAccount\": \"$qq_number\"/g" "$webui_file"
        echo -e "${GREEN}✓ 已更新autoLoginAccount为: $qq_number${NC}"
    else
        # 字段不存在，需要添加
        echo -e "${YELLOW}autoLoginAccount字段不存在，正在添加...${NC}"
        
        # 使用jq工具处理JSON（如果可用）
        if command -v jq &> /dev/null; then
            echo -e "${CYAN}使用jq工具添加autoLoginAccount字段...${NC}"
            jq --arg qq "$qq_number" '. + {"autoLoginAccount": $qq}' "$webui_file" > "${webui_file}.tmp" && \
            mv "${webui_file}.tmp" "$webui_file"
        else
            echo -e "${YELLOW}jq工具未安装，使用sed添加字段（可能不准确）${NC}"
            # 尝试在最后一个}前添加字段
            sed -i '$ s/}/,/' "$webui_file"  # 在最后一行}前添加逗号
            sed -i "\$i\"autoLoginAccount\": \"$qq_number\"" "$webui_file"
            sed -i '$ s/$/\n}/' "$webui_file"  # 确保以}结尾
        fi
        
        echo -e "${GREEN}✓ 已添加autoLoginAccount字段: $qq_number${NC}"
    fi
    
    # 验证更新
    local updated_qq=$(grep -o '"autoLoginAccount": *"[^"]*"' "$webui_file" | head -1 | sed 's/"autoLoginAccount": *"\([^"]*\)"/\1/')
    
    if [ "$updated_qq" = "$qq_number" ]; then
        echo -e "${GREEN}✓ 验证成功: autoLoginAccount已设置为 $updated_qq${NC}"
    else
        echo -e "${YELLOW}⚠ 验证失败，恢复备份文件${NC}"
        cp "$backup_file" "$webui_file"
        return 1
    fi
    
    return 0
}

# 修改onebot配置文件
configure_napcat_onebot() {
    echo ""
    echo -e "${CYAN}正在查找onebot配置文件...${NC}"
    
    # 查找以onebot开头的.json文件
    local onebot_files=$(find "$NAPCAT_CONFIG_DIR" -maxdepth 1 -name "onebot*.json" -type f)
    
    if [ -z "$onebot_files" ]; then
        echo -e "${YELLOW}未找到onebot*.json文件${NC}"
        echo -e "${CYAN}正在创建默认onebot配置文件...${NC}"
        
        # 尝试从napcat文件提取QQ号
        local napcat_file=$(ls -t $NAPCAT_CONFIG_DIR/napcat_*.json 2>/dev/null | head -1)
        local qq_number=""
        
        if [ -n "$napcat_file" ] && [ -f "$napcat_file" ]; then
            qq_number=$(basename "$napcat_file" | sed -n 's/napcat_\([0-9]*\)\.json/\1/p')
        fi
        
        if [ -n "$qq_number" ]; then
            local onebot_file="$NAPCAT_CONFIG_DIR/onebot11_${qq_number}.json"
        else
            echo -e "${YELLOW}无法确定QQ号，创建通用onebot配置文件${NC}"
            local onebot_file="$NAPCAT_CONFIG_DIR/onebot11_config.json"
        fi
    else
        # 取第一个找到的onebot文件
        local onebot_file=$(echo "$onebot_files" | head -1)
    fi
    
    echo -e "${GREEN}处理onebot配置文件: $onebot_file${NC}"
    
    # 备份原文件（如果存在）
    if [ -f "$onebot_file" ]; then
        local backup_file="${onebot_file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$onebot_file" "$backup_file"
        echo -e "${GREEN}已创建备份: $backup_file${NC}"
    fi
    
    # 清空文件并写入新内容
    cat > "$onebot_file" << 'EOF'
{
  "network": {
    "httpServers": [],
    "httpSseServers": [],
    "httpClients": [],
    "websocketServers": [],
    "websocketClients": [
      {
        "enable": true,
        "name": "LoveElysia",
        "url": "ws://localhost:8095",
        "reportSelfMessage": false,
        "messagePostFormat": "array",
        "token": "",
        "debug": false,
        "heartInterval": 30000,
        "reconnectInterval": 30000
      }
    ],
    "plugins": []
  },
  "musicSignUrl": "",
  "enableLocalFile2Url": false,
  "parseMultMsg": false
}
EOF
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ onebot配置文件已成功更新${NC}"
        echo -e "${YELLOW}文件路径: $onebot_file${NC}"
        echo ""
        echo -e "${CYAN}配置文件内容预览:${NC}"
        cat "$onebot_file"
    else
        echo -e "${RED}✗ 写入onebot配置文件失败${NC}"
        if [ -f "$backup_file" ]; then
            echo -e "${YELLOW}正在恢复备份文件...${NC}"
            cp "$backup_file" "$onebot_file"
        fi
        return 1
    fi
    
    return 0
}

# 主配置函数：执行所有Napcat配置步骤
configure_napcat_complete() {
    print_header "配置Napcat QQ"
    
    echo -e "${CYAN}开始配置Napcat QQ...${NC}"
    
    # 步骤1: 配置token
    echo -e "${YELLOW}[1/5] 配置Napcat Token...${NC}"
    if ! configure_napcat_token; then
        echo -e "${YELLOW}⚠ Token配置跳过或失败，继续其他配置...${NC}"
    fi
    
    # 步骤2: 在screen中运行Napcat
    echo -e "${YELLOW}[2/5] 启动Napcat QQ...${NC}"
    if ! run_napcat_in_screen; then
        echo -e "${RED}✗ 启动Napcat失败${NC}"
        return 1
    fi
    
    # 步骤3: 检查登录状态
    echo -e "${YELLOW}[3/5] 检查Napcat登录状态...${NC}"
    if ! check_napcat_login_status; then
        echo -e "${YELLOW}⚠ 登录状态未确认，跳过后续配置${NC}"
        return 1
    fi
    
    # 等待Napcat生成配置文件
    echo -e "${CYAN}等待Napcat生成配置文件...${NC}"
    sleep 5
    
    # 步骤4: 更新autoLoginAccount
    echo -e "${YELLOW}[4/5] 更新autoLoginAccount...${NC}"
    if ! update_napcat_auto_login_account; then
        echo -e "${YELLOW}⚠ 更新autoLoginAccount失败，跳过此项${NC}"
    fi
    
    # 步骤5: 配置onebot
    echo -e "${YELLOW}[5/5] 配置onebot...${NC}"
    if ! configure_napcat_onebot; then
        echo -e "${YELLOW}⚠ 配置onebot失败，跳过此项${NC}"
    fi
    
    echo -e "${GREEN}✓ Napcat QQ配置完成${NC}"
    
    # 显示配置摘要
    echo ""
    echo -e "${CYAN}Napcat配置摘要:${NC}"
    echo -e "${YELLOW}  • Token已配置${NC}"
    echo -e "${YELLOW}  • Napcat已在screen中运行${NC}"
    echo -e "${YELLOW}  • 登录状态已确认${NC}"
    
    # 检查autoLoginAccount配置
    local webui_file="$NAPCAT_CONFIG_DIR/webui.json"
    if [ -f "$webui_file" ]; then
        local auto_login=$(grep -o '"autoLoginAccount": *"[^"]*"' "$webui_file" | head -1 | sed 's/"autoLoginAccount": *"\([^"]*\)"/\1/')
        if [ -n "$auto_login" ] && [ "$auto_login" != "null" ]; then
            echo -e "${YELLOW}  • autoLoginAccount: $auto_login${NC}"
        fi
    fi
    
    echo -e "${YELLOW}  • onebot配置文件已生成${NC}"
    echo ""
    echo -e "${GREEN}Napcat QQ已配置完成，可以与MoFox-Core配合使用！${NC}"
    
    return 0
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
        echo -e "${CYAN}1)删除现有 MoFox-Core "
        echo -e "${CYAN}2) 跳过系统检查，直接从软件选择开始"
        echo -e "${CYAN}3) 正常完整安装"
        
        while true; do
            read -p "请选择 [1/2/3]: " choice
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
                        sleep 3
                    else
                        print_message "$YELLOW" "取消删除，继续使用现有目录"
                        return 1
                    fi
                    ;;
               
                2)
                    print_message "$GREEN" "您选择了跳过系统检查"
                    SKIP_SYSTEM_CHECK=true
                    return 3
                    ;;
                3)
                    print_message "$GREEN" "您选择了正常完整安装"
                    return 0
                    ;;
                *)
                    echo -e "${RED}无效选择，请输入1-3${NC}"
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
        "/opt/Napcat"
        "/usr/local/Napcat"
        "$HOME/Napcat"
        "/root/Napcat"
        "/home/$USER/Napcat"

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
        echo -e "${CYAN}1) 跳过安装NapcatQQ"
        echo -e "${CYAN}2) 正常安装 (忽略现有目录，可能覆盖)"
        
        while true; do
            read -p "请选择 [1/2]: " choice
            case $choice in
                1)
                    print_message "$YELLOW" "您选择了跳过安装NapcatQQ"
                    INSTALL_NAPCATQQ=false
                    return 1
                    ;;
                2)
                    print_message "$GREEN" "您选择了正常安装"
                    print_message "$YELLOW" "注意：如果安装失败，可能需要清理现有目录"
                    return 2
                    ;;
                *)
                    echo -e "${RED}无效选择，请输入1-2${NC}"
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
    [ "$INSTALL_NAPCATQQ" = true ] && echo "2. NapcatQQ: 配置已完成，Napcat正在运行中"
    [ "$INSTALL_NAPCATQQ" = true ] && echo "   查看运行状态: screen -r napcat_qq"
    [ "$INSTALL_NAPCATQQ" = true ] && echo "   停止Napcat: screen -S napcat_qq -X quit"
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
        print_message "$YELLOW" "系统将在60秒后重启..."
        sleep 60
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
    

    retry_command $MAX_RETRIES $RETRY_DELAY "apt-get update" "更新软件包列表" || return 1
    

    silent_install "apt-get upgrade -y" "升级软件包" || return 1

    silent_install "apt-get autoremove -y && apt-get clean" "清理系统" || return 1
    
    print_message "$GREEN" "✓ 系统更新完成"
    return 0
}

# 安装依赖包
install_dependencies() {
    print_header "安装依赖包"
    

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

# 安装napcatQQ
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
            
            # 升级完成后进行配置
            configure_napcat_complete
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
                        
                        # 升级完成后进行配置
                        configure_napcat_complete
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
    

    retry_command $MAX_RETRIES $RETRY_DELAY "curl -o napcat.sh https://nclatest.znin.net/NapNeko/NapCat-Installer/main/script/install.sh" "下载NapcatQQ安装脚本" || return 1
    
    echo -n "设置执行权限... "
    chmod +x napcat.sh
    echo -e "${GREEN}✓${NC}"
    

    silent_install "bash napcat.sh --docker n --cli n" "安装NapcatQQ" || return 1
    
    print_message "$GREEN" "✓ NapcatQQ安装完成"
    
    # 安装完成后立即进行配置
    echo ""
    print_message "$CYAN" "开始配置NapcatQQ..."
    configure_napcat_complete
    
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

# 安装mofox-core
install_mofox() {
    print_header "安装 MoFox-Core"
    
    local start_time=$(date +%s)
    
    # 步骤1：安装系统依赖

    silent_install "apt update && apt install -y sudo git curl python3 python3-pip python3-venv build-essential screen" "安装系统依赖包" || return 1
    
    # 步骤2：安装uv

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

# 步骤6：克隆MoFox-Core仓库
echo -n "克隆MoFox-Core仓库... "

# 直接使用GitHub源进行克隆
GITHUB_URL="https://github.com/MoFox-Studio/MoFox-Core.git"

# 克隆仓库
if ! git clone "$GITHUB_URL"; then
    echo -e "${RED}✗ MoFox-Core仓库克隆失败${NC}"
    echo "尝试使用镜像源..."
    # 如果直接克隆失败，尝试使用镜像源
    MIRROR_URL="https://ghproxy.com/https://github.com/MoFox-Studio/MoFox-Core.git"
    if ! git clone "$MIRROR_URL"; then
        echo -e "${RED}✗ 所有克隆尝试均失败${NC}"
        return 1
    fi
fi
echo -e "${GREEN}✓ MoFox-Core仓库克隆成功${NC}"
   #步骤7
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
    
# 步骤9：在虚拟环境中安装Python依赖（带重试机制）
    echo "安装Python依赖..."
    
    # 方法1：使用uv指定Python路径（重试3次）
    # 先安装numba和llvmlite依赖
    if retry_command $MAX_RETRIES $RETRY_DELAY "UV_LINK_MODE=copy uv pip install --python .venv/bin/python \"numba>=0.56\" \"llvmlite>=0.40\"" "方法1: 安装numba和llvmlite"; then
        echo -e "\r${GREEN}  ✓ numba和llvmlite安装成功${NC}"
    else
        echo -e "\r${RED}  ✗ numba和llvmlite安装失败${NC}"
        print_message "$RED" "依赖安装完全失败"
        return 1
    fi

    if retry_command $MAX_RETRIES $RETRY_DELAY "UV_LINK_MODE=copy uv pip install --python .venv/bin/python -r requirements.txt" "方法1: uv安装requirements.txt依赖"; then
        echo -e "\r${GREEN}  ✓ 依赖安装成功 (使用uv指定python路径)${NC}"
    else
        echo -e "\r${RED}  ✗ 方法1失败${NC}"
        
        # 方法2：先激活虚拟环境再使用uv（重试3次）
        # 先安装numba和llvmlite依赖
        if retry_command $MAX_RETRIES $RETRY_DELAY "source .venv/bin/activate && uv pip install \"numba>=0.56\" \"llvmlite>=0.40\"" "方法2: 安装numba和llvmlite"; then
            echo -e "\r${GREEN}  ✓ numba和llvmlite安装成功${NC}"
        else
            echo -e "\r${RED}  ✗ numba和llvmlite安装失败${NC}"
            print_message "$RED" "依赖安装完全失败"
            return 1
        fi

        if retry_command $MAX_RETRIES $RETRY_DELAY "source .venv/bin/activate && uv pip install -r requirements.txt" "方法2: 激活环境后uv安装requirements.txt依赖"; then
            echo -e "\r${GREEN}  ✓ 依赖安装成功 (激活环境后使用uv)${NC}"
        else
            echo -e "\r${RED}  ✗ 方法2失败${NC}"
            print_message "$RED" "依赖安装完全失败"
            return 1
        fi
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
    
    # 步骤14：配置QQ账号和机器人信息
echo ""
echo -e "${CYAN}现在开始配置MoFox-Core的QQ账号和机器人信息${NC}"

# 1. 配置QQ账号（原有功能）
echo -e "${YELLOW}注意：QQ号应为纯数字，5-15位${NC}"
read -p "请输入机器人的QQ号: " qq_number

# 2. 配置机器人昵称
read -p "请输入机器人的昵称（显示名称）: " bot_nickname

# 3. 配置机器人别名（多个）
alias_array=()
echo -e "${YELLOW}现在配置机器人别名（可设置多个，输入空值结束）${NC}"
while true; do
    read -p "请输入一个别名（直接按Enter结束）: " alias_name
    if [[ -z "$alias_name" ]]; then
        break
    fi
    alias_array+=("\"$alias_name\"")
done

# 验证并写入配置
if [[ -n "$qq_number" && "$qq_number" =~ ^[0-9]+$ ]]; then
    local config_file="config/bot_config.toml"
    if [ -f "$config_file" ]; then
        # 确保[bot]节存在
        if ! grep -q "^\[bot\]" "$config_file"; then
            echo "[bot]" >> "$config_file"
        fi
        
        # 配置QQ账号
        if grep -q "qq_account\s*=" "$config_file"; then
            sed -i "s/qq_account\s*=.*/qq_account = $qq_number/" "$config_file" 2>> "$INSTALL_LOG"
        else
            sed -i "/^\[bot\]/a qq_account = $qq_number" "$config_file" 2>> "$INSTALL_LOG"
        fi
        echo -e "${GREEN}✓ 机器人QQ号配置成功: $qq_number${NC}"
        
        # 配置昵称
        if [[ -n "$bot_nickname" ]]; then
            if grep -q "nickname\s*=" "$config_file"; then
                sed -i "s/nickname\s*=.*/nickname = \"$bot_nickname\"/" "$config_file" 2>> "$INSTALL_LOG"
            else
                sed -i "/^\[bot\]/a nickname = \"$bot_nickname\"" "$config_file" 2>> "$INSTALL_LOG"
            fi
            echo -e "${GREEN}✓ 机器人昵称配置成功: $bot_nickname${NC}"
        else
            echo -e "${YELLOW}⚠ 昵称为空，跳过昵称配置${NC}"
        fi
        
        # 配置别名数组
        if [ ${#alias_array[@]} -gt 0 ]; then
            # 构建TOML数组格式
            alias_string="alias_names = ["
            for ((i=0; i<${#alias_array[@]}; i++)); do
                if [ $i -gt 0 ]; then
                    alias_string+=", "
                fi
                alias_string+="${alias_array[$i]}"
            done
            alias_string+="]"
            
            if grep -q "alias_names\s*=" "$config_file"; then
                # 注意：这里使用|作为分隔符，避免路径中的/冲突
                sed -i "s|alias_names\s*=.*|$alias_string|" "$config_file" 2>> "$INSTALL_LOG"
            else
                sed -i "/^\[bot\]/a $alias_string" "$config_file" 2>> "$INSTALL_LOG"
            fi
            echo -e "${GREEN}✓ 机器人别名配置成功${NC}"
        else
            echo -e "${YELLOW}⚠ 未设置别名，跳过别名配置${NC}"
        fi
        
        # 确保platform配置（根据示例）
        if ! grep -q "platform\s*=" "$config_file"; then
            sed -i "/^\[bot\]/a platform = \"qq\"" "$config_file" 2>> "$INSTALL_LOG"
        fi
        
    else
        echo -e "${YELLOW}⚠ 配置文件不存在，跳过所有配置${NC}"
    fi
else
    echo -e "${YELLOW}⚠ QQ号格式错误，跳过所有配置${NC}"
fi

# 步骤14.1：配置机器人人格设定
echo ""
echo -e "${CYAN}现在开始配置MoFox-Core的机器人人格设定${NC}"
echo -e "${YELLOW}注意：这些设定将影响机器人的行为和回复风格${NC}"

# 1. 配置人格核心特质
echo -e "${YELLOW}人格核心特质（建议50字以内，描述人格的核心特质）${NC}"
read -p "请输入人格核心特质（例如：'是一个积极向上的女大学生'）: " personality_core

# 2. 配置人格侧面特质
echo -e "${YELLOW}人格侧面特质（用一句话或几句话描述人格的一些侧面特质）${NC}"
read -p "请输入人格侧面特质（例如：'喜欢帮助他人，热爱学习'）: " personality_side

# 3. 配置身份特征
echo -e "${YELLOW}身份特征（描述外貌、性别、身高、职业、属性等）${NC}"
read -p "请输入身份特征（例如：'年龄为19岁,是女孩子,身高为160cm,有黑色的短发'）: " identity

# 4. 配置背景故事
echo -e "${YELLOW}背景故事（详细的世界观、背景故事、复杂人际关系等，可选）${NC}"
echo -e "${YELLOW}注意：这部分内容将作为机器人的'背景知识'，不会频繁复述${NC}"
read -p "请输入背景故事（直接按Enter跳过）: " background_story

# 5. 配置回复风格
echo -e "${YELLOW}回复风格（描述机器人的表达风格和习惯）${NC}"
read -p "请输入回复风格（例如：'回复可以简短一些。可以参考贴吧，知乎和微博的回复风格'）: " reply_style

# 写入配置
local config_file="config/bot_config.toml"

# 检查文件是否存在，如果不存在则创建
if [ ! -f "$config_file" ]; then
    echo -e "${YELLOW}配置文件不存在，创建新文件...${NC}"
    mkdir -p "$(dirname "$config_file")"
    touch "$config_file"
fi

# 创建临时文件
local temp_file="${config_file}.tmp"

# 复制原文件内容到临时文件，并处理personality节
{
    # 读取原文件，直到遇到[personality]节
    local in_personality_section=false
    local personality_section_written=false
    
    if [ -f "$config_file" ]; then
        while IFS= read -r line || [ -n "$line" ]; do
            # 检测是否进入或离开personality节
            if [[ "$line" == "[personality]" ]]; then
                in_personality_section=true
                personality_section_written=true
                echo "[personality]"
                
                # 写入配置项
                if [[ -n "$personality_core" ]]; then
                    echo "# 建议50字以内，描述人格的核心特质"
                    echo "personality_core = \"$personality_core\""
                fi
                
                if [[ -n "$personality_side" ]]; then
                    echo "# 人格的细节，描述人格的一些侧面"
                    echo "personality_side = \"$personality_side\""
                fi
                
                if [[ -n "$identity" ]]; then
                    echo "# 可以描述外貌，性别，身高，职业，属性等等描述"
                    echo "identity = \"$identity\""
                fi
                
                if [[ -n "$background_story" ]]; then
                    echo "# 此处用于填写详细的世界观、背景故事、复杂人际关系等"
                    echo "background_story = \"$background_story\""
                else
                    echo "# 此处用于填写详细的世界观、背景故事、复杂人际关系等"
                    echo "background_story = \"\""
                fi
                
                if [[ -n "$reply_style" ]]; then
                    echo "# 描述MoFox-Bot说话的表达风格，表达习惯"
                    echo "reply_style = \"$reply_style\""
                fi
                
                continue
            fi
            
            # 如果离开personality节（遇到下一个节）
            if [[ "$in_personality_section" == true && "$line" =~ ^\[.*\]$ ]]; then
                in_personality_section=false
            fi
            
            # 如果不是在personality节中，或者已经离开personality节，则写入原行
            if [[ "$in_personality_section" == false ]]; then
                echo "$line"
            fi
        done < "$config_file"
        
        # 如果没有找到personality节，则在文件末尾添加
        if [[ "$personality_section_written" == false ]]; then
            echo ""
            echo "[personality]"
            
            if [[ -n "$personality_core" ]]; then
                echo "# 建议50字以内，描述人格的核心特质"
                echo "personality_core = \"$personality_core\""
            fi
            
            if [[ -n "$personality_side" ]]; then
                echo "# 人格的细节，描述人格的一些侧面"
                echo "personality_side = \"$personality_side\""
            fi
            
            if [[ -n "$identity" ]]; then
                echo "# 可以描述外貌，性别，身高，职业，属性等等描述"
                echo "identity = \"$identity\""
            fi
            
            if [[ -n "$background_story" ]]; then
                echo "# 此处用于填写详细的世界观、背景故事、复杂人际关系等"
                echo "background_story = \"$background_story\""
            else
                echo "# 此处用于填写详细的世界观、背景故事、复杂人际关系等"
                echo "background_story = \"\""
            fi
            
            if [[ -n "$reply_style" ]]; then
                echo "# 描述MoFox-Bot说话的表达风格，表达习惯"
                echo "reply_style = \"$reply_style\""
            fi
        fi
    else
        # 如果文件完全不存在，创建完整内容
        echo "[personality]"
        if [[ -n "$personality_core" ]]; then
            echo "# 建议50字以内，描述人格的核心特质"
            echo "personality_core = \"$personality_core\""
        fi
        
        if [[ -n "$personality_side" ]]; then
            echo "# 人格的细节，描述人格的一些侧面"
            echo "personality_side = \"$personality_side\""
        fi
        
        if [[ -n "$identity" ]]; then
            echo "# 可以描述外貌，性别，身高，职业，属性等等描述"
            echo "identity = \"$identity\""
        fi
        
        if [[ -n "$background_story" ]]; then
            echo "# 此处用于填写详细的世界观、背景故事、复杂人际关系等"
            echo "background_story = \"$background_story\""
        else
            echo "# 此处用于填写详细的世界观、背景故事、复杂人际关系等"
            echo "background_story = \"\""
        fi
        
        if [[ -n "$reply_style" ]]; then
            echo "# 描述MoFox-Bot说话的表达风格，表达习惯"
            echo "reply_style = \"$reply_style\""
        fi
    fi
} > "$temp_file"

# 替换原文件
mv "$temp_file" "$config_file"

# 设置UTF-8编码
LC_ALL=en_US.UTF-8

echo -e "${GREEN}✓ 人格设定配置完成！${NC}"
# 步骤14.2：配置聊天功能开关
echo ""
echo -e "${CYAN}现在开始配置MoFox-Core的聊天功能开关${NC}"
echo -e "${YELLOW}以下配置将影响机器人的聊天行为和功能${NC}"

# 1. 询问是否允许回复自己说的话
echo -e "${YELLOW}是否允许回复自己说的话？${NC}"
echo -e "  如果开启，机器人可能会回复自己发送的消息"
echo -e "  默认值：否 (n)"
read -p "允许回复自己？(y/n，默认n): " allow_reply_self_input
if [[ "$allow_reply_self_input" =~ ^[Yy]$ ]]; then
    allow_reply_self="true"
else
    allow_reply_self="false"
fi

# 2. 询问是否私聊必然回复
echo -e "${YELLOW}是否开启私聊必然回复？${NC}"
echo -e "  如果开启，机器人在私聊中会必然回复每条消息"
echo -e "  默认值：否 (n)"
read -p "私聊必然回复？(y/n，默认n): " private_chat_input
if [[ "$private_chat_input" =~ ^[Yy]$ ]]; then
    private_chat_inevitable_reply="true"
else
    private_chat_inevitable_reply="false"
fi

# 3. 询问是否启用消息缓存系统
echo -e "${YELLOW}是否启用消息缓存系统？${NC}"
echo -e "  启用后，处理中收到的消息会被缓存，处理完成后统一刷新到未读列表"
echo -e "  可以提高消息处理效率，但可能增加内存使用"
echo -e "  默认值：否 (n)"
read -p "启用消息缓存？(y/n，默认n): " cache_input
if [[ "$cache_input" =~ ^[Yy]$ ]]; then
    enable_message_cache="true"
else
    enable_message_cache="false"
fi

# 4. 询问是否启用消息打断系统
echo -e "${YELLOW}是否启用消息打断系统？${NC}"
echo -e "  启用后，机器人可以根据消息重要性打断当前处理流程"
echo -e "  默认值：否 (n)"
read -p "启用消息打断？(y/n，默认n): " interruption_input
if [[ "$interruption_input" =~ ^[Yy]$ ]]; then
    interruption_enabled="true"
    
    # 如果启用了消息打断系统，询问是否允许在生成回复时打断
    echo -e "${YELLOW}是否允许在正在生成回复时打断？${NC}"
    echo -e "  如果开启，可以在机器人正在生成回复时打断当前回复"
    echo -e "  默认值：否 (n)"
    read -p "允许打断回复？(y/n，默认n): " reply_interruption_input
    if [[ "$reply_interruption_input" =~ ^[Yy]$ ]]; then
        allow_reply_interruption="true"
    else
        allow_reply_interruption="false"
    fi
else
    interruption_enabled="false"
    allow_reply_interruption="false"
fi

# 5. 询问是否允许回复表情包消息
echo -e "${YELLOW}是否允许回复表情包消息？${NC}"
echo -e "  如果开启，机器人可能会对纯表情包消息进行回复"
echo -e "  默认值：否 (n)"
read -p "允许回复表情包？(y/n，默认n): " emoji_input
if [[ "$emoji_input" =~ ^[Yy]$ ]]; then
    allow_reply_to_emoji="true"
else
    allow_reply_to_emoji="false"
fi

# 写入配置
local config_file="config/bot_config.toml"
if [ -f "$config_file" ]; then
    # 确保[chat]节存在
    if ! grep -q "^\[chat\]" "$config_file"; then
        echo -e "\n[chat] #MoFox-Bot的聊天通用设置" >> "$config_file"
    fi
    
    # 更新或添加配置项的函数
    update_config() {
        local key="$1"
        local value="$2"
        local comment="$3"
        
        # 检查配置项是否存在
        if grep -q "^$key\s*=" "$config_file"; then
            # 存在则更新
            sed -i "s/^$key\s*=.*/$key = $value/" "$config_file" 2>> "$INSTALL_LOG"
        else
            # 不存在则添加，放在[chat]节下面
            sed -i "/^\[chat\]/a $key = $value" "$config_file" 2>> "$INSTALL_LOG"
            
            # 如果有注释，在配置项上方添加注释
            if [[ -n "$comment" ]]; then
                sed -i "/^$key = $value/i # $comment" "$config_file" 2>> "$INSTALL_LOG"
            fi
        fi
    }
    
    # 更新或添加各个配置项
    update_config "allow_reply_self" "$allow_reply_self" "是否允许回复自己说的话"
    echo -e "${GREEN}✓ allow_reply_self: $allow_reply_self${NC}"
    
    update_config "private_chat_inevitable_reply" "$private_chat_inevitable_reply" "私聊必然回复"
    echo -e "${GREEN}✓ private_chat_inevitable_reply: $private_chat_inevitable_reply${NC}"
    
    update_config "enable_message_cache" "$enable_message_cache" "是否启用消息缓存系统（启用后，处理中收到的消息会被缓存，处理完成后统一刷新到未读列表）"
    echo -e "${GREEN}✓ enable_message_cache: $enable_message_cache${NC}"
    
    # 处理消息打断系统相关配置
    update_config "interruption_enabled" "$interruption_enabled" "是否启用消息打断系统"
    echo -e "${GREEN}✓ interruption_enabled: $interruption_enabled${NC}"
    
    if [[ "$interruption_enabled" == "true" ]]; then
        update_config "allow_reply_interruption" "$allow_reply_interruption" "是否允许在正在生成回复时打断（true=允许打断回复，false=回复期间不允许打断）"
        echo -e "${GREEN}✓ allow_reply_interruption: $allow_reply_interruption${NC}"
    else
        # 如果未启用消息打断系统，确保allow_reply_interruption为false
        if grep -q "^allow_reply_interruption\s*=" "$config_file"; then
            sed -i "s/^allow_reply_interruption\s*=.*/allow_reply_interruption = false/" "$config_file" 2>> "$INSTALL_LOG"
        fi
    fi
    
    update_config "allow_reply_to_emoji" "$allow_reply_to_emoji" "是否允许回复表情包消息"
    echo -e "${GREEN}✓ allow_reply_to_emoji: $allow_reply_to_emoji${NC}"
    
    # 确保其他重要的配置项存在（如果不存在则使用默认值）
    if ! grep -q "^max_context_size\s*=" "$config_file"; then
        sed -i "/^\[chat\]/a max_context_size = 25 # 上下文长度" "$config_file" 2>> "$INSTALL_LOG"
    fi
    
    if ! grep -q "^thinking_timeout\s*=" "$config_file"; then
        sed -i "/^\[chat\]/a thinking_timeout = 60 # MoFox-Bot一次回复最长思考规划时间，超过这个时间的思考会放弃（往往是api反应太慢）" "$config_file" 2>> "$INSTALL_LOG"
    fi
    
    if ! grep -q "^dynamic_distribution_enabled\s*=" "$config_file"; then
        sed -i "/^\[chat\]/a dynamic_distribution_enabled = true # 是否启用动态消息分发周期调整" "$config_file" 2>> "$INSTALL_LOG"
    fi
    
    echo -e "${GREEN}✓ 聊天功能开关配置完成${NC}"
    
else
    echo -e "${YELLOW}⚠ 配置文件不存在，跳过聊天功能配置${NC}"
fi

    # 步骤15：配置主人QQ
    echo ""
    read -p "请输入主人QQ号: " master_qq
    
    if [[ -n "$master_qq" && "$master_qq" =~ ^[0-9]+$ ]]; then
        local config_file="config/bot_config.toml"
        
        if [ -f "$config_file" ]; then
            # 检查是否已经有master_users配置
            if grep -q "master_users\s*=" "$config_file"; then
                # 如果有配置，替换它
                sed -i "s/master_users\s*=.*/master_users = [[\"qq\", \"$master_qq\"]]/" "$config_file" 2>> "$INSTALL_LOG"
            else
                # 如果没有配置，在文件末尾添加
                echo -e "\n# 主人账号配置" >> "$config_file"
                echo "master_users = [[\"qq\", \"$master_qq\"]]" >> "$config_file"
            fi
            
            echo -e "${GREEN}✓ 主人QQ号配置成功: $master_qq${NC}"
        else
            echo -e "${YELLOW}⚠ 配置文件不存在，跳过主人QQ配置${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ 主人QQ号格式错误，跳过配置${NC}"
    fi
    
    
# 步骤16：配置模型文件
echo -n "配置模型文件... "
if [ -f "template/model_config_template.toml" ]; then
    cp template/model_config_template.toml config/model_config.toml 2>> "$INSTALL_LOG"
    echo -e "${GREEN}✓${NC}"
    
    # 询问用户输入SiliconFlow的API Key
    echo -n "请输入SiliconFlow的API Key（留空则保持默认）: "
    read -r siliconflow_key
    if [ -n "$siliconflow_key" ]; then
        # 定位并替换SiliconFlow下的第一个api_key
        sed -i '/name = "SiliconFlow"/,/^\[\[api_providers\]\]/ {
            /api_key = ".*"/ {
                s/api_key = ".*"/api_key = "'"$siliconflow_key"'"/
                b
            }
        }' config/model_config.toml
        echo -e "${GREEN}  ✓ SiliconFlow API Key已更新${NC}"
    fi
else
    echo -e "${YELLOW}⚠${NC}"
    print_message "$YELLOW" "未找到模型配置模板"
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
echo "配置Napcat插件..."

# 定义可能的目录
PLUGIN_DIR1="config/plugins/napcat_adapter_plugin"
PLUGIN_DIR2="config/plugins/napcat_adapter"
TEMPLATE_DIR1="template/plugins/napcat_adapter_plugin"
TEMPLATE_DIR2="template/plugins/napcat_adapter"

# 确保插件目录存在
mkdir -p "$PLUGIN_DIR1" "$PLUGIN_DIR2" 2>/dev/null

# 检查当前存在的配置文件
config_found=false
config_file=""

# 检查哪些目录有配置文件
if [ -f "$PLUGIN_DIR1/config.toml" ]; then
    config_found=true
    config_file="$PLUGIN_DIR1/config.toml"
    echo -e "${GREEN}✓ 找到配置文件: $config_file${NC}"
elif [ -f "$PLUGIN_DIR2/config.toml" ]; then
    config_found=true
    config_file="$PLUGIN_DIR2/config.toml"
    echo -e "${GREEN}✓ 找到配置文件: $config_file${NC}"
fi

# 如果配置文件不存在，从模板复制
if [ "$config_found" = false ]; then
    # 检查模板源
    if [ -f "$TEMPLATE_DIR1/config.toml" ]; then
        # 复制到两个目标目录
        echo -e "${CYAN}从模板复制到两个插件目录...${NC}"
        cp "$TEMPLATE_DIR1/config.toml" "$PLUGIN_DIR1/config.toml" 2>> "$INSTALL_LOG"
        cp "$TEMPLATE_DIR1/config.toml" "$PLUGIN_DIR2/config.toml" 2>> "$INSTALL_LOG"
        config_file="$PLUGIN_DIR1/config.toml"
        echo -e "${GREEN}✓ 模板复制完成${NC}"
    elif [ -f "$TEMPLATE_DIR2/config.toml" ]; then
        # 复制到两个目标目录
        echo -e "${CYAN}从模板复制到两个插件目录...${NC}"
        cp "$TEMPLATE_DIR2/config.toml" "$PLUGIN_DIR1/config.toml" 2>> "$INSTALL_LOG"
        cp "$TEMPLATE_DIR2/config.toml" "$PLUGIN_DIR2/config.toml" 2>> "$INSTALL_LOG"
        config_file="$PLUGIN_DIR1/config.toml"
        echo -e "${GREEN}✓ 模板复制完成${NC}"
    else
        echo -e "${YELLOW}⚠ 未找到插件模板文件${NC}"
    fi
else
    # 如果已有配置文件，复制到另一个目录（如果不存在）
    if [ "$config_file" = "$PLUGIN_DIR1/config.toml" ] && [ ! -f "$PLUGIN_DIR2/config.toml" ]; then
        echo -e "${CYAN}复制到另一个插件目录...${NC}"
        cp "$config_file" "$PLUGIN_DIR2/config.toml" 2>> "$INSTALL_LOG"
        echo -e "${GREEN}✓ 配置文件复制完成${NC}"
    elif [ "$config_file" = "$PLUGIN_DIR2/config.toml" ] && [ ! -f "$PLUGIN_DIR1/config.toml" ]; then
        echo -e "${CYAN}复制到另一个插件目录...${NC}"
        cp "$config_file" "$PLUGIN_DIR1/config.toml" 2>> "$INSTALL_LOG"
        echo -e "${GREEN}✓ 配置文件复制完成${NC}"
    fi
fi

# 配置现有的配置文件（如果存在）
configure_plugin_config() {
    local config_file="$1"
    
    if [ -f "$config_file" ]; then
        echo -e "${CYAN}配置 $config_file ...${NC}"
        
        # 启用插件
        sed -i 's/^enabled\s*=\s*false/enabled = true/' "$config_file" 2>> "$INSTALL_LOG"
        
        # 检查端口配置
        if grep -q '^\s*port\s*=' "$config_file"; then
            # 获取当前端口
            current_port=$(grep '^\s*port\s*=' "$config_file" | head -1 | sed 's/.*=\s*//;s/\s*#.*//' | tr -d ' ' | tr -d '"' | tr -d "'")
            
            if [ -n "$current_port" ] && [ "$current_port" != "8095" ]; then
                echo -e "${YELLOW}  检测到端口为 $current_port，改为8095${NC}"
                sed -i "s/^port\s*=.*/port = 8095/" "$config_file" 2>> "$INSTALL_LOG"
                echo -e "${GREEN}  端口已配置为8095${NC}"
            else
                echo -e "${GREEN}  端口已经是8095${NC}"
            fi
        else
            # 添加端口配置
            echo -e "${YELLOW}  未找到端口配置，添加端口8095${NC}"
            echo -e "\n# Napcat WebSocket 服务端口\nport = 8095" >> "$config_file"
        fi
        
        echo -e "${GREEN}  $config_file 配置完成${NC}"
        return 0
    fi
    return 1
}

# 配置两个目录的配置文件
config_configured=false

echo ""
echo -e "${CYAN}开始配置插件文件...${NC}"

# 配置第一个目录
if [ -f "$PLUGIN_DIR1/config.toml" ]; then
    configure_plugin_config "$PLUGIN_DIR1/config.toml"
    config_configured=true
fi

# 配置第二个目录
if [ -f "$PLUGIN_DIR2/config.toml" ]; then
    configure_plugin_config "$PLUGIN_DIR2/config.toml"
    config_configured=true
fi

# 如果没有任何配置文件，创建默认配置
if [ "$config_configured" = false ]; then
    echo -e "${YELLOW}⚠ 未找到或创建任何配置文件，创建默认配置...${NC}"
    
    # 创建默认配置到两个目录
    cat > "$PLUGIN_DIR1/config.toml" << EOF
# Napcat WebSocket 适配器配置
enabled = true

# Napcat WebSocket 服务端口
port = 8095

# WebSocket 连接超时时间（秒）
timeout = 30

# 重连间隔（秒）
reconnect_interval = 5

# 心跳间隔（秒）
heartbeat_interval = 30
EOF
    
    cp "$PLUGIN_DIR1/config.toml" "$PLUGIN_DIR2/config.toml" 2>/dev/null
    
    echo -e "${GREEN}✓ 默认配置创建完成${NC}"
fi

echo ""
echo -e "${GREEN}✓ Napcat插件配置完成${NC}"

# 显示配置摘要
echo ""
echo -e "${CYAN}Napcat插件配置摘要：${NC}"
if [ -f "$PLUGIN_DIR1/config.toml" ]; then
    echo -e "${YELLOW}  $PLUGIN_DIR1/config.toml${NC}"
    echo -e "${YELLOW}    启用状态：$(grep '^enabled =' "$PLUGIN_DIR1/config.toml" 2>/dev/null || echo "未找到")${NC}"
    echo -e "${YELLOW}    端口配置：$(grep '^port =' "$PLUGIN_DIR1/config.toml" 2>/dev/null || echo "未找到")${NC}"
fi

if [ -f "$PLUGIN_DIR2/config.toml" ]; then
    echo -e "${YELLOW}  $PLUGIN_DIR2/config.toml${NC}"
    echo -e "${YELLOW}    启用状态：$(grep '^enabled =' "$PLUGIN_DIR2/config.toml" 2>/dev/null || echo "未找到")${NC}"
    echo -e "${YELLOW}    端口配置：$(grep '^port =' "$PLUGIN_DIR2/config.toml" 2>/dev/null || echo "未找到")${NC}"
fi

echo ""

    
    # 步骤21：测试虚拟环境
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
check_system_resources_strict
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
    print_message "$YELLOW" "系统将在60秒后重启..."
    sleep 60
    reboot
fi

exit 0