# Optimization

## Sysstat

### Iostat

```
./dummy.sh
iostat -yz 1 4
```
### Pidstat

```
./stress.py
pidstat -p $(pidof stress.py) -u 1 2
```

### Sar

```
sar -b
sar -P 0
sar -n DEV 
```

## Co-Pilot

Install: `yum install pcp pcp-gui pcp-system-tools`
Enable: `systemctl enable --now pmcd`

### Cli

```
pcp free
pcp dstat
pcp dstat --time --cpu --proc 2 8
pmstat -s 5
pminfo
pminfo | grep proc
pminfo -dt proc.nprocs
pmval -s 5 proc.nprocs
pminfo | grep free
pminfo -dt mem.freemem
pmval -t 15 -s 5 mem.freemem
```

### Gui

#### Local

```
# pmchart
    File > New Chart > proc.nprocs
```

#### Remote

Open port `44321/tcp`:
```
pmchart -h remote
```

#### Replay

```
pmlogger /var/log/pcp/pmlogger/host.mydomaine.xyz
pmdumplog -L -Z CET+1 /var/log/pcp/pmlogger/host.mydomaine.xyz/20250125.16.11.0
pmval -a /var/log/pcp/pmlogger/host.mydomaine.xyz/somedate kernel.all.load
pmval -a /var/log/pcp/pmlogger/host.mydomaine.xyz/somedate kernel.all.load -S '@ Day Mon dd hh:mm:ss yyyy' -T '@ Day Mon dd hh:mm:ss yyyy'
```

#### Docs

Install `pcp-doc`

___

## Profiling

### Kernel

```
dmesg -T
dmesg | head -n2 # kernel version + boot options
dmesg | grep 'DMA' # Direct Memory Access - 32bit systems
dmesg | grep 'Memory'
dmesg | grep 'CPU'
dmesg | grep 'Huge'
dmesg | grep 'io scheduler'
dmesg | grep 'sda'
dmesg | sed '/Call Trace/,'
```

### CPU

```
lscpu
lscpu -p
getconf -a
```

### BIOS

```
dmidecode
ls /sys/class/dmi/id/
```

### PCI

```
lspci
lspci -vv
```

### USB

```
lsusb
lsusb -vv
```

### Hwloc

Install: `hwloc`
```
lstopo-no-graphics
```

### Hardware

Install: `rasdaemon`
```
lshw -short
lshw -C system
systemctl enable --now rasdaemon
ras-mc-ctl --help
ras-mc-ctl --summary
ras-mc-ctl --errors
```

### Qemu

#### Resources

```
virsh dumpxm myvm | grep q35
virsh dumpxm myvm | grep "cpu mode"
lspci | grep balloon
virsh list --all
virsh start myvm
lscpu | grep -i '^cpu'
virsh vcpuinfo myvm
top -H -u qemu -o %CPU
```

#### Events

```
kvm_stat
perf kvm stat -- sleep 10
myvm$ cat /proc/modules > /tmp/modules
myvm$ cat /proc/kallsyms > /tmp/kallsyms
perf kvm --guest --guestmodules=guest-modules --guestkallsyms=guest-kallsyms record -a
perf kvm --guest --guestmodules=guest-modules --guestkallsyms=guest-kallsyms report --force > myvm-analyze.txt
perf kvm --host --guestmodules=guest-modules --guestkallsyms=guest-kallsyms report --force > myhost-analyze.txt
```

## Tunables

### Kernel

```
/proc/cpuinfo
/proc/meminfo
/proc/swaps
/proc/PID
/proc/cmdline
```

```
/proc/sys/dev
/proc/sys/fs
/proc/sys/kernel
/proc/sys/ne
/proc/sys/vm
```

```
ls -l /proc/sys/kernel/{osrelease,threads-max}
cat /proc/sys/kernel/osrelease
cat /proc/sys/kernel/threads-max
```

```
ping -c1 localhost
echo '1' > /proc/sys/net/ipv4/icmp_echo_ignore_all
ping -c1 localhost
```

```
sysctl -a
sysctl -n vm.swappiness
sysctl -w vm.swappiness=10
```

