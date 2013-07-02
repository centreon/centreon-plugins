
package centreon::esxd::cmdhealthhost;

use strict;
use warnings;
use centreon::esxd::common;

sub new {
    my $class = shift;
    my $self  = {};
    $self->{logger} = shift;
    $self->{obj_esxd} = shift;
    $self->{commandName} = 'healthhost';
    
    bless $self, $class;
    return $self;
}

sub getCommandName {
    my $self = shift;
    return $self->{commandName};
}

sub checkArgs {
    my $self = shift;
    my ($host) = @_;

    if (!defined($host) || $host eq "") {
        $self->{logger}->writeLogError("ARGS error: need hostname");
        return 1;
    }
    return 0;
}

sub initArgs {
    my $self = shift;
    $self->{lhost} = $_[0];
}

sub run {
    my $self = shift;

    my %filters = ('name' => $self->{lhost});
    my @properties = ('runtime.healthSystemRuntime.hardwareStatusInfo.cpuStatusInfo', 'runtime.healthSystemRuntime.systemHealthInfo.numericSensorInfo');
    my $result = centreon::esxd::common::get_entities_host($self->{obj_esxd}, 'HostSystem', \%filters, \@properties);
    if (!defined($result)) {
        return ;
    }
    
    my $status = 0; # OK
    my $output_critical = '';
    my $output_critical_append = '';
    my $output_warning = '';
    my $output_warning_append = '';
    my $output = '';
    my $output_append = '';
    my $OKCount = 0;
    my $CAlertCount = 0;
    my $WAlertCount = 0;
    foreach my $entity_view (@$result) {
            my $cpuStatusInfo = $entity_view->{'runtime.healthSystemRuntime.hardwareStatusInfo.cpuStatusInfo'};
        my $numericSensorInfo = $entity_view->{'runtime.healthSystemRuntime.systemHealthInfo.numericSensorInfo'};
        if (!defined($cpuStatusInfo)) {
            $status = centreon::esxd::common::errors_mask($status, 'CRITICAL');
            centreon::esxd::common::output_add(\$output_critical, \$output_critical_append, ", ",
                "API error - unable to get cpuStatusInfo");
        }
        if (!defined($numericSensorInfo)) {
            $status = centreon::esxd::common::errors_mask($status, 'CRITICAL');
            centreon::esxd::common::output_add(\$output_critical, \$output_critical_append, ", ",
                "API error - unable to get numericSensorInfo");
        }

        # CPU
        foreach (@$cpuStatusInfo) {
            if ($_->status->key =~ /^red$/i) {
                centreon::esxd::common::output_add(\$output_critical, \$output_critical_append, ", ",
                    $_->name . ": " . $_->status->summary);
                $status = centreon::esxd::common::errors_mask($status, 'CRITICAL');
                $CAlertCount++;
            } elsif ($_->status->key =~ /^yellow$/i) {
                centreon::esxd::common::output_add(\$output_warning, \$output_warning_append, ", ",
                    $_->name . ": " . $_->status->summary);
                $status = centreon::esxd::common::errors_mask($status, 'WARNING');
                $WAlertCount++;
            } else {
                $OKCount++;
            }
        }
        # Sensor
        foreach (@$numericSensorInfo) {
            if ($_->healthState->key =~ /^red$/i) {
                centreon::esxd::common::output_add(\$output_critical, \$output_critical_append, ", ",
                    $_->sensorType . " sensor " . $_->name . ": ".$_->healthState->summary);
                $status = centreon::esxd::common::errors_mask($status, 'CRITICAL');
                $CAlertCount++;
            } elsif ($_->healthState->key =~ /^yellow$/i) {
                centreon::esxd::common::output_add(\$output_warning, \$output_warning_append, ", ",
                    $_->sensorType . " sensor " . $_->name . ": ".$_->healthState->summary);
                $status = centreon::esxd::common::errors_mask($status, 'WARNING');
                $WAlertCount++;
            } else {
                $OKCount++;
            }
        }
    }

    if ($output_critical ne "") {
        $output .= $output_append . "CRITICAL - $CAlertCount health issue(s) found: $output_critical";
        $output_append = ". ";
    }
    if ($output_warning ne "") {
        $output .= $output_append . "WARNING - $WAlertCount health issue(s) found: $output_warning";
    }
    if ($status == 0) {
        $output = "All $OKCount health checks are green";
    }
    
    $self->{obj_esxd}->print_response(centreon::esxd::common::get_status($status) . "|$output\n");
}

1;
