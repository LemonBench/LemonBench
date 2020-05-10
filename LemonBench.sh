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
# | Donate Method 打赏方式:                                          |
# | Alipay QR Code: http://t.cn/EA3pZNt                              |
# | 支付宝二维码:http://t.cn/EA3pZNt                                 |
# | Wechat QR Code: http://t.cn/EA3p639                              |
# | 微信二维码: http://t.cn/EA3p639                                   |
# #------------------------------------------------------------------#
#
# 使用方法 (任选其一):
# (1) wget -O- https://ilemonrain.com/download/shell/LemonBench.sh | bash
# (2) curl -fsL https://ilemonrain.com/download/shell/LemonBench.sh | bash
#
# === 全局定义 =====================================

# 全局参数定义
BuildTime="20200426 Intl BetaVersion"
WorkDir="/tmp/.LemonBench"
UA_LemonBench="LemonBench/${BuildTime}"
UA_Browser="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.87 Safari/537.36"
UA_Dalvik="Dalvik/2.1.0 (Linux; U; Android 9; ALP-AL00 Build/HUAWEIALP-AL00)"

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
    echo -e "\n\n${Msg_Error}Caught Signal SIGHUP, Exiting ...\n"
    Global_TrapSigExit_Action
    exit 1
}

# Trap终止信号2 - 处理 (Ctrl+C)
Global_TrapSigExit_Sig2() {
    echo -e "\n\n${Msg_Error}Caught Signal SIGINT (or Ctrl+C), Exiting ...\n"
    Global_TrapSigExit_Action
    exit 1
}

# Trap终止信号3 - 处理
Global_TrapSigExit_Sig3() {
    echo -e "\n\n${Msg_Error}Caught Signal SIGQUIT, Exiting ...\n"
    Global_TrapSigExit_Action
    exit 1
}

# Trap终止信号15 - 处理 (进程被杀)
Global_TrapSigExit_Sig15() {
    echo -e "\n\n${Msg_Error}Caught Signal SIGTERM, Exiting ...\n"
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
        --data "expiration=${PASTEBIN_EXPIRATION:-}" \
        --data "syntax=${PASTEBIN_SYNTAX:-text}")"
    if [ "$?" = "0" ]; then
        echo -e "${Msg_Success}Report Generate Success！Please save the follwing link:"
        echo -e "${Msg_Info}Report URL: ${uploadresult}"
    else
        echo -e "${Msg_Warning}Report Generate Failure, But you can still read $HOME/LemonBench.Result.txt to get this result！"
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
    echo -e "${Msg_Info}Loaded Testmode:${Font_SkyBlue}${Global_TestModeTips}${Font_Suffix}"
    Function_CheckTracemode
    # 清理残留, 为新一次的运行做好准备
    echo -e "${Msg_Info}Initializing Running Enviorment, Please wait ..."
    rm -rf ${WorkDir}
    rm -rf /.tmp_LBench/
    mkdir ${WorkDir}/
    echo -e "${Msg_Info}Checking Dependency ..."
    Check_Virtwhat
    Check_JSONQuery
    Check_Speedtest
    Check_BestTrace
    Check_Spoofer
    Check_SysBench
    echo -e "${Msg_Info}Starting Test ...\n\n"
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

# ==================================================

# =============== -> 主程序开始 <- ==================

# =============== SystemInfo模块 部分 ===============
SystemInfo_GetHostname() {
    LBench_Result_Hostname="$(hostname)"
}


