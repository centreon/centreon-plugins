#
# Copyright 2022 Centreon (http://www.centreon.com/)
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

package database::mssql::mode::backupage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use POSIX;

my $unitdiv = { s => 1, w => 604800, d => 86400, h => 3600, m => 60 };
my $unitdiv_long = { s => 'seconds', w => 'weeks', d => 'days', h => 'hours', m => 'minutes' };

sub custom_duration_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        unit => 's',
        instances => [$self->{result_values}->{name}, $self->{result_values}->{type}],
        value => $self->{result_values}->{duration_seconds},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub custom_backup_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel} . '.' . $unitdiv_long->{ $self->{instance_mode}->{option_results}->{unit} },
        unit => $self->{instance_mode}->{option_results}->{unit},
        instances => [$self->{result_values}->{name}, $self->{result_values}->{type}],
        value => floor($self->{result_values}->{exec_seconds} / $unitdiv->{ $self->{instance_mode}->{option_results}->{unit} }),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => -1
    );
}

sub custom_backup_threshold {
    my ($self, %options) = @_;

    return $self->{perfdata}->threshold_check(
        value => floor($self->{result_values}->{exec_seconds} / $unitdiv->{ $self->{instance_mode}->{option_results}->{unit} }),
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' },
            { label => 'unknown-'. $self->{thlabel}, exit_litteral => 'unknown' }
        ]
    );
}

sub custom_backup_output {
    my ($self, %options) = @_;

    my $msg;
    if ($self->{result_values}->{exec_seconds} == -1) {
        $msg = 'backup never executed';
    } else {
        $msg = 'last backup execution: ' . $self->{result_values}->{exec_human};
    }
    return $msg;
}

sub prefix_database_output {
    my ($self, %options) = @_;

    return "database '" . $options{instance} . "' ";
}

sub database_long_output {
    my ($self, %options) = @_;

    return "checking database '" . $options{instance} . "'";
}

sub prefix_full_output { return 'full '; }
sub prefix_incremental_output { return 'incremental '; }
sub prefix_log_output { return 'log '; }

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name => 'databases', type => 3, cb_prefix_output => 'prefix_database_output', cb_long_output => 'database_long_output', indent_long_output => '    ', message_multiple => 'All databases are ok',
            group => [
                { name => 'full', type => 0, cb_prefix_output => 'prefix_full_output', skipped_code => { -10 => 1 } },
                { name => 'incremental', type => 0, cb_prefix_output => 'prefix_incremental_output', skipped_code => { -10 => 1 } },
                { name => 'log', type => 0, cb_prefix_output => 'prefix_log_output', skipped_code => { -10 => 1 } }
            ]
        }
    ];

    foreach ('full', 'incremental', 'log') {
        $self->{maps_counters}->{$_} = [
            { label => $_ . '-last-execution', nlabel => 'backup.time.last.execution', set => {
                    key_values      => [ { name => 'exec_seconds' }, { name => 'exec_human' }, { name => 'name' }, { name => 'type' } ],
                    closure_custom_output => $self->can('custom_backup_output'),
                    closure_custom_perfdata => $self->can('custom_backup_perfdata'),
                    closure_custom_threshold_check => $self->can('custom_backup_threshold')
                }
            },
            { label => $_ . '-last-duration', nlabel => 'backup.time.last.duration.seconds', set => {
                    key_values => [ { name => 'duration_seconds' }, { name => 'duration_human' }, { name => 'name' }, { name => 'type' } ],
                    output_template => 'duration time: %s',
                    output_use => 'duration_human',
                    closure_custom_perfdata => $self->can('custom_duration_perfdata')
                }
            }
        ];
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'filter-name:s' => { name => 'filter_name' },
        'unit:s'        => { name => 'unit', default => 'd' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if ($self->{option_results}->{unit} eq '' || !defined($unitdiv->{$self->{option_results}->{unit}})) {
        $self->{option_results}->{unit} = 'd';
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    $options{sql}->connect();

    my $query = q{
        SELECT
            a.name, 
            a.recovery_model,
            DATEDIFF(SS, MAX(b.backup_finish_date), GETDATE()),
            DATEDIFF(SS, MAX(b.backup_start_date), MAX(b.backup_finish_date)),
            b.type
        FROM master.dbo.sysdatabases a LEFT OUTER JOIN msdb.dbo.backupset b ON b.database_name = a.name
        WHERE b.type IN ('D', 'I', 'L')
        GROUP BY a.name, b.type
        ORDER BY a.name
    };
    if ($options{sql}->is_version_minimum(version => '9.x')) {
        $query = q{
            SELECT
                D.name AS [database_name],
                D.recovery_model, 
                BS1.last_backup,
                BS1.last_duration,
                BS1.type
            FROM sys.databases D
            LEFT JOIN (
                SELECT
                    BS.[database_name],
                    BS.[type],
                    DATEDIFF(SS, MAX(BS.[backup_finish_date]), GETDATE()) AS last_backup,
                    DATEDIFF(SS, MAX(BS.[backup_start_date]), MAX(BS.[backup_finish_date])) AS last_duration
                FROM msdb.dbo.backupset BS
                WHERE BS.type IN ('D', 'I', 'L')
                GROUP BY BS.[database_name], BS.[type]
            ) BS1 ON D.name = BS1.[database_name]
            WHERE D.source_database_id IS NULL
            ORDER BY D.[name]
        };
    }

    $options{sql}->query(query => $query);
    my $result = $options{sql}->fetchall_arrayref();

    my $map_type = { D => 'full', I => 'incremental', L => 'log' };
    $self->{databases} = {};
    foreach my $row (@$result) {
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $row->[0] !~ /$self->{option_results}->{filter_name}/);
        if (!defined($self->{databases}->{ $row->[0] })) {
            $self->{databases}->{ $row->[0] } = {
                full => { exec_seconds => -1, exec_human => '', type => 'full', name => $row->[0] },
                incremental => { exec_seconds => -1, exec_human => '', type => 'incremental', name => $row->[0] },
                log => { exec_seconds => -1, exec_human => '', type => 'log', name => $row->[0] }
            };
        }

        next if (!defined($map_type->{ $row->[4] }));

        if (defined($row->[2])) {
            $self->{databases}->{ $row->[0] }->{ $map_type->{ $row->[4] } }->{exec_seconds} = $row->[2];
            $self->{databases}->{ $row->[0] }->{ $map_type->{ $row->[4] } }->{exec_human} = centreon::plugins::misc::change_seconds(
                value => $row->[2]
            );
        }
        if (defined($row->[3])) {
            $self->{databases}->{ $row->[0] }->{ $map_type->{ $row->[4] } }->{duration_seconds} = $row->[3];
            $self->{databases}->{ $row->[0] }->{ $map_type->{ $row->[4] } }->{duration_human} = centreon::plugins::misc::change_seconds(
                value => $row->[3]
            );
        }
    }
}

1;

__END__

=head1 MODE

Check MSSQL backup.

=over 8

=item B<--filter-name>

Filter databases by name.

=item B<--unit>

Select the unit for expires threshold. May be 's' for seconds, 'm' for minutes,
'h' for hours, 'd' for days, 'w' for weeks. Default is days.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'incremental-last-execution', 'incremental-last-duration',
'full-last-execution', 'full-last-duration',
'log-last-execution', 'log-last-duration'.

=back

=cut