Doc: 
```
yum install kernel-doc
ls /usr/share/doc/kernel-doc-*/Documentation/sysctl/*.txt`
```

```
vim /etc/sysctl.d/swappiness.conf
sysctl -p /etc/sysctl.d/swappiness.conf
```

```
modinfo loop
modinfo -p loop # options
vim /etc/modprobe.d/my_options_loop.conf
    options loop max_loop=5
modprobe loop
modprobe loop max_loop=5
```

### Tuned

Config':
- `/usr/lib/tuned/`
- `/etc/tuned/`

Example:
```
[sysctl]
net.ipv4.icmp_echo_ignore_all=1
[disk]
devices=vdb
readahead=4096 sectors
[script]
script=${i:PROFILE_DIR}/script.sh
```

Script in same directory:
```
#!/bin/sh
. /usr/lib/tuned/functions

start(){
}

stop(){
}

process $@
```

Check:
```
tuned-adm verify
blockdev --getra /dev/vdb
blockdev --setra 512 /dev/vdb # kilobytes
```

Ref: [Monitoring and managing system status and performance](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/8/html-single/monitoring_and_managing_system_status_and_performance/index)

## Cgroups

### Limits

#### Ulimits

Man pages: 
- `limit.conf`
- `ulimit`

```
@managers hard maxlogins 3
operator hard as 131072
operator hard nproc 1024
```

#### Services

Man pages:
- `systemd.exec`
- `systemd.resource-control`

### Customize

Drop-in systemd config': `/etc/systemd/system/mysrv.service.d/10-cpulimits.conf`
```
[Service]
LimitCPU=30 # seconds
LimitNOFILE=32
```

In cli:
```
systemctl set-property mysrv MemoryAccounting=true
systemctl set-property mysrv MemoryLimit=1G # GibiBytes
cat /etc/systemd/system.control/mysrv.service.d/*
systemctl show -p MemoryAccounting mysrv
systemctl show -p MemoryLimit mysrv
```

Systemwise: `/etc/systemd/system.conf`

### Slices

In `myslice.slice`
```
[Unit]
Description=Example Custom Slice

[Slice]
CPUAccounting=yes
CPUShare=2048
CPUQuota=50%
MemoryAccounting=true
```
or `system-a-b-c-d.slice` file

## Tracing

### Perf

Install: `yum install perf kernel-debuginfo`
```
uname -r
perf list
perf stat dd if=/dev/zero of=/dev/null bs=2048 count=10000000
perf stat -e cycles,instructions,cache-references,cache-misses,bus-cycles -a sleep 10
perf record -e cpu-clock,instructions,cache-misses,context-switches dd if=/dev/zero of=/dev/null bs=2048 count=10000000
perf report --stdio
perf record -o cs-syswide.data -e context-switches -a sleep 10
perf report -i cs-syswide.data --stdio
perf archive # remote host
```

Man pages:
- `perf_event_open(2)`
- `perf`, `perf list`, `perf stat`, `perf report`, `perf record`

### Strace

```
strace ls
strace -p PID
strace -c ls
strace -fc elinks google.com
strace -e open -c uname
```

### SystemTap

Install: `yum install systemtap`
```
stat-prep
yum install kernel-debuginfo kernel-devel kernel-debug-devel
```

Root usage:
```
stap -e 'probe begin { printf("Hello World!\n"); exit()}'
stap -v /usr/share/systemtap/examples/process/syscalls_by_proc.stp
```

Stapusr usage:
```
stap -v -p 4 -m my_syscalls_by_proc /usr/share/systemtap/examples/process/syscalls_by_proc.stp
mkdir /lib/modules/$(uname -r)/systemtap
cp ./my_syscall_by_proc.ko /lib/modules/$(uname -r)/systemtap
usermod -aG stapuser myuser
su - myuser
staprun my_syscalls_by_proc
```

Stapdev usage:
```
usermod -aG stapdev myuser
su - myuser
stap -v /usr/share/systemtap/examples/process/syscalls_by_proc.stp
```

Remote execution:
```
yum install systemtap-runtime
scp root@compile-srv:mymod.ko /lib/modules/$(uname -r)/systemtap/
staprun mymod.ko
```

Docs:
- `/usr/share/systemtap/examples/index.html`
- `/usr/share/docs/systemtap-client`

### eBPF

Install: `yum install bcc-tools`
List of tools: `ls /usr/share/bcc/tools/`
Docs: `ls /usr/share/bcc/tools/doc`
Man pages: `man bcc-*`
```
/usr/share/bcc/tools/execsnoop
/usr/share/bcc/tools/opensnoop # iostat -dxy 1 1
/usr/share/bcc/tools/xfsslower
/usr/share/bcc/tools/biolatency
/usr/share/bcc/tools/biosnoop
/usr/share/bcc/tools/cachestat -T
/usr/share/bcc/tools/cache-misses
/usr/share/bcc/tools/gethostlatency
```

## CPU utilisation

### Policies

#### Priorities

```
ps -eo pid,pri,rtprio,ni,cls,comm # static priority, real-time priority, nice value, scheduling policy (TS=Time-Sharing, FF=FIFO)
ps -eo pid,pri,rtprio,ni,cls,comm,cputime PID1 PID2
grep voluntary /proc/PID/status
ps -o pid,cls,rtprio,comm $(pidof httpd)
```

#### Classes

Classes:
| Class | Policy |
| :---  | ---:   |
| Real-Time Scheduler | SCHED_FIFO SCHED_RR |
| Completely Fair Scheduler (CFS) | SCHED_NORMAL (or SCHED_OTHER) SCHED_BATCH SCHED_IDLE |
| Deadline Scheduler | SCHED_DEADLINE |

#### Scheduling

##### Tunables

Sysctl:
- `sched_latency_ns`
- `sched_min_granularity_ns`
- `sched_migration_cost_ns`
- `sched_rt_period_us`
- `sched_rt_runtime_us`
- `sched_rr_timeslice_us`

Doc: `/usr/share/doc/kernel-doc-*/Documentation/scheduler/` (package `kernel-doc`)

##### Deadline

```
chrt -d --sched-runtime 5000000 --sched-deadline 10000000 --sched-period 16666666 0 mybin
ps -o cls # DLN=SCHED_DEADLINE
chrt -p PID # check priority and scheduler
chrt -f 38 mybin # FIFO
chrt -p PID
chrt -o -p PID # SCHED_NORMAL
```

##### Tuna

Install: `yum install tuna`
```
tuna --show_threads
tuna --threads 10 --show_threads
tuna --threads 10 --priority=RR:99 # system priority = 139
```

##### Systemd

```
[Service]
Nice=-20 # ..., 19
CPUSchedulingPolicy=rr # other, batch, idle, fifo, rr
CPUSchedulingPriority=99 # Real-time priority v.s. System priority
```

#### Check

```
cat /proc/sched_debug
cat /proc/schedstat # /usr/share/doc/kernel-doc-*/Documentation/scheduler/sched-stats.txt
cat /proc/PID/sched
```

### Affinity and isolation

#### Cgroups

```
ls /sys/fs/cgroup/cpuset
pgrep syslog
cat /proc/PID/cpuset
cat /sys/fs/cgroup/cpuset/cpuset.cpus
cat /sys/fs/cgroup/cpuset/cpuset.mems
```

In `/usr/local/bin/my_cpuset`:
```
#!/bin/bash
mkdir -p /sys/fs/cgroup/cpuset/my_cpuset
echo 2 > /sys/fs/cgroup/cpuset/my_cpuset/cpuset.cpus
echo 0 > /sys/fs/cgroup/cpuset/my_cpuset/cpuset.mems
for PID in $(pgrep httpd); do
        echo ${PID} > /sys/fs/cgroup/cpuset/my_cpuset/tasks
