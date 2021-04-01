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

package network::efficientip::snmp::mode::dnsusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
    ];
    
    my @map = ('udp', 'UDP Queries received : %s', 'tcp', 'TCP Queries received : %s', 
        'requestv4', 'IPv4 Queries received : %s', 'requestv6', 'IPv6 Queries received : %s', 
        'recursion', 'Queries requiring recursion : %s', 'response', 'Responses : %s',
        'recurserej', 'Recursive queries : %s', 'duplicate', 'Duplicate queries received : %s', 
        'dropped', 'Queries Dropped : %s', 'res-queryv4', 'Queries sent to external IPv4 DNS servers : %s', 
        'res-queryv6', 'Queries sent to external IPv6 DNS servers : %s', 'res-retry', 'Retried Queries to external DNS servers : %s',
        'res-responsev4', 'Responses from external IPv4 DNS servers : %s', 'res-responsev6', 'Responses from external IPv6 DNS servers : %s', 
        'success', 'Sent NOERROR : %s', 'formerr', 'Sent FORMERR : %s', 'servfail', 'Sent SERVFAIL : %s', 
        'nxdomain', 'Sent NXDOMAIN : %s', 'nxrrset', 'Sent nxrrset : %s', 'failure', 'Sent Other failure : %s',
        'xfrdone', 'Transfert Queries Completed : %s', 'xfrrej' , 'Transfert Queries Rejected : %s', 
        'res-val', 'DNSSEC validation attempted : %s', 'res-valsuccess', 'DNSSEC validation succeeded : %s', 
        'res-valnegsuccess', 'DNSSEC NX validation succeeded : %s', 'res-valfail', 'DNSSEC validation failed : %s');
    
    $self->{maps_counters}->{global} = [];
    for (my $i = 0; $i < scalar(@map); $i += 2) {
        push @{$self->{maps_counters}->{global}}, { label => $map[$i], set => {
                key_values => [ { name => $map[$i], diff => 1 } ],
                output_template => $map[$i + 1],
                perfdatas => [
                    { label => $map[$i], value => $map[$i] , template => '%s', min => 0 },
                ],
            }
        },
    }
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
    eipDnsStatName  => { oid => '.1.3.6.1.4.1.2440.1.4.2.3.1.2' },
    eipDnsStatValue => { oid => '.1.3.6.1.4.1.2440.1.4.2.3.1.3' },
};
my $oid_eipDnsStatEntry = '.1.3.6.1.4.1.2440.1.4.2.3.1';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = "efficientip_" . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' . 
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
    
    $self->{global} = {};
    
    my $results = $options{snmp}->get_table(oid => $oid_eipDnsStatEntry,
                                           nothing_quit => 1);
    foreach my $oid (keys %$results) {
        next if ($oid !~ /^$mapping->{eipDnsStatName}->{oid}\.(.*)/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $results, instance => $instance);
        $result->{eipDnsStatName} =~ s/_/-/g;
        $self->{global}->{$result->{eipDnsStatName}} = $result->{eipDnsStatValue};
    }
}
    
1;

__END__

=head1 MODE

Check dhcp usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^requestv4$'

=item B<--warning-*>

Threshold warning.

=item B<--critical-*>

Threshold critical.

General name server statistics: 'udp', 'tcp', 'requestv4', 'requestv6', 'recursion', 'response',
'recurserej', 'duplicate', 'dropped', 'res-queryv4', 'res-queryv6', 'res-retry',
'res-responsev4', 'res-responsev6'.
DNS answers statistics: 'success', 'formerr', 'servfail', 'nxdomain', 'nxrrset', 'failure'.
DNS Transfer Requests Statistics: 'xfrdone', 'xfrrej'.
DNSSEC Validation Statistics: 'res-val', 'res-valsuccess', 'res-valnegsuccess', 'res-valfail'.

=back

=cut