SystemInfo_GetCPUInfo() {
    mkdir -p ${WorkDir}/data >/dev/null 2>&1
    cat /proc/cpuinfo >${WorkDir}/data/cpuinfo
    local ReadCPUInfo="cat ${WorkDir}/data/cpuinfo"
    LBench_Result_CPUModelName="$($ReadCPUInfo | awk -F ': ' '/model name/{print $2}' | sort -u)"
    local CPUFreqCount="$($ReadCPUInfo | awk -F ': ' '/cpu MHz/{print $2}' | sort -run | wc -l)"
    if [ "${CPUFreqCount}" -ge "2" ]; then
        local CPUFreqArray="$(cat /proc/cpuinfo | awk -F ': ' '/cpu MHz/{print $2}' | sort -run)"
        local CPUFreq_Min="$(echo "$CPUFreqArray" | grep -oE '[0-9]+.[0-9]{3}' | awk 'BEGIN {min = 2147483647} {if ($1+0 < min+0) min=$1} END {print min}')"
        local CPUFreq_Max="$(echo "$CPUFreqArray" | grep -oE '[0-9]+.[0-9]{3}' | awk 'BEGIN {max = 0} {if ($1+0 > max+0) max=$1} END {print max}')"
        LBench_Result_CPUFreqMinGHz="$(echo $CPUFreq_Min | awk '{printf "%.2f\n",$1/1000}')"
        LBench_Result_CPUFreqMaxGHz="$(echo $CPUFreq_Max | awk '{printf "%.2f\n",$1/1000}')"
        Flag_DymanicCPUFreqDetected="1"
    else
        LBench_Result_CPUFreqMHz="$($ReadCPUInfo | awk -F ': ' '/cpu MHz/{print $2}' | sort -u)"
        LBench_Result_CPUFreqGHz="$(echo $LBench_Result_CPUFreqMHz | awk '{printf "%.2f\n",$1/1000}')"
        Flag_DymanicCPUFreqDetected="0"
    fi
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
    elif [ "${Var_VirtType}" = "kvm" ] || [ "${Var_VirtType}" = "hyperv" ] || [ "${Var_VirtType}" = "microsoft" ] || [ "${Var_VirtType}" = "vmware" ]; then
        LBench_Result_CPUIsPhysical="0"
        local VirtCheck="$(cat /proc/cpuinfo | grep -oE 'vmx|svm' | uniq)"
        if [ "${VirtCheck}" = "vmx" ] || [ "${VirtCheck}" = "svm" ]; then
            LBench_Result_CPUVirtualization="2"
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
    LBench_Result_CPUStat_anice="$(Function_ReadCPUStat "${CPUStat_Result}" "ni")"
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

SystemInfo_GetKernelVersion() {
    local version="$(uname -r)"
    LBench_Result_KernelVersion="${version}"
}

SystemInfo_GetNetworkCCMethod() {
    local val_cc="$(sysctl -n net.ipv4.tcp_congestion_control)"
    local val_qdisc="$(sysctl -n net.core.default_qdisc)"
    LBench_Result_NetworkCCMethod="${val_cc} + ${val_qdisc}"
}

SystemInfo_GetSystemBit() {
    local sysarch="$(uname -m)"
    if [ "${sysarch}" = "unknown" ] || [ "${sysarch}" = "" ]; then
        local sysarch="$(arch)"
    fi
    if [ "${sysarch}" = "x86_64" ]; then
        # X86平台 64位
        LBench_Result_SystemBit_Short="64"
        LBench_Result_SystemBit_Full="amd64"
    elif [ "${sysarch}" = "i386" ] || [ "${sysarch}" = "i686" ]; then
        # X86平台 32位
        LBench_Result_SystemBit_Short="32"
        LBench_Result_SystemBit_Full="i386"
    elif [ "${sysarch}" = "armv7l" ] || [ "${sysarch}" = "armv8" ] || [ "${sysarch}" = "armv8l" ] || [ "${sysarch}" = "aarch64" ]; then
        # ARM平台 暂且将32位/64位统一对待
        LBench_Result_SystemBit_Short="arm"
        LBench_Result_SystemBit_Full="arm"
    else
        LBench_Result_SystemBit_Short="unknown"
        LBench_Result_SystemBit_Full="unknown"                
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
        LBench_Result_OSReleaseFullName="[Error: Unknown Linux Branch !]"
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
            LBench_Result_VirtType="Xen Hypervisor"
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
            Var_VirtType="dedicated"
            LBench_Result_VirtType="None"
            local Var_BIOSVendor="$(dmidecode -s bios-vendor)"
            if [ "${Var_BIOSVendor}" = "SeaBIOS" ]; then
                Var_VirtType="Unknown"
                LBench_Result_VirtType="Unknown with SeaBIOS BIOS"
            else
                Var_VirtType="dedicated"
                LBench_Result_VirtType="Dedicated with ${Var_BIOSVendor} BIOS"
            fi
        fi
    elif [ ! -f "/usr/sbin/virt-what" ]; then
        Var_VirtType="Unknown"
        LBench_Result_VirtType="[Error: virt-what not found !]"
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

SystemInfo_GetUptime() {
    local ut="$(cat /proc/uptime | awk '{printf "%d\n",$1}')"
    local ut_day="$(echo $result | awk -v ut="$ut" '{printf "%d\n",ut/86400}')"
    local ut_hour="$(echo $result | awk -v ut="$ut" -v ut_day="$ut_day" '{printf "%d\n",(ut-(86400*ut_day))/3600}')"
    local ut_minute="$(echo $result | awk -v ut="$ut" -v ut_day="$ut_day" -v ut_hour="$ut_hour" '{printf "%d\n",(ut-(86400*ut_day)-(3600*ut_hour))/60}')"
    local ut_second="$(echo $result | awk -v ut="$ut" -v ut_day="$ut_day" -v ut_hour="$ut_hour" -v ut_minute="$ut_minute" '{printf "%d\n",(ut-(86400*ut_day)-(3600*ut_hour)-(60*ut_minute))}')"
    LBench_Result_SystemInfo_Uptime_Day="$ut_day"
    LBench_Result_SystemInfo_Uptime_Hour="$ut_hour"
    LBench_Result_SystemInfo_Uptime_Minute="$ut_minute"
    LBench_Result_SystemInfo_Uptime_Second="$ut_second"
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
    local Result_IPV4="$(curl --connect-timeout 10 -fsL4 https://api.ilemonrain.com/LemonBench/ipgeo.php)"
    local Result_IPV6="$(curl --connect-timeout 10 -fsL6 https://api.ilemonrain.com/LemonBench/ipgeo.php)"
    if [ "${Result_IPV4}" != "" ] && [ "${Result_IPV6}" = "" ]; then
        LBench_Result_NetworkStat="ipv4only"
    elif [ "${Result_IPV4}" = "" ] && [ "${Result_IPV6}" != "" ]; then
        LBench_Result_NetworkStat="ipv6only"
    elif [ "${Result_IPV4}" != "" ] && [ "${Result_IPV6}" != "" ]; then
        LBench_Result_NetworkStat="dualstack"
    else
        LBench_Result_NetworkStat="unknown"
    fi
    if [ "${LBench_Result_NetworkStat}" = "ipv4only" ] || [ "${LBench_Result_NetworkStat}" = "dualstack" ]; then
        IPAPI_IPV4_ip="$(PharseJSON "${Result_IPV4}" "ip")"
        IPAPI_IPV4_location="$(PharseJSON "${Result_IPV4}" "location")"
        IPAPI_IPV4_country_code="$(PharseJSON "${Result_IPV4}" "country_code")"
        IPAPI_IPV4_asn="$(PharseJSON "${Result_IPV4}" "asn")"
        IPAPI_IPV4_organization="$(PharseJSON "${Result_IPV4}" "organization")"
    fi
    if [ "${LBench_Result_NetworkStat}" = "ipv6only" ] || [ "${LBench_Result_NetworkStat}" = "dualstack" ]; then
        IPAPI_IPV6_ip="$(PharseJSON "${Result_IPV6}" "ip")"
        IPAPI_IPV6_location="$(PharseJSON "${Result_IPV6}" "location")"
        IPAPI_IPV6_country_code="$(PharseJSON "${Result_IPV6}" "country_code")"
        IPAPI_IPV6_asn="$(PharseJSON "${Result_IPV6}" "asn")"
        IPAPI_IPV6_organization="$(PharseJSON "${Result_IPV6}" "organization")"
    fi
    if [ "${LBench_Result_NetworkStat}" = "unknown" ]; then
        IPAPI_IPV4_ip="-"
        IPAPI_IPV4_location="-"
        IPAPI_IPV4_country_code="-"
        IPAPI_IPV4_asn="-"
        IPAPI_IPV4_organization="-"
        IPAPI_IPV6_ip="-"
        IPAPI_IPV6_location="-"
        IPAPI_IPV6_country_code="-"
        IPAPI_IPV6_asn="-"
        IPAPI_IPV6_organization="-"
    fi
}

Function_GetSystemInfo() {
    clear
    echo -e "${Msg_Info}LemonBench Server Test Toolkit Build ${BuildTime}"
    echo -e "${Msg_Info}SystemInfo - Collecting System Information ..."
    Check_Virtwhat
    echo -e "${Msg_Info}Collecting CPU Info ..."
    SystemInfo_GetCPUInfo
    SystemInfo_GetLoadAverage
    SystemInfo_GetSystemBit
    SystemInfo_GetCPUStat
    echo -e "${Msg_Info}Collecting Memory Info ..."
    SystemInfo_GetMemInfo
    echo -e "${Msg_Info}Collecting Virtualization Info ..."
    SystemInfo_GetVirtType
    echo -e "${Msg_Info}Collecting System Info ..."
    SystemInfo_GetUptime
    SystemInfo_GetKernelVersion
    echo -e "${Msg_Info}Collecting OS Release Info ..."
    SystemInfo_GetOSRelease
    echo -e "${Msg_Info}Collecting Disk Info ..."
    SystemInfo_GetDiskStat
    echo -e "${Msg_Info}Collecting Network Info ..."
    SystemInfo_GetNetworkCCMethod
    SystemInfo_GetNetworkInfo
    echo -e "${Msg_Info}Starting Test ..."
    clear
}

Function_ShowSystemInfo() {
    echo -e "\n ${Font_Yellow}-> System Information${Font_Suffix}\n"
    if [ "${Var_OSReleaseVersion_Codename}" != "" ]; then
        echo -e " ${Font_Yellow}OS Release:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_OSReleaseFullName}${Font_Suffix}"
    else
        echo -e " ${Font_Yellow}OS Release:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_OSReleaseFullName}${Font_Suffix}"
    fi
    if [ "${Flag_DymanicCPUFreqDetected}" = "1" ]; then
        echo -e " ${Font_Yellow}CPU Model:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_CPUModelName}${Font_Suffix}  ${Font_White}${LBench_Result_CPUFreqMinGHz}~${LBench_Result_CPUFreqMaxGHz}${Font_Suffix}${Font_SkyBlue} GHz${Font_Suffix}"
    elif [ "${Flag_DymanicCPUFreqDetected}" = "0" ]; then
        echo -e " ${Font_Yellow}CPU Model:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_CPUModelName}  ${LBench_Result_CPUFreqGHz} GHz${Font_Suffix}"
    fi
    if [ "${LBench_Result_CPUCacheSize}" != "" ]; then
        echo -e " ${Font_Yellow}CPU Cache Size:${Font_Suffix}\t${Font_SkyBlue}${LBench_Result_CPUCacheSize}${Font_Suffix}"
    else
        echo -e " ${Font_Yellow}CPU Cache Size:${Font_Suffix}\t${Font_SkyBlue}None${Font_Suffix}"
    fi
    # CPU数量 分支判断
    if [ "${LBench_Result_CPUIsPhysical}" = "1" ]; then
        # 如果只存在1个物理CPU (单路物理服务器)
        if [ "${LBench_Result_CPUPhysicalNumber}" -eq "1" ]; then
            echo -e " ${Font_Yellow}CPU Number:${Font_Suffix}\t\t${LBench_Result_CPUPhysicalNumber} ${Font_SkyBlue}Physical CPU${Font_Suffix}, ${LBench_Result_CPUCoreNumber} ${Font_SkyBlue}Cores${Font_Suffix}, ${LBench_Result_CPUThreadNumber} ${Font_SkyBlue}Threads${Font_Suffix}"
        # 存在多个CPU, 继续深入分析检测 (多路物理服务器)
        elif [ "${LBench_Result_CPUPhysicalNumber}" -ge "2" ]; then
            echo -e " ${Font_Yellow}CPU Number:${Font_Suffix}\t\t${LBench_Result_CPUPhysicalNumber} ${Font_SkyBlue}Physical CPU(s)${Font_Suffix}, ${LBench_Result_CPUCoreNumber} ${Font_SkyBlue}Cores/CPU${Font_Suffix}, ${LBench_Result_CPUSiblingsNumber} ${Font_SkyBlue}Threads/CPU${Font_Suffix} (Total ${Font_SkyBlue}${LBench_Result_CPUTotalCoreNumber}${Font_Suffix} Cores, ${Font_SkyBlue}${LBench_Result_CPUProcessorNumber}${Font_Suffix} Threads)"
        # 针对树莓派等特殊情况做出检测优化
        elif [ "${LBench_Result_CPUThreadNumber}" = "0" ] && [ "${LBench_Result_CPUProcessorNumber} " -ge "1" ]; then
             echo -e " ${Font_Yellow}CPU Number:${Font_Suffix}\t\t${LBench_Result_CPUProcessorNumber} ${Font_SkyBlue}Cores${Font_Suffix}"
        fi
        if [ "${LBench_Result_CPUVirtualization}" = "1" ]; then
            echo -e " ${Font_Yellow}VirtReady:${Font_Suffix}\t\t${Font_SkyBlue}Yes${Font_Suffix} ${Font_SkyBlue}(Based on${Font_Suffix} ${LBench_Result_CPUVirtualizationType}${Font_SkyBlue})${Font_Suffix}"
        else
            echo -e " ${Font_Yellow}VirtReady:${Font_Suffix}\t\t${Font_SkyRed}No${Font_Suffix}"
        fi
    elif [ "${Var_VirtType}" = "openvz" ]; then
        echo -e " ${Font_Yellow}CPU Number:${Font_Suffix}\t\t${LBench_Result_CPUThreadNumber} ${Font_SkyBlue}vCPU${Font_Suffix} (${LBench_Result_CPUCoreNumber} ${Font_SkyBlue}Host Core/Thread${Font_Suffix})"
    else
        if [ "${LBench_Result_CPUVirtualization}" = "2" ]; then
            echo -e " ${Font_Yellow}CPU Number:${Font_Suffix}\t\t${LBench_Result_CPUThreadNumber} ${Font_SkyBlue}vCPU${Font_Suffix}"
            echo -e " ${Font_Yellow}VirtReady:${Font_Suffix}\t\t${Font_SkyBlue}Yes${Font_Suffix} ${Font_SkyBlue}(Nested Virtualization)${Font_Suffix}"
        else
            echo -e " ${Font_Yellow}CPU Number:${Font_Suffix}\t\t${LBench_Result_CPUThreadNumber} ${Font_SkyBlue}vCPU${Font_Suffix}"
        fi
    fi
    echo -e " ${Font_Yellow}Virt Type:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_VirtType}${Font_Suffix}"
    # 内存使用率 分支判断
    if [ "${LBench_Result_MemoryUsed_KB}" -lt "1024" ] && [ "${LBench_Result_MemoryTotal_KB}" -lt "1048576" ]; then
        LBench_Result_Memory="${LBench_Result_MemoryUsed_KB} KB / ${LBench_Result_MemoryTotal_MB} MB"
        echo -e " ${Font_Yellow}Memory Usage:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_MemoryUsed_MB} KB${Font_Suffix} / ${Font_SkyBlue}${LBench_Result_MemoryTotal_MB} MB${Font_Suffix}"
    elif [ "${LBench_Result_MemoryUsed_KB}" -lt "1048576" ] && [ "${LBench_Result_MemoryTotal_KB}" -lt "1048576" ]; then
        LBench_Result_Memory="${LBench_Result_MemoryUsed_MB} MB / ${LBench_Result_MemoryTotal_MB} MB"
        echo -e " ${Font_Yellow}Memory Usage:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_MemoryUsed_MB} MB${Font_Suffix} / ${Font_SkyBlue}${LBench_Result_MemoryTotal_MB} MB${Font_Suffix}"
    elif [ "${LBench_Result_MemoryUsed_KB}" -lt "1048576" ] && [ "${LBench_Result_MemoryTotal_KB}" -lt "1073741824" ]; then
        LBench_Result_Memory="${LBench_Result_MemoryUsed_MB} MB / ${LBench_Result_MemoryTotal_GB} GB"
        echo -e " ${Font_Yellow}Memory Usage:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_MemoryUsed_MB} MB${Font_Suffix} / ${Font_SkyBlue}${LBench_Result_MemoryTotal_GB} GB${Font_Suffix}"
    else
        LBench_Result_Memory="${LBench_Result_MemoryUsed_GB} GB / ${LBench_Result_MemoryTotal_GB} GB"
        echo -e " ${Font_Yellow}Memory Usage:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_MemoryUsed_GB} GB${Font_Suffix} / ${Font_SkyBlue}${LBench_Result_MemoryTotal_GB} GB${Font_Suffix}"
    fi
    # Swap使用率 分支判断
    if [ "${LBench_Result_SwapTotal_KB}" -eq "0" ]; then
        LBench_Result_Swap="[ No Swapfile / Swap partition ]"
        echo -e " ${Font_Yellow}Swap Usage:${Font_Suffix}\t\t${Font_SkyBlue}[ No Swapfile/Swap Partition ]${Font_Suffix}"
    elif [ "${LBench_Result_SwapUsed_KB}" -lt "1024" ] && [ "${LBench_Result_SwapTotal_KB}" -lt "1048576" ]; then
        LBench_Result_Swap="${LBench_Result_SwapUsed_KB} KB / ${LBench_Result_SwapTotal_MB} MB"
        echo -e " ${Font_Yellow}Swap Usage:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_SwapUsed_KB} KB${Font_Suffix} / ${Font_SkyBlue}${LBench_Result_SwapTotal_MB} MB${Font_Suffix}"
    elif [ "${LBench_Result_SwapUsed_KB}" -lt "1024" ] && [ "${LBench_Result_SwapTotal_KB}" -lt "1073741824" ]; then
        LBench_Result_Swap="${LBench_Result_SwapUsed_KB} KB / ${LBench_Result_SwapTotal_GB} GB"
        echo -e " ${Font_Yellow}Swap Usage:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_SwapUsed_KB} KB${Font_Suffix} / ${Font_SkyBlue}${LBench_Result_SwapTotal_GB} GB${Font_Suffix}"
    elif [ "${LBench_Result_SwapUsed_KB}" -lt "1048576" ] && [ "${LBench_Result_SwapTotal_KB}" -lt "1048576" ]; then
        LBench_Result_Swap="${LBench_Result_SwapUsed_MB} MB / ${LBench_Result_SwapTotal_MB} MB"
        echo -e " ${Font_Yellow}Swap Usage:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_SwapUsed_MB} MB${Font_Suffix} / ${Font_SkyBlue}${LBench_Result_SwapTotal_MB} MB${Font_Suffix}"
    elif [ "${LBench_Result_SwapUsed_KB}" -lt "1048576" ] && [ "${LBench_Result_SwapTotal_KB}" -lt "1073741824" ]; then
        LBench_Result_Swap="${LBench_Result_SwapUsed_MB} MB / ${LBench_Result_SwapTotal_GB} GB"
        echo -e " ${Font_Yellow}Swap Usage:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_SwapUsed_MB} MB${Font_Suffix} / ${Font_SkyBlue}${LBench_Result_SwapTotal_GB} GB${Font_Suffix}"
    else
        LBench_Result_Swap="${LBench_Result_SwapUsed_GB} GB / ${LBench_Result_SwapTotal_GB} GB"
        echo -e " ${Font_Yellow}Swap Usage:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_SwapUsed_GB} GB${Font_Suffix} / ${Font_SkyBlue}${LBench_Result_SwapTotal_GB} GB${Font_Suffix}"
    fi
    # 启动磁盘
    echo -e " ${Font_Yellow}Boot Device:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_DiskRootPath}${Font_Suffix}"
    # 磁盘使用率 分支判断
    if [ "${LBench_Result_DiskUsed_KB}" -lt "1000000" ]; then
        LBench_Result_Disk="${LBench_Result_DiskUsed_MB} MB / ${LBench_Result_DiskTotal_MB} MB"
        echo -e " ${Font_Yellow}Disk Usage:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_DiskUsed_MB} MB${Font_Suffix} / ${Font_SkyBlue}${LBench_Result_DiskTotal_MB} MB${Font_Suffix}"
    elif [ "${LBench_Result_DiskUsed_KB}" -lt "1000000" ] && [ "${LBench_Result_DiskTotal_KB}" -lt "1000000000" ]; then
        LBench_Result_Disk="${LBench_Result_DiskUsed_MB} MB / ${LBench_Result_DiskTotal_GB} GB"
        echo -e " ${Font_Yellow}Disk Usage:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_DiskUsed_MB} MB${Font_Suffix} / ${Font_SkyBlue}${LBench_Result_DiskTotal_GB} GB${Font_Suffix}"
    elif [ "${LBench_Result_DiskUsed_KB}" -lt "1000000000" ] && [ "${LBench_Result_DiskTotal_KB}" -lt "1000000000" ]; then
        LBench_Result_Disk="${LBench_Result_DiskUsed_GB} GB / ${LBench_Result_DiskTotal_GB} GB"
        echo -e " ${Font_Yellow}Disk Usage:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_DiskUsed_GB} GB${Font_Suffix} / ${Font_SkyBlue}${LBench_Result_DiskTotal_GB} GB${Font_Suffix}"
    elif [ "${LBench_Result_DiskUsed_KB}" -lt "1000000000" ] && [ "${LBench_Result_DiskTotal_KB}" -ge "1000000000" ]; then
        LBench_Result_Disk="${LBench_Result_DiskUsed_GB} GB / ${LBench_Result_DiskTotal_TB} TB"
        echo -e " ${Font_Yellow}Disk Usage:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_DiskUsed_GB} GB${Font_Suffix} / ${Font_SkyBlue}${LBench_Result_DiskTotal_TB} TB${Font_Suffix}"
    else
        LBench_Result_Disk="${LBench_Result_DiskUsed_TB} TB / ${LBench_Result_DiskTotal_TB} TB"
        echo -e " ${Font_Yellow}Disk Usage:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_DiskUsed_TB} TB${Font_Suffix} / ${Font_SkyBlue}${LBench_Result_DiskTotal_TB} TB${Font_Suffix}"
    fi
    # CPU状态
    echo -e " ${Font_Yellow}CPU Usage:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_CPUStat_UsedAll}% used${Font_Suffix}, ${Font_SkyBlue}${LBench_Result_CPUStat_iowait}% iowait${Font_Suffix}, ${Font_SkyBlue}${LBench_Result_CPUStat_steal}% steal${Font_Suffix}"
    # 系统负载
    echo -e " ${Font_Yellow}Load (1/5/15min):${Font_Suffix}\t${Font_SkyBlue}${LBench_Result_LoadAverage_1min} ${LBench_Result_LoadAverage_5min} ${LBench_Result_LoadAverage_15min} ${Font_Suffix}"
    # 系统开机时间
    echo -e " ${Font_Yellow}Uptime:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_SystemInfo_Uptime_Day} Days, ${LBench_Result_SystemInfo_Uptime_Hour} Hours, ${LBench_Result_SystemInfo_Uptime_Minute} Minutes, ${LBench_Result_SystemInfo_Uptime_Second} Seconds${Font_Suffix}"
    # 内核版本
    echo -e " ${Font_Yellow}Kernel Version:${Font_Suffix}\t${Font_SkyBlue}${LBench_Result_KernelVersion}${Font_Suffix}"
    # 网络拥塞控制方式
    echo -e " ${Font_Yellow}Network CC Method:${Font_Suffix}\t${Font_SkyBlue}${LBench_Result_NetworkCCMethod}${Font_Suffix}"
    # 执行完成, 标记FLAG
    LBench_Flag_FinishSystemInfo="1"
}

Function_ShowNetworkInfo() {
    echo -e "\n ${Font_Yellow}-> Network Infomation${Font_Suffix}\n"
    if [ "${LBench_Result_NetworkStat}" = "ipv4only" ] || [ "${LBench_Result_NetworkStat}" = "dualstack" ]; then
        if [ "${IPAPI_IPV4_ip}" != "" ]; then
            echo -e " ${Font_Yellow}IPV4 - IP Address:${Font_Suffix}\t${Font_SkyBlue}[${IPAPI_IPV4_country_code}] ${IPAPI_IPV4_ip}${Font_Suffix}"
            echo -e " ${Font_Yellow}IPV4 - ASN Info:${Font_Suffix}\t${Font_SkyBlue}${IPAPI_IPV4_asn} (${IPAPI_IPV4_organization})${Font_Suffix}"
            echo -e " ${Font_Yellow}IPV4 - Region:${Font_Suffix}\t\t${Font_SkyBlue}${IPAPI_IPV4_location}${Font_Suffix}"
        else
            echo -e " ${Font_Yellow}IPV6 - IP Address:${Font_Suffix}\t${Font_Red}Error: API Query Failed${Font_Suffix}"
        fi
    fi
    if [ "${LBench_Result_NetworkStat}" = "ipv6only" ] || [ "${LBench_Result_NetworkStat}" = "dualstack" ]; then
        if [ "${IPAPI_IPV6_ip}" != "" ]; then
            echo -e " ${Font_Yellow}IPV6 - IP Address:${Font_Suffix}\t${Font_SkyBlue}[${IPAPI_IPV6_country_code}] ${IPAPI_IPV6_ip}${Font_Suffix}"
            echo -e " ${Font_Yellow}IPV6 - ASN Info:${Font_Suffix}\t${Font_SkyBlue}${IPAPI_IPV6_asn} (${IPAPI_IPV6_organization})${Font_Suffix}"
            echo -e " ${Font_Yellow}IPV6 - Region:${Font_Suffix}\t\t${Font_SkyBlue}${IPAPI_IPV6_location}${Font_Suffix}"
        else
            echo -e " ${Font_Yellow}IPV6 - IP Address:${Font_Suffix}\t${Font_Red}Error: API Query Failed${Font_Suffix}"
        fi
    fi
    # 执行完成, 标记FLAG
    LBench_Flag_FinishNetworkInfo="1"
}

# =============== 测试启动与结束动作 ===============
Function_BenchStart() {
    clear
    LBench_Result_BenchStartTime="$(date +"%Y-%m-%d %H:%M:%S")"
    LBench_Result_BenchStartTimestamp="$(date +%s)"
    echo -e "${Font_SkyBlue}LemonBench${Font_Suffix} ${Font_Yellow}Server Test Tookit${Font_Suffix} ${BuildTime} ${Font_SkyBlue}(C)iLemonrain. All Rights Reserved.${Font_Suffix}"
    echo -e "=========================================================================================="
    echo -e " "
    echo -e " ${Msg_Info}${Font_Yellow}Bench Start Time:${Font_Suffix} ${Font_SkyBlue}${LBench_Result_BenchStartTime}${Font_Suffix}"
    echo -e " ${Msg_Info}${Font_Yellow}Test Mode:${Font_Suffix} ${Font_SkyBlue}${Global_TestModeTips}${Font_Suffix}"
    echo -e " "
}

Function_BenchFinish() {
    # 清理临时文件
    LBench_Result_BenchFinishTime="$(date +"%Y-%m-%d %H:%M:%S")"
    LBench_Result_BenchFinishTimestamp="$(date +%s)"
    LBench_Result_TimeElapsedSec="$(echo "$LBench_Result_BenchFinishTimestamp $LBench_Result_BenchStartTimestamp" | awk '{print $1-$2}')"
    echo -e ""
    echo -e "=========================================================================================="
    echo -e " "
    echo -e " ${Msg_Info}${Font_Yellow}Bench Finish Time:${Font_Suffix} ${Font_SkyBlue}${LBench_Result_BenchFinishTime}${Font_Suffix}"
    echo -e " ${Msg_Info}${Font_Yellow}Time Elapsed:${Font_Suffix} ${Font_SkyBlue}${LBench_Result_TimeElapsedSec} seconds${Font_Suffix}"
    echo -e " "
}

#  =============== 流媒体解锁测试 部分 ===============

# 流媒体解锁测试
Function_MediaUnlockTest() {
    echo -e " "
    echo -e "${Font_Yellow} -> Media Unlock Test ${Font_Suffix}"
    echo -e " "
    Function_MediaUnlockTest_HBONow
    Function_MediaUnlockTest_BahamutAnime
    Function_MediaUnlockTest_AbemaTV_IPTest
    Function_MediaUnlockTest_PCRJP
    #Function_MediaUnlockTest_IQiYi_Taiwan
    Function_MediaUnlockTest_BBC
    Function_MediaUnlockTest_BilibiliChinaMainland
    Function_MediaUnlockTest_BilibiliHKMCTW
    Function_MediaUnlockTest_BilibiliTW
    LBench_Flag_FinishMediaUnlockTest="1"
}

# 流媒体解锁测试-HBO Now
Function_MediaUnlockTest_HBONow() {
    echo -n -e " HBO Now:\t\t\t\t->\c"
    # 尝试获取成功的结果
    local result="$(curl --user-agent "${UA_Browser}" -4 -fsL --max-time 30 --write-out "%{url_effective}\n" --output /dev/null https://play.hbonow.com/)"
    if [ "$?" = "0" ]; then
        # 下载页面成功，开始解析跳转
        if [ "${result}" = "https://play.hbonow.com" ] || [ "${result}" = "https://play.hbonow.com/" ]; then
            echo -n -e "\r HBO Now:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
            LemonBench_Result_MediaUnlockTest_HBONow="Yes"
        elif [ "${result}" = "http://hbogeo.cust.footprint.net/hbonow/geo.html" ] || [ "${result}" = "http://geocust.hbonow.com/hbonow/geo.html" ]; then
            echo -n -e "\r HBO Now:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
            LemonBench_Result_MediaUnlockTest_HBONow="No"
        else
            echo -n -e "\r HBO Now:\t\t\t\t${Font_Yellow}Failed (due to parse fail)${Font_Suffix}\n"
            LemonBench_Result_MediaUnlockTest_HBONow="Failed (due to parse fail)"
        fi
    else
        # 下载页面失败，返回错误代码
        echo -e "\r HBO Now:\t\t\t\t${Font_Yellow}Failed (due to network fail)${Font_Suffix}\n"
        LemonBench_Result_MediaUnlockTest_HBONow="Failed (due to network fail)"
    fi
}

# 流媒体解锁测试-动画疯
Function_MediaUnlockTest_BahamutAnime() {
    echo -n -e " Bahamut Anime:\t\t\t\t->\c"
    # 尝试获取成功的结果
    # local result="$(curl -4 --user-agent "${UA_Browser}" --output /dev/null --write-out "%{url_effective}" --max-time 30 -fsL https://ani.gamer.com.tw/animePay.php)"
    local tmpresult="$(curl -4 --user-agent "${UA_Browser}" --max-time 30 -fsL 'https://ani.gamer.com.tw/ajax/token.php?adID=89422&sn=14667')"
    if [ "$?" != "0" ]; then
        echo -n -e "\r Bahamut Anime:\t\t\t\t${Font_Red}Failed (due to network fail)${Font_Suffix}\n"
        LemonBench_Result_MediaUnlockTest_BahamutAnime="Failed (due to network fail)" 
        return 1
    fi
    local result="$(echo $tmpresult | jq -r .animeSn)"
    if [ "$result" != "null" ]; then
        resultverify="$(echo $result | grep -oE '[0-9]{1,}')"
        if [ "$?" = "0" ]; then
            echo -n -e "\r Bahamut Anime:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
            LemonBench_Result_MediaUnlockTest_BahamutAnime="Yes"
        else
            echo -n -e "\r Bahamut Anime:\t\t\t\t${Font_Red}Failed (due to parse fail)${Font_Suffix}\n"
            LemonBench_Result_MediaUnlockTest_BahamutAnime="Failed (due to parse fail)"            
        fi
    else
        local result="$(echo $tmpresult | jq -r .error.code)"
        if [ "$result" != "null" ]; then
            resultverify="$(echo $result | grep -oE '[0-9]{1,}')"
            if [ "$?" = "0" ]; then
                echo -n -e "\r Bahamut Anime:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
                LemonBench_Result_MediaUnlockTest_BahamutAnime="No"
            else
                echo -n -e "\r Bahamut Anime:\t\t\t\t${Font_Red}Failed (due to parse fail)${Font_Suffix}\n"
                LemonBench_Result_MediaUnlockTest_BahamutAnime="Failed (due to parse fail)"                 
            fi
        else
            echo -n -e "\r Bahamut Anime:\t\t\t\t${Font_Red}Failed (due to parse fail)${Font_Suffix}\n"
            LemonBench_Result_MediaUnlockTest_BahamutAnime="Failed (due to parse fail)"    
        fi
    fi
}

# 流媒体解锁测试-哔哩哔哩大陆限定
Function_MediaUnlockTest_BilibiliChinaMainland() {
    echo -n -e " BiliBili China Mainland Only:\t\t->\c"
    local randsession="$(cat /dev/urandom | head -n 32 | md5sum | head -c 32)"
    # 尝试获取成功的结果
    local result="$(curl --user-agent "${UA_Browser}" -4 -fsL --max-time 30 "https://api.bilibili.com/pgc/player/web/playurl?avid=82846771&qn=0&type=&otype=json&ep_id=307247&fourk=1&fnver=0&fnval=16&session=${randsession}&module=bangumi")"
    if [ "$?" = "0" ]; then
        local result="$(PharseJSON "${result}" "code")"
        if [ "$?" = "0" ]; then
            if [ "${result}" = "0" ]; then
                echo -n -e "\r BiliBili China Mainland Only:\t\t${Font_Green}Yes${Font_Suffix}\n"
                LemonBench_Result_MediaUnlockTest_ChinaMainland="Yes"
            elif [ "${result}" = "-10403" ]; then
                echo -n -e "\r BiliBili China Mainland Only:\t\t${Font_Red}No${Font_Suffix}\n"
                LemonBench_Result_MediaUnlockTest_ChinaMainland="No"
            else
                echo -n -e "\r BiliBili China Mainland Only:\t\t${Font_Red}Failed (due to unknown return)${Font_Suffix} ${Font_SkyBlue}(${result})${Font_Suffix}\n"
                LemonBench_Result_MediaUnlockTest_ChinaMainland="Failed (due to unknown return)" 
            fi
        else
            echo -n -e "\r BiliBili China Mainland Only:\t\t${Font_Red}Failed (due to parse fail)${Font_Suffix}\n"
            LemonBench_Result_MediaUnlockTest_ChinaMainland="Failed (due to parse fail)"
        fi
    else
        echo -n -e "\r BiliBili China Mainland Only:\t\t${Font_Red}Failed (due to network fail)${Font_Suffix}\n"
        LemonBench_Result_MediaUnlockTest_ChinaMainland="Failed (due to network fail)"        
    fi   
}

# 流媒体解锁测试-哔哩哔哩港澳台限定
Function_MediaUnlockTest_BilibiliHKMCTW() {
    echo -n -e " BiliBili Hongkong/Macau/Taiwan:\t->\c"
    local randsession="$(cat /dev/urandom | head -n 32 | md5sum | head -c 32)"
    # 尝试获取成功的结果
    local result="$(curl --user-agent "${UA_Browser}" -4 -fsL --max-time 30 "https://api.bilibili.com/pgc/player/web/playurl?avid=18281381&cid=29892777&qn=0&type=&otype=json&ep_id=183799&fourk=1&fnver=0&fnval=16&session=${randsession}&module=bangumi")"
    if [ "$?" = "0" ]; then
        local result="$(PharseJSON "${result}" "code")"
        if [ "$?" = "0" ]; then
            if [ "${result}" = "0" ]; then
                echo -n -e "\r BiliBili Hongkong/Macau/Taiwan:\t${Font_Green}Yes${Font_Suffix}\n"
                LemonBench_Result_MediaUnlockTest_BilibiliHKMCTW="Yes"
            elif [ "${result}" = "-10403" ]; then
                echo -n -e "\r BiliBili Hongkong/Macau/Taiwan:\t${Font_Red}No${Font_Suffix}\n"
                LemonBench_Result_MediaUnlockTest_BilibiliHKMCTW="No"
            else
                echo -n -e "\r BiliBili Hongkong/Macau/Taiwan:\t${Font_Red}Failed (due to unknown return)${Font_Suffix} ${Font_SkyBlue}(${result})${Font_Suffix}\n"
                LemonBench_Result_MediaUnlockTest_BilibiliHKMCTW="Failed (due to unknown return)" 
            fi
        else
            echo -n -e "\r BiliBili Hongkong/Macau/Taiwan:\t${Font_Red}Failed (due to parse fail)${Font_Suffix}\n"
            LemonBench_Result_MediaUnlockTest_BilibiliHKMCTW="Failed (due to parse fail)"
        fi
    else
        echo -n -e "\r BiliBili Hongkong/Macau/Taiwan:\t${Font_Red}Failed (due to network fail)${Font_Suffix}\n"
        LemonBench_Result_MediaUnlockTest_BilibiliHKMCTW="Failed (due to network fail)"        
    fi   
}

# 流媒体解锁测试-哔哩哔哩台湾限定
Function_MediaUnlockTest_BilibiliTW() {
    echo -n -e " Bilibili Taiwan Only:\t\t\t->\c"
    local randsession="$(cat /dev/urandom | head -n 32 | md5sum | head -c 32)"
    # 尝试获取成功的结果
    local result="$(curl --user-agent "${UA_Browser}" -4 -fsL --max-time 30 "https://api.bilibili.com/pgc/player/web/playurl?avid=50762638&cid=100279344&qn=0&type=&otype=json&ep_id=268176&fourk=1&fnver=0&fnval=16&session=${randsession}&module=bangumi")"
    if [ "$?" = "0" ]; then
        local result="$(PharseJSON "${result}" "code")"
        if [ "$?" = "0" ]; then
            if [ "${result}" = "0" ]; then
                echo -n -e "\r Bilibili Taiwan Only:\t\t\t${Font_Green}Yes${Font_Suffix}\n"
                LemonBench_Result_MediaUnlockTest_BilibiliTW="Yes"
            elif [ "${result}" = "-10403" ]; then
                echo -n -e "\r Bilibili Taiwan Only:\t\t\t${Font_Red}No${Font_Suffix}\n"
                LemonBench_Result_MediaUnlockTest_BilibiliTW="No"
            else
                echo -n -e "\r Bilibili Taiwan Only:\t\t\t${Font_Red}Failed (due to unknown return)${Font_Suffix} ${Font_SkyBlue}(${result})${Font_Suffix}\n"
                LemonBench_Result_MediaUnlockTest_BilibiliTW="Failed (due to unknown return)" 
            fi
        else
            echo -n -e "\r Bilibili Taiwan Only:\t\t\t${Font_Red}Failed (due to parse fail)${Font_Suffix}\n"
            LemonBench_Result_MediaUnlockTest_BilibiliTW="Failed (due to parse fail)"
        fi
    else
        echo -n -e "\r 哔哩哔哩-台湾限定:\t${Font_Red}Failed (due to network fail)${Font_Suffix}\n"
        LemonBench_Result_MediaUnlockTest_BilibiliTW="Failed (due to network fail)"        
    fi   
}

# 流媒体解锁测试-爱奇艺台湾站 (Neta)
#
#Function_MediaUnlockTest_IQiYi_Taiwan() {
#    echo -n -e " IQiYi Taiwan (Beta):\t\t\t->\c"
#    local result="$(curl --user-agent "${UA_Browser}" -4 -fsL --max-time 30 "https://cache.video.iqiyi.com/dash?tvid=15364711300&bid=300&vid=3413c5aaa8e04f3724633fb6a4b55c8f&src=01010031010010000000&vt=0&rs=1&uid=&ori=pcw&ps=0&k_uid=949b5c6e48ff7dd333256e186a4d4e64&pt=0&d=0&s=&lid=&cf=&ct=&authKey=d6daa842887706d98d34de38e2c35d94&k_tag=1&ost=0&ppt=0&dfp=a11b673840ba64405b8614ebe8dd6db591c1bd76c1a87d4e9f9305a19f33f87688&locale=zh_tw&prio=%7B%22ff%22%3A%22f4v%22%2C%22code%22%3A2%7D&pck=&k_err_retries=0&up=&qd_v=2&tm=1587902927410&qdy=a&qds=0&k_ft1=706436220846084&k_ft4=1099714535424&k_ft5=1&bop=%7B%22version%22%3A%2210.0%22%2C%22dfp%22%3A%22a11b673840ba64405b8614ebe8dd6db591c1bd76c1a87d4e9f9305a19f33f87688%22%7D&ut=0&vf=674989244c4748e4bf06f169b9eee540")"
#    if [ "$?" = "0" ]; then
#        local res_st="$(echo $result | jq -r .data.st)"
#        if [ "${res_st}" = "101" ]; then
#            echo -n -e "\r IQiYi Taiwan (Beta):\t\t\t${Font_Green}Yes${Font_Suffix}\n"
#            LemonBench_Result_MediaUnlockTest_IQiYi_Taiwan="Yes"
#        elif [ "${res_st}" = "502" ]; then
#            echo -n -e "\r IQiYi Taiwan (Beta):\t\t\t${Font_Red}No${Font_Suffix}\n"
#            LemonBench_Result_MediaUnlockTest_IQiYi_Taiwan="No"
#        else
#            echo -n -e "\r IQiYi Taiwan (Beta):\t\t\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n"
#            LemonBench_Result_MediaUnlockTest_IQiYi_Taiwan="Failed (Unexpected Result: $result)"
#        fi
#    else
#        echo -n -e "\r IQiYi Taiwan (Beta):\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
#        LemonBench_Result_MediaUnlockTest_IQiYi_Taiwan="Failed (Network Connection)"
#    fi
#}

# 流媒体解锁测试-Abema.TV
#
Function_MediaUnlockTest_AbemaTV_IPTest() {
    echo -n -e " Abema.TV:\t\t\t\t\c"
    # 
    # 第一轮判断: 判断IP是否为日本IP (通过Akamai)
    # 如果不是日本IP, 后续没必要继续判断了
    local result="$(curl --user-agent "${UA_Browser}" -4 -fsL --write-out %{http_code} --max-time 30 --output /dev/null http://abematv.akamaized.net/region)"
    if [ "$?" = "0" ]; then
        if [ "${result}" = "200" ]; then
            # 当Akamai 返回 HTTP 200 (OK) 时, 继续第二轮判断
            local result="$(curl --user-agent "${UA_Browser}" -4 -fsL https://abema.tv/now-on-air/abema-news)"
            local result="$(curl --user-agent "${UA_Browser}" -4 -fsL https://abema.tv/now-on-air/abema-news)"
            local result1="$(echo $result | awk -F ' = ' '/window.__CLIENT_REGION__/{print $2$3}' | grep -oP '(?<='isAllowed'":)[0-9A-Za-z]+')"
            local result2="$(echo $result | awk -F ' = ' '/window.__CLIENT_REGION__/{print $2$3}' | grep -oP '(?<='status'":)[0-9A-Za-z]+')"
            if [ "${result1}" = "true" ] && [ "${result2}" = "true" ]; then
                echo -n -e "\r Abema.TV:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
                LemonBench_Result_MediaUnlockTest_AbemaTV_IPTest="Yes"
            elif [ "${result1}" = "true" ] && [ "${result2}" = "false" ]; then
                echo -n -e "\r Abema.TV:\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
                LemonBench_Result_MediaUnlockTest_AbemaTV_IPTest="Yes"
            elif [ "${result1}" = "false" ] && [ "${result2}" = "true" ]; then
                echo -n -e "\r Abema.TV:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
                LemonBench_Result_MediaUnlockTest_AbemaTV_IPTest="No"
            elif [ "${result1}" = "false" ] && [ "${result2}" = "false" ]; then
                echo -n -e "\r Abema.TV:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
                LemonBench_Result_MediaUnlockTest_AbemaTV_IPTest="No"
            else
                echo -n -e "\r Abema.TV:\t\t\t\t${Font_Red}Failed (Unexpected Return Value)${Font_Suffix}\n"
                LemonBench_Result_MediaUnlockTest_AbemaTV_IPTest="Failed (Unexpected Return Value)"
            fi            
        elif [ "${result}" = "403" ]; then
            echo -n -e "\r Abema.TV:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
            LemonBench_Result_MediaUnlockTest_AbemaTV_IPTest="No"
        elif [ "${result}" = "404" ]; then
            echo -n -e "\r Abema.TV:\t\t\t\t${Font_Red}Failed (HTTP 404 Caught)${Font_Suffix}\n"
            LemonBench_Result_MediaUnlockTest_AbemaTV_IPTest="Failed (HTTP 404 Caught)"
        elif [ "${result}" = "000" ]; then
            echo -n -e "\r Abema.TV:\t\t\t\t${Font_Red}No${Font_Suffix}\n"
            LemonBench_Result_MediaUnlockTest_AbemaTV_IPTest="No"
        else
            echo -n -e "\r Abema.TV:\t\t\t\t${Font_Red}Failed (Unexpected HTTP Code)${Font_Suffix} ${Font_SkyBlue}(${result})${Font_Suffix}\n"
            LemonBench_Result_MediaUnlockTest_AbemaTV_IPTest="Failed (Unexpected HTTP Code)" 
        fi
    else
        echo -n -e "\r Abema.TV:\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        LemonBench_Result_MediaUnlockTest_AbemaTV_IPTest="Failed (Network Connection)"        
    fi
}

