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
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'mempool', cb_prefix_output => 'prefix_module_output', type => 0 }
    ];  

    $self->{maps_counters}->{mempool} = [
        { label => 'mempool', nlabel => 'parity.mempol.usage', set => {
                key_values => [ { name => 'mempool' } ],
                output_template => "Mempool: %d %% ",
                perfdatas => [
                    { label => 'mempool', value => 'mempool_absolute', template => '%d', min => 0 }
                ],                
            }
        },
    ];

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
       (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));

    my $query_form_post = [ { method => 'parity_versionInfo', params => [], id => "1", jsonrpc => "2.0" },
                            { method => 'parity_chain', params => [], id => "2", jsonrpc => "2.0" },
                            { method => 'parity_pendingTransactions', params => [], id => "3", jsonrpc => "2.0" } ,
                            { method => 'parity_netPeers', params => [], id => "4", jsonrpc => "2.0" },
                            { method => 'parity_enode', params => [], id => "5", jsonrpc => "2.0" },
                            { method => 'parity_nodeName', params => [], id => "6", jsonrpc => "2.0" },
                            { method => 'parity_transactionsLimit', params => [], id => "7", jsonrpc => "2.0" } ]; #TO CHECK parity_transactionsLimit could be done once, at the beginning of the process 
                            
    my $result = $options{custom}->request_api(method => 'POST', query_form_post => $query_form_post);

    use Data::Dumper;
    # print Dumper($result);

    # Parity version construction
    my $res_parity_version = @{$result}[0]->{result}->{version}->{major} . '.' . @{$result}[0]->{result}->{version}->{minor} .  '.' . @{$result}[0]->{result}->{version}->{patch};

    # Alerts management 
    # my $cache = Cache::File->new( cache_root => './parity-restapi-cache' );

    # if (my $cached_version = $cache->get('parity_version')) {
    #     if ($res_parity_version ne $cached_version) {
    #         #alert
    #     }
    # } else {
    #     $cache->set('parity_version', $res_parity_version);
    # }

    # if (my $cached_name = $cache->get('chain_name')) {
    #     if ($cached_name ne @{$result}[1]->{result}) {
    #         #alert
    #     }
    # } else {
    #     $cache->set('chain_name', @{$result}[1]->{result});
    # }
    
    # use Data::Dumper;
    # print Dumper($result);

    $self->{output}->output_add(long_msg => "Config: [chain name: " . @{$result}[1]->{result} . "] [parity version: " . $res_parity_version . "] [version_hash: " 
                                            . @{$result}[0]->{result}->{hash}  . "]", severity => 'OK');
    $self->{output}->output_add(long_msg => "Network: [peers_connected: " . @{$result}[3]->{result}->{connected} . "] [peers_max: " . @{$result}[3]->{result}->{max} . "] [peers: " 
                                            . scalar(@{$$result[3]->{result}->{peers}})  . "]", severity => 'OK');
    $self->{output}->output_add(long_msg => "Node: [node_name: " . @{$result}[5]->{result} . "] [enode: " . @{$result}[4]->{result}  . "]", severity => 'OK');
    $self->{output}->output_add(long_msg => "Mempool: [pending_transactions: " . scalar(@{$$result[2]->{result}})  . "]", severity => 'OK');

    $self->{mempool} = { mempool => scalar(@{$$result[2]->{result}}) / @{$result}[6]->{result} * 100 }; #TO CHECK division entière 
}

1;

__END__

=head1 MODE

Check parity module metrics parity (parity_versionInfo, parity_chain, parity_pendingTransactions, parity_netPeers, parity_enode, parity_nodeName, parity_transactionsLimit)

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
