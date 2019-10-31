#!/bin/bash
#
# #------------------------------------------------------------------#
# |   LemonBench 服务器测试工具      LemonBench Server Test Utility   |
# #------------------------------------------------------------------#
# | Written by iLemonrain <ilemonrain@ilemonrain.com>                |
# | My Blog: https://ilemonrain.com                                  |
# | Telegram: https://t.me/ilemonrain                                |
# | Telegram (For +86 User): https://t.me/ilemonrain_chatbot         |
# | Telegram Channel: https://t.me/ilemonrain_channel                |
# #------------------------------------------------------------------#
# | If you like this project, feel free to donate!                   |
# | 如果你喜欢这个项目, 欢迎投喂打赏！                                  |
# |                                                                  |
# | Donate Method 打赏方式：                                          |
# | Alipay QR Code: http://t.cn/EA3pZNt                              |
# | 支付宝二维码：http://t.cn/EA3pZNt                                 |
# | Wechat QR Code: http://t.cn/EA3p639                              |
# | 微信二维码: http://t.cn/EA3p639                                   |
# #------------------------------------------------------------------#
#
# 使用方法 (任选其一):
# (1) wget -qO- https://ilemonrain.com/download/shell/LemonBench.sh | bash
# (2) curl -fsL https://ilemonrain.com/download/shell/LemonBench.sh | bash
#
# === 全局定义 =====================================

# 全局参数定义
BuildTime="20191007 BetaVersion"
WorkDir="/tmp/.LemonBench"
UA_LemonBench="LemonBench/${BuildTime}"
UA_Browser="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/75.0.3770.142 Safari/537.36"

# 字体颜色定义
Font_Black="\033[30m"
Font_Red="\033[31m"
Font_Green="\033[32m"
Font_Yellow="\033[33m"
Font_Blue="\033[34m"
Font_Purple="\033[35m"
Font_SkyBlue="\033[36m"
Font_White="\033[37m"
Font_Suffix="\033[0m"

# 消息提示定义
Msg_Info="${Font_Blue}[Info] ${Font_Suffix}"
Msg_Warning="${Font_Yellow}[Warning] ${Font_Suffix}"
Msg_Debug="${Font_Yellow}[Debug] ${Font_Suffix}"
Msg_Error="${Font_Red}[Error] ${Font_Suffix}"
Msg_Success="${Font_Green}[Success] ${Font_Suffix}"
Msg_Fail="${Font_Red}[Failed] ${Font_Suffix}"

# =================================================

# === 全局模块 =====================================

# Trap终止信号捕获
trap "Global_TrapSigExit_Sig1" 1
trap "Global_TrapSigExit_Sig2" 2
trap "Global_TrapSigExit_Sig3" 3
trap "Global_TrapSigExit_Sig15" 15

# Trap终止信号1 - 处理
Global_TrapSigExit_Sig1() {
    echo -e "\n\n${Msg_Error}接收到终止信号(SIGHUP), 正在退出 ...\n"
    Global_TrapSigExit_Action
    exit 1
}

# Trap终止信号2 - 处理 (Ctrl+C)
Global_TrapSigExit_Sig2() {
    echo -e "\n\n${Msg_Error}接收到终止信号(SIGINT / Ctrl+C), 正在退出 ...\n"
    Global_TrapSigExit_Action
    exit 1
}

# Trap终止信号3 - 处理
Global_TrapSigExit_Sig3() {
    echo -e "\n\n${Msg_Error}接收到终止信号(SIGQUIT), 正在退出 ...\n"
    Global_TrapSigExit_Action
    exit 1
}

# Trap终止信号15 - 处理 (进程被杀)
Global_TrapSigExit_Sig15() {
    echo -e "\n\n${Msg_Error}接收到终止信号(SIGTERM), 正在退出 ...\n"
    Global_TrapSigExit_Action
    exit 1
}

# 简易JSON解析器 (Deprecated)
# PharseJSON() {
#    # 使用方法: PharseJSON "要解析的原JSON文本" "要解析的键值"
#    # Example: PharseJSON ""Value":"123456"" "Value" [返回结果: 123456]
#    echo -n $1 | grep -oP '(?<='$2'":)[0-9A-Za-z]+'
#    if [ "$?" = "1" ]; then
#        echo -n $1 | grep -oP ''$2'[" :]+\K[^"]+'
#        if [ "$?" = "1" ]; then
#            echo -n "null"
#            return 1
#        fi
#    fi
#}

# 新版JSON解析
PharseJSON() {
    # 使用方法: PharseJSON "要解析的原JSON文本" "要解析的键值"
    # Example: PharseJSON ""Value":"123456"" "Value" [返回结果: 123456]
    echo -n $1 | jq -r .$2
}

# Ubuntu PasteBin 提交工具
# 感谢 @metowolf 提供思路
PasteBin_Upload() {
    local uploadresult="$(curl -fsL -X POST \
        --url https://paste.ubuntu.com \
        --output /dev/null \
        --write-out "%{url_effective}\n" \
        --data-urlencode "content@${PASTEBIN_CONTENT:-/dev/stdin}" \
        --data "poster=${PASTEBIN_POSTER:-LemonBench}" \
        --data "expiration=${PASTEBIN_EXPIRATION:-year}" \
        --data "syntax=${PASTEBIN_SYNTAX:-text}")"
    if [ "$?" = "0" ]; then
        echo -e "${Msg_Success}云端测试报告生成完成！请注意及时保存！"
        echo -e "${Msg_Info}报告地址：${uploadresult}"
    else
        echo -e "${Msg_Warning}云端测试报告生成失败, 但您仍然可以通过 $HOME/LemonBench.Result.txt 获取测试报告内容！"
    fi
}

# 读取配置文件
ReadConfig() {
    # 使用方法: ReadConfig <配置文件> <读取参数>
    # Example: ReadConfig "/etc/config.cfg" "Parameter"
    cat $1 | sed '/^'$2'=/!d;s/.*=//'
}

# 程序启动动作
Global_StartupInit_Action() {
    Global_Startup_Header
    echo -e "${Msg_Info}已启动测试模式：${Font_SkyBlue}${Global_TestModeTips}${Font_Suffix}"
    # 清理残留, 为新一次的运行做好准备
    echo -e "${Msg_Info}正在初始化环境, 请稍后 ..."
    rm -rf ${WorkDir}
    rm -rf /.tmp_LBench/
    mkdir ${WorkDir}/
    echo -e "${Msg_Info}正在检查必需环境 ..."
    Check_Virtwhat
    Check_JSONQuery
    Check_Speedtest
    Check_BestTrace
    Check_Spoofer
    Check_SysBench
    echo -e "${Msg_Info}正在启动测试 ...\n\n"
    clear
}

Global_Exit_Action() {
    rm -rf ${WorkDir}/
}

# 捕获异常信号后的动作
Global_TrapSigExit_Action() {
    rm -rf ${WorkDir}
    rm -rf /.tmp_LBench/
}

# =================================================

# =============== -> 主程序开始 <- ===============

# =============== SystemInfo模块 部分 ===============
SystemInfo_GetHostname() {
    LBench_Result_Hostname="$(hostname)"
}

SystemInfo_GetCPUInfo() {
    mkdir -p ${WorkDir}/data >/dev/null 2>&1
    cat /proc/cpuinfo >${WorkDir}/data/cpuinfo
    local ReadCPUInfo="cat ${WorkDir}/data/cpuinfo"
    LBench_Result_CPUModelName="$($ReadCPUInfo | awk -F ': ' '/model name/{print $2}' | sort -u)"
    LBench_Result_CPUCacheSize="$($ReadCPUInfo | awk -F ': ' '/cache size/{print $2}' | sort -u)"
    LBench_Result_CPUPhysicalNumber="$($ReadCPUInfo | awk -F ': ' '/physical id/{print $2}' | sort -u | wc -l)"
    LBench_Result_CPUCoreNumber="$($ReadCPUInfo | awk -F ': ' '/cpu cores/{print $2}' | sort -u)"
    LBench_Result_CPUThreadNumber="$($ReadCPUInfo | awk -F ': ' '/cores/{print $2}' | wc -l)"
    LBench_Result_CPUProcessorNumber="$($ReadCPUInfo | awk -F ': ' '/processor/{print $2}' | wc -l)"
    LBench_Result_CPUSiblingsNumber="$($ReadCPUInfo | awk -F ': ' '/siblings/{print $2}' | sort -u)"
    LBench_Result_CPUTotalCoreNumber="$($ReadCPUInfo | awk -F ': ' '/physical id/&&/0/{print $2}' | wc -l)"
    # 虚拟化能力检测
    SystemInfo_GetVirtType
    if [ "${Var_VirtType}" = "dedicated" ] || [ "${Var_VirtType}" = "wsl" ]; then
        LBench_Result_CPUIsPhysical="1"
        local VirtCheck="$(cat /proc/cpuinfo | grep -oE 'vmx|svm' | uniq)"
        if [ "${VirtCheck}" != "" ]; then
            LBench_Result_CPUVirtualization="1"
            local VirtualizationType="$(lscpu | awk /Virtualization:/'{print $2}')"
            LBench_Result_CPUVirtualizationType="${VirtualizationType}"
        else
            LBench_Result_CPUVirtualization="0"
        fi
    else
        LBench_Result_CPUIsPhysical="0"
    fi
}

SystemInfo_GetCPUStat() {
    local CPUStat_Result="$(top -bn1 | grep Cpu)"
    # 原始数据
    LBench_Result_CPUStat_user="$(Function_ReadCPUStat "${CPUStat_Result}" "us")"
    LBench_Result_CPUStat_system="$(Function_ReadCPUStat "${CPUStat_Result}" "sy")"
    LBench_Result_CPUStat_nice="$(Function_ReadCPUStat "${CPUStat_Result}" "ni")"
    LBench_Result_CPUStat_idle="$(Function_ReadCPUStat "${CPUStat_Result}" "id")"
    LBench_Result_CPUStat_iowait="$(Function_ReadCPUStat "${CPUStat_Result}" "wa")"
    LBench_Result_CPUStat_hardint="$(Function_ReadCPUStat "${CPUStat_Result}" "hi")"
    LBench_Result_CPUStat_softint="$(Function_ReadCPUStat "${CPUStat_Result}" "si")"
    LBench_Result_CPUStat_steal="$(Function_ReadCPUStat "${CPUStat_Result}" "st")"
    # 加工后的数据
    LBench_Result_CPUStat_UsedAll="$(echo ${LBench_Result_CPUStat_user} ${LBench_Result_CPUStat_system} ${LBench_Result_CPUStat_nice} | awk '{printf "%.1f\n",$1+$2+$3}')"
}

Function_ReadCPUStat() {
    if [ "$1" == "" ]; then
        echo -n "nil"
    else
        local result="$(echo $1 | grep -oE "[0-9]{1,2}.[0-9]{1} $2" | awk '{print $1}')"
        echo $result
    fi
}

SystemInfo_GetSystemBit() {
    LBench_Result_SystemBit="$(uname -m)"
    if [ "${LBench_Result_SystemBit}" = "unknown" ]; then
        LBench_Result_SystemBit="$(arch)"
    fi
    local is64="$(uname -m | grep -o "64")"
    if [ "${is64}" == "64" ]; then
        LBench_Result_SystemBit_Short="64"
        LBench_Result_SystemBit_Full="amd64"
    else
        LBench_Result_SystemBit_Short="32"
        LBench_Result_SystemBit_Full="i386"
    fi
}

SystemInfo_GetMemInfo() {
    mkdir -p ${WorkDir}/data >/dev/null 2>&1
    cat /proc/meminfo >${WorkDir}/data/meminfo
    local ReadMemInfo="cat ${WorkDir}/data/meminfo"
    # 获取总内存
    LBench_Result_MemoryTotal_KB="$($ReadMemInfo | awk '/MemTotal/{print $2}')"
    LBench_Result_MemoryTotal_MB="$(echo $LBench_Result_MemoryTotal_KB | awk '{printf "%.2f\n",$1/1024}')"
    LBench_Result_MemoryTotal_GB="$(echo $LBench_Result_MemoryTotal_KB | awk '{printf "%.2f\n",$1/1048576}')"
    # 获取可用内存
    local MemFree="$($ReadMemInfo | awk '/MemFree/{print $2}')"
    local Buffers="$($ReadMemInfo | awk '/Buffers/{print $2}')"
    local Cached="$($ReadMemInfo | awk '/Cached/{print $2}')"
    LBench_Result_MemoryFree_KB="$(echo $MemFree $Buffers $Cached | awk '{printf $1+$2+$3}')"
    LBench_Result_MemoryFree_MB="$(echo $LBench_Result_MemoryFree_KB | awk '{printf "%.2f\n",$1/1024}')"
    LBench_Result_MemoryFree_GB="$(echo $LBench_Result_MemoryFree_KB | awk '{printf "%.2f\n",$1/1048576}')"
    # 获取已用内存
    local MemUsed="$(echo $LBench_Result_MemoryTotal_KB $LBench_Result_MemoryFree_KB | awk '{printf $1-$2}')"
    LBench_Result_MemoryUsed_KB="$MemUsed"
    LBench_Result_MemoryUsed_MB="$(echo $LBench_Result_MemoryUsed_KB | awk '{printf "%.2f\n",$1/1024}')"
    LBench_Result_MemoryUsed_GB="$(echo $LBench_Result_MemoryUsed_KB | awk '{printf "%.2f\n",$1/1048576}')"
    # 获取Swap总量
    LBench_Result_SwapTotal_KB="$($ReadMemInfo | awk '/SwapTotal/{print $2}')"
    LBench_Result_SwapTotal_MB="$(echo $LBench_Result_SwapTotal_KB | awk '{printf "%.2f\n",$1/1024}')"
    LBench_Result_SwapTotal_GB="$(echo $LBench_Result_SwapTotal_KB | awk '{printf "%.2f\n",$1/1048576}')"
    # 获取可用Swap
    LBench_Result_SwapFree_KB="$($ReadMemInfo | awk '/SwapFree/{print $2}')"
    LBench_Result_SwapFree_MB="$(echo $LBench_Result_SwapFree_KB | awk '{printf "%.2f\n",$1/1024}')"
    LBench_Result_SwapFree_GB="$(echo $LBench_Result_SwapFree_KB | awk '{printf "%.2f\n",$1/1048576}')"
    # 获取已用Swap
    local SwapUsed="$(echo $LBench_Result_SwapTotal_KB $LBench_Result_SwapFree_KB | awk '{printf $1-$2}')"
    LBench_Result_SwapUsed_KB="$SwapUsed"
    LBench_Result_SwapUsed_MB="$(echo $LBench_Result_SwapUsed_KB | awk '{printf "%.2f\n",$1/1024}')"
    LBench_Result_SwapUsed_GB="$(echo $LBench_Result_SwapUsed_KB | awk '{printf "%.2f\n",$1/1048576}')"
}

SystemInfo_GetOSRelease() {
    if [ -f "/etc/centos-release" ]; then # CentOS
        Var_OSRelease="centos"
        local Var_OSReleaseFullName="$(cat /etc/os-release | awk -F '[= "]' '/PRETTY_NAME/{print $3,$4}')"
        if [ "$(rpm -qa | grep -o el6 | sort -u)" = "el6" ]; then
            Var_CentOSELRepoVersion="6"
            local Var_OSReleaseVersion="$(cat /etc/centos-release | awk '{print $3}')"
        elif [ "$(rpm -qa | grep -o el7 | sort -u)" = "el7" ]; then
            Var_CentOSELRepoVersion="7"
            local Var_OSReleaseVersion="$(cat /etc/centos-release | awk '{print $4}')"
        elif [ "$(rpm -qa | grep -o el8 | sort -u)" = "el8" ]; then
            Var_CentOSELRepoVersion="8"
            local Var_OSReleaseVersion="$(cat /etc/centos-release | awk '{print $4}')"
        else
            local Var_CentOSELRepoVersion="unknown"
            local Var_OSReleaseVersion="<Unknown Release>"
        fi
        local Var_OSReleaseArch="$(arch)"
        LBench_Result_OSReleaseFullName="$Var_OSReleaseFullName $Var_OSReleaseVersion ($Var_OSReleaseArch)"
    elif [ -f "/etc/redhat-release" ]; then # RedHat
        Var_OSRelease="rhel"
        local Var_OSReleaseFullName="$(cat /etc/os-release | awk -F '[= "]' '/PRETTY_NAME/{print $3,$4}')"
        if [ "$(rpm -qa | grep -o el6 | sort -u)" = "el6" ]; then
            Var_RedHatELRepoVersion="6"
            local Var_OSReleaseVersion="$(cat /etc/redhat-release | awk '{print $3}')"
        elif [ "$(rpm -qa | grep -o el7 | sort -u)" = "el7" ]; then
            Var_RedHatELRepoVersion="7"
            local Var_OSReleaseVersion="$(cat /etc/redhat-release | awk '{print $4}')"
        elif [ "$(rpm -qa | grep -o el8 | sort -u)" = "el8" ]; then
            Var_RedHatELRepoVersion="8"
            local Var_OSReleaseVersion="$(cat /etc/redhat-release | awk '{print $4}')"
        else
            local Var_RedHatELRepoVersion="unknown"
            local Var_OSReleaseVersion="<Unknown Release>"
        fi
        local Var_OSReleaseArch="$(arch)"
        LBench_Result_OSReleaseFullName="$Var_OSReleaseFullName $Var_OSReleaseVersion ($Var_OSReleaseArch)"
    elif [ -f "/etc/fedora-release" ]; then # Fedora
        Var_OSRelease="fedora"
        local Var_OSReleaseFullName="$(cat /etc/os-release | awk -F '[= "]' '/PRETTY_NAME/{print $3}')"
        local Var_OSReleaseVersion="$(cat /etc/fedora-release | awk '{print $3,$4,$5,$6,$7}')"
        local Var_OSReleaseArch="$(arch)"
        LBench_Result_OSReleaseFullName="$Var_OSReleaseFullName $Var_OSReleaseVersion ($Var_OSReleaseArch)"
    elif [ -f "/etc/lsb-release" ]; then # Ubuntu
        Var_OSRelease="ubuntu"
        local Var_OSReleaseFullName="$(cat /etc/os-release | awk -F '[= "]' '/NAME/{print $3}' | head -n1)"
        local Var_OSReleaseVersion="$(cat /etc/os-release | awk -F '[= "]' '/VERSION/{print $3,$4,$5,$6,$7}' | head -n1)"
        local Var_OSReleaseArch="$(arch)"
        LBench_Result_OSReleaseFullName="$Var_OSReleaseFullName $Var_OSReleaseVersion ($Var_OSReleaseArch)"
        Var_OSReleaseVersion_Short="$(cat /etc/lsb-release | awk -F '[= "]' '/DISTRIB_RELEASE/{print $2}')"
    elif [ -f "/etc/debian_version" ]; then # Debian
        Var_OSRelease="debian"
        local Var_OSReleaseFullName="$(cat /etc/os-release | awk -F '[= "]' '/PRETTY_NAME/{print $3,$4}')"
        local Var_OSReleaseVersion="$(cat /etc/debian_version | awk '{print $1}')"
        local Var_OSReleaseVersionShort="$(cat /etc/debian_version | awk '{printf "%d\n",$1}')"
        if [ "${Var_OSReleaseVersionShort}" = "7" ]; then
            Var_OSReleaseVersion_Short="7"
            Var_OSReleaseVersion_Codename="wheezy"
            local Var_OSReleaseFullName="${Var_OSReleaseFullName} \"Wheezy\""
        elif [ "${Var_OSReleaseVersionShort}" = "8" ]; then
            Var_OSReleaseVersion_Short="8"
            Var_OSReleaseVersion_Codename="jessie"
            local Var_OSReleaseFullName="${Var_OSReleaseFullName} \"Jessie\""
        elif [ "${Var_OSReleaseVersionShort}" = "9" ]; then
            Var_OSReleaseVersion_Short="9"
            Var_OSReleaseVersion_Codename="stretch"
            local Var_OSReleaseFullName="${Var_OSReleaseFullName} \"Stretch\""
        elif [ "${Var_OSReleaseVersionShort}" = "10" ]; then
            Var_OSReleaseVersion_Short="10"
            Var_OSReleaseVersion_Codename="buster"
            local Var_OSReleaseFullName="${Var_OSReleaseFullName} \"Buster\""
        else
            Var_OSReleaseVersion_Short="sid"
            Var_OSReleaseVersion_Codename="sid"
            local Var_OSReleaseFullName="${Var_OSReleaseFullName} \"Sid (Testing)\""
        fi
        local Var_OSReleaseArch="$(arch)"
        LBench_Result_OSReleaseFullName="$Var_OSReleaseFullName $Var_OSReleaseVersion ($Var_OSReleaseArch)"
    elif [ -f "/etc/alpine-release" ]; then # Alpine Linux
        Var_OSRelease="alpinelinux"
        local Var_OSReleaseFullName="$(cat /etc/os-release | awk -F '[= "]' '/NAME/{print $3,$4}' | head -n1)"
        local Var_OSReleaseVersion="$(cat /etc/alpine-release | awk '{print $1}')"
        local Var_OSReleaseArch="$(arch)"
        LBench_Result_OSReleaseFullName="$Var_OSReleaseFullName $Var_OSReleaseVersion ($Var_OSReleaseArch)"
    else
        Var_OSRelease="unknown" # 未知系统分支
        LBench_Result_OSReleaseFullName="[Error: 未知系统分支 !]"
    fi
}

