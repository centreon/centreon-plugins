package hardware::server::huawei::hmm::snmp::mode::components::cpu;

use strict;
use warnings;

sub check {
    my ($self) = @_;
    
    my %statusHash = ("1"=>"ok","2"=>"warning","3"=>"warning","4"=>"critical","5"=>"unknown");
    my %eachStatus = ("1"=>"ok","2"=>"minor","3"=>"major","4"=>"critical","5"=>"unknown");     
    
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
            my $componentPresentOid = sprintf ".1.3.6.1.4.1.2011.2.82.1.82.4.%s.2006.1.4", $self->{option_results}->{bladeNum};
    		my $componentStatusOid = sprintf ".1.3.6.1.4.1.2011.2.82.1.82.4.%s.2006.1.5", $self->{option_results}->{bladeNum};
    		my $componentMarkOid = sprintf ".1.3.6.1.4.1.2011.2.82.1.82.4.%s.2006.1.2", $self->{option_results}->{bladeNum};
          
            $self->{snmp}->{snmp_force_getnext} = 1;
            my $result = $self->{snmp}->get_table(oid => $componentPresentOid);
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
                    if ($v eq "1")  # presence status: 0-not presence,1-presence 
                    {           
                        $totalPresent++;
                        $k =~ /\.([0-9]+)$/;
                        $endKey = $1;
                        $temnameOid = $componentMarkOid.".".$endKey;
                        $statusOid = $componentStatusOid.".".$endKey;
                        $tmpresult = $self->{snmp}->get_leef(oids =>[$temnameOid]);
                        
                        $tmpMsg = $tmpresult->{$temnameOid}.":";
                        $tmpresult = $self->{snmp}->get_leef(oids =>[$statusOid]);
                        $tmpMsg = $tmpMsg.$eachStatus{$tmpresult->{$statusOid}}." ";
                        $tmpShortMessage = $tmpShortMessage.$tmpMsg;
                        if($statusHash{$tmpresult->{$statusOid}} eq "critical")
                        {
                            $componentStatus = "critical";
                        }elsif (($statusHash{$tmpresult->{$statusOid}}) eq "warning" && ($componentStatus ne "critical"))
                        {
                            $componentStatus = "warning";
                        }elsif (($statusHash{$tmpresult->{$statusOid}}) eq "ok")
                        {
                            if ($componentStatus eq "unknown")
                            {
                                $componentStatus = "ok";
                            }
                        }                
                    }
                }    
                $tmpShortMessage = "cpuPresence:".$totalPresent."\/".$totalComponent." ".$tmpShortMessage;        
            }
        }else
        {   
            $tmpShortMessage = sprintf $tmpShortMessage."Blade%s status unknown.", $self->{option_results}->{bladeNum};
        }
        
    }
      
    $self->{output}->output_add(severity => $componentStatus,
                                short_msg => $tmpShortMessage );
    
    $self->{output}->display(); 
    $self->{output}->exit(); 
}
1;