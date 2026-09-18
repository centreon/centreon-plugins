package hardware::sensors::hwgste::snmp::mode::components::co2;

use strict;
use warnings;

use hardware::sensors::hwgste::snmp::mode::components::resources qw($mapping);

sub load {}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking co2");
    $self->{components}->{co2} = {
        name  => 'co2',
        total => 0,
        skip  => 0
    };

    return if ($self->check_filter(section => 'co2'));

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
        # STE2 Plus:
        # CO2 sensors have:
        #   unit = 0  => ''
        #   name contains CO2
        #
        next if (
            !defined($result->{sensUnit})
            || $result->{sensUnit} ne ''
        );

        next if (
            !defined($result->{sensName})
            || $result->{sensName} !~ /CO2/i
        );

        next if (
            $self->check_filter(
                section  => 'co2',
                instance => $instance
            )
        );

        $self->{components}->{co2}->{total}++;

        #
        # STE2 returns value * 10
        #
        if (
            defined($result->{sensValue})
            && $result->{sensValue} =~ /^-?\d+(?:\.\d+)?$/
        ) {
            $result->{sensValue} /= 10;
        }

        $self->{output}->output_add(
            long_msg => sprintf(
                "co2 '%s' state is '%s' [instance: %s, value: %s ppm]",
                $result->{sensName},
                $result->{sensState},
                $instance,
                $result->{sensValue}
            )
        );

        my $exit = $self->get_severity(
            section => 'co2',
            label   => 'default',
            instance => $instance,
            value    => $result->{sensState}
        );

        if (
            !$self->{output}->is_status(
                value    => $exit,
                compare  => 'ok',
                litteral => 1
            )
        ) {
            $self->{output}->output_add(
                severity  => $exit,
                short_msg => sprintf(
                    "co2 '%s' state is '%s'",
                    $result->{sensName},
                    $result->{sensState}
                )
            );
        }

        if (
            defined($result->{sensValue})
            && $result->{sensValue} =~ /^-?\d+(?:\.\d+)?$/
        ) {
            my ($exit2, $warn, $crit, $checked) =
                $self->get_severity_numeric(
                    section  => 'co2',
                    instance => $instance,
                    value    => $result->{sensValue}
                );

            if (
                !$self->{output}->is_status(
                    value    => $exit2,
                    compare  => 'ok',
                    litteral => 1
                )
            ) {
                $self->{output}->output_add(
                    severity => $exit2,
                    short_msg => sprintf(
                        "co2 '%s' value is %s ppm",
                        $result->{sensName},
                        $result->{sensValue}
                    )
                );
            }

            $self->{output}->perfdata_add(
                label     => 'sensor',
                unit      => 'ppm',
                nlabel    => 'hardware.sensor.co2.ppm',
                instances => $result->{sensName},
                value     => $result->{sensValue},
                warning   => $warn,
                critical  => $crit,
                min       => 0
            );
        }
    }
}

1;
