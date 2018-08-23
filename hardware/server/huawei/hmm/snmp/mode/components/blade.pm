package hardware::server::huawei::hmm::snmp::mode::components::blade;

use strict;
use warnings;

sub check {
    my ($self) = @_;
    
    my %statusHash = ("0"=>"ok","1"=>"warning","2"=>"warning","3"=>"warning","4"=>"critical","5"=>"critical","6"=>"critical","7"=>"critical");
    my %eachStatus = ("0"=>"ok","1"=>"minor","2"=>"major","3"=>"major","4"=>"critical","5"=>"critical","6"=>"critical","7"=>"critical");
    
    my $componentPresentOid = sprintf ".1.3.6.1.4.1.2011.2.82.1.82.4.%s.6.0", $self->{option_results}->{bladeNum};
    my $componentStatusOid = sprintf ".1.3.6.1.4.1.2011.2.82.1.82.4.%s.8.0", $self->{option_results}->{bladeNum};
    my $componentTemperatureOid = sprintf ".1.3.6.1.4.1.2011.2.82.1.82.4.%s.2012.1.2.1", $self->{option_results}->{bladeNum};
    my $tmpShortMessage = "";
    my $tmpSeverity = "unknown";
       
    my $result= $self->{snmp}->get_leef(oids =>[$componentPresentOid]);
    if (scalar(keys %$result) <= 0)
    {
        $tmpShortMessage = $tmpShortMessage."Get blade info error.";
    }else 
    {
        if ($result->{$componentPresentOid} eq "0")
        {
            $tmpShortMessage = sprintf $tmpShortMessage."Blade%s not presence.", $self->{option_results}->{bladeNum};
        }elsif ($result->{$componentPresentOid} eq "2")
        {
            $tmpShortMessage = sprintf $tmpShortMessage."Blade%s status indeterminate.", $self->{option_results}->{bladeNum};
        }elsif ($result->{$componentPresentOid} eq "1") 
        {   
            $result= $self->{snmp}->get_leef(oids =>[$componentStatusOid]);
            $tmpSeverity = $statusHash{$result->{$componentStatusOid}};
            $tmpShortMessage = $tmpShortMessage. "Blade".$self->{option_results}->{bladeNum}.":".$eachStatus{$result->{$componentStatusOid}}; 
            $result = $self->{snmp}->get_leef(oids =>[$componentTemperatureOid] );
            $tmpShortMessage = $tmpShortMessage." Temperature:".$result->{$componentTemperatureOid}."℃"; 
        }else
        {
            $tmpShortMessage = sprintf $tmpShortMessage."Blade%s status unknown.", $self->{option_results}->{bladeNum};
        }
    }
    
    $self->{output}->output_add(severity => $tmpSeverity,
                                short_msg => $tmpShortMessage);
    $self->{output}->display(); 
    $self->{output}->exit();
}

1;    
    
    