SystemInfo_GetVirtType() {
    if [ -f "/usr/bin/systemd-detect-virt" ]; then
        Var_VirtType="$(/usr/bin/systemd-detect-virt)"
        # 虚拟机检测
        if [ "${Var_VirtType}" = "qemu" ]; then
            LBench_Result_VirtType="QEMU"
        elif [ "${Var_VirtType}" = "kvm" ]; then
            LBench_Result_VirtType="KVM"
        elif [ "${Var_VirtType}" = "zvm" ]; then
            LBench_Result_VirtType="S390 Z/VM"
        elif [ "${Var_VirtType}" = "vmware" ]; then
            LBench_Result_VirtType="VMware"
        elif [ "${Var_VirtType}" = "microsoft" ]; then
            LBench_Result_VirtType="Microsoft Hyper-V"
        elif [ "${Var_VirtType}" = "xen" ]; then
            LBench_Result_VirtType="XenServer"
        elif [ "${Var_VirtType}" = "bochs" ]; then
            LBench_Result_VirtType="BOCHS"   
        elif [ "${Var_VirtType}" = "uml" ]; then
            LBench_Result_VirtType="User-mode Linux"   
        elif [ "${Var_VirtType}" = "parallels" ]; then
            LBench_Result_VirtType="Parallels"   
        elif [ "${Var_VirtType}" = "bhyve" ]; then
            LBench_Result_VirtType="FreeBSD Hypervisor"
        # 容器虚拟化检测
        elif [ "${Var_VirtType}" = "openvz" ]; then
            LBench_Result_VirtType="OpenVZ"
        elif [ "${Var_VirtType}" = "lxc" ]; then
            LBench_Result_VirtType="LXC"        
        elif [ "${Var_VirtType}" = "lxc-libvirt" ]; then
            LBench_Result_VirtType="LXC (libvirt)"        
        elif [ "${Var_VirtType}" = "systemd-nspawn" ]; then
            LBench_Result_VirtType="Systemd nspawn"        
        elif [ "${Var_VirtType}" = "docker" ]; then
            LBench_Result_VirtType="Docker"        
        elif [ "${Var_VirtType}" = "rkt" ]; then
            LBench_Result_VirtType="RKT"
        # 特殊处理
        elif [ -c "/dev/lxss" ]; then # 处理WSL虚拟化
            Var_VirtType="wsl"
            LBench_Result_VirtType="Windows Subsystem for Linux (WSL)"
        # 未匹配到任何结果, 或者非虚拟机 
        elif [ "${Var_VirtType}" = "none" ]; then
            LBench_Result_VirtType="无"
        fi
    elif [ ! -f "/usr/sbin/virt-what" ]; then
        Var_VirtType="Unknown"
        LBench_Result_VirtType="[Error: 未安装virt-what !]"
    elif [ -f "/.dockerenv" ]; then # 处理Docker虚拟化
        Var_VirtType="docker"
        LBench_Result_VirtType="Docker"
    elif [ -c "/dev/lxss" ]; then # 处理WSL虚拟化
        Var_VirtType="wsl"
        LBench_Result_VirtType="Windows Subsystem for Linux (WSL)"
    else # 正常判断流程
        Var_VirtType="$(virt-what | xargs)"
        local Var_VirtTypeCount="$(echo $Var_VirtTypeCount | wc -l)"
        if [ "${Var_VirtTypeCount}" -gt "1" ]; then # 处理嵌套虚拟化
            LBench_Result_VirtType="echo ${Var_VirtType}"
            Var_VirtType="$(echo ${Var_VirtType} | head -n1)" # 使用检测到的第一种虚拟化继续做判断
        elif [ "${Var_VirtTypeCount}" -eq "1" ] && [ "${Var_VirtType}" != "" ]; then # 只有一种虚拟化
            LBench_Result_VirtType="${Var_VirtType}"
        else
            local Var_BIOSVendor="$(dmidecode -s bios-vendor)"
            if [ "${Var_BIOSVendor}" = "SeaBIOS" ]; then
                Var_VirtType="Unknown"
                LBench_Result_VirtType="Unknown with SeaBIOS BIOS"
            else
                Var_VirtType="dedicated"
                LBench_Result_VirtType="Dedicated with ${Var_BIOSVendor} BIOS"
            fi
        fi
    fi
}

SystemInfo_GetLoadAverage() {
    local Var_LoadAverage="$(cat /proc/loadavg)"
    LBench_Result_LoadAverage_1min="$(echo ${Var_LoadAverage} | awk '{print $1}')"
    LBench_Result_LoadAverage_5min="$(echo ${Var_LoadAverage} | awk '{print $2}')"
    LBench_Result_LoadAverage_15min="$(echo ${Var_LoadAverage} | awk '{print $3}')"
}

SystemInfo_GetDiskStat() {
    LBench_Result_DiskRootPath="$(df -x tmpfs / | awk "NR>1" | sed ":a;N;s/\\n//g;ta" | awk '{print $1}')"
    local Var_DiskTotalSpace_KB="$(df -x tmpfs / | grep -oE "[0-9]{4,}" | awk 'NR==1 {print $1}')"
    LBench_Result_DiskTotal_KB="${Var_DiskTotalSpace_KB}"
    LBench_Result_DiskTotal_MB="$(echo ${Var_DiskTotalSpace_KB} | awk '{printf "%.2f\n",$1/1000}')"
    LBench_Result_DiskTotal_GB="$(echo ${Var_DiskTotalSpace_KB} | awk '{printf "%.2f\n",$1/1000000}')"
    LBench_Result_DiskTotal_TB="$(echo ${Var_DiskTotalSpace_KB} | awk '{printf "%.2f\n",$1/1000000000}')"
    local Var_DiskUsedSpace_KB="$(df -x tmpfs / | grep -oE "[0-9]{4,}" | awk 'NR==2 {print $1}')"
    LBench_Result_DiskUsed_KB="${Var_DiskUsedSpace_KB}"
    LBench_Result_DiskUsed_MB="$(echo ${LBench_Result_DiskUsed_KB} | awk '{printf "%.2f\n",$1/1000}')"
    LBench_Result_DiskUsed_GB="$(echo ${LBench_Result_DiskUsed_KB} | awk '{printf "%.2f\n",$1/1000000}')"
    LBench_Result_DiskUsed_TB="$(echo ${LBench_Result_DiskUsed_KB} | awk '{printf "%.2f\n",$1/1000000000}')"
    local Var_DiskFreeSpace_KB="$(df -x tmpfs / | grep -oE "[0-9]{4,}" | awk 'NR==3 {print $1}')"
    LBench_Result_DiskFree_KB="${Var_DiskFreeSpace_KB}"
    LBench_Result_DiskFree_MB="$(echo ${LBench_Result_DiskFree_KB} | awk '{printf "%.2f\n",$1/1000}')"
    LBench_Result_DiskFree_GB="$(echo ${LBench_Result_DiskFree_KB} | awk '{printf "%.2f\n",$1/1000000}')"
    LBench_Result_DiskFree_TB="$(echo ${LBench_Result_DiskFree_KB} | awk '{printf "%.2f\n",$1/1000000000}')"
}

SystemInfo_GetNetworkInfo() {
    local LBench_TempResult_LocalIP_IPV4="$(curl --connect-timeout 5 -fsL4 "https://api.saltyfish.eu/ipdb.php?appkey=jmn8dvncsb2batcyhs7pgiut&ip=")"
    LBench_Result_LocalIP_IPV4="$(PharseJSON "${LBench_TempResult_LocalIP_IPV4}" "IP")"
    LBench_Result_LocalIP_IPV6="$(curl --connect-timeout 5 -fsL6 http://api-ipv6.ip.sb)"
    # 判断三种网络情况：
    # - IPV4 Only：只有IPV4
    # - IPV6 Only：只有IPV6
    # - DualStack：双栈 (IPV4+IPV6)
    #
    # 判断IPV4 Only
    if [ "${LBench_Result_LocalIP_IPV4}" != "" ] && [ "${LBench_Result_LocalIP_IPV6}" = "" ]; then
        LBench_Result_NetworkStat="ipv4only"
        local IPAPI_Result_IPV4="$(curl -fsL4 --connect-timeout 5 "https://api.saltyfish.eu/ipdb.php?appkey=jmn8dvncsb2batcyhs7pgiut&ip=${LBench_Result_LocalIP_IPV4}")"
    # 判断IPV6 Only
    elif [ "${LBench_Result_LocalIP_IPV4}" = "" ] && [ "${LBench_Result_LocalIP_IPV6}" != "" ]; then
        LBench_Result_NetworkStat="ipv6only"
        local IPAPI_Result_IPV6="$(curl -fsL6 --connect-timeout 5 https://api-ipv6.ip.sb/geoip)"
    # 判断双栈
    elif [ "${LBench_Result_LocalIP_IPV4}" != "" ] && [ "${LBench_Result_LocalIP_IPV6}" != "" ]; then
        LBench_Result_NetworkStat="dualstack"
        local IPAPI_Result_IPV4="$(curl -fsL4 --connect-timeout 5 "https://api.saltyfish.eu/ipdb.php?appkey=jmn8dvncsb2batcyhs7pgiut&ip=${LBench_Result_LocalIP_IPV4}")"
        local IPAPI_Result_IPV6="$(curl -fsL6 --connect-timeout 5 https://api-ipv6.ip.sb/geoip)"
    # 返回未知值
    else
        LBench_Result_NetworkStat="unknown"
    fi
    # 提取IPV4信息
    if [ "${IPAPI_Result_IPV4}" != "" ]; then
        IPAPI_IPV4_IP="$(PharseJSON "${IPAPI_Result_IPV4}" "IP")"
        IPAPI_IPV4_Location="$(PharseJSON "${IPAPI_Result_IPV4}" "Location")"
        IPAPI_IPV4_ISP="$(PharseJSON "${IPAPI_Result_IPV4}" "ISP")"
        IPAPI_IPV4_ASN="$(PharseJSON "${IPAPI_Result_IPV4}" "ASN")"
        IPAPI_IPV4_Coordinate="$(PharseJSON "${IPAPI_Result_IPV4}" "Coordinate")"
    fi
    if [ "${IPAPI_Result_IPV6}" != "" ]; then
        IPAPI_IPV6_ip="$(PharseJSON "${IPAPI_Result_IPV6}" "ip")"
        IPAPI_IPV6_city="$(PharseJSON "${IPAPI_Result_IPV6}" "city")"
        IPAPI_IPV6_region="$(PharseJSON "${IPAPI_Result_IPV6}" "region")"
        IPAPI_IPV6_country="$(PharseJSON "${IPAPI_Result_IPV6}" "country")"
        IPAPI_IPV6_country_code="$(PharseJSON "${IPAPI_Result_IPV6}" "country_code")"
        IPAPI_IPV6_asn="$(PharseJSON "${IPAPI_Result_IPV6}" "asn")"
        IPAPI_IPV6_organization="$(PharseJSON "${IPAPI_Result_IPV6}" "organization")"
    fi
}

Function_GetSystemInfo() {
    clear
    echo -e "${Msg_Info}LemonBench Server Test Toolkit Build ${BuildTime}"
    echo -e "${Msg_Info}SystemInfo - 正在获取系统信息 ..."
    Check_Virtwhat
    echo -e "${Msg_Info}正在获取CPU信息 ..."
    SystemInfo_GetCPUInfo
    SystemInfo_GetLoadAverage
    SystemInfo_GetSystemBit
    SystemInfo_GetCPUStat
    echo -e "${Msg_Info}正在获取内存信息 ..."
    SystemInfo_GetMemInfo
    echo -e "${Msg_Info}正在获取虚拟化类型信息 ..."
    SystemInfo_GetVirtType
    echo -e "${Msg_Info}正在获取系统版本信息 ..."
    SystemInfo_GetOSRelease
    echo -e "${Msg_Info}正在获取磁盘信息 ..."
    SystemInfo_GetDiskStat
    echo -e "${Msg_Info}正在获取网络信息 ..."
    SystemInfo_GetNetworkInfo
    clear
}

