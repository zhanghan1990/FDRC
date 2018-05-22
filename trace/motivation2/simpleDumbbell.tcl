source "tcp-common-opt.tcl"

# Choose methods that schedule the traffic
set sourceAlg [lindex $argv 0]

# Total Number of nodes that send traffic accoding to the distribution of traffic
set N 5

# Percentage of Flows that have deadline
set DeadlinePercentage 0.1

# Background flows (longlive flows)
set BackgroundFlows 1

# D2TCP:Deadline down threshold in us
set deadline_down 30000 

# D2TCP:Deadline up threshold in us
set deadline_up   60000

# wc lower bound, recommended by the paper
Agent/TCP/FullTcp/Sack/LLDCT set LL_WCMIN_ 0.125;

# wc upper bound, recommended by the paper
Agent/TCP/FullTcp/Sack/LLDCT set LL_WCMAX_ 2.5;  

# bytes lower bound, recommended by the paper,in KB
Agent/TCP/FullTcp/Sack/LLDCT set LL_BMIN_ 2  ;

# bytes upper bound, recommended by the paper, in KB
Agent/TCP/FullTcp/Sack/LLDCT set LL_BMAX_ 200 ;



# Total Number of flows that should sent according to the distribution of traffic
set sim_end 5000

# Compute the total number of flows that have deadline
set DeadlineFlowsNumber [expr $sim_end* $DeadlinePercentage]
set DeadlineFlowsPer [expr $sim_end/$DeadlineFlowsNumber]
set DeadlineFlowsPer [expr int($DeadlineFlowsPer)]


# Total number of simulation time
set simulationTime 1000.0

# Traffic load
set load 0.2

# Thtreshold of Switch (number of packets)
set K 20

# g in Server side
set DCTCP_g_ 0.026


# If trace the packest at the bottleneck link: 1 packetleve trace
set TracePacketLevel 0


# Bandwidth between switches (in Gbps)
set lineRate 1


# Bandwidth of servers that connect to net (in Gbps)
set inputLineRate 2



# Connection between nodes
set connections_per_pair 8


# Queue Limit (number of packets)
set B 250


# Flow Log for distribution traffic
set flowlogname $sourceAlg-[expr int($DeadlinePercentage*10)]-flow.tr
set flowlog [open $flowlogname w]

# Set flow arrival rate
set meanFlowSize [expr 1138*1460]
set lambda [expr ($lineRate*$load*1000000000)/($meanFlowSize*8.0/1460*1500)]
puts "Arrival: Poisson with inter-arrival [expr 1/$lambda * 1000] ms"



set RTT 0.0001

set switchAlg RED

set ackRatio 1 
set packetSize 1460



set filename $sourceAlg
append filename "-out.tr"


set trace_file [open  $filename  w]



set ns [new Simulator]

Agent/TCP set ecn_ 1
Agent/TCP set old_ecn_ 1
Agent/TCP set packetSize_ $packetSize
Agent/TCP/FullTcp set segsize_ $packetSize
Agent/TCP set window_ 1256
Agent/TCP set slow_start_restart_ false
Agent/TCP set tcpTick_ 0.01
Agent/TCP set minrto_ 0.2 ; 
Agent/TCP set windowOption_ 0




if {[string compare $sourceAlg "DD-TCP-Sack"] == 0} {
    Agent/TCP set ecnhat_ true
    Agent/TCPSink set ecnhat_ true
    Agent/TCP set ecnhat_g_ $DCTCP_g_;
    set myAgent "Agent/TCP/FullTcp/Sack/DDTCP";
}

if {[string compare $sourceAlg "LL-DCT-Sack"] == 0} {
    Agent/TCP set ecnhat_ true
    Agent/TCPSink set ecnhat_ true
    Agent/TCP set ecnhat_g_ $DCTCP_g_;
    set myAgent "Agent/TCP/FullTcp/Sack/LLDCT";
}


if {[string compare $sourceAlg "DC-TCP-Sack"] == 0} {
    Agent/TCP set ecnhat_ true
    Agent/TCPSink set ecnhat_ true
    Agent/TCP set ecnhat_g_ $DCTCP_g_;
    set myAgent "Agent/TCP/FullTcp/Sack";
}


