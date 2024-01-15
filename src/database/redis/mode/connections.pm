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

package database::redis::mode::connections;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub prefix_connections_output {
    my ($self, %options) = @_;
    
    return 'Number of connections ';
}

sub prefix_traffic_output {
    my ($self, %options) = @_;
    
    return 'Network usage ';
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'connections', type => 0, cb_prefix_output => 'prefix_connections_output' },
        { name => 'traffic', type => 0, cb_prefix_output => 'prefix_traffic_output' }
    ];
    
    $self->{maps_counters}->{connections} = [
        { label => 'received-connections', nlabel => 'connections.received.count', set => {
                key_values => [ { name => 'total_connections_received', diff => 1 } ],
                output_template => 'received: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'rejected-connections', nlabel => 'connections.rejected.count', set => {
                key_values => [ { name => 'rejected_connections', diff => 1 } ],
                output_template => 'rejected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{traffic} = [
        { label => 'traffic-in', nlabel => 'network.traffic.in.bitspersecond', set => {
                key_values => [ { name => 'total_net_input_bytes', per_second => 1 } ],
                output_template => 'traffic in: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%d', min => 0, unit => 'b/s' }
                ]
            }
        },
        { label => 'traffic-out', nlabel => 'network.traffic.out.bitspersecond', set => {
                key_values => [ { name => 'total_net_output_bytes', per_second => 1 } ],
                output_template => 'traffic out: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%d', min => 0, unit => 'b/s' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments =>  {});

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = 'redis_database_' . $self->{mode} . '_' . $options{custom}->get_connection_info() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));

    my $results = $options{custom}->get_info();
    $self->{connections} = { 
        total_connections_received => $results->{total_connections_received},
        rejected_connections       => $results->{rejected_connections}
    };
    $self->{traffic} = {
        total_net_input_bytes  => $results->{total_net_input_bytes} * 8,
        total_net_output_bytes => $results->{total_net_output_bytes} * 8
    };
}

1;

__END__

=head1 MODE

Check connections number and network usage

=over 8

=item B<--warning-received-connections>

Warning threshold for received connections

=item B<--critical-received-connections>

Critical threshold for received connections

=item B<--warning-rejected-connections>

Warning threshold for rejected connections

=item B<--critical-rejected-connections>

Critical threshold for rejected connections

=item B<--warning-traffic-in>

Warning threshold for inbound traffic (b/s)

=item B<--critical-traffic-in>

Critical threshold for inbound traffic (b/s)

=item B<--warning-traffic-out>

Warning threshold for outbound traffic (b/s)

=item B<--critical-traffic-out>

Critical thresholdfor outbound traffic (b/s)

=back

=cut
