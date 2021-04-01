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

package cloud::aws::rds::mode::storage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

my $metrics_mapping = {
    FreeStorageSpace => {
        output => 'storage space free',
        label  => 'storage-space-free',
        nlabel => {
            absolute   => 'storage.space.free.bytes'
        },
        unit => 'B'
    },
    FreeStorageSpacePrct => {
        output => 'storage space usage',
        label  => 'storage-space-usage-prct',
        nlabel => {
            absolute   => 'storage.space.usage.percentage'
        },
        unit => '%',
        cw_metric => 0
    },
    FreeableMemory => {
        output => 'memory free',
        label  => 'memory-free',
        nlabel => {
            absolute   => 'memory.free.bytes'
        },
        unit   => 'B'
    }
};

my $map_type = {
    instance => 'DBInstanceIdentifier',
    cluster  => 'DBClusterIdentifier'
};

sub custom_metric_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{timeframe} = $options{new_datas}->{$self->{instance} . '_timeframe'};
    $self->{result_values}->{value} = $options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{metric}};
    $self->{result_values}->{metric} = $options{extra_options}->{metric};
    return 0;
}

sub custom_metric_threshold {
    my ($self, %options) = @_;

    return $self->{perfdata}->threshold_check(
        value     => $self->{result_values}->{value},
        threshold => [
            { label => 'critical-' . $metrics_mapping->{ $self->{result_values}->{metric} }->{label} , exit_litteral => 'critical' },
            { label => 'warning-' . $metrics_mapping->{ $self->{result_values}->{metric} }->{label}, exit_litteral => 'warning' }
        ]
    );
}

sub custom_metric_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        instances => $self->{instance},
        nlabel    => $metrics_mapping->{ $self->{result_values}->{metric} }->{nlabel}->{absolute},
        unit      => $metrics_mapping->{ $self->{result_values}->{metric} }->{unit},
        value     => sprintf('%.2f', $self->{result_values}->{value}),
        warning   => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $metrics_mapping->{ $self->{result_values}->{metric} }->{label}),
        critical  => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $metrics_mapping->{ $self->{result_values}->{metric} }->{label})
    );
}

sub custom_metric_output {
    my ($self, %options) = @_;

    my ($value, $unit) = ($metrics_mapping->{ $self->{result_values}->{metric} }->{unit} eq 'B') ?
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{value}) :
        ($self->{result_values}->{value}, $metrics_mapping->{ $self->{result_values}->{metric} }->{unit});
    return sprintf("%s: %.2f %s", $metrics_mapping->{ $self->{result_values}->{metric} }->{output}, $value, $unit);
}

sub prefix_metric_output {
    my ($self, %options) = @_;

    return "'" . $options{instance_value}->{display} . "' ";
}

sub prefix_statistics_output {
    my ($self, %options) = @_;

    return "statistic '" . $options{instance_value}->{display} . "' metrics ";
}

