
package centreon::esxd::cmdmemvm;

use strict;
use warnings;
use centreon::esxd::common;

sub new {
    my $class = shift;
    my $self  = {};
    $self->{logger} = shift;
    $self->{obj_esxd} = shift;
    $self->{commandName} = 'memvm';
    
    bless $self, $class;
    return $self;
}

sub getCommandName {
    my $self = shift;
    return $self->{commandName};
}

sub checkArgs {
    my $self = shift;
    my ($vm, $warn, $crit) = @_;

    if (!defined($vm) || $vm eq "") {
        $self->{logger}->writeLogError("ARGS error: need vm name");
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
    $self->{lvm} = $_[0];
    $self->{warn} = (defined($_[1]) ? $_[1] : 80);
    $self->{crit} = (defined($_[2]) ? $_[2] : 90);
}

sub run {
    my $self = shift;

    if (!($self->{obj_esxd}->{perfcounter_speriod} > 0)) {
        my $status = centreon::esxd::common::errors_mask(0, 'UNKNOWN');
        $self->{obj_esxd}->print_response(centreon::esxd::common::get_status($status) . "|Can't retrieve perf counters.\n");
        return ;
    }

    my %filters = ('name' => $self->{lvm});
    my @properties = ('summary.config.memorySizeMB', 'runtime.connectionState', 'runtime.powerState');
    my $result = centreon::esxd::common::get_entities_host($self->{obj_esxd}, 'VirtualMachine', \%filters, \@properties);
    if (!defined($result)) {
        return ;
    }
    
    return if (centreon::esxd::common::vm_state($self->{obj_esxd}, $self->{lvm}, 
                                                $$result[0]->{'runtime.connectionState'}->val,
                                                $$result[0]->{'runtime.powerState'}->val) == 0);

    my $memory_size = $$result[0]->{'summary.config.memorySizeMB'} * 1024 * 1024;

    my $values = centreon::esxd::common::generic_performance_values_historic($self->{obj_esxd},
                        $$result[0], 
                        [{'label' => 'mem.active.average', 'instances' => ['']},
                         {'label' => 'mem.overhead.average', 'instances' => ['']},
                         {'label' => 'mem.vmmemctl.average', 'instances' => ['']},
                         {'label' => 'mem.consumed.average', 'instances' => ['']},
                         {'label' => 'mem.shared.average', 'instances' => ['']}],
                        $self->{obj_esxd}->{perfcounter_speriod});

    my $mem_consumed = centreon::esxd::common::simplify_number(centreon::esxd::common::convert_number($values->{$self->{obj_esxd}->{perfcounter_cache}->{'mem.consumed.average'}->{'key'} . ":"}[0]));
    my $mem_active = centreon::esxd::common::simplify_number(centreon::esxd::common::convert_number($values->{$self->{obj_esxd}->{perfcounter_cache}->{'mem.active.average'}->{'key'} . ":"}[0]));
    my $mem_overhead = centreon::esxd::common::simplify_number(centreon::esxd::common::convert_number($values->{$self->{obj_esxd}->{perfcounter_cache}->{'mem.overhead.average'}->{'key'} . ":"}[0]));
    my $mem_ballooning = centreon::esxd::common::simplify_number(centreon::esxd::common::convert_number($values->{$self->{obj_esxd}->{perfcounter_cache}->{'mem.vmmemctl.average'}->{'key'} . ":"}[0]));
    my $mem_shared = centreon::esxd::common::simplify_number(centreon::esxd::common::convert_number($values->{$self->{obj_esxd}->{perfcounter_cache}->{'mem.shared.average'}->{'key'} . ":"}[0]));
    my $status = 0; # OK
    my $output = '';
    
    if ($mem_consumed * 100 / ($memory_size / 1024) >= $self->{warn}) {
        $status = centreon::esxd::common::errors_mask($status, 'WARNING');
    }
    if ($mem_consumed * 100 / ($memory_size / 1024) >= $self->{crit}) {
        $status = centreon::esxd::common::errors_mask($status, 'CRITICAL');
    }

    $output = "Memory usage : " . centreon::esxd::common::simplify_number($mem_consumed / 1024 / 1024) . " Go - size : " . centreon::esxd::common::simplify_number($memory_size / 1024 / 1024 / 1024) . " Go - percent : " . centreon::esxd::common::simplify_number($mem_consumed * 100 / ($memory_size / 1024)) . " %";
    $output .= "|usage=" . ($mem_consumed * 1024) . "o;" . centreon::esxd::common::simplify_number($memory_size * $self->{warn} / 100, 0) . ";" . centreon::esxd::common::simplify_number($memory_size * $self->{crit} / 100, 0) . ";0;" . ($memory_size) . " size=" . $memory_size . "o" . " overhead=" . ($mem_overhead * 1024) . "o" . " ballooning=" . ($mem_ballooning * 1024) . "o" . " shared=" . ($mem_shared * 1024) . "o" . " active=" . ($mem_active * 1024) . "o" ;

    $self->{obj_esxd}->print_response(centreon::esxd::common::get_status($status) . "|$output\n");
}

1;
