set N 2
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

set DCTCP_g_ 0.25
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


Agent/TCP/FullTcp/Sack/DAFDTCP set T_  600;                # in ms


if {[string compare $sourceAlg "DAFD-TCP-Sack"] == 0} {
    Agent/TCP set ecnhat_ true
    Agent/TCPSink set ecnhat_ true
    Agent/TCP set ecnhat_g_ $DCTCP_g_;
    set myAgent "Agent/TCP/FullTcp/Sack/DAFDTCP";
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

set nswitch [$ns node]
set nclient [$ns node]



for {set i 0} {$i < $N} {incr i} {
    $ns duplex-link $n($i) $nswitch $inputLineRate [expr $RTT/4] DropTail
}


$ns simplex-link $nswitch $nclient   $lineRate [expr $RTT/4] $switchAlg
$ns simplex-link $nclient $nswitch   $lineRate [expr $RTT/4] DropTail

#$ns duplex-link-op $nqueue $nclient color "green"
#$ns duplex-link-op $nqueue $nclient queuePos 0.25


#set qfile [$ns monitor-queue $nqueue $nclient [open queue.tr w] $traceSamplingInterval]


for {set i 0} {$i < $N} {incr i} {

	if {[string compare $sourceAlg "DAFD-TCP-Sack"] == 0} {
      set tcp($i) [new Agent/TCP/FullTcp/Sack/DAFDTCP]
      set sink($i) [new Agent/TCP/FullTcp/Sack/DAFDTCP]
      $sink($i) listen
	}

    $ns attach-agent $n($i) $tcp($i)
    $ns attach-agent $nclient $sink($i)
    
    $tcp($i) set fid_ [expr $i]
    $sink($i) set fid_ [expr $i]

    $ns connect $tcp($i) $sink($i)       
}

$ns  trace-queue  $nswitch $nclient  $trace_file



$ns at 0.0 "$tcp(0) advance-bytes 50000000" 
$ns at 0.0 "$tcp(1) advance-bytes 100000000" 

#deadline in us
#flow1: 300 ms，flow2: 500ms 
$tcp(0) set deadline_ 300000
$tcp(1) set deadline_ 500000 
                      


set throughputSamplingInterval 0.0005
set qfile [$ns monitor-queue $nswitch $nclient [open queue.tr w] $throughputSamplingInterval]
for {set i 0 } {$i < $N} {incr i} {
  set qmon($i) [$ns monitor-queue $n($i) $nswitch  [open queue.tr w] $throughputSamplingInterval ]
}


proc throughputTrace {file} {

    global ns throughputSamplingInterval qfile  N qmon tcp
    set now [$ns now]
    puts -nonewline $file "$now "
    for {set i 0} {$i < $N} {incr i} {
        $qmon($i) instvar barrivals_
        puts -nonewline $file "[expr $barrivals_/$throughputSamplingInterval*8/1000000]  "
        set barrivals_ 0
   }

  for {set i 0} {$i < $N} {incr i} {
        set cwnd [$tcp($i)  set cwnd_]
        puts -nonewline $file "$cwnd "
        set barrivals_ 0
   }


   for {set i 0} {$i < $N} {incr i} {
        set alpha [$tcp($i)  set ecnhat_alpha_]
        puts -nonewline $file "$alpha "
   }


   


    $qfile instvar parrivals_ pdepartures_ pdrops_ pkts_ ss  
    puts  $file "[expr $parrivals_-$pdepartures_-$pdrops_]"    
    $ns at [expr $now+$throughputSamplingInterval] "throughputTrace $file"
}


set throughputfile [open queue w]
$ns at $throughputSamplingInterval "throughputTrace $throughputfile"  

$ns at $simulationTime "finish"



$ns run
