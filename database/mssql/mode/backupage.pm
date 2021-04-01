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

package database::mssql::mode::backupage;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use Time::HiRes;
use Time::Local;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                  "filter:s"                => { name => 'filter', },
                                  "skip"                    => { name => 'skip', },
                                  "skip-no-backup"          => { name => 'skip_no_backup', },
                                  "warning:s"               => { name => 'warning', },
                                  "critical:s"              => { name => 'critical', },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
       $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{sql} = sqlmode object
    $self->{sql} = $options{sql};

    $self->{output}->output_add(severity => 'OK',
                                short_msg => "All backups are ok.");

    $self->{sql}->connect();

    my $count = 0;
    my $query = 'SELECT
              a.name, a.recovery_model,
              DATEDIFF(SS, MAX(b.backup_finish_date), GETDATE()),
              DATEDIFF(SS, MAX(b.backup_start_date), MAX(b.backup_finish_date))
            FROM master.dbo.sysdatabases a LEFT OUTER JOIN msdb.dbo.backupset b
            ON b.database_name = a.name
            GROUP BY a.name
            ORDER BY a.name
    ';

    if (($self->{sql}->is_version_minimum(version => '9.x'))) {
        $query = "SELECT D.name AS [database_name], D.recovery_model, BS1.last_backup, BS1.last_duration
                 FROM sys.databases D
                 LEFT JOIN (
                    SELECT BS.[database_name],
                    DATEDIFF(SS,MAX(BS.[backup_finish_date]),GETDATE()) AS last_backup,
                    DATEDIFF(SS,MAX(BS.[backup_start_date]),MAX(BS.[backup_finish_date])) AS last_duration
                    FROM msdb.dbo.backupset BS
                    WHERE BS.type = 'D'
                    GROUP BY BS.[database_name]
                ) BS1 ON D.name = BS1.[database_name]
                ORDER BY D.[name]";
    }

    $self->{sql}->query(query => $query);
    my $result = $self->{sql}->fetchall_arrayref();
    foreach my $row (@$result) {
        next if (defined($self->{option_results}->{filter}) && $$row[0] !~ /$self->{option_results}->{filter}/);
        $count++;
        #dbt_backup_start: 0x1686303d8 (dtdays=40599, dttime=7316475)    Feb 27 2011  6:46:28:250AM
        my $last_backup = $$row[2];
        my $backup_duration = $$row[3];
        if (!defined($last_backup)) {
            if (!defined($self->{option_results}->{skip_no_backup})) {
                $self->{output}->output_add(severity => 'CRITICAL',
                                            short_msg => sprintf("No backup found for DB '%s'", $$row[0]));
            }
        } else {
            $self->{output}->output_add(long_msg => sprintf("DB '%s' backup age : %ds [Duration : %ds]", $$row[0], $last_backup, $backup_duration));
            my $exit_code = $self->{perfdata}->threshold_check(value => $last_backup, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
            if (!$self->{output}->is_status(value => $exit_code, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit_code,
                                            short_msg => sprintf("DB '%s' backup age: %ds [Duration : %ds]", $$row[0], $last_backup, $backup_duration));
            
            }
            
            $self->{output}->perfdata_add(label => sprintf("db_%s_backup_age",$$row[0]),
                                          unit => 's',
                                          value => $last_backup,
                                          warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                          critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                          min => 0);
            $self->{output}->perfdata_add(label => sprintf("db_%s_backup_duration",$$row[0]),
                                          unit => 's',
                                          value => $backup_duration,
                                          min => 0);
        }
    }

    if ($count == 0) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => "No backup found");
        if (!defined($self->{option_results}->{skip})) {
            $self->{output}->output_add(severity => 'UNKNOWN',
                                        short_msg => "No backup found");
        }
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check MSSQL backup age.

=over 8

=item B<--filter>

Filter database.

=item B<--skip>

Return ok if no backup found.

=item B<--skip-no-backup>

Skip databases without backup.

=item B<--warning>

Threshold warning in seconds.

=item B<--critical>

Threshold critical in seconds.

=back

=cut
