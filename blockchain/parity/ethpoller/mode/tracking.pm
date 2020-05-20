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
        { name => 'events', cb_prefix_output => 'prefix_output_events', type => 1, message_multiple => 'Events metrics are ok' },
        { name => 'mining', cb_prefix_output => 'prefix_output_mining', type => 1, message_multiple => 'Mining metrics are ok' },
        { name => 'balance', cb_prefix_output => 'prefix_output_balance', type => 1, message_multiple => 'Balances metrics are ok' }
    ];

    $self->{maps_counters}->{events} = [
       { label => 'events_frequency', nlabel => 'parity.tracking.events.perminute', set => {
                key_values => [ { name => 'events_count', diff => 1 }, { name => 'display' } ],
                per_minute => 1,
                output_template => " %.2f (events/min)",
                perfdatas => [ 
                    { label => 'events', template => '%.2f', value => 'events_count_per_minute',
                        label_extra_instance => 1, instance_use => 'display_absolute' } 
                ],
            }
        }
    ];

    $self->{maps_counters}->{mining} = [
       { label => 'mining_frequency', nlabel => 'parity.tracking.mined.block.perminute', set => {
                key_values => [ { name => 'mining_count', diff => 1 }, { name => 'display' } ],
                per_minute => 1,
                output_template => " %.2f (blocks/min)",
                perfdatas => [ { label => 'mining', template => '%.2f', value => 'mining_count_per_minute',
                        label_extra_instance => 1, instance_use => 'display_absolute' } ],
            }
        }
    ];

    $self->{maps_counters}->{balance} = [
       { label => 'balance_fluctuation', nlabel => 'parity.tracking.balance.variation.perminute', set => {
                key_values => [ { name => 'balance', diff => 1 } ],
                per_minute => 1,
                output_template => " variation: %.2f (diff/min)",
                perfdatas => [
                    { label => 'balances', template => '%.2f', value => 'balance_per_minute',
                        label_extra_instance => 1, instance_use => 'display_absolute' }
                ],
            }
        }
    ];

}

sub prefix_output_events {
    my ($self, %options) = @_;

    return "Event '" . $options{instance_value}->{display} . "' ";
}

sub prefix_output_mining {
    my ($self, %options) = @_;

    return "Miner '" . $options{instance_value}->{display} . "' ";;
}

sub prefix_output_balance {
    my ($self, %options) = @_;

    return "Balance '" . $options{instance_value}->{display} . "' ";
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

        $self->{events}->{lc($event->{label})} = { display => lc($event->{label}), 
                                                   events_count => $event->{count} };

    }

    foreach my $miner (@{$results->{miners}}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $miner->{id} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $miner->{label} . "': no matching filter name.", debug => 1);
            next;
        }

        $self->{mining}->{lc($miner->{label})} = { display => lc($miner->{label}), 
                                                   mining_count => $miner->{count} };

    }

    foreach my $balance (@{$results->{balances}}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $balance->{id} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $balance->{label} . "': no matching filter name.", debug => 1);
            next;
        }

        $self->{balance}->{lc($balance->{label})} = { display => lc($balance->{label}),
                                                        balance => $balance->{balance} };
    }
    

}

1;

__END__

=head1 MODE

Check Parity eth-poller for events, miners and balances tracking

=cut
