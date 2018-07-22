# encoding: utf-8
import numpy as np
import matplotlib.pyplot as plt
import sys
from scipy import stats

from matplotlib import rcParams
rcParams.update({'font.size': 10,'font.weight':'bold'})

patterns = ('/','//','-', '+', 'x', '\\', '\\\\', '*', 'o', 'O', '.')

##first read from file
pFabric="pFabric"
Varys="Varys"
Barrat="Barrat"
Yosemite="Yosemite"
Fair="FAIR"

DARK='DARK'



if __name__=='__main__':

	rcParams.update({'font.size': 16,'font.weight':'bold'})
	N=8
	ind = np.arange(N)  # the x locations for the groups
	width = 0.3       # the width of the bars

	D2TCP=[11.36,11.72,12.6 ,13.5545781687,18.76,19.16,26.64,36.6]
	L2DCT=[13.36,14.2,18.2,20.8716513395,24.08,31.6,36.72,39.5841663335]
	DAFD=[13.4,15.8,17.68,21.08,24.32,31.24,33.6,41.96,52.4]

	fig1=plt.figure()
	ax1=fig1.add_subplot(111)
	ax1.set_ylim([0,45])
	ax1.set_xlim([5,85])
	ax1.set_ylabel('Flows Missing Deadline(%)',weight='bold')
	ax1.set_xlabel('Load(%)',weight='bold')
	line1,=ax1.plot([10,20,30,40,50,60,70,80], L2DCT,linewidth = '2',marker='s',color='#00FF00',markersize=15,markeredgecolor='k')
	line2,=ax1.plot([10,20,30,40,50,60,70,80], D2TCP,linewidth = '2',marker='o',color='red',markersize=15,markeredgecolor='k')
	ax1.legend((line2,line1),(r'D$^2$TCP',r'L$^2$DCT'),loc='best',fontsize='x-large')
	fig1.savefig('motivation1_deadline.eps')


	D2TCP=[14.8181298282,17.7577385233,24.6505189102,27.0375218146,47.3378757081,93.4754359745,96.7515255214,186.406999486]
	L2DCT=[13.837414143,16.0677895496,19.2899139473,25.6645718768,33.4326357129,53.8950129213,87.317373976,139.560413906]

	fig2=plt.figure()
	ax1=fig2.add_subplot(111)
	ax1.set_ylim([0,200])
	ax1.set_xlim([5,85])
	ax1.set_ylabel('Average Flow Completion Time (ms)',weight='bold')
	ax1.set_xlabel('Load(%)',weight='bold')
	line1,=ax1.plot([10,20,30,40,50,60,70,80], L2DCT,linewidth = '2',marker='s',color='#00FF00',markersize=15,markeredgecolor='k')
	line2,=ax1.plot([10,20,30,40,50,60,70,80], D2TCP,linewidth = '2',marker='o',color='red',markersize=15,markeredgecolor='k')
	ax1.legend((line2,line1),(r'D$^2$TCP',r'L$^2$DCT'),loc='best',fontsize='x-large')
	fig2.savefig('motivation1_fct.eps')