Function_MediaUnlockTest_PCRJP() {
    echo -n -e " Princess Connect Re:Dive Japan:\t\c"
    # 测试，连续请求两次 (单独请求一次可能会返回35, 第二次开始变成0)
    local result="$(curl --user-agent "${UA_Dalvik}" -4 -fsL --write-out %{http_code} --max-time 30 --output /dev/null https://api-priconne-redive.cygames.jp/)"
    local retval="$?"
    if [ "$retval" = "0" ]; then
        if [ "$result" = "404" ]; then
            echo -n -e "\r Princess Connect Re:Dive Japan:\t${Font_Green}Yes${Font_Suffix}\n"
            LemonBench_Result_MediaUnlockTest_PCRJP="Yes"
        elif [ "$result" = "403" ] || [ "$result" = "000" ]; then
            echo -n -e "\r Princess Connect Re:Dive Japan:\t${Font_Red}No${Font_Suffix}\n"
            LemonBench_Result_MediaUnlockTest_PCRJP="No"
        else
            echo -n -e "\r Princess Connect Re:Dive Japan:\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n"
            LemonBench_Result_MediaUnlockTest_PCRJP="Failed (Unexpected Result: $result)"
        fi
    else
        echo -n -e "\r Princess Connect Re:Dive Japan:\t${Font_Red}Failed (Unexpected Retval: $retval)${Font_Suffix}\n"
        LemonBench_Result_MediaUnlockTest_PCRJP="Failed (Unexpected Retval: $retval)"
    fi
}

Function_MediaUnlockTest_BBC() {
    local result="$(curl --user-agent "${UA_Browser}" -4 -fsL --write-out %{http_code} --max-time 30 --output /dev/null http://ve-dash-uk.live.cf.md.bbci.co.uk/)"
    if [ "$?" = "0" ]; then
        if [ "${result}" = "403" ] || [ "${result}" = "000" ]; then
            echo -n -e "\r BBC:\t\t\t\t\t${Font_Red}No${Font_Suffix}\n"
            LemonBench_Result_MediaUnlockTest_BBC="No"
        elif [ "${result}" = "404" ]; then
            echo -n -e "\r BBC:\t\t\t\t\t${Font_Green}Yes${Font_Suffix}\n"
            LemonBench_Result_MediaUnlockTest_BBC="Yes"
        else
            echo -n -e "\r BBC:\t\t\t\t\t${Font_Red}Failed (Unexpected Result: $result)${Font_Suffix}\n"
            LemonBench_Result_MediaUnlockTest_BBC="Failed (Unexpected Result: $result)"
        fi
    else
        echo -n -e "\r BBC:\t\t\t\t\t${Font_Red}Failed (Network Connection)${Font_Suffix}\n"
        LemonBench_Result_MediaUnlockTest_BBC="Failed (Network Connection)"
    fi
}

# =============== Speedtest 部分 ===============
Run_Speedtest() {
    # 调用方式: Run_Speedtest "服务器ID" "节点名称(用于显示)"
    echo -n -e " $2\t\t->\c"
    mkdir -p ${WorkDir}/result/speedtest/ >/dev/null 2>&1
    if [ "$1" = "default" ]; then
        local result="$(/usr/local/lemonbench/bin/speedtest --accept-license --accept-gdpr --format=json --unit=MiB/s --progress=no 2>/dev/null)"
    elif [ "$1" = "" ]; then
        echo -n -e "\r $2\t\t${Font_Red}Fail: Invalid Speedtest Server (No servers defined)${Font_Suffix}\n"
        echo -e " $2\t\tFail: Invalid Speedtest Server (No servers defined)" >>${WorkDir}/Speedtest/result.txt
    else
        local result="$(/usr/local/lemonbench/bin/speedtest --accept-license --accept-gdpr --format=json --unit=MiB/s --progress=no --server-id $1 2>/dev/null)"
    fi
    # 处理结果
    local getresultid="$(echo $result | jq -r .result.id | grep -v null)"
    if [ "${getresultid}" != "" ]; then
        # 上传速度 (Raw Data, 单位: bytes)
        local rr_upload_bandwidth="$(echo $result | jq -r .upload.bandwidth)"
        # 下载速度 (Raw Data, 单位: bytes)
        local rr_download_bandwidth="$(echo $result | jq -r .download.bandwidth)"
        # Ping 延迟 (Raw Data, 单位: ms)
        local rr_ping_latency="$(echo $result | jq -r .ping.latency)"
        # echo -e " Node Name\t\t\tUpload Speed\tDownload Speed\tPing Latency" >>${WorkDir}/Speedtest/result.txt
        # 处理数据
        # 处理上传速度与下载速度，从B/s转换成MB/s
        local fr_upload_bandwidth="$(echo $rr_upload_bandwidth | awk '{printf"%.2f",$1/1024/1024}')"
        local fr_download_bandwidth="$(echo $rr_download_bandwidth | awk '{printf"%.2f",$1/1024/1024}')"
        # 处理Ping值数据，如果大于1000，只输出整位，否则保留两位小数
        local fr_ping_latency="$(echo $rr_ping_latency | awk '{if($1>=1000){printf"%d",$1}else{printf"%.2f",$1}}')"
        # 输出结果
        echo -n -e "\r $2\t\t${Font_SkyBlue}${fr_upload_bandwidth}${Font_Suffix} MB/s\t${Font_SkyBlue}${fr_download_bandwidth}${Font_Suffix} MB/s\t${Font_SkyBlue}${fr_ping_latency}${Font_Suffix} ms\n"
        echo -e " $2\t\t${fr_upload_bandwidth} MB/s\t${fr_download_bandwidth} MB/s\t${fr_ping_latency} ms" >>${WorkDir}/Speedtest/result.txt
    else
        local getlevel="$(echo $result | jq -r .level)"
        if [ "${getlevel}" = "error" ]; then
            local getmessage="$(echo $result | jq -r .message)"
            echo -n -e "\r $2\t\t${Font_Red}Fail: ${getmessage}${Font_Suffix}\n"
            echo -e " $2\t\tFail: ${getmessage}" >>${WorkDir}/Speedtest/result.txt
        else
            echo -n -e "\r $2\t\t${Font_Red}Fail: ${result}${Font_Suffix}\n"
            echo -e " $2\t\tFail: Unknown Error" >>${WorkDir}/Speedtest/result.txt
        fi      
    fi
}

Function_Speedtest_Fast() {
    mkdir -p ${WorkDir}/Speedtest/ >/dev/null 2>&1
    echo -e "\n ${Font_Yellow}-> Speedtest.net Network Speed Test${Font_Suffix}\n"
    echo -e "\n -> Speedtest.net Network Speed Test\n" >>${WorkDir}/Speedtest/result.txt
    Check_JSONQuery
    Check_Speedtest
    echo -e " ${Font_Yellow}Node Name\t\t\tUpload Speed\tDownload Speed\tPing Latency${Font_Suffix}"
    echo -e " Node Name\t\t\tUpload Speed\tDownload Speed\tPing Latency" >>${WorkDir}/Speedtest/result.txt
    # 默认测试
    Run_Speedtest "default" "Speedtest Default"
    # 快速测试
    Run_Speedtest "9484" "China, Jilin CU"
    Run_Speedtest "15863" "China, Nanning CM"
    Run_Speedtest "26352" "China, Nanjing CT"
    # 执行完成, 标记FLAG
    LBench_Flag_FinishSpeedtestFast="1"
    sleep 1
}

Function_Speedtest_Full() {
    mkdir -p ${WorkDir}/Speedtest/ >/dev/null 2>&1
    echo -e "\n ${Font_Yellow}-> Speedtest.net Network Speed Test${Font_Suffix}\n"
    echo -e "\n -> Speedtest.net Network Speed Test\n" >>${WorkDir}/Speedtest/result.txt
    Check_JSONQuery
    Check_Speedtest
    echo -e " ${Font_Yellow}Node Name\t\t\tUpload Speed\tDownload Speed\tPing Latency${Font_Suffix}"
    echo -e " Node Name\t\t\tUpload Speed\tDownload Speed\tPing Latency" >>${WorkDir}/Speedtest/result.txt
    # 默认测试
    Run_Speedtest "default" "Speedtest Default"
    # 国内测试 - 联通组
    Run_Speedtest "9484" "China, Jilin CU"
    Run_Speedtest "17184" "China, Shandong CU"
    Run_Speedtest "13704" "China, Nanjing CU"
    Run_Speedtest "24447" "China, Shanghai CU"
    Run_Speedtest "4690" "China, Lanzhou CU"
    # 国内测试 - 电信组
    Run_Speedtest "27377" "China, Beijing CT"
    Run_Speedtest "7509" "China, Hangzhou CT"
    Run_Speedtest "26352" "China, Nanjing CT"
    Run_Speedtest "27594" "China, Guangzhou CT"
    Run_Speedtest "23844" "China, Wuhan CT"
    # 国内测试 - 移动组
    Run_Speedtest "16167" "China, Shenyang CM"
    Run_Speedtest "4647" "China, Hangzhou CM"
    Run_Speedtest "15863" "China, Nanning CM"
    Run_Speedtest "16145" "China, Lanzhou CM"
    # 海外测试
    Run_Speedtest "16176" "Hong Kong, HGC"
    Run_Speedtest "13538" "Hong Kong, CSL"
    Run_Speedtest "1536" "Hong Kong, PCCW"
    Run_Speedtest "6527" "Korea, SK [Kdatacenter]"
    Run_Speedtest "28910" "Japan, NTT [fdcservers]"
    Run_Speedtest "21569" "Japan, NTT [i3d]"
    Run_Speedtest "6087" "Japan GLBB"
    Run_Speedtest "24333" "Japan Rakuten"
    Run_Speedtest "17205" "Taiwan, Seednet"
    Run_Speedtest "4938" "Taiwan, HiNet"
    Run_Speedtest "11702" "Taiwan, TFN"
    Run_Speedtest "13623" "Singapore, Singtel"
    Run_Speedtest "7311" "Singapore, M1"
    Run_Speedtest "367" "Singapore, NME"
    Run_Speedtest "8864" "United States, Century Link"
    Run_Speedtest "29623" "United States, Verizon"
    # 执行完成, 标记FLAG
    LBench_Flag_FinishSpeedtestFull="1"
    sleep 1
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
    echo -n -e " $4\t\t->\c"
    # 清理缓存, 避免影响测试结果
    sync
    if [ "${Var_VirtType}" != "docker" ] && [ "${Var_VirtType}" != "openvz" ] && [ "${Var_VirtType}" != "lxc" ] && [ "${Var_VirtType}" != "wsl" ]; then
        echo 3 >/proc/sys/vm/drop_caches
    fi
    # 避免磁盘压力过高, 启动测试前暂停1s
    sleep 1
    # 正式写测试
    dd if=/dev/zero of=/.tmp_LBench/DiskTest/$1 bs=$2 count=$3 oflag=direct 2>${Var_DiskTestResultFile}
    local DiskTest_WriteSpeed_ResultRAW="$(cat ${Var_DiskTestResultFile} | grep -oE "[0-9]{1,4} kB\/s|[0-9]{1,4}.[0-9]{1,2} kB\/s|[0-9]{1,4} KB\/s|[0-9]{1,4}.[0-9]{1,2} KB\/s|[0-9]{1,4} MB\/s|[0-9]{1,4}.[0-9]{1,2} MB\/s|[0-9]{1,4} GB\/s|[0-9]{1,4}.[0-9]{1,2} GB\/s|[0-9]{1,4} TB\/s|[0-9]{1,4}.[0-9]{1,2} TB\/s|[0-9]{1,4} kB\/秒|[0-9]{1,4}.[0-9]{1,2} kB\/秒|[0-9]{1,4} KB\/秒|[0-9]{1,4}.[0-9]{1,2} KB\/秒|[0-9]{1,4} MB\/秒|[0-9]{1,4}.[0-9]{1,2} MB\/秒|[0-9]{1,4} GB\/秒|[0-9]{1,4}.[0-9]{1,2} GB\/秒|[0-9]{1,4} TB\/秒|[0-9]{1,4}.[0-9]{1,2} TB\/秒")"
    DiskTest_WriteSpeed="$(echo "${DiskTest_WriteSpeed_ResultRAW}" | sed "s/秒/s/")"
    local DiskTest_WriteTime_ResultRAW="$(cat ${Var_DiskTestResultFile} | grep -oE "[0-9]{1,}.[0-9]{1,} s|[0-9]{1,}.[0-9]{1,} s|[0-9]{1,}.[0-9]{1,} 秒|[0-9]{1,}.[0-9]{1,} 秒")"
    DiskTest_WriteTime="$(echo ${DiskTest_WriteTime_ResultRAW} | awk '{print $1}')"
    DiskTest_WriteIOPS="$(echo ${DiskTest_WriteTime} $3 | awk '{printf "%d\n",$2/$1}')"
    DiskTest_WritePastTime="$(echo ${DiskTest_WriteTime} | awk '{printf "%.2f\n",$1}')"
    if [ "${DiskTest_WriteIOPS}" -ge "10000" ]; then
        DiskTest_WriteIOPS="$(echo ${DiskTest_WriteIOPS} 1000 | awk '{printf "%.2f\n",$2/$1}')"
        echo -n -e "\r $4\t\t${Font_SkyBlue}${DiskTest_WriteSpeed} (${DiskTest_WriteIOPS}K IOPS, ${DiskTest_WritePastTime}s)${Font_Suffix}\t\t->\c"
    else
        echo -n -e "\r $4\t\t${Font_SkyBlue}${DiskTest_WriteSpeed} (${DiskTest_WriteIOPS} IOPS, ${DiskTest_WritePastTime}s)${Font_Suffix}\t\t->\c"
    fi
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
    local DiskTest_ReadSpeed_ResultRAW="$(cat ${Var_DiskTestResultFile} | grep -oE "[0-9]{1,4} kB\/s|[0-9]{1,4}.[0-9]{1,2} kB\/s|[0-9]{1,4} KB\/s|[0-9]{1,4}.[0-9]{1,2} KB\/s|[0-9]{1,4} MB\/s|[0-9]{1,4}.[0-9]{1,2} MB\/s|[0-9]{1,4} GB\/s|[0-9]{1,4}.[0-9]{1,2} GB\/s|[0-9]{1,4} TB\/s|[0-9]{1,4}.[0-9]{1,2} TB\/s|[0-9]{1,4} kB\/秒|[0-9]{1,4}.[0-9]{1,2} kB\/秒|[0-9]{1,4} KB\/秒|[0-9]{1,4}.[0-9]{1,2} KB\/秒|[0-9]{1,4} MB\/秒|[0-9]{1,4}.[0-9]{1,2} MB\/秒|[0-9]{1,4} GB\/秒|[0-9]{1,4}.[0-9]{1,2} GB\/秒|[0-9]{1,4} TB\/秒|[0-9]{1,4}.[0-9]{1,2} TB\/秒")"
    DiskTest_ReadSpeed="$(echo "${DiskTest_ReadSpeed_ResultRAW}" | sed "s/s/s/")"
    local DiskTest_ReadTime_ResultRAW="$(cat ${Var_DiskTestResultFile} | grep -oE "[0-9]{1,}.[0-9]{1,} s|[0-9]{1,}.[0-9]{1,} s|[0-9]{1,}.[0-9]{1,} 秒|[0-9]{1,}.[0-9]{1,} 秒")"
    DiskTest_ReadTime="$(echo ${DiskTest_ReadTime_ResultRAW} | awk '{print $1}')"
    DiskTest_ReadIOPS="$(echo ${DiskTest_ReadTime} $3 | awk '{printf "%d\n",$2/$1}')"
    DiskTest_ReadPastTime="$(echo ${DiskTest_ReadTime} | awk '{printf "%.2f\n",$1}')"
    rm -f ${Var_DiskTestResultFile}
    # 输出结果
    echo -n -e "\r $4\t\t${Font_SkyBlue}${DiskTest_WriteSpeed} (${DiskTest_WriteIOPS} IOPS, ${DiskTest_WritePastTime}s)${Font_Suffix}\t\t${Font_SkyBlue}${DiskTest_ReadSpeed} (${DiskTest_ReadIOPS} IOPS, ${DiskTest_ReadPastTime}s)${Font_Suffix}\n"
    echo -e " $4\t\t${DiskTest_WriteSpeed} (${DiskTest_WriteIOPS} IOPS, ${DiskTest_WritePastTime} s)\t\t${DiskTest_ReadSpeed} (${DiskTest_ReadIOPS} IOPS, ${DiskTest_ReadPastTime} s)" >>${WorkDir}/DiskTest/result.txt
    rm -rf /.tmp_LBench/DiskTest/
}