done
```
then in `/etc/systemd/system/httpd.service.d/cpuset.conf`:
```
[Service]
ExecStartPost=/usr/local/bin/my_cpuset
```

#### Interrupts

```
printf '%032x' $((2**0+2**2+2**7)) > /proc/irq/INT/smp_affinity
vim /proc/irq/INT/smp_affinity_list
vim /etc/sysconfig/irqbalance
    IRQBALANCE_ONESHOT=no
    IRQBALANCE_BANNED_CPUS=000000fe
```

#### Partitioning

In `/etc/tuned/cpu-partitioning-variables.conf`:
```
isolated_cores=1-3,5-8
no_balance_cores=4,9
```

### Cache

```
lstopo --no-legend --no-io
lscpu
lshw -class memory
yum provides '*/valgrind'
valgrind --tool=cachegrind mybin
perf stat -e instructions,cycles,L1-dcache-loads,L1-dcache-load-misses,LLC-load-misses,LLC-loads mybin
```

## Memory

### Architecture

#### Virtual memory

```
cat /proc/cpuinfo # bits virtual
ps -o pid,vsz,rss,comm -C firefox
systemctl set-property sshd.service MemoryLimit=1G
systemctl cat sshd.service
```

#### Page faults

```
ps -o pid,minflt,majflt,comm -C firefox
perf stat -e minor-fault,major-faults firefox
```

#### TLB

```
perf stat -e dTLB-load-misses firefox
```

#### Huge pages

```
cat /proc/meminfo # Hugepagesize: 2048kB
sysctl -w vm.nr_hugepages=20
cat /proc/meminfo # HugePages_Total: 20
```

Numa nodes:
```
echo 20 > /sys/devices/system/node/nodeX/hugepages/hugepages-2048kB/nr_hugepages
numastat -cm
```

#### Transparent Huge pages:

Check:
```
grep AnonHugePages /proc/meminfo
cat /sys/kernel/mm/transparent_hugepage/enabled
```

Disable in `tuned.conf`:
```
[vm]
transparent_hugepages = never
```

Disable at boot time: `transparent_hugepage=never` in the kernel command line
```
grubby --args="transparent_hugepage=never" --update-kernel ALL
systemctl reboot
```

Docs:
- /usr/share/doc/kernel-doc-*/Documentation/admin-guide/mm/hugetlbpage.rst
- /usr/share/doc/kernel-doc-*/Documentation/admin-guide/mm/transhuge.rst 

### Paging

#### Dirty pages

```
vmstat --unit M 5
grep -i active /proc/meminfo # Free, Active, Inactive clean, Inactive dirty
```

Script:
```
cat /proc/$$/smaps | awk '
/Shared_Clean/ {SHCL+=$2}
END {
    print "Shared clean:", SHCL
}'
```

Tunables:
```
vm.dirty_expire_centisecs
vm.dirty_writeback_centisecs
vm.dirty_background_ratio
vm.dirty_ratio
```

Example: `/usr/lib/tuned/oracle/tuned.conf`

#### OOM killer

Sysctl: `/proc/PID/oom_score_adj`

Systemd:
```
mkdir /etc/systemd/system/sssd.service.d
vim /etc/systemd/system/sssd.service.d/10-OOMscore.conf
    [Service]
    OOMScoreAdjust=-1000
