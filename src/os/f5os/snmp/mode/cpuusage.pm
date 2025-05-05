#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package os::f5os::snmp::mode::cpuusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'cpu_avg', type => 0 },
        { name => 'cpu_core', type => 1, cb_prefix_output => 'prefix_cpu_output' },
    ];

    $self->{maps_counters}->{cpu_avg} = [
        { label => 'average', nlabel => 'cpu.usage.percent', set => {
                key_values => [ { name => 'average' } ],
                output_template => 'CPU(s) average usage is: %.2f %%',
                perfdatas => [
                    { label => 'total_cpu_avg', value => 'average', template => '%.2f',
                      min => 0, max => 100, unit => '%' },
                ]
            }
        }
    ];

    $self->{maps_counters}->{cpu_core} = [
        { label => 'core-current', nlabel => 'cpu.core.current.usage.percent', set => {
                key_values => [ { name => 'CoreCurrent' }, { name => 'display' } ],
                output_template => 'CPU Usage Current : %s %%', output_error_template => "CPU Usage Current : %s",
                perfdatas => [
                    { value => 'CoreCurrent',  template => '%s',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'core-avg-5s', nlabel => 'cpu.core.usage.avg.5s.percent', set => {
                key_values => [ { name => 'CoreTotal5secAvg' }, { name => 'display' } ],
                output_template => 'CPU Usage 5sec : %s %%', output_error_template => "CPU Usage 5sec : %s",
                perfdatas => [
                    { value => 'CoreTotal5secAvg',  template => '%s',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'core-avg-1m', nlabel => 'cpu.core.usage.avg.1m.percent', set => {
                key_values => [ { name => 'CoreTotal1minAvg' }, { name => 'display' } ],
                output_template => 'CPU Usage 1min : %s %%', output_error_template => "CPU Usage 1min : %s",
                perfdatas => [
                    { value => 'CoreTotal1minAvg',  template => '%s',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'core-avg-5m', nlabel => 'cpu.core.usage.avg.5m.percent', set => {
                key_values => [ { name => 'CoreTotal5minAvg' }, { name => 'display' } ],
                output_template => 'CPU Usage 5min : %s %%', output_error_template => "CPU Usage 5min : %s",
                perfdatas => [
                    { value => 'CoreTotal5minAvg',  template => '%s',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_cpu_output {
    my ($self, %options) = @_;

    return "CPU '" . $options{instance_value}->{display} . "' "
        unless $self->{output}->is_verbose();

    return "CPU '" . $options{instance_value}->{display} . " [" .  $options{instance_value}->{CoreName}. "]' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1 );
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'include-name:s' => { name => 'include_name', default => '' },
        'include-id:s' => { name => 'include_id', default => '' },
        'exclude-name:s' => { name => 'exclude_name', default => '' },
        'exclude-id:s' => { name => 'exclude_id', default => '' },
    });

    return $self;
}

my $mapping = {
    CoreIndex                   => { oid => '.1.3.6.1.4.1.12276.1.2.1.1.3.1.1' },
    CoreName                    => { oid => '.1.3.6.1.4.1.12276.1.2.1.1.3.1.2' },
    CoreCurrent                 => { oid => '.1.3.6.1.4.1.12276.1.2.1.1.3.1.3' },
    CoreTotal5secAvg            => { oid => '.1.3.6.1.4.1.12276.1.2.1.1.3.1.4' },
    CoreTotal1minAvg            => { oid => '.1.3.6.1.4.1.12276.1.2.1.1.3.1.5' },
    CoreTotal5minAvg            => { oid => '.1.3.6.1.4.1.12276.1.2.1.1.3.1.6' },
};
my $oid_cpuCoreStatsEntry = '.1.3.6.1.4.1.12276.1.2.1.1.3.1';

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{snmp}->get_table(
        oid => $oid_cpuCoreStatsEntry,
        nothing_quit => 1
    );

    $self->{cpu_core} = {};
    $self->{cpu_avg} = {};

    my $cpu = 0;
    foreach my $oid (keys %$results) {
        next if ($oid !~ /^$mapping->{CoreIndex}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $results, instance => $instance);

        if ($self->{option_results}->{include_name} ne '' || $self->{option_results}->{include_id} ne '') {
            my $whitelist = 0;
            $whitelist = 1 if $self->{option_results}->{include_name} ne '' && $result->{CoreName} =~ /$self->{option_results}->{include_name}/;
            $whitelist = 1 if $self->{option_results}->{include_id} ne '' && $result->{CoreIndex} =~ /$self->{option_results}->{include_id}/;

            if ($whitelist == 0) {
                $self->{output}->output_add(long_msg => "skipping  '" . $result->{CoreIndex} .'-'. $result->{CoreName}. "': no including filter match.", debug => 1);
                next
            }
        }

        if (($self->{option_results}->{exclude_name} ne '' && $result->{CoreName} =~ /$self->{option_results}->{exclude_name}/) ||
            ($self->{option_results}->{exclude_id} ne '' && $result->{CoreIndex} =~ /$self->{option_results}->{exclude_id}/)) {
            $self->{output}->output_add(long_msg => "skipping  '" . $result->{CoreIndex} .'-'. $result->{CoreName}. "': excluding filter match.", debug => 1);
            next
        }

        $self->{cpu_core}->{$result->{CoreIndex}} = {
            display => $result->{CoreIndex},
            %$result
        };

        $cpu += $result->{CoreCurrent};
    }

    my $num_core = scalar(keys %{$self->{cpu_core}});
    if ($num_core <= 0) {
        $self->{output}->add_option_msg(short_msg => "No CPU found.");
        $self->{output}->option_exit();
    } else {
        $self->{cpu_avg}->{average} = $cpu / $num_core;
    }
}

1;

__END__

=head1 MODE

Check CPU usages.

    - cpu.core.current.usage.percent       CPU core current utilization percentage.
    - cpu.core.usage.avg.5s.percent        CPU core utilization average over the last five second.
    - cpu.core.usage.avg.1m.percent        CPU core utilization average over the last one minute.
    - cpu.core.usage.avg.5m.percent        CPU core utilization average over the last five minute.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Can be : core-current, core-avg-5s, core-avg-1m, core-avg-5m
Example : --filter-counters='^core-current$'

=item B<--include-id>

Filter by CPU id (regexp can be used).
Example : --include-id='2'

=item B<--include-name>

Filter by CPU name (regexp can be used).
Example : --include-name='cpu02'

=item B<--exclude-id>

Exclude CPU id from check (regexp can be used).
Example : --exclude-id='21'

=item B<--exclude-name>

Exclude CPU name from check (regexp can be used).
Example : --exclude-name='cpu02'

=item B<--warning-core-current>

Threshold in percentage.

=item B<--critical-core-current>

Threshold in percentage.

=item B<--warning-core-avg-5s>

Threshold in percentage.

=item B<--critical-core-avg-5s>

Threshold in percentage.

=item B<--warning-core-avg-1m>

Threshold in percentage.

=item B<--critical-core-avg-1m>

Threshold in percentage.

=item B<--warning-core-avg-5m>

Threshold in percentage.

=item B<--critical-core-avg-5m>

Threshold in percentage.

=back

=cut
