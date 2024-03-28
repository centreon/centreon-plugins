#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package os::windows::exporter::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::statefile;
use centreon::common::monitoring::openmetrics::scrape;

sub custom_usage_avg_calc {
    my ($self, %options) = @_;

    return -10 if (!defined($options{new_datas}->{$self->{instance} . '_avg_idle'}));
    if (!defined($options{old_datas}->{$self->{instance} . '_avg_idle'})) {
        $self->{error_msg} = "Buffer creation";
        return -1;
    }

    my $diff = $options{new_datas}->{$self->{instance} . '_avg_idle'} - $options{old_datas}->{$self->{instance} . '_avg_idle'};
    $self->{result_values}->{avg_usage} = 100 - ( 100 * $diff / $options{delta_time} );
    $self->{result_values}->{avg_usage} = 0 if ($self->{result_values}->{avg_usage} < 0);
    $self->{result_values}->{count} = $options{new_datas}->{$self->{instance} . '_count'};

    return 0;
}

sub custom_usage_avg_output {
    my ($self, %options) = @_;

    return sprintf(
        "%s CPU(s) average usage is %.2f %%",
            $self->{result_values}->{count},
            $self->{result_values}->{avg_usage}
    );
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    return -10 if (!defined($options{new_datas}->{$self->{instance} . '_idle'}));
    if (!defined($options{old_datas}->{$self->{instance} . '_idle'})) {
        $self->{error_msg} = "Buffer creation";
        return -1;
    }

    my $diff = $options{new_datas}->{$self->{instance} . '_idle'} - $options{old_datas}->{$self->{instance} . '_idle'};
    $self->{result_values}->{usage} = 100 - ( 100 * $diff / $options{delta_time} );
    $self->{result_values}->{usage} = 0 if ($self->{result_values}->{usage} < 0);
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};

    return 0;
}

sub prefix_cpu_core_output {
    my ($self, %options) = @_;
    
    return "CPU '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name => 'global',
            type => 0,
            skipped_code => { -10 => 1 }
        },
        {
            name => 'cpu_core',
            type => 1,
            cb_prefix_output => 'prefix_cpu_core_output',
            skipped_code => { -10 => 1 }
        }
    ];

    $self->{maps_counters}->{global} = [
        {
            label => 'average',
            nlabel => 'cpu.utilization.percentage', set => {
                key_values => [
                    { name => 'avg_idle', diff => 1 },
                    { name => 'count'}
                ],
                closure_custom_calc => $self->can('custom_usage_avg_calc'),
                closure_custom_output => $self->can('custom_usage_avg_output'), 
                threshold_use => 'avg_usage',
                perfdatas => [
                    {
                        value => 'avg_usage',
                        template => '%.2f',
                        min => 0,
                        max => 100,
                        unit => '%'
                    }
                ]
            }
        }
    ];

    $self->{maps_counters}->{cpu_core} = [
        { 
            label => 'core',
            nlabel => 'core.cpu.utilization.percentage',
            set => {
                key_values => [
                    { name => 'idle', diff => 1 },
                    { name => 'display' }
                ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                output_template => 'usage : %.2f %%',
                output_use => 'usage',
                threshold_use => 'usage',
                perfdatas => [
                    {
                        value => 'usage',
                        template => '%.2f',
                        min => 0,
                        max => 100,
                        unit => '%',
                        label_extra_instance => 1,
                        instance_use => 'display'
                    }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {});

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;
  
    $self->{global} = {
        avg_idle => 0,
        count => 0
    };
    $self->{cpu_core} = {};

    $self->{cache_name} = 'exporter_' . $options{custom}->get_uuid()  . '_' . $self->{mode};

    my $raw_metrics = centreon::common::monitoring::openmetrics::scrape::parse(
        filter_metrics => 'windows_cpu_time_total',
        %options
    );

    # windows_cpu_time_total{core="0,0",mode="dpc"} 6.734375
    # windows_cpu_time_total{core="0,0",mode="idle"} 227003.703125
    # windows_cpu_time_total{core="0,0",mode="interrupt"} 11.46875
    # windows_cpu_time_total{core="0,0",mode="privileged"} 2108.25
    # windows_cpu_time_total{core="0,0",mode="user"} 2331.109375
    # windows_cpu_time_total{core="0,1",mode="dpc"} 7.5625
    # windows_cpu_time_total{core="0,1",mode="idle"} 226734.203125
    # windows_cpu_time_total{core="0,1",mode="interrupt"} 13.125
    # windows_cpu_time_total{core="0,1",mode="privileged"} 2187.234375
    # windows_cpu_time_total{core="0,1",mode="user"} 2521.46875
        
    my $total_idle;

    foreach my $data (@{$raw_metrics->{windows_cpu_time_total}->{data}}) {
        next if ($data->{dimensions}->{mode} !~ /idle/);
        my $core = $data->{dimensions}->{core};
        $core =~ s/,/_/g;

        $self->{cpu_core}->{$core}->{idle} = $data->{value};
        $self->{cpu_core}->{$core}->{display} = $core;

        $total_idle += $data->{value};
    }

    my $cpu_count = keys %{$self->{cpu_core}};
    $self->{global}->{avg_idle} = $total_idle / $cpu_count;
    $self->{global}->{count} = $cpu_count;

    if (scalar(keys %{$self->{cpu_core}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check CPU usage globally and per cores.

Uses metrics from https://github.com/prometheus-community/windows_exporter/blob/master/docs/collector.cpu.md.

=over 8

=item B<--warning-*> B<--critical-*>

Warning threshold.

Can be: 'average' or 'core'.

=back

=cut