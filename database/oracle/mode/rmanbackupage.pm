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

package database::oracle::mode::rmanbackupage;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use Time::HiRes;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "skip-no-backup"          => { name => 'skip_no_backup', },
                                  "filter-type:s"           => { name => 'filter_type', },
                                  "warning-db-incr:s"       => { name => 'warning_db_incr', },
                                  "critical-db-incr:s"      => { name => 'critical_db_incr', },
                                  "warning-db-full:s"       => { name => 'warning_db_full', },
                                  "critical-db-full:s"      => { name => 'critical_db_full', },
                                  "warning-archivelog:s"    => { name => 'warning_archivelog', },
                                  "critical-archivelog:s"   => { name => 'critical_archivelog', },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning_db_incr', value => $self->{option_results}->{warning_db_incr})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning-db-incr threshold '" . $self->{option_results}->{warning_db_incr} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical_db_incr', value => $self->{option_results}->{critical_db_incr})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical-db-incr threshold '" . $self->{option_results}->{critical_db_incr} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning_db_full', value => $self->{option_results}->{warning_db_full})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning-db-full threshold '" . $self->{option_results}->{warning_db_full} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical_db_full', value => $self->{option_results}->{critical_db_full})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical-db-full threshold '" . $self->{option_results}->{critical_db_full} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning_archivelog', value => $self->{option_results}->{warning_archivelog})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning-archivelog threshold '" . $self->{option_results}->{warning_archivelog} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical_archivelog', value => $self->{option_results}->{critical_archivelog})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical-archivelog threshold '" . $self->{option_results}->{critical_archivelog} . "'.");
       $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{sql} = sqlmode object
    $self->{sql} = $options{sql};

    $self->{sql}->connect();
    my $retention = $self->{option_results}->{retention};
    my $query = q{SELECT object_type, count(*) as num,
                    ((max(start_time) - date '1970-01-01')*24*60*60 - TO_NUMBER(SUBSTR(TZ_OFFSET(DBTIMEZONE),1,3))*3600 - TO_NUMBER(SUBSTR(TZ_OFFSET(DBTIMEZONE),1,1) || SUBSTR(TZ_OFFSET(DBTIMEZONE),5,2))*60) as last_time
                    FROM v$rman_status
                    WHERE operation='BACKUP'
                    GROUP BY object_type};
    $self->{sql}->query(query => $query);
    my $result = $self->{sql}->fetchall_arrayref();

    $self->{output}->output_add(severity => 'OK',
                                short_msg => sprintf("Rman backup age are ok."));

    my $count_backups = 0;
    foreach my $row (@$result) {
        my ($type, $count, $last_time) = @$row;
        $last_time = sprintf("%i", $last_time);
        next if (defined($self->{option_results}->{filter_type}) && $type !~ /$self->{option_results}->{filter_type}/);
        $count_backups++;
        my $now = sprintf("%i",time());
        my $backup_age = $now - $last_time;
        my $backup_age_convert = centreon::plugins::misc::change_seconds(value => $backup_age);
        my $type_perfdata = $type;
        $type_perfdata =~ s/\s+/_/;
        $self->{output}->output_add(long_msg => sprintf("Last Rman '%s' backups : %s", $type, $backup_age_convert));
        my $exit_code;
        if ($type =~ /incr/i) {
            $self->{output}->perfdata_add(label => sprintf('%s_backup_age',$type_perfdata),
                                          value => $backup_age,
                                          unit => 's',
                                          warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning_db_incr'),
                                          critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical_db_incr'),
                                          min => 0);
            $exit_code = $self->{perfdata}->threshold_check(value => $backup_age, threshold => [ { label => 'critical_db_incr', 'exit_litteral' => 'critical' }, { label => 'warning_db_incr', exit_litteral => 'warning' } ]);
        } elsif ($type =~ /full/i) {
            $self->{output}->perfdata_add(label => sprintf('%s_backup_age',$type_perfdata),
                                          value => $backup_age,
                                          unit => 's',
                                          warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning_db_full'),
                                          critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical_db_full'),
                                          min => 0);
            $exit_code = $self->{perfdata}->threshold_check(value => $backup_age, threshold => [ { label => 'critical_db_full', 'exit_litteral' => 'critical' }, { label => 'warning_db_full', exit_litteral => 'warning' } ]);
        } elsif ($type =~ /archive/i) {
            $self->{output}->perfdata_add(label => sprintf('%s_backup_age',$type_perfdata),
                                          value => $backup_age,
                                          unit => 's',
                                          warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning_archivelog'),
                                          critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical_archivelog'),
                                          min => 0);
            $exit_code = $self->{perfdata}->threshold_check(value => $backup_age, threshold => [ { label => 'critical_archivelog', 'exit_litteral' => 'critical' }, { label => 'warning_archivelog', exit_litteral => 'warning' } ]);
        }
        if (!$self->{output}->is_status(value => $exit_code, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit_code,
                                        short_msg => sprintf("Last Rman '%s' backups : %s", $type, $backup_age_convert));
        }
    }

    if (($count_backups == 0) && (!defined($self->{option_results}->{skip_no_backup}))) {
        $self->{output}->output_add(severity => 'CRITICAL',
                                    short_msg => sprintf("Rman backups never executed."));
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Oracle rman backup problems.

=over 8

=item B<--warning-db-incr>

Threshold warning of DB INCR backups in seconds.

=item B<--critical-db-incr>

Threshold critical of DB INCR backups in seconds.

=item B<--warning-db-full>

Threshold warning of DB FULL backups in seconds.

=item B<--critical-db-full>

Threshold critical of DB FULL backups in seconds.

=item B<--warning-archivelog>

Threshold warning of ARCHIVELOG backups in seconds.

=item B<--critical-archivelog>

Threshold critical of ARCHIVELOG backups in seconds.

=item B<--filter-type>

Filter backup type.
(type can be : 'DB INCR', 'DB FULL', 'ARCHIVELOG')

=item B<--skip-bo-backup>

Return ok if no backup found.

=back

=cut