```

Doc: `/usr/share/doc/kernel-doc-*/Documentation/sysctl/vm.txt

### NUMA

#### Monitoring

```
numactl --hardware
yum install hwloc-gui
lstopo
yum install numactl
numastat -cm
numastat -c rsyslogd
```

#### Association

```
numactl --cpunodebind=2 --preferred=2 -- mybin
numactl --cpunodebind=2 --membind=2,3 -- mybin
numactl --interleave all -- mybin
```

### Overcommit

Tunable: `vm.overcommit_memory`

Doc: `/usr/share/doc/kernel-doc-*/Documentation/sysctl/vm.txt`

## Storage I/O

### Algorithms

#### Schedulers

```
cat /sys/block/vda/queue/scheduler # mq-deadline, kyber, bfq, none
ls /sys/block/vda/queue/iosched
```

#### Tuned

```
[sysfs]
/sys/block/vda/queue/iosched/fifo_batch=1
```

#### Workloads

```
yum install fio
fio --name=randwrite --ioengine=libaio --iodepth=1 --rw=randwrite --bs=4k --direct=1 --size=512M --numjobs=2 --group_reporting --filename=/tmp/testfile
```

Doc: `/usr/share/doc/fio/HOWTO`

### RAID

```
mdadm -C /dev/md0 -l raid0 -n 2 /dev/vd[b-c]1
mdadm --stop /dev/md0
mdadm --remove /dev/md0
mdadm --zero-superblock /dev/vd[b-c]
```

#### Stripe unit

