# Scripting

## Sed

Multi-line:
-`n` copies the next line to the pattern space
-`N` appends to the pattern space the next line, separates it by a new line character
-`P` prints up to the newline character
-`D` deletes everything up to and including an embedded newline in the pattern space
-`h` copies pattern space to hold space
-`H` appends pattern space to hold space
-`g` copies hold space to pattern space
-`G` appends hold space to pattern space
-`x` exchanges contents of pattern and hold spaces

```
sed 'N; s/pattern1\([[:space:]]\)pattern2/replace1\1replace2/g;l' somefile.txt
sed '/^$/{N; /pattern1/D; /pattern2/D}' somefile.txt
sed -n 'N; /pattern1\npattern2/P' somefile.txt
sed -n '/somepattern/{h;n;p;g;p}' somefile.txt # switch line after somepattern with line having somepattern
sed -n '{1!G;h;$p;}' somefile.txt # reverse somefile.txt
sed '$!N; s/pattern1\([[:space:]]\)pattern2/replace1\1replace2/g;P;D' somefile.txt
```

## Awk

Variables:
- `FS`
- `FIELDWIDTHS`
- `RS`
- `OFS`
- `ORS`

```
awk 'BEGIN{FS=":"; FIELDWIDTHS="8 12 13 10"} {print $1,$2,$3}' /etc/passwd
awk 'BEGIN{FS="\n"; RS=""} {print $1,$4}' contacts.txt
awk 'BEGIN{myarray["key1"]="value1"; myarray["key2"]="value2"; print myarray["key1"]} END{for (key in myarray){print key, myarray[key]}; delete myarray["key1"]; print myarray}'
awk '$2 ~ /somepattern/{print}' somefile.txt ; awk '$2 !~ /somepattern/{print}' somefile.txt
awk '{if ($1>$2) print $1,$2}' somefile.txt
awk '{if ($1>$2) {var=$1*$2; print var} else {print $1,$2}}' somefile.txt
awk '{i=10; while(i<=10){ print $0; print i; i++ ; if (i==5) break; else continue}}' somefile.txt
awk '{i=0; do{i++; print i} while(i<=10)}' somefile.txt
awk '{for(i=0;i<=5;i++) print i}' somefile.txt
```

Format specifiers:
- `s` string text
- `i` integers
- `d` integers
- `c` characters
- `e` scientific
- `f` floating-point
- `o` octal
- `x` hex
- `X` hex with capital A-F

```
awk 'BEGIN{FS=":"} {printf "%-10s %s\n", $1, $3}' /etc/passwd
awk 'function myfunc(){print "someprint"}BEGIN{FS=":"} {myfunc()}' /etc/passwd
echo a | awk 'BEGIN{for(n=0;n<256;n++)ord[sprintf("%c",n)]=n}{print ord[$1]}'
echo 97 | awk 'BEGIN{for(n=0;n<256;n++)chr[n]=sprintf("%c",n)}{print chr[$1]}'
awk 'BEGIN{printf "%c", 65}'
```