Function_DiskTest_Fast() {
    mkdir -p ${WorkDir}/DiskTest/ >/dev/null 2>&1
    echo -e "\n ${Font_Yellow}-> Disk Speed Test (4K Block/1M Block, Direct Mode)${Font_Suffix}\n"
    echo -e "\n -> Disk Speed Test (4K Block/1M Block, Direct Mode)\n" >>${WorkDir}/DiskTest/result.txt
    SystemInfo_GetVirtType
    SystemInfo_GetOSRelease
    if [ "${Var_VirtType}" = "docker" ] || [ "${Var_VirtType}" = "wsl" ]; then
        echo -e " ${Msg_Warning}Due to virt architecture limit, the result may affect by the cache !\n"
    fi
    echo -e " ${Font_Yellow}Test Name\t\tWrite Speed\t\t\t\tRead Speed${Font_Suffix}"
    echo -e " Test Name\t\tWrite Speed\t\t\t\tRead Speed" >>${WorkDir}/DiskTest/result.txt
    Run_DiskTest_DD "100MB.test" "4k" "25600" "100MB-4K Block"
    Run_DiskTest_DD "1GB.test" "1M" "1000" "1GB-1M Block"
    # 执行完成, 标记FLAG
    LBench_Flag_FinishDiskTestFast="1"
    sleep 1
}

Function_DiskTest_Full() {
    mkdir -p ${WorkDir}/DiskTest/ >/dev/null 2>&1
    echo -e "\n ${Font_Yellow}-> Disk Speed Test (4K Block/1M Block, Direct-Write)${Font_Suffix}\n"
    echo -e "\n -> Disk Speed Test (4K Block/1M Block, Direct-Write)\n" >>${WorkDir}/DiskTest/result.txt
    SystemInfo_GetVirtType
    SystemInfo_GetOSRelease
    if [ "${Var_VirtType}" = "docker" ] || [ "${Var_VirtType}" = "wsl" ]; then
        echo -e " ${Msg_Warning}Due to virt architecture limit, the result may affect by the cache !\n"
    fi
    echo -e " ${Font_Yellow}Test Name\t\tWrite Speed\t\t\t\tRead Speed${Font_Suffix}"
    echo -e " Test Name\t\tWrite Speed\t\t\t\tRead Speed" >>${WorkDir}/DiskTest/result.txt
    Run_DiskTest_DD "10MB.test" "4k" "2560" "10MB-4K Block"
    Run_DiskTest_DD "10MB.test" "1M" "10" "10MB-1M Block"
    Run_DiskTest_DD "100MB.test" "4k" "25600" "100MB-4K Block"
    Run_DiskTest_DD "100MB.test" "1M" "100" "100MB-1M Block"
    Run_DiskTest_DD "1GB.test" "4k" "256000" "1GB-4K Block"
    Run_DiskTest_DD "1GB.test" "1M" "1000" "1GB-1M Block"
    # 执行完成, 标记FLAG
    LBench_Flag_FinishDiskTestFull="1"
    sleep 1
}

# =============== BestTrace 部分 ===============
Run_BestTrace() {
    mkdir -p ${WorkDir}/BestTrace/ >/dev/null 2>&1
    # 调用方式: Run_BestTrace "目标IP" "ICMP/TCP" "最大跃点数" "说明"
    if [ "$2" = "tcp" ] || [ "$2" = "TCP" ]; then
        echo -e "Traceroute to $4 (TCP Mode, Max $3 Hop)"
        echo -e "============================================================"
        echo -e "\nTraceroute to $4 (TCP Mode, Max $3 Hop)" >>${WorkDir}/BestTrace/result.txt
        echo -e "============================================================" >>${WorkDir}/BestTrace/result.txt
        /usr/local/lemonbench/bin/besttrace -g en -q 1 -n -T -m $3 $1 | tee -a ${WorkDir}/BestTrace/result.txt
    else
        echo -e "Traceroute to $4 (ICMP Mode, Max $3 Hop)"
        echo -e "============================================================"
        echo -e "\nTracecroute to $4 (ICMP Mode, Max $3 Hop)" >>${WorkDir}/BestTrace/result.txt
        echo -e "============================================================" >>${WorkDir}/BestTrace/result.txt
        /usr/local/lemonbench/bin/besttrace -g en -q 1 -n -m $3 $1 | tee -a ${WorkDir}/BestTrace/result.txt
    fi
}

Run_BestTrace6() {
    # 调用方式: Run_BestTrace "目标IP" "ICMP/TCP" "最大跃点数" "说明"
    if [ "$2" = "tcp" ] || [ "$2" = "TCP" ]; then
        echo -e "Traceroute to $4 (TCP Mode, Max $3 Hop)"
        echo -e "============================================================"
        echo -e "\nTraceroute to $4 (TCP Mode, Max $3 Hop)" >>${WorkDir}/BestTrace/result.txt
        echo -e "============================================================" >>${WorkDir}/BestTrace/result.txt
        /usr/local/lemonbench/bin/besttrace -g en -6 -q 1 -n -T -m $3 $1 >>${WorkDir}/BestTrace/result.txt
    elif [ "$2" = "icmp" ] || [ "$2" = "ICMP" ]; then
        echo -e "Traceroute to $4 (ICMP Mode, Max $3 Hop)"
        echo -e "============================================================"
        echo -e "Traceroute to $4 (ICMP Mode, Max $3 Hop)" >>${WorkDir}/BestTrace/result.txt
        echo -e "============================================================" >>${WorkDir}/BestTrace/result.txt
        /usr/local/lemonbench/bin/besttrace -g en -6 -q 1 -n -m $3 $1 | tee -a ${WorkDir}/BestTrace/result.txt
    fi
}

Function_BestTrace_Fast() {
    Check_BestTrace
    mkdir -p ${WorkDir}/BestTrace/ >/dev/null 2>&1
    if [ "${LBench_Result_NetworkStat}" = "ipv4only" ] || [ "${LBench_Result_NetworkStat}" = "dualstack" ]; then
        echo -e "\n ${Font_Yellow}-> Traceroute Test (IPV4)${Font_Suffix}\n"
        echo -e "\n -> Traceroute Test (IPV4)\n" >>${WorkDir}/BestTrace/result.txt
        # LemonBench RouteTest 节点列表 Ver 20191112
        # 国内部分
        Run_BestTrace "123.125.99.1" "${GlobalVar_TracerouteMode}" "50" "China, Beijing CU"
        Run_BestTrace "180.149.128.9" "${GlobalVar_TracerouteMode}" "50" "China, Beijing CT"
        Run_BestTrace "211.136.25.153" "${GlobalVar_TracerouteMode}" "50" "China, Beijing CM"
        Run_BestTrace "58.247.8.158" "${GlobalVar_TracerouteMode}" "50" "China, Shanghai CU"
        Run_BestTrace "180.153.28.5" "${GlobalVar_TracerouteMode}" "50" "China, Shanghai CT"
        Run_BestTrace "221.183.55.22" "${GlobalVar_TracerouteMode}" "50" "China, Shanghai CM"
        Run_BestTrace "210.21.4.130" "${GlobalVar_TracerouteMode}" "50" "China, Guangzhou CU"
        Run_BestTrace "113.108.209.1" "${GlobalVar_TracerouteMode}" "50" "China, Guangzhou CT"
        Run_BestTrace "120.196.212.25" "${GlobalVar_TracerouteMode}" "50" "China, Guangzhou CM"
        Run_BestTrace "210.13.66.238" "${GlobalVar_TracerouteMode}" "50" "China, Shanghai CU AS9929"
        Run_BestTrace "58.32.0.1" "${GlobalVar_TracerouteMode}" "50" "China, Shanghai CT CN2"
        Run_BestTrace "14.131.128.1" "${GlobalVar_TracerouteMode}" "50" "China, Beijing Dr.Peng Home Network"
        Run_BestTrace "211.167.230.100" "${GlobalVar_TracerouteMode}" "50" "China, Beijing Dr.Peng Network IDC Network"
        Run_BestTrace "202.205.109.205" "${GlobalVar_TracerouteMode}" "50" "China, Beijing CERNET"
        Run_BestTrace "159.226.254.1" "${GlobalVar_TracerouteMode}" "50" "China, Beijing CSTNET"
        Run_BestTrace "211.156.140.17" "${GlobalVar_TracerouteMode}" "50" "China, Beijing GCable"
    fi
    if [ "${LBench_Result_NetworkStat}" = "ipv6only" ] || [ "${LBench_Result_NetworkStat}" = "dualstack" ]; then
        echo -e "\n ${Font_Yellow}-> Traceroute Test (IPV6)${Font_Suffix}\n"
        echo -e "\n -> Traceroute Test (IPV6)\n" >>${WorkDir}/BestTrace/result.txt
        Run_BestTrace6 "2408:80f0:4100:2005::3" "ICMP" "50" "China, Beijing CU IPV6"
        Run_BestTrace6 "240e:18:10:a01::1" "ICMP" "50" "China, Shanghai CT IPV6"
        Run_BestTrace6 "2409:8057:5c00:30::6" "ICMP" "50" "China, Guangzhou CM IPV6"
        Run_BestTrace6 "2001:da8:a0:1001::1" "ICMP" "50" "China, Beijing CERNET2 IPV6"
        Run_BestTrace6 "2400:dd00:0:37::213" "ICMP" "50" "China, Beijing CSTNET IPV6"
    fi
    # 执行完成, 标记FLAG
    LBench_Flag_FinishBestTraceFast="1"
    sleep 1
}

Function_BestTrace_Full() {
    Check_BestTrace
    mkdir -p ${WorkDir}/BestTrace/ >/dev/null 2>&1
    if [ "${LBench_Result_NetworkStat}" = "ipv4only" ] || [ "${LBench_Result_NetworkStat}" = "dualstack" ] || [ "${LBench_Result_NetworkStat}" = "unknown" ]; then
        echo -e "\n ${Font_Yellow}-> Traceroute Test (IPV4)${Font_Suffix}\n"
        echo -e "\n -> Traceroute Test (IPV4)\n" >>${WorkDir}/BestTrace/result.txt
        # LemonBench RouteTest 节点列表 Ver 20191112
        # 国内部分
        Run_BestTrace "123.125.99.1" "${GlobalVar_TracerouteMode}" "50" "China, Beijing CU"
        Run_BestTrace "180.149.128.1" "${GlobalVar_TracerouteMode}" "50" "China, Beijing CT"
        Run_BestTrace "211.136.25.153" "${GlobalVar_TracerouteMode}" "50" "China, Beijing CM"
        Run_BestTrace "58.247.0.49" "${GlobalVar_TracerouteMode}" "50" "China, Shanghai CU"
        Run_BestTrace "180.153.28.1" "${GlobalVar_TracerouteMode}" "50" "China, Shanghai CT"
        Run_BestTrace "221.183.55.22" "${GlobalVar_TracerouteMode}" "50" "China, Shanghai CM"
        Run_BestTrace "210.21.4.130" "${GlobalVar_TracerouteMode}" "50" "China, Guangzhou CU"
        Run_BestTrace "113.108.209.1" "${GlobalVar_TracerouteMode}" "50" "China, Guangzhou CT"
        Run_BestTrace "211.139.129.5" "${GlobalVar_TracerouteMode}" "50" "China, Guangzhou CM"
        Run_BestTrace "210.13.66.238" "${GlobalVar_TracerouteMode}" "50" "China, Shanghai CU AS9929"
        Run_BestTrace "58.32.0.1" "${GlobalVar_TracerouteMode}" "50" "China, Shanghai CT CN2"
        Run_BestTrace "14.131.128.1" "${GlobalVar_TracerouteMode}" "50" "China, Beijing Dr.Peng Home Network"
        Run_BestTrace "211.167.230.100" "${GlobalVar_TracerouteMode}" "50" "China, Beijing Dr.Peng Network IDC Network"
        Run_BestTrace "202.205.109.205" "${GlobalVar_TracerouteMode}" "50" "China, Beijing CERNET"
        Run_BestTrace "159.226.254.1" "${GlobalVar_TracerouteMode}" "50" "China, Beijing CSTNET"
        Run_BestTrace "211.156.140.17" "${GlobalVar_TracerouteMode}" "50" "China, Beijing GCable"
        # 香港部分
        Run_BestTrace "203.160.95.218" "${GlobalVar_TracerouteMode}" "50" "China, Hongkong CU"
        Run_BestTrace "203.215.232.173" "${GlobalVar_TracerouteMode}" "50" "China, Hongkong CT"
        Run_BestTrace "203.8.25.187" "${GlobalVar_TracerouteMode}" "50" "China, Hongkong CT CN2"
        Run_BestTrace "203.142.105.9" "${GlobalVar_TracerouteMode}" "50" "China, Hongkong CM"
        Run_BestTrace "218.188.104.30" "${GlobalVar_TracerouteMode}" "50" "China, Hongkong HGC"
        Run_BestTrace "210.6.23.239" "${GlobalVar_TracerouteMode}" "50" "China, Hongkong HKBN"
        Run_BestTrace "202.85.125.60" "${GlobalVar_TracerouteMode}" "50" "China, Hongkong PCCW"
        Run_BestTrace "202.123.76.239" "${GlobalVar_TracerouteMode}" "50" "China, Hongkong TGT"
        Run_BestTrace "59.152.252.242" "${GlobalVar_TracerouteMode}" "50" "China, Hongkong WTT"
        # 新加坡部分
        Run_BestTrace "203.215.233.1" "${GlobalVar_TracerouteMode}" "50" "Singapore, China CT"
        Run_BestTrace "183.91.61.1" "${GlobalVar_TracerouteMode}" "50" "Singapore, China CT CN2"
        Run_BestTrace "118.201.1.11" "${GlobalVar_TracerouteMode}" "50" "Singapore, Singtel"
        Run_BestTrace "203.116.46.33" "${GlobalVar_TracerouteMode}" "50" "Singapore, StarHub"
        Run_BestTrace "118.189.184.1" "${GlobalVar_TracerouteMode}" "50" "Singapore, M1"
        Run_BEstTrace "118.189.38.17" "${GlobalVar_TracerouteMode}" "50" "Singapore, M1 GamePro"
        Run_BestTrace "13.228.0.251" "${GlobalVar_TracerouteMode}" "50" "Singapore, AWS"
        # 日本部分
        Run_BestTrace "61.213.155.84" "${GlobalVar_TracerouteMode}" "50" "Japan, NTT"
        Run_BestTrace "202.232.15.70" "${GlobalVar_TracerouteMode}" "50" "Japan, IIJ"
        Run_BestTrace "210.175.32.26" "${GlobalVar_TracerouteMode}" "50" "Japan, SoftBank"
        Run_BestTrace "106.162.242.108" "${GlobalVar_TracerouteMode}" "50" "Japan, KDDI"
        Run_BestTrace "203.215.236.3" "${GlobalVar_TracerouteMode}" "50" "Japan, China CT"
        Run_BestTrace "202.55.27.4" "${GlobalVar_TracerouteMode}" "50" "Japan, China CT CN2"
        Run_BestTrace "13.112.63.251" "${GlobalVar_TracerouteMode}" "50" "Japan, Amazon AWS"
        # 韩国部分
        Run_BestTrace "210.114.41.101" "${GlobalVar_TracerouteMode}" "50" "South Korea, KT"
        Run_BestTrace "175.122.253.62 " "${GlobalVar_TracerouteMode}" "50" "South Korea, SK"
        Run_BestTrace "211.174.62.44" "${GlobalVar_TracerouteMode}" "50" "South Korea, LG"
        Run_BestTrace "218.185.246.3" "${GlobalVar_TracerouteMode}" "50" "South Korea, China CT CN2"
        Run_BestTrace "13.124.63.251" "${GlobalVar_TracerouteMode}" "50" "South Korea, Amazon AWS"
        # 台湾部分
        Run_BestTrace "202.133.242.116" "${GlobalVar_TracerouteMode}" "50" "China, Taiwan Chief"
        Run_BestTrace "210.200.69.90" "${GlobalVar_TracerouteMode}" "50" "China, Taiwan APTG"
        Run_BestTrace "203.75.129.162" "${GlobalVar_TracerouteMode}" "50" "China, Taiwan CHT"
        Run_BestTrace "219.87.66.3" "${GlobalVar_TracerouteMode}" "50" "China, Taiwan TFN"
        Run_BestTrace "211.73.144.38" "${GlobalVar_TracerouteMode}" "50" "China,Taiwan FET"
        Run_BestTrace "61.63.0.102" "${GlobalVar_TracerouteMode}" "50" "China, Taiwan KBT"
        Run_BestTrace "103.31.196.203" "${GlobalVar_TracerouteMode}" "50" "China, Taiwan TAIFO"
        # 美国部分
        Run_BestTrace "218.30.33.17" "${GlobalVar_TracerouteMode}" "50" "United States, Los Angeles China CT"
        Run_BestTrace "66.102.252.100" "${GlobalVar_TracerouteMode}" "50" "United States, Los Angeles China CT CN2"
        Run_BestTrace "63.218.42.81" "${GlobalVar_TracerouteMode}" "50" "United States, Los Angeles PCCW"
        Run_BestTrace "66.220.18.42" "${GlobalVar_TracerouteMode}" "50" "United States, Los Angeles HE"
        Run_BestTrace "173.205.77.98" "${GlobalVar_TracerouteMode}" "50" "United States, Los Angeles GTT"
        Run_BestTrace "12.169.215.33" "${GlobalVar_TracerouteMode}" "50" "United States, San Fransico ATT"
        Run_BestTrace "66.198.181.100" "${GlobalVar_TracerouteMode}" "50" "United States, New York TATA"
        Run_BestTrace "218.30.33.17" "${GlobalVar_TracerouteMode}" "50" "United States, San Jose China CT"
        Run_BestTrace "23.11.26.62" "${GlobalVar_TracerouteMode}" "50" "United States, San Jose NTT"
        Run_BestTrace "72.52.104.74" "${GlobalVar_TracerouteMode}" "50" "United States, Fremont HE"
        Run_BestTrace "205.216.62.38" "${GlobalVar_TracerouteMode}" "50" "United States, Las Vegas Level3"
        Run_BestTrace "64.125.191.31" "${GlobalVar_TracerouteMode}" "50" "United States, San Jose ZAYO"
        Run_BestTrace "149.127.109.166" "${GlobalVar_TracerouteMode}" "50" "United States, Ashburn Cogentco"
        # 欧洲部分
        Run_BestTrace "80.146.191.1" "${GlobalVar_TracerouteMode}" "50" "German, Telekom"
        Run_BestTrace "82.113.108.25" "${GlobalVar_TracerouteMode}" "50" "German, Frankfurt O2"
        Run_BestTrace "139.7.146.11" "${GlobalVar_TracerouteMode}" "50" "German, Frankfurt Vodafone"
        Run_BestTrace "118.85.205.101" "${GlobalVar_TracerouteMode}" "50" "German, Frankfurt China CT"
        Run_BestTrace "5.10.138.33" "${GlobalVar_TracerouteMode}" "50" "German, Frankfurt China CT CN2"
        Run_BestTrace "213.200.65.70" "${GlobalVar_TracerouteMode}" "50" "German, Frankfurt GTT"
        Run_BestTrace "212.20.150.5" "${GlobalVar_TracerouteMode}" "50" "German, FrankfurtCogentco"
        Run_BestTrace "194.62.232.211" "${GlobalVar_TracerouteMode}" "50" "United Kingdom, Vodafone"
        Run_BestTrace "213.121.43.24" "${GlobalVar_TracerouteMode}" "50" "United Kingdom， BT"
        Run_BestTrace "80.231.131.34" "${GlobalVar_TracerouteMode}" "50" "United Kingdom, London TATA"
        Run_BestTrace "118.85.205.181" "${GlobalVar_TracerouteMode}" "50" "Russia, China CT"
        Run_BestTrace "185.75.173.17" "${GlobalVar_TracerouteMode}" "50" "Russia, China CT CN2"
        Run_BestTrace "87.226.162.77" "${GlobalVar_TracerouteMode}" "50" "Russia, Moscow RT"
        Run_BestTrace "217.150.32.2" "${GlobalVar_TracerouteMode}" "50" "Russia, Moscow TTK"
        Run_BestTrace "195.34.32.71" "${GlobalVar_TracerouteMode}" "50" "Russia, Moscow MTS"
    fi
    if [ "${LBench_Result_NetworkStat}" = "ipv6only" ] || [ "${LBench_Result_NetworkStat}" = "dualstack" ] || [ "${LBench_Result_NetworkStat}" = "unknown" ]; then
        echo -e "\n ${Font_Yellow}-> Traceroute Test (IPV6)${Font_Suffix}\n"
        echo -e "\n -> Traceroute Test (IPV6)\n" >>${WorkDir}/BestTrace/result.txt
        # 国内部分
        Run_BestTrace6 "2408:80f0:4100:2005::3" "ICMP" "50" "China, Beijing CU IPV6"
        Run_BestTrace6 "2400:da00:2::29" "ICMP" "50" "China, Beijing CT IPV6"
        Run_BestTrace6 "2409:8089:1020:50ff:1000::fd01" "ICMP" "50" "China, Beijing CM IPV6"
        Run_BestTrace6 "2408:8000:9000:20e6::b7" "ICMP" "50" "China, Shanghai CU IPV6"
        Run_BestTrace6 "240e:18:10:a01::1" "ICMP" "50" "China, Shanghai CT IPV6"
        Run_BestTrace6 "2409:801e:5c03:2000::207" "ICMP" "50" "China, Shanghai CM IPV6"
        Run_BestTrace6 "2408:8001:3011:310::3" "ICMP" "50" "China, Guangzhou CU IPV6"
        Run_BestTrace6 "240e:ff:e02c:1:21::" "ICMP" "50" "China, Guangzhou CT IPV6"
        Run_BestTrace6 "2409:8057:5c00:30::6" "ICMP" "50" "China, Guangzhou CM IPV6"
        Run_BestTrace6 "2403:8880:400f::2" "ICMP" "50" "China, Beijing Dr.Peng IPV6"
        Run_BestTrace6 "2001:da8:a0:1001::1" "ICMP" "50" "China, Beijing CERNET2 IPV6"
        Run_BestTrace6 "2400:dd00:0:37::213" "ICMP" "50" "China, Beijing CSTNET IPV6"
        # 香港部分
        Run_BestTrace6 "2001:7fa:0:1::ca28:a1a9" "ICMP" "50" "China, Hongkong HKIX IPV6"
        Run_BestTrace6 "2001:470:0:490::2" "ICMP" "50" "China, Hongkong HE IPV6"
        # 美国部分
        Run_BestTrace6 "2001:470:1:ff::1" "ICMP" "50" "United States, San Jose HE IPV6"
        Run_BestTrace6 "2001:418:0:5000::1026" "ICMP" "50" "United States, Chicago NTT IPV6"
        Run_BestTrace6 "2001:2000:3080:1e96::2" "ICMP" "50" "United States, Los Angeles Telia IPV6"
        Run_BestTrace6 "2001:668:0:3:ffff:0:d8dd:9d5a" "ICMP" "50" "United States, Los Angeles GTT IPV6"
        Run_BestTrace6 "2600:0:1:1239:144:228:241:71" "ICMP" "50" "United States, Kansas City Sprint IPV6"
        Run_BestTrace6 "2600:80a:2::15" "ICMP" "50" "United States, Los Angeles Verizon IPV6"
        Run_BestTrace6 "2001:550:0:1000::9a36:4215" "ICMP" "50" "United Status, Ashburn Cogentco IPV6"
        Run_BestTrace6 "2001:1900:2100::2eb5" "ICMP" "50" "United States, San Jose Level3 IPV6"
        Run_BestTrace6 "2001:438:ffff::407d:d6a" "ICMP" "50" "United States, Seattle Zayo IPV6"
        # 欧洲部分
        Run_BestTrace6 "2001:470:0:349::1" "ICMP" "50" "France, Paris HE IPV6"
        Run_BestTrace6 "2001:728:0:5000::6f6" "ICMP" "50" "German, Frankfurt NTT IPV6"
    fi
    # 执行完成, 标记FLAG
    LBench_Flag_FinishBestTraceFull="1"
    sleep 1
}

