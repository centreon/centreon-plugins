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

package cloud::aws::ebs::mode::volumeio;

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
            'VolumeReadBytes' => {
                'output'    => 'Volume Read Bytes',
                'label'     => 'volume-read-bytes',
                'nlabel'    => {
                    'absolute'      => 'ebs.volume.bytes.read.bytes',
                    'per_second'    => 'ebs.volume.bytes.read.bytespersecond'
                },
                'unit'      => 'B'
            },
            'VolumeWriteBytes' => {
                'output'    => 'Volume Write Bytes',
                'label'     => 'volume-write-bytes',
                'nlabel'    => {
                    'absolute'      => 'ebs.volume.bytes.write.bytes',
                    'per_second'    => 'ebs.volume.bytes.write.bytespersecond'
                },
                'unit'      => 'B'
            }
        }
    };

    return $metrics_mapping;
}

sub long_output {
    my ($self, %options) = @_;

    return "AWS EBS Volume '" . $options{instance_value}->{display} . "' ";
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
        $self->{output}->add_option_msg(short_msg => "Need to specify --volume-id option.");
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

Check Amazon Elastic Block Store volumes IO usage.

Example:
perl centreon_plugins.pl --plugin=cloud::aws::ebs::plugin --custommode=awscli --mode=volumeio --region='eu-west-1'
--volumeid='vol-1234abcd' --warning-write-bytes='100000' --critical-write-bytes='200000' --warning --verbose

See 'https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using_cloudwatch_ebs.html' for more information.


=over 8

=item B<--volume-id>

Set the VolumeId (required).

=item B<--filter-metric>

Filter on a specific metric.
Can be: VolumeReadBytes, VolumeWriteBytes

=item B<--warning-$metric$>

Warning thresholds ($metric$ can be: 'volume-read-bytes', 'volume-write-bytes').

=item B<--critical-$metric$>

Critical thresholds ($metric$ can be: 'volume-read-bytes', 'volume-write-bytes').

=item B<--per-sec>

Change the data to be unit/sec.

=back

=cut
