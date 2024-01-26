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

package cloud::aws::ec2::mode::diskio;

use base qw(cloud::aws::custom::mode);

use strict;
use warnings;

sub get_metrics_mapping {
    my ($self, %options) = @_;

    my $metrics_mapping = {
        extra_params => {
            message_multiple => 'All disks metrics are ok'
        },
        metrics => {
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
                output => 'EBS Write Ops',
                label => 'ebs-ops-write',
                nlabel => {
                    absolute => 'ec2.ebs.ops.write.count',
                    per_second => 'ec2.ebs.ops.write.persecond'
                },
                unit => 'ops'
            }
        }
    };

    return $metrics_mapping;
}

sub prefix_metric_output {
    my ($self, %options) = @_;
    
    return ucfirst($self->{option_results}->{type}) . " '" . $options{instance_value}->{display} . "' ";
}

sub long_output {
    my ($self, %options) = @_;

    return "Checking " . ucfirst($self->{option_results}->{type}) . " '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'type:s'	      => { name => 'type' },
        'name:s@'	      => { name => 'name' },
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

    $self->{aws_metrics} = [];
    foreach my $metric (keys %{$self->{metrics_mapping}}) {
        next if (!defined($self->{option_results}->{add_ebs_metrics}) && $metric =~ /EBS/);
        next if (defined($self->{option_results}->{filter_metric}) && $self->{option_results}->{filter_metric} ne ''
            && $metric !~ /$self->{option_results}->{filter_metric}/);

        push @{$self->{aws_metrics}}, $metric;
    }
}

my %map_type = (
    instance => 'InstanceId',
    asg      => 'AutoScalingGroupName'
);

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

Set the instance type (required) (can be: 'asg', 'instance').

=item B<--name>

Set the instance name (required) (can be defined multiple times).

=item B<--add-ebs-metrics>

Add EBS metrics ('EBSReadOps', 'EBSWriteOps', 'EBSReadBytes', 'EBSWriteBytes').

=item B<--filter-metric>

Filter metrics (can be: 'DiskReadBytes', 'DiskWriteBytes',
'DiskReadOps', 'DiskWriteOps') 
(can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds (can be 'disk-bytes-read', 'disk-bytes-write', 'disk-ops-read', 'disk-ops-write',
'ebs-bytes-read', 'ebs-bytes-write', 'ebs-ops-read', 'ebs-ops-write').

=item B<--per-sec>

Change the data to be unit/sec.

=back

=cut
