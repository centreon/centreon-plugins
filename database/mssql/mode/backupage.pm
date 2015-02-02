################################################################################
# Copyright 2005-2013 MERETHIS
# Centreon is developped by : Julien Mathis and Romain Le Merlus under
# GPL Licence 2.0.
# 
# This program is free software; you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation ; either version 2 of the License.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along with 
# this program; if not, see <http://www.gnu.org/licenses>.
# 
# Linking this program statically or dynamically with other modules is making a 
# combined work based on this program. Thus, the terms and conditions of the GNU 
# General Public License cover the whole combination.
# 
# As a special exception, the copyright holders of this program give MERETHIS 
# permission to link this program with independent modules to produce an executable, 
# regardless of the license terms of these independent modules, and to copy and 
# distribute the resulting executable under terms of MERETHIS choice, provided that 
# MERETHIS also meet, for each linked independent module, the terms  and conditions 
# of the license of that module. An independent module is a module which is not 
# derived from this program. If you modify this program, you may extend this 
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
# 
# For more information : contact@centreon.com
# Authors : Kevin Duret <kduret@merethis.com>
#
####################################################################################

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
    
    $self->{version} = '1.0';
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
