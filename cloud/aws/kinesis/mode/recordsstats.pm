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

package cloud::aws::kinesis::mode::recordsstats;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

my %metrics_mapping = (
    'GetRecords.IteratorAgeMilliseconds' => {
        'output' => 'Get Records Iterator Age',
        'label' => 'records-get-iteratorage',
        'nlabel' => 'kinesis.stream.records.get.iteratorage.milliseconds',
        'perf_unit' => 'ms',
        'change_bytes' => '0',
        'stats' => { 'sum' => 'false' }
    },
    'GetRecords.Bytes' => {
        'output' => 'Get Records Bytes',
        'label' => 'records-get-volume',
        'nlabel' => 'kinesis.stream.records.get.volume.bytes',
        'perf_unit' => 'B',
        'change_bytes' => '2',
    },
    'GetRecords.Latency' => {
        'output' => 'Get Records Latency',
        'label' => 'records-get-latency',
        'nlabel' => 'kinesis.stream.records.get.latency.milliseconds',
        'perf_unit' => 'ms',
        'change_bytes' => '0',
        'stats' => { 'sum' => 'false' }
    },
    'GetRecords.Success' => {
        'output' => 'Get Records Success',
        'label' => 'records-get-success',
        'nlabel' => 'kinesis.stream.records.get.success.count',
        'perf_unit' => '',
        'change_bytes' => '0',
        'stats' => { 'average' => 'false' }
    },
    'PutRecord.Latency' => {
        'output' => 'Put Records Latency',
        'label' => 'records-put-latency',
        'nlabel' => 'kinesis.stream.records.put.latency.milliseconds',
        'perf_unit' => 'ms',
        'change_bytes' => '0',
        'stats' => { 'sum' => 'false' }
    },
    'PutRecord.Bytes' => {
        'output' => 'Put Records Bytes',
        'label' => 'records-put-volume',
        'nlabel' => 'kinesis.stream.records.put.volume.bytes',
        'perf_unit' => 'B',
        'change_bytes' => '2'
    },
    'PutRecord.Success' => {
        'output' => 'Put Records Success',
        'label' => 'records-put-success',
        'nlabel' => 'kinesis.stream.records.put.success.count',
        'perf_unit' => '',
        'change_bytes' => '0',
        'stats' => { 'average' => 'false' }
    },
);

sub prefix_metric_output {
    my ($self, %options) = @_;
    
    return " '" . $options{instance_value}->{display} . "' ";
}

sub prefix_statistics_output {
    my ($self, %options) = @_;
    
    return "Statistic '" . $options{instance_value}->{display} . "' Metrics ";
}

sub long_output {
    my ($self, %options) = @_;

    return "Checking'" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'metrics', type => 3, cb_prefix_output => 'prefix_metric_output', cb_long_output => 'long_output',
          message_multiple => 'All records to streams metrics are ok', indent_long_output => '    ',
            group => [
                { name => 'statistics', display_long => 1, cb_prefix_output => 'prefix_statistics_output',
                  message_multiple => 'All records to streams metrics are ok', type => 1, skipped_code => { -10 => 1 } },
            ]
        }
    ];

    foreach my $metric (keys %metrics_mapping) {
        my $entry = {
            label => $metrics_mapping{$metric}->{label},
            nlabel => $metrics_mapping{$metric}->{nlabel},
            set => {
                key_values => [ { name => $metric }, { name => 'display' } ],
                output_template => ($metrics_mapping{$metric}->{change_bytes} != 0) ? $metrics_mapping{$metric}->{output} . ': %.2f %s' : $metrics_mapping{$metric}->{output} . ': %.2f',
                change_bytes => $metrics_mapping{$metric}->{output_change_bytes},
                perfdatas => [
                    { value => $metric , template => '%.2f', label_extra_instance => 1, unit => $metrics_mapping{$metric}->{perf_unit} }
                ],
            }
        };
        push @{$self->{maps_counters}->{statistics}}, $entry;
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, force_new_perfdata => 1,  %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'stream-name:s@'  => { name => 'stream_name' },
        'filter-metric:s' => { name => 'filter_metric' },
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    foreach my $instance (@{$self->{option_results}->{stream_name}}) {
        if ($instance ne '') {
            push @{$self->{aws_instance}}, $instance;
        }
    }

    $self->{aws_timeframe} = defined($self->{option_results}->{timeframe}) ? $self->{option_results}->{timeframe} : 600;
    $self->{aws_period} = defined($self->{option_results}->{period}) ? $self->{option_results}->{period} : 60;
    
    $self->{aws_statistics} = ['Average','Sum'];
    if (defined($self->{option_results}->{statistic})) {
        $self->{aws_statistics} = [];
        foreach my $stat (@{$self->{option_results}->{statistic}}) {
            if ($stat ne '') {
                push @{$self->{aws_statistics}}, ucfirst(lc($stat));
            }
        }
    }

    foreach my $metric (keys %metrics_mapping) {
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
            namespace => 'AWS/Kinesis',
            dimensions => [ { Name => 'StreamName', Value => $instance } ],
            metrics => $self->{aws_metrics},
            statistics => $self->{aws_statistics},
            timeframe => $self->{aws_timeframe},
            period => $self->{aws_period},
        );
        foreach my $metric (@{$self->{aws_metrics}}) {
            foreach my $statistic (@{$self->{aws_statistics}}) {
                next if (!defined($metric_results{$instance}->{$metric}->{lc($statistic)})
                    && !defined($self->{option_results}->{zeroed}) 
                    || defined($metrics_mapping{$metric}->{stats}->{lc($statistic)})
                    && $metrics_mapping{$metric}->{stats}->{lc($statistic)} eq "false");
                    
                $self->{metrics}->{$instance}->{display} = $instance;
                $self->{metrics}->{$instance}->{statistics}->{lc($statistic)}->{display} = $statistic;
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

Check metrics about records statistics in Kinesis streams.

=over 8

=item B<--name>

Set the stream name (Required) (Can be multiple).

=item B<--filter-metric>

Filter metrics (Can be: 'GetRecords.IteratorAgeMilliseconds', 'GetRecords.Bytes', ) 

=item B<--warning-*> B<--critical-*>

Thresholds warning
can be: 'records-get-iteratorage', 'records-get-volume',
'records-get-latency', 'records-get-success',
'records-put-volume', 'records-put-latency',
'records-get-success',

=back

=cut
