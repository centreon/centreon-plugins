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

package apps::monitoring::nodeexporter::linux::mode::load;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::common::monitoring::openmetrics::scrape;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'load', type => 0, message_multiple => 'All nodes load are ok' },
    ];

    $self->{maps_counters}->{load} = [
        { label => 'load1', nlabel => 'load.1minute.count', set => {
                key_values => [ { name => 'node_load1' } ],
                output_template => 'Load 1 minute: %.2f',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'node_load1', value => 'node_load1', template => '%.2f',
                      min => 0 },
                ],
            }
        },
        { label => 'load5', nlabel => 'load.5minutes.count', set => {
                key_values => [ { name => 'node_load5' } ],
                output_template => 'Load 5 minutes: %.2f',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'node_load5', value => 'node_load5', template => '%.2f',
                      min => 0 },
                ],
            }
        },
        { label => 'load15', nlabel => 'load.15minutes.count', set => {
                key_values => [ { name => 'node_load15' } ],
                output_template => 'Load 15 minutes: %.2f',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'node_load15', value => 'node_load15', template => '%.2f',
                      min => 0 },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
    });
   
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
}

sub manage_selection {
    my ($self, %options) = @_;

    my $raw_metrics = centreon::common::monitoring::openmetrics::scrape::parse(%options, strip_chars => "[\"']");

    foreach my $metric (keys %{$raw_metrics}) {
        next if ($metric !~ /node_load1|node_load5|node_load15/i );

        $self->{load}->{$metric} = $raw_metrics->{$metric}->{data}[0]->{value};
    }

    if (scalar(keys %{$self->{load}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check node load based on node exporter metrics.

=over 8

=item B<--warning-*>

Warning threshold.

Can be: 'load1', 'load5', 'load15'.

=item B<--critical-*>

Warning threshold.

Can be: 'load1', 'load5', 'load15'.