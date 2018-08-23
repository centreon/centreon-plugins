package hardware::server::huawei::hmm::snmp::mode::components::shelf;

use strict;
use warnings;

sub check {
    my ($self) = @_;
    
    my %statusHash = ("0"=>"ok","1"=>"warning","2"=>"warning","3"=>"warning","4"=>"critical","5"=>"critical","6"=>"critical","7"=>"critical");
    
    my $componentStatusOid = ".1.3.6.1.4.1.2011.2.82.1.82.2.5.0";        
    my $tmpShortMessage = "";
    my $componentStatus = "unknown";  
    my $tmpResult;
    
    $tmpResult = $self->{snmp}->get_leef(oids =>[$componentStatusOid]);
    
    $componentStatus = $statusHash{$tmpResult->{$componentStatusOid}};
    
    $self->{output}->output_add(severity => $componentStatus,
                                short_msg => $tmpShortMessage);

    $self->{output}->display(); 
    $self->{output}->exit();
    }
1;    
    