sub long_output {
    my ($self, %options) = @_;

    return "AWS RDS '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'metrics', type => 3, cb_prefix_output => 'prefix_metric_output', cb_long_output => 'long_output',
          message_multiple => 'All storage metrics are ok', indent_long_output => '    ',
            group => [
                { name => 'statistics', display_long => 1, cb_prefix_output => 'prefix_statistics_output',
                  message_multiple => 'All metrics are ok', type => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    foreach my $metric (keys %$metrics_mapping) {
        my $entry = {
            label => $metrics_mapping->{$metric}->{label},
            set => {
                key_values                        => [ { name => $metric }, { name => 'timeframe' }, { name => 'display' } ],
                closure_custom_calc               => $self->can('custom_metric_calc'),
                closure_custom_calc_extra_options => { metric => $metric },
                closure_custom_output             => $self->can('custom_metric_output'),
                closure_custom_perfdata           => $self->can('custom_metric_perfdata'),
                closure_custom_threshold_check    => $self->can('custom_metric_threshold')
            }
        };
        push @{$self->{maps_counters}->{statistics}}, $entry;
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'type:s'	              => { name => 'type' },
        'name:s@'	              => { name => 'name' },
        'filter-metric:s'         => { name => 'filter_metric' },
        'add-space-usage-percent' => { name => 'add_space_usage_percent' } 
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{type}) || $self->{option_results}->{type} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --type option.");
        $self->{output}->option_exit();
    }

    if (!defined($map_type->{ $self->{option_results}->{type} })) {
        $self->{output}->add_option_msg(short_msg => "Instance type '" . $self->{option_results}->{type} . "' is not handled for this mode");
        $self->{output}->option_exit();
    }

    if (!defined($self->{option_results}->{name}) || $self->{option_results}->{name} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --name option.");
        $self->{output}->option_exit();
    }

    foreach my $instance (@{$self->{option_results}->{name}}) {
        if ($instance ne '') {
            push @{$self->{aws_instance}}, $instance;
        }
    }

    $self->{aws_timeframe} = defined($self->{option_results}->{timeframe}) ? $self->{option_results}->{timeframe} : 600;
    $self->{aws_period} = defined($self->{option_results}->{period}) ? $self->{option_results}->{period} : 60;

    $self->{aws_statistics} = ['Average'];
    if (defined($self->{option_results}->{statistic})) {
        $self->{aws_statistics} = [];
        foreach my $stat (@{$self->{option_results}->{statistic}}) {
            if ($stat ne '') {
                push @{$self->{aws_statistics}}, ucfirst(lc($stat));
            }
        }
    };
    foreach my $metric (keys %$metrics_mapping) {
        next if (defined($self->{option_results}->{filter_metric}) && $self->{option_results}->{filter_metric} ne ''
            && $metric !~ /$self->{option_results}->{filter_metric}/);
        next if (defined($metrics_mapping->{$metric}->{cw_metric}) && $metrics_mapping->{$metric}->{cw_metric} == 0);
        push @{$self->{aws_metrics}}, $metric;
        # For Aurora instance
        if ($metric eq 'FreeStorageSpace') {
            push @{$self->{aws_metrics}}, 'FreeLocalStorage';
        }
    };
}

sub add_metric {
    my ($self, %options) = @_;

    return if (
        !defined($options{metric_value}) &&
        !defined($self->{option_results}->{zeroed})
    );
    if (!defined($self->{metrics}->{ $options{instance} })) {
        $self->{metrics}->{ $options{instance} } = {
            display => $options{instance},
            statistics => {}
        };
    }
    $self->{metrics}->{ $options{instance} }->{statistics}->{ $options{statistic} }->{display} = $options{statistic};
    $self->{metrics}->{ $options{instance} }->{statistics}->{ $options{statistic} }->{timeframe} = $self->{aws_timeframe};
    $self->{metrics}->{ $options{instance} }->{statistics}->{ $options{statistic} }->{ $options{metric} } =
        defined($options{metric_value}) ?
        $options{metric_value} : 0;
    if (defined($metrics_mapping->{ $options{metric} }->{calc})) {
        $self->{metrics}->{ $options{instance} }->{statistics}->{ $options{statistic} }->{ $options{metric} } = 
            eval $self->{metrics}->{ $options{instance} }->{statistics}->{ $options{statistic} }->{ $options{metric} } . $metrics_mapping->{ $options{metric} }->{calc};
    }
}

sub add_metric_space_usage_percent {
    my ($self, %options) = @_;

    my $total_space;
    foreach (@{$options{list_rds_instances}}) {
        if ($_->{Name} eq $options{instance}) {
            $total_space = $_->{AllocatedStorage} * 1024 * 1024 * 1024;
            last;
        }
    }

    return if (!defined($total_space) || $total_space <= 0);

    my $space_usage = 100 - ($options{free_storage} * 100 / $total_space);
    $self->add_metric(
        metric_value => $space_usage,
        instance => $options{instance},
        metric => 'FreeStorageSpacePrct',
        statistic => $options{statistic}
    );
}

sub manage_selection {
    my ($self, %options) = @_;

    my $list_rds_instances;
    if (defined($self->{option_results}->{add_space_usage_percent})) {
        if ($self->{option_results}->{type} eq 'instance') {
            $list_rds_instances = $options{custom}->rds_list_instances();
        } else {
            $list_rds_instances = $options{custom}->rds_list_clusters();
        }
    }

    foreach my $instance (@{$self->{aws_instance}}) {
        my $metric_results = $options{custom}->cloudwatch_get_metrics(
            namespace  => 'AWS/RDS',
            dimensions => [ { Name => $map_type->{ $self->{option_results}->{type} }, Value => $instance } ],
            metrics    => $self->{aws_metrics},
            statistics => $self->{aws_statistics},
            timeframe  => $self->{aws_timeframe},
            period     => $self->{aws_period}
        );

        foreach my $metric (@{$self->{aws_metrics}}) {
            foreach my $statistic (@{$self->{aws_statistics}}) {
                if ($metric eq 'FreeStorageSpace' && !defined($metric_results->{$metric}->{lc($statistic)})) {
                    $self->add_metric(
                        metric_value => $metric_results->{FreeLocalStorage}->{lc($statistic)},
                        instance => $instance,
                        metric => 'FreeStorageSpace',
                        statistic => lc($statistic)
                    );
                } else {
                    $self->add_metric(
                        metric_value => $metric_results->{$metric}->{lc($statistic)},
                        instance => $instance,
                        metric => $metric,
                        statistic => lc($statistic)
                    );
                }

                if (defined($self->{option_results}->{add_space_usage_percent}) && $metric eq 'FreeStorageSpace' &&
                    defined($self->{metrics}->{$instance}->{statistics}->{lc($statistic)})) {
                    $self->add_metric_space_usage_percent(
                        list_rds_instances => $list_rds_instances,
                        free_storage => $self->{metrics}->{$instance}->{statistics}->{lc($statistic)}->{$metric},
                        instance => $instance,
                        metric => $metric,
                        statistic => lc($statistic)
                    );
                }
            }
        }
    }

    if (scalar(keys %{$self->{metrics}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No metrics. Check your options or use --zeroed option to set 0 on undefined values');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check RDS instances storage metrics.

Example: 
perl centreon_plugins.pl --plugin=cloud::aws::rds::plugin --custommode=paws --mode=storage --region='eu-west-1'
--type='cluster' --name='centreon-db-ppd-cluster' --filter-metric='FreeStorageSpace' --statistic='average'
--critical-freestoragespace-average='10G:' --verbose

Works for the following database engines : aurora, mysql, mariadb.

See 'https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/MonitoringOverview.html' for more informations.

Default statistic: 'average' / All statistics are valid.

=over 8

=item B<--type>

Set the instance type (Required) (Can be: 'cluster', 'instance').

=item B<--name>

Set the instance name (Required) (Can be multiple).

=item B<--filter-metric>

Filter on a specific metric.
Can be: FreeStorageSpace, FreeableMemory.

=item B<--add-space-usage-percent>

Check storage usage space percentage (need privileges to describe rds).

=item B<--warning-$metric$> B<--critical-$metric$>

Thresholds ($metric$ can be: 'storage-space-free', 'storage-space-usage-prct', 'memory-free').

=back

=cut
