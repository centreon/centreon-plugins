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

package blockchain::parity::ethpoller::mode::stats;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use bigint;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'block', cb_prefix_output => 'prefix_output_block', type => 0 },
        { name => 'transaction', cb_prefix_output => 'prefix_output_transaction', type => 0 },
        { name => 'fork', cb_prefix_output => 'prefix_output_fork', type => 0 }
    ];

    $self->{maps_counters}->{block} = [
       { label => 'block-frequency', nlabel => 'parity.stats.block.perminute', set => {
                key_values => [ { name => 'block_count', per_minute => 1 }, { name => 'last_block' }, { name => 'last_block_ts' } ],
                closure_custom_output => $self->can('custom_block_output'),
                perfdatas => [
                    { label => 'block', value => 'block_count', template => '%.2f' }
                ],
            }
        }
    ];

    $self->{maps_counters}->{transaction} = [
       { label => 'transaction-frequency', nlabel => 'parity.stats.transaction.perminute', set => {
                key_values => [ { name => 'transaction_count', per_minute => 1 }, { name => 'last_transaction' }, { name => 'last_transaction_ts' } ],
                closure_custom_output => $self->can('custom_transaction_output'),
                perfdatas => [
                    { label => 'transaction', value => 'transaction_count', template => '%.2f' }
                ],                
            }
        }
    ];

    $self->{maps_counters}->{fork} = [
       { label => 'fork-frequency', nlabel => 'parity.stats.fork.perminute', set => {
                key_values => [ { name => 'fork_count', per_minute => 1 }, { name => 'last_fork' }, { name => 'last_fork_ts' } ],
                closure_custom_output => $self->can('custom_fork_output'),
                perfdatas => [
                    { label => 'fork', value => 'fork_count', template => '%.2f' }
                ],
            }
        }
    ];
}

sub custom_block_output {
    my ($self, %options) = @_;

    if (0 eq $self->{result_values}->{block_count}) {
        return sprintf("No block yet...");
    } else {
        return sprintf(
            "Block frequency: '%.2f/min', Last block (#%s)",
            $self->{result_values}->{block_count},
            $self->{result_values}->{last_block}
        );
    }
}

sub custom_transaction_output {
    my ($self, %options) = @_;

    if (0 eq $self->{result_values}->{transaction_count}) {
        return sprintf("No transaction yet...");
    } else {

        return sprintf(
            "Transaction frequency: '%.2f/min', Last transaction (#%s)",
            $self->{result_values}->{transaction_count},
            $self->{result_values}->{last_transaction}
        );
    }
}

sub custom_fork_output {
    my ($self, %options) = @_;

    if (0 eq $self->{result_values}->{fork_count}) {
        return sprintf("No fork occurred yet...");
    } else {
        
        return sprintf(
            "Fork frequency: '%.2f/min', Last fork (#%s)",
            $self->{result_values}->{fork_count},
            $self->{result_values}->{last_fork}
        );
    }
}


sub prefix_output_block {
    my ($self, %options) = @_;

    return "Block stats '";
}

sub prefix_output_fork {
    my ($self, %options) = @_;

    return "Fork stats '";
}

sub prefix_output_transaction {
    my ($self, %options) = @_;

    return "Transaction stats '";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "filter-name:s" => { name => 'filter_name' },
    });
   
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = "parity_ethpoller_" . $self->{mode} . '_' . (defined($self->{option_results}->{hostname}) ? $self->{option_results}->{hostname} : 'me') . '_' .
           (defined($self->{option_results}->{port}) ? $self->{option_results}->{port} : 'default') . '_' .
           (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));

    my $result = $options{custom}->request_api(url_path => '/stats');

    my $last_block_timestamp = (defined($result->{block}->{timestamp}) && $result->{block}->{timestamp} != 0) ?
                                    $result->{block}->{timestamp} :
                                    'NONE';
    my $last_transaction_timestamp = (defined($result->{transaction}->{timestamp}) && $result->{transaction}->{timestamp} != 0) ?
                                    $result->{transaction}->{timestamp} :
                                    'NONE';
    my $last_fork_timestamp = (defined($result->{fork}->{timestamp}) && $result->{fork}->{timestamp} != 0) ?
                                    $result->{fork}->{timestamp} :
                                    'NONE';

    $self->{block} = { block_count => $result->{block}->{count},
                       last_block => $result->{block}->{count},
                       last_block_ts => $last_block_timestamp };

    $self->{transaction} = { transaction_count => $result->{transaction}->{count},
                             last_transaction => $result->{transaction}->{count},
                             last_transaction_ts => $last_transaction_timestamp };
    
    $self->{fork} = { fork_count => $result->{fork}->{count},
                      last_fork => $result->{fork}->{count},
                      last_fork_ts => $last_fork_timestamp };
}

1;

__END__

=head1 MODE

Check Parity eth-poller for statsitics about blocks, transactions and forks

=cut
