from scipy.integrate import odeint  
from pylab import * 
from numpy import * 
  
from matplotlib import rcParams
rcParams.update({'font.size': 18,'font.weight':'bold'})


nstime=[]
nswindow=[[],[],[],[],[],[],[],[],[],[]]
nsalpha= [[],[],[],[],[],[],[],[],[],[]]
nsqueue=[]





N=2     #flow number

qmax= 10000
DMAX=115

K =20

## dctcp mark process
def ECN(x):
	global K
	if x >= K:
		return 1
	else:
		return 0



interval1=5000
interval2=15000

S =0.0
E =2.0




interval = interval1+interval2
ts = linspace(S,E,interval+1)
dt = ts[1]-ts[0]  


queue    = [0]
window   = [[2],[2],[0],[0],[0],[0],[0],[0],[0],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1],[1]]
alpha    = [[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0],[0]]
start	 =[0,0]
deadline=[300,500,60,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0] 	 # deadline in ms
c = 1*1024.0*1024.0*1024/1460/8       										 # link capacity in packets/s,1G
pd = 0.0001                           										 # propogation delay is 100u
g=0.25
T=600 # in ms



def now(t):
	return (E-S)/interval*t





def penalty(during,j):
	if deadline[j]!=0:
		return (deadline[j]+0.0)/(T+0.0)
	else:
		if(during>T):
			return 1;
		else:
			return (during+0.0)/(T+0.0)






# Flow start
for i in range(interval):
	rtt = pd+queue[i]/c
	temp = 0
	for j in range(N):
		w = window[j][i]
		a = alpha[j][i]
		al  = g/rtt*(ECN(queue[i])-a)*dt+a  # window
		if(al < 0):
			al = 0
		if(al > 1):
			al = 1
		alpha[j].append(al)
		temp += w/rtt
		if(w == 0):
			win = 0
		else:
			part1 = (1-penalty(now(i)-start[j],j)/2.0)/(rtt+0.0)*dt
			if part1 < 0.2:
				part1=0.2
			if part1 > 1:
				part1 = 1
			part2 = (w*a*penalty(now(i)-start[j],j)/2.0/(0.0+rtt)*ECN(queue[i]))*dt
			win=w+part1-part2
			#print part1,part2,win
			#win = ((/rtt-*ECN(queue[i])/rtt)*dt+w  #window
		if(win<0):
			win=0
		#print win
		else:
			window[j].append(win)
	q = (temp-c)*dt+queue[i]   #queue
	if(q>qmax):
		q = qmax;
	if(q<0):
		q=0
	queue.append(q)
# window[1][interval1]=1;
#print window[0]


#print window[0]


# #flow 2 start 
# for i in range(interval1,interval):
# 	rtt = pd+queue[i]/c
# 	temp = 0
# 	for j in range(N):
# 		w = window[j][i]
# 		a = alpha[j][i]
# 		al  = g/rtt*(ECN(queue[i])-a)*dt+a
# 		if(al<0):
# 			al=0
# 		if(al>1):
# 			al=1
# 		alpha[j].append(al)
# 		temp+=w/rtt
# 		if(w==0):
# 			win=0
# 		else:
# 			win = ((1-penalty(now(i)-start[j])/2)/rtt-w*a*penalty(now(i)-start[j])*ECN(queue[i])/2/rtt)*dt+w
# 		if(win<0):
# 			win=0
# 		window[j].append(win)
# 	q = (temp-c)*dt+queue[i]
# 	if(q>qmax):
# 		q = qmax;
# 	if(q<0):
# 		q=0
# 	queue.append(q)


# nstime=[]
# nswindow=[[],[],[],[],[],[],[],[],[],[]]
# nsalpha= [[],[],[],[],[],[],[],[],[],[]]
# nsqueue=[]

# fp = open("2","r")

# totalline= fp.readlines()
# for line in totalline:
# 	array=line.split()
# 	nstime.append(array[0])
# 	nswindow[0].append(array[3])
# 	nswindow[1].append(array[4])
# 	nsalpha[0].append(float(array[5]))
# 	nsalpha[1].append(float(array[6]))
# 	nsqueue.append(array[7])

# win1=[]
# win2=[]
# t=[]
# length=len(window[0])
# for i in length:
# 	t[i]


fp = open("queue","r")
totalline= fp.readlines()
for line in totalline:
	array=line.split()
	nstime.append(array[0])
	nswindow[0].append(array[3])
	nswindow[1].append(array[4])
	nsalpha[0].append(float(array[5]))
	nsalpha[1].append(float(array[6]))
	nsqueue.append(array[7])



step = 10
i = 0
datalength = len(window[1])
plotts=[]
plotwin1=[]
plotwin2=[]
plotalpha1=[]
plotalpha2=[]
plotqueue=[]
while i < datalength:
	plotts.append(ts[i])
	plotwin1.append(window[0][i])
	plotwin2.append(window[1][i])
	plotalpha1.append(alpha[0][i])
	plotalpha2.append(alpha[1][i])
	plotqueue.append(queue[i])
	i+= step

plt.figure(1) # create fig1 congestion window

plot(plotts,plotwin1,'r',label='fluid-flow1',linewidth=3)
plot(plotts,plotwin2,'b',label='fluid-flow2',linewidth=3)
# #plot(ts,window[2],'k',label='fluid-flow3',linewidth=3)
plot(nstime,nswindow[0],'deeppink',label='ns-flow1',linewidth=3)
plot(nstime,nswindow[1],'deepskyblue',label='ns-flow2',linewidth=3)
# #plot(nstime,nswindow[2],'c',label='ns-flow3',linewidth=3)

xlim(0.0,0.3)
ylim(0,60)

xlabel('time')
ylabel('window(pkts)')

legend()
savefig("window.eps");

plt.figure(2) # create fig  2m alpha
plot(plotts,plotalpha1,'r',label='fluid-flow1',linewidth=3)
plot(plotts,plotalpha2,'b',label='fluid-flow2',linewidth=3)
# #plot(ts,alpha[2],'k',label='fluid-flow3',linewidth=3)
plot(nstime,nsalpha[0],'deeppink',label='ns-flow1',linewidth=3)
plot(nstime,nsalpha[1],'deepskyblue',label='ns-flow2',linewidth=3)
# #plot(nstime,nsalpha[2],'c',label='ns-flow3',linewidth=3)
legend()

xlim(0.0,0.3)
ylim(0,1)

xlabel('time')
ylabel('alpha')


savefig("alpha.eps");

plt.figure(3) # create fig3 queue length

plot(plotts,plotqueue,'b',label='fluid-queue',linewidth=3)
plot(nstime,nsqueue,'r',label='ns-queue',linewidth=3)

xlim(0.0,0.3)
ylim(0,60)

xlabel('time')
ylabel('queue(pkts)')
legend()

savefig("queue.eps");


# #print queue









show();