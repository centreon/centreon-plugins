package hardware::server::huawei::hmm::snmp::mode::components::raid;

use strict;
use warnings;

sub check {
    my ($self) = @_;
    
    my $bladePresentOid = sprintf ".1.3.6.1.4.1.2011.2.82.1.82.4.%s.6.0", $self->{option_results}->{bladeNum};  
    
    my $tmpShortMessage = "";
    my $componentStatus = "unknown";
    
    my $result= $self->{snmp}->get_leef(oids =>[$bladePresentOid]);
    if (scalar(keys %$result) <= 0)
    {
        $tmpShortMessage = $tmpShortMessage."Get blade info error.";
    }else 
    {   
        if ($result->{$bladePresentOid} eq "0")
        {
            $tmpShortMessage = sprintf $tmpShortMessage."Blade%s not presence.", $self->{option_results}->{bladeNum};
        }elsif ($result->{$bladePresentOid} eq "2")
        {
            $tmpShortMessage = sprintf $tmpShortMessage."Blade%s status indeterminate.", $self->{option_results}->{bladeNum};
        }elsif ($result->{$bladePresentOid} eq "1") 
        {
            my $componentPresentOid = sprintf ".1.3.6.1.4.1.2011.2.82.1.82.4.%s.2011.1.2", $self->{option_results}->{bladeNum};
            my $componentStatusOid = sprintf ".1.3.6.1.4.1.2011.2.82.1.82.4.%s.2011.1.7", $self->{option_results}->{bladeNum};
            my $componentMarkOid = sprintf ".1.3.6.1.4.1.2011.2.82.1.82.4.%s.2011.1.3", $self->{option_results}->{bladeNum};

            $self->{snmp}->{snmp_force_getnext} = 1;
            my $result = $self->{snmp}->get_table(oid => $componentPresentOid);
            if (scalar(keys %$result) <= 0)
            {
                $tmpShortMessage = $tmpShortMessage."No raid presence.";
            }else 
            {   
                my $endKey;
                my $temnameOid;
                my $statusOid;
                my $tmpMsg;
                my $tmpResult;
                my $totalPresent = 0;
                my $totalComponent = 0;
                my $v;
                foreach my $k ($self->{snmp}->oid_lex_sort(keys %$result))
                {
                    $v = $result->{$k};
                    $endKey = "0";
                    $temnameOid = "";
                    $statusOid = "";
                    $tmpMsg = "";
                    $totalComponent++;
                    if ($v eq "2")  # presence status: 1-not presence,2-presence
                    {                      
                        $totalPresent++;
                        $k =~ /\.([0-9]+)$/;
                        $endKey = $1 ;
                        $temnameOid = $componentMarkOid.".".$endKey;
                        $statusOid = $componentStatusOid.".".$endKey;
                        $tmpResult = $self->{snmp}->get_leef(oids =>[$temnameOid]);
                        
                        $tmpMsg = $tmpResult->{$temnameOid}.":";
                        $tmpResult = $self->{snmp}->get_leef(oids =>[$statusOid]);
                        my $tmpStatus;
                        if ($tmpResult->{$statusOid} eq "-1"){
                            $tmpStatus = "unknown";
                        }elsif($tmpResult->{$statusOid} eq "1")
                        {   
                            $tmpStatus = "ok";
                        }else
                        {  
                            $tmpStatus = "warning";               
                        }
                        $tmpMsg = $tmpMsg.$tmpStatus." ";
                        $tmpShortMessage = $tmpShortMessage.$tmpMsg;
                        if($tmpStatus eq "warning")
                        {
                            $componentStatus = "warning";
                        }elsif ($tmpStatus eq "ok")
                        {
                            if ($componentStatus eq "unknown")
                            {
                                $componentStatus = "ok";
                            }
                        }                        
                    }
                }    
                $tmpShortMessage = "raidPresence:".$totalPresent."\/".$totalComponent." ".$tmpShortMessage;        
            }                           
        }else
        {   
            $tmpShortMessage = sprintf $tmpShortMessage."Blade%s status unknown.", $self->{option_results}->{bladeNum};
        }
    }
     
    $self->{output}->output_add(severity => $componentStatus,
                                short_msg => $tmpShortMessage);
    
    $self->{output}->display(); 
    $self->{output}->exit(); 
                                
}
1;