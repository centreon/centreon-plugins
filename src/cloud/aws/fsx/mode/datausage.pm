#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package cloud::aws::fsx::mode::datausage;

use base qw(cloud::aws::custom::mode);

use strict;
use warnings;

sub get_metrics_mapping {
    my ($self, %options) = @_;

    my $metrics_mapping = {
        extra_params => {
            message_multiple => 'All FSx metrics are ok'
        },
        metrics => {
            DataReadBytes => {
                output    => 'Data Read Bytes',
                label     => 'data-read-bytes',
                nlabel    => {
                    absolute => 'fsx.data.read.bytes',
                    per_second => 'fsx.data.read.bytespersecond'
                },
                unit => 'B'
            },
            DataWriteBytes => {
                output    => 'Data Write Bytes',
                label     => 'data-write-bytes',
                nlabel    => {
                    absolute      => 'fsx.data.write.bytes',
                    per_second    => 'fsx.data.write.bytespersecond'
                },
                unit => 'B'
            },
            DataReadOperations => {
                output    => 'Data Read Ops',
                label     => 'data-read-ops',
                nlabel    => {
                    absolute => 'fsx.data.io.read.count',
                    per_second => 'fsx.data.io.read.persecond'
                },
                unit => 'count'
            },
            DataWriteOperations => {
                output    => 'Data Write Ops',
                label     => 'data-write-ops',
                nlabel    => {
                    absolute => 'fsx.data.io.write.count',
                    per_second => 'fsx.data.io.write.persecond'
                },
                unit => 'count'
            },
            MetadataOperations => {
                output    => 'MetaData Operations Bytes',
                label     => 'metadata-ops-bytes',
                nlabel    => {
                    absolute   => 'fsx.metadata.ops.bytes',
                    per_second => 'fsx.metadata.ops.bytespersecond'
                },
                unit => 'B'
            }
        }
    };

    return $metrics_mapping;
}

sub long_output {
    my ($self, %options) = @_;

    return "FSx FileSystemId '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'name:s@' => { name => 'name' }
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{name}) || $self->{option_results}->{name} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --name option.");
        $self->{output}->option_exit();
    }

    foreach my $instance (@{$self->{option_results}->{name}}) {
        if ($instance ne '') {
            push @{$self->{aws_instance}}, $instance;
        }
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my %metric_results;
    foreach my $instance (@{$self->{aws_instance}}) {
        $metric_results{$instance} = $options{custom}->cloudwatch_get_metrics(
            namespace => 'AWS/FSx',
            dimensions => [ { Name => "FileSystemId", Value => $instance } ],
            metrics => $self->{aws_metrics},
            statistics => $self->{aws_statistics},
            timeframe => $self->{aws_timeframe},
            period => $self->{aws_period}
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

Check FSx FileSystem Data consumption metrics.

Example:
perl centreon_plugins.pl --plugin=cloud::aws::fsx::plugin --custommode=awscli --mode=datausage --region='eu-west-1'
--name='fs-1234abcd' --filter-metric='DataReadIOBytes' --statistic='sum' --warning-data-read-bytes='5' --verbose

See 'https://docs.aws.amazon.com/efs/latest/ug/efs-metrics.html' for more information.

=over 8

=item B<--name>

Set the instance name (required) (can be defined multiple times).

=item B<--filter-metric>

Filter on a specific metric. 
Can be: C<DataReadBytes>, C<DataWriteBytes>, C<DataReadOperations>, C<DataWriteOperations>, C<MetaDataOperations>

=item B<--statistic>

Set the metric calculation method (Only Sum is relevant).

=item B<--warning-data-read-bytes>

Threshold.

=item B<--critical-data-read-bytes>

Threshold.

=item B<--warning-data-read-ops>

Threshold.

=item B<--critical-data-read-ops>

Threshold.

=item B<--warning-data-write-bytes>

Threshold.

=item B<--critical-data-write-bytes>

Threshold.

=item B<--warning-data-write-ops>

Threshold.

=item B<--critical-data-write-ops>

Threshold.

=item B<--warning-metadata-ops-bytes>

Threshold.

=item B<--critical-metadata-ops-bytes>

Threshold.

=back

=cut
