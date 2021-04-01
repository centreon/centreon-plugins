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

package apps::openvpn::omi::mode::serverusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'num-clients', nlabel => 'clients.current.count',set => {
                key_values => [ { name => 'num_clients' } ],
                output_template => 'Current Clients: %s',
                perfdatas => [
                    { label => 'num_clients', template => '%s', min => 0 }
                ]
            }
        },
        { label => 'traffic-in', nlabel => 'server.traffic.in.bitspersecond',set => {
                key_values => [ { name => 'traffic_in', per_second => 1 } ],
                output_change_bytes => 2,
                output_template => 'Traffic In: %s %s/s',
                perfdatas => [
                    { label => 'traffic_in', template => '%.2f', min => 0, unit => 'b/s' }
                ]
            }
        },
        { label => 'traffic-out', nlabel => 'server.traffic.out.bitspersecond', set => {
                key_values => [ { name => 'traffic_out', per_second => 1 } ],
                output_change_bytes => 2,
                output_template => 'Traffic Out: %s %s/s',
                perfdatas => [
                    { label => 'traffic_out', template => '%.2f', min => 0, unit => 'b/s' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->command(cmd => 'load-stats');
    # SUCCESS: nclients=6,bytesin=7765329961,bytesout=18435500727

    $self->{global} = { num_clients => 0, traffic_in => 0, traffic_out => 0 };
    if ($result =~ /nclients=(\d+),bytesin=(\d+),bytesout=(\d+)/) {
        $self->{global} = { num_clients => $1, traffic_in => $2 * 8, traffic_out => $3 * 8 };
    }

    #status
    #OpenVPN CLIENT LIST
    #Updated,Thu Jan 10 16:05:32 2019
    #Common Name,Real Address,Bytes Received,Bytes Sent,Connected Since
    #plop1,xxxx.xxx.xxx.xxxx:56702,104525967,29529209,Thu Jan 10 08:53:46 2019
    #plop2,xxx.xxxx.xxx.xxx:39374,1814536,8630412,Thu Jan 10 15:27:13 2019
    #plop3,xxx.xxxx.xxxx.xxxx:62866,8208936,85352252,Thu Jan 10 08:14:49 2019
    #ROUTING TABLE
    #Virtual Address,Common Name,Real Address,Last Ref
    #10.8.1.xxx,plop1,xxx.xx.xx.xxx:53725,Thu Jan 10 16:05:31 2019
    #...
    #GLOBAL STATS
    #Max bcast/mcast queue length,9
    #END
    if ($self->{output}->is_verbose()) {
        $result = $options{custom}->command(cmd => 'status');
        if ($result =~ /OpenVPN CLIENT LIST\n(.*?)ROUTING TABLE/ms) {
            my @users = split /\n/, $1;
            splice @users, 0, 2;
            foreach (@users) {
                my ($user) = split /,/;
                $self->{output}->add_option_msg(long_msg => "user '$user' connected");
            }
        }
    }

    $self->{cache_name} = 'openvpn_' . $self->{mode} . '_' . $options{custom}->get_connect_info() . '_' . 
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check server usage.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'num-clients', 'traffic-in', 'traffic-out'.

=back

=cut
