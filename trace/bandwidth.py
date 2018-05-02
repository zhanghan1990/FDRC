import numpy as np
import matplotlib.pyplot as plt
import sys
from pylab import * 

from matplotlib import rcParams

linecolor=['#FF3333','#C433FF','#3633FF','#33FF42','#FFA533']

tracename=sys.argv[1]
file = open(tracename)
starttime=0
step=0.001
end=starttime+step
flowsize={}
bandwidthset={}
timeset={}
for line in file:
	line=line.strip()
	lineinfo=line.split()
	if lineinfo[0]=='r':
		linetime=float(lineinfo[1])
		fid=lineinfo[7]

		if bandwidthset.has_key(fid)==False:
			bandwidthset[fid]=[]
			timeset[fid]=[]

		if flowsize.has_key(fid):
			flowsize[fid]+=float(lineinfo[5])/1024.0*8/1024.0
		else:
			flowsize[fid]=0

		if end < linetime:
			for fid in flowsize.keys():
				#print linetime,fid,flowsize[fid]/(linetime-starttime)
				bandwidthset[fid].append(flowsize[fid]/(linetime-starttime))
				timeset[fid].append(linetime)
			starttime=end
			end=starttime+step
			flowsize={}

#print timeset,bandwidthset

allkeys=sorted(timeset.keys())

legends=[]
for key in allkeys:
	legends.append("flow "+str(key))
	plt.plot(timeset[key], bandwidthset[key],label=key,lw=2,color=linecolor[int(key)])
plt.ylim(0,1000)
plt.xlim(0,0.6)
plt.xlabel('Time(s)',fontsize=16,fontweight='bold')
plt.ylabel('Bandwidth(Mbps)',fontsize=16,fontweight='bold')
plt.legend(legends, fontsize=16,loc=2)
plt.xticks(fontsize=16,fontweight='bold')
plt.yticks(fontsize=16,fontweight='bold')
plt.show()



file.close()