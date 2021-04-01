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

package blockchain::parity::restapi::mode::parity;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'mempool', cb_prefix_output => 'prefix_module_output', type => 0 },
        { name => 'peers', cb_prefix_output => 'prefix_module_output', type => 0 }
    ];  

    $self->{maps_counters}->{mempool} = [
        { label => 'mempool-tx-pending', nlabel => 'parity.pending.transactions', set => {
                key_values => [ { name => 'tx_pending' } ],
                output_template => "Pending transactions: %d",
                perfdatas => [
                    { label => 'tx_pending', value => 'tx_pending', template => '%d', min => 0 }
                ],                
            }
        },
        { label => 'mempool-size', nlabel => 'parity.mempol.size', set => {
                key_values => [ { name => 'mempool_size' } ],
                output_template => "Mempool size: %d",
                perfdatas => [
                    { label => 'mempool_size', value => 'mempool_size', template => '%d', min => 0 }
                ],                
            }
        },
        { label => 'mempool-usage', nlabel => 'parity.mempol.usage', set => {
                key_values => [ { name => 'mempool_usage' } ],
                output_template => "Mempool usage: %d %% ",
                perfdatas => [
                    { label => 'mempool_usage', value => 'mempool_usage', template => '%.2f', unit => '%', min => 0 }
                ],                
            }
        },
    ];

    $self->{maps_counters}->{peers} = [
        { label => 'peers-connected', nlabel => 'parity.peers.connected', set => {
                key_values => [ { name => 'peers_connected' } ],
                output_template => "Connected peers: %d",
                perfdatas => [
                    { label => 'peers_connected', value => 'peers_connected', template => '%d', min => 0 }
                ],                
            }
        },
        { label => 'peers-max', nlabel => 'parity.peers.max', set => {
                key_values => [ { name => 'peers_max' } ],
                output_template => "Peers max: %d",
                perfdatas => [
                    { label => 'peers_max', value => 'peers_max', template => '%d', min => 0 }
                ],                
            }
        },
        { label => 'peers-usage', nlabel => 'parity.peers.usage', set => {
                key_values => [ { name => 'peers_usage' } ],
                output_template => "Peers usage: %d %% ",
                perfdatas => [
                    { label => 'peers_usage', value => 'peers_usage', template => '%.2f', unit => '%', min => 0 }
                ],                
            }
        },
    ];

}

sub custom_peers_output {
    my ($self, %options) = @_;

    return sprintf(
        "Connected peers: %d / %d",
        $self->{result_values}->{peers_connected},
        $self->{result_values}->{peers_limit}
    );
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1, statefile => 1);
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

    $self->{cache_name} = "parity_restapi_" . $self->{mode} . '_' . (defined($self->{option_results}->{hostname}) ? $self->{option_results}->{hostname} : 'me') . '_' .
           (defined($self->{option_results}->{port}) ? $self->{option_results}->{port} : 'default') . '_' .
           (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));

    my $query_form_post = [ { method => 'parity_versionInfo', params => [], id => "1", jsonrpc => "2.0" },
                            { method => 'parity_chain', params => [], id => "2", jsonrpc => "2.0" },
                            { method => 'parity_pendingTransactions', params => [], id => "3", jsonrpc => "2.0" } ,
                            { method => 'parity_netPeers', params => [], id => "4", jsonrpc => "2.0" },
                            { method => 'parity_enode', params => [], id => "5", jsonrpc => "2.0" },
                            { method => 'parity_nodeName', params => [], id => "6", jsonrpc => "2.0" },
                            { method => 'parity_transactionsLimit', params => [], id => "7", jsonrpc => "2.0" }, 
                            { method => 'net_peerCount', params => [], id => "8", jsonrpc => "2.0" } ]; 
                            
    my $result = $options{custom}->request_api(method => 'POST', query_form_post => $query_form_post);

    my $res_parity_version = @{$result}[0]->{result}->{version}->{major} . '.' . @{$result}[0]->{result}->{version}->{minor} .  '.' . @{$result}[0]->{result}->{version}->{patch};

    $self->{mempool} = { mempool_usage => scalar(@{$$result[2]->{result}}) / @{$result}[6]->{result} * 100, 
                         mempool_size => @{$result}[6]->{result},
                         tx_pending => scalar(@{$$result[2]->{result}}) }; 

    $self->{peers} = { peers_usage => @{$result}[3]->{result}->{connected} / @{$result}[3]->{result}->{max} * 100, 
                       peers_max => @{$result}[3]->{result}->{max},
                       peers_limit => @{$result}[3]->{result}->{max},
                       peers_connected => @{$result}[3]->{result}->{connected} }; 
}

1;

__END__

=head1 MODE

Check parity module metrics parity (Mempool and peers)