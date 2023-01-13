#!/bin/bash
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y linux-headers-`uname -r`
sudo apt-get install -y build-essential librdmacm-dev libnuma-dev libmnl-dev meson wget git
git clone https://github.com/omec-project/ngic-rtc-tmo.git ~/
git clone https://github.com/omec-project/il_trafficgen.git ~/
sudo apt-get install -y dpdk
