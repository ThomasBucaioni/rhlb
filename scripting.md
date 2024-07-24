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
```


