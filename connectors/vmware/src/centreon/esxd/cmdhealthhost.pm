
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
    if (defined($options{arguments}->{disconnect_status}) && 
        $options{manager}->{output}->is_litteral_status(status => $options{arguments}->{disconnect_status}) == 0) {
        $options{manager}->{output}->output_add(severity => 'UNKNOWN',
                                                short_msg => "Argument error: wrong value for disconnect status '" . $options{arguments}->{disconnect_status} . "'");
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
    
    $self->{connector} = $options{connector};
}

sub run {
    my $self = shift;

    my %filters = ();
    my $multiple = 0;

    if (defined($self->{esx_hostname}) && !defined($self->{filter})) {
        $filters{name} = qr/^\Q$self->{esx_hostname}\E$/;
    } elsif (!defined($self->{esx_hostname})) {
        $filters{name} = qr/.*/;
    } else {
        $filters{name} = qr/$self->{esx_hostname}/;
    }
    
    my @properties = ('name', 'runtime.healthSystemRuntime.hardwareStatusInfo', 'runtime.healthSystemRuntime.systemHealthInfo.numericSensorInfo', 
                      'runtime.connectionState');
    my $result = centreon::esxd::common::search_entities(command => $self, view_type => 'HostSystem', properties => \@properties, filter => \%filters);
    return if (!defined($result));
    
    if (scalar(@$result) > 1) {
        $multiple = 1;
    }
    if ($multiple == 1) {
        $self->{manager}->{output}->output_add(severity => 'OK',
                                               short_msg => sprintf("All ESX health checks are ok"));
    }
    
    foreach my $entity_view (@$result) {
        next if (centreon::esxd::common::host_state(connector => $self->{connector},
                                                    hostname => $entity_view->{name}, 
                                                    state => $entity_view->{'runtime.connectionState'}->val,
                                                    status => $self->{disconnect_status},
                                                    multiple => $multiple) == 0);

        my $OKCount = 0;
        my $CAlertCount = 0;
        my $WAlertCount = 0;
        my $cpuStatusInfo = $entity_view->{'runtime.healthSystemRuntime.hardwareStatusInfo'}->{cpuStatusInfo};
        my $memoryStatusInfo = $entity_view->{'runtime.healthSystemRuntime.hardwareStatusInfo'}->{memoryStatusInfo};
        my $storageStatusInfo = $entity_view->{'runtime.healthSystemRuntime.hardwareStatusInfo'}->{storageStatusInfo};
        my $numericSensorInfo = $entity_view->{'runtime.healthSystemRuntime.systemHealthInfo.numericSensorInfo'};
        $self->{manager}->{output}->output_add(long_msg => sprintf("Checking %s", $entity_view->{name}));
        
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
                                                   short_msg => sprintf("'%s' %s health issue(s) found", $entity_view->{name}, $WAlertCount));
        }
        $exit = $self->{manager}->{perfdata}->threshold_check(value => $CAlertCount, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' } ]);
        if (!$self->{manager}->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{manager}->{output}->output_add(severity => $exit,
                                                   short_msg => sprintf("'%s' %s health issue(s) found", $entity_view->{name}, $CAlertCount));
        }
        
        $self->{manager}->{output}->output_add(long_msg => sprintf("%s health checks are green", $OKCount));
        if ($multiple == 0) {
            $self->{manager}->{output}->output_add(severity => 'OK',
                                                   short_msg => sprintf("'%s' %s health checks are green", $entity_view->{name}, $OKCount));
        }
        my $extra_label = '';
        $extra_label = '_' . $entity_view->{name} if ($multiple == 1);
        $self->{manager}->{output}->perfdata_add(label => 'problems' . $extra_label,
                                                 value => $CAlertCount + $WAlertCount,
                                                 min => 0, max => $OKCount + $CAlertCount + $WAlertCount);
    }
}

1;