```
mdadm --detail /dev/md0 | grep 'Chunk Size' # 64K
mkfs -t xfs -d su=64k,sw=2 /dev/san/lun1 # Raid0=2disks
mkfs -t ext4 -E stride=16,stripe-width=64 /dev/san/lun1
lvcreate --type raid0 -L 3G --stripes 3 --stripesize 4 -n raidlv raidvg
```

### Tools

- `top`
- `iostat -x`
- `iotop`
- `pcp atop` (package `pcp-system-tools`, enable `pmcd`)
- `pmiostat`

Examples:
```
pmiostat -R vda
pcp atop -d
```

## FS

### Attributes

#### Trim

```
systemctl enable --now fstrim.timer
```

#### Options

##### XFS

Formating options:
- Inode size: `-i size=512` (default 256)
- Logical block size for directories: `-n`
- RAID alignment: `-d su=512k,sw=2`

##### Ext4

Formating options:
- Inode size: `-I 128` (default 256)
- Extra_isize: `mkfs.ext4 -O ^extra_isize /dev/mydevice`
- Large_dir: `mkfs.ext4 -O large_dir /dev/mydevice`
- Huge_file: `mkfs.ext4 -O ^huge_file /dev/mydevice`
- RAID alignment: `-E stride=128,stripe-width=256 /dev/mydevice`

#### Mount

##### Common

- atime
- realtime
- noatime
- nodiratime

##### XFS

- inode64
- logbsize

##### Ext4

- i_version
- journal_ioprio


#### Benchmark

- dd
- hdparm
- bonnie++

Man pages:
- mkfs.*
- tune2fs
- mount
- xfs, ext4

### Journaling

Placement: `data=mode`
- ordered: only metadata
- writeback: only metadata, ordering not preserved (crash=data loss)
- journal: best reliability

Barriers: `barrier=0,1`

#### External

##### XFS

```
mkfs.xfs -l logdev=/dev/vdd1 /dev/vdc1
mount -o logdev=/dev/vdc1 /mnt
```

##### Ext4

```
mkfs.ext4 -O journal_dev -b 4096 /dev/vdd1
mkfs.ext4 -J device=/dev/vdd1 -b 4096 /dev/vdc1
```

Conversion:
```
tune2fs -l /dev/vdc1 # check block size
mkfs.ext4 -O journal_dev -b 4096 /dev/vdd1
umount /dev/vdc1
tune2fs -O '^has_journal' /dev/vdc1
tune2fs -j -J device=/dev/vdd1 /dev/vdc1
```

Check: `findmnt --target /myjournal`

## Network

### Latency vs throughput

#### Tunables

- TCP buffers (min, pressure, max): `net.ipv4.tcp_mem`
- UDP buffers (min, pressure, max): `net.ipv4.udp_mem`
- Bandwidth Delay Product: `rtt*bandwidth`
- Core Receive socket: `net.core.rmem_max`
- Core Sending socket: `net.core.wmem_max`
- TCP Receive socket (min, default, max): `net.ipv4.tcp_rmem`
- TCP Sending socket (min, default, max): `net.ipv4.tcp_wmem`

#### Jumbo frames

```
nmcli connection modify ens3 802-3-ethernet.mtu 9000
```

### Driver parameter

#### Ethtool

```
ethtool -s ens3 advertise 0x28
ethtool -s ens3 autoneg off speed 1000 duplex full
```

#### Nmcli

```
nmcli connection modify "Wired connection 1" 802-3-ethernet.auto-negotiate off 802-3-ethernet.speed 1000 802-3-ethernet.duplex full
```

#### Qperf

```
host1$ qperf
host2$ qperf host1 tcp_bw udp_bw
```

#### Teaming

Configuration:
```
nmcli connection add type team con-name myteam ifname myiface team.runner loadbalance
nmcli connection modify myteam team.link-watchers "name=ethtool"
nmcli connection modify myteam ipv4.addresses '1.2.3.4/24' ipv4.method manual
nmcli connection add type ethernet slave-type team con-name myteam-port1 ifname ensXpY master myteam
nmcli connection add type ethernet slave-type team con-name myteam-port2 ifname ensXpZ master myteam
```

Activation:
```
nmcli connection up myteam
nmcli dev dis ensXpY
```

