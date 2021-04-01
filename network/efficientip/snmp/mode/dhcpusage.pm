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

package network::efficientip::snmp::mode::dhcpusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'ack', set => {
                key_values => [ { name => 'ack', diff => 1 } ],
                output_template => 'Ack : %s',
                perfdatas => [
                    { label => 'ack', value => 'ack', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'nack', set => {
                key_values => [ { name => 'nack', diff => 1 } ],
                output_template => 'Nack : %s',
                perfdatas => [
                    { label => 'nack', value => 'nack', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'offer', set => {
                key_values => [ { name => 'offer', diff => 1 } ],
                output_template => 'Offer : %s',
                perfdatas => [
                    { label => 'offer', value => 'offer', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'inform', set => {
                key_values => [ { name => 'inform', diff => 1 } ],
                output_template => 'Inform : %s',
                perfdatas => [
                    { label => 'inform', value => 'inform', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'decline', set => {
                key_values => [ { name => 'decline', diff => 1 } ],
                output_template => 'Decline : %s',
                perfdatas => [
                    { label => 'decline', value => 'decline', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'release', set => {
                key_values => [ { name => 'release', diff => 1 } ],
                output_template => 'Release : %s',
                perfdatas => [
                    { label => 'release', value => 'release', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'request', set => {
                key_values => [ { name => 'request', diff => 1 } ],
                output_template => 'Request : %s',
                perfdatas => [
                    { label => 'request', value => 'request', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'discover', set => {
                key_values => [ { name => 'discover', diff => 1 } ],
                output_template => 'Discover : %s',
                perfdatas => [
                    { label => 'discover', value => 'discover', template => '%s', min => 0 },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                });
                                
    return $self;
}

my $mapping = {
    eipDhcpStatName     => { oid => '.1.3.6.1.4.1.2440.1.3.2.22.1.2' },
    eipDhcpStatValue    => { oid => '.1.3.6.1.4.1.2440.1.3.2.22.1.3' },
};
my $oid_eipDhcpStatEntry = '.1.3.6.1.4.1.2440.1.3.2.22.1';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = "efficientip_" . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' . 
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
    
    $self->{global} = {};
    
    my $results = $options{snmp}->get_table(oid => $oid_eipDhcpStatEntry,
                                           nothing_quit => 1);
    foreach my $oid (keys %$results) {
        next if ($oid !~ /^$mapping->{eipDhcpStatName}->{oid}\.(.*)/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $results, instance => $instance);
        $self->{global}->{$result->{eipDhcpStatName}} = $result->{eipDhcpStatValue};
    }
}
    
1;

__END__

=head1 MODE

Check dhcp usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^request$'

=item B<--warning-*>

Threshold warning.
Can be: 'ack', 'nack', 'offer', 'inform', 'decline',
'release', 'request', 'discover'.

=item B<--critical-*>

Threshold critical.
Can be: 'ack', 'nack', 'offer', 'inform', 'decline',
'release', 'request', 'discover'.

=back

=cut