Function_ShowSystemInfo() {
    echo -e "\n ${Font_Yellow}-> 系统信息${Font_Suffix}\n"
    if [ "${Var_OSReleaseVersion_Codename}" != "" ]; then
        echo -e " ${Font_Yellow}系统名称:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_OSReleaseFullName}${Font_Suffix}"
    else
        echo -e " ${Font_Yellow}系统名称:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_OSReleaseFullName}${Font_Suffix}"
    fi
    echo -e " ${Font_Yellow}CPU型号:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_CPUModelName}${Font_Suffix}"
    echo -e " ${Font_Yellow}CPU缓存大小:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_CPUCacheSize}${Font_Suffix}"
    # CPU数量 分支判断
    if [ "${LBench_Result_CPUIsPhysical}" = "1" ]; then
        # 如果只存在1个物理CPU (单路物理服务器)
        if [ "${LBench_Result_CPUPhysicalNumber}" -eq "1" ]; then
            echo -e " ${Font_Yellow}CPU数量:${Font_Suffix}\t\t${LBench_Result_CPUPhysicalNumber} ${Font_SkyBlue}物理CPU${Font_Suffix}, ${LBench_Result_CPUCoreNumber} ${Font_SkyBlue}核心${Font_Suffix}, ${LBench_Result_CPUThreadNumber} ${Font_SkyBlue}线程${Font_Suffix}"
        # 存在多个CPU, 继续深入分析检测 (多路物理服务器)
        else
            echo -e " ${Font_Yellow}CPU数量:${Font_Suffix}\t\t${LBench_Result_CPUPhysicalNumber} ${Font_SkyBlue}物理CPU${Font_Suffix}, ${LBench_Result_CPUCoreNumber} ${Font_SkyBlue}核心/CPU${Font_Suffix}, ${LBench_Result_CPUSiblingsNumber} ${Font_SkyBlue}线程/CPU${Font_Suffix} (总共 ${Font_SkyBlue}${LBench_Result_CPUTotalCoreNumber}${Font_Suffix} 核心, ${Font_SkyBlue}${LBench_Result_CPUProcessorNumber}${Font_Suffix} 线程)"
        fi
        if [ "${LBench_Result_CPUVirtualization}" = "1" ]; then
            echo -e " ${Font_Yellow}虚拟化已就绪:${Font_Suffix}\t\t${Font_SkyBlue}是${Font_Suffix} ${Font_SkyBlue}(基于${Font_Suffix} ${LBench_Result_CPUVirtualizationType}${Font_SkyBlue})${Font_Suffix}"
        else
            echo -e " ${Font_Yellow}虚拟化已就绪:${Font_Suffix}\t\t${Font_SkyRed}否${Font_Suffix}"
        fi
    elif [ "${Var_VirtType}" = "openvz" ]; then
        echo -e " ${Font_Yellow}CPU数量:${Font_Suffix}\t\t${LBench_Result_CPUThreadNumber} ${Font_SkyBlue}vCPU${Font_Suffix} (${LBench_Result_CPUCoreNumber} ${Font_SkyBlue}宿主机核心${Font_Suffix})"
    else
        echo -e " ${Font_Yellow}CPU数量:${Font_Suffix}\t\t${LBench_Result_CPUThreadNumber} ${Font_SkyBlue}vCPU${Font_Suffix}"
    fi
    echo -e " ${Font_Yellow}虚拟化类型:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_VirtType}${Font_Suffix}"
    # 内存使用率 分支判断
    if [ "${LBench_Result_MemoryUsed_KB}" -lt "1024" ] && [ "${LBench_Result_MemoryTotal_KB}" -lt "1048576" ]; then
        LBench_Result_Memory="${LBench_Result_MemoryUsed_KB} KB / ${LBench_Result_MemoryTotal_MB} MB"
        echo -e " ${Font_Yellow}内存使用率:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_MemoryUsed_MB} KB${Font_Suffix} / ${Font_SkyBlue}${LBench_Result_MemoryTotal_MB} MB${Font_Suffix}"
    elif [ "${LBench_Result_MemoryUsed_KB}" -lt "1048576" ] && [ "${LBench_Result_MemoryTotal_KB}" -lt "1048576" ]; then
        LBench_Result_Memory="${LBench_Result_MemoryUsed_MB} MB / ${LBench_Result_MemoryTotal_MB} MB"
        echo -e " ${Font_Yellow}内存使用率:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_MemoryUsed_MB} MB${Font_Suffix} / ${Font_SkyBlue}${LBench_Result_MemoryTotal_MB} MB${Font_Suffix}"
    elif [ "${LBench_Result_MemoryUsed_KB}" -lt "1048576" ] && [ "${LBench_Result_MemoryTotal_KB}" -lt "1073741824" ]; then
        LBench_Result_Memory="${LBench_Result_MemoryUsed_MB} MB / ${LBench_Result_MemoryTotal_GB} GB"
        echo -e " ${Font_Yellow}内存使用率:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_MemoryUsed_MB} MB${Font_Suffix} / ${Font_SkyBlue}${LBench_Result_MemoryTotal_GB} GB${Font_Suffix}"
    else
        LBench_Result_Memory="${LBench_Result_MemoryUsed_GB} GB / ${LBench_Result_MemoryTotal_GB} GB"
        echo -e " ${Font_Yellow}内存使用率:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_MemoryUsed_GB} GB${Font_Suffix} / ${Font_SkyBlue}${LBench_Result_MemoryTotal_GB} GB${Font_Suffix}"
    fi
    # Swap使用率 分支判断
    if [ "${LBench_Result_SwapTotal_KB}" -eq "0" ]; then
        LBench_Result_Swap="[无Swap分区/文件]"
        echo -e " ${Font_Yellow}Swap使用率:${Font_Suffix}\t\t${Font_SkyBlue}[无Swap分区/文件]${Font_Suffix}"
    elif [ "${LBench_Result_SwapUsed_KB}" -lt "1024" ] && [ "${LBench_Result_SwapTotal_KB}" -lt "1048576" ]; then
        LBench_Result_Swap="${LBench_Result_SwapUsed_KB} KB / ${LBench_Result_SwapTotal_MB} MB"
        echo -e " ${Font_Yellow}Swap使用率:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_SwapUsed_KB} KB${Font_Suffix} / ${Font_SkyBlue}${LBench_Result_SwapTotal_MB} MB${Font_Suffix}"
    elif [ "${LBench_Result_SwapUsed_KB}" -lt "1024" ] && [ "${LBench_Result_SwapTotal_KB}" -lt "1073741824" ]; then
        LBench_Result_Swap="${LBench_Result_SwapUsed_KB} KB / ${LBench_Result_SwapTotal_GB} GB"
        echo -e " ${Font_Yellow}Swap使用率:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_SwapUsed_KB} KB${Font_Suffix} / ${Font_SkyBlue}${LBench_Result_SwapTotal_GB} GB${Font_Suffix}"
    elif [ "${LBench_Result_SwapUsed_KB}" -lt "1048576" ] && [ "${LBench_Result_SwapTotal_KB}" -lt "1048576" ]; then
        LBench_Result_Swap="${LBench_Result_SwapUsed_MB} MB / ${LBench_Result_SwapTotal_MB} MB"
        echo -e " ${Font_Yellow}Swap使用率:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_SwapUsed_MB} MB${Font_Suffix} / ${Font_SkyBlue}${LBench_Result_SwapTotal_MB} MB${Font_Suffix}"
    elif [ "${LBench_Result_SwapUsed_KB}" -lt "1048576" ] && [ "${LBench_Result_SwapTotal_KB}" -lt "1073741824" ]; then
        LBench_Result_Swap="${LBench_Result_SwapUsed_MB} MB / ${LBench_Result_SwapTotal_GB} GB"
        echo -e " ${Font_Yellow}Swap使用率:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_SwapUsed_MB} MB${Font_Suffix} / ${Font_SkyBlue}${LBench_Result_SwapTotal_GB} GB${Font_Suffix}"
    else
        LBench_Result_Swap="${LBench_Result_SwapUsed_GB} GB / ${LBench_Result_SwapTotal_GB} GB"
        echo -e " ${Font_Yellow}Swap使用率:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_SwapUsed_GB} GB${Font_Suffix} / ${Font_SkyBlue}${LBench_Result_SwapTotal_GB} GB${Font_Suffix}"
    fi
    # 启动磁盘
    echo -e " ${Font_Yellow}引导设备:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_DiskRootPath}${Font_Suffix}"
    # 磁盘使用率 分支判断
    if [ "${LBench_Result_DiskUsed_KB}" -lt "1000000" ]; then
        LBench_Result_Disk="${LBench_Result_DiskUsed_MB} MB / ${LBench_Result_DiskTotal_MB} MB"
        echo -e " ${Font_Yellow}磁盘使用率:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_DiskUsed_MB} MB${Font_Suffix} / ${Font_SkyBlue}${LBench_Result_DiskTotal_MB} MB${Font_Suffix}"
    elif [ "${LBench_Result_DiskUsed_KB}" -lt "1000000" ] && [ "${LBench_Result_DiskTotal_KB}" -lt "1000000000" ]; then
        LBench_Result_Disk="${LBench_Result_DiskUsed_MB} MB / ${LBench_Result_DiskTotal_GB} GB"
        echo -e " ${Font_Yellow}磁盘使用率:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_DiskUsed_MB} MB${Font_Suffix} / ${Font_SkyBlue}${LBench_Result_DiskTotal_GB} GB${Font_Suffix}"
    elif [ "${LBench_Result_DiskUsed_KB}" -lt "1000000000" ] && [ "${LBench_Result_DiskTotal_KB}" -lt "1000000000" ]; then
        LBench_Result_Disk="${LBench_Result_DiskUsed_GB} GB / ${LBench_Result_DiskTotal_GB} GB"
        echo -e " ${Font_Yellow}磁盘使用率:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_DiskUsed_GB} GB${Font_Suffix} / ${Font_SkyBlue}${LBench_Result_DiskTotal_GB} GB${Font_Suffix}"
    elif [ "${LBench_Result_DiskUsed_KB}" -lt "1000000000" ] && [ "${LBench_Result_DiskTotal_KB}" -ge "1000000000" ]; then
        LBench_Result_Disk="${LBench_Result_DiskUsed_GB} GB / ${LBench_Result_DiskTotal_TB} TB"
        echo -e " ${Font_Yellow}磁盘使用率:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_DiskUsed_GB} GB${Font_Suffix} / ${Font_SkyBlue}${LBench_Result_DiskTotal_TB} TB${Font_Suffix}"
    else
        LBench_Result_Disk="${LBench_Result_DiskUsed_TB} TB / ${LBench_Result_DiskTotal_TB} TB"
        echo -e " ${Font_Yellow}磁盘使用率:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_DiskUsed_TB} TB${Font_Suffix} / ${Font_SkyBlue}${LBench_Result_DiskTotal_TB} TB${Font_Suffix}"
    fi
    # CPU状态
    echo -e " ${Font_Yellow}CPU负载:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_CPUStat_UsedAll}% used${Font_Suffix}, ${Font_SkyBlue}${LBench_Result_CPUStat_iowait}% iowait${Font_Suffix}, ${Font_SkyBlue}${LBench_Result_CPUStat_steal}% steal${Font_Suffix}"
    # 系统负载
    echo -e " ${Font_Yellow}系统负载(1/5/15min):${Font_Suffix}\t${Font_SkyBlue}${LBench_Result_LoadAverage_1min} ${LBench_Result_LoadAverage_5min} ${LBench_Result_LoadAverage_15min} ${Font_Suffix}"
    # CPU Steal
    echo -e " ${Font_Yellow}CPU ST (仅供参考):${Font_Suffix}\t${Font_SkyBlue}${LBench_Result_CPUStat_steal}%${Font_Suffix}"
    # 执行完成, 标记FLAG
    LBench_Flag_FinishSystemInfo="1"
}

Function_ShowNetworkInfo() {
    echo -e "\n ${Font_Yellow}-> 网络信息${Font_Suffix}\n"
    if [ "${LBench_Result_NetworkStat}" = "ipv4only" ] || [ "${LBench_Result_NetworkStat}" = "dualstack" ]; then
        echo -e " ${Font_Yellow}IPV4 - 本机IP:${Font_Suffix}\t\t${Font_SkyBlue}${IPAPI_IPV4_IP}${Font_Suffix}"
        echo -e " ${Font_Yellow}IPV4 - ASN信息:${Font_Suffix}\t${Font_SkyBlue}${IPAPI_IPV4_ASN} ( ${IPAPI_IPV4_Location})${Font_Suffix}"
        echo -e " ${Font_Yellow}IPV4 - 运营商:${Font_Suffix}\t\t${Font_SkyBlue}${IPAPI_IPV4_ISP}${Font_Suffix}"
    fi
    if [ "${LBench_Result_NetworkStat}" = "ipv6only" ] || [ "${LBench_Result_NetworkStat}" = "dualstack" ]; then
        echo -e " ${Font_Yellow}IPV6 - 本机IP:${Font_Suffix}\t\t${Font_SkyBlue}[${IPAPI_IPV6_country_code}] ${IPAPI_IPV6_ip}${Font_Suffix}"
        echo -e " ${Font_Yellow}IPV6 - ASN信息:${Font_Suffix}\t${Font_SkyBlue}AS${IPAPI_IPV6_asn} (${IPAPI_IPV6_organization})${Font_Suffix}"
        echo -e " ${Font_Yellow}IPV6 - 归属地:${Font_Suffix}\t\t${Font_SkyBlue}${IPAPI_IPV6_country}, ${IPAPI_IPV6_region}${Font_Suffix}"
    fi
    # 执行完成, 标记FLAG
    LBench_Flag_FinishNetworkInfo="1"
}

# =============== 测试启动与结束动作 ===============
Function_BenchStart() {
    clear
    LBench_Result_BenchStartTime="$(date +"%Y-%m-%d %H:%M:%S")"
    echo -e "${Font_SkyBlue}LemonBench${Font_Suffix} ${Font_Yellow}Server Test Tookit${Font_Suffix} ${BuildTime} ${Font_SkyBlue}(C)iLemonrain. All Rights Reserved.${Font_Suffix}"
    echo -e "=========================================================================================="
    echo -e " "
    echo -e " ${Msg_Info}${Font_Yellow}测试开始时间：${Font_Suffix} ${Font_SkyBlue}${LBench_Result_BenchStartTime}${Font_Suffix}"
    echo -e " ${Msg_Info}${Font_Yellow}测试模式：${Font_Suffix} ${Font_SkyBlue}${Global_TestModeTips}${Font_Suffix}"
    echo -e " "
}

Function_BenchFinish() {
    # 清理临时文件
    LBench_Result_BenchFinishTime="$(date +"%Y-%m-%d %H:%M:%S")"
    echo -e ""
    echo -e "=========================================================================================="
    echo -e " "
    echo -e " ${Msg_Info}${Font_Yellow}测试结束时间：${Font_Suffix} ${Font_SkyBlue}${LBench_Result_BenchFinishTime}${Font_Suffix}"
    echo -e " "
}

#  =============== 流媒体解锁测试 部分 ===============

# 流媒体解锁测试
Function_MediaUnlockTest() {
    echo -e " "
    echo -e "${Font_Yellow} -> 流媒体解锁测试 ${Font_Suffix}"
    echo -e " "
    Function_MediaUnlockTest_HBONow
    Function_MediaUnlockTest_BahamutAnime
    # Function_MediaUnlockTest_AbemaTV_IPTest
    Function_MediaUnlockTest_BilibiliHKMCTW
    Function_MediaUnlockTest_BilibiliTW
    LBench_Flag_FinishMediaUnlockTest="1"
}

# 流媒体解锁测试-HBO Now
Function_MediaUnlockTest_HBONow() {
    echo -n -e " HBONow:\c"
    # 尝试获取成功的结果
    local result="$(curl --user-agent "${UA_Browser}" -4 -fsL --max-time 30 --write-out "%{url_effective}\n" --output /dev/null https://play.hbonow.com/)"
    if [ "$?" = "0" ]; then
        # 下载页面成功，开始解析跳转
        if [ "${result}" = "https://play.hbonow.com" ] || [ "${result}" = "https://play.hbonow.com/" ]; then
            echo -n -e "\r HBO Now:\t\t${Font_Green}是${Font_Suffix}\n"
            LemonBench_Result_MediaUnlockTest_HBONow="是"
        elif [ "${result}" = "http://hbogeo.cust.footprint.net/hbonow/geo.html" ] || [ "${result}" = "http://geocust.hbonow.com/hbonow/geo.html" ]; then
            echo -n -e "\r HBO Now:\t\t${Font_Red}否${Font_Suffix}\n"
            LemonBench_Result_MediaUnlockTest_HBONow="否"
        else
            echo -n -e "\r HBO Now:\t${Font_Yellow}失败-解析失败${Font_Suffix}\n"
            LemonBench_Result_MediaUnlockTest_HBONow="测试失败 (解析失败)"
        fi
    else
        # 下载页面失败，返回错误代码
        echo -e "\r HBO Now:\t\t${Font_Yellow}失败-网络连接异常${Font_Suffix}\n"
        LemonBench_Result_MediaUnlockTest_HBONow="测试失败 (网络连接异常)"
    fi
}

# 流媒体解锁测试-动画疯
Function_MediaUnlockTest_BahamutAnime() {
    echo -n -e " 巴哈姆特動畫瘋:\c"
    # 尝试获取成功的结果
    local result="$(curl -4 --user-agent "${UA_Browser}" --output /dev/null --write-out "%{url_effective}" --max-time 30 -fsL https://ani.gamer.com.tw/animePay.php)"
    if [ "$?" = "0" ]; then
        if [ "${result}" = "https://user.gamer.com.tw/login.php" ]; then
            echo -n -e "\r 巴哈姆特動畫瘋:\t${Font_Green}是${Font_Suffix}\n"
            LemonBench_Result_MediaUnlockTest_BahamutAnime="是"
        elif [ "${result}" = "https://ani.gamer.com.tw/animePay.php" ]; then
            echo -n -e "\r 巴哈姆特動畫瘋:\t${Font_Red}否${Font_Suffix}\n"
            LemonBench_Result_MediaUnlockTest_BahamutAnime="否"
        else
            echo -n -e "\r 巴哈姆特動畫瘋:\t${Font_Yellow}失败-解析失败${Font_Suffix}\n"
            LemonBench_Result_MediaUnlockTest_BahamutAnime="测试失败 (解析失败)"
        fi
    else
        echo -e "\r 巴哈姆特動畫瘋:\t${Font_Yellow}失败-网络连接异常${Font_Suffix}\n"
        LemonBench_Result_MediaUnlockTest_BahamutAnime="测试失败 (网络连接异常)"
    fi
}

# 流媒体解锁测试-哔哩哔哩港澳台限定
Function_MediaUnlockTest_BilibiliHKMCTW() {
    echo -n -e " 哔哩哔哩-港澳台限定:\c"
    local randsession="$(cat /dev/urandom | head -n 32 | md5sum | head -c 32)"
    # 尝试获取成功的结果
    local result="$(curl --user-agent "${UA_Browser}" -4 -fsL --max-time 30 "https://api.bilibili.com/pgc/player/web/playurl?avid=18281381&cid=29892777&qn=0&type=&otype=json&ep_id=183799&fourk=1&fnver=0&fnval=16&session=${randsession}&module=bangumi")"
    if [ "$?" = "0" ]; then
        local result="$(PharseJSON "${result}" "code")"
        if [ "$?" = "0" ]; then
            if [ "${result}" = "0" ]; then
                echo -n -e "\r 哔哩哔哩-港澳台限定:\t${Font_Green}是${Font_Suffix}\n"
                LemonBench_Result_MediaUnlockTest_BilibiliHKMCTW="是"
            elif [ "${result}" = "-10403" ]; then
                echo -n -e "\r 哔哩哔哩-港澳台限定:\t${Font_Red}否${Font_Suffix}\n"
                LemonBench_Result_MediaUnlockTest_BilibiliHKMCTW="否"
            else
                echo -n -e "\r 哔哩哔哩-港澳台限定:\t${Font_Red}失败-返回值异常${Font_Suffix} ${Font_SkyBlue}(${result})${Font_Suffix}\n"
                LemonBench_Result_MediaUnlockTest_BilibiliHKMCTW="测试失败 (返回值异常)" 
            fi
        else
            echo -n -e "\r 哔哩哔哩-港澳台限定:\t${Font_Red}失败-解析失败${Font_Suffix}\n"
            LemonBench_Result_MediaUnlockTest_BilibiliHKMCTW="测试失败 (解析失败)"
        fi
    else
        echo -n -e "\r 哔哩哔哩-港澳台限定:\t${Font_Red}失败-网络连接异常${Font_Suffix}\n"
        LemonBench_Result_MediaUnlockTest_BilibiliHKMCTW="测试失败 (网络连接异常)"        
    fi   
}

# 流媒体解锁测试-哔哩哔哩台湾限定
Function_MediaUnlockTest_BilibiliTW() {
    echo -n -e " 哔哩哔哩-台湾限定:\c"
    local randsession="$(cat /dev/urandom | head -n 32 | md5sum | head -c 32)"
    # 尝试获取成功的结果
    local result="$(curl --user-agent "${UA_Browser}" -4 -fsL --max-time 30 "https://api.bilibili.com/pgc/player/web/playurl?avid=50762638&cid=100279344&qn=0&type=&otype=json&ep_id=268176&fourk=1&fnver=0&fnval=16&session=${randsession}&module=bangumi")"
    if [ "$?" = "0" ]; then
        local result="$(PharseJSON "${result}" "code")"
        if [ "$?" = "0" ]; then
            if [ "${result}" = "0" ]; then
                echo -n -e "\r 哔哩哔哩-台湾限定:\t${Font_Green}是${Font_Suffix}\n"
                LemonBench_Result_MediaUnlockTest_BilibiliTW="是"
            elif [ "${result}" = "-10403" ]; then
                echo -n -e "\r 哔哩哔哩-台湾限定:\t${Font_Red}否${Font_Suffix}\n"
                LemonBench_Result_MediaUnlockTest_BilibiliTW="否"
            else
                echo -n -e "\r 哔哩哔哩-台湾限定:\t${Font_Red}失败-返回值异常${Font_Suffix} ${Font_SkyBlue}(${result})${Font_Suffix}\n"
                LemonBench_Result_MediaUnlockTest_BilibiliTW="测试失败 (返回值异常)" 
            fi
        else
            echo -n -e "\r 哔哩哔哩-台湾限定:\t${Font_Red}失败-解析失败${Font_Suffix}\n"
            LemonBench_Result_MediaUnlockTest_BilibiliTW="测试失败 (解析失败)"
        fi
    else
        echo -n -e "\r 哔哩哔哩-台湾限定:\t${Font_Red}失败-网络连接异常${Font_Suffix}\n"
        LemonBench_Result_MediaUnlockTest_BilibiliTW="测试失败 (网络连接异常)"        
    fi   
}

# 流媒体解锁测试-Abema.TV
#
# 免责声明：此项测试仅测试IP是否可以观看，并不测试是否有地域限制 (也就是Sorry页面) ！
#
Function_MediaUnlockTest_AbemaTV_IPTest() {
    echo -n -e " Abema.TV (IP Test):\c"
    # 尝试获取成功的结果
    local result="$(curl --user-agent "${UA_Browser}" -4 -fsL --write-out %{http_code} --output /dev/null http://abematv.akamaized.net/region)"
    if [ "$?" = "0" ]; then
        if [ "${result}" = "200" ]; then
            echo -n -e "\r Abema.TV (IP Test):\t${Font_Green}是${Font_Suffix}\n"
            LemonBench_Result_MediaUnlockTest_AbemaTV_IPTest="是"
        elif [ "${result}" = "403" ]; then
            echo -n -e "\r Abema.TV (IP Test):\t${Font_Red}否${Font_Suffix}\n"
            LemonBench_Result_MediaUnlockTest_AbemaTV_IPTest="否"
        elif [ "${result}" = "404" ]; then
            echo -n -e "\r Abema.TV (IP Test):\t${Font_Red}失败-HTTP 404${Font_Suffix}\n"
            LemonBench_Result_MediaUnlockTest_AbemaTV_IPTest="测试失败 (HTTP 404)"
        else
            echo -n -e "\r Abema.TV (IP Test):\t${Font_Red}失败-返回值异常${Font_Suffix} ${Font_SkyBlue}(${result})${Font_Suffix}\n"
            LemonBench_Result_MediaUnlockTest_AbemaTV_IPTest="测试失败 (返回值异常)" 
        fi
    else
        echo -n -e "\r Abema.TV (IP Test):\t${Font_Red}失败-网络连接异常${Font_Suffix}\n"
        LemonBench_Result_MediaUnlockTest_AbemaTV_IPTest"测试失败 (网络连接异常)"        
    fi   
}