Agent/TCP/FullTcp set segsperack_ $ackRatio; 
Agent/TCP/FullTcp set spa_thresh_ 3000;
Agent/TCP/FullTcp set interval_ 0.04 ; #delayed ACK interval = 40ms
Agent/TCP set window_ 1000000
Agent/TCP set windowInit_ 2
Agent/TCP set maxcwnd_ 149


Queue set limit_ 1000

Queue/RED set bytes_ false
Queue/RED set queue_in_bytes_ true
Queue/RED set mean_pktsize_ $packetSize
Queue/RED set setbit_ true
Queue/RED set gentle_ false
Queue/RED set q_weight_ 1.0
Queue/RED set mark_p_ 1.0
Queue/RED set thresh_ [expr $K]
Queue/RED set maxthresh_ [expr $K]
			 
DelayLink set avoidReordering_ true


proc finish {} {
    global ns
    $ns flush-trace
	exit 0
}


for {set i 0} {$i < $N} {incr i} {
    set n($i) [$ns node]
}

set nswitch1 [$ns node]
set nswitch2 [$ns node]
set nclient1 [$ns node]
set nclient2 [$ns node]


for {set i 0} {$i < $N} {incr i} {
    $ns duplex-link $n($i) $nswitch1 [set inputLineRate]Gb [expr $RTT/6] DropTail
}




$ns simplex-link $nswitch1 $nswitch2 [set lineRate]Gb [expr $RTT/6] $switchAlg
$ns simplex-link $nswitch2 $nswitch1 [set lineRate]Gb [expr $RTT/6] DropTail

$ns queue-limit $nswitch1 $nswitch2 $B

$ns duplex-link $nswitch2 $nclient1 [set inputLineRate]Gb [expr $RTT/6] DropTail
$ns duplex-link $nswitch2 $nclient2 [set inputLineRate]Gb [expr $RTT/6] DropTail






# Config for the distribution flows

set flow_gen 0
set flow_fin 0
set init_fid 0
set tbf 0


for {set i 0} {$i < $N } {incr i} {
    set agtagr($i,0) [new Agent_Aggr_pair]

    $agtagr($i,0) setup $n($i) $nclient2 [array get tbf] 0 "$i 0" $connections_per_pair $init_fid "TCP_pair" $deadline_down $deadline_up
    $agtagr($i,0) attach-logfile $flowlog
    
    puts -nonewline "($i,0) "
        
    $agtagr($i,0) set_PCarrival_process  [expr $lambda/($N - 1)] "CDF_search.tcl" [expr 17*$i] [expr 33*$i]
    $ns at 0.01 "$agtagr($i,0) warmup 0.5 5"
    $ns at 0.1 "$agtagr($i,0) init_schedule"
    set init_fid [expr $init_fid + $connections_per_pair];
}





# Config for background flows (longlived flows)
for {set i 0} {$i < $BackgroundFlows} {incr i} {
    set BackgroundNodes($i) [$ns node]
}


for {set i 0} {$i < $BackgroundFlows} {incr i} {
    $ns duplex-link $BackgroundNodes($i) $nswitch1 [set inputLineRate]Gb [expr $RTT/6] DropTail
}



set nclient3 [$ns node]
$ns duplex-link $nswitch2 $nclient3 [set inputLineRate]Gb [expr $RTT/6] DropTail



for {set i 0} {$i < $BackgroundFlows} {incr i} {
  set tcps($i) [new $myAgent]  ;
  set tcpr($i) [new $myAgent]  ;
  $tcps($i) set fid_ [expr $i+1000000]
  $tcpr($i) set fid_ [expr $i+1000000]
  $ns attach-agent $BackgroundNodes($i) $tcps($i);
  $ns attach-agent $nclient3 $tcpr($i);
  $tcpr($i) listen
  $ns connect $tcps($i) $tcpr($i)
}




for {set i 0} {$i < $BackgroundFlows} {incr i} {
    set ftp($i) [new Application/FTP]
    $ftp($i) attach-agent $tcps($i)
    $ftp($i) set type_ FTP
}





for {set i 0} {$i < $BackgroundFlows} {incr i} {
    $ns at 0.0 "$ftp($i) start"
}




if { $TracePacketLevel == 1} {
    $ns  trace-queue  $nswitch1 $nswitch2  $trace_file
} 

                      
$ns at $simulationTime "finish"

$ns run
