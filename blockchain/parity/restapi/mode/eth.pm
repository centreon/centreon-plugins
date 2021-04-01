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
        { name => 'gas', cb_prefix_output => 'prefix_module_output', type => 0 },
        { name => 'block', cb_prefix_output => 'prefix_module_output', type => 0 },
        { name => 'sync', cb_prefix_output => 'prefix_module_output', type => 0 },
    ];

    $self->{maps_counters}->{sync} = [
        { label => 'sync-status', nlabel => 'parity.eth.sync.status', set => {
                key_values => [ { name => 'sync_status' } ],
                output_template => "Syncing: %d %% ",
                perfdatas => [
                    { label => 'sync_status', value => 'sync_status', template => '%d', min => 0 }
                ],                
            }
        }
    ];

    $self->{maps_counters}->{gas} = [
        { label => 'gas-price', nlabel => 'parity.eth.gas.price', set => {
                key_values => [ { name => 'gas_price' } ],
                output_template => "The gas price is: %d wei ",
                perfdatas => [
                    { label => 'gas_price', value => 'gas_price', template => '%d', min => 0 }
                ],                
            }
        },
        { label => 'gas-used', nlabel => 'parity.eth.gas.used', set => {
                key_values => [ { name => 'gas_used' } ],
                output_template => "The gas used is: %d",
                perfdatas => [
                    { label => 'gas_used', value => 'gas_used', template => '%d', min => 0 }
                ],                
            }
        },
        { label => 'gas-limit', nlabel => 'parity.eth.gas.limit', set => {
                key_values => [ { name => 'gas_limit' } ],
                output_template => "The gas limit is: %d",
                perfdatas => [
                    { label => 'gas_limit', value => 'gas_limit', template => '%d', min => 0 }
                ],                
            }
        }
    ];

    $self->{maps_counters}->{block} = [  
        { label => 'block-size', nlabel => 'parity.eth.block.size', set => {
                key_values => [ { name => 'block_size' } ],
                output_template => "Block size: %d ",
                perfdatas => [
                    { label => 'block_size', value => 'block_size', template => '%d', min => 0 }
                ],                
            }
        },
        { label => 'block-usage', nlabel => 'parity.eth.block.usage', set => {
                key_values => [ { name => 'block_usage' } ],
                output_template => "Block usage: %.2f %%",
                perfdatas => [
                    { label => 'block_usage', value => 'block_usage', template => '%.2f', unit => '%', min => 0 }
                ],                
            }
        },
        { label => 'block-transactions', nlabel => 'parity.eth.block.transactions.number', set => {
                key_values => [ { name => 'block_transactions' } ],
                output_template => "Block transactions number: %d ",
                perfdatas => [
                    { label => 'block_transactions', value => 'block_transactions', template => '%d', min => 0 }
                ],                
            }
        },
        { label => 'block-gas', nlabel => 'parity.eth.block.gas', set => {
                key_values => [ { name => 'block_gas' } ],
                output_template => "Block gas: %d ",
                perfdatas => [
                    { label => 'block_gas', value => 'block_gas', template => '%d', min => 0 }
                ],                
            }
        },
        { label => 'block-uncles', nlabel => 'parity.eth.block.uncles', set => {
                key_values => [ { name => 'block_uncles' } ],
                output_template => "Block uncles: %d ",
                perfdatas => [
                    { label => 'block_uncles', value => 'block_uncles', template => '%d', min => 0 }
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
           (defined($self->{option_results}->{port}) ? $self->{option_results}->{port} : 'default') . '_' .
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
    my $res_block_time = @{$result}[5]->{result}->{timestamp} == 0 ? '': localtime(hex(@{$result}[5]->{result}->{timestamp}));

    my $res_sync = 100;
    
    if (@{$result}[6]->{result}) {
        my $res_sync = hex(@{$result}[6]->{result}->{highestBlock}) != 0 ? (hex(@{$result}[6]->{result}->{currentBlock}) * 100) / hex(@{$result}[6]->{result}->{highestBlock}) : 'none';
    } 

    $self->{sync} = { sync_status => $res_sync };

    $self->{gas} = { gas_price => $gas_price,
                     gas_used => hex(@{$result}[5]->{result}->{gasUsed}),
                     gas_limit => hex(@{$result}[5]->{result}->{gasLimit}) };

    my $calculated_block_usage = hex(@{$result}[5]->{result}->{gasUsed}) / hex(@{$result}[5]->{result}->{gasLimit}) * 100;

    $self->{block} =  { block_size => hex(@{$result}[5]->{result}->{size}), 
                        block_gas => hex(@{$result}[5]->{result}->{gasUsed}),
                        block_usage => $calculated_block_usage,
                        block_uncles => scalar(@{$$result[5]->{result}->{uncles}}), 
                        block_transactions => scalar(@{$$result[5]->{result}->{transactions}})};   
}

1;

__END__

=head1 MODE

Check eth module metrics parity (Gas, blocks and syncing status)