# =============== Speedtest 部分 ===============
Run_Speedtest() {
    # 调用方式: Run_Speedtest "服务器ID" "节点名称(用于显示)"
    isFailed="0"
    mkdir -p ${WorkDir}/Speedtest/ >/dev/null 2>&1
    if [ -f "/usr/sbin/speedtest-cli" ]; then
        Speedtest_Exec="speedtest-cli"
    else
        Speedtest_Exec="speedtest"
    fi
    if [ "${LBench_Flag_Speedtest_DisablePreAllocate}" = "1" ]; then
        Speedtest_Exec="${Speedtest_Exec} --no-pre-allocate "
    fi
    echo -n -e " $2\c"
    Speedtest_Result_Ping=""
    Speedtest_Result_Download=""
    Speedtest_Result_Upload=""
    if [ "$1" = "default" ]; then
        local Speedtest_Result="$(${Speedtest_Exec} --simple --bytes 2>&1)"
        if [ "$?" != "0" ]; then
            local Speedtest_Result="Fail"
        fi
    else
        local Speedtest_Result="$(${Speedtest_Exec} --server $1 --simple --bytes 2>&1)"
        if [ "$?" != "0" ]; then
            local Speedtest_Result="Fail"
        fi
    fi
    echo "${Speedtest_Result}" | grep "No|retrieve|urlopen|usage|Fail" >/dev/null 2>&1
    if [ "$?" != "0" ]; then
        Speedtest_Result_Ping="$(echo "${Speedtest_Result}" | awk '(NR==1){print $2}')"
        Speedtest_Result_Download="$(echo "${Speedtest_Result}" | awk '(NR==2){print $2}')"
        Speedtest_Result_Upload="$(echo "${Speedtest_Result}" | awk '(NR==3){print $2}')"
        echo -n -e "\r $2\t\t${Font_SkyBlue}${Speedtest_Result_Upload}${Font_Suffix} MB/s\t${Font_SkyBlue}${Speedtest_Result_Download}${Font_Suffix} MB/s\t${Font_SkyBlue}${Speedtest_Result_Ping}${Font_Suffix} ms\n"
        echo -e " $2\t\t${Speedtest_Result_Upload} MB/s\t${Speedtest_Result_Download} MB/s\t${Speedtest_Result_Ping} ms" >>${WorkDir}/Speedtest/result.txt
    else
        echo -n -e "\r $2\t\t${Font_Red}Fail: $(echo ${Speedtest_Result} | sed -n '1p')${Font_Suffix}\n"
        echo -e " $2\t\tFail\n" >>${WorkDir}/Speedtest/result.txt
    fi
}

Run_Speedtest_DetectLowMemory() {
    SystemInfo_GetMemInfo
    local PhyMemFree_MB="$(echo ${LBench_Result_MemoryFree_MB} | awk '{printf "%d\n", $1}')"
    local SwapMemFree_MB="$(echo ${LBench_Result_SwapFree_MB} | awk '{printf "%d\n", $1}')"
    if [ "${PhyMemFree_MB}" -le "128" ] && [ "${SwapMemFree_MB}" -eq "0" ]; then
        echo -e "${Msg_Warning}系统当前可用内存过小 (物理内存可用：${LBench_Result_MemoryFree_MB} MB, 无Swap内存), 可能会导致测试出现MemoryError异常！"
        echo -e "${Msg_Warning}已禁用Speedtest模块的预生成数据功能, 上传测试结果准确度可能会降低！"
        echo -e "\n"
        LBench_Flag_Speedtest_DisablePreAllocate="1"
    elif [ "${PhyMemFree_MB}" -ge "128" ] && [ "${SwapMemFree_MB}" -gt "0" ]; then
        local TotalAvaPhySwpMem_MB="$(echo ${LBench_Result_MemoryFree_MB} ${LBench_Result_SwapFree_MB} | awk '{print $1+$2}' | awk '{printf "%d", $1}')"
        if [ "${TotalAvaPhySwpMem_MB}" -le "300" ]; then
            echo -e "${Msg_Warning}系统当前可用物理内存+Swap内存过小 (物理内存可用：${LBench_Result_MemoryFree_MB} MB, 无Swap内存)！"
            echo -e "${Msg_Warning}已禁用Speedtest模块的预生成数据功能, 上传测试结果准确度可能会降低！"
            echo -e "\n"
            LBench_Flag_Speedtest_DisablePreAllocate="1"
        fi
    fi
}

Function_Speedtest_Fast() {
    mkdir -p ${WorkDir}/Speedtest/ >/dev/null 2>&1
    echo -e "\n ${Font_Yellow}-> Speedtest.net 网速测试${Font_Suffix}\n"
    echo -e "\n -> Speedtest.net 网速测试\n" >>${WorkDir}/Speedtest/result.txt
    Check_Speedtest
    Run_Speedtest_DetectLowMemory
    echo -e " ${Font_Yellow}节点名称\t\t上传速度\t下载速度\tPing延迟${Font_Suffix}"
    echo -e " 节点名称\t\t上传速度\t下载速度\tPing延迟" >>${WorkDir}/Speedtest/result.txt
    # 默认测试
    Run_Speedtest "default" "距离最近测速点"
    # 快速测试
    Run_Speedtest "9484" "东北-吉林联通"
    Run_Speedtest "25637" "华东-上海移动"
    Run_Speedtest "17251" "华南-广州电信"
    # 执行完成, 标记FLAG
    LBench_Flag_FinishSpeedtestFast="1"
}

Function_Speedtest_Full() {
    mkdir -p ${WorkDir}/Speedtest/ >/dev/null 2>&1
    echo -e "\n ${Font_Yellow}-> Speedtest.net 网速测试${Font_Suffix}\n"
    echo -e "\n-> Speedtest.net 网速测试\n" >>${WorkDir}/Speedtest/result.txt
    Check_Speedtest
    Run_Speedtest_DetectLowMemory
    echo -e " ${Font_Yellow}节点名称\t\t上传速度\t下载速度\tPing延迟${Font_Suffix}"
    echo -e " 节点名称\t\t上传速度\t下载速度\tPing延迟" >>${WorkDir}/Speedtest/result.txt
    # 默认测试
    Run_Speedtest "default" "距离最近测速点"
    # 国内测试
    Run_Speedtest "9484" "东北-吉林联通"
    Run_Speedtest "16167" "东北-沈阳移动"
    Run_Speedtest "17184" "华北-山东联通"
    Run_Speedtest "13704" "华中-南京联通"
    Run_Speedtest "7509" "华中-杭州电信"
    Run_Speedtest "4647" "华中-杭州移动"
    Run_Speedtest "24447" "华东-上海联通"
    Run_Speedtest "25637" "华东-上海移动"
    Run_Speedtest "17251" "华南-广州电信"
    Run_Speedtest "5726" "西南-重庆联通"
    Run_Speedtest "15863" "西南-南宁移动"
    Run_Speedtest "4690" "西北-兰州联通"
    Run_Speedtest "3973" "西北-兰州电信"
    Run_Speedtest "16145" "西北-兰州移动"
    # 执行完成, 标记FLAG
    LBench_Flag_FinishSpeedtestFull="1"
}

# =============== 磁盘测试 部分 ===============
Run_DiskTest_DD() {
    # 调用方式: Run_DiskTest_DD "测试文件名" "块大小" "写入次数" "测试项目名称"
    mkdir -p ${WorkDir}/DiskTest/ >/dev/null 2>&1
    SystemInfo_GetVirtType
    mkdir -p /.tmp_LBench/DiskTest >/dev/null 2>&1
    mkdir -p ${WorkDir}/data >/dev/null 2>&1
    local Var_DiskTestResultFile="${WorkDir}/data/disktest_result"
    # 将先测试读, 后测试写
    echo -n -e " $4\c"
    # 清理缓存, 避免影响测试结果
    sync
    if [ "${Var_VirtType}" != "docker" ] && [ "${Var_VirtType}" != "openvz" ] && [ "${Var_VirtType}" != "lxc" ] && [ "${Var_VirtType}" != "wsl" ]; then
        echo 3 >/proc/sys/vm/drop_caches
    fi
    # 避免磁盘压力过高, 启动测试前暂停1秒
    sleep 1
    # 正式写测试
    dd if=/dev/zero of=/.tmp_LBench/DiskTest/$1 bs=$2 count=$3 oflag=direct 2>${Var_DiskTestResultFile}
    local DiskTest_WriteSpeed_ResultRAW="$(cat ${Var_DiskTestResultFile} | grep -oE "[0-9]{1,}.[0-9]{1,} MB\/s|[0-9]{1,}.[0-9]{1,} MB\/秒|[0-9]{1,} MB\/s|[0-9]{1,} MB\/秒|[0-9]{1,}.[0-9]{1,} GB\/s|[0-9]{1,} MB\/s|[0-9]{1,} MB\/秒|[0-9]{1,}.[0-9]{1,} GB\/秒")"
    DiskTest_WriteSpeed="$(echo "${DiskTest_WriteSpeed_ResultRAW}" | sed "s/秒/s/")"
    local DiskTest_WriteTime_ResultRAW="$(cat ${Var_DiskTestResultFile} | grep -oE "[0-9]{1,}.[0-9]{1,} s|[0-9]{1,}.[0-9]{1,} 秒")"
    DiskTest_WriteTime="$(echo ${DiskTest_WriteTime_ResultRAW} | awk '{print $1}')"
    DiskTest_WriteIOPS="$(echo ${DiskTest_WriteTime} $3 | awk '{printf "%d\n",$2/$1}')"
    DiskTest_WritePastTime="$(echo ${DiskTest_WriteTime} | awk '{printf "%.2f\n",$1}')"
    echo -n -e "\r $4\t\t${Font_SkyBlue}${DiskTest_WriteSpeed} (${DiskTest_WriteIOPS} IOPS, ${DiskTest_WritePastTime}s)${Font_Suffix}\t\t\c"
    # 清理结果文件, 准备下一次测试
    rm -f ${Var_DiskTestResultFile}
    # 清理缓存, 避免影响测试结果
    sync
    if [ "${Var_VirtType}" != "docker" ] && [ "${Var_VirtType}" != "wsl" ]; then
        echo 3 >/proc/sys/vm/drop_caches
    fi
    sleep 0.5
    # 正式读测试
    dd if=/.tmp_LBench/DiskTest/$1 of=/dev/null bs=$2 count=$3 iflag=direct 2>${Var_DiskTestResultFile}
    local DiskTest_ReadSpeed_ResultRAW="$(cat ${Var_DiskTestResultFile} | grep -oE "[0-9]{1,}.[0-9]{1,} MB\/s|[0-9]{1,}.[0-9]{1,} MB\/秒|[0-9]{1,} MB\/s|[0-9]{1,} MB\/秒|[0-9]{1,}.[0-9]{1,} GB\/s|[0-9]{1,} MB\/s|[0-9]{1,} MB\/秒|[0-9]{1,}.[0-9]{1,} GB\/秒")"
    DiskTest_ReadSpeed="$(echo "${DiskTest_ReadSpeed_ResultRAW}" | sed "s/秒/s/")"
    local DiskTest_ReadTime_ResultRAW="$(cat ${Var_DiskTestResultFile} | grep -oE "[0-9]{1,}.[0-9]{1,} s|[0-9]{1,}.[0-9]{1,} 秒")"
    DiskTest_ReadTime="$(echo ${DiskTest_ReadTime_ResultRAW} | awk '{print $1}')"
    DiskTest_ReadIOPS="$(echo ${DiskTest_ReadTime} $3 | awk '{printf "%d\n",$2/$1}')"
    DiskTest_ReadPastTime="$(echo ${DiskTest_ReadTime} | awk '{printf "%.2f\n",$1}')"
    rm -f ${Var_DiskTestResultFile}
    # 输出结果
    echo -n -e "\r $4\t\t${Font_SkyBlue}${DiskTest_WriteSpeed} (${DiskTest_WriteIOPS} IOPS, ${DiskTest_WritePastTime}s)${Font_Suffix}\t\t${Font_SkyBlue}${DiskTest_ReadSpeed} (${DiskTest_ReadIOPS} IOPS, ${DiskTest_ReadPastTime}s)${Font_Suffix}\n"
    echo -e " $4\t\t${DiskTest_WriteSpeed} (${DiskTest_WriteIOPS} IOPS, ${DiskTest_WritePastTime} 秒)\t\t${DiskTest_ReadSpeed} (${DiskTest_ReadIOPS} IOPS, ${DiskTest_ReadPastTime} 秒)" >>${WorkDir}/DiskTest/result.txt
    rm -rf /.tmp_LBench/DiskTest/
}

Function_DiskTest_Fast() {
    mkdir -p ${WorkDir}/DiskTest/ >/dev/null 2>&1
    echo -e "\n ${Font_Yellow}-> 磁盘性能测试 (4K块/1M块, Direct写入)${Font_Suffix}\n"
    echo -e "\n -> 磁盘性能测试 (4K块/1M块, Direct写入)\n" >>${WorkDir}/DiskTest/result.txt
    SystemInfo_GetVirtType
    SystemInfo_GetOSRelease
    if [ "${Var_VirtType}" = "docker" ] || [ "${Var_VirtType}" = "wsl" ]; then
        echo -e " ${Msg_Warning}由于系统架构限制, 磁盘测试结果可能会受到缓存影响, 仅供参考！\n"
    fi
    echo -e " ${Font_Yellow}测试项目\t\t写入速度\t\t\t\t读取速度${Font_Suffix}"
    echo -e " 测试项目\t\t写入速度\t\t\t\t读取速度" >>${WorkDir}/DiskTest/result.txt
    Run_DiskTest_DD "100MB.test" "4k" "25600" "100MB-4K块"
    Run_DiskTest_DD "1000MB.test" "1M" "1000" "1000MB-1M块"
    # 执行完成, 标记FLAG
    LBench_Flag_FinishDiskTestFast="1"
}

Function_DiskTest_Full() {
    mkdir -p ${WorkDir}/DiskTest/ >/dev/null 2>&1
    echo -e "\n ${Font_Yellow}-> 磁盘性能测试 (4K块/1M块, Direct写入)${Font_Suffix}\n"
    echo -e "\n -> 磁盘性能测试 (4K块/1M块, Direct写入)\n" >>${WorkDir}/DiskTest/result.txt
    SystemInfo_GetVirtType
    SystemInfo_GetOSRelease
    if [ "${Var_VirtType}" = "docker" ] || [ "${Var_VirtType}" = "wsl" ]; then
        echo -e " ${Msg_Warning}由于系统架构限制, 磁盘测试结果可能会受到缓存影响, 仅供参考！\n"
    fi
    echo -e " ${Font_Yellow}测试项目\t\t写入速度\t\t\t\t读取速度${Font_Suffix}"
    echo -e " 测试项目\t\t写入速度\t\t\t\t读取速度" >>${WorkDir}/DiskTest/result.txt
    Run_DiskTest_DD "10MB.test" "4k" "2560" "10MB-4K块"
    Run_DiskTest_DD "10MB.test" "1M" "10" "10MB-1M块"
    Run_DiskTest_DD "100MB.test" "4k" "25600" "100MB-4K块"
    Run_DiskTest_DD "100MB.test" "1M" "100" "100MB-1M块"
    Run_DiskTest_DD "1000MB.test" "4k" "256000" "1000MB-4K块"
    Run_DiskTest_DD "1000MB.test" "1M" "1000" "1000MB-1M块"
    # 执行完成, 标记FLAG
    LBench_Flag_FinishDiskTestFull="1"
}

# =============== BestTrace 部分 ===============
Run_BestTrace() {
    mkdir -p ${WorkDir}/BestTrace/ >/dev/null 2>&1
    # 调用方式: Run_BestTrace "目标IP" "ICMP/TCP" "最大跃点数" "说明"
    if [ "$2" = "tcp" ] || [ "$2" = "TCP" ]; then
        echo -e "路由追踪到 $4 (TCP 模式, 最大 $3 跃点)"
        echo -e "============================================================"
        echo -e "\n路由追踪到 $4 (TCP 模式, 最大 $3 跃点)" >>${WorkDir}/BestTrace/result.txt
        echo -e "============================================================" >>${WorkDir}/BestTrace/result.txt
        besttrace -g cn -q 1 -n -T -m $3 $1 | tee -a ${WorkDir}/BestTrace/result.txt
    else
        echo -e "路由追踪到 $4 (ICMP 模式, 最大 $3 跃点)"
        echo -e "============================================================"
        echo -e "\n路由追踪到 $4 (ICMP 模式, 最大 $3 跃点)" >>${WorkDir}/BestTrace/result.txt
        echo -e "============================================================" >>${WorkDir}/BestTrace/result.txt
        besttrace -g cn -q 1 -n -m $3 $1 | tee -a ${WorkDir}/BestTrace/result.txt
    fi
}

Run_BestTrace6() {
    # 调用方式: Run_BestTrace "目标IP" "ICMP/TCP" "最大跃点数" "说明"
    if [ "$2" = "tcp" ] || [ "$2" = "TCP" ]; then
        echo -e "路由追踪到 $4 (TCP 模式, 最大 $3 跃点)"
        echo -e "============================================================"
        echo -e "\n路由追踪到 $4 (TCP 模式, 最大 $3 跃点)" >>${WorkDir}/BestTrace/result.txt
        echo -e "============================================================" >>${WorkDir}/BestTrace/result.txt
        besttrace -g cn -6 -q 1 -n -T -m $3 $1 >>${WorkDir}/BestTrace/result.txt
    else
        echo -e "路由追踪到 $4 (ICMP 模式, 最大 $3 跃点)"
        echo -e "============================================================"
        echo -e "路由追踪到 $4 (ICMP 模式, 最大 $3 跃点)" >>${WorkDir}/BestTrace/result.txt
        echo -e "============================================================" >>${WorkDir}/BestTrace/result.txt
        besttrace -g cn -6 -q 1 -n -m $3 $1 | tee -a ${WorkDir}/BestTrace/result.txt
    fi
}

Function_BestTrace_Fast() {
    Check_BestTrace
    mkdir -p ${WorkDir}/BestTrace/ >/dev/null 2>&1
    if [ "${LBench_Result_NetworkStat}" = "ipv4only" ] || [ "${LBench_Result_NetworkStat}" = "dualstack" ]; then
        echo -e "\n ${Font_Yellow}-> 路由追踪测试 (IPV4)${Font_Suffix}\n"
        echo -e "\n -> 路由追踪测试 (IPV4)\n" >>${WorkDir}/BestTrace/result.txt
        # 新版节点列表 Ver 20190817
        # 国内部分
        Run_BestTrace "123.125.99.1" "TCP" "30" "北京联通"
        Run_BestTrace "180.149.128.1" "TCP" "30" "北京电信"
        Run_BestTrace "211.136.88.117" "TCP" "30" "北京移动"
        Run_BestTrace "58.247.0.49" "TCP" "30" "上海联通"
        Run_BestTrace "180.153.28.1" "TCP" "30" "上海电信"
        Run_BestTrace "221.183.55.22" "TCP" "30" "上海移动"
        Run_BestTrace "210.21.4.130" "TCP" "30" "广州联通"
        Run_BestTrace "121.14.50.65" "TCP" "30" "广州电信"
        Run_BestTrace "211.139.129.5" "TCP" "30" "广州移动"
        Run_BestTrace "210.13.66.238" "TCP" "30" "上海联通精品网"
        Run_BestTrace "58.32.0.1" "TCP" "30" "上海电信CN2"
        Run_BestTrace "211.167.230.100" "TCP" "30" "北京鹏博士/电信通"
        Run_BestTrace "202.205.109.205" "TCP" "30" "北京教育网"
        Run_BestTrace "159.226.254.1" "TCP" "30" "北京科技网"
        Run_BestTrace "211.156.140.17" "TCP" "30" "北京广电网"
    fi
    if [ "${LBench_Result_NetworkStat}" = "ipv6only" ] || [ "${LBench_Result_NetworkStat}" = "dualstack" ]; then
        echo -e "\n ${Font_Yellow}-> 路由追踪测试 (IPV6)${Font_Suffix}\n"
        echo -e "\n -> 路由追踪测试 (IPV6)\n" >>${WorkDir}/BestTrace/result.txt
        Run_BestTrace6 "2408:80f0:4100:2005::3" "ICMP" "30" "北京联通-IPV6"
        Run_BestTrace6 "240e:0:a::c9:1cb4" "ICMP" "30" "北京电信-IPV6"
        Run_BestTrace6 "2409:8080:0:2:103:1b1:0:1" "ICMP" "30" "北京移动-IPV6"
        Run_BestTrace6 "2001:da8:a0:1001::1" "ICMP" "30" "北京教育网CERNET2-IPV6"
    fi
    # 执行完成, 标记FLAG
    LBench_Flag_FinishBestTraceFast="1"
}

