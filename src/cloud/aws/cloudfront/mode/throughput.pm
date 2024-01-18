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

package cloud::aws::cloudfront::mode::throughput;

use base qw(cloud::aws::custom::mode);

use strict;
use warnings;

sub get_metrics_mapping {
    my ($self, %options) = @_;

    my $metrics_mapping = {
        extra_params => {
            message_multiple => 'All instances metrics are ok'
        },
        metrics => {
            BytesDownloaded => {
                output => 'Bytes Downloaded',
                label => 'bytes-downloaded',
                nlabel => {
                    absolute => 'cloudfront.bytes.downloaded.bytes',
                    per_second => 'cloudfront.bytes.downloaded.persecond'
                },
                unit => 'B'
            },
            BytesUploaded => {
                output => 'Bytes Uploaded',
                label => 'bytes-uploaded',
                nlabel => {
                    absolute => 'cloudfront.bytes.uploaded.bytes',
                    per_second => 'cloudfront.bytes.uploaded.persecond',
                },
                unit => 'B'
            }
        }
    };

    return $metrics_mapping;
}

sub prefix_metric_output {
    my ($self, %options) = @_;
    
    return "Instance '" . $options{instance_value}->{display} . "' ";
}

sub long_output {
    my ($self, %options) = @_;

    return "Checking Instance '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'id:s@'	=> { name => 'id' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{id}) || $self->{option_results}->{id} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --id option.");
        $self->{output}->option_exit();
    }

    foreach my $instance (@{$self->{option_results}->{id}}) {
        if ($instance ne '') {
            push @{$self->{aws_instance}}, $instance;
        }
    }

    $self->{aws_statistics} = ['Sum'];
    if (defined($self->{option_results}->{statistic})) {
        $self->{aws_statistics} = [];
        foreach my $stat (@{$self->{option_results}->{statistic}}) {
            if ($stat ne '') {
                push @{$self->{aws_statistics}}, ucfirst(lc($stat));
            }
        }
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my %metric_results;
    foreach my $instance (@{$self->{aws_instance}}) {
        $metric_results{$instance} = $options{custom}->cloudwatch_get_metrics(
            namespace => 'AWS/CloudFront',
            dimensions => [ { Name => 'Region', Value => 'Global' }, { Name => 'DistributionId', Value => $instance } ],
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

Check CloudFront instances throughput.

Example: 
perl centreon_plugins.pl --plugin=cloud::aws::cloudfront::plugin --custommode=paws --mode=throughput --region='eu-west-1'
--id='E8T734E1AF1L4' --statistic='sum' --critical-bytes-downloaded='10' --verbose

See 'https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/monitoring-using-cloudwatch.html'
for more informations.

Default statistic: 'sum' / Valid statistic: 'sum'.

=over 8

=item B<--id>

Set the instance ID (required) (can be defined multiple times).

=item B<--filter-metric>

Filter metrics (can be: 'BytesDownloaded', 'BytesUploaded') 
(can be a regexp).

=item B<--warning-*>

Warning thresholds (can be: 'bytes-downloaded', 'bytes-uploaded').

=item B<--critical-*>

Critical thresholds (can be: 'bytes-downloaded', 'bytes-uploaded')

=item B<--per-sec>

Change the data to be unit/sec.

=back

=cut