Function_SpooferTest() {
    if [ "${Var_SpooferDisabled}" = "1" ]; then
        return 0
    fi
    mkdir -p ${WorkDir}/Spoofer/ >/dev/null 2>&1
    echo -e "\n ${Font_Yellow}-> Spoof Test${Font_Suffix}\n"
    echo -e "\n -> Spoof Test\n" >>${WorkDir}/Spoofer/result.txt
    Check_Spoofer
    mkdir ${WorkDir}/ >/dev/null 2>&1
    echo -e "Running Spoof Test, this may take a long time, please wait ..."
    /usr/local/bin/spoofer-prober -s0 -r0 | tee -a ${WorkDir}/spoofer.log >/dev/null
    if [ "$?" = "0" ]; then
        LBench_Result_SpooferResultURL="$(cat ${WorkDir}/spoofer.log | grep -oE "https://spoofer.caida.org/report.php\?sessionkey\=[0-9a-z]{1,}")"
        echo -e "\n ${Msg_Success}Spoofer Result:${LBench_Result_SpooferResultURL}"
        echo -e "\n Spoofer Result:${LBench_Result_SpooferResultURL}" >>${WorkDir}/Spoofer/result.txt
        LBench_Flag_FinishSpooferTest="1"
    else
        cp -f ${WorkDir}/spoofer.log /tmp/lemonbench.spoofer.log
        echo -e "\n ${Msg_Error}Spoofer Test Fail! Please read /tmp/lemonbench.spoofer.log to view logs !"
        echo -e "\n Spoofer Result:Fail" >>${WorkDir}/Spoofer/result.txt
        LBench_Flag_FinishSpooferTest="2"
    fi
    rm -rf ${WorkDir}/spoofer.log
    # 执行完成, 标记FLAG
    sleep 1
}

Function_SpooferWarning() {
    echo -e " "
    echo -e "\e[33;43;1m  Please Read this FIRST  \e[0m"
    echo -e " "
    echo -e " Due to some user report, running spoof test may cause server suspendsion by your host provider."
    echo -e " Please use this function with caution."
    echo -e " "
    echo -e " If you still want to start this test, you can press any key to continue, else press Ctrl+C to"
    echo -e " stop running this test."
    read -s -n1 -p ""
}

# =============== SysBench - CPU性能 部分 ===============
Run_SysBench_CPU() {
    # 调用方式: Run_SysBench_CPU "线程数" "测试时长(s)" "测试遍数" "说明"
    # 变量初始化
    mkdir -p ${WorkDir}/SysBench/CPU/ >/dev/null 2>&1
    maxtestcount="$3"
    local count="1"
    local TestScore="0"
    local TotalScore="0"
    # 运行测试
    while [ $count -le $maxtestcount ]; do
        echo -e "\r ${Font_Yellow}$4: ${Font_Suffix}\t\t$count/$maxtestcount \c"
        local TestResult="$(sysbench --test=cpu --num-threads=$1 --cpu-max-prime=10000 --max-requests=1000000 --max-time=$2 run 2>&1)"
        local TestScore="$(echo ${TestResult} | grep -oE "events per second: [0-9]+" | grep -oE "[0-9]+")"
        local TotalScore="$(echo "${TotalScore} ${TestScore}" | awk '{printf "%d",$1+$2}')"
        let count=count+1
        local TestResult=""
        local TestScore="0"
    done
    local ResultScore="$(echo "${TotalScore} ${maxtestcount}" | awk '{printf "%d",$1/$2}')"
    if [ "$1" = "1" ]; then
        echo -e "\r ${Font_Yellow}$4: ${Font_Suffix}\t\t${Font_SkyBlue}${ResultScore}${Font_Suffix} ${Font_Yellow}Scores${Font_Suffix}"
        echo -e " $4:\t\t\t${ResultScore} Scores" >>${WorkDir}/SysBench/CPU/result.txt
    elif [ "$1" -ge "2" ]; then
        echo -e "\r ${Font_Yellow}$4: ${Font_Suffix}\t\t${Font_SkyBlue}${ResultScore}${Font_Suffix} ${Font_Yellow}Scores${Font_Suffix}"
        echo -e " $4:\t\t${ResultScore} Scores" >>${WorkDir}/SysBench/CPU/result.txt
    fi
}

Function_SysBench_CPU_Fast() {
    mkdir -p ${WorkDir}/SysBench/CPU/ >/dev/null 2>&1
    echo -e "\n ${Font_Yellow}-> CPU Performance Test (Fast Mode, 1-Pass @ 5sec)${Font_Suffix}\n"
    echo -e "\n -> CPU Performance Test (Fast Mode, 1-Pass @ 5sec)\n" >>${WorkDir}/SysBench/CPU/result.txt
    Run_SysBench_CPU "1" "5" "1" "1 Thread Test"
    if [ "${LBench_Result_CPUThreadNumber}" -ge "2" ]; then
        Run_SysBench_CPU "${LBench_Result_CPUThreadNumber}" "5" "1" "${LBench_Result_CPUThreadNumber} Threads Test"
    elif [ "${LBench_Result_CPUProcessorNumber}" -ge "2" ]; then
        Run_SysBench_CPU "${LBench_Result_CPUProcessorNumber}" "5" "1" "${LBench_Result_CPUProcessorNumber} Threads Test"
    fi
    # 完成FLAG
    LBench_Flag_FinishSysBenchCPUFast="1"
}

Function_SysBench_CPU_Full() {
    mkdir -p ${WorkDir}/SysBench/CPU/ >/dev/null 2>&1
    echo -e "\n ${Font_Yellow}-> CPU Performance Test (Standard Mode, 3-Pass @ 30sec)${Font_Suffix}\n"
    echo -e "\n -> CPU Performance Test (Standard Mode, 3-Pass @ 30sec)\n" >>${WorkDir}/SysBench/CPU/result.txt
    Run_SysBench_CPU "1" "50" "3" "1 Thread Test"
    if [ "${LBench_Result_CPUThreadNumber}" -ge "2" ]; then
        Run_SysBench_CPU "${LBench_Result_CPUThreadNumber}" "50" "3" "${LBench_Result_CPUThreadNumber} Threads Test"
    elif [ "${LBench_Result_CPUProcessorNumber}" -ge "2" ]; then
        Run_SysBench_CPU "${LBench_Result_CPUProcessorNumber}" "50" "3" "${LBench_Result_CPUProcessorNumber} Threads Test"
    fi
    # 完成FLAG
    LBench_Flag_FinishSysBenchCPUFull="1"
    sleep 1
}

# =============== SysBench - 内存性能 部分 ===============
Run_SysBench_Memory() {
    # 调用方式: Run_SysBench_Memory "线程数" "测试时长(s)" "测试遍数" "测试模式(读/写)" "读写方式(顺序/随机)" "说明"
    # 变量初始化
    mkdir -p ${WorkDir}/SysBench/Memory/ >/dev/null 2>&1
    maxtestcount="$3"
    local count="1"
    local TestScore="0.00"
    local TestSpeed="0.00"
    local TotalScore="0.00"
    local TotalSpeed="0.00"
    if [ "$1" -ge "2" ]; then
        MultiThread_Flag="1"
    else
        MultiThread_Flag="0"
    fi
    # 运行测试
    while [ $count -le $maxtestcount ]; do
        if [ "$1" -ge "2" ] && [ "$4" = "write" ]; then
            echo -e "\r ${Font_Yellow}$6:${Font_Suffix}\t$count/$maxtestcount \c"
        else
            echo -e "\r ${Font_Yellow}$6:${Font_Suffix}\t\t$count/$maxtestcount \c"
        fi
        local TestResult="$(sysbench --test=memory --num-threads=$1 --memory-block-size=1M --memory-total-size=102400G --memory-oper=$4 --max-time=$2 --memory-access-mode=$5 run 2>&1)"
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
    # 1线程的测试结果写入临时变量，方便与后续的多线程变量做对比
    if [ "$1" = "1" ] && [ "$4" = "read" ]; then
        LBench_Result_MemoryReadSpeedSingle="${ResultSpeed}"
    elif [ "$1" = "1" ] &&[ "$4" = "write" ]; then
        LBench_Result_MemoryWriteSpeedSingle="${ResultSpeed}"
    fi
    if [ "${MultiThread_Flag}" = "1" ]; then
        # 如果是多线程测试，输出与1线程测试对比的倍率
        if [ "$1" -ge "2" ] && [ "$4" = "read" ]; then
            LBench_Result_MemoryReadSpeedMulti="${ResultSpeed}"
            local readmultiple="$(echo "${LBench_Result_MemoryReadSpeedMulti} ${LBench_Result_MemoryReadSpeedSingle}" | awk '{printf "%.2f", $1/$2}')"
            echo -e "\r ${Font_Yellow}$6:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_MemoryReadSpeedMulti}${Font_Suffix} ${Font_Yellow}MB/s${Font_Suffix} (${readmultiple} x)"
        elif [ "$1" -ge "2" ] && [ "$4" = "write" ]; then
            LBench_Result_MemoryWriteSpeedMulti="${ResultSpeed}"
            local writemultiple="$(echo "${LBench_Result_MemoryWriteSpeedMulti} ${LBench_Result_MemoryWriteSpeedSingle}" | awk '{printf "%.2f", $1/$2}')"
            echo -e "\r ${Font_Yellow}$6:${Font_Suffix}\t\t${Font_SkyBlue}${LBench_Result_MemoryWriteSpeedMulti}${Font_Suffix} ${Font_Yellow}MB/s${Font_Suffix} (${writemultiple} x)"
        fi
    else
        if [ "$4" = "read" ]; then
            echo -e "\r ${Font_Yellow}$6:${Font_Suffix}\t\t${Font_SkyBlue}${ResultSpeed}${Font_Suffix} ${Font_Yellow}MB/s${Font_Suffix}"
        elif [ "$4" = "write" ]; then
            echo -e "\r ${Font_Yellow}$6:${Font_Suffix}\t\t${Font_SkyBlue}${ResultSpeed}${Font_Suffix} ${Font_Yellow}MB/s${Font_Suffix}"
        fi
    fi
    # Fix
    if [ "$1" -ge "2" ] && [ "$4" = "write" ]; then
        echo -e " $6:\t${ResultSpeed} MB/s" >>${WorkDir}/SysBench/Memory/result.txt
    else
        echo -e " $6:\t\t${ResultSpeed} MB/s" >>${WorkDir}/SysBench/Memory/result.txt
    fi
    sleep 1
}

Function_SysBench_Memory_Fast() {
    mkdir -p ${WorkDir}/SysBench/Memory/ >/dev/null 2>&1
    echo -e "\n ${Font_Yellow}-> Memory Performance Test (Fast Mode, 1-Pass @ 5sec)${Font_Suffix}\n"
    echo -e "\n -> Memory Performance Test (Fast Mode, 1-Pass @ 5sec)\n" >>${WorkDir}/SysBench/Memory/result.txt
    Run_SysBench_Memory "1" "5" "1" "read" "seq" "1 Thread - Read Test "
    Run_SysBench_Memory "1" "5" "1" "write" "seq" "1 Thread - Write Test"
    # 完成FLAG
    LBench_Flag_FinishSysBenchMemoryFast="1"
    sleep 1
}

Function_SysBench_Memory_Full() {
    mkdir -p ${WorkDir}/SysBench/Memory/ >/dev/null 2>&1
    echo -e "\n ${Font_Yellow}-> Memory Performance Test (Standard Mode, 3-Pass @ 30sec)${Font_Suffix}\n"
    echo -e "\n -> Memory Performance Test (Standard Mode, 3-Pass @ 30sec)\n" >>${WorkDir}/SysBench/Memory/result.txt
    Run_SysBench_Memory "1" "50" "3" "read" "seq" "1 Thread - Read Test "
    Run_SysBench_Memory "1" "50" "3" "write" "seq" "1 Thread - Write Test"
    # 完成FLAG
    LBench_Flag_FinishSysBenchMemoryFull="1"
    sleep 1
}

# 生成结果文件
Function_GenerateResult() {
    echo -e "${Msg_Info}Please wait, collecting results ..."
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
    echo -e "${Msg_Info}Generating Report ..."
    local finalresultfile="${WorkDir}/result/finalresult.txt"
    sleep 0.2
    if [ -f "${WorkDir}/result/00-header.result" ]; then
        cat ${WorkDir}/result/00-header.result >>${WorkDir}/result/finalresult.txt
    fi
    sleep 0.2
    if [ -f "${WorkDir}/result/01-systeminfo.result" ]; then
        cat ${WorkDir}/result/01-systeminfo.result >>${WorkDir}/result/finalresult.txt
    fi
    sleep 0.2
    if [ -f "${WorkDir}/result/02-networkinfo.result" ]; then
        cat ${WorkDir}/result/02-networkinfo.result >>${WorkDir}/result/finalresult.txt
    fi
    if [ -f "${WorkDir}/result/03-mediaunlocktest.result" ]; then
        cat ${WorkDir}/result/03-mediaunlocktest.result >>${WorkDir}/result/finalresult.txt
    fi
    sleep 0.2
    if [ -f "${WorkDir}/result/04-cputest.result" ]; then
        cat ${WorkDir}/result/04-cputest.result >>${WorkDir}/result/finalresult.txt
    fi
    sleep 0.2
    if [ -f "${WorkDir}/result/05-memorytest.result" ]; then
        cat ${WorkDir}/result/05-memorytest.result >>${WorkDir}/result/finalresult.txt
    fi
    sleep 0.2
    if [ -f "${WorkDir}/result/06-disktest.result" ]; then
        cat ${WorkDir}/result/06-disktest.result >>${WorkDir}/result/finalresult.txt
    fi
    if [ -f "${WorkDir}/result/07-speedtest.result" ]; then
        cat ${WorkDir}/result/07-speedtest.result >>${WorkDir}/result/finalresult.txt
    fi
    sleep 0.2
    if [ -f "${WorkDir}/result/08-besttrace.result" ]; then
        cat ${WorkDir}/result/08-besttrace.result >>${WorkDir}/result/finalresult.txt
    fi
    sleep 0.2
    if [ -f "${WorkDir}/result/09-spoofer.result" ]; then
        cat ${WorkDir}/result/09-spoofer.result >>${WorkDir}/result/finalresult.txt
    fi
    sleep 0.2
    if [ -f "${WorkDir}/result/99-footer.result" ]; then
        cat ${WorkDir}/result/99-footer.result >>${WorkDir}/result/finalresult.txt
    fi
    sleep 0.2
    echo -e "${Msg_Info}Saving local Report ..."
    cp ${WorkDir}/result/finalresult.txt $HOME/LemonBench.Result.txt
    sleep 0.1
    echo -e "${Msg_Info}Generating Report URL ..."
    cat ${WorkDir}/result/finalresult.txt | PasteBin_Upload
}

Function_GenerateResult_Header() {
    sleep 0.1
    local rfile="${WorkDir}/result/00-header.result"
    echo -e " " >>$rfile
    echo -e " LemonBench Linux System Benchmark Utility Version ${BuildTime} " >>$rfile
    echo -e " " >>$rfile
    echo -e " Bench Start Time:\t${LBench_Result_BenchStartTime}" >>$rfile
    echo -e " Bench Finish Time:\t${LBench_Result_BenchFinishTime}" >>$rfile
    echo -e " Test Mode:\t\t${Global_TestModeTips}" >>$rfile
    echo -e " \n\n"
}

