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

package database::mssql::mode::memoryusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

my %counters_mapping = (
    'Total Server Memory (KB)' => 'total_server',
    'Target Server Memory (KB)' => 'target_server',
    'Connection Memory (KB)' => 'connection',
    'Database Cache Memory (KB)' => 'database_cache',
    'Free Memory (KB)' => 'free',
    'Granted Workspace Memory (KB)' => 'granted_workplace',
    'Lock Memory (KB)' => 'lock',
    'Maximum Workspace Memory (KB)' => 'maximum_workplace',
    'Optimizer Memory (KB)' => 'optimizer',
    'Reserved Server Memory (KB)' => 'reserved_server',
    'SQL Cache Memory (KB)' => 'sql_cache',
    'Stolen Server Memory (KB)' => 'stolen_server',
    'Log Pool Memory (KB)' => 'log_pool'
);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf("Threshold matches with following values [total_server: %s %s] [target_server: %s %s] [connection: %s %s] [database_cache: %s %s] [free: %s %s] [granted_workplace: %s %s] [lock: %s %s] [maximum_workplace: %s %s] [optimizer: %s %s][reserved_server: %s %s] [sql_cache: %s %s] [stolen_server: %s %s] [log_pool: %s %s]",
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{total_server}),
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{target_server}),
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{connection}),
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{database_cache}),
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{free}),
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{granted_workplace}),
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{lock}),
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{maximum_workplace}),
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{optimizer}),
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{reserved_server}),
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{sql_cache}),
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{stolen_server}),
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{log_pool})
    );

    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];
    
    $self->{maps_counters}->{global} = [
        {
            label => 'total-server',
            nlabel => 'mssql.memory.server.total.bytes',
            set => {
                key_values => [
                    { name => 'total_server' }
                ],
                output_template => 'Total Server: %.2f %s',
                output_change_bytes => 1,
                perfdatas => [
                    { value => 'total_server', template => '%s', unit => 'B', min => 0 },
                ],
            }
        },
        {
            label => 'target-server',
            nlabel => 'mssql.memory.server.target.bytes',
            set => {
                key_values => [
                    { name => 'target_server' }
                ],
                output_template => 'Target Server: %.2f %s',
                output_change_bytes => 1,
                perfdatas => [
                    { value => 'target_server', template => '%s', unit => 'B', min => 0 },
                ],
            }
        },
        {
            label => 'reserved-server',
            nlabel => 'mssql.memory.server.reserved.bytes',
            set => {
                key_values => [
                    { name => 'reserved_server' }
                ],
                output_template => 'Reserved Server: %.2f %s',
                output_change_bytes => 1,
                perfdatas => [
                    { value => 'reserved_server', template => '%s', unit => 'B', min => 0 },
                ],
            }
        },
        {
            label => 'granted-workplace',
            nlabel => 'mssql.memory.workplace.granted.bytes',
            set => {
                key_values => [
                    { name => 'granted_workplace' }
                ],
                output_template => 'Granted Workplace: %.2f %s',
                output_change_bytes => 1,
                perfdatas => [
                    { value => 'granted_workplace', template => '%s', unit => 'B', min => 0 },
                ],
            }
        },
        {
            label => 'maximum-workplace',
            nlabel => 'mssql.memory.workplace.maximum.bytes',
            display_ok => 0,
            set => {
                key_values => [
                    { name => 'maximum_workplace' }
                ],
                output_template => 'Maximum Workplace: %.2f %s',
                output_change_bytes => 1,
                perfdatas => [
                    { value => 'maximum_workplace', template => '%s', unit => 'B', min => 0 },
                ],
            }
        },
        {
            label => 'connection',
            nlabel => 'mssql.memory.connection.bytes',
            display_ok => 0,
            set => {
                key_values => [
                    { name => 'connection' }
                ],
                output_template => 'Connection: %.2f %s',
                output_change_bytes => 1,
                perfdatas => [
                    { value => 'connection', template => '%s', unit => 'B', min => 0 },
                ],
            }
        },
        {
            label => 'database-cache',
            nlabel => 'mssql.memory.cache.database.bytes',
            display_ok => 0,
            set => {
                key_values => [
                    { name => 'database_cache' }
                ],
                output_template => 'Database Cache: %.2f %s',
                output_change_bytes => 1,
                perfdatas => [
                    { value => 'database_cache', template => '%s', unit => 'B', min => 0 },
                ],
            }
        },
        {
            label => 'free',
            nlabel => 'mssql.memory.free.bytes',
            display_ok => 0,
            set => {
                key_values => [
                    { name => 'free' }
                ],
                output_template => 'Free: %.2f %s',
                output_change_bytes => 1,
                perfdatas => [
                    { value => 'free', template => '%s', unit => 'B', min => 0 },
                ],
            }
        },
        {
            label => 'lock',
            nlabel => 'mssql.memory.lock.bytes',
            display_ok => 0,
            set => {
                key_values => [
                    { name => 'lock' }
                ],
                output_template => 'Lock: %.2f %s',
                output_change_bytes => 1,
                perfdatas => [
                    { value => 'lock', template => '%s', unit => 'B', min => 0 },
                ],
            }
        },
        {
            label => 'optimizer',
            nlabel => 'mssql.memory.optimizer.bytes',
            display_ok => 0,
            set => {
                key_values => [
                    { name => 'optimizer' }
                ],
                output_template => 'Optimizer: %.2f %s',
                output_change_bytes => 1,
                perfdatas => [
                    { value => 'optimizer', template => '%s', unit => 'B', min => 0 },
                ],
            }
        },
        {
            label => 'sql-cache',
            nlabel => 'mssql.memory.cache.sql.bytes',
            display_ok => 0,
            set => {
                key_values => [
                    { name => 'sql_cache' }
                ],
                output_template => 'SQL Cache: %.2f %s',
                output_change_bytes => 1,
                perfdatas => [
                    { value => 'sql_cache', template => '%s', unit => 'B', min => 0 },
                ],
            }
        },
        {
            label => 'stolen-server',
            nlabel => 'mssql.memory.server.stolen.bytes',
            display_ok => 0,
            set => {
                key_values => [
                    { name => 'stolen_server' }
                ],
                output_template => 'Stolen Server: %.2f %s',
                output_change_bytes => 1,
                perfdatas => [
                    { value => 'stolen_server', template => '%s', unit => 'B', min => 0 },
                ],
            }
        },
        {
            label => 'log-pool',
            nlabel => 'mssql.memory.log_pool.bytes',
            display_ok => 0,
            set => {
                key_values => [
                    { name => 'log_pool' }
                ],
                output_template => 'Log Pool: %.2f %s',
                output_change_bytes => 1,
                perfdatas => [
                    { value => 'log_pool', template => '%s', unit => 'B', min => 0 },
                ],
            }
        },
        {
            label => 'status',
            threshold => 0,
            display_ok => 0,
            set => {
                key_values => [
                    { name => 'total_server' },
                    { name => 'target_server' },
                    { name => 'connection' },
                    { name => 'database_cache' },
                    { name => 'free' },
                    { name => 'granted_workplace' },
                    { name => 'lock' },
                    { name => 'maximum_workplace' },
                    { name => 'optimizer' },
                    { name => 'reserved_server' },
                    { name => 'sql_cache' },
                    { name => 'stolen_server' },
                    { name => 'log_pool' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'warning-status:s'  => { name => 'warning_status', default => '' },
        'critical-status:s' => { name => 'critical_status', default => '' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
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
            counter_name LIKE '%(KB)%'
    });

    while ((my $row = $options{sql}->fetchrow_hashref())) {
        my $counter_name = centreon::plugins::misc::trim($row->{counter_name});
        next if (!defined($counters_mapping{$counter_name}));
        $self->{global}->{$counters_mapping{$counter_name}} = $row->{cntr_value} * 1024;
    }
}

1;

__END__

=head1 MODE

Check MSSQL memory usage counters.

Some of the counters are hidden from the output for readability but will graph
anyway.

Use the --warning/critical-status thresholds to compare values and have a
better alerting than just plain thresholds on values.

See:

https://learn.microsoft.com/en-us/sql/relational-databases/performance-monitor/sql-server-memory-manager-object

https://learn.microsoft.com/en-us/sql/relational-databases/performance-monitor/monitor-memory-usage

=over 8

=item B<--warning-status>

Define the conditions to match for the status to be considered WARNING (default: '')

You can use the following variables: %{total_server}, %{target_server}, %{connection}, 
%{database_cache}, %{free}, %{granted_workplace}, %{lock}, %{maximum_workplace},
%{optimizer}, %{reserved_server}, %{sql_cache}, %{stolen_server}, %{log_pool}.

Example:

The Total Server Memory is less than 90% of the Target Server Memory which can
result of a memory pressure:

--warning-status='(%{total_server} / %{target_server} * 100) < 90'

=item B<--critical-status>

Define the conditions to match for the status to be considered CRITICAL (default: '').

You can use the following variables: %{total_server}, %{target_server}, %{connection}, 
%{database_cache}, %{free}, %{granted_workplace}, %{lock}, %{maximum_workplace},
%{optimizer}, %{reserved_server}, %{sql_cache}, %{stolen_server}, %{log_pool}.

=item B<--warning-*> B<--critical-*>

Can be: 'total-server', 'target-server', 'connection', 'database-cache', 'free',
'granted-workplace', 'lock', 'maximum-workplace', 'optimizer', 'reserved-server',
'sql-cache', 'stolen-server', 'log-pool'.

All thresholds are expressed in bytes.

=back

=cut