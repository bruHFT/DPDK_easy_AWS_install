#!/bin/bash

# Set noninteractive mode to suppress prompts
export DEBIAN_FRONTEND=noninteractive

#!/bin/bash

# clone F-Stack
sudo apt update

mkdir -p /data/f-stack
git clone https://github.com/F-Stack/f-stack.git /data/f-stack
git clone https://github.com/renzibei/f-stack.git /data/f-stack

# Install libnuma-dev
yes | sudo apt-get install libnuma-dev  # on Ubuntu
yes | apt-get install git gcc openssl libssl-dev linux-headers-$(uname -r) bc libnuma1 libnuma-dev libpcre3 libpcre3-dev zlib1g-dev python
# Install python3-pip and automatically select default option for restart prompt
echo -e "\n" | sudo -E apt-get -y install python3-pip
yes | pip3 install pyelftools --upgrade
yes | sudo python3 -m pip install meson ninja pyelftools
yes | sudo apt install gcc make libssl-dev net-tools 

# Compile DPDK
cd  /data/f-stack/dpdk/
# re-enable kni now, to remove kni later
meson -Denable_kmods=true -Ddisable_libs=flow_classify build
ninja -C build
ninja -C build install

# Set hugepage (Linux only)
# single-node system
echo 1024 > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages

# Using Hugepage with the DPDK (Linux only)
mkdir /mnt/huge
mount -t hugetlbfs nodev /mnt/huge

# Close ASLR; it is necessary in multiple process (Linux only)
echo 0 > /proc/sys/kernel/randomize_va_space

# Offload NIC
modprobe uio
insmod /data/f-stack/dpdk/build/kernel/linux/igb_uio/igb_uio.ko
insmod /data/f-stack/dpdk/build/kernel/linux/kni/rte_kni.ko carrier=on # carrier=on is necessary, otherwise need to be up `veth0` via `echo 1 > /sys/class/net/veth0/carrier`
python3 usertools/dpdk-devbind.py --status
sudo ip link set ens6 down
python3 usertools/dpdk-devbind.py --bind=igb_uio ens6 # assuming that use 10GE NIC

# Upgrade pkg-config while version < 0.28
cd /data
wget https://pkg-config.freedesktop.org/releases/pkg-config-0.29.2.tar.gz
tar xzvf pkg-config-0.29.2.tar.gz
cd pkg-config-0.29.2
./configure --with-internal-glib
make
sudo make install
sudo mv /usr/bin/pkg-config /usr/bin/pkg-config.bak
sudo ln -s /usr/local/bin/pkg-config /usr/bin/pkg-config

# Compile F-Stack
export FF_PATH=/data/f-stack
export PKG_CONFIG_PATH="/usr/local/lib/x86_64-linux-gnu/pkgconfig:
/usr/lib/x86_64-linux-gnu/pkgconfig:
/usr/lib/pkgconfig"

# Install F-STACK
# libfstack.a will be installed to /usr/local/lib
# ff_*.h will be installed to /usr/local/include
# start.sh will be installed to /usr/local/bin/ff_start
# config.ini will be installed to /etc/f-stack.conf

cd /data/f-stack/lib/
make    # On Linux
make install    # On Linux

cd /data/f-stack/example
make
mv /data/f-stack/config.ini /data/f-stack/example
./helloworld







