#
# Copyright 2021 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and application monitoring for
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package storage::hp::3par::ssh::mode::components::sensor;

use strict;
use warnings;
use centreon::plugins::misc;

sub load {
    my ($self) = @_;

    #Node 0
    #---------
    #
    #------Measurement------ -Reading- -Lo_Limit- -Hi_Limit- -----Status-----
    #                Ambient      21 C        5 C       40 C Within Tolerance
    #               Midplane      23 C       10 C       50 C Within Tolerance
    #            PCM 0 inlet      27 C       10 C       50 C Within Tolerance
    #  SBB Canister 1 memory      42 C        5 C       82 C Within Tolerance
    #             PCM 0 (5V)    5.19 V        ---        --- Within Tolerance
    #        PCM 0 (40A Max)    2.77 A        ---        --- Within Tolerance
    #
    #Node 1
    #---------
    #
    #------Measurement------ -Reading- -Lo_Limit- -Hi_Limit- -----Status-----
    #                Ambient      21 C        5 C       40 C Within Tolerance
    #               Midplane      23 C       10 C       50 C Within Tolerance
    #            PCM 0 inlet      27 C       10 C       50 C Within Tolerance
    #          PCM 0 hotspot      21 C       10 C       65 C Within Tolerance
    #         Node Input PWR    87.6 W      0.0 W    264.0 W Within Tolerance
    push @{$self->{commands}}, 'echo "===shownodeenv==="', 'shownodeenv';
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking sensors");
    $self->{components}->{sensor} = { name => 'sensors', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'sensor'));

    return if ($self->{results} !~ /===shownodeenv===.*?\n(.*?)(===|\Z)/msi);
    my $content = $1;
    my $unit_new_perf = { A => 'current.ampere', V => 'voltage.volt', W => 'power.watt', C => 'temperature.celsius' };

    while ($content =~ /^Node\s+(\d+)(.*?)(?=\nNode|\Z$)/msg) {
        my ($node_id, $measures) = ($1, $2);

        my @lines = split /\n/, $measures;
        foreach (@lines) {
            next if (!/^(.*?)\s+(\S+)\s+([CWAV])\s+(\S+\s+[CWAV]|---)\s+(\S+\s+[CWAV]|---)\s+/);
            my ($name, $reading, $unit, $lo_limit, $hi_limit)  = (centreon::plugins::misc::trim($1), $2, $3, $4, $5);
            my $instance = 'node' . $node_id . '.' . $name;

            next if ($self->check_filter(section => 'sensor', instance => $instance));
            $self->{components}->{sensor}->{total}++;

            $self->{output}->output_add(long_msg => sprintf("sensor '%s' on node '%s' is %s %s [instance: %s]",
                                        $name, $node_id, $reading, $unit, $instance)
                                        );
            
            my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'sensor', instance => $instance, value => $reading);
            $lo_limit = ($lo_limit =~ s/.*?(\d+(\.\d+)?).*/$1/) ? $lo_limit : undef;
            $hi_limit = ($hi_limit =~ s/.*?(\d+(\.\d+)?).*/$1/) ? $hi_limit : undef;  
            if ($checked == 0 && (defined($lo_limit) || defined($hi_limit))) {
                my $warn_th = '';
                my $crit_th = (defined($lo_limit) ? $lo_limit : '~') . ':' . (defined($hi_limit) ? $hi_limit : '~');
                $self->{perfdata}->threshold_validate(label => 'warning-sensor-instance-' . $instance, value => $warn_th);
                $self->{perfdata}->threshold_validate(label => 'critical-sensor-instance-' . $instance, value => $crit_th);

                $exit = $self->{perfdata}->threshold_check(
                    value => $reading,
                    threshold => [ { label => 'critical-sensor-instance-' . $instance, exit_litteral => 'critical' },
                                   { label => 'warning-sensor-instance-' . $instance, exit_litteral => 'warning' } ]);
                $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-sensor-instance-' . $instance);
                $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-sensor-instance-' . $instance);
            }

            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Sensor '%s' on node '%s' is %s %s ", $name, $node_id, $reading, $unit));
            }
            $self->{output}->perfdata_add(
                label => 'sensor', unit => $unit,
                nlabel => 'hardware.sensor.' . $unit_new_perf->{$unit},
                instances => ['node' . $node_id, $name],
                value => $reading,
                warning => $warn,
                critical => $crit,
            );
        }
    }
}

1;
