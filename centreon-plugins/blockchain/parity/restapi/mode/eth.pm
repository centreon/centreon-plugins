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
        { name => 'peer', cb_prefix_output => 'prefix_module_output', type => 0 },
        { name => 'block', cb_prefix_output => 'prefix_module_output', type => 0 },
        { name => 'sync', cb_prefix_output => 'prefix_module_output', type => 0 }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'coinbase', nlabel => 'parity.eth.client.coinbase', set => {
                key_values => [ { name => 'coinbase' } ],
                output_template => "Client coinbase is: %s ",
                # closure_custom_perfdata => sub { return 0; }
                perfdatas => [
                    { label => 'client_coinbase', value => 'coinbase_absolute', template => '%s', min => 0 }
                ],                
            }
        },
        { label => 'gas_price', nlabel => 'parity.eth.gas.price', set => {
                key_values => [ { name => 'gas_price' } ],
                output_template => "The gas price is: %d wei ",
                perfdatas => [
                    { label => 'gas_price', value => 'gas_price_absolute', template => '%d', min => 0 }
                ],                
            }
        }
    ];

    $self->{maps_counters}->{peer} = [
        # { label => 'status', nlabel => 'parity.eth.peers.mining.status', set => {
        #         key_values => [ { name => 'is_mining' } ],
        #         output_template => "Client is mining:  " . $self->can('custom_mining_status_output'),
        #         perfdatas => [
        #             { label => 'is_mining', value => 'is_mining_absolute', template => '%s', min => 0 }
        #         ],                
        #     }
        # },
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'is_mining' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        },
        { label => 'hashrate', nlabel => 'parity.eth.node.hashrate', set => {
                key_values => [ { name => 'hashrate' } ],
                output_template => "Node hashrate is: %d/s ",
                perfdatas => [
                    { label => 'node_hashrate', value => 'hashrate_absolute', template => '%d', min => 0 }
                ],                
            }
        },
    ];

    $self->{maps_counters}->{block} = [  
        { label => 'block_number', nlabel => 'parity.eth.block.number', set => {
                key_values => [ { name => 'block_number' } ],
                output_template => "Most recent block number is: %d ",
                closure_custom_perfdata => sub { return 0; }
                # perfdatas => [
                #     { label => 'block_number', value => 'block_number_absolute', template => '%d', min => 0 }
                # ],                
            }
        },
        { label => 'block_time', nlabel => 'parity.eth.block.time', set => {
                key_values => [ { name => 'block_time' } ],
                output_template => "Block time is: %s ",
                closure_custom_perfdata => sub { return 0; }
                # perfdatas => [
                #     { label => 'block_time', value => 'block_time_absolute', template => '%s', min => 0 }
                # ],                
            }
        },
    ];

    $self->{maps_counters}->{sync} = [
        { label => 'sync_start', nlabel => 'parity.eth.sync.start.block', set => {
                key_values => [ { name => 'sync_start' } ],
                output_template => "Sync start block number is: %d ",
                closure_custom_perfdata => sub { return 0; }
                # perfdatas => [
                #     { label => 'sync_start', value => 'sync_start_absolute', template => '%d', min => 0 }
                # ],                
            }
        },
        { label => 'sync_current', nlabel => 'parity.eth.sync.current.block', set => {
                key_values => [ { name => 'sync_current' } ],
                output_template => "Sync current block number is: %d ",
                closure_custom_perfdata => sub { return 0; }
                # perfdatas => [
                #     { label => 'sync_current', value => 'sync_current_absolute', template => '%d', min => 0 }
                # ],                
            }
        },
        { label => 'sync_highest', nlabel => 'parity.eth.sync.highest.block', set => {
                key_values => [ { name => 'sync_highest' } ],
                output_template => "Sync highest block number is: %d ",
                # closure_custom_perfdata => sub { return 0; }
                perfdatas => [
                    { label => 'sync_highest', value => 'sync_highest_absolute', template => '%d', min => 0 }
                ],                
            }
        },
        { label => 'sync', nlabel => 'parity.eth.sync.ratio', set => {
                key_values => [ { name => 'sync' } ],
                output_template => "Sync ratio is: %d% ",
                perfdatas => [
                    { label => 'sync', value => 'sync_absolute', template => '%d', min => 0 }
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
    
    return "Parity Eth module: ";
}

sub manage_selection {
    my ($self, %options) = @_;

    my $query_form_post = [ { method => 'eth_mining', params => [], id => "1", jsonrpc => "2.0" },
                            { method => 'eth_coinbase', params => [], id => "2", jsonrpc => "2.0" },
                            { method => 'eth_gasPrice', params => [], id => "3", jsonrpc => "2.0" } ,
                            { method => 'eth_hashrate', params => [], id => "4", jsonrpc => "2.0" } ,
                            { method => 'eth_blockNumber', params => [], id => "5", jsonrpc => "2.0" },
                            { method => 'eth_getBlockByNumber', params => ["latest",\0], id => "6", jsonrpc => "2.0" },
                            { method => 'eth_syncing', params => [], id => "7", jsonrpc => "2.0" } ];

    my $result = $options{custom}->request_api(method => 'POST', query_form_post => $query_form_post);
   
    # use Data::Dumper;
    # print Dumper($result);
   
    # conditional formating:
    my $res_sync = @{$result}[6]->{result} ? hex((@{$result}[6]->{result}->{currentBlock} / @{$result}[6]->{result}->{highestBlock})) * 100 : 100;
    my $res_startingBlock = $res_sync != 100 ? hex(@{$result}[6]->{result}->{startingBlock}) : undef;
    my $res_currentBlock = $res_sync != 100 ? hex(@{$result}[6]->{result}->{currentBlock}) : undef;
    my $res_highestBlock = $res_sync != 100 ? hex(@{$result}[6]->{result}->{highestBlock}) : undef;

    # Unix time conversion
    my $res_timestamp = localtime(hex(@{$result}[5]->{result}->{timestamp}));  

    $self->{global} = { coinbase => @{$result}[1]->{result},
                        gas_price => hex(@{$result}[2]->{result}) };

    $self->{block} = { block_number => defined @{$result}[4]->{result} ? hex(@{$result}[4]->{result}) : 0,
                     block_time => $res_timestamp };

    $self->{sync} = { sync_start => $res_startingBlock,
                     sync_current => $res_currentBlock,
                     sync_highest => $res_highestBlock,
                     sync => $res_sync };

    $self->{peer} = { is_mining => @{$result}[0]->{result},
                     hashrate => hex(@{$result}[3]->{result}) };
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