Function_GenerateResult_SystemInfo() {
    sleep 0.1
    local rfile="${WorkDir}/result/01-systeminfo.result"
    if [ "${LBench_Flag_FinishSystemInfo}" = "1" ]; then
        echo -e " \n -> System Information" >>$rfile
        echo -e " " >>$rfile
        echo -e " OS Release:\t\t${LBench_Result_OSReleaseFullName}" >>$rfile
        if [ "${Flag_DymanicCPUFreqDetected}" = "1" ]; then
            echo -e " CPU Model:\t\t${LBench_Result_CPUModelName}  ${LBench_Result_CPUFreqMinGHz}~${LBench_Result_CPUFreqMaxGHz} GHz" >>$rfile
        elif [ "${Flag_DymanicCPUFreqDetected}" = "0" ]; then
            echo -e " CPU Model:\t\t${LBench_Result_CPUModelName}  ${LBench_Result_CPUFreqGHz} GHz" >>$rfile
        fi
        echo -e " CPU Cache Size:\t${LBench_Result_CPUCacheSize}" >>$rfile
        if [ "${LBench_Result_CPUIsPhysical}" = "1" ]; then
            if [ "${LBench_Result_CPUPhysicalNumber}" -eq "1" ]; then
                echo -e " CPU Number:\t\t${LBench_Result_CPUPhysicalNumber} Physical CPU, ${LBench_Result_CPUCoreNumber} Cores, ${LBench_Result_CPUThreadNumber} Threads" >>$rfile
            elif [ "${LBench_Result_CPUPhysicalNumber}" -ge "2" ]; then
                echo -e " CPU Number:\t\t${LBench_Result_CPUPhysicalNumber} Physical CPUs, ${LBench_Result_CPUCoreNumber} Cores/CPU, ${LBench_Result_CPUSiblingsNumber} Thread)/CPU (Total ${LBench_Result_CPUTotalCoreNumber} Cores, ${LBench_Result_CPUProcessorNumber} Threads)" >>$rfile
            elif [ "${LBench_Result_CPUThreadNumber}" = "0" ] && [ "${LBench_Result_CPUProcessorNumber} " -ge "1" ]; then
                echo -e " CPU Number:\t\t${LBench_Result_CPUProcessorNumber} Cores" >>$rfile
            fi
            if [ "${LBench_Result_CPUVirtualization}" = "1" ]; then
                echo -e " VirtReady:\t\tYes (Based on ${LBench_Result_CPUVirtualizationType})" >>$rfile
            elif [ "${LBench_Result_CPUVirtualization}" = "2" ]; then
                echo -e " VirtReady:\t\tYes (Nested Virtualization)" >>$rfile
            else
                echo -e " VirtReady:\t\t${Font_SkyRed}No" >>$rfile
            fi
        elif [ "${Var_VirtType}" = "openvz" ]; then
            echo -e " CPU Number:\t\t${LBench_Result_CPUThreadNumber} vCPU (${LBench_Result_CPUCoreNumber} Host Core(s)/Thread(s))" >>$rfile
        else
            echo -e " CPU Number:\t\t${LBench_Result_CPUThreadNumber} vCPU" >>$rfile
        fi
        echo -e " Virt Type:\t\t${LBench_Result_VirtType}" >>$rfile
        echo -e " Memory Usage:\t\t${LBench_Result_Memory}" >>$rfile
        echo -e " Swap Usage:\t\t${LBench_Result_Swap}" >>$rfile
        if [ "${LBench_Result_DiskUsed_KB}" -lt "1000000" ]; then
            LBench_Result_Disk="${LBench_Result_DiskUsed_MB} MB / ${LBench_Result_DiskTotal_MB} MB"
            echo -e " Disk Usage:\t\t${LBench_Result_DiskUsed_MB} MB / ${LBench_Result_DiskTotal_MB} MB" >>$rfile
        elif [ "${LBench_Result_DiskUsed_KB}" -lt "1000000" ] && [ "${LBench_Result_DiskTotal_KB}" -lt "1000000000" ]; then
            LBench_Result_Disk="${LBench_Result_DiskUsed_MB} MB / ${LBench_Result_DiskTotal_GB} GB"
            echo -e " Disk Usage:\t\t${LBench_Result_DiskUsed_MB} MB / ${LBench_Result_DiskTotal_GB} GB" >>$rfile
        elif [ "${LBench_Result_DiskUsed_KB}" -lt "1000000000" ] && [ "${LBench_Result_DiskTotal_KB}" -lt "1000000000" ]; then
            LBench_Result_Disk="${LBench_Result_DiskUsed_GB} GB / ${LBench_Result_DiskTotal_GB} GB"
            echo -e " Disk Usage:\t\t${LBench_Result_DiskUsed_GB} GB / ${LBench_Result_DiskTotal_GB} GB" >>$rfile
        elif [ "${LBench_Result_DiskUsed_KB}" -lt "1000000000" ] && [ "${LBench_Result_DiskTotal_KB}" -ge "1000000000" ]; then
            LBench_Result_Disk="${LBench_Result_DiskUsed_GB} GB / ${LBench_Result_DiskTotal_TB} TB"
            echo -e " Disk Usage:\t\t${LBench_Result_DiskUsed_GB} GB / ${LBench_Result_DiskTotal_TB} TB" >>$rfile
        else
            LBench_Result_Disk="${LBench_Result_DiskUsed_TB} TB / ${LBench_Result_DiskTotal_TB} TB"
            echo -e " Disk Usage:\t\t${LBench_Result_DiskUsed_TB} TB / ${LBench_Result_DiskTotal_TB} TB" >>$rfile
        fi
        echo -e " Boot Device:\t\t${LBench_Result_DiskRootPath}" >>$rfile
        echo -e " Load (1/5/15min):\t${LBench_Result_LoadAverage_1min} ${LBench_Result_LoadAverage_5min} ${LBench_Result_LoadAverage_15min} " >>$rfile
        echo -e " CPU Usage:\t\t${LBench_Result_CPUStat_UsedAll}% used, ${LBench_Result_CPUStat_iowait}% iowait, ${LBench_Result_CPUStat_steal}% steal" >>$rfile
        echo -e " Kernel Version:\t${LBench_Result_KernelVersion}" >>$rfile
        echo -e " Network CC Method:\t${LBench_Result_NetworkCCMethod}" >>$rfile
    fi
}

