<div align="center"><img src="assets/logo.png" style="height: 200px"></div>
<h1 align="center">LemonBench</h1>

<h4 align="center">A simple Linux Benchmark Utility developed using Shell Script.</h4>



## How To Use

Document Language: English (Coming Soon) | 简体中文

### Quick Start
```
wget -qO- https://raw.githubusercontent.com/LemonBench/LemonBench/main/LemonBench.sh | bash -s -- --fast
```
(or)
```
curl -fsL https://raw.githubusercontent.com/LemonBench/LemonBench/main/LemonBench.sh | bash -s -- --fast
```

### Requirements

系统发行版：```CentOS 7/8```, ```Debian 11/12+```, ```Ubuntu 18.04/20.04/22.04+```

处理器架构：```x86_64 (amd64)```, ```aarch64 (arm64)```

需要 **root 权限** 运行 (直接root或者sudo root)

⚠️ 由于LemonBench连续高强度测试的特性，在某些低资源或主机商限制严格的环境下，连续长时间100%占用计算资源/网络资源，可能会被视作滥用(Abuse)。建议在以上环境中谨慎运行LemonBench。

## Get Started

LemonBench 支持以下项目的基准测试：

- **系统信息基准模块**
  - CPU基准信息 (CPU型号、缓存大小、核心数量配置等)
  - 虚拟化信息 (当前系统所使用的虚拟化、VT-x/SVM开启检测、IOMMU开启检测)
  - 内存信息 (内存、交换分区)
  - 磁盘信息 (检测根挂载点所在分区或磁盘)
  - 系统发行版信息 (发行版名称、内核版本)
- **网络信息基准模块**
  - IPv4 网络信息 (IP地址、GeoIP信息，以默认路由网卡为准)
  - IPv6 网络信息 (IP地址、GeoIP信息，以默认路由网卡为准)
- **流媒体解锁测试模块**
  - Netflix
  - HBO Now
  - Youtube Premium
  - Tiktok Region
  - BBC iPlayer
  - NicoNico
  - 公主连结Re:dive (Princonne Re:dive) 日服
  - 赛马娘 (Pretty Derby) 日服
  - 巴哈姆特動畫瘋
  - 哔哩哔哩 (国内限定/港澳台地区限定/中国台湾地区限定)
  - Steam 汇率区
- **CPU基准性能测试模块**
  - 1 线程测试 (快速测试 5秒 1次/完整测试 30秒 3次平均值)
  - 半线程测试 (如4核心8线程，则运行4线程测试)
  - 全线程测试 (所有可用线程)
  - 超线程倍率检测 (以 1线程测试 作为基准)
- **磁盘基准性能测试模块** (基于FIO Direct 32 队列深度)
  - 写入测试 (4K - 模拟数据库操作)
  - 读取测试 (4K - 模拟数据库操作)
  - 写入测试 (128K - 模拟大文件读写)
  - 读取测试 (128K - 模拟大文件读写)
- **网络速率基准测试模块** (基于Ookla Speedtest)
  - 默认节点 (Speedtest 最近节点)
  - 快速模式：国内三大运营商(联通/移动/电信)各 1 个
  - 完整模式：国内三大运营商(联通/移动/电信)各 3 个 + 海外运营商扩展测试
- **路由追踪基准测试** (基于 NextTrace)
  - 快速模式：国内主流运营商 (联通-AS4837/移动-AS9808/电信-AS4134/联通CUII-AS9929/电信CN2-AS4812/鹏博士长宽家用网络/鹏博士长宽商用网络/教育网CERNET1-AS4538/教育网CERNET2-AS4538/科技网CSTNET-AS7497/广电网络-AS7641)
  - 完整模式：国内主流运营商 + 海外运营商扩展测试

## Xpack 增强扩展包 (Coming soon)

针对 LemonBench 运行过程中各平台环境的特异性，可启用Xpack功能包以扩展LemonBench的检测能力。Xpack 增强扩展包可额外检测如下项目：

- 公有云平台虚拟机增强检测
  - 实例信息检测 (实例ID、网卡信息等)
  - 实例类型检测 (如腾讯云 SA2.SMALL)
  - 可用区信息检测
- 物理服务器增强检测
  - 服务器型号检测
  - 服务器BIOS信息检测
  - Dell 服务器 Service Tag 检测
- (未完待续)

## LemonBench 使用说明

LemonBench 作为非专业性能基准工具，测试结果仅供参考。不同的 LemonBench 版本之间性能测试结果不具有可比性。跨处理器架构之间部分测试结果（如CPU性能测试）不具有直接可比性。

在部分VPS主机商提供的虚拟机运行 LemonBench 之前，请直接向官方，或向社群确认是否允许长时间占用计算资源或网络带宽资源（LemonBench快速测试需要占用约5分钟的CPU资源，以及约2分钟的网络带宽资源；完整测试需要占用约15分钟的CPU资源，以及约10分钟的网络带宽资源），避免因长时间占用共享（Fair-Share）资源导致被主机商封禁。

由于部分音视频资源提供方对于网站代码可能会随时变动，流媒体解锁测试部分结果仅供参考。请以实际是否可以直接访问作为最终测试结果。
