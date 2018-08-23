package hardware::server::huawei::ibmc::snmp::mode::components::cpu;

use strict;
use warnings;

sub check {
    my ($self) = @_;
    
    my %statusHash = ("1"=>"ok","2"=>"warning","3"=>"warning","4"=>"critical","5"=>"unknown","6"=>"unknown");
    my %eachStatus = ("1"=>"ok","2"=>"minor","3"=>"major","4"=>"critical","5"=>"absence","6"=>"unknown");     
     
    my $cpuStatusOid = ".1.3.6.1.4.1.2011.2.235.1.1.15.1.0";        
    my $statusTableOid = ".1.3.6.1.4.1.2011.2.235.1.1.15.50.1.6";
    my $deviceTableOid = ".1.3.6.1.4.1.2011.2.235.1.1.15.50.1.10";
    
    my $tmpShortMessage = "";
    my $totalPresent = 0;
    my $totalComponent = 0;
    my $result = $self->{snmp}->get_table(oid => $statusTableOid);
    if (scalar(keys %$result) <= 0)
    {
        $tmpShortMessage = $tmpShortMessage."No cpu presence.";
    }else 
    {   
        my $endKey;
        my $temnameOid;
        my $statusOid;
        my $tmpMsg;
        my $tmpresult;
        my $v;
        foreach my $k ($self->{snmp}->oid_lex_sort(keys %$result))
        {
            $v = $result->{$k};
            $endKey = "0";
            $temnameOid = "";
            $statusOid = "";
            $tmpMsg = "";
            $totalComponent++;
            if ($v ne "5")  # cpu present  
            {   
                $totalPresent++;
                $k =~ /\.([0-9]+)$/;
                $endKey = $1;
                $temnameOid = $deviceTableOid.".".$endKey;
                $statusOid = $statusTableOid.".".$endKey;
                $tmpresult = $self->{snmp}->get_leef(oids =>[$temnameOid]);
                $tmpMsg = $tmpresult->{$temnameOid}.":";
                $tmpresult = $self->{snmp}->get_leef(oids =>[$statusOid]);
                $tmpMsg = $tmpMsg.$eachStatus{$tmpresult->{$statusOid}}." ";
                $tmpShortMessage = $tmpShortMessage.$tmpMsg;
            }
        }       
    } 
    $result = $self->{snmp}->get_leef(oids =>[$cpuStatusOid]);
    $tmpShortMessage = "cpuPresence:".$totalPresent."\/".$totalComponent." ".$tmpShortMessage;

    $self->{output}->output_add(severity => $statusHash{$result-> {$cpuStatusOid}},
                                short_msg => $tmpShortMessage );

    $self->{output}->display(); 
    $self->{output}->exit();
}
1;