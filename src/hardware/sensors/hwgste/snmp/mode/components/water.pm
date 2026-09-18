package hardware::sensors::hwgste::snmp::mode::components::water;

use strict;
use warnings;

use hardware::sensors::hwgste::snmp::mode::components::resources qw($mapping);

sub load {}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking water");

    $self->{components}->{water} = {
        name  => 'water',
        total => 0,
        skip  => 0
    };

    return if ($self->check_filter(section => 'water'));

    foreach my $oid (
        $self->{snmp}->oid_lex_sort(
            keys %{
                $self->{results}->{
                    $mapping->{branch_sensors}->{$self->{branch}}
                }
            }
        )
    ) {
        next if (
            $oid !~
            /^$mapping->{$self->{branch}}->{sensState}->{oid}\.(.*)$/
        );

        my $instance = $1;

        my $result = $self->{snmp}->map_instance(
            mapping => $mapping->{$self->{branch}},
            results => $self->{results}->{
                $mapping->{branch_sensors}->{$self->{branch}}
            },
            instance => $instance
        );

        #
        # STE2 Plus water leak sensor:
        # unit = 5 => water
        #
        next if (
            !defined($result->{sensUnit})
            || $result->{sensUnit} ne 'water'
        );

        #
        # Accept common naming conventions
        #
        next if (
            !defined($result->{sensName})
            || $result->{sensName} !~ /(?:WATER|FLOOD|LEAK)/i
        );

        next if (
            $self->check_filter(
                section  => 'water',
                instance => $instance
            )
        );

        $self->{components}->{water}->{total}++;

        my $value = defined($result->{sensValue})
            ? $result->{sensValue}
            : 'unknown';

        $self->{output}->output_add(
            long_msg => sprintf(
                "water sensor '%s' state is '%s' [instance: %s, value: %s]",
                $result->{sensName},
                $result->{sensState},
                $instance,
                $value
            )
        );

        #
        # Water leak detector is binary:
        # normal => OK
        # anything else => CRITICAL
        #
        my $exit = 'OK';

        if ($result->{sensState} 