Troubleshooting:
```
teamdctl myteam state
teamnl myteam ports
teamnl myteam getoption activeport
teamnl myteam setoption activeport 3
teamdctl myteam state
teamdctl myteam config dump
```

## Virtualization

### Tuning hosts

#### Numa

```
nemastat -c qemu-kvm
virsh numatune
```

#### Virtual CPU

```
virsh vcpupin myvm
virsh vcpupin myvm 0 3
virsh vcpupin myvm 1 7
virsh vcpuinfo myvm
virsh dumpxml myvm | sed -n '/<cputune>/,/<\/cputune>/p'
```

#### Tuning Qemu

```
virsh emulatorpin myvm 1
virsh emulatorpin myvm
virsh dumpxml myvm | sed -n '/<cputune>/,/<\/cputune>/p'
```

#### Limiting memory

```
virsh dominfo myvm
virsh memtune myvm --hard-limit 2G --soft-limit 1G
virsh memtune myvm
virsh dumpxml myvm | sed -n '/<memtune>/,/<\/memtune>/p'
```

#### Huge pages

```
<memoryBacking>
    <hugepages>
        <page size='2', unit='M' nodeset='0-3,5'/>
    </hugepages>
</memoryBacking>
```

#### KSM (Kernel Samepage Merging) Tunables

```
ls /sys/kernel/mm/ksm/*
```
- Memory scan: `run`
- Memory pages to scan in the next cycle: `pages_to_scan`
- Number of milliseconds between cycles: `sleep_millisecs`
- Number of pages shared: `pages_shared`
- Number of pages currently shared: `pages_sharing`
- Number of memory scan: `full_scan`
- Pages on different NUMA nodes: `merge_across_nodes`

With virsh:
```
virsh node-memory-tune --shm-pages-to-scan 100 --shm-sleep-millisecs 10
```

With `ksmtuned.service`, in `/etc/ksmtuned.conf`:
```
KSM_MAX_KERNEL_PAGES=x
```

Disable KSM on the host: `ksm` and `ksmtuned`
Disable KSM on the guest: 
```
<memoryBacking>
    <nosharepages/>
</memoryBacking>
```

#### Tuning block I/O

Preallocation:
- metadata
- falloc
- full
```
qemu-img create -f qcow2 -o preallocation=metadata /var/lib/libvirt/images/disk.qcow2 1G
```

Cache mode:
- none
- writetrhough
- writeback
- directsync
- unsafe
```
<disk type='file' device='disk'>
    <driver name='qemu' type='qcow2' cache='none'/>
    <source file='/var/lib/libvirt/images/disk.qcow2'/>
    <target dev='vdb' bus='virtio'/>
</disk>
```

Threads:
```
virsh iothreadinfo myvm
virsh iothreadadd myvm 2
```
In the dump:
```
<iothreads>2</iothreads>
<iothreadids>
    <iothread id='1'/>
    <iothread id='2'/>
</iothreadids>
<disk type='file' device='disk'>
    <driver name='qemu' type='qcow2' cache='none' io=native/>
    <source file='/var/lib/libvirt/images/bisk.qcow2'/>
    <target dev='vdb' bus='virtio'/>
</disk>
```

Virtual disk I/O:
```
virsh blkdeviotune myvm vdb --total-iops-sec 1000[ --total-bytes-sec 20MB
virsh dumpxml myvm | grep -B4 -A2 iotune
```

#### Limit on guests

```
lscgroup
virsh schedinfo myvm
virsh schedinfo myvm cpu_shares=2048
virsh blkiotune myvm
```

#### Virtual networks

```
modinfo vhost_net
```

### Monitoring

#### Performance metrics

```
virsh domblkstat myvm vda --human
virsh domiflist myvm
virsh domifstat myvm vnet0
virsh dommemstat myvm
```

#### Prometheus

Binary: `node_exporter`
Config':
```
global:
    scrape_interval: 15s
    evaluation_interval: 15s
scrape_configs;
    - job_name: 'demo'
      static_configs:
        - targets:
            - myhost.mydomain.com:9100
          labels:
            name: demo-targets
```
Check: `promtool check config prometheus.yml`
Run: `./prometheus --storage.tsdb.path /var/lib/prometheus/`

#### Grafana

```
systemctl start grafana-server
firefox http://localhost:3000/
```