Function_BestTrace_Full() {
    Check_BestTrace
    mkdir -p ${WorkDir}/BestTrace/ >/dev/null 2>&1
    if [ "${LBench_Result_NetworkStat}" = "ipv4only" ] || [ "${LBench_Result_NetworkStat}" = "dualstack" ]; then
        echo -e "\n ${Font_Yellow}-> 路由追踪测试 (IPV4)${Font_Suffix}\n"
        echo -e "\n -> 路由追踪测试 (IPV4)\n" >>${WorkDir}/BestTrace/result.txt
        # 新版节点列表 Ver 20190817
        # 国内部分
        Run_BestTrace "123.125.99.1" "TCP" "30" "北京联通"
        Run_BestTrace "180.149.128.1" "TCP" "30" "北京电信"
        Run_BestTrace "211.136.88.117" "TCP" "30" "北京移动"
        Run_BestTrace "58.247.0.49" "TCP" "30" "上海联通"
        Run_BestTrace "180.153.28.1" "TCP" "30" "上海电信"
        Run_BestTrace "221.183.55.22" "TCP" "30" "上海移动"
        Run_BestTrace "210.21.4.130" "TCP" "30" "广州联通"
        Run_BestTrace "113.108.209.1" "TCP" "30" "广州电信"
        Run_BestTrace "211.139.129.5" "TCP" "30" "广州移动"
        Run_BestTrace "210.13.66.238" "TCP" "30" "上海联通精品网"
        Run_BestTrace "58.32.0.1" "TCP" "30" "上海电信CN2"
        Run_BestTrace "211.167.230.100" "TCP" "30" "北京鹏博士/电信通"
        Run_BestTrace "202.205.109.205" "TCP" "30" "北京教育网"
        Run_BestTrace "159.226.254.1" "TCP" "30" "北京科技网"
        Run_BestTrace "211.156.140.17" "TCP" "30" "北京广电网"
        # 香港部分
        Run_BestTrace "203.160.95.218" "TCP" "30" "香港联通"
        Run_BestTrace "203.215.232.173" "TCP" "30" "香港电信163"
        Run_BestTrace "203.8.25.187" "TCP" "30" "香港电信CN2"
        Run_BestTrace "203.142.105.9" "TCP" "30" "香港移动"
        Run_BestTrace "218.188.104.30" "TCP" "30" "香港HGC"
        Run_BestTrace "210.6.23.239" "TCP" "30" "香港HKBN"
        Run_BestTrace "202.85.125.60" "TCP" "30" "香港PCCW"
        Run_BestTrace "61.4.15.137" "TCP" "30" "香港TGT"
        Run_BestTrace "59.152.252.242" "TCP" "30" "香港WTT"
        # 新加坡部分
        Run_BestTrace "203.215.233.1" "TCP" "30" "新加坡电信163"
        Run_BestTrace "183.91.61.1" "TCP" "30" "新加坡电信CN2"
        Run_BestTrace "118.201.1.11" "TCP" "30" "新加坡Singtel"
        Run_BestTrace "203.116.221.47" "TCP" "30" "新加坡StarHub"
        Run_BestTrace "203.123.8.123" "TCP" "30" "新加坡M1"
        Run_BestTrace "13.228.0.251" "TCP" "50" "新加坡AWS"
        # 日本部分
        Run_BestTrace "61.213.155.84" "TCP" "30" "日本NTT"
        Run_BestTrace "202.232.15.70" "TCP" "30" "日本IIJ"
        Run_BestTrace "210.175.32.26" "TCP" "30" "日本SoftBank"
        Run_BestTrace "106.162.242.108" "TCP" "30" "日本KDDI"
        Run_BestTrace "203.215.236.3" "TCP" "30" "日本电信163"
        Run_BestTrace "202.55.27.4" "TCP" "30" "日本电信CN2"
        Run_BestTrace "13.112.63.251" "TCP" "50" "日本AWS"
        # 韩国部分
        Run_BestTrace "59.10.184.64" "TCP" "30" "韩国KT"
        Run_BestTrace "175.113.80.201" "TCP" "30" "韩国SK"
        Run_BestTrace "211.174.62.44" "TCP" "30" "韩国LG"
        Run_BestTrace "218.185.246.1" "TCP" "30" "韩国电信CN2"
        Run_BestTrace "13.124.63.251" "TCP" "50" "韩国AWS"
        # 台湾部分
        Run_BestTrace "202.133.242.116" "TCP" "30" "台湾Chief"
        Run_BestTrace "210.200.69.90" "TCP" "30" "台湾APTG"
        Run_BestTrace "203.75.129.162" "TCP" "30" "台湾CHT"
        Run_BestTrace "219.87.66.3" "TCP" "30" "台湾TFN"
        Run_BestTrace "211.73.144.38" "TCP" "30" "台湾FET"
        Run_BestTrace "61.63.0.102" "TCP" "30" "台湾KBT"
        Run_BestTrace "103.31.196.203" "TCP" "30" "台湾TAIFO"
        # 美国部分
        Run_BestTrace "218.30.33.17" "TCP" "30" "美国洛杉矶电信163"
        Run_BestTrace "66.102.252.100" "TCP" "30" "美国洛杉矶电信CN2"
        Run_BestTrace "63.218.42.81" "TCP" "30" "美国洛杉矶PCCW"
        Run_BestTrace "66.220.18.42" "TCP" "30" "美国洛杉矶HE"
        Run_BestTrace "173.205.77.98" "TCP" "30" "美国洛杉矶GTT"
        Run_BestTrace "12.169.215.33" "TCP" "30" "美国旧金山ATT"
        Run_BestTrace "66.198.181.100" "TCP" "30" "美国纽约TATA"
        Run_BestTrace "218.30.33.17" "TCP" "30" "美国圣何塞电信163"
        Run_BestTrace "23.11.26.62" "TCP" "30" "美国圣何塞NTT"
        Run_BestTrace "72.52.104.74" "TCP" "30" "美国费利蒙HE"
        Run_BestTrace "205.216.62.38" "TCP" "30" "美国达拉斯Level3"
        Run_BestTrace "64.125.191.144" "TCP" "30" "美国迈阿密ZAYO"
        Run_BestTrace "149.127.109.166" "TCP" "30" "美国阿什本Cogentco"
        # 欧洲部分
        Run_BestTrace "80.146.191.1" "TCP" "30" "德国北莱茵－威斯特法伦州Telekom"
        Run_BestTrace "82.113.108.25" "TCP" "30" "德国法兰克福O2"
        Run_BestTrace "139.7.146.11" "TCP" "50" "德国法兰克福Vodafone"
        Run_BestTrace "118.85.205.101" "TCP" "30" "德国法兰克福电信163"
        Run_BestTrace "5.10.138.33" "TCP" "30" "德国法兰克福电信CN2"
        Run_BestTrace "213.200.65.70" "TCP" "30" "德国法兰克福GTT"
        Run_BestTrace "212.20.150.5" "TCP" "30" "德国法兰克福Cogentco"
        Run_BestTrace "194.62.232.211" "TCP" "30" "英国Vodafone"
        Run_BestTrace "213.121.43.24" "TCP" "30" "英国BT"
        Run_BestTrace "80.231.60.38" "TCP" "30" "英国伦敦TATA"
        Run_BestTrace "118.85.205.121" "TCP" "30" "俄罗斯电信163"
        Run_BestTrace "185.75.173.17" "TCP" "30" "俄罗斯电信CN2"
        Run_BestTrace "87.226.162.77" "TCP" "30" "俄罗斯莫斯科RT"
        Run_BestTrace "217.150.32.2" "TCP" "30" "俄罗斯莫斯科TTK"
        Run_BestTrace "195.34.53.186" "TCP" "30" "俄罗斯莫斯科MTS"
    fi
    if [ "${LBench_Result_NetworkStat}" = "ipv6only" ] || [ "${LBench_Result_NetworkStat}" = "dualstack" ]; then
        echo -e "\n ${Font_Yellow}-> 路由追踪测试 (IPV6)${Font_Suffix}\n"
        echo -e "\n -> 路由追踪测试 (IPV6)\n" >>${WorkDir}/BestTrace/result.txt
        Run_BestTrace6 "2408:80f0:4100:2005::3" "ICMP" "30" "北京联通-IPV6"
        Run_BestTrace6 "240e:0:a::c9:1cb4" "ICMP" "30" "北京电信-IPV6"
        Run_BestTrace6 "2409:8080:0:2:103:1b1:0:1" "ICMP" "30" "北京移动-IPV6"
        Run_BestTrace6 "2001:da8:a0:1001::1" "ICMP" "30" "北京教育网CERNET2-IPV6"
    fi
    # 执行完成, 标记FLAG
    LBench_Flag_FinishBestTraceFull="1"
}

Function_SpooferTest() {
    if [ "${Var_SpooferDisabled}" = "1" ]; then
        return 0
    fi
    mkdir -p ${WorkDir}/Spoofer/ >/dev/null 2>&1
    echo -e "\n ${Font_Yellow}-> Spoofer测试${Font_Suffix}\n"
    echo -e "\n -> Spoofer测试\n" >>${WorkDir}/Spoofer/result.txt
    Check_Spoofer
    mkdir ${WorkDir}/ >/dev/null 2>&1
    echo -e "正在运行Spoofer测试, 请耐心等待..."
    /usr/local/bin/spoofer-prober -s0 -r0 | tee -a ${WorkDir}/spoofer.log >/dev/null
    if [ "$?" = "0" ]; then
        LBench_Result_SpooferResultURL="$(cat ${WorkDir}/spoofer.log | grep -oE "https://spoofer.caida.org/report.php\?sessionkey\=[0-9a-z]{1,}")"
        echo -e "\n ${Msg_Success}Spoofer测试结果：${LBench_Result_SpooferResultURL}"
        echo -e "\n Spoofer测试结果：${LBench_Result_SpooferResultURL}" >>${WorkDir}/Spoofer/result.txt
        LBench_Flag_FinishSpooferTest="1"
    else
        cp -f ${WorkDir}/spoofer.log /tmp/lemonbench.spoofer.log
        echo -e "\n ${Msg_Error}Spoofer测试失败! 请使用 cat /tmp/lemonbench.spoofer.log 查看日志!"
        echo -e "\n Spoofer测试结果：测试失败" >>${WorkDir}/Spoofer/result.txt
        LBench_Flag_FinishSpooferTest="2"
    fi
    rm -rf ${WorkDir}/spoofer.log
    # 执行完成, 标记FLAG
}

# =============== SysBench - CPU性能 部分 ===============
Run_SysBench_CPU() {
    # 调用方式: Run_SysBench_CPU "线程数" "测试时长(秒)" "测试遍数" "说明"
    # 变量初始化
    mkdir -p ${WorkDir}/SysBench/CPU/ >/dev/null 2>&1
    maxtestcount="$3"
    local count="1"
    local TestScore="0"
    local TotalScore="0"
    # 运行测试
    while [ $count -le $maxtestcount ]; do
        echo -e "\r ${Font_Yellow}$4:${Font_Suffix}\t$count/$maxtestcount \c"
        local TestResult="$(sysbench --test=cpu --num-threads=$1 --cpu-max-prime=10000 --max-requests=1000000 --max-time=$2 run 2>&1)"
        local TestScore="$(echo ${TestResult} | grep -oE "total number of events: [0-9]+" | grep -oE "[0-9]+")"
        local TestScoreAvg="$(echo ${TestScore} $2 | awk '{printf "%d",$1/$2}')"
        let TotalScore=TotalScore+TestScoreAvg
        let count=count+1
        local TestResult=""
        local TestScore="0"
    done
    ResultScore="$(echo "${TotalScore} ${maxtestcount}" | awk '{printf "%d",$1/$2}')"
    echo -e "\r ${Font_Yellow}$4:${Font_Suffix}\t${Font_SkyBlue}${ResultScore}${Font_Suffix} ${Font_Yellow}分${Font_Suffix}"
    echo -e " $4:\t${ResultScore} 分" >>${WorkDir}/SysBench/CPU/result.txt
}

Function_SysBench_CPU_Fast() {
    mkdir -p ${WorkDir}/SysBench/CPU/ >/dev/null 2>&1
    echo -e "\n ${Font_Yellow}-> CPU性能测试 (快速模式, 1-Pass @ 5sec)${Font_Suffix}\n"
    echo -e "\n -> CPU性能测试 (快速模式, 1-Pass @ 5sec)\n" >>${WorkDir}/SysBench/CPU/result.txt
    Run_SysBench_CPU "1" "5" "1" "1 线程测试"
    if [ "${LBench_Result_CPUThreadNumber}" != "1" ]; then
        Run_SysBench_CPU "${LBench_Result_CPUThreadNumber}" "5" "1" "${LBench_Result_CPUThreadNumber} 线程测试"
    fi
    # 完成FLAG
    LBench_Flag_FinishSysBenchCPUFast="1"
}

Function_SysBench_CPU_Full() {
    mkdir -p ${WorkDir}/SysBench/CPU/ >/dev/null 2>&1
    echo -e "\n ${Font_Yellow}-> CPU性能测试 (标准模式, 3-Pass @ 30sec)${Font_Suffix}\n"
    echo -e "\n -> CPU性能测试 (标准模式, 3-Pass @ 30sec)\n" >>${WorkDir}/SysBench/CPU/result.txt
    Run_SysBench_CPU "1" "30" "3" "1 线程测试"
    if [ "${LBench_Result_CPUThreadNumber}" != "1" ]; then
        Run_SysBench_CPU "${LBench_Result_CPUThreadNumber}" "30" "3" "${LBench_Result_CPUThreadNumber} 线程测试"
    fi
    # 完成FLAG
    LBench_Flag_FinishSysBenchCPUFull="1"
}

# =============== SysBench - 内存性能 部分 ===============
Run_SysBench_Memory() {
    # 调用方式: Run_SysBench_Memory "线程数" "测试时长(秒)" "测试遍数" "测试模式(读/写)" "读写方式(顺序/随机)" "说明"
    # 变量初始化
    mkdir -p ${WorkDir}/SysBench/Memory/ >/dev/null 2>&1
    maxtestcount="$3"
    local count="1"
    local TestScore="0.00"
    local TestSpeed="0.00"
    local TotalScore="0.00"
    local TotalSpeed="0.00"
    # 运行测试
    while [ $count -le $maxtestcount ]; do
        echo -e "\r ${Font_Yellow}$6:${Font_Suffix}\t$count/$maxtestcount \c"
        local TestResult="$(sysbench --test=memory --num-threads=$1 --memory-total-size=1000000M --memory-oper=$4 --max-time=$2 --memory-access-mode=$5 run 2>&1)"
        # 判断是MB还是MiB
        echo "${TestResult}" | grep -oE "MiB" >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            local MiB_Flag="1"
        else
            local MiB_Flag="0"
        fi
        local TestScore="$(echo "${TestResult}" | grep -oE "[0-9]{1,}.[0-9]{1,2} ops\/sec|[0-9]{1,}.[0-9]{1,2} per second" | grep -oE "[0-9]{1,}.[0-9]{1,2}")"
        local TestSpeed="$(echo "${TestResult}" | grep -oE "[0-9]{1,}.[0-9]{1,2} MB\/sec|[0-9]{1,}.[0-9]{1,2} MiB\/sec" | grep -oE "[0-9]{1,}.[0-9]{1,2}")"
        local TotalScore="$(echo "${TotalScore} ${TestScore}" | awk '{printf "%.2f",$1+$2}')"
        local TotalSpeed="$(echo "${TotalSpeed} ${TestSpeed}" | awk '{printf "%.2f",$1+$2}')"
        let count=count+1
        local TestResult=""
        local TestScore="0.00"
        local TestSpeed="0.00"
    done
    ResultScore="$(echo "${TotalScore} ${maxtestcount} 1000" | awk '{printf "%.2f",$1/$2/$3}')"
    if [ "${MiB_Flag}" = "1" ]; then
        # MiB to MB
        ResultSpeed="$(echo "${TotalSpeed} ${maxtestcount} 1048576‬ 1000000" | awk '{printf "%.2f",$1/$2/$3*$4}')"
    else
        # 直接输出
        ResultSpeed="$(echo "${TotalSpeed} ${maxtestcount}" | awk '{printf "%.2f",$1/$2}')"
    fi
    echo -e "\r ${Font_Yellow}$6:${Font_Suffix}\t${Font_SkyBlue}${ResultScore}K${Font_Suffix} ${Font_Yellow}ops${Font_Suffix} (${Font_SkyBlue}${ResultSpeed}${Font_Suffix} ${Font_Yellow}MB/s${Font_Suffix})"
    echo -e " $6:\t${ResultScore}K ops (${ResultSpeed} MB/s)" >>${WorkDir}/SysBench/Memory/result.txt
}

Function_SysBench_Memory_Fast() {
    mkdir -p ${WorkDir}/SysBench/Memory/ >/dev/null 2>&1
    echo -e "\n ${Font_Yellow}-> 内存性能测试 (快速模式, 1-Pass @ 5sec)${Font_Suffix}\n"
    echo -e "\n -> 内存性能测试 (快速模式, 1-Pass @ 5sec)\n" >>${WorkDir}/SysBench/Memory/result.txt
    Run_SysBench_Memory "1" "5" "1" "read" "seq" "1 线程测试-顺序读"
    Run_SysBench_Memory "1" "5" "1" "read" "seq" "1 线程测试-顺序写"
    Run_SysBench_Memory "1" "5" "1" "write" "rnd" "1 线程测试-随机读"
    Run_SysBench_Memory "1" "5" "1" "write" "rnd" "1 线程测试-随机写"
    if [ "${LBench_Result_CPUThreadNumber}" -gt "1" ]; then
        Run_SysBench_Memory "${LBench_Result_CPUThreadNumber}" "5" "1" "read" "seq" "${LBench_Result_CPUThreadNumber} 线程测试-顺序读"
        Run_SysBench_Memory "${LBench_Result_CPUThreadNumber}" "5" "1" "read" "seq" "${LBench_Result_CPUThreadNumber} 线程测试-顺序写"
        Run_SysBench_Memory "${LBench_Result_CPUThreadNumber}" "5" "1" "write" "rnd" "${LBench_Result_CPUThreadNumber} 线程测试-随机读"
        Run_SysBench_Memory "${LBench_Result_CPUThreadNumber}" "5" "1" "write" "rnd" "${LBench_Result_CPUThreadNumber} 线程测试-随机写"
    fi
    # 完成FLAG
    LBench_Flag_FinishSysBenchMemoryFast="1"
}

