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

package database::mssql::mode::transactions;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use Digest::MD5 qw(md5_hex);

sub prefix_database_output {
    my ($self, %options) = @_;

    return "Database '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'database', type => 1, cb_prefix_output => 'prefix_database_output', message_multiple => 'All databases are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'databases-transactions', nlabel => 'databases.transactions.persecond', set => {
                key_values => [ { name => 'transactions', per_second => 1 } ],
                output_template => 'total transactions: %.2f/s',
                perfdatas => [
                    { template => '%.2f', unit => '/s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{database} = [
        { label => 'database-transactions', nlabel => 'database.transactions.persecond', set => {
                key_values => [ { name => 'transactions', per_second => 1 }, { name => 'display' } ],
                output_template => 'transactions: %.2f/s',
                perfdatas => [
                    { template => '%.2f', unit => '/s', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-database:s' => { name => 'filter_database' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $options{sql}->connect();
    $options{sql}->query(query => q{SELECT instance_name, cntr_value FROM sys.dm_os_performance_counters WHERE UPPER(counter_name) = UPPER('transactions/sec')});
    my $result = $options{sql}->fetchall_arrayref();

    $self->{global} = {};
    $self->{database} = {};
    foreach my $row (@$result) {
        my $name = centreon::plugins::misc::trim($row->[0]);
        if ($name eq '_Total') {
            $self->{global}->{transactions} = $row->[1];
            next;
        }
        if (defined($self->{option_results}->{filter_database}) && $self->{option_results}->{filter_database} ne '' &&
            $name !~ /$self->{option_results}->{filter_database}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $name . "': no matching filter.", debug => 1);
            next;
        }

        $self->{database}->{ $name } = {
            display => $name,
            transactions => $row->[1]
        };
    }
    
    $self->{cache_name} = 'mssql_' . $self->{mode} . '_' . $options{sql}->get_unique_id4save() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_database}) ? md5_hex($self->{option_results}->{filter_database}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check MSSQL transactions.

=over 8

=item B<--filter-database>

Filter database name (can be a regexp).

=item B<--warning-*> B<--critical-*> 

Thresholds.
Can be: 'databases-transactions', 'database-transactions'.

=back

=cut
