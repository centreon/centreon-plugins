#
# Copyright 2023 Centreon (http://www.centreon.com/)
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

package database::mssql::mode::memorygrants;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

my %counters_mapping = (
    'Memory Grants Outstanding' => 'outstanding',
    'Memory Grants Pending' => 'pending'
);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];
    
    $self->{maps_counters}->{global} = [
        {
            label => 'memory-grants-outstanding',
            nlabel => 'mssql.memory.grants.outstanding.count',
            set => {
                key_values => [
                    { name => 'outstanding' }
                ],
                output_template => 'Grants Outstanding: %d',
                output_change_bytes => 1,
                perfdatas => [
                    { value => 'outstanding', template => '%d', min => 0 },
                ],
            }
        },
        {
            label => 'memory-grants-pending',
            nlabel => 'mssql.memory.grants.pending.count',
            set => {
                key_values => [
                    { name => 'pending' }
                ],
                output_template => 'Grants Pending: %d',
                output_change_bytes => 1,
                perfdatas => [
                    { value => 'pending', template => '%d', min => 0 },
                ],
            }
        }
    ]
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {});

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    $options{sql}->connect();
    $options{sql}->query(query => q{
        SELECT
            counter_name, cntr_value
        FROM
            sys.dm_os_performance_counters
        WHERE
            object_name LIKE '%Memory Manager%'
        AND
            counter_name LIKE 'Memory Grants%'
    });

    while ((my $row = $options{sql}->fetchrow_hashref())) {
        my $counter_name = centreon::plugins::misc::trim($row->{counter_name});
        next if (!defined($counters_mapping{$counter_name}));
        $self->{global}->{$counters_mapping{$counter_name}} = $row->{cntr_value};
    }
}

1;

__END__

=head1 MODE

Check MSSQL memory grants.

See:

https://learn.microsoft.com/en-us/sql/relational-databases/performance-monitor/sql-server-memory-manager-object

=over 8

=item B<--warning-*> B<--critical-*>

Can be: 'outstanding', 'pending'.

=back

=cut