Function_SysBench_Memory_Full() {
    mkdir -p ${WorkDir}/SysBench/Memory/ >/dev/null 2>&1
    echo -e "\n ${Font_Yellow}-> 内存性能测试 (标准模式, 3-Pass @ 30sec)${Font_Suffix}\n"
    echo -e "\n -> 内存性能测试 (标准模式, 3-Pass @ 30sec)\n" >>${WorkDir}/SysBench/Memory/result.txt
    Run_SysBench_Memory "1" "30" "3" "read" "seq" "1 线程测试-顺序读"
    Run_SysBench_Memory "1" "30" "3" "read" "seq" "1 线程测试-顺序写"
    Run_SysBench_Memory "1" "30" "3" "write" "rnd" "1 线程测试-随机读"
    Run_SysBench_Memory "1" "30" "3" "write" "rnd" "1 线程测试-随机写"
    if [ "${LBench_Result_CPUThreadNumber}" -gt "1" ]; then
        Run_SysBench_Memory "${LBench_Result_CPUThreadNumber}" "30" "1" "read" "seq" "${LBench_Result_CPUThreadNumber} 线程测试-顺序读"
        Run_SysBench_Memory "${LBench_Result_CPUThreadNumber}" "30" "1" "read" "seq" "${LBench_Result_CPUThreadNumber} 线程测试-顺序写"
        Run_SysBench_Memory "${LBench_Result_CPUThreadNumber}" "30" "1" "write" "rnd" "${LBench_Result_CPUThreadNumber} 线程测试-随机读"
        Run_SysBench_Memory "${LBench_Result_CPUThreadNumber}" "30" "1" "write" "rnd" "${LBench_Result_CPUThreadNumber} 线程测试-随机写"
    fi
    # 完成FLAG
    LBench_Flag_FinishSysBenchMemoryFull="1"
}

# 生成结果文件
Function_GenerateResult() {
    echo -e "${Msg_Info}请稍后, 正在收集结果 ..."
    mkdir -p /tmp/ >/dev/null 2>&1
    mkdir -p ${WorkDir}/result >/dev/null 2>&1
    Function_GenerateResult_Header >/dev/null
    Function_GenerateResult_SystemInfo >/dev/null
    Function_GenerateResult_NetworkInfo >/dev/null
    Function_GenerateResult_MediaUnlockTest >/dev/null
    Function_GenerateResult_SysBench_CPUTest >/dev/null
    Function_GenerateResult_SysBench_MemoryTest >/dev/null
    Function_GenerateResult_DiskTest >/dev/null
    Function_GenerateResult_Speedtest >/dev/null
    Function_GenerateResult_BestTrace >/dev/null
    Function_GenerateResult_Spoofer >/dev/null
    Function_GenerateResult_Footer >/dev/null
    echo -e "${Msg_Info}正在生成测试报告 ..."
    local finalresultfile="${WorkDir}/result/finalresult.txt"
    if [ -f "${WorkDir}/result/00-header.result" ]; then
        cat ${WorkDir}/result/00-header.result >>${WorkDir}/result/finalresult.txt
    fi
    if [ -f "${WorkDir}/result/01-systeminfo.result" ]; then
        cat ${WorkDir}/result/01-systeminfo.result >>${WorkDir}/result/finalresult.txt
    fi
    if [ -f "${WorkDir}/result/02-networkinfo.result" ]; then
        cat ${WorkDir}/result/02-networkinfo.result >>${WorkDir}/result/finalresult.txt
    fi
    if [ -f "${WorkDir}/result/03-mediaunlocktest.result" ]; then
        cat ${WorkDir}/result/03-mediaunlocktest.result >>${WorkDir}/result/finalresult.txt
    fi
    if [ -f "${WorkDir}/result/04-cputest.result" ]; then
        cat ${WorkDir}/result/04-cputest.result >>${WorkDir}/result/finalresult.txt
    fi
    if [ -f "${WorkDir}/result/05-memorytest.result" ]; then
        cat ${WorkDir}/result/05-memorytest.result >>${WorkDir}/result/finalresult.txt
    fi
    if [ -f "${WorkDir}/result/06-disktest.result" ]; then
        cat ${WorkDir}/result/06-disktest.result >>${WorkDir}/result/finalresult.txt
    fi
    if [ -f "${WorkDir}/result/07-speedtest.result" ]; then
        cat ${WorkDir}/result/07-speedtest.result >>${WorkDir}/result/finalresult.txt
    fi
    if [ -f "${WorkDir}/result/08-besttrace.result" ]; then
        cat ${WorkDir}/result/08-besttrace.result >>${WorkDir}/result/finalresult.txt
    fi
    if [ -f "${WorkDir}/result/09-spoofer.result" ]; then
        cat ${WorkDir}/result/09-spoofer.result >>${WorkDir}/result/finalresult.txt
    fi
    if [ -f "${WorkDir}/result/99-footer.result" ]; then
        cat ${WorkDir}/result/99-footer.result >>${WorkDir}/result/finalresult.txt
    fi
    echo -e "${Msg_Info}正在保存本地测试报告 ..."
    cp ${WorkDir}/result/finalresult.txt $HOME/LemonBench.Result.txt
    echo -e "${Msg_Info}正在生成云端测试报告 ..."
    cat ${WorkDir}/result/finalresult.txt | PasteBin_Upload
}

Function_GenerateResult_Header() {
    local rfile="${WorkDir}/result/00-header.result"
    echo -e " " >>$rfile
    echo -e " LemonBench Linux System Benchmark Utility Version ${BuildTime} " >>$rfile
    echo -e " " >>$rfile
    echo -e " 测试开始时间：\t${LBench_Result_BenchStartTime}" >>$rfile
    echo -e " 测试结束时间：\t${LBench_Result_BenchFinishTime}" >>$rfile
    echo -e " 测试模式：\t${Global_TestModeTips}" >>$rfile
    echo -e " \n\n"
}

Function_GenerateResult_SystemInfo() {
    local rfile="${WorkDir}/result/01-systeminfo.result"
    if [ "${LBench_Flag_FinishSystemInfo}" = "1" ]; then
        echo -e " \n -> 系统信息" >>$rfile
        echo -e " " >>$rfile
        echo -e " 系统名称:\t\t${LBench_Result_OSReleaseFullName}" >>$rfile
        echo -e " CPU型号:\t\t${LBench_Result_CPUModelName}" >>$rfile
        echo -e " CPU缓存大小:\t\t${LBench_Result_CPUCacheSize}" >>$rfile
        if [ "${LBench_Result_CPUIsPhysical}" = "1" ]; then
            if [ "${LBench_Result_CPUPhysicalNumber}" -eq "1" ]; then
                echo -e " CPU数量:\t\t${LBench_Result_CPUPhysicalNumber} 物理CPU, ${LBench_Result_CPUCoreNumber} 核心, ${LBench_Result_CPUThreadNumber} 线程" >>$rfile
            else
                echo -e " CPU数量:\t\t${LBench_Result_CPUPhysicalNumber} 物理CPU, ${LBench_Result_CPUCoreNumber} 核心/CPU, ${LBench_Result_CPUSiblingsNumber} 线程/CPU (总共 ${LBench_Result_CPUTotalCoreNumber} 核心, ${LBench_Result_CPUProcessorNumber} 线程)" >>$rfile
            fi
            if [ "${LBench_Result_CPUVirtualization}" = "1" ]; then
                echo -e " 虚拟化已就绪:\t\t是 (基于 ${LBench_Result_CPUVirtualizationType})" >>$rfile
            else
                echo -e " 虚拟化已就绪:\t\t${Font_SkyRed}否" >>$rfile
            fi
        elif [ "${Var_VirtType}" = "openvz" ]; then
            echo -e " CPU数量:\t\t${LBench_Result_CPUThreadNumber} vCPU (${LBench_Result_CPUCoreNumber} 宿主机核心)" >>$rfile
        else
            echo -e " CPU数量:\t\t${LBench_Result_CPUThreadNumber} vCPU" >>$rfile
        fi
        echo -e " 虚拟化类型:\t\t${LBench_Result_VirtType}" >>$rfile
        echo -e " 内存使用率:\t\t${LBench_Result_Memory}" >>$rfile
        echo -e " Swap使用率:\t\t${LBench_Result_Swap}" >>$rfile
        if [ "${LBench_Result_DiskUsed_KB}" -lt "1000000" ]; then
            LBench_Result_Disk="${LBench_Result_DiskUsed_MB} MB / ${LBench_Result_DiskTotal_MB} MB"
            echo -e " 磁盘使用率:\t\t${LBench_Result_DiskUsed_MB} MB / ${LBench_Result_DiskTotal_MB} MB" >>$rfile
        elif [ "${LBench_Result_DiskUsed_KB}" -lt "1000000" ] && [ "${LBench_Result_DiskTotal_KB}" -lt "1000000000" ]; then
            LBench_Result_Disk="${LBench_Result_DiskUsed_MB} MB / ${LBench_Result_DiskTotal_GB} GB"
            echo -e " 磁盘使用率:\t\t${LBench_Result_DiskUsed_MB} MB / ${LBench_Result_DiskTotal_GB} GB" >>$rfile
        elif [ "${LBench_Result_DiskUsed_KB}" -lt "1000000000" ] && [ "${LBench_Result_DiskTotal_KB}" -lt "1000000000" ]; then
            LBench_Result_Disk="${LBench_Result_DiskUsed_GB} GB / ${LBench_Result_DiskTotal_GB} GB"
            echo -e " 磁盘使用率:\t\t${LBench_Result_DiskUsed_GB} GB / ${LBench_Result_DiskTotal_GB} GB" >>$rfile
        elif [ "${LBench_Result_DiskUsed_KB}" -lt "1000000000" ] && [ "${LBench_Result_DiskTotal_KB}" -ge "1000000000" ]; then
            LBench_Result_Disk="${LBench_Result_DiskUsed_GB} GB / ${LBench_Result_DiskTotal_TB} TB"
            echo -e " 磁盘使用率:\t\t${LBench_Result_DiskUsed_GB} GB / ${LBench_Result_DiskTotal_TB} TB" >>$rfile
        else
            LBench_Result_Disk="${LBench_Result_DiskUsed_TB} TB / ${LBench_Result_DiskTotal_TB} TB"
            echo -e " 磁盘使用率:\t\t${LBench_Result_DiskUsed_TB} TB / ${LBench_Result_DiskTotal_TB} TB" >>$rfile
        fi
        echo -e " 引导设备:\t\t${LBench_Result_DiskRootPath}" >>$rfile
        echo -e " 系统负载(1/5/15min):\t${LBench_Result_LoadAverage_1min} ${LBench_Result_LoadAverage_5min} ${LBench_Result_LoadAverage_15min} " >>$rfile
    fi
}

Function_GenerateResult_NetworkInfo() {
    if [ "${LBench_Flag_FinishNetworkInfo}" = "1" ]; then
        local rfile="${WorkDir}/result/02-networkinfo.result"
        echo -e "\n -> 网络信息\n" >>$rfile
        if [ "${LBench_Result_NetworkStat}" = "ipv4only" ] || [ "${LBench_Result_NetworkStat}" = "dualstack" ]; then
            local IPAPI_IPV4_IP_Masked="$(echo ${IPAPI_IPV4_IP} | awk -F'.' '{print $1"."$2.".*.*"}')"
            echo -e " IPV4 - 本机IP:\t\t${IPAPI_IPV4_IP_Masked}" >>$rfile
            echo -e " IPV4 - ASN信息:\t${IPAPI_IPV4_ASN} (${IPAPI_IPV4_Location})" >>$rfile
            echo -e " IPV4 - 运营商:\t\t${IPAPI_IPV4_ISP}" >>$rfile
        fi
        if [ "${LBench_Result_NetworkStat}" = "ipv6only" ] || [ "${LBench_Result_NetworkStat}" = "dualstack" ]; then
            echo -e " IPV6 - 本机IP:\t\t[${IPAPI_IPV6_country_code}] ${IPAPI_IPV6_ip}" >>$rfile
            echo -e " IPV6 - ASN信息:\tAS${IPAPI_IPV6_asn} (${IPAPI_IPV6_organization})" >>$rfile
            echo -e " IPV6 - 归属地:\t\t${IPAPI_IPV6_country}, ${IPAPI_IPV6_region}" >>$rfile
        fi
    fi
}

Function_GenerateResult_MediaUnlockTest() {
    if [ "${LBench_Flag_FinishMediaUnlockTest}" = "1" ]; then
        local rfile="${WorkDir}/result/03-mediaunlocktest.result"
        echo -e "\n -> 流媒体解锁测试\n" >>$rfile
        # HBO Now
        echo -e " HBO Now:\t\t${LemonBench_Result_MediaUnlockTest_HBONow}" >>$rfile
        # 动画疯
        echo -e " 巴哈姆特動畫瘋:\t${LemonBench_Result_MediaUnlockTest_BahamutAnime}" >>$rfile
        # Abema.TV (IP Test)
        # echo -e " Abema.TV (IP Test):\t${LemonBench_Result_MediaUnlockTest_AbemaTV_IPTest}" >>$rfile
        # 哔哩哔哩港澳台
        echo -e " 哔哩哔哩-港澳台限定:\t${LemonBench_Result_MediaUnlockTest_BilibiliHKMCTW}" >>$rfile
        # 哔哩哔哩台湾限定
        echo -e " 哔哩哔哩-台湾限定:\t${LemonBench_Result_MediaUnlockTest_BilibiliTW}" >>$rfile
    fi
}

Function_GenerateResult_SysBench_CPUTest() {
    if [ -f "${WorkDir}/SysBench/CPU/result.txt" ]; then
        cp -f ${WorkDir}/SysBench/CPU/result.txt ${WorkDir}/result/04-cputest.result
    fi
}

Function_GenerateResult_SysBench_MemoryTest() {
    if [ -f "${WorkDir}/SysBench/Memory/result.txt" ]; then
        cp -f ${WorkDir}/SysBench/Memory/result.txt ${WorkDir}/result/05-memorytest.result
    fi
}

Function_GenerateResult_DiskTest() {
    if [ -f "${WorkDir}/DiskTest/result.txt" ]; then
        cp -f ${WorkDir}/DiskTest/result.txt ${WorkDir}/result/06-disktest.result
    fi
}

Function_GenerateResult_Speedtest() {
    if [ -f "${WorkDir}/Speedtest/result.txt" ]; then
        cp -f ${WorkDir}/Speedtest/result.txt ${WorkDir}/result/07-speedtest.result
    fi
}

Function_GenerateResult_BestTrace() {
    if [ -f "${WorkDir}/BestTrace/result.txt" ]; then
        cp -f ${WorkDir}/BestTrace/result.txt ${WorkDir}/result/08-besttrace.result
    fi
}

Function_GenerateResult_Spoofer() {
    if [ -f "${WorkDir}/Spoofer/result.txt" ]; then
        cp -f ${WorkDir}/Spoofer/result.txt ${WorkDir}/result/09-spoofer.result
    fi
}

Function_GenerateResult_Footer() {
    local rfile="${WorkDir}/result/99-footer.result"
    echo -e " \n"
    echo -e " Generated by LemonBench on $(date -u "+%Y-%m-%dT%H:%M:%SZ") Version ${BuildTime}" >>$rfile
    echo -e " \n"
}

# =============== 检查 Virt-what 组件 ===============
Check_Virtwhat() {
    if [ ! -f "/usr/sbin/virt-what" ]; then
        SystemInfo_GetOSRelease
        if [ "${Var_OSRelease}" = "centos" ] || [ "${Var_OSRelease}" = "rhel" ]; then
            echo -e "${Msg_Warning}未检测到Virt-What模块, 正在安装..."
            yum -y install virt-what
        elif [ "${Var_OSRelease}" = "ubuntu" ] || [ "${Var_OSRelease}" = "debian" ]; then
            echo -e "${Msg_Warning}未检测到Virt-What模块, 正在安装..."
            apt-get update
            apt-get install -y virt-what
        elif [ "${Var_OSRelease}" = "fedora" ]; then
            echo -e "${Msg_Warning}未检测到Virt-What模块, 正在安装..."
            dnf -y install virt-what
        elif [ "${Var_OSRelease}" = "alpinelinux" ]; then
            echo -e "${Msg_Warning}未检测到Virt-What模块, 正在安装..."
            apk update
            apk add virt-what
        else
            echo -e "${Msg_Warning}未检测到Virt-What模块, 但无法确定当前系统分支!"
        fi
    fi
    # 二次检测
    if [ ! -f "/usr/sbin/virt-what" ]; then
        echo -e "Virt-What模块安装失败! 请尝试重启程序或者手动安装!"
        exit 1
    fi
}

# =============== 检查 Speedtest 组件 ===============
Check_Speedtest() {
    speedtest --version >/dev/null 2>&1
    if [ "$?" != "0" ]; then
        SystemInfo_GetOSRelease
        if [ "${Var_OSRelease}" = "centos" ] || [ "${Var_OSRelease}" = "rhel" ]; then
            echo -e "${Msg_Warning}未检测到Speedtest模块, 正在安装..."
            echo -e "${Msg_Info}正在安装必需环境 ..."
            yum -y install epel-release
            yum -y install python-pip
            echo -e "${Msg_Info}正在安装Speedtest模块 ..."
            pip install speedtest-cli
        elif [ "${Var_OSRelease}" = "ubuntu" ] || [ "${Var_OSRelease}" = "debian" ]; then
            echo -e "${Msg_Warning}未检测到Speedtest模块, 正在安装..."
            echo -e "${Msg_Info}正在安装必需环境 ..."
            apt-get update
            apt-get --no-install-recommends -y install python-pip
            echo -e "${Msg_Info}正在安装Speedtest模块 ..."
            pip install speedtest-cli
        elif [ "${Var_OSRelease}" = "fedora" ]; then
            echo -e "${Msg_Warning}未检测到Speedtest模块, 正在安装..."
            echo -e "${Msg_Info}正在安装必需环境 ..."
            dnf -y install python-pip
            echo -e "${Msg_Info}正在安装Speedtest模块 ..."
            pip install speedtest-cli
        elif [ "${Var_OSRelease}" = "alpinelinux" ]; then
            echo -e "${Msg_Warning}未检测到Speedtest模块, 正在安装..."
            echo -e "${Msg_Info}正在安装必需环境 ..."
            apk update
            apk add py2-pip
            echo -e "${Msg_Info}正在安装Speedtest模块 ..."
            pip install speedtest-cli
        else
            echo -e "${Msg_Warning}未检测到Speedtest模块, 但无法确定当前系统分支!"
        fi
    fi
    # 二次检测
    speedtest --version >/dev/null 2>&1
    if [ "$?" != "0" ]; then
        speedtest-cli --version >/dev/null 2>&1
        if [ "$?" != "0" ]; then
            echo -e "Speedtest模块安装失败! 请尝试重启程序或者手动安装!"
            exit 1
        fi
    fi
}

