#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

package apps::lync::2013::mssql::mode::audioqoe;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'jittermin', type => 0 },
        { name => 'jittermax', type => 0 },
        { name => 'jitteravg', type => 0 },
        { name => 'pcktlossmin', type => 0 },
        { name => 'pcktlossmax', type => 0 },
        { name => 'pcktlossavg', type => 0 },
    ];

    $self->{maps_counters}->{jittermin} = [
        { label => 'jitter-min', set => {
                key_values => [ { name => 'min' } ],
                output_template => 'Jitter(Min) : %d ms',
                perfdatas => [
                    { label => 'jitter_min', value => 'min_absolute', template => '%d',
                      unit => 'ms', min => 0, label_extra_instance => 0 },
                ],
            }
        },
    ];
    $self->{maps_counters}->{jittermax} = [
        { label => 'jitter-max', set => {
                key_values => [ { name => 'max' } ],
                output_template => 'Jitter(Max) : %d ms',
                perfdatas => [
                    { label => 'jitter_max', value => 'max_absolute', template => '%d',
                      unit => 'ms', min => 0, label_extra_instance => 0 },
                ],
            }
        },
    ];
    $self->{maps_counters}->{jitteravg} = [
        { label => 'jitter-avg', set => {
                key_values => [ { name => 'avg' } ],
                output_template => 'Jitter(Avg) : %d ms',
                perfdatas => [
                    { label => 'jitter_avg', value => 'avg_absolute', template => '%d', 
                      unit => 'ms', min => 0, label_extra_instance => 0 },
                ],
            }
        },
    ];
    $self->{maps_counters}->{pcktlossmin} = [
        { label => 'loss-min', set => {
                key_values => [ { name => 'min' } ],
                output_template => 'Packet-loss(Min) : %.2f%%',
                perfdatas => [
                    { label => 'pckt_loss_min', value => 'min_absolute', template => '%.2f',
                      unit => '%', min => 0, max => 100,  label_extra_instance => 0 },
                ],
            }
        },
    ];
    $self->{maps_counters}->{pcktlossmax} = [
        { label => 'loss-max', set => {
                key_values => [ { name => 'max' } ],
                output_template => 'Packet-loss(Max) : %.2f%%',
                perfdatas => [
                    { label => 'pckt_loss_max', value => 'max_absolute', template => '%.2f',
                      unit => '%', min => 0, max => 100 },
                ],
            }
        },
    ];
    $self->{maps_counters}->{pcktlossavg} = [
        { label => 'loss-avg', set => {
                key_values => [ { name => 'avg' } ],
                output_template => 'Packet-loss(Avg) : %.2f%%',
                perfdatas => [
                    { label => 'pckt_loss_avg', value => 'avg_absolute', template => '%.2f',
                      unit => '%', min => 0, max => 100, label_extra_instance => 0 },
                ],
            }
        },
    ];

}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                });
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;
    # $options{sql} = sqlmode object
    $self->{sql} = $options{sql};
    $self->{sql}->connect();

    $self->{sql}->query(query => q{select min(cast(JitterInterArrival as bigint)) as JitterMin,
                                          max(cast(JitterInterArrival as bigint)) as JitterMax,
                                          avg(cast(JitterInterArrival as bigint)) as JitterAvg,
                                          min(PacketLossRate) as PacketLossMin,
                                          max(PacketLossRate) as PacketLossMax,
                                          avg(PacketLossRate) as PacketLossRateAvg
                                   from [QoEMetrics].[dbo].AudioStream
                                   }
                        );

    my ($jittermin, $jittermax, $jitteravg, $pcktlossmin, $pcktlossmax, $pcktlossavg) = $self->{sql}->fetchrow_array();

    $self->{jittermin} = { min => $jittermin };
    $self->{jittermax} = { max => $jittermax };
    $self->{jitteravg} = { avg => $jitteravg };
    $self->{pcktlossmin} = { min => $pcktlossmin };
    $self->{pcktlossmax} = { max => $pcktlossmax };
    $self->{pcktlossavg} = { avg => $pcktlossavg }; 

}

1;

__END__

=head1 MODE

Check audio metrics QoE from SQL Server Lync Database [QoEMetrics].[dbo].AudioStream

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).

=item B<--warning-*>

Set warning threshold for number of user. Can be : 'jitter-min', 'jitter-max', 'jitter-avg', 'loss-min', 'loss-max', 'loss-avg'

=item B<--critical-*>

Set critical threshold for number of user. Can be : 'jitter-min', 'jitter-max', 'jitter-avg', 'loss-min', 'loss-max', 'loss-avg'

=back

=cut
