package hardware::server::lenovo::xcc::snmp::mode::components::cpu;
use strict;
use warnings FATAL => 'all';

use strict;
use warnings;
use centreon::plugins::misc;

my $mapping = {
    cpuStatus       => { oid => '.1.3.6.1.4.1.19046.11.1.1.5.20.1.11' },
    cpuString       => { oid => '.1.3.6.1.4.1.19046.11.1.1.5.20.1.2' },
};

my $oid_cpuEntry = '.1.3.6.1.4.1.19046.11.1.1.5.20.1';

sub load {
    my ($self) = @_;

    push @{$self->{request}}, { oid => $oid_cpuEntry };
}
sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking cpu");
    $self->{components}->{cpu} = { name => 'cpu', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'cpu'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_cpuEntry}})) {

        next if ($oid !~ /^$mapping->{cpuString}->{oid}\.(.*)$/);

        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_cpuEntry}, instance => $instance);
        next if ($self->check_filter(section => 'cpu', instance => $instance));
        $result->{cpuStatus} = centreon::plugins::misc::trim($result->{cpuStatus});
        $self->{components}->{cpu}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("'%s' status is %s [instance: %s].",
                                    $result->{cpuString}, $result->{cpuStatus}, $instance));

        my $exit = $self->get_severity(label => 'default', section => 'default', value => $result->{cpuStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("'%s' cpu status for '%s'", $result->{cpuStatus}, $result->{cpuString}));
        }
    }
}
1;