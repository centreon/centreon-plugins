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

package blockchain::parity::ethpoller::mode::tracking;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use bigint;
use Math::BigFloat;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'events', cb_prefix_output => 'prefix_output_events', type => 1, message_multiple => 'Events metrics are ok' },
        { name => 'mining', cb_prefix_output => 'prefix_output_mining', type => 1, message_multiple => 'Mining metrics are ok' },
        { name => 'balance', cb_prefix_output => 'prefix_output_balances', type => 1, message_multiple => 'Balances metrics are ok' }
    ];

    $self->{maps_counters}->{events} = [
       { label => 'events-frequency', nlabel => 'parity.tracking.events.perminute', set => {
                key_values => [ { name => 'events_count', per_minute => 1 }, { name => 'display' }, 
                                { name => 'last_event' }, { name => 'last_event_block' }, { name => 'last_event_ts' } ],
                closure_custom_output => $self->can('custom_event_output'),
                perfdatas => [ 
                    { template => '%.2f', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{mining} = [
       { label => 'mining-frequency', nlabel => 'parity.tracking.mined.block.perminute', set => {
                key_values => [ { name => 'mining_count', per_minute => 1 }, { name => 'display' },
                                , { name => 'last_mining' }, { name => 'last_mining_block' }, { name => 'last_mining_ts' } ],
                closure_custom_output => $self->can('custom_miner_output'),
                perfdatas => [
                    { template => '%.2f', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'mining-prct', nlabel => 'parity.tracking.mined.block.prct', display_ok => 0, set => {
                key_values => [],
                manual_keys => 1,
                closure_custom_calc => $self->can('custom_mining_prct_calc'),
                closure_custom_output => $self->can('custom_mining_prct_output'),
                threshold_use => 'mining_prct',
                perfdatas => [
                   { value => 'mining_prct', template => '%.2f', unit => '%',
                     min => 0, label_extra_instance => 1, instance_use => 'display'  }
                ],
            }
        }
    ];

    $self->{maps_counters}->{balance} = [
    #    { label => 'balance-fluctuation-prct', nlabel => 'parity.tracking.balances.fluctuation', display_ok => 0, set => {
    #             key_values => [],
    #             manual_keys => 1,
    #             closure_custom_calc => $self->can('custom_balance_prct_calc'),
    #             closure_custom_output => $self->can('custom_balance_prct_output'),
    #             threshold_use => 'balance_fluctuation_prct',
    #             perfdatas => [
    #                { value => 'balance_fluctuation_prct', template => '%.2f', unit => '%',
    #                  min => 0, label_extra_instance => 1, instance_use => 'display'  }
    #             ],
    #         }
    #     }
        { label => 'balance-changes', nlabel => 'parity.tracking.balance.changes.perminute', set => {
                key_values => [ { name => 'balance_count', per_minute => 1 }, { name => 'display' },
                                { name => 'last_balance' } ],
                closure_custom_output => $self->can('custom_balance_output'),
                perfdatas => [
                    { template => '%.2f', label_extra_instance => 1, unit => 'wei', instance_use => 'display' }
                ]
            }
        },
    ];
}

sub prefix_output_balances {
    my ($self, %options) = @_;

    return "Balance '" . $options{instance_value}->{display} . "' ";
}

sub prefix_output_events {
    my ($self, %options) = @_;

    return "Event '" . $options{instance_value}->{display} . "' ";
}

sub prefix_output_mining {
    my ($self, %options) = @_;

    return "Miner '" . $options{instance_value}->{display} . "' ";
}

sub custom_mining_prct_output {
    my ($self, %options) = @_;
    
    return sprintf(
        "Mined: %d blocks, witch corresponds to %.2f %% of total validated block",
        $self->{result_values}->{mined_block_count},
        $self->{result_values}->{mining_prct}
    );
}

sub custom_mining_prct_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{mined_block_count} = Math::BigFloat->new($options{new_datas}->{$self->{instance} . '_mined_block_count'});
    $self->{result_values}->{total_block} = Math::BigFloat->new($options{new_datas}->{$self->{instance} . '_total_block'});
    $self->{result_values}->{mining_prct} = (defined($self->{result_values}->{total_block}) && $self->{result_values}->{total_block} != 0) ? 
                                                    $self->{result_values}->{mined_block_count} / $self->{result_values}->{total_block} * 100 : 0; 
    return 0;
}

# sub custom_balance_prct_output {
#     my ($self, %options) = @_;
    
#     return sprintf(
#         "Balance: %s ether, Last fluctuation: %.2f ",
#         $self->{result_values}->{balance},
#         $self->{result_values}->{balance_fluctuation_prct}
#     );
# }

# sub custom_balance_prct_calc {
#     my ($self, %options) = @_;

#     $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
#     $self->{result_values}->{balance} = Math::BigFloat->new($options{new_datas}->{$self->{instance} . '_balance'});
#     $self->{result_values}->{balance_old} = Math::BigFloat->new($options{old_datas}->{$self->{instance} . '_balance'});
#     $self->{result_values}->{balance_fluctuation_prct} = (defined($self->{result_values}->{balance_old}) && $self->{result_values}->{balance_old} != 0) ? 
#                                                     ($self->{result_values}->{balance} - $self->{result_values}->{balance_old}) / 
#                                                     $self->{result_values}->{balance_old} * 100 : 0; 

#     return 0;
# }

sub custom_event_output {
    my ($self, %options) = @_;

    if (0 eq $self->{result_values}->{last_event}) {
        return sprintf("No event yet...");
    } else {
       
        return sprintf(
            "Event frequency: %.2f/min, Last event (#%s) was in block #%s",
            $self->{result_values}->{event_count},
            $self->{result_values}->{last_event},
            $self->{result_values}->{last_event_block}
        );
    }
}

sub custom_miner_output {
    my ($self, %options) = @_;

    if (0 eq $self->{result_values}->{last_mining}) {
        return sprintf("No validation yet...");
    } else {
        
        return sprintf(
            "Mining frequency: %.2f/min, Last validation (#%s) ago for block #%s",
            $self->{result_values}->{mining_count},
            $self->{result_values}->{last_mining},
            $self->{result_values}->{last_mining_block}
        );
    }
}

sub custom_balance_output {
    my ($self, %options) = @_;

    if (0 eq $self->{result_values}->{balance_count}) {
        return sprintf("No change in balance in last minute. Balance still %s wei",
            $self->{result_values}->{last_balance});
    } else {
        return sprintf(
            "Balance changes: %.2f/min. New balance: %s",
            $self->{result_values}->{balance_count},
            $self->{result_values}->{last_balance}
        );
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
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

    my $results = $options{custom}->request_api(url_path => '/tracking');

    $self->{events} = {};
    $self->{mining} = {};
    $self->{balance} = {};

    foreach my $event (@{$results->{events}}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $event->{id} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $event->{label} . "': no matching filter name.", debug => 1);
            next;
        }

        my $last_event_timestamp = (defined($event->{timestamp}) && $event->{timestamp} != 0) ? $event->{timestamp} : 'NONE';
                                    
        $self->{events}->{lc($event->{label})} = {
            display => lc($event->{label}), 
            events_count => $event->{count},
            last_event => $event->{count},
            last_event_block => $event->{block},
            last_event_ts => $last_event_timestamp 
        };
    }

    foreach my $miner (@{$results->{miners}}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $miner->{id} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $miner->{label} . "': no matching filter name.", debug => 1);
            next;
        }

        my $last_mining_timestamp = (defined($miner->{timestamp}) && $miner->{timestamp} != 0) ? $miner->{timestamp} : 'NONE';

        $self->{mining}->{lc($miner->{label})} = {
            display => lc($miner->{label}), 
            mining_count => $miner->{count},
            last_mining => $miner->{count},
            last_mining_block => $miner->{block},
            last_mining_ts => $last_mining_timestamp,
            total_block => $miner->{currentBlock},
            mined_block_count => $miner->{count}
        };
    }

    foreach my $balance (@{$results->{balances}}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $balance->{id} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $balance->{label} . "': no matching filter name.", debug => 1);
            next;
        }

        $self->{balance}->{lc($balance->{label})} = {
            display => lc($balance->{label}),
            balance_count => $balance->{balance},
            last_balance => $balance->{balance}
        };
    }
    
}

1;

__END__

=head1 MODE

Check Parity eth-poller for events, miners and balances tracking

=cut