# =============== 检查 BestTrace 组件 ===============
Check_BestTrace() {
    if [ ! -f "/usr/local/bin/besttrace" ]; then
        SystemInfo_GetOSRelease
        SystemInfo_GetSystemBit
        if [ "${LBench_Result_SystemBit_Short}" = "64" ]; then
            local DownloadSrc="https://download.ilemonrain.com/LemonBench/include/BestTrace/besttrace64.gz"
        elif [ "${LBench_Result_SystemBit_Short}" = "32" ]; then
            local DownloadSrc="https://download.ilemonrain.com/LemonBench/include/BestTrace/besttrace32.gz"
        else
            local DownloadSrc="https://download.ilemonrain.com/LemonBench/include/BestTrace/besttrace32.gz"
        fi
        mkdir -p ${WorkDir}/
        if [ "${Var_OSRelease}" = "centos" ] || [ "${Var_OSRelease}" = "rhel" ]; then
            echo -e "${Msg_Warning}未检测到BestTrace模块, 正在安装..."
            echo -e "${Msg_Info}正在安装必需环境 ..."
            yum -y install curl unzip
            echo -e "${Msg_Info}正在下载BestTrace组件 ..."
            curl --user-agent "${UA_LemonBench}" ${DownloadSrc} -o ${WorkDir}/besttrace.gz
            echo -e "${Msg_Info}正在安装BestTrace组件 ..."
            gzip -dN ${WorkDir}/besttrace.gz
            mv ${WorkDir}/besttrace /usr/local/bin/besttrace
            chmod +x /usr/local/bin/besttrace
            echo -e "${Msg_Info}正在清理环境 ..."
            rm -rf ${WorkDir}/besttrace.gz
        elif [ "${Var_OSRelease}" = "ubuntu" ] || [ "${Var_OSRelease}" = "debian" ]; then
            echo -e "${Msg_Warning}未检测到BestTrace模块, 正在安装..."
            echo -e "${Msg_Info}正在安装必需环境 ..."
            apt-get update
            apt-get --no-install-recommends -y install wget unzip curl ca-certificates
            echo -e "${Msg_Info}正在下载BestTrace组件 ..."
            curl --user-agent "${UA_LemonBench}" ${DownloadSrc} -o ${WorkDir}/besttrace.gz
            echo -e "${Msg_Info}正在安装BestTrace组件 ..."
            gzip -dN ${WorkDir}/besttrace.gz
            mv ${WorkDir}/besttrace /usr/local/bin/besttrace
            chmod +x /usr/local/bin/besttrace
            echo -e "${Msg_Info}正在清理环境 ..."
            rm -rf ${WorkDir}/besttrace.gz
        elif [ "${Var_OSRelease}" = "fedora" ]; then
            echo -e "${Msg_Warning}未检测到BestTrace模块, 正在安装..."
            echo -e "${Msg_Info}正在安装必需环境 ..."
            dnf -y install wget unzip curl
            echo -e "${Msg_Info}正在下载BestTrace组件 ..."
            curl  --user-agent "${UA_LemonBench}" ${DownloadSrc} -o ${WorkDir}/besttrace.gz
            echo -e "${Msg_Info}正在安装BestTrace组件 ..."
            gzip -dN ${WorkDir}/besttrace.gz
            mv ${WorkDir}/besttrace /usr/local/bin/besttrace
            chmod +x /usr/local/bin/besttrace
            echo -e "${Msg_Info}正在清理环境 ..."
            rm -rf ${WorkDir}/besttrace.gz
        elif [ "${Var_OSRelease}" = "alpinelinux" ]; then
            echo -e "${Msg_Warning}未检测到BestTrace模块, 正在安装..."
            echo -e "${Msg_Info}正在安装必需环境 ..."
            apk update
            apk add wget unzip curl
            echo -e "${Msg_Info}正在下载BestTrace组件 ..."
            curl --user-agent "${UA_LemonBench}" ${DownloadSrc} -o ${WorkDir}/besttrace.gz
            echo -e "${Msg_Info}正在安装BestTrace组件 ..."
            gzip -dN ${WorkDir}/besttrace.gz
            mv ${WorkDir}/besttrace /usr/local/bin/besttrace
            chmod +x /usr/local/bin/besttrace
            echo -e "${Msg_Info}正在清理环境 ..."
            rm -rf ${WorkDir}/besttrace.gz
        else
            echo -e "${Msg_Warning}未检测到BestTrace模块, 但无法确定当前系统分支!"
        fi
    fi
    # 二次检测
    if [ ! -f "/usr/local/bin/besttrace" ]; then
        echo -e "BestTrace模块安装失败! 请尝试重启程序或者手动安装!"
        exit 1
    fi
}

# =============== 检查 JSON Query 组件 ===============
Check_JSONQuery() {
    if [ ! -f "/usr/bin/jq" ]; then
        SystemInfo_GetOSRelease
        SystemInfo_GetSystemBit
        if [ "${LBench_Result_SystemBit_Short}" = "64" ]; then
            local DownloadSrc="https://download.ilemonrain.com/LemonBench/include/jq/1.6/amd64/jq.tar.gz"
        elif [ "${LBench_Result_SystemBit_Short}" = "32" ]; then
            local DownloadSrc="https://download.ilemonrain.com/LemonBench/include/jq/1.6/i386/jq.tar.gz"
        else
            local DownloadSrc="https://download.ilemonrain.com/LemonBench/include/jq/1.6/i386/jq.tar.gz"
        fi
        mkdir -p ${WorkDir}/
        if [ "${Var_OSRelease}" = "centos" ] || [ "${Var_OSRelease}" = "rhel" ]; then
            echo -e "${Msg_Warning}未检测到JSON Query模块, 正在安装..."
            echo -e "${Msg_Info}正在安装必需环境 ..."
            yum install -y epel-release
            yum install -y jq
        elif [ "${Var_OSRelease}" = "ubuntu" ] || [ "${Var_OSRelease}" = "debian" ]; then
            echo -e "${Msg_Warning}未检测到JSON Query模块, 正在安装..."
            echo -e "${Msg_Info}正在安装必需环境 ..."
            apt-get update
            apt-get install -y jq
        elif [ "${Var_OSRelease}" = "fedora" ]; then
            echo -e "${Msg_Warning}未检测到JSON Query模块, 正在安装..."
            echo -e "${Msg_Info}正在安装必需环境 ..."
            dnf install -y jq
        elif [ "${Var_OSRelease}" = "alpinelinux" ]; then
            echo -e "${Msg_Warning}未检测到JSON Query模块, 正在安装..."
            echo -e "${Msg_Info}正在安装必需环境 ..."
            apk update
            apk add jq
        else
            echo -e "${Msg_Warning}未检测到JSON Query模块, 正在安装..."
            echo -e "${Msg_Info}正在安装必需环境 ..."
            apk update
            apk add wget unzip curl
            echo -e "${Msg_Info}正在下载JSON Query组件 ..."
            curl --user-agent "${UA_LemonBench}" ${DownloadSrc} -o ${WorkDir}/jq.tar.gz
            echo -e "${Msg_Info}正在安装JSON Query组件 ..."
            tar xvf ${WorkDir}/jq.tar.gz
            mv ${WorkDir}/jq/usr/bin/jq
            chmod +x /usr/local/bin/besttrace
            echo -e "${Msg_Info}正在清理环境 ..."
            rm -rf ${WorkDir}/jq.tar.gz
        fi
    fi
    # 二次检测
    if [ ! -f "/usr/bin/jq" ]; then
        echo -e "JSON Query模块安装失败! 请尝试重启程序或者手动安装!"
        exit 1
    fi
}

# =============== 检查 Spoofer 组件 ===============
Check_Spoofer() {
    # 如果是快速模式启动, 则跳过Spoofer相关检查及安装
    if [ "${Global_TestMode}" = "fast" ] || [ "${Global_TestMode}" = "full" ]; then
        return 0
    fi
    # 检测是否存在已安装的Spoofer模块
    if [ -f "/usr/local/bin/spoofer-prober" ]; then
        return 0
    else
        echo -e "${Msg_Warning}未检测到Spoofer模块, 正在安装..."
        Check_Spoofer_PreBuild
    fi
    # 如果预编译安装失败了, 则开始编译安装
    if [ ! -f "/usr/local/bin/spoofer-prober" ]; then
        echo -e "${Msg_Warning}Spoofer模块预编译安装失败, 正在尝试编译安装 ..."
        Check_Spoofer_InstantBuild
    fi
    # 如果编译安装仍然失败, 则停止运行
    if [ ! -f "/usr/local/bin/spoofer-prober" ]; then
        echo -e "${Msg_Error}Spoofer模块安装失败! 请尝试重启程序或者手动安装!"
        exit 1
    fi
}

Check_Spoofer_PreBuild() {
    # 获取系统信息
    SystemInfo_GetOSRelease
    SystemInfo_GetSystemBit
    # 判断CentOS分支
    if [ "${Var_OSRelease}" = "centos" ] || [ "${Var_OSRelease}" = "rhel" ]; then
        local SysRel="centos"
        # 判断系统位数
        if [ "${LBench_Result_SystemBit}" = "i386" ]; then
            local SysBit="i386"
        elif [ "${LBench_Result_SystemBit}" = "amd64" ]; then
            local SysBit="amd64"
        else
            local SysBit="unknown"
        fi
        # 判断版本号
        if [ "${Var_CentOSELRepoVersion}" = "6" ]; then
            local SysVer="6"
        elif [ "${Var_CentOSELRepoVersion}" = "7" ]; then
            local SysVer="7"
        else
            local SysVer="unknown"
        fi
    # 判断Debian分支
    elif [ "${Var_OSRelease}" = "debian" ]; then
        local SysRel="debian"
        # 判断系统位数
        if [ "${LBench_Result_SystemBit}" = "i386" ]; then
            local SysBit="i386"
        elif [ "${LBench_Result_SystemBit}" = "amd64" ]; then
            local SysBit="amd64"
        else
            local SysBit="unknown"
        fi
        # 判断版本号
        if [ "${Var_OSReleaseVersion_Short}" = "8" ]; then
            local SysVer="8"
        elif [ "${Var_OSReleaseVersion_Short}" = "9" ]; then
            local SysVer="9"
        else
            local SysVer="unknown"
        fi
    # 判断Ubuntu分支
    elif [ "${Var_OSRelease}" = "ubuntu" ]; then
        local SysRel="ubuntu"
        # 判断系统位数
        if [ "${LBench_Result_SystemBit}" = "i386" ]; then
            local SysBit="i386"
        elif [ "${LBench_Result_SystemBit}" = "amd64" ]; then
            local SysBit="amd64"
        else
            local SysBit="unknown"
        fi
        # 判断版本号
        if [ "${Var_OSReleaseVersion_Short}" = "14.04" ]; then
            local SysVer="14.04"
        elif [ "${Var_OSReleaseVersion_Short}" = "16.04" ]; then
            local SysVer="16.04"
        elif [ "${Var_OSReleaseVersion_Short}" = "18.04" ]; then
            local SysVer="18.04"
        elif [ "${Var_OSReleaseVersion_Short}" = "18.10" ]; then
            local SysVer="18.10"
        elif [ "${Var_OSReleaseVersion_Short}" = "19.04" ]; then
            local SysVer="19.04"
        else
            local SysVer="unknown"
        fi
    fi
    if [ "${SysBit}" = "i386" ] && [ "${SysVer}" != "unknown" ]; then
        echo -e "${Msg_Warning}预编译组件暂不支持32位系统, 正在启动即时编译 ..."
        Check_Spoofer_InstantBuild
    fi
    if [ "${SysBit}" = "unknown" ] || [ "${SysVer}" = "unknown" ]; then
        echo -e "${Msg_Warning}无法确认当前系统的版本号及位数, 或目前暂不支持预编译组件！"
    else
        if [ "${SysRel}" = "centos" ]; then
            echo -e "${Msg_Info}检测到系统: ${SysRel} ${SysVer} ${SysBit}"
            echo -e "${Msg_Info}正在安装必需组件 ..."
            yum install -y epel-release
            yum install -y protobuf-devel libpcap-devel openssl-devel traceroute wget curl
            local Spoofer_Version="$(curl  --user-agent "${UA_LemonBench}" -fskSL https://download.ilemonrain.com/LemonBench/include/Spoofer/latest_version)"
            echo -e "${Msg_Info}正在下载 Spoofer 预编译组件 (版本 ${Spoofer_Version}) ..."
            mkdir -p /tmp/_LBench/src/
            wget -U "${UA_LemonBench}" -O /tmp/_LBench/src/spoofer-prober.gz https://download.ilemonrain.com/LemonBench/include/Spoofer/${Spoofer_Version}/${SysRel}/${SysVer}/${SysBit}/spoofer-prober.gz
            echo -e "${Msg_Info}正在安装 Spoofer 组件 ..."
            gzip -dN /tmp/_LBench/src/spoofer-prober.gz
            cp -f /tmp/_LBench/src/spoofer-prober /usr/local/bin/spoofer-prober
            chmod +x /usr/local/bin/spoofer-prober
            echo -e "${Msg_Info}正在清理临时文件 ..."
            rm -f /tmp/_LBench/src/spoofer-prober.tar.gz
            rm -f /tmp/_LBench/src/spoofer-prober
        elif [ "${SysRel}" = "ubuntu" ] || [ "${SysRel}" = "debian" ]; then
            echo -e "${Msg_Info}检测到系统: ${SysRel} ${SysVer} ${SysBit}"
            echo -e "${Msg_Info}正在安装必需组件 ..."
            apt-get update
            apt-get install --no-install-recommends -y ca-certificates libprotobuf-dev libpcap-dev traceroute wget curl
            local Spoofer_Version="$(curl  --user-agent "${UA_LemonBench}" -fskSL https://download.ilemonrain.com/LemonBench/include/Spoofer/latest_version)"
            echo -e "${Msg_Info}正在下载 Spoofer 预编译组件 (版本 ${Spoofer_Version}) ..."
            mkdir -p /tmp/_LBench/src/
            wget -U "${UA_LemonBench}" -O /tmp/_LBench/src/spoofer-prober.gz https://download.ilemonrain.com/LemonBench/include/Spoofer/${Spoofer_Version}/${SysRel}/${SysVer}/${SysBit}/spoofer-prober.gz
            echo -e "${Msg_Info}正在安装 Spoofer ..."
            gzip -dN /tmp/_LBench/src/spoofer-prober.gz
            cp -f /tmp/_LBench/src/spoofer-prober /usr/local/bin/spoofer-prober
            chmod +x /usr/local/bin/spoofer-prober
            echo -e "${Msg_Info}正在清理临时文件 ..."
            rm -f /tmp/_LBench/src/spoofer-prober.tar.gz
            rm -f /tmp/_LBench/src/spoofer-prober
        else
            echo -e "${Msg_Warning}无法确认当前系统的版本号及位数, 或目前暂不支持预编译组件！"
        fi
    fi
}

Check_Spoofer_InstantBuild() {
    SystemInfo_GetOSRelease
    SystemInfo_GetCPUInfo
    if [ "${Var_OSRelease}" = "centos" ] || [ "${Var_OSRelease}" = "rhel" ]; then
        echo -e "${Msg_Info}已检测到系统: ${Var_OSRelease}"
        echo -e "${Msg_Info}正在准备编译环境 ..."
        yum install -y epel-release
        yum install -y wget curl make gcc gcc-c++ traceroute openssl-devel protobuf-devel bison flex libpcap-devel
        local Spoofer_Version="$(curl  --user-agent "${UA_LemonBench}"  -fskSL https://download.ilemonrain.com/LemonBench/include/Spoofer/latest_version)"
        echo -e "${Msg_Info}正在下载源码包 (版本 ${Spoofer_Version})..."
        mkdir -p /tmp/_LBench/src/
        wget -U "${UA_LemonBench}" -qO /tmp/_LBench/src/spoofer.tar.gz https://download.ilemonrain.com/LemonBench/include/Spoofer/${Spoofer_Version}/spoofer.tar.gz
        echo -e "${Msg_Info}正在编译安装 Spoofer 组件..."
        cd /tmp/_LBench/src/
        tar xvf spoofer.tar.gz && cd spoofer-"${Spoofer_Version}"
        # 测试性补丁
        wget -U "${UA_LemonBench}" -qO /tmp/_LBench/src/configure.patch https://download.ilemonrain.com/LemonBench/include/Spoofer/${Spoofer_Version}/patch/configure.patch
        patch -p0 configure /tmp/_LBench/src/configure.patch
        ./configure && make -j ${LBench_Result_CPUThreadNumber}
        cp prober/spoofer-prober /usr/local/bin/spoofer-prober
        echo -e "${Msg_Info}正在清理临时文件 ..."
        cd /tmp && rm -rf /tmp/_LBench/src/spoofer*
    elif [ "${Var_OSRelease}" = "ubuntu" ] || [ "${Var_OSRelease}" = "debian" ]; then
        echo -e "${Msg_Info}已检测到系统: ${Var_OSRelease}"
        echo -e "${Msg_Info}正在准备编译环境 ..."
        apt-get update
        apt-get install -y --no-install-recommends wget curl gcc g++ make traceroute protobuf-compiler libpcap-dev libprotobuf-dev openssl libssl-dev ca-certificates
        local Spoofer_Version="$(curl --user-agent "${UA_LemonBench}"  -fskSL https://download.ilemonrain.com/LemonBench/include/Spoofer/latest_version)"
        echo -e "${Msg_Info}正在下载源码包 (版本 ${Spoofer_Version})..."
        mkdir -p /tmp/_LBench/src/
        wget -U "${UA_LemonBench}" -qO /tmp/_LBench/src/spoofer.tar.gz https://download.ilemonrain.com/LemonBench/include/Spoofer/${Spoofer_Version}/spoofer.tar.gz
        echo -e "${Msg_Info}正在编译安装 Spoofer 组件..."
        cd /tmp/_LBench/src/
        tar xvf spoofer.tar.gz && cd spoofer-"${Spoofer_Version}"
        # 测试性补丁
        wget -U "${UA_LemonBench}" -qO /tmp/_LBench/src/configure.patch https://download.ilemonrain.com/LemonBench/include/Spoofer/${Spoofer_Version}/patch/configure.patch
        patch -p0 configure /tmp/_LBench/src/configure.patch
        ./configure && make -j ${LBench_Result_CPUThreadNumber}
        cp prober/spoofer-prober /usr/local/bin/spoofer-prober
        echo -e "${Msg_Info}正在清理临时文件 ..."
        cd /tmp && rm -rf /tmp/_LBench/src/spoofer*
    elif [ "${Var_OSRelease}" = "fedora" ]; then
        echo -e "${Msg_Info}已检测到系统: ${Var_OSRelease}"
        echo -e "${Msg_Info}正在准备编译环境 ..."
        dnf install -y wget curl make gcc gcc-c++ traceroute openssl-devel protobuf-devel bison flex libpcap-devel
        local Spoofer_Version="$(curl --user-agent "${UA_LemonBench}" -fskSL https://download.ilemonrain.com/LemonBench/include/Spoofer/latest_version)"
        echo -e "${Msg_Info}正在下载源码包 (版本 ${Spoofer_Version})..."
        mkdir -p /tmp/_LBench/src/
        wget -U "${UA_LemonBench}" -qO /tmp/_LBench/src/spoofer.tar.gz https://download.ilemonrain.com/LemonBench/include/Spoofer/${Spoofer_Version}/spoofer.tar.gz
        echo -e "${Msg_Info}正在编译安装 Spoofer ..."
        cd /tmp/_LBench/src/
        tar xvf spoofer.tar.gz && cd spoofer-"${Spoofer_Version}"
        # 测试性补丁
        wget -U "${UA_LemonBench}" -qO /tmp/_LBench/src/configure.patch https://download.ilemonrain.com/LemonBench/include/Spoofer/${Spoofer_Version}/patch/configure.patch
        patch -p0 configure /tmp/_LBench/src/configure.patch
        ./configure && make -j ${LBench_Result_CPUThreadNumber}
        cp prober/spoofer-prober /usr/local/bin/spoofer-prober
        echo -e "${Msg_Info}正在清理临时文件 ..."
        cd /tmp && rm -rf /tmp/_LBench/src/spoofer*
    elif [ "${Var_OSRelease}" = "alpinelinux" ]; then
        echo -e "${Msg_Info}已检测到系统: ${Var_OSRelease}"
        echo -e "${Msg_Info}正在准备编译环境 ..."
        apk update
        apk add traceroute gcc g++ make openssl-dev protobuf-dev libpcap-dev
        local Spoofer_Version="$(curl  --user-agent "${UA_LemonBench}"  -fskSL https://download.ilemonrain.com/LemonBench/include/Spoofer/latest_version)"
        echo -e "${Msg_Info}正在下载源码包 (版本 ${Spoofer_Version})..."
        mkdir -p /tmp/_LBench/src/
        wget -U "${UA_LemonBench}" -qO /tmp/_LBench/src/spoofer.tar.gz https://download.ilemonrain.com/LemonBench/include/Spoofer/${Spoofer_Version}/spoofer.tar.gz
        echo -e "${Msg_Info}正在编译安装 Spoofer ..."
        cd /tmp/_LBench/src/
        tar xvf spoofer.tar.gz && cd spoofer-"${Spoofer_Version}"
        # 测试性补丁
        wget -U "${UA_LemonBench}" -qO /tmp/_LBench/src/configure.patch https://download.ilemonrain.com/LemonBench/include/Spoofer/${Spoofer_Version}/patch/configure.patch
        patch -p0 configure /tmp/_LBench/src/configure.patch
        ./configure && make -j ${LBench_Result_CPUThreadNumber}
        cp prober/spoofer-prober /usr/local/bin/spoofer-prober
        echo -e "${Msg_Info}正在清理临时文件 ..."
        cd /tmp && rm -rf /tmp/_LBench/src/spoofer*
    else
        echo -e "${Msg_Error}程序不支持当前系统的编译运行！ (目前仅支持 CentOS/Debian/Ubuntu/Fedora/AlpineLinux) "
    fi
}

