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

package apps::protocols::tcp::mode::responsetime;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Time::HiRes qw(gettimeofday tv_interval);
use IO::Socket::INET;

sub prefix_output {
    my ($self, %options) = @_;

    return sprintf(
        "TCP '%s' port %s ",
        $options{instance_value}->{hostname},
        $options{instance_value}->{port}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_output' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'rta', nlabel => 'tcp.roundtrip.time.average.milliseconds', set => {
                key_values => [ { name => 'rta' } ],
                output_template => 'rta %.3fms',
                perfdatas => [
                    { template => '%.3f', min => 0, unit => 'ms' }
                ]
            }
        },
        { label => 'rtmax', nlabel => 'tcp.roundtrip.time.maximum.milliseconds', display_ok => 0, set => {
                key_values => [ { name => 'rtmax' } ],
                perfdatas => [
                    { template => '%.3f', min => 0, unit => 'ms' }
                ]
            }
        },
        { label => 'rtmin', nlabel => 'tcp.roundtrip.time.minimum.milliseconds', display_ok => 0, set => {
                key_values => [ { name => 'rtmin' } ],
                perfdatas => [
                    { template => '%.3f', min => 0, unit => 'ms' }
                ]
            }
        },
        { label => 'pl', nlabel => 'tcp.packets.loss.percentage', set => {
                key_values => [ { name => 'pl' } ],
                output_template => 'lost %s%%',
                perfdatas => [
                    { template => '%s', min => 0, max => 100, unit => '%' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'hostname:s' => { name => 'hostname' },
        'port:s'     => { name => 'port' },
        'timeout:s'  => { name => 'timeout', default => 5 },
        'packets:s'  => { name => 'packets', default => 5 }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{hostname})) {
        $self->{output}->add_option_msg(short_msg => 'Please set the hostname option');
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{port}) || $self->{option_results}->{port} !~ /(\d+)/) {
        $self->{output}->add_option_msg(short_msg => 'Please set the port option');
        $self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $total_time_elapsed = 0;
    my $max_time_elapsed = 0;
    my $min_time_elapsed = 0;
    my $total_packet_lost = 0;
    for (my $i = 0; $i < $self->{option_results}->{packets}; $i++) {
        my $timing0 = [gettimeofday];
        my $return = IO::Socket::INET->new(
            PeerAddr => $self->{option_results}->{hostname},
            PeerPort => $self->{option_results}->{port},
            Timeout => $self->{option_results}->{timeout}
        );
        my $timeelapsed = tv_interval($timing0, [gettimeofday]);

        if (!defined($return)) {
            $total_packet_lost++;
        } else {
            $total_time_elapsed += $timeelapsed;
            $max_time_elapsed = $timeelapsed if ($timeelapsed > $max_time_elapsed);
            $min_time_elapsed = $timeelapsed if ($timeelapsed < $min_time_elapsed || $min_time_elapsed == 0);
            close($return);
        }
    }

    $self->{global} = {
        hostname => $self->{option_results}->{hostname},
        port => $self->{option_results}->{port},
        rta => ($self->{option_results}->{packets} > $total_packet_lost) ? $total_time_elapsed * 1000 / ($self->{option_results}->{packets} - $total_packet_lost) : 0,
        rtmax => $max_time_elapsed * 1000,
        rtmin => $min_time_elapsed * 1000,
        pl => int($total_packet_lost * 100 / $self->{option_results}->{packets})
    };
}
    
1;

__END__

=head1 MODE

Check TCP port response time.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example : --filter-counters='rta'

=item B<--hostname>

IP Addr/FQDN of the host

=item B<--port>

Port used

=item B<--timeout>

Set timeout in seconds (default: 5).

=item B<--packets>

Number of packets to send (default: 5).

=item B<--warning-rta>

Response time threshold warning in milliseconds

=item B<--critical-rta>

Response time threshold critical in milliseconds

=item B<--warning-pl>

Packets lost threshold warning in %

=item B<--critical-pl>

Packets lost threshold critical in %

=back

=cut
