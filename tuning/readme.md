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