# =============== 检查 SysBench 组件 ===============
Check_SysBench() {
    if [ ! -f "/usr/bin/sysbench" ]; then
        SystemInfo_GetOSRelease
        SystemInfo_GetSystemBit
        if [ "${Var_OSRelease}" = "centos" ] || [ "${Var_OSRelease}" = "rhel" ]; then
            echo -e "${Msg_Warning}未检测到SysBench模块, 正在安装..."
            yum -y install epel-release
            yum -y install sysbench
        elif [ "${Var_OSRelease}" = "ubuntu" ]; then
            echo -e "${Msg_Warning}未检测到SysBench模块, 正在安装..."
            apt-get install -y sysbench
        elif [ "${Var_OSRelease}" = "debian" ]; then
            echo -e "${Msg_Warning}未检测到SysBench模块, 正在安装..."
            apt-get install -y sysbench
            if [ "$?" != "0" ]; then
                echo -e "${Msg_Warning}从当前Debian镜像源下载Sysbench模块失败, 正在尝试获取deb包 ..."
                local mirrorbase="https://download.ilemonrain.com/LemonBench"
                local componentname="Sysbench"
                local version="1.0.17-1"
                local arch="debian"
                local codename="${Var_OSReleaseVersion_Codename}"
                local bit="${LBench_Result_SystemBit_Full}"
                local filenamebase="sysbench"
                local filename="${filenamebase}_${version}_${bit}.deb"
                local downurl="${mirrorbase}/include/${componentname}/${version}/${arch}/${codename}/${filename}"
                mkdir -p ${WorkDir}/download/
                pushd ${WorkDir}/download/
                wget -U "${UA_LemonBench}" -O ${filenamebase}_${version}_${bit}.deb ${downurl}
                apt-get install -y -f ./${filename}
                popd
                if [ ! -f "/usr/bin/sysbench" ]; then
                    echo -e "${Msg_Warning}Sysbench模块安装失败!"
                fi
            fi
        elif [ "${Var_OSRelease}" = "fedora" ]; then
            echo -e "${Msg_Warning}未检测到SysBench模块, 正在安装..."
            dnf -y install sysbench
        elif [ "${Var_OSRelease}" = "alpinelinux" ]; then
            echo -e "${Msg_Warning}未检测到SysBench模块, 正在安装..."
            echo -e "${Msg_Warning}SysBench模块目前暂不支持Alpine Linux, 正在跳过..."
            Var_Skip_SysBench="1"
        else
            echo -e "${Msg_Warning}未检测到SysBench模块, 但无法确定当前系统分支!"
        fi
    fi
    # 二次检测
    if [ ! -f "/usr/bin/sysbench" ] && [ "${Var_OSRelease}" != "alpinelinux" ]; then
        echo -e "${Msg_Error}SysBench模块安装失败! 请尝试重启程序或者手动安装!"
        exit 1
    fi
}

# =============== 全局启动信息 ===============
Global_Startup_Header() {
    echo -e "
 ${Font_Green}#-----------------------------------------------------------#${Font_Suffix}
 ${Font_Green}@${Font_Suffix}   ${Font_Blue}LBench${Font_Suffix} ${Font_Yellow}服务器测试工具${Font_Suffix}  ${Font_SkyBlue}LemonBench${Font_Suffix} ${Font_Yellow}Server Test Toolkit${Font_Suffix}   ${Font_Green}@${Font_Suffix}
 ${Font_Green}#-----------------------------------------------------------#${Font_Suffix}
 ${Font_Green}@${Font_Suffix} ${Font_Purple}Written by${Font_Suffix} ${Font_SkyBlue}iLemonrain${Font_Suffix} ${Font_Blue}<ilemonrain@ilemonrain.com>${Font_Suffix}         ${Font_Green}@${Font_Suffix}
 ${Font_Green}@${Font_Suffix} ${Font_Purple}My Blog:${Font_Suffix} ${Font_SkyBlue}https://ilemonrain.com${Font_Suffix}                           ${Font_Green}@${Font_Suffix}
 ${Font_Green}@${Font_Suffix} ${Font_Purple}Telegram:${Font_Suffix} ${Font_SkyBlue}https://t.me/ilemonrain${Font_Suffix}                         ${Font_Green}@${Font_Suffix}
 ${Font_Green}@${Font_Suffix} ${Font_Purple}Telegram (For +86 User):${Font_Suffix} ${Font_SkyBlue}https://t.me/ilemonrain_chatbot${Font_Suffix}  ${Font_Green}@${Font_Suffix}
 ${Font_Green}@${Font_Suffix} ${Font_Purple}Telegram Channel:${Font_Suffix} ${Font_SkyBlue}https://t.me/ilemonrain_channel${Font_Suffix}         ${Font_Green}@${Font_Suffix}
 ${Font_Green}#-----------------------------------------------------------#${Font_Suffix}

 Version: ${BuildTime}

 如需反馈BUG, 请通过：
 https://t.me/ilemonrain 或 https://t.me/ilemonrain_chatbot
 联系我, 谢谢你们的支持！

 使用方法 (任选其一):
 (1) wget -qO- https://ilemonrain.com/download/shell/LemonBench.sh | bash
 (2) curl -fsL https://ilemonrain.com/download/shell/LemonBench.sh | bash

"
}

# =============== 入口 - 快速测试 (fast) ===============
Entrance_FastBench() {
    Global_TestMode="fast"
    Global_TestModeTips="快速测试"
    Global_StartupInit_Action
    Function_GetSystemInfo
    Function_BenchStart
    Function_ShowSystemInfo
    Function_ShowNetworkInfo
    Function_MediaUnlockTest
    Function_SysBench_CPU_Fast
    Function_SysBench_Memory_Fast
    Function_DiskTest_Fast
    Function_Speedtest_Fast
    Function_BestTrace_Fast
    Function_BenchFinish
    Function_GenerateResult
    Global_Exit_Action
}

# =============== 入口 - 完全测试 (full) ===============
Entrance_FullBench() {
    Global_TestMode="full"
    Global_TestModeTips="全面测试"
    Global_StartupInit_Action
    Function_GetSystemInfo
    Function_BenchStart
    Function_ShowSystemInfo
    Function_ShowNetworkInfo
    Function_MediaUnlockTest
    Function_SysBench_CPU_Full
    Function_SysBench_Memory_Full
    Function_DiskTest_Full
    Function_Speedtest_Full
    Function_BestTrace_Full
    Function_BenchFinish
    Function_GenerateResult
    Global_Exit_Action
}

# =============== 入口 - 仅Speedtest测试-快速模式 (spfast) ===============
Entrance_Speedtest_Fast() {
    Global_Startup_Header
    Global_TestMode="speedtest-fast"
    Global_TestModeTips="仅Speedtest测试 (快速测试)"
    Function_BenchStart
    Check_Speedtest
    Function_Speedtest_Fast
    Function_BenchFinish
    Function_GenerateResult
    Global_Exit_Action
}

# =============== 入口 - 仅Speedtest测试-全面模式 (spfull) ===============
Entrance_Speedtest_Full() {
    Global_Startup_Header
    Global_TestMode="speedtest-full"
    Global_TestModeTips="仅Speedtest测试 (全面测试)"
    Check_Speedtest
    Function_BenchStart
    Function_Speedtest_Full
    Function_BenchFinish
    Function_GenerateResult
    Global_Exit_Action
}

# =============== 入口 - 仅磁盘性能测试-快速模式 (dtfast) ===============
Entrance_DiskTest_Fast() {
    Global_Startup_Header
    Global_TestMode="disktest-fast"
    Global_TestModeTips="仅磁盘性能测试 (快速测试)"
    Function_BenchStart
    Function_DiskTest_Fast
    Function_BenchFinish
    Function_GenerateResult
    Global_Exit_Action
}

# =============== 入口 - 仅磁盘性能测试-全面模式 (dtfull) ===============
Entrance_DiskTest_Full() {
    Global_Startup_Header
    Global_TestMode="disktest-full"
    Global_TestModeTips="仅磁盘性能测试 (全面测试)"
    Function_BenchStart
    Function_DiskTest_Full
    Function_BenchFinish
    Function_GenerateResult
    Global_Exit_Action
}

# =============== 入口 - 仅路由追踪测试-快速模式 (btfast) ===============
Entrance_BestTrace_Fast() {
    Global_Startup_Header
    Global_TestMode="besttrace-fast"
    Global_TestModeTips="仅路由追踪测试 (快速测试)"
    Check_BestTrace
    echo -e "${Msg_Info}正在获取网络信息 ..."
    SystemInfo_GetNetworkInfo
    Function_BenchStart
    Function_ShowNetworkInfo
    Function_BestTrace_Fast
    Function_BenchFinish
    Function_GenerateResult
    Global_Exit_Action
}

# =============== 入口 - 仅路由追踪测试-完全模式 (btfull) ===============
Entrance_BestTrace_Full() {
    Global_Startup_Header
    Global_TestMode="besttrace-full"
    Global_TestModeTips="仅路由追踪测试 (全面测试)"
    Check_BestTrace
    echo -e "${Msg_Info}正在获取网络信息 ..."
    SystemInfo_GetNetworkInfo
    Function_BenchStart
    Function_ShowNetworkInfo
    Function_BestTrace_Full
    Function_BenchFinish
    Function_GenerateResult
    Global_Exit_Action
}

# =============== 入口 - 仅Spoofer测试-快速模式 (spf) ===============
Entrance_Spoofer() {
    Global_Startup_Header
    Global_TestMode="spoofer"
    Global_TestModeTips="仅Spoofer测试"
    Check_Spoofer
    Function_BenchStart
    Function_SpooferTest
    Function_BenchFinish
    Function_GenerateResult
    Global_Exit_Action
}

# == 测试 ==
Entrance_DebugMode() {
    Global_Startup_Header
    Global_TestMode="debug"
    Global_TestModeTips="Debug Mode"
    Function_GetSystemInfo
    Function_BenchStart
    Function_ShowSystemInfo
    Function_ShowNetworkInfo
    Function_MediaUnlockTest
    Function_BenchFinish
    Function_GenerateResult
    Global_Exit_Action
}

#
Entrance_SysBench_CPU_Fast() {
    Global_Startup_Header
    Global_TestMode="sysbench-cpu-fast"
    Global_TestModeTips="仅CPU性能测试 (快速模式)"
    Check_SysBench
    Function_BenchStart
    SystemInfo_GetCPUInfo
    Function_SysBench_CPU_Fast
    Function_BenchFinish
    Function_GenerateResult
    Global_Exit_Action
}

Entrance_SysBench_CPU_Full() {
    Global_Startup_Header
    Global_TestMode="sysbench-cpu-full"
    Global_TestModeTips="仅CPU性能测试 (标准模式)"
    Check_SysBench
    Function_BenchStart
    SystemInfo_GetCPUInfo
    Function_SysBench_CPU_Full
    Function_BenchFinish
    Function_GenerateResult
    Global_Exit_Action
}

#
Entrance_SysBench_Memory_Fast() {
    Global_Startup_Header
    Global_TestMode="sysbench-memory-fast"
    Global_TestModeTips="仅内存性能测试 (快速模式)"
    Check_SysBench
    Function_BenchStart
    SystemInfo_GetCPUInfo
    Function_SysBench_Memory_Fast
    Function_BenchFinish
    Function_GenerateResult
    Global_Exit_Action
}

Entrance_SysBench_Memory_Full() {
    Global_Startup_Header
    Global_TestMode="sysbench-memory-full"
    Global_TestModeTips="仅内存性能测试 (标准模式)"
    Check_SysBench
    Function_BenchStart
    SystemInfo_GetCPUInfo
    Function_SysBench_Memory_Full
    Function_BenchFinish
    Function_GenerateResult
    Global_Exit_Action
}

# =============== 入口 - 帮助文档 (help) ===============
Entrance_HelpDocument() {
    echo -e "\n ${Font_Blue}LBench${Font_Suffix} ${Font_Yellow}服务器测试工具${Font_Suffix}  ${Font_SkyBlue}LemonBench${Font_Suffix} ${Font_Yellow}Server Test Toolkit${Font_Suffix} ${BuildTime}"
    echo -e "
 > ${Font_Green}帮助文档${Font_Suffix} ${Font_SkyBlue}HelpDocument${Font_Suffix}

 使用方法 Usage ：

 (1) ${Font_SkyBlue}wget -qO- https://ilemonrain.com/download/shell/LemonBench.sh | bash -s${Font_Suffix} ${Font_Yellow}[TestMode]${Font_Suffix}
 (2) ${Font_SkyBlue}curl -fsL https://ilemonrain.com/download/shell/LemonBench.sh | bash -s${Font_Suffix} ${Font_Yellow}[TestMode]${Font_Suffix}

 可选测试参数 Available Parameters :

   ${Font_SkyBlue}-f${Font_Suffix}, ${Font_SkyBlue}--fast${Font_Suffix}, ${Font_SkyBlue}fast${Font_Suffix} \t\t 执行快速测试
   ${Font_SkyBlue}-F${Font_Suffix}, ${Font_SkyBlue}--full${Font_Suffix}, ${Font_SkyBlue}full${Font_Suffix} \t\t 执行完整测试
   ${Font_SkyBlue}spfast${Font_Suffix}, ${Font_SkyBlue}--speedtest-fast${Font_Suffix} \t 仅执行Speedtest网速测试 (快速测试)
   ${Font_SkyBlue}spfull${Font_Suffix}, ${Font_SkyBlue}--speedtest-full${Font_Suffix} \t 仅执行Speedtest网速测试 (完整测试)
   ${Font_SkyBlue}dtfast${Font_Suffix}, ${Font_SkyBlue}--disktest-fast${Font_Suffix} \t 仅执行磁盘性能测试 (快速测试)
   ${Font_SkyBlue}dtfull${Font_Suffix}, ${Font_SkyBlue}--disktest-full${Font_Suffix} \t 仅执行磁盘性能测试 (完整测试)
   ${Font_SkyBlue}btfast${Font_Suffix}, ${Font_SkyBlue}--besttrace-fast${Font_Suffix} \t 仅执行路由追踪测试 (快速测试)
   ${Font_SkyBlue}btfull${Font_Suffix}, ${Font_SkyBlue}--besttrace-full${Font_Suffix} \t 仅执行路由追踪测试 (完整测试)
   ${Font_SkyBlue}spf${Font_Suffix}, ${Font_SkyBlue}--spoofer${Font_Suffix} \t\t 仅执行Spoofer测试
   ${Font_SkyBlue}sbcfast${Font_Suffix}, ${Font_SkyBlue}--sbcfast${Font_Suffix} \t\t 仅执行CPU性能测试 (快速模式)
   ${Font_SkyBlue}sbcfull${Font_Suffix}, ${Font_SkyBlue}--sbcfull${Font_Suffix} \t\t 仅执行CPU性能测试 (标准模式)

    "
    exit 0
}

# =============== 命令行参数 ===============
case "$1" in
-f | fast | -fast | --fast)
    Entrance_FastBench
    exit 0
    ;;
-F | full | -full | --full)
    Entrance_FullBench
    exit 0
    ;;
spfast | -spfast | --spfast | speedtest-fast | -speedtest-fast | --speedtest-fast)
    Entrance_Speedtest_Fast
    exit 0
    ;;
spfull | -spfull | --spfull | speedtest-full | -speedtest-full | --speedtest-full)
    Entrance_Speedtest_Full
    exit 0
    ;;
dtfast | -dtfast | --dtfast | disktest-fast | -disktest-fast | --disktest-fast)
    Entrance_DiskTest_Fast
    exit 0
    ;;
dtfull | -dtfull | --dtfull | disktest-full | -disktest-full | --disktest-full)
    Entrance_DiskTest_Full
    exit 0
    ;;
btfast | -btfast | --btfast | besttrace-fast | -besttrace-fast | --besttrace-fast)
    Entrance_BestTrace_Fast
    exit 0
    ;;
btfull | -btfull | --btfull | besttrace-full | -besttrace-full | --besttrace-full)
    Entrance_BestTrace_Full
    exit 0
    ;;
spf | -spf | --spf | spoof | -spoof | --spoof | spoofer | -spoofer | --spoofer)
    Entrance_Spoofer
    exit 0
    ;;
sbcfast | -sbcfast | --sbcfast | sysbench-cpu-fast | -sysbench-cpu-fast | --sysbench-cpu-fast)
    Entrance_SysBench_CPU_Fast
    exit 0
    ;;
sbcfull | -sbcfull | --sbcfull | sysbench-cpu-full | -sysbench-cpu-full | --sysbench-cpu-full)
    Entrance_SysBench_CPU_Full
    exit 0
    ;;
sbmfast | -sbmfast | --sbmfast | sysbench-memory-fast | -sysbench-memory-fast | --sysbench-memory-fast)
    Entrance_SysBench_Memory_Fast
    exit 0
    ;;
sbmfull | -sbmfull | --sbmfull | sysbench-memory-full | -sysbench-memory-full | --sysbench-memory-full)
    Entrance_SysBench_Memory_Full
    exit 0
    ;;
-h | -H | help | -help | --help)
    Entrance_HelpDocument
    exit 0
    ;;
debug)
    Entrance_DebugMode
    exit 0
    ;;
*)
    Entrance_HelpDocument
    exit 0
    ;;
esac
