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

package cloud::aws::ebs::mode::volumeiops;

use base qw(cloud::aws::custom::mode);

use strict;
use warnings;

sub get_metrics_mapping {
    my ($self, %options) = @_;

    my $metrics_mapping = {
        extra_params => {
            message_multiple => 'All EBS metrics are ok'
        },
        metrics => {
            VolumeReadOps => {
                output    => 'IOPS Read',
                label     => 'iops-read',
                nlabel    => {
                    absolute      => 'ebs.volume.iops.read.count',
                    per_second    => 'ebs.volume.iops.read.countpersecond'
                },
                unit      => ''
            },
            VolumeWriteOps => {
                output    => 'IOPS Write',
                label     => 'iops-write',
                nlabel    => {
                    absolute      => 'ebs.volume.iops.write.count',
                    per_second    => 'ebs.volume.iops.write.countpersecond'
                },
                unit      => ''
            },
            VolumeThroughputPercentage => {
                output    => 'IOPS Throughput',
                label     => 'iops-throughput',
                nlabel    => {
                    absolute      => 'ebs.volume.iops.throughput.percentage',
                    per_second    => 'ebs.volume.iops.throughput.percentagepersecond'
                },
                unit      => '%'
            },
            VolumeConsumedReadWriteOps => {
                output    => 'IOPS Consumed',
                label     => 'iops-consumed',
                nlabel    => {
                    absolute      => 'ebs.volume.iops.consumed.count',
                    per_second    => 'ebs.volume.iops.consumed.countpersecond'
                },
                unit      => ''
            },
            VolumeQueueLength => {
                output    => 'IOPS Queue Length',
                label     => 'iops-queue-length',
                nlabel    => {
                    absolute      => 'ebs.volume.iops.queuelength.count',
                    per_second    => 'ebs.volume.iops.queuelength.countpersecond'
                },
                unit      => ''
            }
        }
    };

    return $metrics_mapping;
}

sub long_output {
    my ($self, %options) = @_;

    return "AWS EBS Volume'" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'volume-id:s@' => { name => 'volume_id' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{volume_id}) || $self->{option_results}->{volume_id} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --volumeid option.");
        $self->{output}->option_exit();
    };

    foreach my $instance (@{$self->{option_results}->{volume_id}}) {
        if ($instance ne '') {
            push @{$self->{aws_instance}}, $instance;
        };
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my %metric_results;
    foreach my $instance (@{$self->{aws_instance}}) {
        $metric_results{$instance} = $options{custom}->cloudwatch_get_metrics(
            namespace   => 'AWS/EBS',
            dimensions  => [ { Name => 'VolumeId', Value => $instance } ],
            metrics     => $self->{aws_metrics},
            statistics  => $self->{aws_statistics},
            timeframe   => $self->{aws_timeframe},
            period      => $self->{aws_period}
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

Check Amazon Elastic Block Store volumes IOPS.

Example:
perl centreon_plugins.pl --plugin=cloud::aws::ebs::plugin --custommode=awscli --mode=volumeiops --region='eu-west-1'
--volumeid='vol-1234abcd' --warning-iops-queue-length='100' --critical-iops-queue-length='200' --warning --verbose

See 'https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using_cloudwatch_ebs.html' for more information.


=over 8

=item B<--volume-id>

Set the VolumeId (required).

=item B<--filter-metric>

Filter on a specific metric.
Can be: VolumeReadOps, VolumeWriteOps, VolumeThroughputPercentage, VolumeConsumedReadWriteOps

=item B<--warning-$metric$>

Warning thresholds ($metric$ can be: 'iops-read', 'iops-write', 'iops-throughput', 'iops-consumed', 'iops-queue-length').

=item B<--critical-$metric$>

Critical thresholds ($metric$ can be: 'iops-read', 'iops-write', 'iops-throughput', 'iops-consumed', 'iops-queue-length').

=item B<--per-sec>

Change the data to be unit/sec.

=back

=cut
