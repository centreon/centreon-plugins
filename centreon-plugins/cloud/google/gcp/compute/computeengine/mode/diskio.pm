#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package cloud::google::gcp::compute::computeengine::mode::diskio;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use cloud::google::gcp::custom::misc;

sub prefix_metric_output {
    my ($self, %options) = @_;
    
    return "Instance '" . $options{instance_value}->{display} . "' " . $options{instance_value}->{stat} . " ";
}

sub custom_metric_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{stat} = $options{new_datas}->{$self->{instance} . '_stat'};
    $self->{result_values}->{metric_perf} = $options{extra_options}->{metric_perf};
    $self->{result_values}->{metric_label} = $options{extra_options}->{metric_label};
    $self->{result_values}->{metric_name} = $options{extra_options}->{metric_name};
    $self->{result_values}->{metric} = $options{extra_options}->{metric};
    $self->{result_values}->{timeframe} = $options{new_datas}->{$self->{instance} . '_timeframe'};
    $self->{result_values}->{value} = $options{new_datas}->{$self->{instance} . '_' . $self->{result_values}->{metric} . '_' . $self->{result_values}->{stat}};
    $self->{result_values}->{value_per_sec} = $self->{result_values}->{value} / $self->{result_values}->{timeframe};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub custom_usage_threshold {
    my ($self, %options) = @_;

    my $exit = $self->{perfdata}->threshold_check(
        value => defined($self->{instance_mode}->{option_results}->{per_sec}) ?  $self->{result_values}->{value_per_sec} : $self->{result_values}->{value},
        threshold => [ { label => 'critical-' . $self->{result_values}->{metric_label} . "-" . $self->{result_values}->{stat}, exit_litteral => 'critical' },
                       { label => 'warning-' . $self->{result_values}->{metric_label} . "-" . $self->{result_values}->{stat}, exit_litteral => 'warning' } ]
    );
    return $exit;
}

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    my $extra_label = '';
    $extra_label = '_' . lc($self->{result_values}->{display}) if (!defined($options{extra_instance}) || $options{extra_instance} != 0);

    $self->{output}->perfdata_add(
        label => $self->{result_values}->{metric_perf} . "_" . $self->{result_values}->{stat} . $extra_label,
        unit => defined($self->{instance_mode}->{option_results}->{per_sec}) ? 'B/s' : 'B',
        value => sprintf("%d", defined($self->{instance_mode}->{option_results}->{per_sec}) ? $self->{result_values}->{value_per_sec} : $self->{result_values}->{value}),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{result_values}->{metric_label} . "-" . $self->{result_values}->{stat}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{result_values}->{metric_label} . "-" . $self->{result_values}->{stat}),
        min => 0
    );
}

sub custom_usage_output {
    my ($self, %options) = @_;
    my $msg = "";

    if (defined($self->{instance_mode}->{option_results}->{per_sec})) {
        my ($value, $unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{value_per_sec});
        $msg = $self->{result_values}->{metric_name}  . ": " . $value . $unit . "/s"; 
    } else {
        my ($value, $unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{value});
        $msg = $self->{result_values}->{metric_name}  . ": " . $value . $unit;
    }
    return $msg;
}

sub custom_ops_threshold {
    my ($self, %options) = @_;

    my $exit = $self->{perfdata}->threshold_check(
        value => $self->{result_values}->{value},
        threshold => [ { label => 'critical-' . $self->{result_values}->{metric_label} . "-" . $self->{result_values}->{stat}, exit_litteral => 'critical' },
                       { label => 'warning-' . $self->{result_values}->{metric_label} . "-" . $self->{result_values}->{stat}, exit_litteral => 'warning' } ]
    );
    return $exit;
}

