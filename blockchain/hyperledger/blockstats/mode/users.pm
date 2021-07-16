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

package blockchain::hyperledger::blockstats::mode::users;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'users', type => 1, cb_prefix_output => 'prefix_output', message_multiple => 'All user metrics are ok' }
    ];

    $self->{maps_counters}->{users} = [
        { label => 'transactions', nlabel => 'user.transactions.count', set => {
                key_values => [ { name => 'transactions' }, { name => 'display' } ],
                output_template => 'Transactions: %d',
                perfdatas => [
                    { label => 'transactions', value => 'transactions_absolute', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
    ];
}

sub prefix_output {
    my ($self, %options) = @_;

    return "User '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "filter-name:s" => { name => 'filter_name' },
    });
   
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{users} = {};

    my $results = $options{custom}->request_api(url_path => '/statistics/users');

    foreach my $user (@{$results}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $user->{mspid} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $user->{mspid} . "': no matching filter name.", debug => 1);
            next;
        }

        $self->{users}->{$user->{mspid}}->{display} = $user->{mspid};
        $self->{users}->{$user->{mspid}}->{transactions} = $user->{nbTransactions};
    }
    
    if (scalar(keys %{$self->{users}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No users found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check blockchain statistics

=cut
