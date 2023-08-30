#!/usr/bin/env bash
#
# LemonBench-Next - 下一代Linux性能基准测试工具
# Author: iLemonrain <ilemonrain@ilemonrain.com>
#
# ===== 全局变量 =====
# -> LemonBench工作基础路径
GlobalVar_BaseDir="$HOME/.LemonBench"
# -> LemonBench默认测试预置 (fast|full)
GlobalVar_BenchPreset="none"
# -> 是否在测试结束后自动上传测试报告 (0|1)
GlobalVar_UploadReport="1"
# 设置LemonBench的BenchUA, 此参数由作者维护, 并在某些场景下会作为验证字符串, 您不应该随意修改这里的值
GlobalVar_UA_LemonBench="LemonBench v3/$GlobalVar_LemonBench_Version"
GlobalVar_LemonBench_Version="2023.06.22-Stable"
# 设置LemonBench的浏览器UA, 此参数由作者维护, 并在某些场景下会作为验证字符串, 您不应该随意修改这里的值
GlobalVar_UA_WebBrowser="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36"
# 设置LemonBench的手机UA, 此参数由作者维护, 并在某些场景下会作为验证字符串, 您不应该随意修改这里的值
GlobalVar_UA_Dalvik="Dalvik/2.1.0 (Linux; U; Android 9; ALP-AL00 Build/HUAWEIALP-AL00)"
# 设置LemonBench的UnityPlayer UA, 此参数由作者维护, 并在某些场景下会作为验证字符串, 您不应该随意修改这里的值
GlobalVar_UA_UnityPlayer="UnityPlayer/2019.4.1f1 (UnityWebRequest/1.0, libcurl/7.52.0-DEV)"
# 设置curl命令的超时时间 (默认值: 30)
GlobalVar_CurlMaxTime="10"
# -> 路由追踪测试 - 使用工具 (nexttrace|worsttrace)
GlobalVar_TracerouteBinary="nexttrace"
# -> 路由追踪测试 - 使用协议 (icmp|tcp)
GlobalVar_TracerouteMode="icmp"
# -> 路由追踪测试 - 最大跳数 (10~99)
GlobalVar_TracerouteMaxHop="30"
# -> 字体颜色定义 (彩色输出)
Font_Black="\033[30m"
Font_Red="\033[31m"
Font_Green="\033[32m"
Font_Yellow="\033[33m"
Font_Blue="\033[34m"
Font_Purple="\033[35m"
Font_SkyBlue="\033[36m"
Font_White="\033[37m"
Font_Suffix="\033[0m"
# -> 消息提示定义 (消息前缀)
Msg_Info="${Font_Blue}[INFO]${Font_Suffix}"
Msg_Warning="${Font_Yellow}[WARN]${Font_Suffix}"
Msg_Debug="${Font_Yellow}[DEBUG]${Font_Suffix}"
Msg_Error="${Font_Red}[ERROR]${Font_Suffix}"
Msg_Success="${Font_Green}[SUCCESS]${Font_Suffix}"
Msg_Fail="${Font_Red}[FAIL]${Font_Suffix}"
Msg_Time="$(date +"[%Y/%m/%d %T]")"
#
# -> 全局函数 - JSON解析
function BenchExec_PharseJSON() {
    echo -n "$1" | jq -r "$2" 2>/dev/null
}
#
# ===========================================================================
# -> 系统信息模块 (Entrypoint) -> 执行
function BenchFunc_Systeminfo_GetSysteminfo() {
    BenchAPI_Systeminfo_GetCPUinfo
    BenchAPI_Systeminfo_GetVMMinfo
    BenchAPI_Systeminfo_GetMemoryinfo
    BenchAPI_Systeminfo_GetDiskinfo
    BenchAPI_Systeminfo_GetOSReleaseinfo
    BenchAPI_Systeminfo_GetLinuxKernelinfo
}
# -> 系统信息模块 (DisplayOutput) -> 输出系统信息
function BenchFunc_Systeminfo_ShowSysteminfo() {
    echo -e "\n${Font_Yellow} -> System Information${Font_Suffix}\n"
    echo -e " ${Font_Yellow}CPU Model Name:${Font_Suffix}\t\t${Font_SkyBlue}${Result_Systeminfo_CPUModelName}"
    echo -e " ${Font_Yellow}CPU Cache Size:${Font_Suffix}\t\t${Font_SkyBlue}L1: ${Result_Systeminfo_CPUCacheSizeL1} / L2: ${Result_Systeminfo_CPUCacheSizeL2} / L3: ${Result_Systeminfo_CPUCacheSizeL3}"
    if [ "${Result_Systeminfo_isPhysical}" = "1" ]; then
        echo -e " ${Font_Yellow}CPU Specifications:${Font_Suffix}\t\t${Font_SkyBlue}${Result_Systeminfo_CPUSockets} Socket(s), ${Result_Systeminfo_CPUCores} Core(s), ${Result_Systeminfo_CPUThreads} Thread(s)"
        if [ "${Result_Systeminfo_VirtReady}" = "1" ]; then
            if [ "${Result_Systeminfo_IOMMU}" = "1" ]; then
                echo -e " ${Font_Yellow}Virtualization Ready:${Font_Suffix}\t\t${Font_SkyBlue}Yes (Based on ${Result_Systeminfo_CPUVMX}, IOMMU Enabled)${Font_Suffix}"
            else
                echo -e " ${Font_Yellow}Virtualization Ready:${Font_Suffix}\t\t${Font_SkyBlue}Yes (Based on ${Result_Systeminfo_CPUVMX})${Font_Suffix}"
            fi
        else
            echo -e " ${Font_Yellow}Virtualization Ready:${Font_Suffix}\t\t${Font_SkyBlue}No${Font_Suffix}"
        fi
    elif [ "$Result_Systeminfo_isPhysical" = "0" ]; then
        echo -e " ${Font_Yellow}CPU Specifications:${Font_Suffix}\t\t${Font_SkyBlue}${Result_Systeminfo_CPUThreads} vCPU(s)${Font_Suffix}"
        if [ "${Result_Systeminfo_VirtReady}" = "1" ]; then
            if [ "${Result_Systeminfo_IOMMU}" = "1" ]; then
                echo -e " ${Font_Yellow}Virtualization Ready:${Font_Suffix}\t\t${Font_SkyBlue}Yes (Based on ${Result_Systeminfo_CPUVMX}, Nested Virtualization Enabled, IOMMU Enabled${Font_Suffix})"
            else
                echo -e " ${Font_Yellow}Virtualization Ready:${Font_Suffix}\t\t${Font_SkyBlue}Yes (Based on ${Result_Systeminfo_CPUVMX}, Nested Virtualization Enabled${Font_Suffix})"
            fi
        else
            echo -e " ${Font_Yellow}Virtualization Ready:${Font_Suffix}\t\t${Font_SkyBlue}No${Font_Suffix}"
        fi
    fi
    echo -e " ${Font_Yellow}Virtualization Type:${Font_Suffix}\t\t${Font_SkyBlue}${Result_Systeminfo_VMMType}${Font_Suffix}"
    echo -e " ${Font_Yellow}Memory Usage:${Font_Suffix}\t\t\t${Font_SkyBlue}${Result_Systeminfo_Memoryinfo}${Font_Suffix}"
    echo -e " ${Font_Yellow}Swap Usage:${Font_Suffix}\t\t\t${Font_SkyBlue}${Result_Systeminfo_Swapinfo}${Font_Suffix}"
    echo -e " ${Font_Yellow}Disk Usage:${Font_Suffix}\t\t\t${Font_SkyBlue}${Result_Systeminfo_Diskinfo}${Font_Suffix}"
    echo -e " ${Font_Yellow}Boot Disk:${Font_Suffix}\t\t\t${Font_SkyBlue}${Result_Systeminfo_DiskRootPath}${Font_Suffix}"
    echo -e " ${Font_Yellow}OS Release:${Font_Suffix}\t\t\t${Font_SkyBlue}${Result_Systeminfo_OSReleaseNameFull}${Font_Suffix}"
    echo -e " ${Font_Yellow}Kernel Version:${Font_Suffix}\t\t${Font_SkyBlue}${Result_Systeminfo_LinuxKernelVersion}${Font_Suffix}"
    return 0
}
#
# -> 系统信息模块 (Collector) -> 获取CPU信息
function BenchAPI_Systeminfo_GetCPUinfo() {
    # CPU 基础信息检测
    local r_modelname && r_modelname="$(lscpu -B 2>/dev/null | grep -oP -m1 "(?<=Model name:).*(?=)" | sed -e 's/^[ ]*//g')"
    local r_cachesize_l1d_b && r_cachesize_l1d_b="$(lscpu -B 2>/dev/null | grep -oP "(?<=L1d cache:).*(?=)" | sed -e 's/^[ ]*//g')"
    local r_cachesize_l1i_b && r_cachesize_l1i_b="$(lscpu -B 2>/dev/null | grep -oP "(?<=L1i cache:).*(?=)" | sed -e 's/^[ ]*//g')"
    local r_cachesize_l1_b && r_cachesize_l1_b="$(echo "$r_cachesize_l1d_b" "$r_cachesize_l1i_b" | awk '{printf "%d\n",$1+$2}')"
    local r_cachesize_l1_k && r_cachesize_l1_k="$(echo "$r_cachesize_l1_b" | awk '{printf "%.2f\n",$1/1024}')"
    local t_cachesize_l1_k && t_cachesize_l1_k="$(echo "$r_cachesize_l1_b" | awk '{printf "%d\n",$1/1024}')"
    if [ "$t_cachesize_l1_k" -ge "1024" ]; then
        local r_cachesize_l1_m && r_cachesize_l1_m="$(echo "$r_cachesize_l1_k" | awk '{printf "%.2f\n",$1/1024}')"
        local r_cachesize_l1="$r_cachesize_l1_m MB"
    else
        local r_cachesize_l1="$r_cachesize_l1_k KB"
    fi
    local r_cachesize_l2_b && r_cachesize_l2_b="$(lscpu -B 2>/dev/null | grep -oP "(?<=L2 cache:).*(?=)" | sed -e 's/^[ ]*//g')"
    local r_cachesize_l2_k && r_cachesize_l2_k="$(echo "$r_cachesize_l2_b" | awk '{printf "%.2f\n",$1/1024}')"
    local t_cachesize_l2_k && t_cachesize_l2_k="$(echo "$r_cachesize_l2_b" | awk '{printf "%d\n",$1/1024}')"
    if [ "$t_cachesize_l2_k" -ge "1024" ]; then
        local r_cachesize_l2_m && r_cachesize_l2_m="$(echo "$r_cachesize_l2_k" | awk '{printf "%.2f\n",$1/1024}')"
        local r_cachesize_l2="$r_cachesize_l2_m MB"
    else
        local r_cachesize_l2="$r_cachesize_l2_k KB"
    fi
    local r_cachesize_l3_b && r_cachesize_l3_b="$(lscpu -B 2>/dev/null | grep -oP "(?<=L3 cache:).*(?=)" | sed -e 's/^[ ]*//g')"
    local r_cachesize_l3_k && r_cachesize_l3_k="$(echo "$r_cachesize_l3_b" | awk '{printf "%.2f\n",$1/1024}')"
    local t_cachesize_l3_k && t_cachesize_l3_k="$(echo "$r_cachesize_l3_b" | awk '{printf "%d\n",$1/1024}')"
    if [ "$t_cachesize_l3_k" -ge "1024" ]; then
        local r_cachesize_l3_m && r_cachesize_l3_m="$(echo "$r_cachesize_l3_k" | awk '{printf "%.2f\n",$1/1024}')"
        local r_cachesize_l3="$r_cachesize_l3_m MB"
    else
        local r_cachesize_l3="$r_cachesize_l3_k KB"
    fi
    local r_sockets && r_sockets="$(lscpu -B 2>/dev/null | grep -oP "(?<=Socket\(s\):).*(?=)" | sed -e 's/^[ ]*//g')"
    if [ "$r_sockets" -ge "2" ]; then
        local r_cores && r_cores="$(lscpu -B 2>/dev/null | grep -oP "(?<=Core\(s\) per socket:).*(?=)" | sed -e 's/^[ ]*//g')"
        r_cores="$(echo "$r_sockets" "$r_cores" | awk '{printf "%d\n",$1*$2}')"
        local r_threadpercore && r_threadpercore="$(lscpu -B 2>/dev/null | grep -oP "(?<=Thread\(s\) per core:).*(?=)" | sed -e 's/^[ ]*//g')"
        local r_threads && r_threads="$(echo "$r_cores" "$r_threadpercore" | awk '{printf "%d\n",$1*$2}')"
        r_threads="$(echo "$r_threadpercore" "$r_cores" | awk '{printf "%d\n",$1*$2}')"
    else
        local r_cores && r_cores="$(lscpu -B 2>/dev/null | grep -oP "(?<=Core\(s\) per socket:).*(?=)" | sed -e 's/^[ ]*//g')"
        local r_threadpercore && r_threadpercore="$(lscpu -B 2>/dev/null | grep -oP "(?<=Thread\(s\) per core:).*(?=)" | sed -e 's/^[ ]*//g')"
        local r_threads && r_threads="$(echo "$r_cores" "$r_threadpercore" | awk '{printf "%d\n",$1*$2}')"
    fi
    # CPU AES能力检测
    # local t_aes && t_aes="$(awk -F ': ' '/flags/{print $2}' /proc/cpuinfo 2>/dev/null | grep -oE "\baes\b" | sort -u)"
    # [[ "${t_aes}" = "aes" ]] && Result_Systeminfo_CPUAES="1" || Result_Systeminfo_CPUAES="0"
    # CPU AVX能力检测
    # local t_avx && t_avx="$(awk -F ': ' '/flags/{print $2}' /proc/cpuinfo 2>/dev/null | grep -oE "\bavx\b" | sort -u)"
    # [[ "${t_avx}" = "avx" ]] && Result_Systeminfo_CPUAVX="1" || Result_Systeminfo_CPUAVX="0"
    # CPU AVX512能力检测
    # local t_avx512 && t_avx512="$(awk -F ': ' '/flags/{print $2}' /proc/cpuinfo 2>/dev/null | grep -oE "\bavx512\b" | sort -u)"
    # [[ "${t_avx512}" = "avx" ]] && Result_Systeminfo_CPUAVX512="1" || Result_Systeminfo_CPUAVX512="0"
    # CPU 虚拟化能力检测
    local t_vmx_vtx && t_vmx_vtx="$(awk -F ': ' '/flags/{print $2}' /proc/cpuinfo 2>/dev/null | grep -oE "\bvmx\b" | sort -u)"
    local t_vmx_svm && t_vmx_svm="$(awk -F ': ' '/flags/{print $2}' /proc/cpuinfo 2>/dev/null | grep -oE "\bsvm\b" | sort -u)"
    if [ "$t_vmx_vtx" = "vmx" ]; then
        Result_Systeminfo_VirtReady="1"
        Result_Systeminfo_CPUVMX="Intel VT-x"
    elif [ "$t_vmx_svm" = "svm" ]; then
        Result_Systeminfo_VirtReady="1"
        Result_Systeminfo_CPUVMX="AMD-V"
    else
        if [ -c "/dev/kvm" ]; then
            Result_Systeminfo_VirtReady="1"
            Result_Systeminfo_CPUVMX="unknown"
        else
            Result_Systeminfo_VirtReady="0"
            Result_Systeminfo_CPUVMX="unknown"
        fi
    fi
    # 输出结果
    Result_Systeminfo_CPUModelName="$r_modelname"
    Result_Systeminfo_CPUSockets="$r_sockets"
    Result_Systeminfo_CPUCores="$r_cores"
    Result_Systeminfo_CPUThreads="$r_threads"
    Result_Systeminfo_CPUCacheSizeL1="$r_cachesize_l1"
    Result_Systeminfo_CPUCacheSizeL2="$r_cachesize_l2"
    Result_Systeminfo_CPUCacheSizeL3="$r_cachesize_l3"
}
#
# -> 系统信息模块 (Collector) -> 获取内存及Swap信息
function BenchAPI_Systeminfo_GetMemoryinfo() {
    # 内存信息
    local r_memtotal_kib && r_memtotal_kib="$(awk '/MemTotal/{print $2}' /proc/meminfo | head -n1)"
    local r_memtotal_mib && r_memtotal_mib="$(echo "$r_memtotal_kib" | awk '{printf "%.2f\n",$1/1024}')"
    local r_memtotal_gib && r_memtotal_gib="$(echo "$r_memtotal_kib" | awk '{printf "%.2f\n",$1/1048576}')"
    local r_meminfo_memfree_kib && r_meminfo_memfree_kib="$(awk '/MemFree/{print $2}' /proc/meminfo | head -n1)"
    local r_meminfo_buffers_kib && r_meminfo_buffers_kib="$(awk '/Buffers/{print $2}' /proc/meminfo | head -n1)"
    local r_meminfo_cached_kib && r_meminfo_cached_kib="$(awk '/Cached/{print $2}' /proc/meminfo | head -n1)"
    local r_memfree_kib && r_memfree_kib="$(echo "$r_meminfo_memfree_kib" "$r_meminfo_buffers_kib" "$r_meminfo_cached_kib" | awk '{printf $1+$2+$3}')"
    local r_memfree_mib && r_memfree_mib="$(echo "$r_memfree_kib" | awk '{printf "%.2f\n",$1/1024}')"
    local r_memfree_gib && r_memfree_gib="$(echo "$r_memfree_kib" | awk '{printf "%.2f\n",$1/1048576}')"
    local r_memused_kib && r_memused_kib="$(echo "$r_memtotal_kib" "$r_memfree_kib" | awk '{printf $1-$2}')"
    local r_memused_mib && r_memused_mib="$(echo "$r_memused_kib" | awk '{printf "%.2f\n",$1/1024}')"
    local r_memused_gib && r_memused_gib="$(echo "$r_memused_kib" | awk '{printf "%.2f\n",$1/1048576}')"
    # 交换信息
    local r_swaptotal_kib && r_swaptotal_kib="$(awk '/SwapTotal/{print $2}' /proc/meminfo | head -n1)"
    local r_swaptotal_mib && r_swaptotal_mib="$(echo "$r_swaptotal_kib" | awk '{printf "%.2f\n",$1/1024}')"
    local r_swaptotal_gib && r_swaptotal_gib="$(echo "$r_swaptotal_kib" | awk '{printf "%.2f\n",$1/1048576}')"
    local r_swapfree_kib && r_swapfree_kib="$(awk '/SwapFree/{print $2}' /proc/meminfo | head -n1)"
    local r_swapfree_mib && r_swapfree_mib="$(echo "$r_swapfree_kib" | awk '{printf "%.2f\n",$1/1024}')"
    local r_swapfree_gib && r_swapfree_gib="$(echo "$r_swapfree_kib" | awk '{printf "%.2f\n",$1/1048576}')"
    local r_swapused_kib && r_swapused_kib="$(echo "$r_swaptotal_kib" "${r_swapfree_kib}" | awk '{printf $1-$2}')"
    local r_swapused_mib && r_swapused_mib="$(echo "$r_swapused_kib" | awk '{printf "%.2f\n",$1/1024}')"
    local r_swapused_gib && r_swapused_gib="$(echo "$r_swapused_kib" | awk '{printf "%.2f\n",$1/1048576}')"
    # 数据加工
    if [ "$r_memused_kib" -lt "1024" ] && [ "$r_memtotal_kib" -lt "1048576" ]; then
        Result_Systeminfo_Memoryinfo="$r_memused_kib KiB / $r_memtotal_mib MiB"
    elif [ "$r_memused_kib" -lt "1048576" ] && [ "$r_memtotal_kib" -lt "1048576" ]; then
        Result_Systeminfo_Memoryinfo="$r_memused_mib MiB / $r_memtotal_mib MiB"
    elif [ "$r_memused_kib" -lt "1048576" ] && [ "$r_memtotal_kib" -lt "1073741824" ]; then
        Result_Systeminfo_Memoryinfo="$r_memused_mib MiB / $r_memtotal_gib GiB"
    else
        Result_Systeminfo_Memoryinfo="$r_memused_gib GiB / $r_memtotal_gib GiB"
    fi
    if [ "$r_swaptotal_kib" -eq "0" ]; then
        Result_Systeminfo_Swapinfo="[ no swap partition or swap file detected ]"
    elif [ "$r_swapused_kib" -lt "1024" ] && [ "$r_swaptotal_kib" -lt "1048576" ]; then
        Result_Systeminfo_Swapinfo="$r_swapused_kib KiB / $r_swaptotal_mib MiB"
    elif [ "$r_swapused_kib" -lt "1024" ] && [ "$r_swaptotal_kib" -lt "1073741824" ]; then
        Result_Systeminfo_Swapinfo="$r_swapused_kib KiB / $r_swaptotal_gib GiB"
    elif [ "$r_swapused_kib" -lt "1048576" ] && [ "$r_swaptotal_kib" -lt "1048576" ]; then
        Result_Systeminfo_Swapinfo="$r_swapused_mib MiB / $r_swaptotal_mib MiB"
    elif [ "$r_swapused_kib" -lt "1048576" ] && [ "$r_swaptotal_kib" -lt "1073741824" ]; then
        Result_Systeminfo_Swapinfo="$r_swapused_mib MiB / $r_swaptotal_gib GiB"
    else
        Result_Systeminfo_Swapinfo="$r_swapused_gib GiB / $r_swaptotal_gib GiB"
    fi
}
#
# -> 系统信息模块 (Collector) -> 获取磁盘信息
function BenchAPI_Systeminfo_GetDiskinfo() {
    # 磁盘信息
    local r_diskpath_root && r_diskpath_root="$(df -x tmpfs / | awk "NR>1" | sed ":a;N;s/\\n//g;ta" | awk '{print $1}')"
    local r_disktotal_kib && r_disktotal_kib="$(df -x tmpfs / | grep -oE "[0-9]{4,}" | awk 'NR==1 {print $1}')"
    local r_disktotal_mib && r_disktotal_mib="$(echo "$r_disktotal_kib" | awk '{printf "%.2f\n",$1/1024}')"
    local r_disktotal_gib && r_disktotal_gib="$(echo "$r_disktotal_kib" | awk '{printf "%.2f\n",$1/1048576}')"
    local r_disktotal_tib && r_disktotal_tib="$(echo "$r_disktotal_kib" | awk '{printf "%.2f\n",$1/1073741824}')"
    local r_diskused_kib && r_diskused_kib="$(df -x tmpfs / | grep -oE "[0-9]{4,}" | awk 'NR==2 {print $1}')"
    local r_diskused_mib && r_diskused_mib="$(echo "$r_diskused_kib" | awk '{printf "%.2f\n",$1/1024}')"
    local r_diskused_gib && r_diskused_gib="$(echo "$r_diskused_kib" | awk '{printf "%.2f\n",$1/1048576}')"
    local r_diskused_tib && r_diskused_tib="$(echo "$r_diskused_kib" | awk '{printf "%.2f\n",$1/1073741824}')"
    local r_diskfree_kib && r_diskfree_kib="$(df -x tmpfs / | grep -oE "[0-9]{4,}" | awk 'NR==3 {print $1}')"
    local r_diskfree_mib && r_diskfree_mib="$(echo "$r_diskfree_kib" | awk '{printf "%.2f\n",$1/1024}')"
    local r_diskfree_gib && r_diskfree_gib="$(echo "$r_diskfree_kib" | awk '{printf "%.2f\n",$1/1048576}')"
    local r_diskfree_tib && r_diskfree_tib="$(echo "$r_diskfree_kib" | awk '{printf "%.2f\n",$1/1073741824}')"
    # 数据加工
    Result_Systeminfo_DiskRootPath="$r_diskpath_root"
    if [ "$r_diskused_kib" -lt "1048576" ]; then
        Result_Systeminfo_Diskinfo="$r_diskused_mib MiB / $r_disktotal_mib MiB"
    elif [ "$r_diskused_kib" -lt "1048576" ] && [ "$r_disktotal_kib" -lt "1073741824" ]; then
        Result_Systeminfo_Diskinfo="$r_diskused_mib MiB / $r_disktotal_gib GiB"
    elif [ "$r_diskused_kib" -lt "1073741824" ] && [ "$r_disktotal_kib" -lt "1073741824" ]; then
        Result_Systeminfo_Diskinfo="$r_diskused_gib GiB / $r_disktotal_gib GiB"
    elif [ "$r_diskused_kib" -lt "1073741824" ] && [ "$r_disktotal_kib" -ge "1073741824" ]; then
        Result_Systeminfo_Diskinfo="$r_diskused_gib GiB / $r_disktotal_tib TiB"
    else
        Result_Systeminfo_Diskinfo="$r_diskused_tib TiB / $r_disktotal_tib TiB"
    fi
}
#
# -> 系统信息模块 (Collector) -> 获取虚拟化信息
function BenchAPI_Systeminfo_GetVMMinfo() {
    if [ -f "/usr/bin/systemd-detect-virt" ]; then
        local r_vmmtype && r_vmmtype="$(/usr/bin/systemd-detect-virt 2>/dev/null)"
        case "${r_vmmtype}" in
        kvm)
            Result_Systeminfo_VMMType="KVM"
            Result_Systeminfo_VMMTypeShort="kvm"
            Result_Systeminfo_isPhysical="0"
            return 0
            ;;
        xen)
            Result_Systeminfo_VMMType="Xen Hypervisor"
            Result_Systeminfo_VMMTypeShort="xen"
            Result_Systeminfo_isPhysical="0"
            return 0
            ;;
        microsoft)
            Result_Systeminfo_VMMType="Microsoft Hyper-V"
            Result_Systeminfo_VMMTypeShort="microsoft"
            Result_Systeminfo_isPhysical="0"
            return 0
            ;;
        vmware)
            Result_Systeminfo_VMMType="VMware"
            Result_Systeminfo_VMMTypeShort="vmware"
            Result_Systeminfo_isPhysical="0"
            return 0
            ;;
        oracle)
            Result_Systeminfo_VMMType="Oracle VirtualBox"
            Result_Systeminfo_VMMTypeShort="oracle"
            Result_Systeminfo_isPhysical="0"
            return 0
            ;;
        parallels)
            Result_Systeminfo_VMMType="Parallels"
            Result_Systeminfo_VMMTypeShort="parallels"
            Result_Systeminfo_isPhysical="0"
            return 0
            ;;
        qemu)
            Result_Systeminfo_VMMType="QEMU"
            Result_Systeminfo_VMMTypeShort="qemu"
            Result_Systeminfo_isPhysical="0"
            return 0
            ;;
        amazon)
            Result_Systeminfo_VMMType="Amazon Virtualization"
            Result_Systeminfo_VMMTypeShort="amazon"
            Result_Systeminfo_isPhysical="0"
            return 0
            ;;
        docker)
            Result_Systeminfo_VMMType="Docker"
            Result_Systeminfo_VMMTypeShort="docker"
            Result_Systeminfo_isPhysical="0"
            return 0
            ;;
        openvz)
            Result_Systeminfo_VMMType="OpenVZ (Virutozzo)"
            Result_Systeminfo_VMMTypeShort="openvz"
            Result_Systeminfo_isPhysical="0"
            return 0
            ;;
        lxc)
            Result_Systeminfo_VMMTypeShort="lxc"
            Result_Systeminfo_VMMType="LXC"
            Result_Systeminfo_isPhysical="0"
            return 0
            ;;
        lxc-libvirt)
            Result_Systeminfo_VMMType="LXC (Based on libvirt)"
            Result_Systeminfo_VMMTypeShort="lxc-libvirt"
            Result_Systeminfo_isPhysical="0"
            return 0
            ;;
        uml)
            Result_Systeminfo_VMMType="User-mode Linux"
            Result_Systeminfo_VMMTypeShort="uml"
            Result_Systeminfo_isPhysical="0"
            return 0
            ;;
        systemd-nspawn)
            Result_Systeminfo_VMMType="Systemd nspawn"
            Result_Systeminfo_VMMTypeShort="systemd-nspawn"
            Result_Systeminfo_isPhysical="0"
            return 0
            ;;
        bochs)
            Result_Systeminfo_VMMType="BOCHS"
            Result_Systeminfo_VMMTypeShort="bochs"
            Result_Systeminfo_isPhysical="0"
            return 0
            ;;
        rkt)
            Result_Systeminfo_VMMType="RKT"
            Result_Systeminfo_VMMTypeShort="rkt"
            Result_Systeminfo_isPhysical="0"
            return 0
            ;;
        zvm)
            Result_Systeminfo_VMMType="S390 Z/VM"
            Result_Systeminfo_VMMTypeShort="zvm"
            Result_Systeminfo_isPhysical="0"
            return 0
            ;;
        none)
            Result_Systeminfo_VMMType="Dedicated"
            Result_Systeminfo_VMMTypeShort="none"
            Result_Systeminfo_isPhysical="1"
            if test -f "/sys/class/iommu/dmar0/uevent"; then
                Result_Systeminfo_IOMMU="1"
            else
                Result_Systeminfo_IOMMU="0"
            fi
            return 0
            ;;
        *)
            echo -e "${Msg_Error} BenchAPI_Systeminfo_GetVirtinfo(): invalid result (${r_vmmtype}), please check parameter!"
            exit 1
            ;;
        esac
    elif [ -f "/.dockerenv" ]; then
        Result_Systeminfo_VMMType="Docker"
        Result_Systeminfo_VMMTypeShort="docker"
        Result_Systeminfo_isPhysical="0"
        return 0
    elif [ -c "/dev/lxss" ]; then
        Result_Systeminfo_VMMType="Windows Subsystem for Linux"
        Result_Systeminfo_VMMTypeShort="wsl"
        Result_Systeminfo_isPhysical="0"
        return 0
    else
        Result_Systeminfo_VMMType="Dedicated"
        Result_Systeminfo_VMMTypeShort="none"
        if test -f "/sys/class/iommu/dmar0/uevent"; then
            Result_Systeminfo_IOMMU="1"
        else
            Result_Systeminfo_IOMMU="0"
        fi
        return 0
    fi
}
#
# -> 系统信息模块 (Collector) -> 获取Linux发行版信息
function BenchAPI_Systeminfo_GetOSReleaseinfo() {
    local r_arch && r_arch="$(arch)"
    Result_Systeminfo_OSArch="$r_arch"
    # CentOS/Red Hat 判断
    if [ -f "/etc/centos-release" ] || [ -f "/etc/redhat-release" ]; then
        Result_Systeminfo_OSReleaseNameShort="centos"
        local r_prettyname && r_prettyname="$(grep -oP '(?<=\bPRETTY_NAME=").*(?=")' /etc/os-release)"
        local r_elrepo_version && r_elrepo_version="$(rpm -qa | grep -oP "el[0-9]+" | sort -ur | head -n1)"
        case "$r_elrepo_version" in
        9 | el9)
            Result_Systeminfo_OSReleaseVersionShort="9"
            Result_Systeminfo_OSReleaseNameFull="$r_prettyname ($r_arch)"
            return 0
            ;;
        8 | el8)
            Result_Systeminfo_OSReleaseVersionShort="8"
            Result_Systeminfo_OSReleaseNameFull="$r_prettyname ($r_arch)"
            return 0
            ;;
        7 | el7)
            Result_Systeminfo_OSReleaseVersionShort="7"
            Result_Systeminfo_OSReleaseNameFull="$r_prettyname ($r_arch)"
            return 0
            ;;
        6 | el6)
            Result_Systeminfo_OSReleaseVersionShort="6"
            Result_Systeminfo_OSReleaseNameFull="$r_prettyname ($r_arch)"
            return 0
            ;;
        *)
            echo -e "${Msg_Error} BenchAPI_Systeminfo_GetOSReleaseinfo(): invalid result (CentOS/Redhat-$r_prettyname ($r_arch)), please check parameter!"
            exit 1
            ;;
        esac
    elif [ -f "/etc/lsb-release" ]; then # Ubuntu
        Result_Systeminfo_OSReleaseNameShort="ubuntu"
        local r_prettyname && r_prettyname="$(grep -oP '(?<=\bPRETTY_NAME=").*(?=")' /etc/os-release)"
        Result_Systeminfo_OSReleaseVersion="$(grep -oP '(?<=\bVERSION=").*(?=")' /etc/os-release)"
        Result_Systeminfo_OSReleaseVersionShort="$(grep -oP '(?<=\bVERSION_ID=").*(?=")' /etc/os-release)"
        Result_Systeminfo_OSReleaseNameFull="$r_prettyname ($r_arch)"
        return 0
    elif [ -f "/etc/debian_version" ]; then # Debian
        Result_Systeminfo_OSReleaseNameShort="debian"
        local r_prettyname && r_prettyname="$(grep -oP '(?<=\bPRETTY_NAME=").*(?=")' /etc/os-release)"
        Result_Systeminfo_OSReleaseVersion="$(grep -oP '(?<=\bVERSION=").*(?=")' /etc/os-release)"
        Result_Systeminfo_OSReleaseVersionShort="$(grep -oP '(?<=\bVERSION_ID=").*(?=")' /etc/os-release)"
        Result_Systeminfo_OSReleaseNameFull="$r_prettyname ($r_arch)"
        return 0
    else
        echo -e "${Msg_Error} BenchAPI_Systeminfo_GetOSReleaseinfo(): invalid result ($r_prettyname ($r_arch)), please check parameter!"
        exit 1
    fi
}
#
# -> 系统信息模块 (Collector) -> 获取Linux内核版本信息
function BenchAPI_Systeminfo_GetLinuxKernelinfo() {
    # 获取原始数据
    Result_Systeminfo_LinuxKernelVersion="$(uname -r)"
}
#
# ===========================================================================
# -> 网络信息模块 (Entrypoint) -> 执行
function BenchFunc_Networkinfo_GetNetworkinfo() {
    BenchAPI_Networkinfo_GetNetworkinfo
}
# -> 网络信息模块 (DisplayOutput) -> 输出网络信息
function BenchFunc_Networkinfo_ShowNetworkinfo() {
    echo -e "\n ${Font_Yellow}-> Network Information${Font_Suffix}\n"
    if [ "$Result_Networkinfo_NetworkType" = "ipv4" ] || [ "$Result_Networkinfo_NetworkType" = "dualstack" ]; then
        echo -e " ${Font_Yellow}IPv4-IP Address:${Font_Suffix}\t\t${Font_SkyBlue}[$Result_Networkinfo_CountryCode4] $Result_Networkinfo_IP4${Font_Suffix}"
        echo -e " ${Font_Yellow}IPv4-AS Information:${Font_Suffix}\t\t${Font_SkyBlue}$Result_Networkinfo_NetworkOwner4${Font_Suffix}"
        echo -e " ${Font_Yellow}IPv4-GeoIP Location:${Font_Suffix}\t\t${Font_SkyBlue}$Result_Networkinfo_GeoLocation4${Font_Suffix}"
    fi
    if [ "$Result_Networkinfo_NetworkType" = "ipv6" ] || [ "$Result_Networkinfo_NetworkType" = "dualstack" ]; then
        echo -e " ${Font_Yellow}IPv6-IP Address:${Font_Suffix}\t\t${Font_SkyBlue}[$Result_Networkinfo_CountryCode6] $Result_Networkinfo_IP6${Font_Suffix}"
        echo -e " ${Font_Yellow}IPv6-AS Information:${Font_Suffix}\t\t${Font_SkyBlue}$Result_Networkinfo_NetworkOwner6${Font_Suffix}"
        echo -e " ${Font_Yellow}IPv6-GeoIP Location:${Font_Suffix}\t\t${Font_SkyBlue}$Result_Networkinfo_GeoLocation6${Font_Suffix}"
    fi
    if [ "$Result_Networkinfo_NetworkType" = "unknown" ]; then
        echo -e " ${Font_Yellow}No network information detected${Font_Suffix}"
    fi
}
#
# -> 网络信息模块 (Collector) -> 获取网络信息
function BenchAPI_Networkinfo_GetNetworkinfo() {
    local r_r4 && r_r4="$(curl --connect-timeout 10 -s4 https://ipapi.co/json/)"
    sleep 1
    local r_r6 && r_r6="$(curl --connect-timeout 10 -s6 https://ipapi.co/json/)"
    local r_r4_error && r_r4_error="$(BenchExec_PharseJSON "$r_r4" ".error")"
    local r_r6_error && r_r6_error="$(BenchExec_PharseJSON "$r_r6" ".error")"
    if [ "$r_r4_error" = "true" ]; then
        local r_r4=""
    fi
    if [ "$r_r6_error" = "true" ]; then
        local r_r6=""
    fi
    if [ "$r_r4" != "" ] && [ "$r_r6" = "" ]; then
        local r_ntype && r_ntype="ipv4"
        Result_Networkinfo_NetworkType="ipv4"
    elif [ "$r_r4" != "" ] && [ "$r_r6" = "" ]; then
        local r_ntype && r_ntype="ipv6"
        Result_Networkinfo_NetworkType="ipv6"
    elif [ "$r_r4" != "" ] && [ "$r_r6" != "" ]; then
        local r_ntype && r_ntype="dualstack"
        Result_Networkinfo_NetworkType="dualstack"
    else
        local r_ntype && r_ntype="unknown"
        Result_Networkinfo_NetworkType="unknown"
        return 1
    fi
    if [ "$r_ntype" = "ipv4" ] || [ "$r_ntype" = "dualstack" ]; then
        local r_r4_ip && r_r4_ip="$(BenchExec_PharseJSON "$r_r4" ".ip")"
        local r_r4_country_name && r_r4_country_name="$(BenchExec_PharseJSON "$r_r4" ".country_name")"
        local r_r4_region && r_r4_region="$(BenchExec_PharseJSON "$r_r4" ".region")"
        local r_r4_city && r_r4_city="$(BenchExec_PharseJSON "$r_r4" ".city")"
        local r_r4_country_code && r_r4_country_code="$(BenchExec_PharseJSON "$r_r4" ".country_code")"
        local r_r4_asn && r_r4_asn="$(BenchExec_PharseJSON "$r_r4" ".asn")"
        local r_r4_org && r_r4_org="$(BenchExec_PharseJSON "$r_r4" ".org")"
        Result_Networkinfo_IP4="$r_r4_ip"
        Result_Networkinfo_GeoLocation4="$r_r4_country_name $r_r4_region $r_r4_city"
        Result_Networkinfo_CountryCode4="$r_r4_country_code"
        Result_Networkinfo_NetworkOwner4="$r_r4_asn - $r_r4_org"
    fi
    if [ "$r_ntype" = "ipv6" ] || [ "$r_ntype" = "dualstack" ]; then
        local r_r6_ip && r_r6_ip="$(BenchExec_PharseJSON "$r_r6" ".ip")"
        local r_r6_country_name && r_r6_country_name="$(BenchExec_PharseJSON "$r_r6" ".country_name")"
        local r_r6_region && r_r6_region="$(BenchExec_PharseJSON "$r_r6" ".region")"
        local r_r6_city && r_r6_city="$(BenchExec_PharseJSON "$r_r6" ".city")"
        local r_r6_country_code && r_r6_country_code="$(BenchExec_PharseJSON "$r_r6" ".country_code")"
        local r_r6_asn && r_r6_asn="$(BenchExec_PharseJSON "$r_r6" ".asn")"
        local r_r6_org && r_r6_org="$(BenchExec_PharseJSON "$r_r6" ".org")"
        Result_Networkinfo_IP6="$r_r6_ip"
        Result_Networkinfo_GeoLocation6="$r_r6_country_name $r_r6_region $r_r6_city"
        Result_Networkinfo_CountryCode6="$r_r6_country_code"
        Result_Networkinfo_NetworkOwner6="$r_r6_asn - $r_r6_org"
    fi
}
#
# ===========================================================================
#
# -> 流媒体解锁测试模块 (DisplayOutput) - 输出解锁测试结果
function BenchFunc_StreamingServiceUnlockTest_RunTest() {
    echo -e "\n ${Font_Yellow}-> Streaming Service Unlock Test${Font_Suffix}"
    #
    echo -e "\n ${Font_Yellow}Netflix:${Font_Suffix}\t\t\t->\c"
    BenchAPI_StreamingServiceUnlockTest_Netflix
    echo -n -e "\r ${Font_Yellow}Netflix:${Font_Suffix}\t\t\t${Font_SkyBlue}$Result_StreamingServiceUnlockTest_Netflix${Font_Suffix}"
    #
    echo -e "\n ${Font_Yellow}HBO Now:${Font_Suffix}\t\t\t->\c"
    BenchAPI_StreamingServiceUnlockTest_HBONow
    echo -n -e "\r ${Font_Yellow}HBO Now:${Font_Suffix}\t\t\t${Font_SkyBlue}$Result_StreamingServiceUnlockTest_HBONow${Font_Suffix}"
    #
    echo -e "\n ${Font_Yellow}Youtube Premium:${Font_Suffix}\t\t->\c"
    BenchAPI_StreamingServiceUnlockTest_YoutubePremium
    echo -n -e "\r ${Font_Yellow}Youtube Premium:${Font_Suffix}\t\t${Font_SkyBlue}$Result_StreamingServiceUnlockTest_YoutubePremium${Font_Suffix}"
    #
    echo -e "\n ${Font_Yellow}Tiktok Region:${Font_Suffix}\t\t\t->\c"
    BenchAPI_StreamingServiceUnlockTest_TiktokRegion
    echo -n -e "\r ${Font_Yellow}Tiktok Region:${Font_Suffix}\t\t\t${Font_SkyBlue}$Result_StreamingServiceUnlockTest_TiktokRegion${Font_Suffix}"
    #
    echo -e "\n ${Font_Yellow}BBC iPlayer:${Font_Suffix}\t\t\t->\c"
    BenchAPI_StreamingServiceUnlockTest_BBCiPlayer
    echo -n -e "\r ${Font_Yellow}BBC iPlayer:${Font_Suffix}\t\t\t${Font_SkyBlue}$Result_StreamingServiceUnlockTest_BBCiPlayer${Font_Suffix}"
    #
    echo -e "\n ${Font_Yellow}NicoNico:${Font_Suffix}\t\t\t->\c"
    BenchAPI_StreamingServiceUnlockTest_NicoVideo
    echo -n -e "\r ${Font_Yellow}NicoNico:${Font_Suffix}\t\t\t${Font_SkyBlue}$Result_StreamingServiceUnlockTest_NicoVideo${Font_Suffix}"
    #
    echo -e "\n ${Font_Yellow}Princonne Re:dive Japan:${Font_Suffix}\t->\c"
    BenchAPI_StreamingServiceUnlockTest_PriconneRediveJP
    echo -n -e "\r ${Font_Yellow}Princonne Re:dive Japan:${Font_Suffix}\t${Font_SkyBlue}$Result_StreamingServiceUnlockTest_PriconneRediveJP${Font_Suffix}"
    #
    echo -e "\n ${Font_Yellow}Pretty Derby Japan:${Font_Suffix}\t\t->\c"
    BenchAPI_StreamingServiceUnlockTest_UmamusumeJP
    echo -n -e "\r ${Font_Yellow}Pretty Derby Japan:${Font_Suffix}\t\t${Font_SkyBlue}$Result_StreamingServiceUnlockTest_UmamusumeJP${Font_Suffix}"
    #
    echo -e "\n ${Font_Yellow}Kantai Collection Japan:${Font_Suffix}\t->\c"
    BenchAPI_StreamingServiceUnlockTest_KancolleJP
    echo -n -e "\r ${Font_Yellow}Kantai Collection Japan:${Font_Suffix}\t${Font_SkyBlue}$Result_StreamingServiceUnlockTest_KancolleJP${Font_Suffix}"
    #
    echo -e "\n ${Font_Yellow}Bahamut Anime:${Font_Suffix}\t\t\t->\c"
    BenchAPI_StreamingServiceUnlockTest_BahamutAnime
    echo -n -e "\r ${Font_Yellow}Bahamut Anime:${Font_Suffix}\t\t\t${Font_SkyBlue}$Result_StreamingServiceUnlockTest_BahamutAnime${Font_Suffix}"
    #
    echo -e "\n ${Font_Yellow}Bilibili (China Mainland):${Font_Suffix}\t->\c"
    BenchAPI_StreamingServiceUnlockTest_BilibiliChinaMainland
    echo -n -e "\r ${Font_Yellow}Bilibili (China Mainland):${Font_Suffix}\t${Font_SkyBlue}$Result_StreamingServiceUnlockTest_BilibiliChinaMainland${Font_Suffix}"
    #
    echo -e "\n ${Font_Yellow}Bilibili (China SAR&Taiwan):${Font_Suffix}\t->\c"
    BenchAPI_StreamingServiceUnlockTest_BilibiliChinaSARTaiwan
    echo -n -e "\r ${Font_Yellow}Bilibili (China SAR&Taiwan):${Font_Suffix}\t${Font_SkyBlue}$Result_StreamingServiceUnlockTest_BilibiliChinaSARTaiwan${Font_Suffix}"
    #
    echo -e "\n ${Font_Yellow}Bilibili (China Taiwan):${Font_Suffix}\t->\c"
    BenchAPI_StreamingServiceUnlockTest_BilibiliChinaTaiwan
    echo -n -e "\r ${Font_Yellow}Bilibili (China Taiwan):${Font_Suffix}\t${Font_SkyBlue}$Result_StreamingServiceUnlockTest_BilibiliChinaTaiwan${Font_Suffix}"
    #
    echo -e "\n ${Font_Yellow}Steam Price Currency:${Font_Suffix}\t\t->\c"
    BenchAPI_StreamingServiceUnlockTest_SteamPriceCurrency
    echo -n -e "\r ${Font_Yellow}Steam Price Currency:${Font_Suffix}\t\t${Font_SkyBlue}$Result_StreamingServiceUnlockTest_SteamPriceCurrency${Font_Suffix}"
    #
    echo -e ""
}
#
# -> 流媒体解锁测试模块 (Collector) - Netflix
function BenchAPI_StreamingServiceUnlockTest_Netflix() {
    local res1 && res1=$(curl -fsL --user-agent "$GlobalVar_UA_WebBrowser" --max-time "$GlobalVar_CurlMaxTime" --write-out "%{http_code}" --output /dev/null "https://www.netflix.com/title/81215567" 2>&1)
    case "$res1" in
    404)
        Result_StreamingServiceUnlockTest_Netflix="Netflix Only"
        return 0
        ;;
    200)
        local res2 && res2="$(curl -fsL --user-agent "$GlobalVar_UA_WebBrowser" --max-time "$GlobalVar_CurlMaxTime" --write-out "%{redirect_url}" --output /dev/null "https://www.netflix.com/title/80018499" | cut -d '/' -f4 | cut -d '-' -f1 | tr "[:lower:]" "[:upper:]")"
        [[ -z "$R_res2" ]] && Result_StreamingServiceUnlockTest_Netflix="Yes (GeoIP: US)" || Result_StreamingServiceUnlockTest_Netflix="Yes (GeoIP: $res2)"
        return 0
        ;;
    000)
        Result_StreamingServiceUnlockTest_Netflix="FAIL (Network Connection Error)"
        return 1
        ;;
    *)
        Result_StreamingServiceUnlockTest_Netflix="FAIL (Unexpected Result)"
        return 1
        ;;
    esac
}
#
# -> 流媒体解锁测试模块 (Collector) - HBO Now
function BenchAPI_StreamingServiceUnlockTest_HBONow() {
    local res1 && res1="$(curl -fsL --user-agent "$GlobalVar_UA_WebBrowser" --max-time "$GlobalVar_CurlMaxTime" --write-out "%{url_effective}" --output /dev/null https://play.hbonow.com/ 2>&1)"
    case "$res1" in
    "https://play.hbonow.com")
        Result_StreamingServiceUnlockTest_HBONow="Yes"
        return 0
        ;;
    "https://play.hbonow.com/")
        Result_StreamingServiceUnlockTest_HBONow="Yes"
        return 0
        ;;
    "https://play.hbomax.com")
        Result_StreamingServiceUnlockTest_HBONow="Yes"
        return 0
        ;;
    "https://play.hbomax.com/")
        Result_StreamingServiceUnlockTest_HBONow="Yes"
        return 0
        ;;
    "http://hbogeo.cust.footprint.net/hbonow/geo.html")
        Result_StreamingServiceUnlockTest_HBONow="No"
        return 0
        ;;
    "http://geocust.hbonow.com/hbonow/geo.html")
        Result_StreamingServiceUnlockTest_HBONow="No"
        return 0
        ;;
    "curl"*)
        Result_StreamingServiceUnlockTest_HBONow="FAIL (Network Connection Error)"
        return 1
        ;;
    *)
        Result_StreamingServiceUnlockTest_HBONow="FAIL (Unexpected Result)"
        return 1
        ;;
    esac
}
#
# -> 流媒体解锁测试模块 (Collector) - Youtube Premium
function BenchAPI_StreamingServiceUnlockTest_YoutubePremium() {
    local res1 && res1="$(curl -fsL --user-agent "$GlobalVar_UA_WebBrowser" --max-time "$GlobalVar_CurlMaxTime" https://www.youtube.com/red 2>&1)"
    if [[ "$res1" == "curl"* ]]; then
        Result_StreamingServiceUnlockTest_YoutubePremium="FAIL (Network Connection Error)"
        return 1
    fi
    local res2 && res2="$(echo "$res1" | grep -oP '(?<="countryCode":").*?(?=")')"
    if [ -n "$res2" ]; then
        Result_StreamingServiceUnlockTest_YoutubePremium="Yes (GeoIP: $res2)"
        return 0
    fi
    local res3 && res3="$(echo "$res1" | grep -o "Premium is not available in your country")"
    if [ -n "$res3" ]; then
        Result_StreamingServiceUnlockTest_YoutubePremium="No"
        return 0
    fi
    Result_StreamingServiceUnlockTest_YoutubePremium="FAIL (Unexpected Result)"
    return 1
}
#
# -> 流媒体解锁测试模块 (Collector) - Tiktok Region
function BenchAPI_StreamingServiceUnlockTest_TiktokRegion() {
    local res1 && res1="$(curl -fsL --user-agent "$GlobalVar_UA_WebBrowser" --max-time "$GlobalVar_CurlMaxTime" https://www.tiktok.com/ 2>&1)"
    if [[ "$res1" == "curl"* ]]; then
        Result_StreamingServiceUnlockTest_TiktokRegion="FAIL (Network Connection Error)"
        return 1
    fi
    local res2 && res2="$(echo "$res1" | grep -oP '(?<="\$region":").*?(?=")' | head -1)"
    if [ -n "$res2" ]; then
        Result_StreamingServiceUnlockTest_TiktokRegion="Yes"
        return 0
    else
        Result_StreamingServiceUnlockTest_TiktokRegion="No"
        return 0
    fi
}
#
# -> 流媒体解锁测试模块 (Collector) - BBC iPlayer
function BenchAPI_StreamingServiceUnlockTest_BBCiPlayer() {
    local res1 && res1="$(curl -fsL --user-agent "$GlobalVar_UA_WebBrowser" --max-time "$GlobalVar_CurlMaxTime" https://open.live.bbc.co.uk/mediaselector/6/select/version/2.0/mediaset/pc/vpid/bbc_one_london/format/json/jsfunc/JS_callbacks0 2>&1)"
    if [[ "$res1" == "curl"* ]]; then
        Result_StreamingServiceUnlockTest_BBCiPlayer="FAIL (Network Connection Error)"
        return 1
    fi
    local res2 && res2="$(echo "$res2" | grep -o "geolocation")"
    if [ "$res2" = "geolocation" ]; then
        Result_StreamingServiceUnlockTest_BBCiPlayer="No"
        return 0
    else
        Result_StreamingServiceUnlockTest_BBCiPlayer="Yes"
        return 0
    fi
}
#
# -> 流媒体解锁测试模块 (Collector) - NicoNico
function BenchAPI_StreamingServiceUnlockTest_NicoVideo() {
    local res1 && res1="$(curl -fsL --user-agent "$GlobalVar_UA_WebBrowser" --max-time "$GlobalVar_CurlMaxTime" https://www.nicovideo.jp/watch/so23017073 2>&1)"
    if [[ "$res1" == "curl"* ]]; then
        Result_StreamingServiceUnlockTest_NicoVideo="FAIL (Network Connection Error)"
        return 1
    fi
    local res2 && res2="$(echo "$res1" | grep -oP "(?<=<p class=\"fail-message\">).*(?=</p>)")"
    if [ "$res2" = "この動画は投稿( アップロード )された地域と同じ地域からのみ視聴できます。" ]; then
        Result_StreamingServiceUnlockTest_NicoVideo="No"
        return 0
    else
        Result_StreamingServiceUnlockTest_NicoVideo="Yes"
        return 0
    fi
}
#
# -> 流媒体解锁测试模块 (Collector) - Princess Connect Re:Dive (JPN Server)
function BenchAPI_StreamingServiceUnlockTest_PriconneRediveJP() {
    local res1 && res1="$(curl -fsL --user-agent "$GlobalVar_UA_UnityPlayer" --max-time "$GlobalVar_CurlMaxTime" --write-out "%{http_code}" --output /dev/null https://api-priconne-redive.cygames.jp/)"
    if [[ "$res1" == "curl"* ]]; then
        Result_StreamingServiceUnlockTest_PriconneRediveJP="FAIL (Network Connection Error)"
        return 1
    fi
    case "$res1" in
    404)
        Result_StreamingServiceUnlockTest_PriconneRediveJP="Yes"
        return 0
        ;;
    403)
        Result_StreamingServiceUnlockTest_PriconneRediveJP="No"
        return 0
        ;;
    000)
        Result_StreamingServiceUnlockTest_PriconneRediveJP="FAIL (Network Connection Error)"
        return 1
        ;;
    *)
        Result_StreamingServiceUnlockTest_PriconneRediveJP="FAIL (Unknown Result)"
        return 1
        ;;
    esac
}
#
# -> 流媒体解锁测试模块 (Collector) - Pretty Derby (JPN Server)
function BenchAPI_StreamingServiceUnlockTest_UmamusumeJP() {
    local res1 && res1="$(curl -fsL --user-agent "$GlobalVar_UA_UnityPlayer" --max-time "$GlobalVar_CurlMaxTime" --write-out "%{http_code}" --output /dev/null https://api-umamusume.cygames.jp/)"
    if [[ "$res1" == "curl"* ]]; then
        Result_StreamingServiceUnlockTest_UmamusumeJP="FAIL (Network Connection Error)"
        return 1
    fi
    case "$res1" in
    404)
        local f1 && f1="1"
        ;;
    403)
        local f1 && f1="0"
        ;;
    *)
        Result_StreamingServiceUnlockTest_UmamusumeJP="FAIL (Unexpected Result)"
        return 1
        ;;
    esac
    local res2 && res2="$(curl -fsL --user-agent "${GlobalVar_UA_UnityPlayer}" --max-time 10 --write-out "%{http_code}" --output /dev/null https://api-umamusume.cygames.jp/umamusume/tool/pre_signup)"
    if [[ "$res2" == "curl"* ]]; then
        Result_StreamingServiceUnlockTest_UmamusumeJP="FAIL (Network Connection Error)"
        return 1
    fi
    case "$res2" in
    500)
        local f2 && f2="1"
        ;;
    403)
        local f2 && f2="1"
        ;;
    *)
        Result_StreamingServiceUnlockTest_UmamusumeJP="FAIL (Unexpected Result)"
        return 1
        ;;
    esac
    if [ "$f1" = "1" ] && [ "$f2" = "1" ]; then
        Result_StreamingServiceUnlockTest_UmamusumeJP="Yes"
        return 0
    elif [ "$f1" = "1" ] && [ "$f2" = "0" ]; then
        Result_StreamingServiceUnlockTest_UmamusumeJP="Game Only (Cannot Register)"
        return 0
    else
        Result_StreamingServiceUnlockTest_UmamusumeJP="No"
        return 0
    fi
}
#
# -> 流媒体解锁测试模块 (Collector) - Kantai Collection (JPN Server)
function BenchAPI_StreamingServiceUnlockTest_KancolleJP() {
    local res1 && res1="$(curl -fsL --user-agent "$GlobalVar_UA_WebBrowser" --max-time "$GlobalVar_CurlMaxTime" --write-out "%{http_code}" --output /dev/null http://203.104.209.7/kcscontents/)"
    if [[ "$res1" == "curl"* ]]; then
        Result_StreamingServiceUnlockTest_KancolleJP="FAIL (Network Connection Error)"
        return 1
    fi
    case $res1 in
    200)
        Result_StreamingServiceUnlockTest_KancolleJP="Yes"
        return 0
        ;;
    403)
        Result_StreamingServiceUnlockTest_KancolleJP="No"
        return 0
        ;;
    000)
        Result_StreamingServiceUnlockTest_KancolleJP="FAIL (Network Connection Error)"
        return 1
        ;;
    *)
        Result_StreamingServiceUnlockTest_KancolleJP="FAIL (Unexpected Result)"
        return 1
        ;;
    esac
}
#
# -> 流媒体解锁测试模块 (Collector) - 巴哈姆特動畫瘋
function BenchAPI_StreamingServiceUnlockTest_BahamutAnime() {
    local res1 && res1="$(curl -fsL --user-agent "$GlobalVar_UA_WebBrowser" --max-time "$GlobalVar_CurlMaxTime" 'https://ani.gamer.com.tw/ajax/token.php?adID=89422&sn=14667' 2>&1)"
    if [[ "$res1" == "curl"* ]]; then
        Result_StreamingServiceUnlockTest_BahamutAnime="FAIL (Network Connection Error)"
        return 1
    fi
    local res2 && res2="$(BenchExec_PharseJSON "$res1" "error.code")"
    if [ "$res2" = "1011" ]; then
        Result_StreamingServiceUnlockTest_BahamutAnime="No"
        return 0
    fi
    local res3 && res3="$(BenchExec_PharseJSON "$res1" "animeSn")"
    if [ -n "$res3" ]; then
        Result_StreamingServiceUnlockTest_BahamutAnime="Yes"
        return 0
    else
        Result_StreamingServiceUnlockTest_BahamutAnime="No"
        return 0
    fi
}
#
# -> 流媒体解锁测试模块 (Collector) - 哔哩哔哩中国大陆地区限定
function BenchAPI_StreamingServiceUnlockTest_BilibiliChinaMainland() {
    local r_session && r_session="$(head -n 32 /dev/urandom | md5sum | head -c 32)"
    local res1 && res1="$(curl -fsL --user-agent "$GlobalVar_UA_WebBrowser" --max-time "$GlobalVar_CurlMaxTime" "https://api.bilibili.com/pgc/player/web/playurl?avid=82846771&qn=0&type=&otype=json&ep_id=307247&fourk=1&fnver=0&fnval=16&session=$r_session&module=bangumi" 2>&1)"
    if [[ "$res1" == "curl"* ]]; then
        Result_StreamingServiceUnlockTest_BilibiliChinaMainland="FAIL (Network Connection Error)"
        return 1
    fi
    local res2 && res2="$(BenchExec_PharseJSON "$res1" ".code")"
    case $res2 in
    0)
        Result_StreamingServiceUnlockTest_BilibiliChinaMainland="Yes"
        return 0
        ;;
    -10403)
        Result_StreamingServiceUnlockTest_BilibiliChinaMainland="No"
        return 0
        ;;
    *)
        Result_StreamingServiceUnlockTest_BilibiliChinaMainland="FAIL (Unexpected Result)"
        return 1
        ;;
    esac
}
# -> 流媒体解锁测试模块 (Collector) - 哔哩哔哩中国港澳台地区限定
function BenchAPI_StreamingServiceUnlockTest_BilibiliChinaSARTaiwan() {
    local r_session && r_session="$(head -n 32 /dev/urandom | md5sum | head -c 32)"
    local res1 && res1="$(curl -fsL --user-agent "$GlobalVar_UA_WebBrowser" --max-time "$GlobalVar_CurlMaxTime" "https://api.bilibili.com/pgc/player/web/playurl?avid=18281381&cid=29892777&qn=0&type=&otype=json&ep_id=183799&fourk=1&fnver=0&fnval=16&session=$r_session&module=bangumi" 2>&1)"
    if [[ "$res1" == "curl"* ]]; then
        Result_StreamingServiceUnlockTest_BilibiliChinaSARTaiwan="FAIL (Network Connection Error)"
        return 1
    fi
    local res2 && res2="$(BenchExec_PharseJSON "$res1" ".code")"
    case $res2 in
    0)
        Result_StreamingServiceUnlockTest_BilibiliChinaSARTaiwan="Yes"
        return 0
        ;;
    -10403)
        Result_StreamingServiceUnlockTest_BilibiliChinaSARTaiwan="No"
        return 0
        ;;
    *)
        Result_StreamingServiceUnlockTest_BilibiliChinaSARTaiwan="FAIL (Unexpected Result)"
        return 1
        ;;
    esac
}
# -> 流媒体解锁测试模块 (Collector) - 哔哩哔哩中国台湾地区限定
function BenchAPI_StreamingServiceUnlockTest_BilibiliChinaTaiwan() {
    local r_session && r_session="$(head -n 32 /dev/urandom | md5sum | head -c 32)"
    local res1 && res1="$(curl -fsL --user-agent "${GlobalVar_UA_WebBrowser}" --max-time "$GlobalVar_CurlMaxTime" "https://api.bilibili.com/pgc/player/web/playurl?avid=50762638&cid=100279344&qn=0&type=&otype=json&ep_id=268176&fourk=1&fnver=0&fnval=16&session=$r_session&module=bangumi" 2>&1)"
    if [[ "$res1" == "curl"* ]]; then
        Result_StreamingServiceUnlockTest_BilibiliChinaTaiwan="FAIL (Network Connection Error)"
        return 1
    fi
    local res2 && res2="$(BenchExec_PharseJSON "$res1" ".code")"
    case $res2 in
    0)
        Result_StreamingServiceUnlockTest_BilibiliChinaTaiwan="Yes"
        return 0
        ;;
    -10403)
        Result_StreamingServiceUnlockTest_BilibiliChinaTaiwan="No"
        return 0
        ;;
    *)
        Result_StreamingServiceUnlockTest_BilibiliChinaTaiwan="FAIL (Unexpected Result)"
        return 1
        ;;
    esac
}
# -> 流媒体解锁测试模块 (Collector) - Steam Price Currency
function BenchAPI_StreamingServiceUnlockTest_SteamPriceCurrency() {
    local res1 && res1="$(curl -fsL --user-agent "$GlobalVar_UA_WebBrowser" --max-time "$GlobalVar_CurlMaxTime" https://store.steampowered.com/app/20 2>&1)"
    if [[ "$res1" == "curl"* ]]; then
        Result_StreamingServiceUnlockTest_SteamPriceCurrency="FAIL (Network Connection Error)"
        return 1
    fi
    local res2 && res2="$(echo "$res1" | grep 'priceCurrency' | grep -oP '(?<=content\=").*?(?=")')"
    if [ -n "$res2" ]; then
        Result_StreamingServiceUnlockTest_SteamPriceCurrency="$res2"
        return 0
    fi
    Result_StreamingServiceUnlockTest_SteamPriceCurrency="FAIL (Unexpected Result)"
    return 1
}
# ===========================================================================
# -> CPU 性能测试模块 (Entrypoint) -> 执行 (快速模式)
function BenchFunc_PerformanceTest_CPU_RunTest_Fast() {
    BenchAPI_PerformanceTest_CPU "fast" "5" "1"
}
# -> CPU 性能测试模块 (Entrypoint) -> 执行 (完整模式)
function BenchFunc_PerformanceTest_CPU_RunTest_Full() {
    BenchAPI_PerformanceTest_CPU "full" "30" "3"
}
# -> CPU 性能测试模块 (Executor) -> 执行核心代码
function BenchExec_Sysbench_CPU() {
    local cc && cc="1"  # Count Current
    local ct && ct="$3" # Count Total
    local sc && sc="0"  # Score Current
    local st && st="0"  # Score Total
    while [ "$cc" -le "$ct" ]; do
        local rr && rr="$(sysbench --num-threads="$1" --cpu-max-prime=10000 --events=1000000 --time="$2" cpu run 2>&1)"
        local sc && sc="$(echo "$rr" | grep "events per second:" | grep -oE "[0-9]+\.[0-9]+")"
        local st && st="$(echo "$st $sc" | awk '{printf "%.2f",$1+$2}')"
        ((cc = cc + 1))
        rr=""
        sc="0"
    done
    local sa && sa="$(echo "$st $ct" | awk '{printf "%.2f",$1/$2}')" # Score Average (=Final Score)
    echo -n "$sa"
    sleep 1
    return 0
}
# -> CPU 性能测试模块 (Collector) -> 运行测试
function BenchAPI_PerformanceTest_CPU() {
    if [ "$1" = "fast" ]; then
        echo -e "\n ${Font_Yellow}-> CPU Performance Test (Fast mode, $3-Pass @ $2sec)${Font_Suffix}\n"
        Result_PerformanceTest_CPU_BenchTitle=" -> CPU Performance Test (Fast mode, $3-Pass @ $2sec)"
    elif [ "$1" = "full" ]; then
        echo -e "\n ${Font_Yellow}-> CPU Performance Test (Full mode, $3-Pass @ $2sec)${Font_Suffix}\n"
        Result_PerformanceTest_CPU_BenchTitle=" -> CPU Performance Test (Full mode, $3-Pass @ $2sec)"
    else
        echo -e "${Msg_Error} BenchAPI_PerformanceTest_CPU(): invalid params ($1), please check parameter!"
        exit 1
    fi
    echo -e " ${Font_Yellow}1 Thread(s) Test:${Font_Suffix}\t\t->\c"
    local res1 && res1="$(BenchExec_Sysbench_CPU 1 "$2" "$3")"
    echo -n -e "\r ${Font_Yellow}1 Thread(s) Test:${Font_Suffix}\t\t${Font_SkyBlue}$res1 Scores (1.00x)${Font_Suffix}\n"
    Result_PerformanceTest_CPU_SingleCore=" 1 Thread(s) Test:\t\t$res1 Scores (1.00x)"
    #
    if [ "$Result_Systeminfo_CPUCores" -ge "2" ]; then
        local v2 && v2="$Result_Systeminfo_CPUCores"
        echo -e " ${Font_Yellow}$v2 Thread(s) Test:${Font_Suffix}\t\t->\c"
        local res2 && res2="$(BenchExec_Sysbench_CPU "$v2" "$2" "$3")"
        local m2 && m2="$(echo "$res2" "$res1" | awk '{printf "%.2f",$1/$2}')"
        echo -n -e "\r ${Font_Yellow}$v2 Thread(s) Test:${Font_Suffix}\t\t${Font_SkyBlue}$res2 Scores (${m2}x)${Font_Suffix}\n"
        Result_PerformanceTest_CPU_MultiCore=" $v2 Thread(s) Test:\t\t$res2 Scores (${m2}x)"
    fi
    if [ "$Result_Systeminfo_CPUCores" != "$Result_Systeminfo_CPUThreads" ]; then
        local v3 && v3="$Result_Systeminfo_CPUThreads"
        echo -e " ${Font_Yellow}$v3 Thread(s) Test:${Font_Suffix}\t\t->\c"
        local res3 && res3="$(BenchExec_Sysbench_CPU "$v3" "$2" "$3")"
        local m3 && m3="$(echo "$res3" "$res1" | awk '{printf "%.2f",$1/$2}')"
        echo -n -e "\r ${Font_Yellow}$v3 Thread(s) Test:${Font_Suffix}\t\t${Font_SkyBlue}$res3 Scores (${m3}x)${Font_Suffix}\n"
        Result_PerformanceTest_CPU_MultiCoreHT=" $v3 Thread(s) Test:\t\t$res3 Scores (${m3}x)"
    fi
}
# ===========================================================================
# -> 磁盘性能测试模块 (Entrypoint) -> 执行
function BenchFunc_PerformanceTest_Disk_RunTest() {
    BenchFunc_PerformanceTest_Disk_RunTest_FIO
}
# -> 磁盘性能测试 (Executor) -> 执行核心代码
function BenchExec_FIO() {
    if [ "$1" == "read" ] || [ "$1" == "randread" ]; then
        local rr && rr="$("${GlobalVar_BaseDir}"/bin/fio -ioengine=libaio -rw="$1" -bs="$2" -size="$3" -direct=1 -iodepth="$4" -runtime="$5" -name="$6" --minimal)"
        local rra && rra=(${rr//;/ }) # Result Array
        local rss && rss="${rra[6]}"  # Result Score Speed (KB/s)
        local rsi && rsi="${rra[7]}"  # Result Score IOPS
    elif [ "$1" == "write" ] || [ "$1" == "randwrite" ]; then
        local rr && rr="$("${GlobalVar_BaseDir}"/bin/fio -ioengine=libaio -rw="$1" -bs="$2" -size="$3" -direct=1 -iodepth="$4" -runtime="$5" -name="$6" --minimal)"
        local rra && rra=(${rr//;/ }) # Result Array
        local rss && rss="${rra[47]}" # Result Score Speed (KB/s)
        local rsi && rsi="${rra[48]}" # Result Score IOPS
    else
        echo -e "${Msg_Error} BenchExec_FIO(): invalid params ($1), please check parameter!"
        exit 1
    fi
    # if [ "$rss" -ge "1073741824" ]; then # 结果 TB/s
    #     local rs && rs="$(echo "$rss" | awk '{printf "%.2f\n",$1/1073741824}')"
    #     local r && r="$rs TB/s ($rsi IOPS)"
    # elif [ "$rss" -ge "1048576" ]; then # 结果 GB/s
    #     local rs && rs="$(echo "$rss" | awk '{printf "%.2f\n",$1/1048576}')"
    #    local r && r="$rs GB/s ($rsi IOPS)"
    if [ "$rss" -ge "1024" ]; then # 结果 MB/s
        local rs && rs="$(echo "$rss" | awk '{printf "%.2f\n",$1/1024}')"
        local r && r="$rs MB/s ($rsi IOPS)"
    else # 结果 KB/s
        local r && r="$rss KB/s ($rsi IOPS)"
    fi
    echo -n "$r"
    rm -f "$6.0.0"
}
# -> 磁盘性能测试 (Collector) -> 运行测试
function BenchFunc_PerformanceTest_Disk_RunTest_FIO() {
    echo -e "\n ${Font_Yellow}-> Disk Performance Test (Using FIO, Direct mode, 32 IO-Depth)${Font_Suffix}\n"
    #
    mkdir -p "${GlobalVar_BaseDir}/tmp" >/dev/null 2>&1
    echo -n -e " ${Font_Yellow}Write Test (4K-Block):${Font_Suffix}\t\t->\c"
    local rw4 && rw4="$(BenchExec_FIO "randwrite" "4k" "50m" "32" "60" "${GlobalVar_BaseDir}/tmp/TestFile.bin")"
    echo -n -e "\r ${Font_Yellow}Write Test (4K-Block):${Font_Suffix}\t\t${Font_SkyBlue}$rw4${Font_Suffix}\n"
    Result_PerformanceTest_Disk_4KRandWrite=" Write Test (4K-Block):\t\t$rw4"
    #
    echo -n -e " ${Font_Yellow}Read Test (4K-Block):${Font_Suffix}\t\t->\c"
    local rr4 && rr4="$(BenchExec_FIO "randread" "4k" "50m" "32" "60" "${GlobalVar_BaseDir}/tmp/TestFile.bin")"
    echo -n -e "\r ${Font_Yellow}Read  Test (4K-Block):${Font_Suffix}\t\t${Font_SkyBlue}$rr4${Font_Suffix}\n"
    Result_PerformanceTest_Disk_4KRandRead=" Read  Test (4K-Block):\t\t$rr4"
    #
    echo -n -e " ${Font_Yellow}Write Test (128K-Block):${Font_Suffix}\t->\c"
    local rw128 && rw128="$(BenchExec_FIO "randwrite" "128k" "100m" "32" "60" "${GlobalVar_BaseDir}/tmp/TestFile.bin")"
    echo -n -e "\r ${Font_Yellow}Write Test (128K-Block):${Font_Suffix}\t${Font_SkyBlue}$rw128${Font_Suffix}\n"
    Result_PerformanceTest_Disk_128KRandWrite=" Write Test (128K-Block):\t$rw128"
    #
    echo -n -e " ${Font_Yellow}Read Test (128K-Block):${Font_Suffix}\t->\c"
    local rr128 && rr128="$(BenchExec_FIO "randread" "128k" "100m" "32" "60" "${GlobalVar_BaseDir}/tmp/TestFile.bin")"
    echo -n -e "\r ${Font_Yellow}Read  Test (128K-Block):${Font_Suffix}\t${Font_SkyBlue}$rr128${Font_Suffix}\n"
    Result_PerformanceTest_Disk_128KRandRead=" Read  Test (128K-Block):\t$rr128"
}
# ===========================================================================
# -> 网络速度测试 (Executor) -> 执行核心代码
function BenchExec_NetworkSpeedTest() {
    # 根据传参, 确认测试目标类型 (default=默认最近测试点 id=根据Speedtest ServerID host=根据Speedtest FQDN)
    if [ "$1" = "default" ]; then
        local res && res="$("${GlobalVar_BaseDir}"/bin/speedtest --accept-license --accept-gdpr --format=json --unit=Mbps --progress=no 2>/dev/null)"
        local ret && ret="$?"
    elif [ "$1" = "id" ]; then
        local res && res="$("${GlobalVar_BaseDir}"/bin/speedtest --server-id="$2" --accept-license --accept-gdpr --format=json --unit=Mbps --progress=no 2>/dev/null)"
        local ret && ret="$?"
    elif [ "$1" = "host" ]; then
        local res && res="$("${GlobalVar_BaseDir}"/bin/speedtest --host="$2" --accept-license --accept-gdpr --format=json --unit=Mbps --progress=no 2>/dev/null)"
        local ret && ret="$?"
    else
        echo -n "FAIL (Invalid Parameter)"
        return 1
    fi
    # 异常处理
    if [ "$ret" = "2" ]; then
        local res_lv && res_lv="$(BenchExec_PharseJSON "$res" "level")"
        local res_msg && res_msg="$(BenchExec_PharseJSON "$res" "message")"
        if [ "$res_lv" = "error" ] && [ "$res_msg" = "Configuration - No servers defined (NoServersException)" ]; then
            echo -e -n "FAIL: Server Offline (NoServersException)"
            return 1
        else
            echo -e -n "FAIL: $res"
            return 1
        fi
    # 结果处理
    elif [ "$ret" = "0" ] || [ "$ret" = "1" ]; then
        local res_pl && res_pl="$(BenchExec_PharseJSON "$res" ".ping.latency" | awk '{printf "%.2f", $1}')"
        local res_db && res_db="$(BenchExec_PharseJSON "$res" ".download.bandwidth" | awk '{printf "%.2f", $1/1024/1024*8}')"
        local res_ub && res_ub="$(BenchExec_PharseJSON "$res" ".upload.bandwidth" | awk '{printf "%.2f", $1/1024/1024*8}')"
        local res_sn && res_sn="$(BenchExec_PharseJSON "$res" ".server.name")"
        local res_sc && res_sc="$(BenchExec_PharseJSON "$res" ".server.country")"
        local res_sl && res_sl="$(BenchExec_PharseJSON "$res" ".server.location")"
        if [ "$res_pl" != "" ] && [ "$res_db" != "" ] && [ "$res_ub" != "" ]; then
            echo -e -n "$res_db Mbps\t$res_ub Mbps\t$res_pl ms\t$res_sn, $res_sc $res_sl"
            return 0
        elif [ "$res_pl" = "null" ] && [ "$res_db" = "null" ] && [ "$res_ub" = "null" ]; then
            echo -e -n "FAIL: Connection Problem"
            return 1
        else
            echo -e -n "FAIL: $res"
            return 1
        fi
    else
        echo -e -n "FAIL: $res"
    fi
}
#
# -> 网络速度测试 (Collector) -> 运行测试
function BenchFunc_Speedtest_Fast_Pretty() {
    mkdir -p "${GlobalVar_BaseDir}/tmp/result" >/dev/null 2>&1
    local v_resfile && v_resfile="${GlobalVar_BaseDir}/tmp/result/speedtest.restmp"
    echo -e "\n ${Font_Yellow}-> Network Speedtest Test (Using Ookla Speedtest, Fast Test Mode)${Font_Suffix}\n"
    echo -e "\n -> Network Speedtest Test (Using Ookla Speedtest, Fast Test Mode)\n" >"$v_resfile"
    echo -e " ${Font_Yellow}Node Name\t\t\tDownload Speed\tUpload Speed\tPing Latency\tServer Name${Font_Suffix}"
    echo -e " Node Name\t\t\tDownload Speed\tUpload Speed\tPing Latency\tServer Name" >>"$v_resfile"
    #
    echo -n -e " ${Font_Yellow}Speedtest Default:${Font_Suffix}\t\t->\c"
    local res_default && res_default="$(BenchExec_NetworkSpeedTest "default" "default")"
    echo -n -e "\r ${Font_Yellow}Speedtest Default:${Font_Suffix}\t\t${Font_SkyBlue}${res_default}${Font_Suffix}\n"
    echo -e " Speedtest Default:\t\t${res_default}" >>"$v_resfile"
    #
    echo -n -e " ${Font_Yellow}China Unicom Shanghai:${Font_Suffix}\t\t->\c"
    local res_cush && res_cush="$(BenchExec_NetworkSpeedTest "host" "5g.shunicomtest.com")"
    echo -n -e "\r ${Font_Yellow}China Unicom Shanghai:${Font_Suffix}\t\t${Font_SkyBlue}${res_cush}${Font_Suffix}\n"
    echo -e " China Unicom Shanghai:\t\t${res_cush}" >>"$v_resfile"
    #
    echo -n -e " ${Font_Yellow}China Telecom Shanghai:${Font_Suffix}\t->\c"
    local res_ctsh && res_ctsh="$(BenchExec_NetworkSpeedTest "host" "speedtest1.online.sh.cn")"
    echo -n -e "\r ${Font_Yellow}China Telecom Shanghai:${Font_Suffix}\t${Font_SkyBlue}${res_ctsh}${Font_Suffix}\n"
    echo -e " China Telecom Shanghai:\t${res_ctsh}" >>"$v_resfile"
    #
    echo -n -e " ${Font_Yellow}China Mobile Sichuan:${Font_Suffix}\t\t->\c"
    local res_chinamobile && res_chinamobile="$(BenchExec_NetworkSpeedTest "host" "speedtest1.sc.chinamobile.com")"
    echo -n -e "\r ${Font_Yellow}China Mobile Sichuan:${Font_Suffix}\t\t${Font_SkyBlue}${res_chinamobile}${Font_Suffix}\n"
    echo -e " China Mobile Sichuan:\t\t${res_chinamobile}" >>"$v_resfile"
    return 0
}
function BenchFunc_Speedtest_Full_Pretty() {
    mkdir -p "${GlobalVar_BaseDir}/tmp/result" >/dev/null 2>&1
    local v_resfile && v_resfile="${GlobalVar_BaseDir}/tmp/result/speedtest.restmp"
    echo -e "\n ${Font_Yellow}-> Network Speedtest Test (Using Ookla Speedtest, Full Test Mode)${Font_Suffix}\n"
    echo -e "\n -> Network Speedtest Test (Using Ookla Speedtest, Full Test Mode)\n" >"$v_resfile"
    echo -e " ${Font_Yellow}Node Name\t\t\tDownload Speed\tUpload Speed\tPing Latency\tServer Name${Font_Suffix}"
    echo -e " Node Name\t\t\tDownload Speed\tUpload Speed\tPing Latency\tServer Name" >>"$v_resfile"
    #
    echo -n -e " ${Font_Yellow}Speedtest Default:${Font_Suffix}\t\t->\c"
    local res_default && res_default="$(BenchExec_NetworkSpeedTest "default" "default")"
    echo -n -e "\r ${Font_Yellow}Speedtest Default:${Font_Suffix}\t\t${Font_SkyBlue}${res_default}${Font_Suffix}\n"
    echo -e " Speedtest Default:\t\t${res_default}" >>"$v_resfile"
    #
    echo -n -e " ${Font_Yellow}China Unicom Shanghai:${Font_Suffix}\t\t->\c"
    local res_cush && res_cush="$(BenchExec_NetworkSpeedTest "host" "5g.shunicomtest.com")"
    echo -n -e "\r ${Font_Yellow}China Unicom Shanghai:${Font_Suffix}\t\t${Font_SkyBlue}${res_cush}${Font_Suffix}\n"
    echo -e " China Unicom Shanghai:\t\t${res_cush}" >>"$v_resfile"
    #
    echo -n -e " ${Font_Yellow}China Telecom Shanghai:${Font_Suffix}\t->\c"
    local res_ctsh && res_ctsh="$(BenchExec_NetworkSpeedTest "host" "speedtest1.online.sh.cn")"
    echo -n -e "\r ${Font_Yellow}China Telecom Shanghai:${Font_Suffix}\t${Font_SkyBlue}${res_ctsh}${Font_Suffix}\n"
    echo -e " China Telecom Shanghai:\t${res_ctsh}" >>"$v_resfile"
    #
    echo -n -e " ${Font_Yellow}China Mobile Sichuan:${Font_Suffix}\t\t->\c"
    local res_chinamobile && res_chinamobile="$(BenchExec_NetworkSpeedTest "host" "speedtest1.sc.chinamobile.com")"
    echo -n -e "\r ${Font_Yellow}China Mobile Sichuan:${Font_Suffix}\t\t${Font_SkyBlue}${res_chinamobile}${Font_Suffix}\n"
    echo -e " China Mobile Sichuan:\t\t${res_chinamobile}" >>"$v_resfile"
    return 0
}
#
# ===========================================================================
# -> 路由追踪测试 (Executor)
# $1=目标IP $2=协议类型(icmp/tcp/udp) $3=最大跃点数 $4=目标名称
function BenchExec_Traceroute_Core() {
    "${GlobalVar_BaseDir}"/bin/nexttrace -q 1 -m "$3" -n -g en -c -M "$1"
}
# -> 路由追踪测试 (Collector)
function BenchAPI_Traceroute_Pretty() {
    mkdir -p "${GlobalVar_BaseDir}/tmp/result" >/dev/null 2>&1
    local v_resfile && v_resfile="${GlobalVar_BaseDir}/tmp/result/traceroute.restmp"
    if [ "$2" = "icmp" ] || [ "$2" = "ICMP" ]; then
        echo -e "${Font_Yellow} [+] Traceroute to ${Font_Suffix}${Font_SkyBlue}$4${Font_Suffix}${Font_Yellow} (${Font_Suffix}${Font_SkyBlue}ICMP${Font_Suffix} ${Font_Yellow}Mode, Max${Font_Suffix} ${Font_SkyBlue}$3${Font_Suffix} ${Font_Yellow}Hops)${Font_Suffix}\n"
        echo -e "[+] Traceroute to $4(ICMP Mode, Max $3 Hops)" >>"$v_resfile"
        BenchExec_Traceroute_Core "$1" "icmp" "$3" | tee -a "$v_resfile"
    elif [ "$2" = "tcp" ] || [ "$2" = "TCP" ]; then
        echo -e "${Font_Yellow} [+] Traceroute to ${Font_Suffix}${Font_SkyBlue}$4${Font_Suffix}${Font_Yellow} (${Font_Suffix}${Font_SkyBlue}TCP${Font_Suffix} ${Font_Yellow}Mode, Max${Font_Suffix} ${Font_SkyBlue}$3${Font_Suffix} ${Font_Yellow}Hops)${Font_Suffix}\n"
        echo -e " [+] Traceroute to $4(TCP Mode, Max $3 Hops)" >>"$v_resfile"
        BenchExec_Traceroute_Core "$1" "tcp" "$3" | tee -a "$v_resfile"
    elif [ "$2" = "udp" ] || [ "$2" = "UDP" ]; then
        echo -e "${Font_Yellow} [+] Traceroute to ${Font_Suffix}${Font_SkyBlue}$4${Font_Suffix}${Font_Yellow} (${Font_Suffix}${Font_SkyBlue}UDP${Font_Suffix} ${Font_Yellow}Mode, Max${Font_Suffix} ${Font_SkyBlue}$3${Font_Suffix} ${Font_Yellow}Hops)${Font_Suffix}\n"
        echo -e " [+] Traceroute to $4(UDP Mode, Max $3 Hops)" >>"$v_resfile"
        BenchExec_Traceroute_Core "$1" "udp" "$3" | tee -a "$v_resfile"
    else
        echo -e "${Font_Yellow} [+] Traceroute to ${Font_Suffix}${Font_SkyBlue}$4${Font_Suffix}${Font_Yellow} (${Font_Suffix}${Font_SkyBlue}ICMP${Font_Suffix} ${Font_Yellow}Mode, Max${Font_Suffix} ${Font_SkyBlue}$3${Font_Suffix} ${Font_Yellow}Hops)${Font_Suffix}\n"
        echo -e " [+] Traceroute to $4(ICMP Mode, Max $3 Hops)" >>"$v_resfile"
        BenchExec_Traceroute_Core "$1" "icmp" "$3" | tee -a "$v_resfile"
    fi
    echo -e "" | tee -a "$v_resfile"
    return 0
}
# -> 路由追踪测试 (Entrypoint)
function BenchFunc_Traceroute_Fast_Pretty() {
    mkdir -p "${GlobalVar_BaseDir}/tmp/result" >/dev/null 2>&1
    local v_resfile && v_resfile="${GlobalVar_BaseDir}/tmp/result/traceroute.restmp"
    echo -e "\n ${Font_Yellow}-> Traceroute Test (Fast Mode)${Font_Suffix}\n"
    echo -e "\n -> Traceroute Test (Fast Mode)\n" >"$v_resfile"
    if [ "$Result_Networkinfo_NetworkType" = "ipv4" ] || [ "$Result_Networkinfo_NetworkType" = "dualstack" ]; then
        BenchAPI_Traceroute_Pretty "113.209.132.146" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "China Unicom (Beijing, IPv4)"
        BenchAPI_Traceroute_Pretty "45.126.112.33" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "China Telecom (Beijing, IPv4)"
        BenchAPI_Traceroute_Pretty "183.242.65.12" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "China Mobile (Beijing, IPv4)"
        BenchAPI_Traceroute_Pretty "103.116.79.1" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "China Unicom (Shanghai, IPv4)"
        BenchAPI_Traceroute_Pretty "210.5.157.1" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "China Telecom (Shanghai, IPv4)"
        BenchAPI_Traceroute_Pretty "117.144.213.77" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "China Mobile (Shanghai, IPv4)"
        BenchAPI_Traceroute_Pretty "210.21.4.130" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "China Unicom (Guangzhou, IPv4)"
        BenchAPI_Traceroute_Pretty "113.108.209.1" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "China Telecom (Guangzhou, IPv4)"
        BenchAPI_Traceroute_Pretty "183.232.48.167" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "China Mobile (Guangzhou, IPv4)"
        BenchAPI_Traceroute_Pretty "210.13.66.238" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "China Unicom CUII/AS9929 (Shanghai, IPv4)"
        BenchAPI_Traceroute_Pretty "58.32.0.1" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "China Telecom CN2/AS4812 (Shanghai, IPv4)"
        BenchAPI_Traceroute_Pretty "14.131.128.1" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "China Dr.Peng HomeNetwork (Beijing, IPv4)"
        BenchAPI_Traceroute_Pretty "211.167.230.100" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "China Dr.Peng BizNetwork (Beijing, IPv4)"
        BenchAPI_Traceroute_Pretty "101.6.6.6" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "China CERNET (Beijing, IPv4)"
        BenchAPI_Traceroute_Pretty "159.226.254.1" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "China CSTNET (Beijing, IPv4)"
        BenchAPI_Traceroute_Pretty "211.156.140.17" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "China RTVB (Beijing, IPv4)"
    fi
    # IPv6
    if [ "$Result_Networkinfo_NetworkType" = "ipv6" ] || [ "$Result_Networkinfo_NetworkType" = "dualstack" ]; then
        BenchAPI_Traceroute_Pretty "2408:80f0:4100:2005::3" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "China Unicom (Beijing, IPv6)"
        BenchAPI_Traceroute_Pretty "2400:da00:2::29" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "China Telecom (Beijing, IPv6)"
        BenchAPI_Traceroute_Pretty "2409:8089:1020:50ff:1000::fd01" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "China Mobile (Beijing, IPv6)"
        BenchAPI_Traceroute_Pretty "2408:8000:9000:20e6::b7" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "China Unicom (Shanghai, IPv6)"
        BenchAPI_Traceroute_Pretty "240e:18:10:a01::1" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "China Telecom (Shanghai, IPv6)"
        BenchAPI_Traceroute_Pretty "2409:801e:5c03:2000::207" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "China Mobile (Shanghai, IPv6)"
        BenchAPI_Traceroute_Pretty "2408:8001:3011:310::3" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "China Unicom (Guangzhou, IPv6)"
        BenchAPI_Traceroute_Pretty "240e:ff:e02c:1:21::" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "China Telecom (Guangzhou, IPv6)"
        BenchAPI_Traceroute_Pretty "2409:8057:5c00:30::6" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "China Mobile (Guangzhou, IPv6)"
        BenchAPI_Traceroute_Pretty "2001:da8:a0:1001::1" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "China CERNET2 (Beijing, IPv6)"
        BenchAPI_Traceroute_Pretty "2400:dd00:0:37::213" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "China CSTNET (Beijing, IPv6)"
    fi
}
# -> 路由追踪测试 (Executor)
function BenchFunc_Traceroute_Full_Pretty() {
    mkdir -p "${GlobalVar_BaseDir}/tmp/result" >/dev/null 2>&1
    local v_resfile && v_resfile="${GlobalVar_BaseDir}/tmp/result/traceroute.restmp"
    echo -e "\n ${Font_Yellow}-> Traceroute Test (Fast Mode)${Font_Suffix}\n"
    echo -e "\n -> Traceroute Test (Fast Mode)\n" >"$v_resfile"
    if [ "$Result_Networkinfo_NetworkType" = "ipv4" ] || [ "$Result_Networkinfo_NetworkType" = "dualstack" ]; then
        BenchAPI_Traceroute_Pretty "113.209.132.146" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "China Unicom (Beijing, IPv4)"
        BenchAPI_Traceroute_Pretty "45.126.112.33" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "China Telecom (Beijing, IPv4)"
        BenchAPI_Traceroute_Pretty "183.242.65.12" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "China Mobile (Beijing, IPv4)"
        BenchAPI_Traceroute_Pretty "103.116.79.1" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "China Unicom (Shanghai, IPv4)"
        BenchAPI_Traceroute_Pretty "210.5.157.1" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "China Telecom (Shanghai, IPv4)"
        BenchAPI_Traceroute_Pretty "117.144.213.77" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "China Mobile (Shanghai, IPv4)"
        BenchAPI_Traceroute_Pretty "210.21.4.130" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "China Unicom (Guangzhou, IPv4)"
        BenchAPI_Traceroute_Pretty "113.108.209.1" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "China Telecom (Guangzhou, IPv4)"
        BenchAPI_Traceroute_Pretty "183.232.48.167" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "China Mobile (Guangzhou, IPv4)"
        BenchAPI_Traceroute_Pretty "210.13.66.238" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "China Unicom CUII/AS9929 (Shanghai, IPv4)"
        BenchAPI_Traceroute_Pretty "58.32.0.1" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "China Telecom CN2/AS4812 (Shanghai, IPv4)"
        BenchAPI_Traceroute_Pretty "14.131.128.1" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "China Dr.Peng HomeNetwork (Beijing, IPv4)"
        BenchAPI_Traceroute_Pretty "211.167.230.100" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "China Dr.Peng BizNetwork (Beijing, IPv4)"
        BenchAPI_Traceroute_Pretty "101.6.6.6" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "China CERNET (Beijing, IPv4)"
        BenchAPI_Traceroute_Pretty "159.226.254.1" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "China CSTNET (Beijing, IPv4)"
        BenchAPI_Traceroute_Pretty "211.156.140.17" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "China RTVB (Beijing, IPv4)"
        BenchAPI_Traceroute_Pretty "203.160.95.218" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "中国-香港联通"
        BenchAPI_Traceroute_Pretty "203.215.232.173" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "中国-香港电信"
        BenchAPI_Traceroute_Pretty "203.8.25.187" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "中国-香港电信CN2"
        BenchAPI_Traceroute_Pretty "203.142.105.9" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "中国-香港移动"
        BenchAPI_Traceroute_Pretty "218.188.104.30" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "中国-香港HGC"
        BenchAPI_Traceroute_Pretty "210.6.23.239" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "中国-香港HKBN"
        BenchAPI_Traceroute_Pretty "202.85.125.60" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "中国-香港PCCW"
        BenchAPI_Traceroute_Pretty "202.123.76.239" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "中国-香港TGT"
        BenchAPI_Traceroute_Pretty "59.152.252.242" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "中国-香港WTT"
        BenchAPI_Traceroute_Pretty "203.215.233.1" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "新加坡-中国电信"
        BenchAPI_Traceroute_Pretty "183.91.61.1" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "新加坡-中国电信CN2"
        BenchAPI_Traceroute_Pretty "118.201.1.11" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "新加坡-Singtel"
        BenchAPI_Traceroute_Pretty "203.116.46.33" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "新加坡-StarHub"
        BenchAPI_Traceroute_Pretty "118.189.184.1" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "新加坡-M1"
        BenchAPI_Traceroute_Pretty "118.189.38.17" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "新加坡-M1 GamePro"
        BenchAPI_Traceroute_Pretty "13.228.0.251" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "新加坡-AWS"
        BenchAPI_Traceroute_Pretty "61.213.155.84" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "日本-NTT"
        BenchAPI_Traceroute_Pretty "202.232.15.70" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "日本-IIJ"
        BenchAPI_Traceroute_Pretty "210.175.32.26" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "日本-SoftBank"
        BenchAPI_Traceroute_Pretty "106.162.242.108" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "日本-KDDI"
        BenchAPI_Traceroute_Pretty "203.215.236.3" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "日本-中国电信"
        BenchAPI_Traceroute_Pretty "202.55.27.4" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "日本-中国电信CN2"
        BenchAPI_Traceroute_Pretty "13.112.63.251" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "日本-AWS"
        BenchAPI_Traceroute_Pretty "210.114.41.101" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "韩国-KT"
        BenchAPI_Traceroute_Pretty "175.122.253.62 " "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "韩国-SK"
        BenchAPI_Traceroute_Pretty "211.174.62.44" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "韩国-LG"
        BenchAPI_Traceroute_Pretty "218.185.246.3" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "韩国-中国电信CN2"
        BenchAPI_Traceroute_Pretty "13.124.63.251" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "韩国-AWS"
        BenchAPI_Traceroute_Pretty "202.133.242.116" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "中国-台湾Chief"
        BenchAPI_Traceroute_Pretty "210.200.69.90" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "中国-台湾APTG"
        BenchAPI_Traceroute_Pretty "203.75.129.162" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "中国-台湾CHT"
        BenchAPI_Traceroute_Pretty "219.87.66.3" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "中国-台湾TFN"
        BenchAPI_Traceroute_Pretty "211.73.144.38" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "中国-台湾FET"
        BenchAPI_Traceroute_Pretty "61.63.0.102" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "中国-台湾KBT"
        BenchAPI_Traceroute_Pretty "103.31.196.203" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "中国-台湾TAIFO"
        BenchAPI_Traceroute_Pretty "218.30.33.17" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "美国-洛杉矶-中国电信"
        BenchAPI_Traceroute_Pretty "66.102.252.100" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "美国-洛杉矶-中国电信CN2"
        BenchAPI_Traceroute_Pretty "63.218.42.81" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "美国-洛杉矶-PCCW"
        BenchAPI_Traceroute_Pretty "66.220.18.42" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "美国-洛杉矶-HE"
        BenchAPI_Traceroute_Pretty "173.205.77.98" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "美国-洛杉矶-GTT"
        BenchAPI_Traceroute_Pretty "12.169.215.33" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "美国-旧金山-ATT"
        BenchAPI_Traceroute_Pretty "66.198.181.100" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "美国-纽约州-TATA"
        BenchAPI_Traceroute_Pretty "218.30.33.17" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "美国-圣何塞-中国电信"
        BenchAPI_Traceroute_Pretty "23.11.26.62" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "美国-圣何塞-NTT"
        BenchAPI_Traceroute_Pretty "72.52.104.74" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "美国-费利蒙-HE"
        BenchAPI_Traceroute_Pretty "205.216.62.38" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "美国-拉斯维加斯-Level3"
        BenchAPI_Traceroute_Pretty "64.125.191.31" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "美国-圣何塞-ZAYO"
        BenchAPI_Traceroute_Pretty "149.127.109.166" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "美国-阿什本-Cogentco"
        BenchAPI_Traceroute_Pretty "80.146.191.1" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "德国-Telekom"
        BenchAPI_Traceroute_Pretty "82.113.108.25" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "德国-法兰克福-O2"
        BenchAPI_Traceroute_Pretty "139.7.146.11" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "德国-法兰克福-Vodafone"
        BenchAPI_Traceroute_Pretty "118.85.205.101" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "德国-法兰克福-中国电信"
        BenchAPI_Traceroute_Pretty "5.10.138.33" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "德国-法兰克福-中国电信CN2"
        BenchAPI_Traceroute_Pretty "213.200.65.70" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "德国-法兰克福-GTT"
        BenchAPI_Traceroute_Pretty "212.20.150.5" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "德国-法兰克福-Cogentco"
        BenchAPI_Traceroute_Pretty "194.62.232.211" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "英国-Vodafone"
        BenchAPI_Traceroute_Pretty "213.121.43.24" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "英国-BT"
        BenchAPI_Traceroute_Pretty "80.231.131.34" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "英国-伦敦-TATA"
        BenchAPI_Traceroute_Pretty "118.85.205.181" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "俄罗斯-中国电信"
        BenchAPI_Traceroute_Pretty "185.75.173.17" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "俄罗斯-中国电信CN2"
        BenchAPI_Traceroute_Pretty "87.226.162.77" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "俄罗斯-莫斯科RT"
        BenchAPI_Traceroute_Pretty "217.150.32.2" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "俄罗斯-莫斯科TTK"
        BenchAPI_Traceroute_Pretty "195.34.32.71" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "俄罗斯-莫斯科MTS"
    fi
    # IPv6
    if [ "$Result_Networkinfo_NetworkType" = "ipv6" ] || [ "$Result_Networkinfo_NetworkType" = "dualstack" ]; then
        BenchAPI_Traceroute_Pretty "2408:80f0:4100:2005::3" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "China Unicom (Beijing, IPv6)"
        BenchAPI_Traceroute_Pretty "2400:da00:2::29" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "China Telecom (Beijing, IPv6)"
        BenchAPI_Traceroute_Pretty "2409:8089:1020:50ff:1000::fd01" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "China Mobile (Beijing, IPv6)"
        BenchAPI_Traceroute_Pretty "2408:8000:9000:20e6::b7" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "China Unicom (Shanghai, IPv6)"
        BenchAPI_Traceroute_Pretty "240e:18:10:a01::1" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "China Telecom (Shanghai, IPv6)"
        BenchAPI_Traceroute_Pretty "2409:801e:5c03:2000::207" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "China Mobile (Shanghai, IPv6)"
        BenchAPI_Traceroute_Pretty "2408:8001:3011:310::3" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "China Unicom (Guangzhou, IPv6)"
        BenchAPI_Traceroute_Pretty "240e:ff:e02c:1:21::" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "China Telecom (Guangzhou, IPv6)"
        BenchAPI_Traceroute_Pretty "2409:8057:5c00:30::6" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "China Mobile (Guangzhou, IPv6)"
        BenchAPI_Traceroute_Pretty "2001:da8:a0:1001::1" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "China CERNET2 (Beijing, IPv6)"
        BenchAPI_Traceroute_Pretty "2400:dd00:0:37::213" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "China CSTNET (Beijing, IPv6)"
        BenchAPI_Traceroute_Pretty "2001:7fa:0:1::ca28:a1a9" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "中国-香港HKIX-IPv6"
        BenchAPI_Traceroute_Pretty "2001:470:0:490::2" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "中国-香港HE-IPv6"
        BenchAPI_Traceroute_Pretty "2001:470:1:ff::1" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "美国-圣何塞-HE-IPv6"
        BenchAPI_Traceroute_Pretty "2001:418:0:5000::1026" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "美国-芝加哥-NTT-IPv6"
        BenchAPI_Traceroute_Pretty "2001:2000:3080:1e96::2" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "美国-洛杉矶-Telia-IPv6"
        BenchAPI_Traceroute_Pretty "2001:668:0:3:ffff:0:d8dd:9d5a" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "美国-洛杉矶-GTT-IPv6"
        BenchAPI_Traceroute_Pretty "2600:0:1:1239:144:228:241:71" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "美国-堪萨斯-Sprint-IPv6"
        BenchAPI_Traceroute_Pretty "2600:80a:2::15" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "美国-洛杉矶-Verizon-IPv6"
        BenchAPI_Traceroute_Pretty "2001:550:0:1000::9a36:4215" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "美国-阿什本-Cogentco-IPv6"
        BenchAPI_Traceroute_Pretty "2001:1900:2100::2eb5" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "美国-圣何塞-Level3-IPv6"
        BenchAPI_Traceroute_Pretty "2001:438:ffff::407d:d6a" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "美国-西雅图-Zayo-IPv6"
        BenchAPI_Traceroute_Pretty "2001:470:0:349::1" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "法国-巴黎-HE-IPv6"
        BenchAPI_Traceroute_Pretty "2001:728:0:5000::6f6" "${GlobalVar_TracerouteMode}" "${GlobalVar_TracerouteMaxHop}" "德国-法兰克福-NTT-IPv6"
    fi
}
# ===========================================================================
# -> 结果输出
function BenchFunc_GenerateReport_GetResult() {
    BenchAPI_GenerateReport_Systeminfo
    BenchAPI_GenerateReport_Networkinfo
    BenchAPI_GenerateReport_StreamingServiceUnlockTest
    BenchAPI_GenerateReport_PerformanceTest_CPU
    BenchAPI_GenerateReport_PerformanceTest_Disk
}
# -> 结果输出
function BenchAPI_GenerateReport_Systeminfo() {
    mkdir -p "${GlobalVar_BaseDir}/tmp/result" >/dev/null 2>&1
    local v_resfile && v_resfile="${GlobalVar_BaseDir}/tmp/result/systeminfo.restmp"
    echo -e "\n -> System Information\n" >"$v_resfile"
    echo -e " CPU Model Name:\t\t${Result_Systeminfo_CPUModelName}" >>"$v_resfile"
    echo -e " CPU Cache Size:\t\tL1: ${Result_Systeminfo_CPUCacheSizeL1} / L2: ${Result_Systeminfo_CPUCacheSizeL2} / L3: ${Result_Systeminfo_CPUCacheSizeL3}" >>"$v_resfile"
    if [ "$Result_Systeminfo_isPhysical" = "1" ]; then
        echo -e " CPU Specifications:\t\t${Result_Systeminfo_CPUSockets} Physical CPUs, ${Result_Systeminfo_CPUCores} Total Cores, ${Result_Systeminfo_CPUThreads} Total Threads" >>"$v_resfile"
        if [ "${Result_Systeminfo_VirtReady}" = "1" ]; then
            if [ "${Result_Systeminfo_IOMMU}" = "1" ]; then
                echo -e " Virtualization Ready:\t\tYes (Based on ${Result_Systeminfo_CPUVMX}, IOMMU Enabled)" >>"$v_resfile"
            else
                echo -e " Virtualization Ready:\t\tYes (Based on ${Result_Systeminfo_CPUVMX})" >>"$v_resfile"
            fi
        else
            echo -e " CPU Specifications:\t\t${Result_Systeminfo_CPUSockets} Physical CPUs, ${Result_Systeminfo_CPUCores} Total Cores, ${Result_Systeminfo_CPUThreads} Total Threads" >>"$v_resfile"
            echo -e " Virtualization Ready:\t\tNo" >>"$v_resfile"
        fi
    elif [ "$Result_Systeminfo_isPhysical" = "0" ]; then
        echo -e " CPU Specifications:\t\t${Result_Systeminfo_CPUThreads} vCPU" >>"$v_resfile"
        if [ "${Result_Systeminfo_VirtReady}" = "1" ]; then
            if [ "${Result_Systeminfo_IOMMU}" = "1" ]; then
                echo -e " Virtualization Ready:\t\tYes (Based on ${Result_Systeminfo_CPUVMX}, Nested Virtualization Enabled, IOMMU Enabled)" >>"$v_resfile"
            else
                echo -e " Virtualization Ready:\t\tYes (Based on ${Result_Systeminfo_CPUVMX}, Nested Virtualization Enabled)" >>"$v_resfile"
            fi
        else
            echo -e " Virtualization Ready:\t\tNo" >>"$v_resfile"
        fi
    fi
    {
        echo -e " Virtualization Type:\t\t${Result_Systeminfo_VMMType}"
        echo -e " Memory Usage:\t\t\t${Result_Systeminfo_Memoryinfo}"
        echo -e " Swap Usage:\t\t\t${Result_Systeminfo_Swapinfo}"
        echo -e " Disk Usage:\t\t\t${Result_Systeminfo_Diskinfo}"
        echo -e " Boot Disk:\t\t\t${Result_Systeminfo_DiskRootPath}"
        echo -e " OS Release:\t\t\t${Result_Systeminfo_OSReleaseNameFull}"
        echo -e " Kernel Version:\t\t${Result_Systeminfo_LinuxKernelVersion}"
    } >>"$v_resfile"
    return 0
}
# -> 结果输出
function BenchAPI_GenerateReport_Networkinfo() {
    mkdir -p "${GlobalVar_BaseDir}/tmp/result" >/dev/null 2>&1
    local v_resfile && v_resfile="${GlobalVar_BaseDir}/tmp/result/networkinfo.restmp"
    echo -e "\n -> Network Information\n" >"$v_resfile"
    if [ "$Result_Networkinfo_NetworkType" = "ipv4" ] || [ "$Result_Networkinfo_NetworkType" = "dualstack" ]; then
        {
            echo -e " IPv4-IP Address:\t\t[$Result_Networkinfo_CountryCode4] $Result_Networkinfo_IP4"
            echo -e " IPv4-AS Information:\t\t$Result_Networkinfo_NetworkOwner4"
            echo -e " IPv4-GeoIP Location:\t\t$Result_Networkinfo_GeoLocation4"
        } >>"$v_resfile"
    fi
    if [ "$Result_Networkinfo_NetworkType" = "ipv6" ] || [ "$Result_Networkinfo_NetworkType" = "dualstack" ]; then
        {
            echo -e " IPv6-IP Address:\t\t[$Result_Networkinfo_CountryCode6] $Result_Networkinfo_IP6"
            echo -e " IPv6-AS Information:\t\t$Result_Networkinfo_NetworkOwner6"
            echo -e " IPv6-GeoIP Location:\t\t$Result_Networkinfo_GeoLocation6"
        } >>"$v_resfile"
    fi
    if [ "$Result_Networkinfo_NetworkType" = "unknown" ]; then
        echo -e " No network information detected" >>"$v_resfile"
    fi
}
# -> 结果输出
function BenchAPI_GenerateReport_StreamingServiceUnlockTest() {
    mkdir -p "${GlobalVar_BaseDir}/tmp/result" >/dev/null 2>&1
    local v_resfile && v_resfile="${GlobalVar_BaseDir}/tmp/result/streamunlocktest.restmp"
    echo -e "\n -> Streaming Service Unlock Test" >"$v_resfile"
    {
        echo -e "" >>"$v_resfile"
        echo -e " Netflix:\t\t\t$Result_StreamingServiceUnlockTest_Netflix"
        echo -e " HBO Now:\t\t\t$Result_StreamingServiceUnlockTest_HBONow"
        echo -e " Youtube Premium:\t\t$Result_StreamingServiceUnlockTest_YoutubePremium"
        echo -e " Tiktok Region:\t\t\t$Result_StreamingServiceUnlockTest_TiktokRegion"
        echo -e " BBC iPlayer:\t\t\t$Result_StreamingServiceUnlockTest_BBCiPlayer"
        echo -e " NicoNico:\t\t\t$Result_StreamingServiceUnlockTest_NicoVideo"
        echo -e " Princonne Re:dive Japan:\t$Result_StreamingServiceUnlockTest_PriconneRediveJP"
        echo -e " Pretty Derby Japan:\t\t$Result_StreamingServiceUnlockTest_UmamusumeJP"
        echo -e " Kantai Collection Japan:\t$Result_StreamingServiceUnlockTest_KancolleJP"
        echo -e " Bahamut Anime:\t\t\t$Result_StreamingServiceUnlockTest_BahamutAnime"
        echo -e " Bilibili (China Mainland):\t$Result_StreamingServiceUnlockTest_BilibiliChinaMainland"
        echo -e " Bilibili (China SAR&Taiwan):\t$Result_StreamingServiceUnlockTest_BilibiliChinaSARTaiwan"
        echo -e " Bilibili (China Taiwan):\t$Result_StreamingServiceUnlockTest_BilibiliChinaTaiwan"
        echo -e " Steam Price Currency:\t\t$Result_StreamingServiceUnlockTest_SteamPriceCurrency"
    } >>"$v_resfile"
}
# -> 结果输出
function BenchAPI_GenerateReport_PerformanceTest_CPU() {
    mkdir -p "${GlobalVar_BaseDir}/tmp/result" >/dev/null 2>&1
    local v_resfile && v_resfile="${GlobalVar_BaseDir}/tmp/result/performance_cpu.restmp"
    echo -e "\n $Result_PerformanceTest_CPU_BenchTitle\n" >"$v_resfile"
    {
        [[ "$Result_PerformanceTest_CPU_SingleCore" != "" ]] && echo -e "$Result_PerformanceTest_CPU_SingleCore"
        [[ "$Result_PerformanceTest_CPU_MultiCore" != "" ]] && echo -e "$Result_PerformanceTest_CPU_MultiCore"
        [[ "$Result_PerformanceTest_CPU_MultiCoreHT" != "" ]] && echo -e "$Result_PerformanceTest_CPU_MultiCoreHT"
    } >>"$v_resfile"
}
# -> 结果输出
function BenchAPI_GenerateReport_PerformanceTest_Disk() {
    mkdir -p "${GlobalVar_BaseDir}/tmp/result" >/dev/null 2>&1
    local v_resfile && v_resfile="${GlobalVar_BaseDir}/tmp/result/performance_disk.restmp"
    echo -e "\n -> Disk Performance Test (Using FIO, Direct mode, 32 IO-Depth)\n" >"$v_resfile"
    {
        echo -e "$Result_PerformanceTest_Disk_4KRandWrite"
        echo -e "$Result_PerformanceTest_Disk_4KRandRead"
        echo -e "$Result_PerformanceTest_Disk_128KRandWrite"
        echo -e "$Result_PerformanceTest_Disk_128KRandRead"
    } >>"$v_resfile"
}
# -> 结果输出
function BenchFunc_GenerateReport_GenerateReport() {
    mkdir -p "${GlobalVar_BaseDir}/tmp/result" >/dev/null 2>&1
    local v_resfile && v_resfile="${GlobalVar_BaseDir}/tmp/result/report.txt"
    {
        echo -e " LemonBench v3.0 Linux Benchmark & Evaluation Utility Codename \"Stardust\". (C) iLemonrain, All Rights Reserved."
        cat "${GlobalVar_BaseDir}"/tmp/result/systeminfo.restmp
        cat "${GlobalVar_BaseDir}"/tmp/result/networkinfo.restmp
        cat "${GlobalVar_BaseDir}"/tmp/result/streamunlocktest.restmp
        cat "${GlobalVar_BaseDir}"/tmp/result/performance_cpu.restmp
        cat "${GlobalVar_BaseDir}"/tmp/result/performance_disk.restmp
        cat "${GlobalVar_BaseDir}"/tmp/result/speedtest.restmp
        cat "${GlobalVar_BaseDir}"/tmp/result/traceroute.restmp
        echo -e "\nGenerated by LemonBench v3 on $(date -u "+%Y-%m-%dT%H:%M:%SZ") Version $GlobalVar_LemonBench_Version\n"
    } >"${v_resfile}"
    Result_GenerateReport_TimestampFinish="$(date +%s)"
    cat "${GlobalVar_BaseDir}"/tmp/result/report.txt >"$HOME"/LemonBenchReport-"$Result_GenerateReport_TimestampFinish".txt
    true
}
# -> 上传报告
function BenchAPI_GenerateReport_UploadReport() {
    local res && res="$(curl -fsL -X POST \
        --url https://paste.wmlabs.net/ \
        --data-urlencode "content@${PASTEBIN_CONTENT:-/dev/stdin}" \
        --data "title=${PASTEBIN_TITLE:-LemonBench v3 测试报告}" \
        --data "author=${PASTEBIN_AUTHOR:-LemonBench v3/$GlobalVar_LemonBench_Version}" \
        --data "ttl=${PASTEBIN_TTL:--1}")"
    if [ "$?" = "0" ]; then
        local report_id && report_id="$(echo "$res" | jq -r .data.id)"
        echo -e "${Msg_Success}测试报告上传成功, 请保存以下信息:"
        echo -e "${Msg_Info}LemonBench 测试报告URL: https://paste.wmlabs.net/p/$report_id"
    else
        echo -e "${Msg_Warning}测试报告上传失败, 但测试报告已安全保存到本机, 请保存以下信息:"
        echo -e "${Msg_Info}LemonBench 测试报告保存位置: $HOME/LemonBenchReport-$Result_GenerateReport_TimestampFinish.txt"
    fi
}
# -> 上传报告
function BenchFunc_GenerateReport_UploadReport() {
    if [ "$GlobalVar_UploadReport" = "0" ]; then
        echo -e "${Msg_Warning}根据参数设置, 已禁用报告自动上传, 测试报告将仅保存到本机, 请保存以下信息:"
        echo -e "${Msg_Info}LemonBench 测试报告保存位置: $HOME/LemonBench-Result-$$Result_GenerateReport_TimestampFinish.txt"
        return 0
    else
        cat "${GlobalVar_BaseDir}/tmp/result/report.txt" | BenchAPI_GenerateReport_UploadReport
    fi
    return 0
}
#
# ===========================================================================
# -> 依赖处理 (Executor) -> 依赖组件扫描
function BenchAPI_DepProcess_DepScan() {
    # 检测运行必要依赖
    # 使用系统组件: curl sysbench
    # 使用LemonBench组件: jq fio speedtest nexttrace/worsttrace
    if curl -V >/dev/null 2>&1; then
        Flag_DepProcess_DepScan_CurlExist="1"
    else
        Flag_DepProcess_DepScan_CurlExist="0"
    fi
    if "${GlobalVar_BaseDir}"/bin/jq -V >/dev/null 2>&1; then
        Flag_DepProcess_DepScan_JsonQueryExist="1"
    else
        Flag_DepProcess_DepScan_JsonQueryExist="0"
    fi
    if sysbench --version >/dev/null 2>&1; then
        Flag_DepProcess_DepScan_SysbenchExist="1"
    else
        Flag_DepProcess_DepScan_SysbenchExist="0"
    fi
    if "${GlobalVar_BaseDir}"/bin/fio -v >/dev/null 2>&1; then
        Flag_DepProcess_DepScan_FIOExist="1"
    else
        Flag_DepProcess_DepScan_FIOExist="0"
    fi
    if "${GlobalVar_BaseDir}"/bin/speedtest -V >/dev/null 2>&1; then
        Flag_DepProcess_DepScan_SpeedtestExist="1"
    else
        Flag_DepProcess_DepScan_SpeedtestExist="0"
    fi
    if [ "$GlobalVar_TracerouteBinary" = "nexttrace" ]; then
        if "${GlobalVar_BaseDir}"/bin/nexttrace -h >/dev/null 2>&1; then
            Flag_DepProcess_DepScan_TracerouteExist="1"
        else
            Flag_DepProcess_DepScan_TracerouteExist="0"
        fi
    elif [ "$GlobalVar_TracerouteBinary" = "worsttrace" ]; then
        if "${GlobalVar_BaseDir}"/bin/worsttrace -h >/dev/null 2>&1; then
            Flag_DepProcess_DepScan_TracerouteExist="1"
        else
            Flag_DepProcess_DepScan_TracerouteExist="0"
        fi
    else
        exit 1
    fi
    if [ "$Flag_DepProcess_DepScan_CurlExist" = "1" ] && [ "$Flag_DepProcess_DepScan_JsonQueryExist" = "1" ] && [ "$Flag_DepProcess_DepScan_SysbenchExist" = "1" ] && [ "$Flag_DepProcess_DepScan_FIOExist" = "1" ] && [ "$Flag_DepProcess_DepScan_SpeedtestExist" = "1" ] && [ "$Flag_DepProcess_DepScan_TracerouteExist" = "1" ]; then
        Flag_DepProcess_DepScan_AllDepExist="1"
    else
        Flag_DepProcess_DepScan_AllDepExist="0"
    fi
}
# -> 依赖处理 (Collector) -> 依赖组件扫描
function BenchFunc_DepProcess_DepScan() {
    echo -e "${Msg_Time} Scanning for Runtime Dependency ..."
    BenchAPI_DepProcess_DepScan
    if [ "$Flag_DepProcess_DepScan_AllDepExist" = "1" ]; then
        echo -e "${Msg_Time} Runtime Dependency status GOOD"
        return 0
    else
        echo -e "${Msg_Time} Installing Runtime Dependency ..."
        BenchFunc_DepProcess_DepInst
    fi
}
# -> 依赖处理 (Executor) -> 依赖安装 (PkgMgrCache)
function BenchAPI_DepProcess_DepInst_PkgMgrCache() {
    BenchAPI_Systeminfo_GetOSReleaseinfo
    if [ "$Result_Systeminfo_OSReleaseNameShort" = "centos" ]; then
        case $Result_Systeminfo_OSReleaseVersionShort in
        9 | 8)
            dnf makecache
            return 0
            ;;
        7 | 6)
            yum makecache fast
            return 0
            ;;
        *)
            yum makecache fast
            return 0
            ;;
        esac
    elif [ "$Result_Systeminfo_OSReleaseNameShort" = "debian" ] || [ "$Result_Systeminfo_OSReleaseNameShort" = "ubuntu" ]; then
        apt-get update
        return 0
    else
        return 1
    fi
}
# -> 依赖处理 (Executor) -> 依赖安装 (Curl)
function BenchAPI_DepProcess_DepInst_Curl() {
    if [ "$Result_Systeminfo_OSReleaseNameShort" = "centos" ]; then
        case $Result_Systeminfo_OSReleaseVersionShort in
        9 | 8)
            dnf install curl -y
            return 0
            ;;
        7 | 6)
            yum install curl -y
            return 0
            ;;
        *)
            yum install curl -y
            return 0
            ;;
        esac
    elif [ "$Result_Systeminfo_OSReleaseNameShort" = "debian" ] || [ "$Result_Systeminfo_OSReleaseNameShort" = "ubuntu" ]; then
        apt-get install --no-install-recommends -y curl ca-certificates
        return 0
    else
        return 1
    fi
}
# -> 依赖处理 (Executor) -> 依赖安装 (JsonQuery)
function BenchAPI_DepProcess_DepInst_JsonQuery() {
    [[ "${Flag_DepProcess_DepScan_CurlExist}" != "1" ]] && BenchAPI_DepProcess_DepInst_Curl
    curl -o /tmp/jq.tar.gz https://raw.githubusercontent.com/LemonBench/LemonBench/main/requirements/jq/jq-1.6-"$(arch)".tar.gz
    pushd /tmp/ >/dev/null 2>&1 || return 1
    tar xf /tmp/jq.tar.gz
    chmod +x /tmp/jq
    mkdir -p "${GlobalVar_BaseDir}"/bin >/dev/null 2>&1
    mv /tmp/jq "${GlobalVar_BaseDir}"/bin/jq >/dev/null 2>&1
    rm -f /tmp/jq.tar.gz
    popd >/dev/null 2>&1 || return 1
    return 0
}
# -> 依赖处理 (Executor) -> 依赖安装 (Sysbench)
function BenchAPI_DepProcess_DepInst_Sysbench() {
    if [ "$Result_Systeminfo_OSReleaseNameShort" = "centos" ]; then
        case $Result_Systeminfo_OSReleaseVersionShort in
        9 | 8)
            dnf install epel-release -y
            dnf install sysbench -y
            return 0
            ;;
        7 | 6)
            yum install epel-release -y
            yum install sysbench -y
            return 0
            ;;
        *)
            yum install epel-release -y
            yum install sysbench -y
            return 0
            ;;
        esac
    elif [ "$Result_Systeminfo_OSReleaseNameShort" = "debian" ] || [ "$Result_Systeminfo_OSReleaseNameShort" = "ubuntu" ]; then
        apt-get install --no-install-recommends -y sysbench
        return 0
    else
        return 1
    fi
}
# -> 依赖处理 (Executor) -> 依赖安装 (FIO)
function BenchAPI_DepProcess_DepInst_FIO() {
    [[ "${Flag_DepProcess_DepScan_CurlExist}" != "1" ]] && BenchAPI_DepProcess_DepInst_Curl
    curl -o /tmp/fio.tar.gz https://raw.githubusercontent.com/LemonBench/LemonBench/main/requirements/fio/fio-3.34-"$(arch)".tar.gz
    pushd /tmp/ >/dev/null 2>&1 || return 1
    tar xf /tmp/fio.tar.gz
    chmod +x /tmp/fio
    mkdir -p "${GlobalVar_BaseDir}"/bin >/dev/null 2>&1
    mv /tmp/fio "${GlobalVar_BaseDir}"/bin/fio >/dev/null 2>&1
    rm -f /tmp/fio.tar.gz
    popd >/dev/null 2>&1 || return 1
    return 0
}
# -> 依赖处理 (Executor) -> 依赖安装 (Speedtest)
function BenchAPI_DepProcess_DepInst_Speedtest() {
    [[ "${Flag_DepProcess_DepScan_CurlExist}" != "1" ]] && BenchAPI_DepProcess_DepInst_Curl
    curl -o /tmp/speedtest.tar.gz https://raindrop.ilemonrain.com/LemonBench-v3/include/speedtest/speedtest-1.2.0-"$(arch)".tar.gz
    pushd /tmp/ >/dev/null 2>&1 || return 1
    tar xf /tmp/speedtest.tar.gz
    chmod +x /tmp/speedtest
    mkdir -p "${GlobalVar_BaseDir}"/bin >/dev/null 2>&1
    mv /tmp/speedtest "${GlobalVar_BaseDir}"/bin/speedtest >/dev/null 2>&1
    rm -f /tmp/speedtest.tar.gz
    popd >/dev/null 2>&1 || return 1
    return 0
}
# -> 依赖处理 (Executor) -> 依赖安装 (Traceroute)
function BenchAPI_DepProcess_DepInst_Traceroute() {
    if [ "$GlobalVar_TracerouteBinary" = "nexttrace" ]; then
        BenchAPI_DepProcess_DepInst_NextTrace
        return 0
    elif [ "$GlobalVar_TracerouteBinary" = "worsttrace" ]; then
        BenchAPI_DepProcess_DepInst_WorstTrace
        return 0
    else
        return 1
    fi
}
# -> 依赖处理 (Executor) -> 依赖安装 (NextTrace)
function BenchAPI_DepProcess_DepInst_NextTrace() {
    [[ "${Flag_DepProcess_DepScan_CurlExist}" != "1" ]] && BenchAPI_DepProcess_DepInst_Curl
    curl -o /tmp/nexttrace.tar.gz https://raw.githubusercontent.com/LemonBench/LemonBench/main/requirements/nexttrace/nexttrace-1.2.0-"$(arch)".tar.gz
    pushd /tmp/ >/dev/null 2>&1 || return 1
    tar xf /tmp/nexttrace.tar.gz
    chmod +x /tmp/nexttrace
    mkdir -p "${GlobalVar_BaseDir}"/bin >/dev/null 2>&1
    mv /tmp/nexttrace "${GlobalVar_BaseDir}"/bin/nexttrace >/dev/null 2>&1
    rm -f /tmp/nexttrace.tar.gz
    popd >/dev/null 2>&1 || return 1
    return 0
}
# -> 依赖处理 (Executor) -> 依赖安装 (WorstTrace)
function BenchAPI_DepProcess_DepInst_WorstTrace() {
    [[ "${Flag_DepProcess_DepScan_CurlExist}" != "1" ]] && BenchAPI_DepProcess_DepInst_Curl
    curl -o /tmp/worsttrace.tar.gz https://raw.githubusercontent.com/LemonBench/LemonBench/main/requirements/worsttrace/worsttrace-2.0.7-"$(arch)".tar.gz
    pushd /tmp/ >/dev/null 2>&1 || return 1
    tar xf /tmp/worsttrace.tar.gz
    chmod +x /tmp/worsttrace
    mkdir -p "${GlobalVar_BaseDir}"/bin >/dev/null 2>&1
    mv /tmp/worsttrace "${GlobalVar_BaseDir}"/bin/worsttrace >/dev/null 2>&1
    rm -f /tmp/worsttrace.tar.gz
    popd >/dev/null 2>&1 || return 1
    return 0
}
# -> 依赖处理 (Collector) -> 依赖安装
function BenchFunc_DepProcess_DepInst() {
    mkdir -p "${GlobalVar_BaseDir}"/bin >/dev/null 2>&1
    BenchAPI_DepProcess_DepInst_PkgMgrCache
    case $GlobalVar_BenchPreset in
    fast | full)
        [[ "$Flag_DepProcess_DepScan_CurlExist" = "0" ]] && BenchAPI_DepProcess_DepInst_Curl
        [[ "$Flag_DepProcess_DepScan_JsonQueryExist" = "0" ]] && BenchAPI_DepProcess_DepInst_JsonQuery
        [[ "$Flag_DepProcess_DepScan_SysbenchExist" = "0" ]] && BenchAPI_DepProcess_DepInst_Sysbench
        [[ "$Flag_DepProcess_DepScan_FIOExist" = "0" ]] && BenchAPI_DepProcess_DepInst_FIO
        [[ "$Flag_DepProcess_DepScan_SpeedtestExist" = "0" ]] && BenchAPI_DepProcess_DepInst_Speedtest
        [[ "$Flag_DepProcess_DepScan_TracerouteExist" = "0" ]] && BenchAPI_DepProcess_DepInst_Traceroute
        # 二次扫描, 如果所有检测结果不为1, 则认为依赖处理失败, 直接退出运行
        BenchAPI_DepProcess_DepScan
        if [ "$Flag_DepProcess_DepScan_AllDepExist" = "1" ]; then
            return 0
        else
            echo "BenchFunc_DepProcess_DepInst(): Dep Failed"
            exit 1
        fi
        ;;
    *)
        exit 1
        ;;
    esac
}
# ===== 功能: 显示测试Header ======
function GlobalFunc_ShowBenchHeader() {
    echo -e "${Msg_Time} "
    echo -e "${Msg_Time}    __                       ___               __  "
    echo -e "${Msg_Time}   / /  ___ __ _  ___  ___  / _ )___ ___  ____/ /  "
    echo -e "${Msg_Time}  / /__/ -_)  ' \/ _ \/ _ \/ _  / -_) _ \/ __/ _ \ "
    echo -e "${Msg_Time} /____/\__/_/_/_/\___/_//_/____/\__/_//_/\__/_//_/ "
    echo -e "${Msg_Time} "
    echo -e "${Msg_Time} LemonBench - A simple Linux Platform Benchmark & Evaluation Utility."
    echo -e "${Msg_Time} (C)iLemonrain. All Rights Reserved. Distribute under MIT License."
    echo -e "${Msg_Time} "
}
# ===== 功能: 显示帮助文档 =====
function GlobalFunc_ShowHelpDocument() {
    echo -e "LemonBench - Linux 服务器性能基准测试工具包"
    echo -e ""
    echo -e "用法: LemonBench.sh [选项]..."
    echo -e ""
    echo -e "预置测试方案："
    echo -e "  -f,  --fast                      使用预置 <快速模式> 启动测试"
    echo -e "  -F,  --full                      使用预置 <完整模式> 启动测试"
    echo -e ""
    echo -e "全局参数:"
    echo -e "       --no-upload                 在测试结束后禁止上传报告"
    echo -e ""
    echo -e "测试参数："
    echo -e "       --disk-engine               配置 磁盘性能测试 使用引擎 (fio|dd)"
    echo -e "       --trace-mode                设置 路由追踪测试 数据包类型 (icmp|tcp)"
    echo -e "       --trace-hop                 设置 路由追踪测试 最大跳数 (10-99)"
    echo -e ""
    echo -e "请将问题报告和讨论内容电子邮件发送至 <ilemonrain@ilemonrain.com>"
    echo -e "和/或在 https://github.com/LemonBench/LemonBench 开 issue 进行讨论。"
}
#
# ===== 预置: LemonBench 测试预置方案 =====
#
# -> 预置: 快速模式 (Fast)
#    测试速度与精确度的平衡点 (~8min)，适用于常规测试，快速了解待测服务器性能指标
function StartBench_Preset_Fast() {
    rm -rf "${GlobalVar_BaseDir}"/tmp
    GlobalFunc_ShowBenchHeader
    #RunBench_StartBenchPre
    BenchFunc_DepProcess_DepScan
    #RunBench_StartBenchPost
    BenchFunc_Systeminfo_GetSysteminfo
    BenchFunc_Systeminfo_ShowSysteminfo
    BenchFunc_Networkinfo_GetNetworkinfo
    BenchFunc_Networkinfo_ShowNetworkinfo
    BenchFunc_StreamingServiceUnlockTest_RunTest
    BenchFunc_PerformanceTest_CPU_RunTest_Fast
    BenchFunc_PerformanceTest_Disk_RunTest
    BenchFunc_Speedtest_Fast_Pretty
    BenchFunc_Traceroute_Fast_Pretty
    BenchFunc_GenerateReport_GetResult
    BenchFunc_GenerateReport_GenerateReport
    BenchFunc_GenerateReport_UploadReport
}
# -> 预置: 完整模式 (Full)
#    通过耐久测试/多次采样测试，获取更高的结果，但更慢的速度 (~30min)，适用于获取更高精度的测试结果
function StartBench_Preset_Full() {
    rm -rf "${GlobalVar_BaseDir}"/tmp
    GlobalFunc_ShowBenchHeader
    #RunBench_StartBenchPre
    BenchFunc_DepProcess_DepScan
    #RunBench_StartBenchPost
    BenchFunc_Systeminfo_GetSysteminfo
    BenchFunc_Systeminfo_ShowSysteminfo
    BenchFunc_Networkinfo_GetNetworkinfo
    BenchFunc_Networkinfo_ShowNetworkinfo
    BenchFunc_StreamingServiceUnlockTest_RunTest
    BenchFunc_PerformanceTest_CPU_RunTest_Full
    BenchFunc_PerformanceTest_Disk_RunTest
    BenchFunc_Speedtest_Full_Pretty
    BenchFunc_Traceroute_Full_Pretty
    BenchFunc_GenerateReport_GetResult
    BenchFunc_GenerateReport_GenerateReport
    BenchFunc_GenerateReport_UploadReport
}
#
# ===== 全局程序主入口 =====
#
export PATH=${GlobalVar_BaseDir}/bin:$PATH
LANG=C
if ! ARGS="$(getopt -a -o hfF --long fast,full,no-upload,trace-mode:,trace-hop:,help -- "$@")"; then
    echo "error"
    exit 1