sub custom_ops_perfdata {
    my ($self, %options) = @_;

    my $extra_label = '';
    $extra_label = '_' . lc($self->{result_values}->{display}) if (!defined($options{extra_instance}) || $options{extra_instance} != 0);

    $self->{output}->perfdata_add(
        label => $self->{result_values}->{metric_perf} . "_" . $self->{result_values}->{stat} . $extra_label,
        unit => 'ops/s',
        value => sprintf("%.2f", $self->{result_values}->{value}),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{result_values}->{metric_label} . "-" . $self->{result_values}->{stat}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{result_values}->{metric_label} . "-" . $self->{result_values}->{stat}),
        min => 0
    );
}

sub custom_ops_output {
    my ($self, %options) = @_;

    my $msg = sprintf("%s: %.2f ops/s", $self->{result_values}->{metric_name}, $self->{result_values}->{value});
 
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'metric', type => 1, cb_prefix_output => 'prefix_metric_output', message_multiple => "All disk metrics are ok", skipped_code => { -10 => 1 } },
    ];

    foreach my $aggregation ('minimum', 'maximum', 'average', 'total') {
        foreach my $metric ('instance/disk/read_bytes_count', 'instance/disk/throttled_read_bytes_count',
            'instance/disk/write_bytes_count', 'instance/disk/throttled_write_bytes_count') {
            my $metric_label = cloud::google::gcp::custom::misc::format_metric_label(metric => $metric, remove => 'instance/');
            my $metric_perf = cloud::google::gcp::custom::misc::format_metric_perf(metric => $metric, remove => 'instance/');
            my $metric_name = cloud::google::gcp::custom::misc::format_metric_name(metric => $metric, remove => 'instance/');
            my $entry = { label => $metric_label . '-' . $aggregation, set => {
                                key_values => [ { name => $metric . '_' . $aggregation }, { name => 'display' },
                                    { name => 'stat' }, { name => 'timeframe' } ],
                                closure_custom_calc => $self->can('custom_metric_calc'),
                                closure_custom_calc_extra_options => { metric_perf => $metric_perf,
                                    metric_label => $metric_label, metric_name => $metric_name, metric => $metric },
                                closure_custom_output => $self->can('custom_usage_output'),
                                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
                            }
                        };
            push @{$self->{maps_counters}->{metric}}, $entry;
        }
        foreach my $metric ('instance/disk/read_ops_count', 'instance/disk/write_ops_count') {
            my $metric_label = cloud::google::gcp::custom::misc::format_metric_label(metric => $metric, remove => 'instance/');
            my $metric_perf = cloud::google::gcp::custom::misc::format_metric_perf(metric => $metric, remove => 'instance/');
            my $metric_name = cloud::google::gcp::custom::misc::format_metric_name(metric => $metric, remove => 'instance/');
            my $entry = { label => $metric_label . '-' . $aggregation, set => {
                                key_values => [ { name => $metric . '_' . $aggregation }, { name => 'display' },
                                    { name => 'stat' }, { name => 'timeframe' } ],
                                closure_custom_calc => $self->can('custom_metric_calc'),
                                closure_custom_calc_extra_options => { metric_perf => $metric_perf,
                                    metric_label => $metric_label, metric_name => $metric_name, metric => $metric },
                                closure_custom_output => $self->can('custom_ops_output'),
                                closure_custom_perfdata => $self->can('custom_ops_perfdata'),
                                closure_custom_threshold_check => $self->can('custom_ops_threshold'),
                            }
                        };
            push @{$self->{maps_counters}->{metric}}, $entry;
        }
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments => {
        "instance:s@"       => { name => 'instance' },
        "filter-metric:s"   => { name => 'filter_metric' },
        "per-sec"           => { name => 'per_sec' },
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{instance})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify --instance <name>.");
        $self->{output}->option_exit();
    }
    
    $self->{gcp_instance} = $self->{option_results}->{instance};
    $self->{gcp_timeframe} = defined($self->{option_results}->{timeframe}) ? $self->{option_results}->{timeframe} : 900;
    $self->{gcp_aggregations} = ['average'];
    if (defined($self->{option_results}->{aggregation})) {
        $self->{gcp_aggregations} = [];
        foreach my $stat (@{$self->{option_results}->{aggregation}}) {
            if ($stat ne '') {
                push @{$self->{gcp_aggregations}}, $stat;
            }
        }
    }

    foreach my $metric ('instance/disk/read_bytes_count', 'instance/disk/throttled_read_bytes_count',
        'instance/disk/write_bytes_count', 'instance/disk/throttled_write_bytes_count',
        'instance/disk/read_ops_count', 'instance/disk/write_ops_count') {
        next if (defined($self->{option_results}->{filter_metric}) && $self->{option_results}->{filter_metric} ne ''
            && $metric !~ /$self->{option_results}->{filter_metric}/);

        push @{$self->{gcp_metrics}}, $metric;
    }

    $self->{gcp_api} = "compute.googleapis.com";
}

