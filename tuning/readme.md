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
pminfo -dt proc.nprocs
pmval -s 5 proc.nprocs
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

### Replay

```
pmlogger /var/log/pcp/pmlogger/host.mydomaine.xyz
pmdumplog -L -Z CET+1 /var/log/pcp/pmlogger/host.mydomaine.xyz/20250125.16.11.0
pmval -a /var/log/pcp/pmlogger/host.mydomaine.xyz/somedate kernel.all.load
pmval -a /var/log/pcp/pmlogger/host.mydomaine.xyz/somedate kernel.all.load -S '@ Day Mon dd hh:mm:ss yyyy' -T '@ Day Mon dd hh:mm:ss yyyy'
```


