set N 6
set B 250
set K 20
set RTT 0.0001

set simulationTime 1.0

set startMeasurementTime 1
set stopMeasurementTime 2
set flowClassifyTime 0.1

set sourceAlg [lindex $argv 0]
set switchAlg RED
set lineRate 1Gb
set inputLineRate 2Gb

set DCTCP_g_ 0.026
set ackRatio 1 
set packetSize 1460
 
set traceSamplingInterval 0.0001
set throughputSamplingInterval 0.1
set enableNAM 0

set filename $sourceAlg
append filename "-out.tr"
puts $filename

set trace_file [open  $filename  w]


set ns [new Simulator]

Agent/TCP set ecn_ 1
Agent/TCP set old_ecn_ 1
Agent/TCP set packetSize_ $packetSize
Agent/TCP/FullTcp set segsize_ $packetSize
Agent/TCP set window_ 1256
Agent/TCP set slow_start_restart_ false
Agent/TCP set tcpTick_ 0.01
Agent/TCP set minrto_ 0.2 ; # minRTO = 200ms
Agent/TCP set windowOption_ 0


Agent/TCP/FullTcp/Sack/LLDCT set LL_WCMIN_ 0.125; #wc lower bound, recommended by the paper
Agent/TCP/FullTcp/Sack/LLDCT set LL_WCMAX_ 2.5;   #wc upper bound, recommended by the paper

Agent/TCP/FullTcp/Sack/LLDCT set LL_BMIN_ 10000  ;#bytes lower bound, recommended by the paper,in KB
Agent/TCP/FullTcp/Sack/LLDCT set LL_BMAX_ 20000 ;#bytes upper bound, recommended by the paper, in KB




if {[string compare $sourceAlg "DD-TCP-Sack"] == 0} {
    Agent/TCP set ecnhat_ true
    Agent/TCPSink set ecnhat_ true
    Agent/TCP set ecnhat_g_ $DCTCP_g_;
    #Agent/TCP/FullTcp set deadline 100
    set myAgent "Agent/TCP/FullTcp/Sack/DDTCP";
}

if {[string compare $sourceAlg "LL-DCT-Sack"] == 0} {
    Agent/TCP set ecnhat_ true
    Agent/TCPSink set ecnhat_ true
    Agent/TCP set ecnhat_g_ $DCTCP_g_;
    #Agent/TCP/FullTcp set deadline 100
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
    global ns enableNAM namfile mytracefile throughputfile
    $ns flush-trace
    if {$enableNAM != 0} {
        close $namfile
        exec nam out.nam &
    }
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
    $ns duplex-link $n($i) $nswitch1 $inputLineRate [expr $RTT/6] DropTail
}


$ns simplex-link $nswitch1 $nswitch2 $lineRate [expr $RTT/6] $switchAlg
$ns simplex-link $nswitch2 $nswitch1 $lineRate [expr $RTT/6] DropTail
$ns queue-limit $nswitch1 $nswitch2 $B

$ns duplex-link $nswitch2 $nclient1 $inputLineRate [expr $RTT/6] DropTail
$ns duplex-link $nswitch2 $nclient2 $inputLineRate [expr $RTT/6] DropTail

#$ns duplex-link-op $nqueue $nclient color "green"
#$ns duplex-link-op $nqueue $nclient queuePos 0.25


#set qfile [$ns monitor-queue $nqueue $nclient [open queue.tr w] $traceSamplingInterval]


for {set i 0} {$i < $N} {incr i} {
    if {[string compare $sourceAlg "Newreno"] == 0 || [string compare $sourceAlg "DC-TCP-Newreno"] == 0} {
	      set tcp($i) [new Agent/TCP/Newreno]
	      set sink($i) [new Agent/TCPSink]
    }
    if {[string compare $sourceAlg "Sack"] == 0 || [string compare $sourceAlg "DC-TCP-Sack"] == 0} { 
        set tcp($i) [new Agent/TCP/FullTcp/Sack]
	      set sink($i) [new Agent/TCP/FullTcp/Sack]
	      $sink($i) listen
    }

    if {[string compare $sourceAlg "DD-TCP-Sack"] == 0} { 
        set tcp($i) [new Agent/TCP/FullTcp/Sack/DDTCP]
        set sink($i) [new Agent/TCP/FullTcp/Sack/DDTCP]
        $sink($i) listen
    }

    if {[string compare $sourceAlg "LL-DCT-Sack"] == 0} { 
      set tcp($i) [new Agent/TCP/FullTcp/Sack/LLDCT]
      set sink($i) [new Agent/TCP/FullTcp/Sack/LLDCT]
      $sink($i) listen
    }

    $ns attach-agent $n($i) $tcp($i)
    if {$i <=3} {
        $ns attach-agent $nclient1 $sink($i)
    } else {
        $ns attach-agent $nclient2 $sink($i)
    }
    
    
    $tcp($i) set fid_ [expr $i]
    $sink($i) set fid_ [expr $i]

    $ns connect $tcp($i) $sink($i)       
}

$ns  trace-queue  $nswitch1 $nswitch2  $trace_file


set ru [new RandomVariable/Uniform]
$ru set min_ 0
$ru set max_ 1.0




$ns at 0.0 "$tcp(0) advance-bytes 5000000" 
$ns at 0.0 "$tcp(1) advance-bytes 10000000" 
$ns at 0.2 "$tcp(2) advance-bytes 20000000" 
$ns at 0.2 "$tcp(3) advance-bytes 20000000" 
$ns at 0.0 "$tcp(4) advance-bytes 100000000" 
$ns at 0.0 "$tcp(5) advance-bytes 100000000" 

#deadline in us
#flow1: 150 ms，flow2: 300ms 
$tcp(0) set deadline_ 150000
$tcp(1) set deadline_ 300000 
                      
$ns at $simulationTime "finish"

$ns run
