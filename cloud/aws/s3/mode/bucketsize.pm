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

package cloud::aws::s3::mode::bucketsize;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_metric_output {
    my ($self, %options) = @_;
    
    return "Bucket '" . $options{instance_value}->{display} . "' [" . ucfirst($options{instance_value}->{storage_type}) . "] " . $options{instance_value}->{stat} . " ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'metric', type => 1, cb_prefix_output => 'prefix_metric_output', message_multiple => "All size metrics are ok", skipped_code => { -10 => 1 } },
    ];

    foreach my $statistic ('minimum', 'maximum', 'average', 'sum') {
        foreach my $metric ('BucketSizeBytes') {
            foreach my $storage_type ('StandardStorage', 'StandardIAStorage', 'ReducedRedundancyStorage') {
                my $entry = { label => lc($metric) . '-' . lc($storage_type) . '-' . lc($statistic), set => {
                                    key_values => [ { name => $metric . '_' . $storage_type . '_' . $statistic }, { name => 'display' }, { name => 'storage_type' }, { name => 'stat' } ],
                                    output_template => $metric . ': %d %s',
                                    output_change_bytes => 1,
                                    perfdatas => [
                                        { label => lc($metric) . '_' . lc($storage_type) . '_' . lc($statistic), value => $metric . '_' . $storage_type . '_' . $statistic , 
                                        template => '%d', unit => 'B', min => 0, label_extra_instance => 1, instance_use => 'display' },
                                    ],
                                }
                            };
                push @{$self->{maps_counters}->{metric}}, $entry;
            }
        }
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                    "name:s@"	       => { name => 'name' },
                                    "storage-type:s@"  => { name => 'storage_type' },
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

    $self->{aws_timeframe} = defined($self->{option_results}->{timeframe}) ? $self->{option_results}->{timeframe} : 172800;
    $self->{aws_period} = defined($self->{option_results}->{period}) ? $self->{option_results}->{period} : 86400;
    
    $self->{aws_statistics} = ['Average'];
    if (defined($self->{option_results}->{statistic})) {
        $self->{aws_statistics} = [];
        foreach my $stat (@{$self->{option_results}->{statistic}}) {
            if ($stat ne '') {
                push @{$self->{aws_statistics}}, ucfirst(lc($stat));
            }
        }
    }

    foreach my $metric ('BucketSizeBytes') {
        next if (defined($self->{option_results}->{filter_metric}) && $self->{option_results}->{filter_metric} ne ''
            && $metric !~ /$self->{option_results}->{filter_metric}/);

        push @{$self->{aws_metrics}}, $metric;
    }

    $self->{aws_storage_type} = ['StandardStorage'];
    if (defined($self->{option_results}->{storage_type})) {
        $self->{aws_storage_type} = [];
        foreach my $storage_type (@{$self->{option_results}->{storage_type}}) {
            if ($storage_type ne '') {
                push @{$self->{aws_storage_type}}, $storage_type;
            }
        }
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my %metric_results;
    foreach my $instance (@{$self->{aws_instance}}) {
        foreach my $storage_type (@{$self->{aws_storage_type}}) {
            $metric_results{$instance} = $options{custom}->cloudwatch_get_metrics(
                namespace => 'AWS/S3',
                dimensions => [ {Name => 'StorageType', Value => $storage_type }, { Name => 'BucketName', Value => $instance } ],
                metrics => $self->{aws_metrics},
                statistics => $self->{aws_statistics},
                timeframe => $self->{aws_timeframe},
                period => $self->{aws_period}
            );
            
            foreach my $metric (@{$self->{aws_metrics}}) {
                foreach my $statistic (@{$self->{aws_statistics}}) {
                next if (!defined($metric_results{$instance}->{$metric}->{lc($statistic)}) && !defined($self->{option_results}->{zeroed}));

                    $self->{metric}->{$instance . "_" . $storage_type . "_" . lc($statistic)}->{display} = $instance;
                    $self->{metric}->{$instance . "_" . $storage_type . "_" . lc($statistic)}->{storage_type} = $storage_type;
                    $self->{metric}->{$instance . "_" . $storage_type . "_" . lc($statistic)}->{stat} = lc($statistic);
                    $self->{metric}->{$instance . "_" . $storage_type . "_" . lc($statistic)}->{$metric . "_" . $storage_type . "_" . lc($statistic)} = defined($metric_results{$instance}->{$metric}->{lc($statistic)}) ? $metric_results{$instance}->{$metric}->{lc($statistic)} : 0;
                }
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

Check S3 buckets size.

Example: 
perl centreon_plugins.pl --plugin=cloud::aws::s3::plugin --custommode=paws --mode=bucket-size --region='eu-west-1'
--name='centreon-iso' --critical-bucketsizebytes-standardiastorage-average='1000'
--storage-type='StandardIAStorage' --verbose

See 'https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/s3-metricscollected.html' for more informations.

Default statistic: 'average' / All satistics are valid.

=over 8

=item B<--name>

Set the instance name (Required) (Can be multiple).

=item B<--storage-type>

Set the storage type of the bucket (Default: 'StandardStorage')
(Can be multiple: 'StandardStorage', 'StandardIAStorage', 'ReducedRedundancyStorage').

=item B<--warning-$metric$-$storagetype$-$statistic$>

Thresholds warning ($metric$ can be: 'bucketsizebytes',
$storagetype$ can be: 'standardstorage',
'standardiastorage', 'reducedredundancystorage',
$statistic$ can be: 'minimum', 'maximum', 'average', 'sum').

=item B<--critical-$metric$-$storagetype$-$statistic$>

Thresholds critical ($metric$ can be: 'bucketsizebytes',
$storagetype$ can be: 'standardstorage',
'standardiastorage', 'reducedredundancystorage',
$statistic$ can be: 'minimum', 'maximum', 'average', 'sum').

=back

=cut
