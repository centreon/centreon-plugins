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

package cloud::azure::compute::virtualmachine::mode::diskio;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_metric_output {
    my ($self, %options) = @_;
    
    return "Resource '" . $options{instance_value}->{display} . "' " . $options{instance_value}->{stat} . " ";
}

sub custom_metric_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{stat} = $options{new_datas}->{$self->{instance} . '_stat'};
    $self->{result_values}->{metric_perf} = lc($options{extra_options}->{metric_perf});
    $self->{result_values}->{metric_label} = lc($options{extra_options}->{metric_label});
    $self->{result_values}->{metric_name} = $options{extra_options}->{metric_name};
    $self->{result_values}->{timeframe} = $options{new_datas}->{$self->{instance} . '_timeframe'};
    $self->{result_values}->{value} = $options{new_datas}->{$self->{instance} . '_' . $self->{result_values}->{metric_perf} . '_' . $self->{result_values}->{stat}};
    $self->{result_values}->{value_per_sec} = $self->{result_values}->{value} / $self->{result_values}->{timeframe};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub custom_metric_threshold {
    my ($self, %options) = @_;

    my $exit = $self->{perfdata}->threshold_check(value => defined($self->{instance_mode}->{option_results}->{per_sec}) ?  $self->{result_values}->{value_per_sec} : $self->{result_values}->{value},
                                                  threshold => [ { label => 'critical-' . $self->{result_values}->{metric_label} . "-" . $self->{result_values}->{stat}, exit_litteral => 'critical' },
                                                                 { label => 'warning-' . $self->{result_values}->{metric_label} . "-" . $self->{result_values}->{stat}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    my $extra_label = '';
    $extra_label = '_' . lc($self->{result_values}->{display}) if (!defined($options{extra_instance}) || $options{extra_instance} != 0);

    $self->{output}->perfdata_add(label => $self->{result_values}->{metric_perf} . "_" . $self->{result_values}->{stat} . $extra_label,
				                  unit => defined($self->{instance_mode}->{option_results}->{per_sec}) ? 'B/s' : 'B',
                                  value => sprintf("%.2f", defined($self->{instance_mode}->{option_results}->{per_sec}) ? $self->{result_values}->{value_per_sec} : $self->{result_values}->{value}),
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

sub custom_ops_perfdata {
    my ($self, %options) = @_;

    my $extra_label = '';
    $extra_label = '_' . lc($self->{result_values}->{display}) if (!defined($options{extra_instance}) || $options{extra_instance} != 0);

    $self->{output}->perfdata_add(label => $self->{result_values}->{metric_perf} . "_" . $self->{result_values}->{stat} . $extra_label,
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
        foreach my $metric ('Disk Read Bytes', 'Disk Write Bytes') {
            my $metric_perf = lc($metric);
            my $metric_label = lc($metric);
            $metric_perf =~ s/ /_/g;
            $metric_label =~ s/ /-/g;
            my $entry = { label => $metric_label . '-' . $aggregation, set => {
                                key_values => [ { name => $metric_perf . '_' . $aggregation }, { name => 'display' },
                                    { name => 'stat' }, { name => 'timeframe' } ],
                                closure_custom_calc => $self->can('custom_metric_calc'),
                                closure_custom_calc_extra_options => { metric_perf => $metric_perf,
                                    metric_label => $metric_label, metric_name => $metric },
                                closure_custom_output => $self->can('custom_usage_output'),
                                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                                closure_custom_threshold_check => $self->can('custom_metric_threshold'),
                            }
                        };
            push @{$self->{maps_counters}->{metric}}, $entry;
        }
        foreach my $metric ('Disk Read Operations/Sec', 'Disk Write Operations/Sec') {
            my $metric_perf = lc($metric);
            my $metric_label = lc($metric);
            $metric_perf =~ s/ /_/g;
            $metric_label =~ s/( |\/)/-/g;
            my $entry = { label => $metric_label . '-' . $aggregation, set => {
                                key_values => [ { name => $metric_perf . '_' . $aggregation }, { name => 'display' },
                                    { name => 'stat' }, { name => 'timeframe' } ],
                                closure_custom_calc => $self->can('custom_metric_calc'),
                                closure_custom_calc_extra_options => { metric_perf => $metric_perf,
                                    metric_label => $metric_label, metric_name => $metric },
                                closure_custom_output => $self->can('custom_ops_output'),
                                closure_custom_perfdata => $self->can('custom_ops_perfdata'),
                                closure_custom_threshold_check => $self->can('custom_metric_threshold'),
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
    
    $options{options}->add_options(arguments => {
        "resource:s@"           => { name => 'resource' },
        "resource-group:s"      => { name => 'resource_group' },
        "filter-metric:s"       => { name => 'filter_metric' },
        "per-sec"               => { name => 'per_sec' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{resource})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify either --resource <name> with --resource-group option or --resource <id>.");
        $self->{output}->option_exit();
    }

    $self->{az_resource} = $self->{option_results}->{resource};
    $self->{az_resource_group} = $self->{option_results}->{resource_group} if (defined($self->{option_results}->{resource_group}));
    $self->{az_resource_type} = 'virtualMachines';
    $self->{az_resource_namespace} = 'Microsoft.Compute';
    $self->{az_timeframe} = defined($self->{option_results}->{timeframe}) ? $self->{option_results}->{timeframe} : 900;
    $self->{az_interval} = defined($self->{option_results}->{interval}) ? $self->{option_results}->{interval} : "PT5M";
    $self->{az_aggregations} = ['Average'];
    if (defined($self->{option_results}->{aggregation})) {
        $self->{az_aggregations} = [];
        foreach my $stat (@{$self->{option_results}->{aggregation}}) {
            if ($stat ne '') {
                push @{$self->{az_aggregations}}, ucfirst(lc($stat));
            }
        }
    }

    foreach my $metric ('Disk Read Bytes', 'Disk Write Bytes', 'Disk Read Operations/Sec',
        'Disk Write Operations/Sec') {
        next if (defined($self->{option_results}->{filter_metric}) && $self->{option_results}->{filter_metric} ne ''
            && $metric !~ /$self->{option_results}->{filter_metric}/);

        push @{$self->{az_metrics}}, $metric;
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my %metric_results;
    foreach my $resource (@{$self->{az_resource}}) {
        my $resource_group = $self->{az_resource_group};
        my $resource_name = $resource;
        if ($resource =~ /^\/subscriptions\/.*\/resourceGroups\/(.*)\/providers\/Microsoft\.Compute\/virtualMachines\/(.*)$/) {
            $resource_group = $1;
            $resource_name = $2;
        }

        ($metric_results{$resource_name}, undef, undef) = $options{custom}->azure_get_metrics(
            resource => $resource_name,
            resource_group => $resource_group,
            resource_type => $self->{az_resource_type},
            resource_namespace => $self->{az_resource_namespace},
            metrics => $self->{az_metrics},
            aggregations => $self->{az_aggregations},
            timeframe => $self->{az_timeframe},
            interval => $self->{az_interval},
        );

        foreach my $metric (@{$self->{az_metrics}}) {
            my $metric_name = lc($metric);
            $metric_name =~ s/ /_/g;
            foreach my $aggregation (@{$self->{az_aggregations}}) {
                next if (!defined($metric_results{$resource_name}->{$metric_name}->{lc($aggregation)}) && !defined($self->{option_results}->{zeroed}));

                $self->{metric}->{$resource_name . "_" . lc($aggregation)}->{display} = $resource_name;
                $self->{metric}->{$resource_name . "_" . lc($aggregation)}->{timeframe} = $self->{az_timeframe};
                $self->{metric}->{$resource_name . "_" . lc($aggregation)}->{stat} = lc($aggregation);
                $self->{metric}->{$resource_name . "_" . lc($aggregation)}->{$metric_name . "_" . lc($aggregation)} = defined($metric_results{$resource_name}->{$metric_name}->{lc($aggregation)}) ? $metric_results{$resource_name}->{$metric_name}->{lc($aggregation)} : 0;
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

Check virtual machine resources disk IO metrics.

Example:

Using resource name :

perl centreon_plugins.pl --plugin=cloud::azure::compute::virtualmachine::plugin --custommode=azcli --mode=diskio
--resource=MYSQLINSTANCE --resource-group=MYHOSTGROUP --aggregation='total' --aggregation='average'
--critical-disk-write-bytes-total='10' --verbose

Using resource id :

perl centreon_plugins.pl --plugin=cloud::azure::compute::virtualmachine::plugin --custommode=azcli --mode=diskio
--resource='/subscriptions/xxx/resourceGroups/xxx/providers/Microsoft.Compute/virtualMachines/xxx'
--aggregation='total' --aggregation='average' --critical-disk-write-bytes-total='10' --verbose

Default aggregation: 'total', 'average' / All aggregations are valid.

=over 8

=item B<--resource>

Set resource name or id (Required).

=item B<--resource-group>

Set resource group (Required if resource's name is used).

=item B<--filter-metric>

Filter metrics (Can be: 'Disk Read Bytes', 'Disk Write Bytes',
'Disk Read Operations/Sec', 'Disk Write Operations/Sec') (Can be a regexp).

=item B<--warning-$metric$-$aggregation$>

Thresholds warning ($metric$ can be: 'disk-read-bytes', 'disk-write-bytes', 'disk-read-operations-sec',
'disk-write-operations-sec', $aggregation$ can be: 'minimum', 'maximum', 'average', 'total').

=item B<--critical-$metric$-$aggregation$>

Thresholds critical ($metric$ can be: 'disk-read-bytes', 'disk-write-bytes', 'disk-read-operations-sec',
'disk-write-operations-sec', $aggregation$ can be: 'minimum', 'maximum', 'average', 'total').

=item B<--per-sec>

Change the data to be unit/sec.

=back

=cut
