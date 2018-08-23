package hardware::server::huawei::hmm::snmp::mode::components::psu;

use strict;
use warnings;

sub check {
    my ($self) = @_;
    
    my %statusHash = ("1"=>"ok","2"=>"warning","3"=>"warning","4"=>"critical");
    my %eachStatus = ("1"=>"ok","2"=>"minor","3"=>"major","4"=>"critical");     
         
    my $psuPresenceOid = ".1.3.6.1.4.1.2011.2.82.1.82.100.4.2001.1.1";
    my $psuStatusOid = ".1.3.6.1.4.1.2011.2.82.1.82.100.4.2001.1.3";
    
    my $tmpShortMessage = "";
    my $componentStatus = "unknown";
    
    $self->{snmp}->{snmp_force_getnext} = 1;
    my $result = $self->{snmp}->get_table(oid => $psuPresenceOid);
    if (scalar(keys %$result) <= 0)
    {
        $tmpShortMessage = $tmpShortMessage."No psu presence.";
    }else 
    {   
        my $endKey;
        my $statusOid;
        my $tmpMsg;
        my $tmpResult;
        my $totalPresence = 0;
        my $totalComponent = 6;
        my $v;
        foreach my $k ($self->{snmp}->oid_lex_sort(keys %$result))
        {
            $v = $result->{$k};
            $endKey = "0";
            $statusOid = "";
            $tmpMsg = "";         
            $totalPresence++;
            $k =~ /\.([0-9]+)$/;
            $endKey = $1 ;
            $tmpMsg = "Psu".$endKey.":";
            $statusOid = $psuStatusOid.".".$endKey;
            $tmpResult = $self->{snmp}->get_leef(oids =>[$statusOid]);
            $tmpMsg = $tmpMsg.$eachStatus{$tmpResult->{$statusOid}}." ";
            $tmpShortMessage = $tmpShortMessage.$tmpMsg;
            
            if($statusHash{$tmpResult->{$statusOid}} eq "critical")
            {
                $componentStatus = "critical";
            }elsif (($statusHash{$tmpResult->{$statusOid}}) eq "warning" && ($componentStatus ne "critical"))
            {
                $componentStatus = "warning";
            }elsif (($statusHash{$tmpResult->{$statusOid}}) eq "ok")
            {
                if ($componentStatus eq "unknown")
                {
                    $componentStatus = "ok";
                }
            }         
        } 
        $tmpShortMessage = "psuPresence:".$totalPresence."\/".$totalComponent." ".$tmpShortMessage;
    } 
    
    $self->{output}->output_add(severity => $componentStatus,
                                short_msg => $tmpShortMessage);
    
    $self->{output}->display(); 
    $self->{output}->exit();    
}
1;