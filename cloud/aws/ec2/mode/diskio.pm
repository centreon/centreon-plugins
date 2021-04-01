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

package cloud::aws::ec2::mode::diskio;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

my %metrics_mapping = (
    DiskReadBytes => {
        output => 'Disk Read Bytes',
        label => 'disk-bytes-read',
        nlabel => {
            absolute => 'ec2.disk.bytes.read.bytes',
            per_second => 'ec2.disk.bytes.read.bytespersecond'
        },
        unit => 'B'
    },
    DiskWriteBytes => {
        output => 'Disk Write Bytes',
        label => 'disk-bytes-write',
        nlabel => {
            absolute => 'ec2.disk.bytes.write.bytes',
            per_second => 'ec2.disk.bytes.write.bytespersecond'
        },
        unit => 'B'
    },
    DiskReadOps => {
        output => 'Disk Read Ops',
        label => 'disk-ops-read',
        nlabel => {
            absolute => 'ec2.disk.ops.read.count',
            per_second => 'ec2.disk.ops.read.persecond'
        },
        unit => 'ops'
    },
    DiskWriteOps => {
        output => 'Disk Write Ops',
        label => 'disk-ops-write',
        nlabel => {
            absolute => 'ec2.disk.ops.write.count',
            per_second => 'ec2.disk.ops.write.persecond'
        },
        unit => 'ops'
    },
    EBSReadBytes => {
        output => 'EBS Read Bytes',
        label => 'ebs-bytes-read',
        nlabel => {
            absolute => 'ec2.disk.bytes.read.bytes',
            per_second => 'ec2.disk.bytes.read.bytespersecond'
        },
        unit => 'B'
    },
    EBSWriteBytes => {
        output => 'EBS Write Bytes',
        label => 'ebs-bytes-write',
        nlabel => {
            absolute => 'ec2.ebs.bytes.write.bytes',
            per_second => 'ec2.ebs.bytes.write.bytespersecond'
        },
        unit => 'B'
    },
    EBSReadOps => {
        output => 'EBS Read Ops',
        label => 'ebs-ops-read',
        nlabel => {
            absolute => 'ec2.ebs.ops.read.count',
            per_second => 'ec2.ebs.ops.read.persecond'
        },
        unit => 'ops'
    },
    EBSWriteOps => {
        output => 'EBC Write Ops',
        label => 'ebs-ops-write',
        nlabel => {
            absolute => 'ec2.ebs.ops.write.count',
            per_second => 'ec2.ebs.ops.write.persecond'
        },
        unit => 'ops'
    }
);

my %map_type = (
    instance => "InstanceId",
    asg      => "AutoScalingGroupName"
);

sub prefix_metric_output {
    my ($self, %options) = @_;
    
    return ucfirst($self->{option_results}->{type}) . " '" . $options{instance_value}->{display} . "' ";
}

sub prefix_statistics_output {
    my ($self, %options) = @_;
    
    return "Statistic '" . $options{instance_value}->{display} . "' Metrics ";
}

sub long_output {
    my ($self, %options) = @_;

    return "Checking " . ucfirst($self->{option_results}->{type}) . " '" . $options{instance_value}->{display} . "' ";
}

sub custom_metric_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{timeframe} = $options{new_datas}->{$self->{instance} . '_timeframe'};
    $self->{result_values}->{value} = $options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{metric}};
    $self->{result_values}->{value_per_sec} = $self->{result_values}->{value} / $self->{result_values}->{timeframe};
    $self->{result_values}->{metric} = $options{extra_options}->{metric};
    return 0;
}

sub custom_metric_threshold {
    my ($self, %options) = @_;

    my $exit = $self->{perfdata}->threshold_check(
        value => defined($self->{instance_mode}->{option_results}->{per_sec}) ? $self->{result_values}->{value_per_sec} : $self->{result_values}->{value},
        threshold => [
            { label => 'critical-' . $metrics_mapping{$self->{result_values}->{metric}}->{label}, exit_litteral => 'critical' },
            { label => 'warning-' . $metrics_mapping{$self->{result_values}->{metric}}->{label}, exit_litteral => 'warning' }
        ]
    );
    return $exit;
}

sub custom_metric_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        instances => $self->{instance},
        label => $metrics_mapping{$self->{result_values}->{metric}}->{label},
        nlabel => defined($self->{instance_mode}->{option_results}->{per_sec}) ?
            $metrics_mapping{$self->{result_values}->{metric}}->{nlabel}->{per_second} :
            $metrics_mapping{$self->{result_values}->{metric}}->{nlabel}->{absolute},
        unit => defined($self->{instance_mode}->{option_results}->{per_sec}) ?
            $metrics_mapping{$self->{result_values}->{metric}}->{unit} . '/s' :
            $metrics_mapping{$self->{result_values}->{metric}}->{unit},
        value => sprintf("%.2f", defined($self->{instance_mode}->{option_results}->{per_sec}) ?
            $self->{result_values}->{value_per_sec} :
            $self->{result_values}->{value}),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $metrics_mapping{$self->{result_values}->{metric}}->{label}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $metrics_mapping{$self->{result_values}->{metric}}->{label}),
    );
}

