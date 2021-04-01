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

package database::sap::hana::mode::connectedusers;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'host', type => 1, cb_prefix_output => 'prefix_output', message_multiple => 'All connected users are ok' },
    ];
    $self->{maps_counters}->{host} = [
        { label => 'users', nlabel => 'users.count', set => {
                key_values => [ { name => 'total' }, { name => 'display' } ],
                output_template => 'Connected Users : %s',
                perfdatas => [
                    { label => 'users', value => 'total', template => '%s', min => 0,
                      label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_output {
    my ($self, %options) = @_;

    return "Host '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                "filter-username:s"     => { name => 'filter_username' },
                                });
                                
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;
    $options{sql}->connect();

    my $query = q{
        SELECT * FROM SYS.M_CONNECTIONS WHERE CONNECTION_TYPE IN ('Remote')
    };
    $options{sql}->query(query => $query);

    $self->{host} = {};
    while ((my $row = $options{sql}->fetchrow_hashref())) {
        my $name = $row->{HOST} . ':' . $row->{PORT};
        
        $self->{host}->{$name} = { total => 0, display => $name } if (!defined($self->{host}->{$name}));
        
        if (defined($self->{option_results}->{filter_username}) && $self->{option_results}->{filter_username} ne '' &&
            $row->{USER_NAME} !~ /$self->{option_results}->{filter_username}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $name . '/' . $row->{USER_NAME} . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{host}->{$name}->{total}++;
    }
    
    if (scalar(keys %{$self->{host}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No host found.");
        $self->{output}->option_exit();
    }
}
    
1;

__END__

=head1 MODE

Check connected users.

=over 8

=item B<--filter-username>

Filter connected username. (Can be a regex)

=item B<--warning-*>

Threshold warning.
Can be: 'users'.

=item B<--critical-*>

Threshold critical.
Can be: 'users'.

=back

=cut