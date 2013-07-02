
package centreon::esxd::cmdcpuhost;

use strict;
use warnings;
use centreon::esxd::common;

sub new {
    my $class = shift;
    my $self  = {};
    $self->{logger} = shift;
    $self->{obj_esxd} = shift;
    $self->{commandName} = 'cpuhost';
    
    bless $self, $class;
    return $self;
}

sub getCommandName {
    my $self = shift;
    return $self->{commandName};
}

sub checkArgs {
    my $self = shift;
    my ($host, $warn, $crit, $light_perfdata) = @_;

    if (!defined($host) || $host eq "") {
        $self->{logger}->writeLogError("ARGS error: need hostname");
        return 1;
    }
    if (defined($warn) && $warn !~ /^-?(?:\d+\.?|\.\d)\d*\z/) {
        $self->{logger}->writeLogError("ARGS error: warn threshold must be a positive number");
        return 1;
    } 
    if (defined($crit) && $crit !~ /^-?(?:\d+\.?|\.\d)\d*\z/) {
        $self->{logger}->writeLogError("ARGS error: crit threshold must be a positive number");
        return 1;
    }
    if (defined($warn) && defined($crit) && $warn > $crit) {
        $self->{logger}->writeLogError("ARGS error: warn threshold must be lower than crit threshold");
        return 1;
    }
    return 0;
}

sub initArgs {
    my $self = shift;
    $self->{lhost} = $_[0];
    $self->{warn} = (defined($_[1]) ? $_[1] : 80);
    $self->{crit} = (defined($_[2]) ? $_[2] : 90);
    $self->{light_perfdata} = (defined($_[3]) ? $_[3] : 0);
}

sub run {
    my $self = shift;

    if (!($self->{obj_esxd}->{perfcounter_speriod} > 0)) {
        my $status = centreon::esxd::common::errors_mask(0, 'UNKNOWN');
        $self->{obj_esxd}->print_response(centreon::esxd::common::get_status($status) . "|Can't retrieve perf counters.\n");
        return ;
    }

    my %filters = ('name' => $self->{lhost});
    my @properties = ('name', 'runtime.connectionState');
    my $result = centreon::esxd::common::get_entities_host($self->{obj_esxd}, 'HostSystem', \%filters, \@properties);
    if (!defined($result)) {
        return ;
    }

    return if (centreon::esxd::common::host_state($self->{obj_esxd}, $self->{lhost}, 
                                                $$result[0]->{'runtime.connectionState'}->val) == 0);

    my @instances = ('*');

    my $values = centreon::esxd::common::generic_performance_values_historic($self->{obj_esxd},
                        $$result[0], 
                        [{'label' => 'cpu.usage.average', 'instances' => \@instances}],
                        $self->{obj_esxd}->{perfcounter_speriod});

    my $status = 0; # OK
    my $output = '';
    my $total_cpu_average = centreon::esxd::common::simplify_number(centreon::esxd::common::convert_number($values->{$self->{obj_esxd}->{perfcounter_cache}->{'cpu.usage.average'}->{'key'} . ":"}[0] * 0.01));
    
    if ($total_cpu_average >= $self->{warn}) {
        $status = centreon::esxd::common::errors_mask($status, 'WARNING');
    }
    if ($total_cpu_average >= $self->{crit}) {
        $status = centreon::esxd::common::errors_mask($status, 'CRITICAL');
    }

    $output = "Total Average CPU usage '$total_cpu_average%' on last " . int($self->{obj_esxd}->{perfcounter_speriod} / 60) . "min | cpu_total=$total_cpu_average%;$self->{warn};$self->{crit};0;100";

    foreach my $id (sort { my ($cida, $cia) = split /:/, $a;
                   my ($cidb, $cib) = split /:/, $b;
                               $cia = -1 if (!defined($cia) || $cia eq "");
                               $cib = -1 if (!defined($cib) || $cib eq "");
                   $cia <=> $cib} keys %$values) {
        my ($counter_id, $instance) = split /:/, $id;
        if ($instance ne "" and $self->{light_perfdata} != 1) {
            $output .= " cpu$instance=" . centreon::esxd::common::simplify_number(centreon::esxd::common::convert_number($values->{$id}[0]) * 0.01) . "%;;0;100";
        }
    }
    $self->{obj_esxd}->print_response(centreon::esxd::common::get_status($status) . "|$output\n");
}

1;
