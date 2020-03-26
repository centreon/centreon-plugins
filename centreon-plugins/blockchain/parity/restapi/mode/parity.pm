#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package blockchain::parity::restapi::mode::parity;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'parity', cb_prefix_output => 'prefix_module_output', type => 0 },
    ];

    $self->{maps_counters}->{parity} = [
        { label => 'parity_version', nlabel => 'parity.version', set => {
                key_values => [ { name => 'parity_version' } ],
                output_template => "Parity version is: %s ",
                perfdatas => [
                    { label => 'parity_version', value => 'parity_version_absolute', template => '%s', min => 0 }
                ],                
            }
        },
        { label => 'parity_version_hash', nlabel => 'parity.version.hash', set => {
                key_values => [ { name => 'parity_version_hash' } ],
                output_template => "Parity version hash is: %s ",
                perfdatas => [
                    { label => 'parity_version_hash', value => 'parity_version_hash_absolute', template => '%s', min => 0 }
                ],                
            }
        },
        { label => 'chain_name', nlabel => 'parity.chain.name', set => {
                key_values => [ { name => 'chain_name' } ],
                output_template => "Chain name is: %s ",
                perfdatas => [
                    { label => 'chain_name', value => 'chain_name_absolute', template => '%s', min => 0 }
                ],                
            }
        },
        { label => 'pending_transactions', nlabel => 'parity.pending.transactions', set => {
                key_values => [ { name => 'pending_transactions' } ],
                output_template => "Pending transactions: %d ",
                perfdatas => [
                    { label => 'pending_transactions', value => 'pending_transactions_absolute', template => '%d', min => 0 }
                ],                
            }
        },
        { label => 'mempool', nlabel => 'parity.mempol.capacity', set => {
                key_values => [ { name => 'mempool' } ],
                output_template => "Mempool: %d % ",
                perfdatas => [
                    { label => 'mempool', value => 'mempool_absolute', template => '%d', min => 0 }
                ],                
            }
        },
        { label => 'peers_connected', nlabel => 'parity.peers.connected', set => {
                key_values => [ { name => 'peers_connected' } ],
                output_template => "Number of connected peers: %d ",
                perfdatas => [
                    { label => 'peers_connected', value => 'peers_connected_absolute', template => '%d', min => 0 }
                ],                
            }
        },
        { label => 'peers_max', nlabel => 'parity.peers.max.connected', set => {
                key_values => [ { name => 'peers_max' } ],
                output_template => "Maximum number of connected peers: %d ",
                perfdatas => [
                    { label => 'peers_max', value => 'peers_max_absolute', template => '%d', min => 0 }
                ],                
            }
        },
        { label => 'peers', nlabel => 'parity.peers', set => {
                key_values => [ { name => 'peers' } ],
                output_template => "Peers: %d ",
                perfdatas => [
                    { label => 'peers', value => 'peers_absolute', template => '%d', min => 0 }
                ],                
            }
        },
        { label => 'enode', nlabel => 'parity.node.enode.uri', set => {
                key_values => [ { name => 'enode' } ],
                output_template => "Node enode URI: %s ",
                perfdatas => [
                    { label => 'enode', value => 'enode_absolute', template => '%s', min => 0 }
                ],                
            }
        },
        { label => 'node_name', nlabel => 'parity.node.name', set => {
                key_values => [ { name => 'node_name' } ],
                output_template => "Node name: %s ",
                perfdatas => [
                    { label => 'node_name', value => 'node_name_absolute', template => '%s', min => 0 }
                ],                
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'unknown-status:s'  => { name => 'unknown_status', default => '' },
        'warning-status:s'  => { name => 'warning_status', default => '' },
        'critical-status:s' => { name => 'critical_status', default => '%{listening} !~ /true/' },
    });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['unknown_status', 'warning_status', 'critical_status']);
}

sub prefix_module_output {
    my ($self, %options) = @_;
    
    return "Parity module: ";
}

sub manage_selection {
    my ($self, %options) = @_;

    my $query_form_post = [ { method => 'parity_versionInfo', params => [], id => "1", jsonrpc => "2.0" },
                            { method => 'parity_chain', params => [], id => "2", jsonrpc => "2.0" },
                            { method => 'parity_pendingTransactions', params => [], id => "3", jsonrpc => "2.0" } ,
                            { method => 'parity_netPeers', params => [], id => "4", jsonrpc => "2.0" },
                            { method => 'parity_enode', params => [], id => "5", jsonrpc => "2.0" },
                            { method => 'parity_nodeName', params => [], id => "6", jsonrpc => "2.0" },
                            { method => 'parity_transactionsLimit', params => [], id => "7", jsonrpc => "2.0" } # could be done once, at the beginning of the process 
                            ];

    my $result = $options{custom}->request_api(method => 'POST', query_form_post => $query_form_post);

    # Parity version construction
    my $res_parity_version = @{$result}[0]->{result}->{version}->{major} . @{$result}[0]->{result}->{version}->{minor} . @{$result}[0]->{result}->{version}->{patch};

    $self->{eth} = { parity_version => $res_parity_version,
                     parity_version_hash => @{$result}[0]->{result}->{hash},
                     chain_name => @{$result}[1]->{result},
                     pending_transactions => scalar @{$result}[2]->{result},
                     mempool => @{$result}[2]->{result} / @{$result}[6]->{result} * 100,
                     peers_connected => @{$result}[3]->{result}->{connected},
                     peers_max => @{$result}[3]->{result}->{max},
                     peers => scalar @{$result}[3]->{result}->{peers},
                     enode => @{$result}[4]->{result},
                     node_name => @{$result}[5]->{result} };

}

1;

__END__

=head1 MODE

Check parity module metrics parity (parity_versionInfo, )

=over 8

=item B<--unknown-status>

Set unknown threshold for listening status (Default: '').

=item B<--warning-status>

Set warning threshold for listening status (Default: '').

=item B<--critical-status>

Set critical threshold for listening status (Default: '%{listening} !~ /true/').

=item B<--warning-peers> B<--critical-peers>

Warning and Critical threhsold on the number of peer

=back

=cut
