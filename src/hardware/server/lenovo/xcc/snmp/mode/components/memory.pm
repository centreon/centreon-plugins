package hardware::server::lenovo::xcc::snmp::mode::components::memory;
use strict;
use warnings;

use strict;
use warnings;
use centreon::plugins::misc;

my $mapping = {
    memoryStatus       => { oid => '.1.3.6.1.4.1.19046.11.1.1.5.21.1.8' },
    memoryString       => { oid => '.1.3.6.1.4.1.19046.11.1.1.5.21.1.2' },
};

my $oid_memoryEntry = '.1.3.6.1.4.1.19046.11.1.1.5.21.1';

sub load {
    my ($self) = @_;

    push @{$self->{request}}, { oid => $oid_memoryEntry };
}
sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking memory");
    $self->{components}->{memory} = { name => 'memory', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'memory'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_memoryEntry}})) {

        next if ($oid !~ /^$mapping->{memoryString}->{oid}\.(.*)$/);

        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_memoryEntry}, instance => $instance);
        next if ($self->check_filter(section => 'memory', instance => $instance));
        $result->{memoryStatus} = centreon::plugins::misc::trim($result->{memoryStatus});
        $self->{components}->{memory}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("'%s' status is %s [instance: %s].",
                                    $result->{memoryString}, $result->{memoryStatus}, $instance));

        my $exit = $self->get_severity(label => 'default', section => 'default', value => $result->{memoryStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("'%s' memory status for '%s'", $result->{memoryStatus}, $result->{memoryString}));
        }
    }
}
1;