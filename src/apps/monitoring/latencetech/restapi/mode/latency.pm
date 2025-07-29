#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package apps::monitoring::latencetech::restapi::mode::latency;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'latency', type => 1, cb_prefix_output => 'prefix_output', message_multiple => 'All latencies are OK', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{latency} = [
        { label => 'latency-average', nlabel => 'latency.average.milliseconds', set => {
                key_values => [ { name => 'latency_average' }, { name => 'points' }, { name => 'display' },{ name => 'protocol' } ],
                output_template => 'average: %.2fms',
                perfdatas => [
                    { value => 'latency_average', template => '%.2f',
                      min => 0, unit => 'ms', label_extra_instance => 1, instance_use => 'protocol' },
                ],
            }
        },
        { label => 'latency-minimum', nlabel => 'latency.minimum.milliseconds', set => {
                key_values => [ { name => 'latency_minimum' }, { name => 'protocol' } ],
                output_template => 'minimum: %.2fms',
                perfdatas => [
                    { value => 'latency_minimum', template => '%.2f',
                      min => 0, unit => 'ms', label_extra_instance => 1, instance_use => 'protocol' },
                ],
            }
        },
        { label => 'latency-maximum', nlabel => 'latency.maximum.milliseconds', set => {
                key_values => [ { name => 'latency_maximum' }, { name => 'protocol' } ],
                output_template => 'maximum: %.2fms',
                perfdatas => [
                    { value => 'latency_maximum', template => '%.2f',
                      min => 0, unit => 'ms', label_extra_instance => 1, instance_use => 'protocol' },
                ],
            }
        }
    ];
}

sub prefix_output {
    my ($self, %options) = @_;

    return sprintf('Latency for Agent %s, Protocol %s (%s points): ', $options{instance_value}->{display}, $options{instance_value}->{protocol}, $options{instance_value}->{points});
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-protocol:s'  => { name => 'filter_protocol' },
        'timerange:s'        => { name => 'time_range', default => '300'}
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    foreach my $protocol ('tcp', 'udp', 'http', 'https', 'icmp', 'twamp') {
        next if (defined($self->{option_results}->{filter_protocol}) && $self->{option_results}->{filter_protocol} ne '' &&
            $protocol !~ /$self->{option_results}->{filter_protocol}/i);

        my @get_param = [
            "protocol=$protocol",
            "time_range=$self->{option_results}->{time_range}"
        ];

        my $results = $options{custom}->request_api(endpoint => '/latency', get_param => @get_param);

        foreach my $timeserie (@{$results}) {
            $self->{latency}->{$protocol}->{display} = $timeserie->{agentID};
            $self->{latency}->{$protocol}->{protocol} = $timeserie->{measurement};
            $self->{timeseries}->{$protocol}->{points}++;
            $self->{timeseries}->{$protocol}->{total} += $timeserie->{value};
            $self->{timeseries}->{$protocol}->{metrics}->{minimum} = $timeserie->{value}
                if (!defined($self->{timeseries}->{$protocol}->{metrics}->{minimum}) || $timeserie->{value} < $self->{timeseries}->{$protocol}->{metrics}->{minimum});
            $self->{timeseries}->{$protocol}->{metrics}->{maximum} = $timeserie->{value} 
                if (!defined($self->{timeseries}->{$protocol}->{metrics}->{maximum}) || $timeserie->{value} > $self->{timeseries}->{$protocol}->{metrics}->{maximum});
        }
        $self->{timeseries}->{$protocol}->{metrics}->{average} = $self->{timeseries}->{$protocol}->{total} / $self->{timeseries}->{$protocol}->{points}++;
        $self->{latency}->{$protocol}->{points} = $self->{timeseries}->{$protocol}->{points};

        foreach (keys %{$self->{timeseries}->{$protocol}->{metrics}}) {
            $self->{latency}->{$protocol}->{"latency_" . $_} = $self->{timeseries}->{$protocol}->{metrics}->{$_};
        }
    }
}

1;

__END__

=head1 MODE

Check agent latency statistics.

=over 8

=item B<--agent-id>

Set the ID of the agent (mandatory option).

=item B<--filter-protocol>

Filter protocol if needed (can be a regexp)
Accepted values are C<tcp>, C<udp>, C<http>, C<https>, C<icmp>, C<twamp>.
=item B<--timerange>

Choose a timerange of values on wich datas shoud be aggregated (in seconds).
(default: '300')

=item B<--warning-latency-average>

Warning thresholds for average latency.

=item B<--critical-latency-average>

Critical thresholds for average latency.

=item B<--warning-latency-minimum>

Warning thresholds for minimum latency.

=item B<--critical-latency-minimum>

Critical thresholds for minimum latency.

=item B<--warning-latency-maximum>

Warning thresholds for maximum latency.

=item B<--critical-latency-maximum>

Critical thresholds for maximum latency.

=back

=cut
