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

package apps::lync::2013::mssql::mode::lyncusers;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_user_output {
    my ($self, %options) = @_;

    return "'Frontend' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'users', type => 0, cb_prefix_output => 'prefix_user_output' }
    ];

    $self->{maps_counters}->{users} = [
        { label => 'total', nlabel => 'users.total.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => '%d total users',
                perfdatas => [
                    { label => 'total_users', template => '%d',
                      unit => 'users', min => 0 }
                ]
            }
        },
        { label => 'unique', nlabel => 'users.unique.count', set => {
                key_values => [ { name => 'unique' } ],
                output_template => '%d unique users',
                perfdatas => [
                    { label => 'unique_users', template => '%d',
                      unit => 'users', min => 0 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $options{sql}->connect();
    $options{sql}->query(query => q{
        Select
            count(*) as totalonline,
            count(distinct UserAtHost) as totalunique
        From rtcdyn.dbo.RegistrarEndpoint RE
        Inner Join
        rtc.dbo.Resource R on R.ResourceId = RE.OwnerId
        Inner Join
        rtcdyn.dbo.Registrar Reg on Reg.RegistrarId = RE.PrimaryRegistrarClusterId
    });

    my ($total_online, $total_unique) = $options{sql}->fetchrow_array();
    $self->{users} = { total => $total_online, unique => $total_unique };

}

1;

__END__

=head1 MODE

Check Lync Users Total and Unique. Query your RTCLocal Lync Frontend Dabatase (Get instance port in SQL Server configuration if dynamic mode)

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).

=item B<--warning-*>

Set warning threshold for number of user. Can be : 'total', 'unique'

=item B<--critical-*>

Set critical threshold for number of user. Can be : 'total', 'unique'

=back

=cut