sub custom_metric_output {
    my ($self, %options) = @_;
    my $msg = "";

    if (defined($self->{instance_mode}->{option_results}->{per_sec})) {
        my ($value, $unit) = ($metrics_mapping{$self->{result_values}->{metric}}->{unit} eq 'B') ? 
            $self->{perfdata}->change_bytes(value => $self->{result_values}->{value_per_sec}) :
            ($self->{result_values}->{value_per_sec}, $metrics_mapping{$self->{result_values}->{metric}}->{unit});
        $msg = sprintf("%s: %.2f %s", $metrics_mapping{$self->{result_values}->{metric}}->{output}, $value, $unit . '/s');
    } else {
        my ($value, $unit) = ($metrics_mapping{$self->{result_values}->{metric}}->{unit} eq 'B') ? 
            $self->{perfdata}->change_bytes(value => $self->{result_values}->{value}) :
            ($self->{result_values}->{value}, $metrics_mapping{$self->{result_values}->{metric}}->{unit});
        $msg = sprintf("%s: %.2f %s", $metrics_mapping{$self->{result_values}->{metric}}->{output}, $value, $unit);
    }
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'metrics', type => 3, cb_prefix_output => 'prefix_metric_output', cb_long_output => 'long_output',
          message_multiple => 'All disks metrics are ok', indent_long_output => '    ',
            group => [
                { name => 'statistics', display_long => 1, cb_prefix_output => 'prefix_statistics_output',
                  message_multiple => 'All metrics are ok', type => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    foreach my $metric (keys %metrics_mapping) {
        my $entry = {
            label => $metrics_mapping{$metric}->{label},
            set => {
                key_values => [ { name => $metric }, { name => 'timeframe' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_metric_calc'),
                closure_custom_calc_extra_options => { metric => $metric },
                closure_custom_output => $self->can('custom_metric_output'),
                closure_custom_perfdata => $self->can('custom_metric_perfdata'),
                closure_custom_threshold_check => $self->can('custom_metric_threshold')
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
        'type:s'	      => { name => 'type' },
        'name:s@'	      => { name => 'name' },
        'filter-metric:s' => { name => 'filter_metric' },
        'per-sec'         => { name => 'per_sec' },
        'add-ebs-metrics' => { name => 'add_ebs_metrics' }
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

    if ($self->{option_results}->{type} ne 'asg' && $self->{option_results}->{type} ne 'instance') {
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
    }

    foreach my $metric (keys %metrics_mapping) {
        next if (!defined($self->{option_results}->{add_ebs_metrics}) && $metric =~ /EBS/);
        next if (defined($self->{option_results}->{filter_metric}) && $self->{option_results}->{filter_metric} ne ''
            && $metric !~ /$self->{option_results}->{filter_metric}/);

        push @{$self->{aws_metrics}}, $metric;
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my %metric_results;
    foreach my $instance (@{$self->{aws_instance}}) {
        $metric_results{$instance} = $options{custom}->cloudwatch_get_metrics(
            namespace => 'AWS/EC2',
            dimensions => [ { Name => $map_type{$self->{option_results}->{type}}, Value => $instance } ],
            metrics => $self->{aws_metrics},
            statistics => $self->{aws_statistics},
            timeframe => $self->{aws_timeframe},
            period => $self->{aws_period},
        );
        
        foreach my $metric (@{$self->{aws_metrics}}) {
            foreach my $statistic (@{$self->{aws_statistics}}) {
                next if (!defined($metric_results{$instance}->{$metric}->{lc($statistic)}) &&
                    !defined($self->{option_results}->{zeroed}));

                $self->{metrics}->{$instance}->{display} = $instance;
                $self->{metrics}->{$instance}->{statistics}->{lc($statistic)}->{display} = $statistic;
                $self->{metrics}->{$instance}->{statistics}->{lc($statistic)}->{timeframe} = $self->{aws_timeframe};
                $self->{metrics}->{$instance}->{statistics}->{lc($statistic)}->{$metric} = 
                    defined($metric_results{$instance}->{$metric}->{lc($statistic)}) ? 
                    $metric_results{$instance}->{$metric}->{lc($statistic)} : 0;
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

Check EC2 instances disk IO metrics.

Example: 
perl centreon_plugins.pl --plugin=cloud::aws::ec2::plugin --custommode=paws --mode=diskio --region='eu-west-1'
--type='asg' --name='centreon-middleware' --filter-metric='Read' --statistic='sum' --critical-disk-ops-read='10'
--verbose

See 'https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ec2-metricscollected.html' for more informations.

Default statistic: 'average' / All satistics are valid.

=over 8

=item B<--type>

Set the instance type (Required) (Can be: 'asg', 'instance').

=item B<--name>

Set the instance name (Required) (Can be multiple).

=item B<--add-ebs-metrics>

Add EBS metrics ('EBSReadOps', 'EBSWriteOps', 'EBSReadBytes', 'EBSWriteBytes').

=item B<--filter-metric>

Filter metrics (Can be: 'DiskReadBytes', 'DiskWriteBytes',
'DiskReadOps', 'DiskWriteOps') 
(Can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds (Can be 'disk-bytes-read', 'disk-bytes-write', 'disk-ops-read', 'disk-ops-write',
'ebs-bytes-read', 'ebs-bytes-write', 'ebs-ops-read', 'ebs-ops-write').

=item B<--per-sec>

Change the data to be unit/sec.

=back

=cut
