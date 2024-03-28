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

package os::linux::exporter::mode::cpudetailed;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::statefile;
use centreon::common::monitoring::openmetrics::scrape;

sub custom_cpu_calc {
    my ($self, %options) = @_;

    return -10 if (!defined($options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref}}));
    if (!defined($options{old_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref}})) {
        $self->{error_msg} = "Buffer creation";
        return -1;
    }

    if (!defined($self->{instance_mode}->{total_cpu})) {
        $self->{instance_mode}->{total_cpu} = 0;        
        foreach (keys %{$options{new_datas}}) {
            if (/$self->{instance}_/) {
                my $new_total = $options{new_datas}->{$_};
                next if (!defined($options{old_datas}->{$_}));
                my $old_total = $options{old_datas}->{$_};

                my $diff_total = $new_total - $old_total;
                if ($diff_total < 0) {
                    $self->{instance_mode}->{total_cpu} += $old_total;
                } else {
                    $self->{instance_mode}->{total_cpu} += $diff_total;
                }
            }
        }
    }

    if ($self->{instance_mode}->{total_cpu} <= 0) {
        $self->{error_msg} = "counter not moved";
        return -12;
    }
    
    if ($options{old_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref}} >
        $options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref}}) {
        $options{old_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref}} = 0;
    }
    $self->{result_values}->{prct_used} = 
        ($options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref}} - 
        $options{old_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref}}) * 100 /
        $self->{instance_mode}->{total_cpu};
    
    return 0;
}

sub prefix_cpu_output {
    my ($self, %options) = @_;

    return 'CPU Usage: ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name => 'global',
            type => 0,
            cb_prefix_output => 'prefix_cpu_output',
            skipped_code => { -10 => 1 }
        }
    ];

    foreach ("idle", "iowait", "irq", "nice", "softirq", "steal", "system", "user") {
        push @{$self->{maps_counters}->{global} }, {
            label => $_,
            nlabel => 'cpu.' . $_ . '.utilization.percentage',
            set => {
                key_values => [],
                closure_custom_calc => $self->can('custom_cpu_calc'),
                closure_custom_calc_extra_options => {
                    label_ref => $_
                },
                manual_keys => 1, 
                threshold_use => 'prct_used',
                output_use => 'prct_used',
                output_template => ucfirst($_) . ' %.2f %%',
                perfdatas => [
                    {
                        value => 'prct_used',
                        template => '%.2f',
                        min => 0 ,
                        max => 100,
                        unit => '%'
                    }
                ]
            }
        }
    }
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

    foreach my $data (@{$raw_metrics->{node_cpu_seconds_total}->{data}}) {
        $self->{global}->{$data->{dimensions}->{mode}} += $data->{value};
    }
    
    my $cpu_count = scalar(@{$raw_metrics->{node_cpu_seconds_total}->{data}}) / 8;
    foreach (keys %{$self->{global}}) {
        $self->{global}->{$_} /= $cpu_count;
    }
}

1;

__END__

=head1 MODE

Check CPU detailed usage.

=over 8

=item B<--warning-*> B<--critical-*>

Warning threshold.

Can be: 'user', 'nice', 'system', 'idle', 'iowait', '"irq"', 'softirq', 'steal'.

=back

=cut