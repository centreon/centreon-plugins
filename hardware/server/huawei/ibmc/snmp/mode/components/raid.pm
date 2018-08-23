package hardware::server::huawei::ibmc::snmp::mode::components::raid;

use strict;
use warnings;

sub check {
    my ($self) = @_;
    
    my $raidStatusOid = ".1.3.6.1.4.1.2011.2.235.1.1.36.50.1.7";
    my $bbuPresentOid = ".1.3.6.1.4.1.2011.2.235.1.1.36.50.1.16";
    my $bbuStatusOid = ".1.3.6.1.4.1.2011.2.235.1.1.36.50.1.18";
    
    my $tmpShortMessage = "";
    my $result = $self->{snmp}->get_table(oid => $bbuPresentOid);
    if (scalar(keys %$result) <= 0)
    {
        $tmpShortMessage = $tmpShortMessage."Get BBU info failed.";
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
            $k =~ /\.([0-9]+)$/;
            $endKey = $1;
            if ($v eq "2")  # BBU present  
            {   
                $statusOid = $bbuStatusOid.".".$endKey;
                $tmpresult = $self->{snmp}->get_leef(oids =>[$statusOid]);
                my $tmpEachstate;
                if ($tmpresult->{$statusOid} eq "0")
                {   
                    $tmpEachstate="ok";  
                }
                else 
                {  
                    $tmpEachstate="warning";  
                }  
                $tmpMsg =$tmpMsg. "BBU ".$endKey.":".$tmpEachstate." ";
                $tmpShortMessage=$tmpShortMessage.$tmpMsg;
            }elsif ($v eq "1")
            {   
                $tmpShortMessage= $tmpShortMessage."BBU".$1.":absent ";
            }else
            {
                $tmpShortMessage= $tmpShortMessage."BBU".$1.":unknown ";
            }
        } 
    }
    
    $result = $self->{snmp}->get_table(oid =>$raidStatusOid);
    my $raidseverity = "undefine";
    if (scalar(keys %$result) <= 0)
    {
        $tmpShortMessage = $tmpShortMessage."Get raid Status failed."
    }else 
    {   
        while (my($k,$v)= each %$result){
            $k =~ /\.([0-9]+)$/;
            
            if ($v eq "65535")
            {   
                if( $raidseverity ne "warning")
                {
                    $raidseverity = "unknown";
                }
                $tmpShortMessage = "RAID".$1.":unknown ".$tmpShortMessage;
            }elsif ($v eq "0")
            {  
                if (($raidseverity ne "warning")&&($raidseverity ne "unknown"))
                {   
                    $raidseverity = "ok";  
                }
                $tmpShortMessage = "RAID".$1.":ok ".$tmpShortMessage;
            }else 
            {   
                $raidseverity = "warning";
                $tmpShortMessage = "RAID".$1.":warning ".$tmpShortMessage;
            }                
        } 
    }
    if ($raidseverity eq "undefine") 
    { 
        $raidseverity = "unknown";
    }
    
    $self->{output}->output_add(severity => $raidseverity ,
                                short_msg => $tmpShortMessage );     
    $self->{output}->display(); 
    $self->{output}->exit();
    
}
1;