package hardware::server::huawei::ibmc::snmp::mode::components::system;

use strict;
use warnings;

sub check {
    my ($self) = @_;
    
    my %statusHash = ("1"=>"ok","2"=>"warning","3"=>"warning","4"=>"critical");
    my %powerHash = ("1"=>"normalPowerOff","2"=>"powerOn","3"=>"forcedSystemReset","4"=>"forcedPowerCycle","5"=>"forcedPowerOff");
       
    my $systemStatusOid = ".1.3.6.1.4.1.2011.2.235.1.1.1.1.0";
    my $deviceNameOid = ".1.3.6.1.4.1.2011.2.235.1.1.1.6.0";
    my $deviceSerialNo = ".1.3.6.1.4.1.2011.2.235.1.1.1.7.0";
    my $systemPowerState = ".1.3.6.1.4.1.2011.2.235.1.1.1.12.0";
    
    my $tmpShortMessage = "";
     
    my $result = $self->{snmp}->get_leef(oids =>[$systemStatusOid,$deviceNameOid,$deviceSerialNo,$systemPowerState]);
    if (scalar(keys %$result) <= 0)
    {
        $tmpShortMessage = $tmpShortMessage."Get system info failed.";
    }else
    {  
        $tmpShortMessage = "deviceName:".$result->{$deviceNameOid}." deviceSerialNo:".$result->{$deviceSerialNo}." systemPowerStatus:".$powerHash{$result->{$systemPowerState}};
    }
      
    
    $self->{output}->output_add(severity => $statusHash{$result->{$systemStatusOid}},
                                short_msg => $tmpShortMessage);

    $self->{output}->display(); 
    $self->{output}->exit();
}
1;