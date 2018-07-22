import numpy as np
import matplotlib.pyplot as plt
import sys
from pylab import * 

from matplotlib import rcParams

linecolor=['#FF3333','#C433FF','#3633FF','#33FF42','#FFA533','#000000']

tracename=sys.argv[1]
file = open(tracename)
missdeadline =0
totaldeadline=0
totalflows=0
totalflowcompletionTime=0
for line in file:
	totalflows+=1
	line=line.strip()
	lineinfo=line.split()
	# Get flow duration and deadline in ms 
	flowdur = float(lineinfo[12])*1000.0
	deadline=float(lineinfo[18])/1000.0
	# analysis the percentage of missing deadline
	if deadline >0:
		totaldeadline+=1
	if deadline <= flowdur and deadline > 0:
		missdeadline+=1
	if deadline >= flowdur and deadline >0:
		totalflowcompletionTime+=flowdur
	if deadline==0:
		totalflowcompletionTime+=flowdur
	#print totalflowcompletionTime

print (missdeadline+0.0)/(0.0+totaldeadline)*100,(totalflowcompletionTime+0.0)/(totalflows-missdeadline+0.0)