sub manage_selection {
    my ($self, %options) = @_;

    my $metric_results;
    foreach my $instance (@{$self->{gcp_instance}}) {
        foreach my $metric (@{$self->{gcp_metrics}}) {
            ($metric_results, undef) = $options{custom}->gcp_get_metrics(
                instance => $instance,
                metric => $metric,
                api => $self->{gcp_api},
                aggregations => $self->{gcp_aggregations},
                timeframe => $self->{gcp_timeframe},
            );
            
            foreach my $aggregation (@{$self->{gcp_aggregations}}) {
                next if (!defined($metric_results->{$metric}->{lc($aggregation)}) && !defined($self->{option_results}->{zeroed}));

                $self->{metric}->{$instance . "_" . lc($aggregation)}->{display} = $metric_results->{labels}->{instance_name};
                $self->{metric}->{$instance . "_" . lc($aggregation)}->{timeframe} = $self->{gcp_timeframe};
                $self->{metric}->{$instance . "_" . lc($aggregation)}->{stat} = lc($aggregation);
                $self->{metric}->{$instance . "_" . lc($aggregation)}->{$metric . "_" . lc($aggregation)} = defined($metric_results->{$metric}->{lc($aggregation)}) ? $metric_results->{$metric}->{lc($aggregation)} : 0;
            }
        }
    }

    if (scalar(keys %{$self->{metric}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No metrics. Check your options or use --zeroed option to set 0 on undefined values');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check Compute Engine instances disk IO metrics.

Example:

perl centreon_plugins.pl --plugin=cloud::google::gcp::compute::computeengine::plugin --custommode=api --mode=diskio
--instance=mycomputeinstance --filter-metric='throttled' --aggregation='average'
--critical-disk-throttled-write-bytes-count-average='10' --verbose

Default aggregation: 'average' / All aggregations are valid.

=over 8

=item B<--instance>

Set instance name (Required).

=item B<--filter-metric>

Filter metrics (Can be: 'instance/disk/read_bytes_count', 'instance/disk/throttled_read_bytes_count',
'instance/disk/write_bytes_count', 'instance/disk/throttled_write_bytes_count',
'instance/disk/read_ops_count', 'instance/disk/write_ops_count') (Can be a regexp).

=item B<--warning-$metric$-$aggregation$>

Thresholds warning ($metric$ can be: 'disk-read-bytes-count', 'disk-throttled-read-bytes-count',
'disk-write-bytes-count', 'disk-throttled-write-bytes-count','disk-read-ops-count',
'disk-write-ops-count', $aggregation$ can be: 'minimum', 'maximum', 'average', 'total').

=item B<--critical-$metric$-$aggregation$>

Thresholds critical ($metric$ can be: 'disk-read-bytes-count', 'disk-throttled-read-bytes-count',
'disk-write-bytes-count', 'disk-throttled-write-bytes-count','disk-read-ops-count',
'disk-write-ops-count', $aggregation$ can be: 'minimum', 'maximum', 'average', 'total').

=item B<--per-sec>

Change the data to be unit/sec.

=back

=cut
