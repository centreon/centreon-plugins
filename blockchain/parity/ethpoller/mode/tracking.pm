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

package blockchain::parity::ethpoller::mode::tracking;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use bigint;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'events', cb_prefix_output => 'prefix_module_events', type => 1, message_multiple => 'All event metrics are ok' },
        { name => 'miners', cb_prefix_output => 'prefix_module_miners', type => 1, message_multiple => 'All miner metrics are ok' },
        { name => 'balances', cb_prefix_output => 'prefix_module_balances', type => 1, message_multiple => 'All balance metrics are ok' },
    ];

    $self->{maps_counters}->{events} = [
       { label => 'event_frequency', nlabel => 'parity.tracking.event.frequency', set => {
                key_values => [ { name => 'event_frequency' } ],
                output_template => "Event's frequency: %d (evt/min)",
                perfdatas => [
                    { label => 'event_frequency', value => 'event_frequency_absolute', template => '%d', min => 0 }
                ],                
            }
        }
    ];

    $self->{maps_counters}->{miners} = [
       { label => 'mining_frequency', nlabel => 'parity.tracking.mining.frequency', set => {
                key_values => [ { name => 'mining_frequency' } ],
                output_template => "Mining frequency: %d (block/min)",
                perfdatas => [
                    { label => 'mining_frequency', value => 'mining_frequency_absolute', template => '%d', min => 0 }
                ],                
            }
        }
    ];

    $self->{maps_counters}->{balances} = [
       { label => 'balance_fluctuation', nlabel => 'parity.tracking.balances.fluctuation', set => {
                key_values => [ { name => 'balance_fluctuation' } ],
                output_template => "Balance fluctuation: %d (diff/min)",
                perfdatas => [
                    { label => 'balance_fluctuation', value => 'balance_fluctuation_absolute', template => '%d', min => 0 }
                ],                
            }
        }
    ];

}

sub prefix_output_events {
    my ($self, %options) = @_;

    return "Event stats '";
}

sub prefix_output_miners {
    my ($self, %options) = @_;

    return "Miner stats '";
}

sub prefix_output_balances {
    my ($self, %options) = @_;

    return "Balance stats '";
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
       (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));

    my $results = $options{custom}->request_api(url_path => '/tracking');

    # use Data::Dumper;
    # print Dumper($results);

    my $res_timestamp = 0;
    my $calculated_frequency = 0;

    $self->{events} = {};
    $self->{miners} = {};
    $self->{balances} = {};
    
    my $datas = {};

    foreach my $event (@{$results->{events}}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $event->{id} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $event->{id} . "': no matching filter name.", debug => 1);
            next;
        }

        my $old_event_timestamp = $self->{statefile_cache}->get(name => 'last_event_timestamp'); #get the id last_event_timestamp
        my $old_event_count = $self->{statefile_cache}->get(name => 'last_event_count'); #get the id last_event_count

        $datas->{$event->{id}}->{last_event_timestamp} = time();
        $datas->{$event->{id}}->{last_event_count} = $event->{count};

        if ($old_event_count && $old_event_timestamp) {
            $calculated_frequency = ($event->{count} - $old_event_count) / (time() - $old_event_timestamp);

            $self->{events}->{$event->{id}}->{display} = $event->{label};
            $self->{events}->{$event->{id}}->{event_frequency} = $calculated_frequency;        

            $res_timestamp = $event->{timestamp} == 0 ? '': localtime($event->{timestamp});

            if ($event->{count} > 0) {
                $self->{output}->output_add(severity  => 'OK', long_msg => 'Event ' . $event->{id} . ': Last Tx from "' . $event->{label} . '" (#' . $event->{count} .
                                ') was at ' . $res_timestamp . ' (block #' . $event->{block} . ')' );
            } else {
                $self->{output}->output_add(severity  => 'OK', long_msg => 'Event ' . $event->{id} . ': No Tx from "' . $event->{label} . '"');
            }
        } else {
            $self->{output}->output_add(severity  => 'OK', long_msg => 'Event ' . $event->{id} . ': Building perfdata for "' . $event->{label} . '"...');
        }
    }

    foreach my $miner (@{$results->{miners}}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $miner->{id} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $miner->{id} . "': no matching filter name.", debug => 1);
            next;
        }

        my $old_miner_timestamp = $self->{statefile_cache}->get(name => 'last_miner_timestamp'); #get the id last_miner_timestamp
        my $old_miner_count = $self->{statefile_cache}->get(name => 'last_miner_count'); #get the id last_miner_count

        $datas->{$miner->{id}}->{last_miner_timestamp} = time();
        $datas->{$miner->{id}}->{last_miner_count} = $miner->{count};

        if ($old_miner_timestamp && $old_miner_timestamp) {
            $calculated_frequency = ($miner->{count} - $old_miner_count) / (time() - $old_miner_timestamp);

            $self->{miners}->{$miner->{id}}->{display} = $miner->{label};
            $self->{miners}->{$miner->{id}}->{mining_frequency} = $calculated_frequency;

            $res_timestamp = $miner->{timestamp} == 0 ? '': localtime($miner->{timestamp});
            if ($miner->{count} > 0) {
                $self->{output}->output_add(severity  => 'OK', long_msg => 'Miner ' . $miner->{id} . ': Last block from label "' . $miner->{label} . '" (#' . $miner->{count} .
                                ') was at ' . $res_timestamp . ' (block #' . $miner->{block} . ')' );
            } else {
                 $self->{output}->output_add(severity  => 'OK', long_msg => 'Miner ' . $miner->{id} . ': No validation from "' . $miner->{label} . '"');
            }
        } else {
            $self->{output}->output_add(severity  => 'OK', long_msg => 'Miner ' . $miner->{id} . ': Building perfdata for "' . $miner->{label} . '"...');
        }
    }

    foreach my $balance (@{$results->{balances}}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $balance->{id} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $balance->{id} . "': no matching filter name.", debug => 1);
            next;
        }

        my $old_balance = $self->{statefile_cache}->get(name => 'last_balance'); #get the id last_balance

        $datas->{$balance->{id}}->{last_balance} = $balance->{balance};

        if ($old_balance) {
            my $calculated_diff = ($balance->{balance} - $old_balance) / ($old_balance);

            $self->{balances}->{$balance->{id}}->{display} = $balance->{label};
            $self->{balances}->{$balance->{id}}->{balance} = $calculated_diff;

            $self->{output}->output_add(severity  => 'OK', long_msg => 'Balance ' . $balance->{id} . ': Balance of "' . $balance->{label} . '" is ' . $balance->{balance} . ' ether' );
        } else {
            $self->{output}->output_add(severity  => 'OK', long_msg => 'Balance ' . $balance->{id} . ': Balance fluctuation of "' . $balance->{label} . '" is being calculated...');
        }
    }
    

}

1;

__END__

=head1 MODE

Check Parity eth-poller for events, miners and balances tracking

=cut
