
package centreon::esxd::cmdhealthhost;

use strict;
use warnings;
use centreon::esxd::common;

sub new {
    my $class = shift;
    my $self  = {};
    $self->{logger} = shift;
    $self->{commandName} = 'healthhost';
    
    bless $self, $class;
    return $self;
}

sub getCommandName {
    my $self = shift;
    return $self->{commandName};
}

sub checkArgs {
    my ($self, %options) = @_;

    if (defined($options{arguments}->{esx_hostname}) && $options{arguments}->{esx_hostname} eq "") {
        $options{manager}->{output}->output_add(severity => 'UNKNOWN',
                                                short_msg => "Argument error: esx hostname cannot be null");
        return 1;
    }
    return 0;
}

sub initArgs {
    my ($self, %options) = @_;
    
    foreach (keys %{$options{arguments}}) {
        $self->{$_} = $options{arguments}->{$_};
    }
    $self->{manager} = centreon::esxd::common::init_response();
    $self->{manager}->{output}->{plugin} = $options{arguments}->{identity};
    $self->{manager}->{perfdata}->threshold_validate(label => 'warning', value => 0);
    $self->{manager}->{perfdata}->threshold_validate(label => 'critical', value => 0);
}

sub set_connector {
    my ($self, %options) = @_;
    
    $self->{obj_esxd} = $options{connector};
}

sub run {
    my $self = shift;

    my %filters = (name => $self->{esx_hostname});
    my @properties = ('runtime.healthSystemRuntime.hardwareStatusInfo', 'runtime.healthSystemRuntime.systemHealthInfo.numericSensorInfo', 
                      'runtime.connectionState');
    my $result = centreon::esxd::common::get_entities_host($self->{obj_esxd}, 'HostSystem', \%filters, \@properties);
    if (!defined($result)) {
        return ;
    }
    
    return if (centreon::esxd::common::host_state($self->{obj_esxd}, $self->{esx_hostname}, 
                                                  $$result[0]->{'runtime.connectionState'}->val) == 0);
    
    foreach my $entity_view (@$result) {
        my $OKCount = 0;
        my $CAlertCount = 0;
        my $WAlertCount = 0;
        my $cpuStatusInfo = $entity_view->{'runtime.healthSystemRuntime.hardwareStatusInfo'}->{cpuStatusInfo};
        my $memoryStatusInfo = $entity_view->{'runtime.healthSystemRuntime.hardwareStatusInfo'}->{memoryStatusInfo};
        my $storageStatusInfo = $entity_view->{'runtime.healthSystemRuntime.hardwareStatusInfo'}->{storageStatusInfo};
        my $numericSensorInfo = $entity_view->{'runtime.healthSystemRuntime.systemHealthInfo.numericSensorInfo'};
        
        # CPU
        if (defined($cpuStatusInfo)) {
            foreach (@$cpuStatusInfo) {
                if ($_->status->key =~ /^red$/i) {
                    $self->{manager}->{output}->output_add(long_msg => $_->name . ": " . $_->status->summary);
                    $CAlertCount++;
                } elsif ($_->status->key =~ /^yellow$/i) {
                    $self->{manager}->{output}->output_add(long_msg => $_->name . ": " . $_->status->summary);
                    $WAlertCount++;
                } else {
                    $OKCount++;
                }
            }
        }
        
        # Memory
        if (defined($memoryStatusInfo)) {
            foreach (@$memoryStatusInfo) {
                if ($_->status->key =~ /^red$/i) {
                    $self->{manager}->{output}->output_add(long_msg => $_->name . ": " . $_->status->summary);
                    $CAlertCount++;
                } elsif ($_->status->key =~ /^yellow$/i) {
                    $self->{manager}->{output}->output_add(long_msg => $_->name . ": " . $_->status->summary);
                    $WAlertCount++;
                } else {
                    $OKCount++;
                }
            }
        }
        
        # Storage
        if (defined($self->{storage_status}) && defined($storageStatusInfo)) {
            foreach (@$storageStatusInfo) {
                if ($_->status->key =~ /^red$/i) {
                    $self->{manager}->{output}->output_add(long_msg => $_->name . ": " . $_->status->summary);
                    $CAlertCount++;
                } elsif ($_->status->key =~ /^yellow$/i) {
                    $self->{manager}->{output}->output_add(long_msg => $_->name . ": " . $_->status->summary);
                    $WAlertCount++;
                } else {
                    $OKCount++;
                }
            }
        }
        
        # Sensor
        if (defined($numericSensorInfo)) {
            foreach (@$numericSensorInfo) {
                if ($_->healthState->key =~ /^red$/i) {
                    $self->{manager}->{output}->output_add(long_msg => $_->sensorType . " sensor " . $_->name . ": ".$_->healthState->summary);
                    $CAlertCount++;
                } elsif ($_->healthState->key =~ /^yellow$/i) {
                    $self->{manager}->{output}->output_add(long_msg => $_->sensorType . " sensor " . $_->name . ": ".$_->healthState->summary);
                    $WAlertCount++;
                } else {
                    $OKCount++;
                }
            }
        }
        
        my $exit = $self->{manager}->{perfdata}->threshold_check(value => $WAlertCount, 
                                                                 threshold => [ { label => 'warning', exit_litteral => 'warning' } ]);
        if (!$self->{manager}->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{manager}->{output}->output_add(severity => $exit,
                                                   short_msg => sprintf("%s health issue(s) found", $WAlertCount));
        }
        $exit = $self->{manager}->{perfdata}->threshold_check(value => $CAlertCount, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' } ]);
        if (!$self->{manager}->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{manager}->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("%s health issue(s) found", $CAlertCount));
        }
        
        $self->{manager}->{output}->output_add(severity => 'OK',
                                               short_msg => sprintf("All %s health checks are green", $OKCount));
    }
}

1;
