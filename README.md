# LemonBench - Linux Server Benchmark Toolkit

English Docs | 简体中文文档



LemonBench is a simple Linux Server Evaluation & Benchmark Toolkit, written in Shell Script.

This simple tool can test linux server/vps performance in about 10 minutes, and gerenate a report, which can share to others.

Currently, LemonBench supports ```i386/i686```, ```x86_64```, ```armel/armhf```, ```arm64/aarch64``` architectures, and support CentOS / Debian / Ubuntu / Fedora / Raspbian OS.

Feel free for PR, and good issues, and please add stars and donate if you feel it is a good tool !



### Current Support Features

- System Information (OS Release Info / CPU Info / Virt Info / Memory Info / Disk Info / Load Info etc.)
- Network Information (IPV4 IP Address, ASN Info, Geo Info / IPV6 IP Address, ASN Info, Geo Info)
- Streaming Unlock Test (HBO Now, Bahamut Anime, Bilibili HongKong/Macau/Taiwan, BiliBili TaiwanOnly)
- CPU Performance Test (Based on Sysbench 1.0.17)
- Memory Performance Test (Based on Sysbench 1.0.17)
- Disk Performance Test (4K Block / 1M Block)
- Speedtest.net Network Speed Test
- Traceroute Test (Server -> Primary ISP)
- Spoof Test (need manually activate)
- Auto-Generate Result and Sharing
