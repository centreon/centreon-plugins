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

package blockchain::parity::restapi::mode::eth;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use bigint;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'Client mininig status: %s ',
        $self->{result_values}->{is_mining},
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', cb_prefix_output => 'prefix_module_output', type => 0 },
        { name => 'block', cb_prefix_output => 'prefix_module_output', type => 0 },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'gas_price', nlabel => 'parity.eth.gas.price', set => {
                key_values => [ { name => 'gas_price' } ],
                output_template => "The gas price is: %d wei ",
                perfdatas => [
                    { label => 'gas_price', value => 'gas_price_absolute', template => '%d', min => 0 }
                ],                
            }
        }
    ];

    $self->{maps_counters}->{block} = [  
        { label => 'block_size', nlabel => 'parity.eth.block.size', set => {
                key_values => [ { name => 'block_size' } ],
                output_template => "Most recent block size: %d ",
                perfdatas => [
                    { label => 'block_size', value => 'block_size_absolute', template => '%d', min => 0 }
                ],                
            }
        },
        { label => 'block_transactions', nlabel => 'parity.eth.block.transactions.number', set => {
                key_values => [ { name => 'block_transactions' } ],
                output_template => "Block transactions number: %d ",
                perfdatas => [
                    { label => 'block_transactions', value => 'block_transactions_absolute', template => '%d', min => 0 }
                ],                
            }
        },
        { label => 'block_gas', nlabel => 'parity.eth.block.gas', set => {
                key_values => [ { name => 'block_gas' } ],
                output_template => "Block gas: %d ",
                perfdatas => [
                    { label => 'block_gas', value => 'block_gas_absolute', template => '%d', min => 0 }
                ],                
            }
        },
        { label => 'block_difficulty', nlabel => 'parity.eth.block.difficulty', set => {
                key_values => [ { name => 'block_difficulty' } ],
                output_template => "Block difficulty: %f ",
                perfdatas => [
                    { label => 'block_difficulty', value => 'block_difficulty_absolute', template => '%f', min => 0 }
                ],                
            }
        },
        { label => 'block_uncles', nlabel => 'parity.eth.block.difficulty', set => {
                key_values => [ { name => 'block_uncles' } ],
                output_template => "Block uncles: %d ",
                perfdatas => [
                    { label => 'block_uncles', value => 'block_uncles_absolute', template => '%d', min => 0 }
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
    
    return "Parity Eth module: ";
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = "parity_restapi_" . $self->{mode} . '_' . (defined($self->{option_results}->{hostname}) ? $self->{option_results}->{hostname} : 'me') . '_' .
       (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));

    my $query_form_post = [ { method => 'eth_mining', params => [], id => "1", jsonrpc => "2.0" },
                            { method => 'eth_coinbase', params => [], id => "2", jsonrpc => "2.0" },
                            { method => 'eth_gasPrice', params => [], id => "3", jsonrpc => "2.0" } ,
                            { method => 'eth_hashrate', params => [], id => "4", jsonrpc => "2.0" } ,
                            { method => 'eth_blockNumber', params => [], id => "5", jsonrpc => "2.0" },
                            { method => 'eth_getBlockByNumber', params => ["latest",\0], id => "6", jsonrpc => "2.0" },
                            { method => 'eth_syncing', params => [], id => "7", jsonrpc => "2.0" } ];

    my $result = $options{custom}->request_api(method => 'POST', query_form_post => $query_form_post);

    my $gas_price = hex(@{$result}[2]->{result});
   
    # use Data::Dumper;
    # my $length = scalar(@{$$result[5]->{result}->{transactions}});
    # print Dumper($result) ;
   
    # conditional formating:
    my $res_sync = @{$result}[6]->{result} ? hex((@{$result}[6]->{result}->{currentBlock} / @{$result}[6]->{result}->{highestBlock})) * 100 : 100;
    my $res_startingBlock = $res_sync != 100 ? hex(@{$result}[6]->{result}->{startingBlock}) : 'none';
    my $res_currentBlock = $res_sync != 100 ? hex(@{$result}[6]->{result}->{currentBlock}) : 'none';
    my $res_highestBlock = $res_sync != 100 ? hex(@{$result}[6]->{result}->{highestBlock}) : 'none';

    # Alerts management 
    # my $cache = Cache::File->new( cache_root => './parity-restapi-cache' );

    # if (my $cached_sync = $cache->get('node_sync')) {
    #     if ($cached_sync == 100 && $res_sync < 100) {
    #         #alert
    #     }
    # } else {
    #     $cache->set('node_sync', $res_sync);
    # }

    # if (my $cached_price = $cache->get('gas_price')) {
    #     if ($cached_price != $gas_price) {
    #         #alert
    #     }
    # } else {
    #     $cache->set('gas_price', $gas_price);
    # }

    $self->{global} = { gas_price => $gas_price };

    $self->{block} =  { block_size => hex(@{$result}[5]->{result}->{size}), 
                        block_gas => hex(@{$result}[5]->{result}->{gasUsed}),
                        block_difficulty => hex(@{$result}[5]->{result}->{totalDifficulty}), 
                        block_uncles => scalar(@{$$result[5]->{result}->{uncles}}), 
                        block_transactions => scalar(@{$$result[5]->{result}->{transactions}})};

    $self->{output}->output_add(severity  => 'OK', long_msg => 'Node status: [is_mining: ' . @{$result}[0]->{result} . '] [sync_start: ' . $res_startingBlock . 
                                                                '] [sync_current: ' . $res_currentBlock . '] [sync_highest: ' . $res_highestBlock . '] [sync: ' . $res_sync . '%%]');
    $self->{output}->output_add(severity  => 'OK', long_msg => 'Client: [coinbase: ' . @{$result}[1]->{result} . ']');
    $self->{output}->output_add(severity  => 'OK', long_msg => 'Global: [hashrate: ' . hex(@{$result}[3]->{result}) . 
                                                                '] [block_number: ' . (defined @{$result}[4]->{result} ? hex(@{$result}[4]->{result}) : 0) . ']');
    $self->{output}->output_add(severity  => 'OK', long_msg => 'Last block: [block_time: ' . localtime(hex(@{$result}[5]->{result}->{timestamp})) . '] [block_gas_limit: ' . hex(@{$result}[5]->{result}->{gasLimit}) . 
                                                                '] [block_miner: ' . @{$result}[5]->{result}->{miner} . '] [block_hash: ' . @{$result}[5]->{result}->{hash} . 
                                                                '] [last_block_number: ' . hex(@{$result}[5]->{result}->{number}) . ']');
    
}

1;

__END__

=head1 MODE

Check eth module metrics parity (eth_mining, eth_coinbase, eth_gasPrice, eth_hashrate, eth_blockNumber, eth_getBlockByNumber::timestamp)

=over 8

=item B<--unknown-status>

Set unknown threshold for listening status (Default: '').

=item B<--warning-status>

Set warning threshold for listening status (Default: '').

=item B<--critical-status>

Set critical threshold for listening status (Default: '%{is_mining} !~ /true/').

=item B<--warning-peers> B<--critical-peers>

Warning and Critical threhsold on the number of peer

=back

=cut