Function_GenerateResult_NetworkInfo() {
    sleep 0.1
    if [ "${LBench_Flag_FinishNetworkInfo}" = "1" ]; then
        local rfile="${WorkDir}/result/02-networkinfo.result"
        echo -e "\n -> Network Information\n" >>$rfile
        if [ "${LBench_Result_NetworkStat}" = "ipv4only" ] || [ "${LBench_Result_NetworkStat}" = "dualstack" ]; then
            if [ "${IPAPI_IPV4_ip}" != "" ]; then
                local IPAPI_IPV4_ip_masked="$(echo ${IPAPI_IPV4_ip} | awk -F'.' '{print $1"."$2."."$3".*"}')"
                echo -e " IPV4 - IP Address:\t[${IPAPI_IPV4_country_code}] ${IPAPI_IPV4_ip_masked}" >>$rfile
                echo -e " IPV4 - ASN Info:\t${IPAPI_IPV4_asn} (${IPAPI_IPV4_organization})" >>$rfile
                echo -e " IPV4 - Region:\t\t${IPAPI_IPV4_location}" >>$rfile
            else
                echo -e " IPV6 - IP Address:\tError: API Query Failed" >>$rfile
            fi
        fi
        if [ "${LBench_Result_NetworkStat}" = "ipv6only" ] || [ "${LBench_Result_NetworkStat}" = "dualstack" ]; then
            if [ "${IPAPI_IPV6_ip}" != "" ]; then
                local IPAPI_IPV6_IP_Masked="$(echo ${IPAPI_IPV6_ip} | sed "s/[0-9a-f]\{1,4\}.$/*/g")"
                echo -e " IPV6 - IP Address:\t[${IPAPI_IPV6_country_code}] ${IPAPI_IPV6_IP_Masked}" >>$rfile
                echo -e " IPV6 - ASN Info:\t${IPAPI_IPV6_asn} (${IPAPI_IPV6_organization})" >>$rfile
                echo -e " IPV6 - Region:\t\t${IPAPI_IPV6_location}" >>$rfile
            else
                echo -e " IPV6 - IP Address:\tError: API Query Failed" >>$rfile
            fi
        fi
    fi
}

Function_GenerateResult_MediaUnlockTest() {
    sleep 0.1
    if [ "${LBench_Flag_FinishMediaUnlockTest}" = "1" ]; then
        local rfile="${WorkDir}/result/03-mediaunlocktest.result"
        echo -e "\n -> Media Unlock Test\n" >>$rfile
        # HBO Now
        echo -e " HBO Now:\t\t\t\t${LemonBench_Result_MediaUnlockTest_HBONow}" >>$rfile
        # 动画疯
        echo -e " Bahamut Anime:\t\t\t\t${LemonBench_Result_MediaUnlockTest_BahamutAnime}" >>$rfile
        # Abema.TV
        echo -e " Abema.TV:\t\t\t\t${LemonBench_Result_MediaUnlockTest_AbemaTV_IPTest}" >>$rfile
        # Princess Connect Re:Dive 日服
        echo -e " Princess Connect Re:Dive Japan:\t${LemonBench_Result_MediaUnlockTest_PCRJP}" >>$rfile
        # 爱奇艺台湾站
        # echo -e " IQiYi Taiwan (Beta):\t\t\t${LemonBench_Result_MediaUnlockTest_IQiYi_Taiwan}" >>$rfile
        # BBC
        echo -e " BBC:\t\t\t\t\t${LemonBench_Result_MediaUnlockTest_BBC}" >>$rfile
        # 哔哩哔哩大陆限定
        echo -e " Bilibili China Mainland Only:\t\t${LemonBench_Result_MediaUnlockTest_ChinaMainland}" >>$rfile
        # 哔哩哔哩港澳台
        echo -e " Bilibili Hongkong/Macau/Taiwan:\t${LemonBench_Result_MediaUnlockTest_BilibiliHKMCTW}" >>$rfile
        # 哔哩哔哩台湾限定
        echo -e " Bilibili Taiwan Only:\t\t\t${LemonBench_Result_MediaUnlockTest_BilibiliTW}" >>$rfile
    fi
}

Function_GenerateResult_SysBench_CPUTest() {
    sleep 0.1
    if [ -f "${WorkDir}/SysBench/CPU/result.txt" ]; then
        cp -f ${WorkDir}/SysBench/CPU/result.txt ${WorkDir}/result/04-cputest.result
    fi
}

Function_GenerateResult_SysBench_MemoryTest() {
    sleep 0.1
    if [ -f "${WorkDir}/SysBench/Memory/result.txt" ]; then
        cp -f ${WorkDir}/SysBench/Memory/result.txt ${WorkDir}/result/05-memorytest.result
    fi
}

Function_GenerateResult_DiskTest() {
    sleep 0.1
    if [ -f "${WorkDir}/DiskTest/result.txt" ]; then
        cp -f ${WorkDir}/DiskTest/result.txt ${WorkDir}/result/06-disktest.result
    fi
}

Function_GenerateResult_Speedtest() {
    sleep 0.1
    if [ -f "${WorkDir}/Speedtest/result.txt" ]; then
        cp -f ${WorkDir}/Speedtest/result.txt ${WorkDir}/result/07-speedtest.result
    fi
}

Function_GenerateResult_BestTrace() {
    sleep 0.1
    if [ -f "${WorkDir}/BestTrace/result.txt" ]; then
        cp -f ${WorkDir}/BestTrace/result.txt ${WorkDir}/result/08-besttrace.result
    fi
}

Function_GenerateResult_Spoofer() {
    sleep 0.1
    if [ -f "${WorkDir}/Spoofer/result.txt" ]; then
        cp -f ${WorkDir}/Spoofer/result.txt ${WorkDir}/result/09-spoofer.result
    fi
}

Function_GenerateResult_Footer() {
    sleep 0.1
    local rfile="${WorkDir}/result/99-footer.result"
    echo -e "\nGenerated by LemonBench on $(date -u "+%Y-%m-%dT%H:%M:%SZ") Version ${BuildTime}\n" >>$rfile
    # 恰饭时间！（雾
    echo -e "[AD] 高质量美西CN2 GIA with ARIN IP (可直接解锁常见流媒体)，1核心/2G内存/15G SSD/1IP/1TB单向流量\n季付仅需588元/季度，年付仅需1899元/年，做站理想之选！\n使用优惠码 BW9K1IPZXN 即刻享受优惠价格！ \n购买传送门： http://ilemonra.in/HKSSLaxGIAPromo" >>$rfile
    echo -e " \n"  >>$rfile
}

# =============== 检查 Virt-what 组件 ===============
Check_Virtwhat() {
    if [ ! -f "/usr/sbin/virt-what" ]; then
        SystemInfo_GetOSRelease
        if [ "${Var_OSRelease}" = "centos" ] || [ "${Var_OSRelease}" = "rhel" ]; then
            echo -e "${Msg_Warning}Virt-What Module not found, Installing ..."
            yum -y install virt-what
        elif [ "${Var_OSRelease}" = "ubuntu" ] || [ "${Var_OSRelease}" = "debian" ]; then
            echo -e "${Msg_Warning}Virt-What Module not found, Installing ..."
            apt-get update
            apt-get install -y virt-what dmidecode
        elif [ "${Var_OSRelease}" = "fedora" ]; then
            echo -e "${Msg_Warning}Virt-What Module not found, Installing ..."
            dnf -y install virt-what
        elif [ "${Var_OSRelease}" = "alpinelinux" ]; then
            echo -e "${Msg_Warning}Virt-What Module not found, Installing ..."
            apk update
            apk add virt-what
        else
            echo -e "${Msg_Warning}Virt-What Module not found, but we could not find the os's release ..."
        fi
    fi
    # 二次检测
    if [ ! -f "/usr/sbin/virt-what" ]; then
        echo -e "Virt-What Moudle install Failure! Try Restart Bench or Manually install it! (/usr/sbin/virt-what)"
        exit 1
    fi
}

# =============== 检查 Speedtest 组件 ===============
Check_Speedtest() {
    if [ -f "/usr/local/lemonbench/bin/speedtest" ]; then
        chmod +x /usr/local/lemonbench/bin/speedtest >/dev/null 2>&1
        /usr/local/lemonbench/bin/speedtest --version >/dev/null 2>&1
        if [ "$?" = "0" ]; then
            return 0
        else
            rm -f /usr/local/lemonbench/bin/speedtest
            Check_Speedtest_GetComponent
        fi
    else
        Check_Speedtest_GetComponent
    fi
}

Check_Speedtest_GetComponent() {
    SystemInfo_GetOSRelease
    SystemInfo_GetSystemBit
    if [ "${LBench_Result_SystemBit_Full}" = "amd64" ]; then
        local DownloadSrc="https://raindrop.ilemonrain.com/LemonBench/include/Speedtest/1.0.0.2/speedtest-amd64.tar.gz"
    elif [ "${LBench_Result_SystemBit_Full}" = "i386" ]; then
        local DownloadSrc="https://raindrop.ilemonrain.com/LemonBench/include/Speedtest/1.0.0.2/speedtest-i386.tar.gz"
    elif [ "${LBench_Result_SystemBit_Full}" = "arm" ]; then
        local DownloadSrc="https://raindrop.ilemonrain.com/LemonBench/include/Speedtest/1.0.0.2/speedtest-arm.tar.gz"
    else
        local DownloadSrc="https://raindrop.ilemonrain.com/LemonBench/include/Speedtest/1.0.0.2/speedtest-i386.tar.gz"
    fi
    if [ "${Var_OSRelease}" = "centos" ] || [ "${Var_OSRelease}" = "rhel" ]; then
        echo -e "${Msg_Warning}Speedtest Module not found, Installing ..."
        echo -e "${Msg_Info}Installing Dependency ..."
        yum makecache fast
        yum -y install curl
        echo -e "${Msg_Info}Installing Speedtest Module ..."
        mkdir -p ${WorkDir}/.DownTmp >/dev/null 2>&1
        pushd ${WorkDir}/.DownTmp >/dev/null
        curl --user-agent "${UA_LemonBench}" ${DownloadSrc} -o ${WorkDir}/.DownTmp/speedtest.tar.gz
        tar xf ${WorkDir}/.DownTmp/speedtest.tar.gz
        mkdir -p /usr/local/lemonbench/bin/ >/dev/null 2>&1
        mv ${WorkDir}/.DownTmp/speedtest /usr/local/lemonbench/bin/
        chmod +x /usr/local/lemonbench/bin/speedtest
        echo -e "${Msg_Info}Cleaning up ..."
        popd >/dev/null
        rm -rf ${WorkDir}/.DownTmp
    elif [ "${Var_OSRelease}" = "ubuntu" ] || [ "${Var_OSRelease}" = "debian" ]; then
        echo -e "${Msg_Warning}Speedtest Module not found, Installing ..."
        echo -e "${Msg_Info}Installing Dependency ..."
        apt-get update
        apt-get --no-install-recommends -y install curl
        echo -e "${Msg_Info}Installing Speedtest Module ..."
        mkdir -p ${WorkDir}/.DownTmp >/dev/null 2>&1
        pushd ${WorkDir}/.DownTmp >/dev/null
        curl --user-agent "${UA_LemonBench}" ${DownloadSrc} -o ${WorkDir}/.DownTmp/speedtest.tar.gz
        tar xf ${WorkDir}/.DownTmp/speedtest.tar.gz
        mkdir -p /usr/local/lemonbench/bin/ >/dev/null 2>&1
        mv ${WorkDir}/.DownTmp/speedtest /usr/local/lemonbench/bin/
        chmod +x /usr/local/lemonbench/bin/speedtest
        echo -e "${Msg_Info}Cleaning up ..."
        popd >/dev/null
        rm -rf ${WorkDir}/.DownTmp
    elif [ "${Var_OSRelease}" = "fedora" ]; then
        echo -e "${Msg_Warning}Speedtest Module not found, Installing ..."
        echo -e "${Msg_Info}Installing Dependency ..."
        dnf -y install curl
        echo -e "${Msg_Info}Installing Speedtest Module ..."
        mkdir -p ${WorkDir}/.DownTmp >/dev/null 2>&1
        pushd ${WorkDir}/.DownTmp >/dev/null
        curl --user-agent "${UA_LemonBench}" ${DownloadSrc} -o ${WorkDir}/.DownTmp/speedtest.tar.gz
        tar xf ${WorkDir}/.DownTmp/speedtest.tar.gz
        mkdir -p /usr/local/lemonbench/bin/ >/dev/null 2>&1
        mv ${WorkDir}/.DownTmp/speedtest /usr/local/lemonbench/bin/
        chmod +x /usr/local/lemonbench/bin/speedtest
        echo -e "${Msg_Info}Cleaning up ..."
        popd >/dev/null
        rm -rf ${WorkDir}/.DownTmp
    elif [ "${Var_OSRelease}" = "alpinelinux" ]; then
        echo -e "${Msg_Warning}Speedtest Module not found, Installing ..."
        echo -e "${Msg_Info}Installing Dependency ..."
        apk update
        apk add curl
        echo -e "${Msg_Info}Installing Speedtest Module ..."
        mkdir -p ${WorkDir}/.DownTmp >/dev/null 2>&1
        pushd ${WorkDir}/.DownTmp >/dev/null
        curl --user-agent "${UA_LemonBench}" ${DownloadSrc} -o ${WorkDir}/.DownTmp/speedtest.tar.gz
        tar xf ${WorkDir}/.DownTmp/speedtest.tar.gz
        mkdir -p /usr/local/lemonbench/bin/ >/dev/null 2>&1
        mv ${WorkDir}/.DownTmp/speedtest /usr/local/lemonbench/bin/
        chmod +x /usr/local/lemonbench/bin/speedtest
        echo -e "${Msg_Info}Cleaning up ..."
        popd >/dev/null
        rm -rf ${WorkDir}/.DownTmp
    else
        echo -e "${Msg_Warning}Speedtest Module not found, trying direct download ..."
        mkdir -p ${WorkDir}/.DownTmp >/dev/null 2>&1
        pushd ${WorkDir}/.DownTmp >/dev/null
        curl --user-agent "${UA_LemonBench}" ${DownloadSrc} -o ${WorkDir}/.DownTmp/speedtest.tar.gz
        tar xf ${WorkDir}/.DownTmp/speedtest.tar.gz
        mkdir -p /usr/local/lemonbench/bin/ >/dev/null 2>&1
        mv ${WorkDir}/.DownTmp/speedtest /usr/local/lemonbench/bin/
        chmod +x /usr/local/lemonbench/bin/speedtest
        echo -e "${Msg_Info}Cleaning up ..."
        popd >/dev/null
        rm -rf ${WorkDir}/.DownTmp
    fi
    /usr/local/lemonbench/bin/speedtest --version >/dev/null 2>&1
    if [ "$?" != "0" ]; then
        echo -e "Speedtest Moudle install Failure! Try Restart Bench or Manually install it!"
        exit 1
    fi
}

# =============== 检查 BestTrace 组件 ===============
Check_BestTrace() {
    if [ ! -f "/usr/local/lemonbench/bin/besttrace" ]; then
        SystemInfo_GetOSRelease
        SystemInfo_GetSystemBit
        if [ "${LBench_Result_SystemBit_Full}" = "amd64" ]; then
            local BinaryName="besttrace64"
            local DownloadSrc="https://raindrop.ilemonrain.com/LemonBench/include/BestTrace/besttrace64.tar.gz"
            # local DownloadSrc="https://raw.githubusercontent.com/LemonBench/LemonBench/master/Resources/BestTrace/besttrace64.tar.gz"
        elif [ "${LBench_Result_SystemBit_Full}" = "i386" ]; then
            local BinaryName="besttrace32"
            local DownloadSrc="https://raindrop.ilemonrain.com/LemonBench/include/BestTrace/besttrace32.tar.gz"
            # local DownloadSrc="https://raw.githubusercontent.com/LemonBench/LemonBench/master/Resources/BestTrace/besttrace32.tar.gz"
        elif [ "${LBench_Result_SystemBit_Full}" = "arm" ]; then
            local BinaryName="besttracearm"
            local DownloadSrc="https://raindrop.ilemonrain.com/LemonBench/include/BestTrace/besttracearm.tar.gz"
            # local DownloadSrc="https://raw.githubusercontent.com/LemonBench/LemonBench/master/Resources/BestTrace/besttracearm.tar.gz"
        else
            local BinaryName="besttrace32"
            local DownloadSrc="https://raindrop.ilemonrain.com/LemonBench/include/BestTrace/besttrace32.tar.gz"
            # local DownloadSrc="https://raw.githubusercontent.com/LemonBench/LemonBench/master/Resources/BestTrace/besttrace32.tar.gz"
        fi
        mkdir -p ${WorkDir}/ >/dev/null 2>&1
        mkdir -p /usr/local/lemonbench/bin/ >/dev/null 2>&1
        if [ "${Var_OSRelease}" = "centos" ] || [ "${Var_OSRelease}" = "rhel" ]; then
            echo -e "${Msg_Warning}BestTrace Module not found, Installing ..."
            echo -e "${Msg_Info}Installing Dependency ..."
            yum -y install curl unzip
            echo -e "${Msg_Info}Downloading BestTrace Module ..."
            curl --user-agent "${UA_LemonBench}" ${DownloadSrc} -o ${WorkDir}/besttrace.tar.gz
            echo -e "${Msg_Info}Installing BestTrace Module ..."
            pushd ${WorkDir} >/dev/null
            tar xf besttrace.tar.gz
            mv ${BinaryName} /usr/local/lemonbench/bin/besttrace
            chmod +x /usr/local/lemonbench/bin/besttrace
            popd >/dev/null
            echo -e "${Msg_Info}Cleaning up ..."
            rm -rf ${WorkDir}/besttrace.tar.gz
        elif [ "${Var_OSRelease}" = "ubuntu" ] || [ "${Var_OSRelease}" = "debian" ]; then
            echo -e "${Msg_Warning}BestTrace Module not found, Installing ..."
            echo -e "${Msg_Info}Installing Dependency ..."
            apt-get update
            apt-get --no-install-recommends -y install wget unzip curl ca-certificates
            echo -e "${Msg_Info}Downloading BestTrace Module ..."
            curl --user-agent "${UA_LemonBench}" ${DownloadSrc} -o ${WorkDir}/besttrace.tar.gz
            echo -e "${Msg_Info}Installing BestTrace Module ..."
            pushd ${WorkDir} >/dev/null
            tar xf besttrace.tar.gz
            mv ${BinaryName} /usr/local/lemonbench/bin/besttrace
            chmod +x /usr/local/lemonbench/bin/besttrace
            popd >/dev/null
            echo -e "${Msg_Info}Cleaning up ..."
            rm -rf ${WorkDir}/besttrace.tar.gz
        elif [ "${Var_OSRelease}" = "fedora" ]; then
            echo -e "${Msg_Warning}BestTrace Module not found, Installing ..."
            echo -e "${Msg_Info}Installing Dependency ..."
            dnf -y install wget unzip curl
            echo -e "${Msg_Info}Downloading BestTrace Module ..."
            curl  --user-agent "${UA_LemonBench}" ${DownloadSrc} -o ${WorkDir}/besttrace.tar.gz
            echo -e "${Msg_Info}Installing BestTrace Module ..."
            pushd ${WorkDir} >/dev/null
            tar xf besttrace.tar.gz
            mv ${BinaryName} /usr/local/lemonbench/bin/besttrace
            chmod +x /usr/local/lemonbench/bin/besttrace
            popd >/dev/null
            echo -e "${Msg_Info}Cleaning up ..."
            rm -rf ${WorkDir}/besttrace.tar.gz
        elif [ "${Var_OSRelease}" = "alpinelinux" ]; then
            echo -e "${Msg_Warning}BestTrace Module not found, Installing ..."
            echo -e "${Msg_Info}Installing Dependency ..."
            apk update
            apk add wget unzip curl
            echo -e "${Msg_Info}Downloading BestTrace Module ..."
            curl --user-agent "${UA_LemonBench}" ${DownloadSrc} -o ${WorkDir}/besttrace.tar.gz
            echo -e "${Msg_Info}Installing BestTrace Module ..."
            pushd ${WorkDir} >/dev/null
            tar xf besttrace.tar.gz
            mv ${BinaryName} /usr/local/lemonbench/bin/besttrace
            chmod +x /usr/local/lemonbench/bin/besttrace
            popd >/dev/null
            echo -e "${Msg_Info}Cleaning up ..."
            rm -rf ${WorkDir}/besttrace.tar.gz
        else
            echo -e "${Msg_Warning}BestTrace Module not found, but we could not find the os's release ..."
        fi
    fi
    # 二次检测
    if [ ! -f "/usr/local/lemonbench/bin/besttrace" ]; then
        echo -e "BestTrace Moudle install Failure! Try Restart Bench or Manually install it! (/usr/local/lemonbench/bin/besttrace)"
        exit 1
    fi
}

# =============== 检查 JSON Query 组件 ===============
Check_JSONQuery() {
    if [ ! -f "/usr/bin/jq" ]; then
        SystemInfo_GetOSRelease
        SystemInfo_GetSystemBit
        if [ "${LBench_Result_SystemBit_Short}" = "64" ]; then
            local DownloadSrc="https://raindrop.ilemonrain.com/LemonBench/include/JSONQuery/jq-amd64.tar.gz"
            # local DownloadSrc="https://raw.githubusercontent.com/LemonBench/LemonBench/master/Resources/JSONQuery/jq-amd64.tar.gz"
            # local DownloadSrc="https://raindrop.ilemonrain.com/LemonBench/include/jq/1.6/amd64/jq.tar.gz"
        elif [ "${LBench_Result_SystemBit_Short}" = "32" ]; then
            local DownloadSrc="https://raindrop.ilemonrain.com/LemonBench/include/JSONQuery/jq-i386.tar.gz"
            # local DownloadSrc="https://raw.githubusercontent.com/LemonBench/LemonBench/master/Resources/JSONQuery/jq-i386.tar.gz"
            # local DownloadSrc="https://raindrop.ilemonrain.com/LemonBench/include/jq/1.6/i386/jq.tar.gz"
        else
            local DownloadSrc="https://raindrop.ilemonrain.com/LemonBench/include/JSONQuery/jq-i386.tar.gz"
            # local DownloadSrc="https://raw.githubusercontent.com/LemonBench/LemonBench/master/Resources/JSONQuery/jq-i386.tar.gz"
            # local DownloadSrc="https://raindrop.ilemonrain.com/LemonBench/include/jq/1.6/i386/jq.tar.gz"
        fi
        mkdir -p ${WorkDir}/
        if [ "${Var_OSRelease}" = "centos" ] || [ "${Var_OSRelease}" = "rhel" ]; then
            echo -e "${Msg_Warning}JSON Query Module not found, Installing ..."
            echo -e "${Msg_Info}Installing Dependency ..."
            yum install -y epel-release
            yum install -y jq
        elif [ "${Var_OSRelease}" = "ubuntu" ] || [ "${Var_OSRelease}" = "debian" ]; then
            echo -e "${Msg_Warning}JSON Query Module not found, Installing ..."
            echo -e "${Msg_Info}Installing Dependency ..."
            apt-get update
            apt-get install -y jq
        elif [ "${Var_OSRelease}" = "fedora" ]; then
            echo -e "${Msg_Warning}JSON Query Module not found, Installing ..."
            echo -e "${Msg_Info}Installing Dependency ..."
            dnf install -y jq
        elif [ "${Var_OSRelease}" = "alpinelinux" ]; then
            echo -e "${Msg_Warning}JSON Query Module not found, Installing ..."
            echo -e "${Msg_Info}Installing Dependency ..."
            apk update
            apk add jq
        else
            echo -e "${Msg_Warning}JSON Query Module not found, Installing ..."
            echo -e "${Msg_Info}Installing Dependency ..."
            apk update
            apk add wget unzip curl
            echo -e "${Msg_Info}Downloading Json Query Module ..."
            curl --user-agent "${UA_LemonBench}" ${DownloadSrc} -o ${WorkDir}/jq.tar.gz
            echo -e "${Msg_Info}Installing JSON Query Module ..."
            tar xvf ${WorkDir}/jq.tar.gz
            mv ${WorkDir}/jq /usr/bin/jq
            chmod +x /usr/bin/jq
            echo -e "${Msg_Info}Cleaning up ..."
            rm -rf ${WorkDir}/jq.tar.gz
        fi
    fi
    # 二次检测
    if [ ! -f "/usr/bin/jq" ]; then
        echo -e "JSON Query Moudle install Failure! Try Restart Bench or Manually install it! (/usr/bin/jq)"
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
        echo -e "${Msg_Warning}Spoof Module not found, Installing ..."
        Check_Spoofer_PreBuild
    fi
    # 如果预编译安装失败了, 则开始编译安装
    if [ ! -f "/usr/local/bin/spoofer-prober" ]; then
        echo -e "${Msg_Warning}Spoof Module with Pre-Build Failed, trying complie ..."
        Check_Spoofer_InstantBuild
    fi
    # 如果编译安装仍然失败, 则停止运行
    if [ ! -f "/usr/local/bin/spoofer-prober" ]; then
        echo -e "${Msg_Error}Spoofer Moudle install Failure! Try Restart Bench or Manually install it! (/usr/local/bin/spoofer-prober)"
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
        echo -e "${Msg_Warning}Pre-Build current does not support 32-bit system, starting compile process ..."
        Check_Spoofer_InstantBuild
    fi
    if [ "${SysBit}" = "unknown" ] || [ "${SysVer}" = "unknown" ]; then
        echo -e "${Msg_Warning}无法确认当前系统的版本号及位数, 或目前暂不支持预编译组件！"
    else
        if [ "${SysRel}" = "centos" ]; then
            echo -e "${Msg_Info}Release Detected: ${SysRel} ${SysVer} ${SysBit}"
            echo -e "${Msg_Info}Installing Dependency"
            yum install -y epel-release
            yum install -y protobuf-devel libpcap-devel openssl-devel traceroute wget curl
            local Spoofer_Version="$(curl  --user-agent "${UA_LemonBench}" -fskSL https://raindrop.ilemonrain.com/LemonBench/include/Spoofer/latest_version)"
            echo -e "${Msg_Info}Downloading Spoof Module (Version ${Spoofer_Version}) ..."
            mkdir -p /tmp/_LBench/src/
            wget -U "${UA_LemonBench}" -O /tmp/_LBench/src/spoofer-prober.gz https://raindrop.ilemonrain.com/LemonBench/include/Spoofer/${Spoofer_Version}/${SysRel}/${SysVer}/${SysBit}/spoofer-prober.gz
            echo -e "${Msg_Info}Installing Spoof Module ..."
            tar xf /tmp/_LBench/src/spoofer-prober.gz
            cp -f /tmp/_LBench/src/spoofer-prober /usr/local/bin/spoofer-prober
            chmod +x /usr/local/bin/spoofer-prober
            echo -e "${Msg_Info}Cleaning up ..."
            rm -f /tmp/_LBench/src/spoofer-prober.tar.gz
            rm -f /tmp/_LBench/src/spoofer-prober
        elif [ "${SysRel}" = "ubuntu" ] || [ "${SysRel}" = "debian" ]; then
            echo -e "${Msg_Info}Release Detected: ${SysRel} ${SysVer} ${SysBit}"
            echo -e "${Msg_Info}Installing Dependency"
            apt-get update
            apt-get install --no-install-recommends -y ca-certificates libprotobuf-dev libpcap-dev traceroute wget curl
            local Spoofer_Version="$(curl  --user-agent "${UA_LemonBench}" -fskSL https://raindrop.ilemonrain.com/LemonBench/include/Spoofer/latest_version)"
            echo -e "${Msg_Info}Downloading Spoof Module (Version ${Spoofer_Version}) ..."
            mkdir -p /tmp/_LBench/src/
            wget -U "${UA_LemonBench}" -O /tmp/_LBench/src/spoofer-prober.gz https://raindrop.ilemonrain.com/LemonBench/include/Spoofer/${Spoofer_Version}/${SysRel}/${SysVer}/${SysBit}/spoofer-prober.gz
            echo -e "${Msg_Info}Installing Spoof Module ..."
            tar xf /tmp/_LBench/src/spoofer-prober.gz
            cp -f /tmp/_LBench/src/spoofer-prober /usr/local/bin/spoofer-prober
            chmod +x /usr/local/bin/spoofer-prober
            echo -e "${Msg_Info}Cleaning up ..."
            rm -f /tmp/_LBench/src/spoofer-prober.tar.gz
            rm -f /tmp/_LBench/src/spoofer-prober
        else
            echo -e "${Msg_Warning}We cannot figure out the system bit or os release, so we cannot use the pre-build module！"
        fi
    fi
}

Check_Spoofer_InstantBuild() {
    SystemInfo_GetOSRelease
    SystemInfo_GetCPUInfo
    if [ "${Var_OSRelease}" = "centos" ] || [ "${Var_OSRelease}" = "rhel" ]; then
        echo -e "${Msg_Info}Release Detected: ${Var_OSRelease}"
        echo -e "${Msg_Info}Preparing compile enviorment ..."
        yum install -y epel-release
        yum install -y wget curl make gcc gcc-c++ traceroute openssl-devel protobuf-devel bison flex libpcap-devel
        local Spoofer_Version="$(curl  --user-agent "${UA_LemonBench}"  -fskSL https://raindrop.ilemonrain.com/LemonBench/include/Spoofer/latest_version)"
        echo -e "${Msg_Info}Downloading Source code (Version ${Spoofer_Version})..."
        mkdir -p /tmp/_LBench/src/
        wget -U "${UA_LemonBench}" -O /tmp/_LBench/src/spoofer.tar.gz https://raindrop.ilemonrain.com/LemonBench/include/Spoofer/${Spoofer_Version}/spoofer.tar.gz
        echo -e "${Msg_Info}Compiling Spoof Module ..."
        cd /tmp/_LBench/src/
        tar xvf spoofer.tar.gz && cd spoofer-"${Spoofer_Version}"
        # 测试性补丁
        wget -U "${UA_LemonBench}" -O /tmp/_LBench/src/configure.patch https://raindrop.ilemonrain.com/LemonBench/include/Spoofer/${Spoofer_Version}/patch/configure.patch
        patch -p0 configure /tmp/_LBench/src/configure.patch
        ./configure && make -j ${LBench_Result_CPUThreadNumber}
        cp prober/spoofer-prober /usr/local/bin/spoofer-prober
        echo -e "${Msg_Info}Cleaning up ..."
        cd /tmp && rm -rf /tmp/_LBench/src/spoofer*
    elif [ "${Var_OSRelease}" = "ubuntu" ] || [ "${Var_OSRelease}" = "debian" ]; then
        echo -e "${Msg_Info}Release Detected: ${Var_OSRelease}"
        echo -e "${Msg_Info}Preparing compile enviorment ..."
        apt-get update
        apt-get install -y --no-install-recommends wget curl gcc g++ make traceroute protobuf-compiler libpcap-dev libprotobuf-dev openssl libssl-dev ca-certificates
        local Spoofer_Version="$(curl --user-agent "${UA_LemonBench}" -fskSL https://raindrop.ilemonrain.com/LemonBench/include/Spoofer/latest_version)"
        echo -e "${Msg_Info}Downloading Source code (Version ${Spoofer_Version})..."
        mkdir -p /tmp/_LBench/src/
        wget -U "${UA_LemonBench}" -O /tmp/_LBench/src/spoofer.tar.gz https://raindrop.ilemonrain.com/LemonBench/include/Spoofer/${Spoofer_Version}/spoofer.tar.gz
        echo -e "${Msg_Info}Compiling Spoof Module ..."
        cd /tmp/_LBench/src/
        tar xvf spoofer.tar.gz && cd spoofer-"${Spoofer_Version}"
        # 测试性补丁
        wget -U "${UA_LemonBench}" -O /tmp/_LBench/src/configure.patch https://raindrop.ilemonrain.com/LemonBench/include/Spoofer/${Spoofer_Version}/patch/configure.patch
        patch -p0 configure /tmp/_LBench/src/configure.patch
        ./configure && make -j ${LBench_Result_CPUThreadNumber}
        cp prober/spoofer-prober /usr/local/bin/spoofer-prober
        echo -e "${Msg_Info}Cleaning up ..."
        cd /tmp && rm -rf /tmp/_LBench/src/spoofer*
    elif [ "${Var_OSRelease}" = "fedora" ]; then
        echo -e "${Msg_Info}Release Detected: ${Var_OSRelease}"
        echo -e "${Msg_Info}Preparing compile enviorment ..."
        dnf install -y wget curl make gcc gcc-c++ traceroute openssl-devel protobuf-devel bison flex libpcap-devel
        local Spoofer_Version="$(curl --user-agent "${UA_LemonBench}" -fskSL https://raindrop.ilemonrain.com/LemonBench/include/Spoofer/latest_version)"
        echo -e "${Msg_Info}Downloading Source code (Version ${Spoofer_Version})..."
        mkdir -p /tmp/_LBench/src/
        wget -U "${UA_LemonBench}" -O /tmp/_LBench/src/spoofer.tar.gz https://raindrop.ilemonrain.com/LemonBench/include/Spoofer/${Spoofer_Version}/spoofer.tar.gz
        echo -e "${Msg_Info}Compiling Spoof Module ..."
        cd /tmp/_LBench/src/
        tar xvf spoofer.tar.gz && cd spoofer-"${Spoofer_Version}"
        # 测试性补丁
        wget -U "${UA_LemonBench}" -O /tmp/_LBench/src/configure.patch https://raindrop.ilemonrain.com/LemonBench/include/Spoofer/${Spoofer_Version}/patch/configure.patch
        patch -p0 configure /tmp/_LBench/src/configure.patch
        ./configure && make -j ${LBench_Result_CPUThreadNumber}
        cp prober/spoofer-prober /usr/local/bin/spoofer-prober
        echo -e "${Msg_Info}Cleaning up ..."
        cd /tmp && rm -rf /tmp/_LBench/src/spoofer*
    elif [ "${Var_OSRelease}" = "alpinelinux" ]; then
        echo -e "${Msg_Info}Release Detected: ${Var_OSRelease}"
        echo -e "${Msg_Info}Preparing compile enviorment ..."
        apk update
        apk add traceroute gcc g++ make openssl-dev protobuf-dev libpcap-dev
        local Spoofer_Version="$(curl  --user-agent "${UA_LemonBench}"  -fskSL https://raindrop.ilemonrain.com/LemonBench/include/Spoofer/latest_version)"
        echo -e "${Msg_Info}Downloading Source code (Version ${Spoofer_Version})..."
        mkdir -p /tmp/_LBench/src/
        wget -U "${UA_LemonBench}" -O /tmp/_LBench/src/spoofer.tar.gz https://raindrop.ilemonrain.com/LemonBench/include/Spoofer/${Spoofer_Version}/spoofer.tar.gz
        echo -e "${Msg_Info}Compiling Spoof Module ..."
        cd /tmp/_LBench/src/
        tar xvf spoofer.tar.gz && cd spoofer-"${Spoofer_Version}"
        # 测试性补丁
        wget -U "${UA_LemonBench}" -O /tmp/_LBench/src/configure.patch https://raindrop.ilemonrain.com/LemonBench/include/Spoofer/${Spoofer_Version}/patch/configure.patch
        patch -p0 configure /tmp/_LBench/src/configure.patch
        ./configure && make -j ${LBench_Result_CPUThreadNumber}
        cp prober/spoofer-prober /usr/local/bin/spoofer-prober
        echo -e "${Msg_Info}Cleaning up ..."
        cd /tmp && rm -rf /tmp/_LBench/src/spoofer*
    else
        echo -e "${Msg_Error}Cannot compile on current enviorment！ (Only Support CentOS/Debian/Ubuntu/Fedora/AlpineLinux) "
    fi
}

# =============== 检查 SysBench 组件 ===============
Check_SysBench() {
    if [ ! -f "/usr/bin/sysbench" ] && [ ! -f "/usr/local/bin/sysbench" ]; then
        SystemInfo_GetOSRelease
        SystemInfo_GetSystemBit
        if [ "${Var_OSRelease}" = "centos" ] || [ "${Var_OSRelease}" = "rhel" ]; then
            echo -e "${Msg_Warning}Sysbench Module not found, installing ..."
            yum -y install epel-release
            yum -y install sysbench
        elif [ "${Var_OSRelease}" = "ubuntu" ]; then
            echo -e "${Msg_Warning}Sysbench Module not found, installing ..."
            apt-get install -y sysbench
        elif [ "${Var_OSRelease}" = "debian" ]; then
            echo -e "${Msg_Warning}Sysbench Module not found, installing ..."
            local mirrorbase="https://raindrop.ilemonrain.com/LemonBench"
            local componentname="Sysbench"
            local version="1.0.19-1"
            local arch="debian"
            local codename="${Var_OSReleaseVersion_Codename}"
            local bit="${LBench_Result_SystemBit_Full}"
            local filenamebase="sysbench"
            local filename="${filenamebase}_${version}_${bit}.deb"
            local downurl="${mirrorbase}/include/${componentname}/${version}/${arch}/${codename}/${filename}"
            mkdir -p ${WorkDir}/download/
            pushd ${WorkDir}/download/ >/dev/null
            wget -U "${UA_LemonBench}" -O ${filenamebase}_${version}_${bit}.deb ${downurl}
            dpkg -i ./${filename}
            apt-get install -f -y
            popd
            if [ ! -f "/usr/bin/sysbench" ] && [ ! -f "/usr/local/bin/sysbench" ]; then
                echo -e "${Msg_Warning}Sysbench Module Install Failed!"
            fi
        elif [ "${Var_OSRelease}" = "fedora" ]; then
            echo -e "${Msg_Warning}Sysbench Module not found, installing ..."
            dnf -y install sysbench
        elif [ "${Var_OSRelease}" = "alpinelinux" ]; then
            echo -e "${Msg_Warning}Sysbench Module not found, installing ..."
            echo -e "${Msg_Warning}SysBench Current not support Alpine Linux, Skipping..."
            Var_Skip_SysBench="1"
        fi
    fi
    # 垂死挣扎 (尝试编译安装)
    if [ ! -f "/usr/bin/sysbench" ] && [ ! -f "/usr/local/bin/sysbench" ]; then
        echo -e "${Msg_Warning}Sysbench Module install Failure, trying compile modules ..."
        Check_Sysbench_InstantBuild
    fi
    # 最终检测
    if [ ! -f "/usr/bin/sysbench" ] && [ ! -f "/usr/local/bin/sysbench" ]; then
        echo -e "${Msg_Error}SysBench Moudle install Failure! Try Restart Bench or Manually install it! (/usr/bin/sysbench)"
        exit 1
    fi
}

Check_Sysbench_InstantBuild() {
    SystemInfo_GetOSRelease
    SystemInfo_GetCPUInfo
    if [ "${Var_OSRelease}" = "centos" ] || [ "${Var_OSRelease}" = "rhel" ]; then
        echo -e "${Msg_Info}Release Detected: ${Var_OSRelease}"
        echo -e "${Msg_Info}Preparing compile enviorment ..."
        yum install -y epel-release
        yum install -y wget curl make gcc gcc-c++ make automake libtool pkgconfig libaio-devel
        echo -e "${Msg_Info}Release Detected: ${Var_OSRelease}"
        echo -e "${Msg_Info}Downloading Source code (Version 1.0.17)..."
        mkdir -p /tmp/_LBench/src/
        wget -U "${UA_LemonBench}" -O /tmp/_LBench/src/sysbench.zip https://github.com/akopytov/sysbench/archive/1.0.17.zip
        echo -e "${Msg_Info}Compiling Sysbench Module ..."
        cd /tmp/_LBench/src/
        unzip sysbench.zip && cd sysbench-1.0.17
        ./autogen.sh && ./configure --without-mysql && make -j8 && make install
        echo -e "${Msg_Info}Cleaning up ..."
        cd /tmp && rm -rf /tmp/_LBench/src/sysbench*
    elif [ "${Var_OSRelease}" = "ubuntu" ] || [ "${Var_OSRelease}" = "debian" ]; then
        echo -e "${Msg_Info}Release Detected: ${Var_OSRelease}"
        echo -e "${Msg_Info}Preparing compile enviorment ..."
        apt-get update
        apt -y install --no-install-recommends curl wget make automake libtool pkg-config libaio-dev unzip
        echo -e "${Msg_Info}Downloading Source code (Version 1.0.17)..."
        mkdir -p /tmp/_LBench/src/
        wget -U "${UA_LemonBench}" -O /tmp/_LBench/src/sysbench.zip https://github.com/akopytov/sysbench/archive/1.0.17.zip
        echo -e "${Msg_Info}Compiling Sysbench Module ..."
        cd /tmp/_LBench/src/
        unzip sysbench.zip && cd sysbench-1.0.17
        ./autogen.sh && ./configure --without-mysql && make -j8 && make install
        echo -e "${Msg_Info}Cleaning up ..."
        cd /tmp && rm -rf /tmp/_LBench/src/sysbench*
    elif [ "${Var_OSRelease}" = "fedora" ]; then
        echo -e "${Msg_Info}Release Detected: ${Var_OSRelease}"
        echo -e "${Msg_Info}Preparing compile enviorment ..."
        dnf install -y wget curl gcc gcc-c++ make automake libtool pkgconfig libaio-devel
        echo -e "${Msg_Info}Downloading Source code (Version 1.0.17)..."
        mkdir -p /tmp/_LBench/src/
        wget -U "${UA_LemonBench}" -O /tmp/_LBench/src/sysbench.zip https://github.com/akopytov/sysbench/archive/1.0.17.zip
        echo -e "${Msg_Info}Compiling Sysbench Module ..."
        cd /tmp/_LBench/src/
        unzip sysbench.zip && cd sysbench-1.0.17
        ./autogen.sh && ./configure --without-mysql && make -j8 && make install
        echo -e "${Msg_Info}Cleaning up ..."
        cd /tmp && rm -rf /tmp/_LBench/src/sysbench*
    else
        echo -e "${Msg_Error}Cannot compile on current enviorment！ (Only Support CentOS/Debian/Ubuntu/Fedora) "
    fi
}

Function_CheckTracemode() {
    if [ "${Flag_TracerouteModeisSet}" = "1" ]; then
        if [ "${GlobalVar_TracerouteMode}" = "icmp" ]; then
            echo -e "${Msg_Info}Traceroute/BestTrace Tracemode is set to: ${Font_SkyBlue}ICMP Mode${Font_Suffix}"
        elif [ "${GlobalVar_TracerouteMode}" = "tcp" ]; then
            echo -e "${Msg_Info}Traceroute/BestTrace Tracemode is set to: ${Font_SkyBlue}TCP Mode${Font_Suffix}"
        fi
    else
        GlobalVar_TracerouteMode="tcp"
    fi
}

# =============== 全局启动信息 ===============
Global_Startup_Header() {
    echo -e "
 ${Font_Green}#-----------------------------------------------------------#${Font_Suffix}
 ${Font_Green}@${Font_Suffix}    ${Font_Blue}LemonBench${Font_Suffix} ${Font_Yellow}Server Evaluation & Benchmark Ultility${Font_Suffix}      ${Font_Green}@${Font_Suffix}
 ${Font_Green}#-----------------------------------------------------------#${Font_Suffix}
 ${Font_Green}@${Font_Suffix} ${Font_Purple}Written by${Font_Suffix} ${Font_SkyBlue}iLemonrain${Font_Suffix} ${Font_Blue}<ilemonrain@ilemonrain.com>${Font_Suffix}         ${Font_Green}@${Font_Suffix}
 ${Font_Green}@${Font_Suffix} ${Font_Purple}My Blog:${Font_Suffix} ${Font_SkyBlue}https://ilemonrain.com${Font_Suffix}                           ${Font_Green}@${Font_Suffix}
 ${Font_Green}@${Font_Suffix} ${Font_Purple}Telegram:${Font_Suffix} ${Font_SkyBlue}https://t.me/ilemonrain${Font_Suffix}                         ${Font_Green}@${Font_Suffix}
 ${Font_Green}@${Font_Suffix} ${Font_Purple}Telegram (For +86 User):${Font_Suffix} ${Font_SkyBlue}https://t.me/ilemonrain_chatbot${Font_Suffix}  ${Font_Green}@${Font_Suffix}
 ${Font_Green}@${Font_Suffix} ${Font_Purple}Telegram Channel:${Font_Suffix} ${Font_SkyBlue}https://t.me/ilemonrain_channel${Font_Suffix}         ${Font_Green}@${Font_Suffix}
 ${Font_Green}#-----------------------------------------------------------#${Font_Suffix}

 Version: ${BuildTime}

 Reporting Bugs Via:
 https://t.me/ilemonrain 或 https://t.me/ilemonrain_chatbot
 (简体中文/繁體中文/English only)
 
 Thanks for using！

 Usage (two way):
 (1) wget -O- https://ilemonrain.com/download/shell/LemonBench.sh | bash
 (2) curl -fsL https://ilemonrain.com/download/shell/LemonBench.sh | bash

"
}

# =============== 入口 - 快速测试 (fast) ===============
Entrance_FastBench() {
    Global_TestMode="fast"
    Global_TestModeTips="Fast Mode"
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
    Global_TestModeTips="Full Mode"
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

# =============== 入口 - 仅流媒体解锁测试 (mlt) ===============
Entrance_MediaUnlockTest() {
    Global_Startup_Header
    Global_TestMode="mediaunlocktest"
    Global_TestModeTips="Media Unlock Test Only"
    Check_JSONQuery
    Function_BenchStart
    Function_MediaUnlockTest
    Function_BenchFinish
    Function_GenerateResult
    Global_Exit_Action
}

# =============== 入口 - 仅Speedtest测试-快速模式 (spfast) ===============
Entrance_Speedtest_Fast() {
    Global_Startup_Header
    Global_TestMode="speedtest-fast"
    Global_TestModeTips="Speedtest Only (Fast Mode)"
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
    Global_TestModeTips="Speedtest Only (Full Mode)"
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
    Global_TestModeTips="Disk Performance Test Only (Fast Mode)"
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
    Global_TestModeTips="Disk Performance Test Only (Full Mode)"
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
    Global_TestModeTips="Traceroute Test Only (Fast Mode)"
    Function_CheckTracemode
    Check_JSONQuery
    Check_BestTrace
    echo -e "${Msg_Info}Collecting Network Info ..."
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
    Global_TestModeTips="Traceroute Test Only (Full Mode)"
    Function_CheckTracemode
    Check_JSONQuery
    Check_BestTrace
    echo -e "${Msg_Info}Collecting Network Info ..."
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
    Function_SpooferWarning
    Global_TestMode="spoofer"
    Global_TestModeTips="Spoof Test Only"
    Check_Spoofer
    Function_BenchStart
    Function_SpooferTest
    Function_BenchFinish
    Function_GenerateResult
    Global_Exit_Action
}


Entrance_SysBench_CPU_Fast() {
    Global_Startup_Header
    Global_TestMode="sysbench-cpu-fast"
    Global_TestModeTips="CPU Performance Test Only (Fast Mode)"
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
    Global_TestModeTips="CPU Performance Test Only (Standard Mode)"
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
    Global_TestModeTips="Memory Performance Test Only (Fast Mode)"
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
    Global_TestModeTips="Memory Performance Test Only (Standard Mode)"
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
    echo -e " "
    echo -e " ${Font_SkyBlue}LemonBench${Font_Suffix} ${Font_Yellow}Server Performace Test Utility${Font_Suffix}"
    echo -e " "
    echo -e " ${Font_Yellow}Written by:${Font_Suffix}\t\t ${Font_SkyBlue}iLemonrain <ilemonrain@ilemonrain.com>${Font_Suffix}"
    echo -e " ${Font_Yellow}Project Homepage:${Font_Suffix}\t ${Font_SkyBlue}https://blog.ilemonrain.com/linux/LemonBench.html${Font_Suffix}"
    echo -e " ${Font_Yellow}Code Version:${Font_Suffix}\t\t ${Font_SkyBlue}${BuildTime}${Font_Suffix}"
    echo -e " "
    echo -e " Usage:"
    echo -e " ${Font_SkyBlue}>> One-Key Benchmark${Font_Suffix}"
    echo -e " ${Font_Yellow}--mode TestMode${Font_Suffix}\t${Font_SkyBlue}Test Mode (fast/full, aka FastMode/FullMode)${Font_Suffix}"
    echo -e " "
    echo -e " ${Font_SkyBlue}>> Single Test${Font_Suffix}"
    echo -e " ${Font_Yellow}--dtfast${Font_Suffix}\t\t${Font_SkyBlue}Disk Test (Fast Test Mode)${Font_Suffix}"
    echo -e " ${Font_Yellow}--dtfull${Font_Suffix}\t\t${Font_SkyBlue}Disk Test (Full Test Mode)${Font_Suffix}"
    echo -e " ${Font_Yellow}--spfast${Font_Suffix}\t\t${Font_SkyBlue}Speedtest Test (Fast Test Mode)${Font_Suffix}"
    echo -e " ${Font_Yellow}--spfull${Font_Suffix}\t\t${Font_SkyBlue}Speedtest Test (Full Test Mode)${Font_Suffix}"
    echo -e " ${Font_Yellow}--trfast${Font_Suffix}\t\t${Font_SkyBlue}Traceroute Test (Fast Test Mode)${Font_Suffix}"
    echo -e " ${Font_Yellow}--trfull${Font_Suffix}\t\t${Font_SkyBlue}Traceroute Test (Full Test Mode)${Font_Suffix}"
    echo -e " ${Font_Yellow}--sbcfast${Font_Suffix}\t\t${Font_SkyBlue}CPU Benchmark Test (Fast Test Mode)${Font_Suffix}"
    echo -e " ${Font_Yellow}--sbcfull${Font_Suffix}\t\t${Font_SkyBlue}CPU Benchmark Test (Full Test Mode)${Font_Suffix}"
    echo -e " ${Font_Yellow}--sbmfast${Font_Suffix}\t\t${Font_SkyBlue}Memory Benchmark Test (Fast Test Mode)${Font_Suffix}"
    echo -e " ${Font_Yellow}--sbmfull${Font_Suffix}\t\t${Font_SkyBlue}Memory Benchmark Test (Full Test Mode)${Font_Suffix}"    
    echo -e " ${Font_Yellow}--spoof${Font_Suffix}\t\t${Font_SkyBlue}Caida Spoofer Test ${Font_Yellow}(Use it at your own risk)${Font_Suffix}${Font_Suffix}"
}

# =============== 命令行参数 ===============
# 检测传入参数
SingleTestCount="0"
while [[ $# -ge 1 ]]; do
    case $1 in
    mode | -mode | --mode | testmode | -testmode | --testmode)
        shift
        if [ "${GlobalVar_TestMode}" != "" ]; then
            echo -e "\n${Msg_Error}只允许同时启用一种预置测试! 请检查输入参数后重试!"
            Entrance_HelpDocument
            exit 1
        else
            GlobalVar_TestMode="$1"
            shift
        fi
        ;;
    # 快速测试
    fast | -fast | --fast)
        shift
        if [ "${GlobalVar_TestMode}" != "" ]; then
            echo -e "\n${Msg_Error}只允许同时启用一种预置测试! 请检查输入参数后重试!"
            Entrance_HelpDocument
            exit 1
        else
            GlobalVar_TestMode="fast"
        fi
        ;;
    # 完整测试
    full | -full | --full)
        shift
        if [ "${GlobalVar_TestMode}" != "" ]; then
            echo -e "\n${Msg_Error}只允许同时启用一种预置测试! 请检查输入参数后重试!"
            Entrance_HelpDocument
            exit 1
        else
            GlobalVar_TestMode="full"
        fi
        ;;
    # 流媒体解锁测试
    mlt | -mlt | --mlt)
        shift
        GlobalVar_TestMode="mediaunlocktest"
        ;;
    # 磁盘测试
    dtfast | -dtfast | --dtfast)
        shift
        GlobalVar_TestMode="disktest-fast"
        ;;
    dtfull | -dtfull | --dtfull)
        shift
        GlobalVar_TestMode="disktest-full"
        ;;
    # Speedtest测试
    spfast | -spfast | --spfast)
        shift
        GlobalVar_TestMode="speedtest-fast"
        ;;
    spfull | -spfull | --spfull)
        shift
        GlobalVar_TestMode="speedtest-full"
        ;;
    # 路由追踪测试        
    btfast | -btfast | --btfast | trfast | -trfast | --trfast)
        shift
        GlobalVar_TestMode="besttrace-fast"
        ;;
    btfull | -btfull | --btfull | trfull | -trull | --trfull)
        shift
        GlobalVar_TestMode="besttrace-full"
        ;;
    # Spoof测试
    spf | -spf | --spf | spoof | -spoof | --spoof | spoofer | -spoofer | --spoofer)
        shift
        GlobalVar_TestMode="spoof"
        ;;
    # CPU测试
    sbcfast | -sbcfast | --sbcfast)
        shift
        GlobalVar_TestMode="sysbench-cpu-fast"
        ;;
    sbcfull | -sbcfull | --sbcfull)
        shift
        GlobalVar_TestMode="sysbench-cpu-full"
        ;;
    # 内存测试
    sbmfast | -sbmfast | --sbmfast)
        shift
        GlobalVar_TestMode="sysbench-memory-fast"
        ;;
    sbmfull | -sbmfull | --sbmfull)
        shift
        GlobalVar_TestMode="sysbench-memory-full"
        ;;
    # 路由追踪测试模式
    tracemode | -tracemode | --tracemode )
        shift
        if [ "$1" = "icmp" ]; then
            Flag_TracerouteModeisSet="1"
            GlobalVar_TracerouteMode="icmp"
            shift
        elif [ "$1" = "tcp" ]; then
            Flag_TracerouteModeisSet="1"
            GlobalVar_TracerouteMode="tcp"
            shift
        else
            Flag_TracerouteModeisSet="0"
            GlobalVar_TracerouteMode="tcp"
            shift
        fi
        ;;
    # 帮助文档
    h | -h | --h | help | -help | --help)
        Entrance_HelpDocument
        exit 1
        ;;
    # 无效参数处理
    *)
        [[ "$1" != 'error' ]] && echo -ne "\n${Msg_Error}Invalid Parameters: \"$1\"\n"
        Entrance_HelpDocument
        exit 1
        ;;
    esac
done
# 全局入口
echo " "
if [ "${#SingleTestList[@]}" -eq "0" ] && [ "${GlobalVar_TestMode}" = "" ]; then
    Entrance_HelpDocument
    exit 1
elif [ "${GlobalVar_TestMode}" = "fast" ]; then
    Global_Startup_Header
    Entrance_FastBench
elif [ "${GlobalVar_TestMode}" = "full" ]; then
    Global_Startup_Header
    Entrance_FullBench
elif [ "${GlobalVar_TestMode}" = "mediaunlocktest" ]; then
    Global_Startup_Header
    Entrance_MediaUnlockTest
elif [ "${GlobalVar_TestMode}" = "disktest-fast" ]; then
    Global_Startup_Header
    Entrance_DiskTest_Fast
elif [ "${GlobalVar_TestMode}" = "disktest-full" ]; then
    Global_Startup_Header
    Entrance_DiskTest_Full
elif [ "${GlobalVar_TestMode}" = "speedtest-fast" ]; then
    Global_Startup_Header
    Entrance_Speedtest_Fast
elif [ "${GlobalVar_TestMode}" = "speedtest-full" ]; then
    Global_Startup_Header
    Entrance_Speedtest_Full
elif [ "${GlobalVar_TestMode}" = "besttrace-fast" ]; then
    Global_Startup_Header
    Entrance_BestTrace_Fast
elif [ "${GlobalVar_TestMode}" = "besttrace-full" ]; then
    Global_Startup_Header
    Entrance_BestTrace_Full
elif [ "${GlobalVar_TestMode}" = "spoof" ]; then
    Global_Startup_Header
    Entrance_Spoofer
elif [ "${GlobalVar_TestMode}" = "sysbench-cpu-fast" ]; then
    Global_Startup_Header
    Entrance_SysBench_CPU_Fast
elif [ "${GlobalVar_TestMode}" = "sysbench-cpu-full" ]; then
    Global_Startup_Header
    Entrance_SysBench_CPU_Full
elif [ "${GlobalVar_TestMode}" = "sysbench-memory-fast" ]; then
    Global_Startup_Header
    Entrance_SysBench_Memory_Fast
elif [ "${GlobalVar_TestMode}" = "sysbench-memory-full" ]; then
    Global_Startup_Header
    Entrance_SysBench_Memory_Full
else
    Entrance_HelpDocument
    exit 1
fi