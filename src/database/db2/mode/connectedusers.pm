#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package database::db2::mode::connectedusers;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'connected', nlabel => 'users.connected.count', set => {
                key_values => [ { name => 'connected' } ],
                output_template => 'connected users: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-appl-name:s'  => { name => 'filter_appl_name' },
        'exclude-appl-name:s' => { name => 'exclude_appl_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $options{sql}->connect();
    $options{sql}->query(query => q{
        SELECT
            appl_name
        FROM
            sysibmadm.applications
    });

    $self->{global} = { connected  => 0 };
    while (my $row = $options{sql}->fetchrow_arrayref()) {
        if (defined($self->{option_results}->{filter_appl_name}) && $self->{option_results}->{filter_appl_name} ne '' &&
            $row->[0] !~ /$self->{option_results}->{filter_appl_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $row->[0] . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{exclude_appl_name}) && $self->{option_results}->{exclude_appl_name} ne '' &&
            $row->[0] =~ /$self->{option_results}->{exclude_appl_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $row->[0] . "': no matching filter.", debug => 1);
            next;
        }

        $self->{global}->{connected}++;
    }
}

1;

__END__

=head1 MODE

Check connected users.

=over 8

=item B<--filter-appl-name>

Filter users by application name (can be a regex).

=item B<--exclude-appl-name>

Exclude users by application name (can be a regex).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'connected'.

=back

=cut