fi
eval set -- "${ARGS}"
while :; do
    [ -z "$1" ] && break
    case $1 in
    -h | --help)
        GlobalFunc_ShowHelpDocument
        exit 1
        ;;
    -f | --fast | fast)
        GlobalVar_BenchPreset="fast"
        shift
        ;;
    -F | --full | full)
        GlobalVar_BenchPreset="full"
        shift
        ;;
    --no-upload)
        GlobalVar_UploadReport="0"
        shift
        ;;
    --trace-mode)
        if [ "$2" = "icmp" ] || [ "$2" = "ICMP" ]; then
            GlobalVar_TracerouteMode="icmp"
        elif [ "$2" = "tcp" ] || [ "$2" = "TCP" ]; then
            GlobalVar_TracerouteMode="tcp"
        else
            echo -e "${Msg_Error} --trace-mode 参数错误, 请输入正确的参数值 (icmp|tcp)"
            exit 1
        fi
        shift 2
        ;;
    --trace-hop)
        TestVar="$(echo "$2" | grep -oE "\b[0-9]{1,2}\b")"
        if [ "${TestVar}" != "" ]; then
            GlobalVar_TracerouteMaxHop="$2"
        else
            echo -e "${Msg_Error} --trace-hop 参数错误, 请输入正确的参数值 (10~99)"
            exit 1
        fi
        shift 2
        ;;
    --)
        shift
        ;;
    *)
        GlobalFunc_ShowHelpDocument
        exit 1
        ;;
    esac
done
if [ "${GlobalVar_BenchPreset}" = "fast" ]; then
    StartBench_Preset_Fast
elif [ "${GlobalVar_BenchPreset}" = "full" ]; then
    StartBench_Preset_Full
else
    GlobalFunc_ShowHelpDocument
    exit 1
fi
