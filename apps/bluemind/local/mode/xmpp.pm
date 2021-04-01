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

package apps::bluemind::local::mode::xmpp;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use bigint;

sub prefix_xmpp_output {
    my ($self, %options) = @_;
    
    return 'Instant messaging service ';
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'bm_xmpp', type => 0, cb_prefix_output => 'prefix_xmpp_output' }
    ];
    
    $self->{maps_counters}->{bm_xmpp} = [
        { label => 'packets-all', nlabel => 'xmpp.packets.all.count', set => {
                key_values => [ { name => 'packets_all', diff => 1 } ],
                output_template => 'all packets sent: %s',
                perfdatas => [
                    { value => 'packets_all', template => '%s', min => 0 }
                ]
            }
        },
        { label => 'packets-chat', nlabel => 'xmpp.packets.chat.count', display_ok => 0, set => {
                key_values => [ { name => 'packets_chat', diff => 1 } ],
                output_template => 'chat packets sent: %s',
                perfdatas => [
                    { value => 'packets_chat', template => '%s', min => 0 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
    });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    # bm-xmpp.packetsCount,type=all,meterType=Counter count=517791
    # bm-xmpp.packetsCount,type=chat,meterType=Counter count=12
    my $result = $options{custom}->execute_command(
        command => 'curl --unix-socket /var/run/bm-metrics/metrics-bm-xmpp.sock http://127.0.0.1/metrics',
        filter => 'packetsCount'
    );

    $self->{bm_xmpp} = {};
    foreach (keys %$result) {
        $self->{bm_xmpp}->{'packets_' . $1} = $result->{$_}->{count} if (/bm-xmpp\.packetsCount.*type=(all|chat)/);
    }

    $self->{cache_name} = 'bluemind_' . $self->{mode} . '_' . $options{custom}->get_hostname()  . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check instant messaging service.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='chat'

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'packets-all', 'packets-chat'.

=back

=cut
