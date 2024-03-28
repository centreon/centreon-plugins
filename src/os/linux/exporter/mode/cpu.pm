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

package os::linux::exporter::mode::cpu;

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
        filter_metrics => 'node_cpu_seconds_total',
        %options
    );

    # node_cpu_seconds_total{cpu="0",mode="idle"} 3.05553941e+06
    # node_cpu_seconds_total{cpu="0",mode="iowait"} 3289.19
    # node_cpu_seconds_total{cpu="0",mode="irq"} 2633.34
    # node_cpu_seconds_total{cpu="0",mode="nice"} 112.39
    # node_cpu_seconds_total{cpu="0",mode="softirq"} 1129.17
    # node_cpu_seconds_total{cpu="0",mode="steal"} 0
    # node_cpu_seconds_total{cpu="0",mode="system"} 8463.86
    # node_cpu_seconds_total{cpu="0",mode="user"} 14164.45
    # node_cpu_seconds_total{cpu="1",mode="idle"} 3.0536849e+06
    # node_cpu_seconds_total{cpu="1",mode="iowait"} 3224.31
    # node_cpu_seconds_total{cpu="1",mode="irq"} 2232.46
    # node_cpu_seconds_total{cpu="1",mode="nice"} 297.12
    # node_cpu_seconds_total{cpu="1",mode="softirq"} 711.47
    # node_cpu_seconds_total{cpu="1",mode="steal"} 0
    # node_cpu_seconds_total{cpu="1",mode="system"} 8869.22
    # node_cpu_seconds_total{cpu="1",mode="user"} 18244.22
        
    my $total_idle;

    foreach my $data (@{$raw_metrics->{node_cpu_seconds_total}->{data}}) {
        next if ($data->{dimensions}->{mode} !~ /idle/);

        $self->{cpu_core}->{$data->{dimensions}->{cpu}}->{idle} = $data->{value};
        $self->{cpu_core}->{$data->{dimensions}->{cpu}}->{display} = $data->{dimensions}->{cpu};

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

=over 8

=item B<--warning-*> B<--critical-*>

Warning threshold.

Can be: 'average' or 'core'.

=back

=cut