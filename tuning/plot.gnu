# 
set xdata time
set timefmt '%H:%M:%S'
set format x '%H:%M:%S'
set xtics rotate by -90
set xlabel 'Time'
set ylabel 'Load average'
plot  \
'./mydata.txt' using 1:2 title '1mn' with lines, \
'./mydata.txt' using 1:3 title '5mn' with lines, \
'./mydata.txt' using 1:4 title '15mn' with lines 

