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

package blockchain::parity::ethpoller::mode::prct;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use bigint;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'balances', cb_prefix_output => 'prefix_output_balances', type => 1, message_multiple => 'Balances metrics are ok' }
    ];

    $self->{maps_counters}->{balances} = [
        { label => 'balance-fluctuation-prct', nlabel => 'parity.tracking.balances.fluctuation', display_ok => 0, set => {
                key_values => [],
                manual_keys => 1,
                closure_custom_calc => $self->can('custom_prct_calc'),
                closure_custom_output => $self->can('custom_prct_output'),
                threshold_use => 'balance_fluctuation',
                perfdatas => [
                   { value => 'balance_fluctuation', template => '%.2f',
                     min => 0, label_extra_instance => 1, instance_use => 'display'  },
                ],
            }
        },
        { label => 'balance', nlabel => 'parity.tracking.balance', set => {
                key_values => [ { name => 'balance' } ],
                output_template => "%d (wei)",
                perfdatas => [
                    { label => 'balance', template => '%d', value => 'balance_absolute' }
                ],
            }
        }
    ];

}

sub custom_prct_output {
    my ($self, %options) = @_;

    # use Data::Dumper;
    # print Dumper('$total_balance');
    return sprintf(
        "balance variation: %.2f ",
        $self->{result_values}->{balance_fluctuation}
    );
}

sub custom_prct_calc {
    use Data::Dumper;
    
    my ($self, %options) = @_;

    my ($old_balance, $new_balance) = (0, 0);
    foreach (keys %{$options{new_datas}}) {
        # print Dumper($self->{instance});
        # print Dumper($options{new_datas});
        # print Dumper($options{new_datas}->{$_});
        if (/\Q$self->{instance}\E_.*_balance/) {
            # print Dumper($self->{instance});
            $new_balance = $options{new_datas}->{$_};
            $old_balance = $options{old_datas}->{$_};
            # print Dumper($old_balance);
            # print Dumper($new_balance);
        }
    }
    
    
    
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{balance_fluctuation} = 0;
    if ($old_balance > 0) {
        $self->{result_values}->{balance_fluctuation} = ($new_balance - $old_balance) / $old_balance;
    }


}

sub prefix_output_balances {
    my ($self, %options) = @_;

    return "Balance '" . $options{instance_value}->{display} . "': ";
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

    my $result = $options{custom}->request_api(url_path => '/tracking');
    use Data::Dumper;
    # print Dumper($result);

    foreach my $balance (@{$result->{balances}}) {
        # print Dumper($balance);
        $self->{balances}->{$balance->{label}} = { display => $balance->{label} };
        $self->{balances}->{$balance->{label}}->{'balance'} = $balance->{balance};
    }

}
    


1;

__END__

=head1 MODE

Check Parity eth-poller for events, miners and balances tracking

=cut
