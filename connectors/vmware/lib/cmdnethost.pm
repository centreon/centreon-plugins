
package centreon::esxd::cmdnethost;

use strict;
use warnings;
use centreon::esxd::common;

sub new {
    my $class = shift;
    my $self  = {};
    $self->{logger} = shift;
    $self->{obj_esxd} = shift;
    $self->{commandName} = 'nethost';
    
    bless $self, $class;
    return $self;
}

sub getCommandName {
    my $self = shift;
    return $self->{commandName};
}

sub checkArgs {
    my $self = shift;
    my ($host, $pnic, $warn, $crit) = @_;

    if (!defined($host) || $host eq "") {
        $self->{logger}->writeLogError("ARGS error: need hostname");
        return 1;
    }
    if (!defined($pnic) || $pnic eq "") {
        $self->{logger}->writeLogError("ARGS error: need physical nic name");
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
    $self->{pnic} = $_[1];
    $self->{filter} = (defined($_[2]) && $_[2] == 1) ? 1 : 0;
    $self->{warn} = (defined($_[3]) ? $_[3] : 80);
    $self->{crit} = (defined($_[4]) ? $_[4] : 90);
}

sub run {
    my $self = shift;

    if (!($self->{obj_esxd}->{perfcounter_speriod} > 0)) {
        my $status = centreon::esxd::common::errors_mask(0, 'UNKNOWN');
        $self->{obj_esxd}->print_response(centreon::esxd::common::get_status($status) . "|Can't retrieve perf counters.\n");
        return ;
    }

    my %filters = ('name' => $self->{lhost});
    my @properties = ('config.network.pnic', 'runtime.connectionState');
    my $result = centreon::esxd::common::get_entities_host($self->{obj_esxd}, 'HostSystem', \%filters, \@properties);
    if (!defined($result)) {
        return ;
    }
    
    return if (centreon::esxd::common::host_state($self->{obj_esxd}, $self->{lhost}, 
                                                $$result[0]->{'runtime.connectionState'}->val) == 0);
    
    my %pnic_def = ();
    foreach (@{$$result[0]->{'config.network.pnic'}}) {
        if (defined($_->linkSpeed)) {
            $pnic_def{$_->device} = $_->linkSpeed->speedMb;
        }
    }

    if (!defined($pnic_def{$self->{pnic}})) {
        my $status = centreon::esxd::common::errors_mask(0, 'UNKNOWN');
        $self->{obj_esxd}->print_response(centreon::esxd::common::get_status($status) . "|Link '" . $self->{pnic} . "' not exist or down.\n");
        return ;
    }


    my $values = centreon::esxd::common::generic_performance_values_historic($self->{obj_esxd},
                        $$result[0], 
                        [{'label' => 'net.received.average', 'instances' => [$self->{pnic}]},
                         {'label' => 'net.transmitted.average', 'instances' => [$self->{pnic}]}],
                        $self->{obj_esxd}->{perfcounter_speriod});
    return if (centreon::esxd::common::performance_errors($self->{obj_esxd}, $values) == 1);

    my $traffic_in = centreon::esxd::common::simplify_number(centreon::esxd::common::convert_number($values->{$self->{obj_esxd}->{perfcounter_cache}->{'net.received.average'}->{'key'} . ":" . $self->{pnic}}[0]));    
    my $traffic_out = centreon::esxd::common::simplify_number(centreon::esxd::common::convert_number($values->{$self->{obj_esxd}->{perfcounter_cache}->{'net.transmitted.average'}->{'key'} . ":" . $self->{pnic}}[0]));
    my $status = 0; # OK
    my $output = '';
    
    if (($traffic_in / 1024 * 8 * 100 / $pnic_def{$self->{pnic}}) >= $self->{warn} || ($traffic_out / 1024 * 8 * 100 / $pnic_def{$self->{pnic}}) >= $self->{warn}) {
        $status = centreon::esxd::common::errors_mask($status, 'WARNING');
    }
    if (($traffic_in / 1024 * 8 * 100 / $pnic_def{$self->{pnic}}) >= $self->{crit} || ($traffic_out / 1024 * 8 * 100 / $pnic_def{$self->{pnic}}) >= $self->{crit}) {
        $status = centreon::esxd::common::errors_mask($status, 'CRITICAL');
    }

    $output = "Traffic In : " . centreon::esxd::common::simplify_number($traffic_in / 1024 * 8) . " Mb/s (" . centreon::esxd::common::simplify_number($traffic_in / 1024 * 8 * 100 / $pnic_def{$self->{pnic}}) . " %), Out : " . centreon::esxd::common::simplify_number($traffic_out / 1024 * 8) . " Mb/s (" . centreon::esxd::common::simplify_number($traffic_out / 1024 * 8 * 100 / $pnic_def{$self->{pnic}}) . " %)";
    $output .= "|traffic_in=" . ($traffic_in * 1024 * 8) . "b/s traffic_out=" . (($traffic_out * 1024 * 8)) . "b/s";

    $self->{obj_esxd}->print_response(centreon::esxd::common::get_status($status) . "|$output\n");
}

1;
