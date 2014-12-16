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

package database::oracle::mode::rmanonlinebackupage;

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

    $self->{sql}->connect();
    my $query = q{SELECT min(((time  -  date '1970-01-01') * 86400) - TO_NUMBER(SUBSTR(TZ_OFFSET(DBTIMEZONE),1,3))*3600 - TO_NUMBER(SUBSTR(TZ_OFFSET(DBTIMEZONE),1,1) || SUBSTR(TZ_OFFSET(DBTIMEZONE),5,2))*60 ) as last_time
                  FROM v$backup
                  WHERE STATUS='ACTIVE'
    };
    $self->{sql}->query(query => $query);
    my $result = $self->{sql}->fetchall_arrayref();

    $self->{output}->output_add(severity => 'OK',
                                short_msg => sprintf("Rman online backup age are ok."));

    my $count_backups = 0;
    foreach my $row (@$result) {
        next if (!defined($$row[0]));
        my $last_time = $$row[0];
        $last_time = sprintf("%i", $last_time);
        $count_backups++;
        my $now = sprintf("%i",time());
        my $backup_age = $now - $last_time;
        my $backup_age_convert = centreon::plugins::misc::change_seconds(value => $backup_age);
        $self->{output}->output_add(long_msg => sprintf("Last Rman online backup : %s", $backup_age_convert));
        $self->{output}->perfdata_add(label => 'online_backup_age',
                                      value => $backup_age,
                                      unit => 's',
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                      min => 0);
        my $exit_code = $self->{perfdata}->threshold_check(value => $backup_age, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
        if (!$self->{output}->is_status(value => $exit_code, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit_code,
                                        short_msg => sprintf("Last Rman online backup : %s", $backup_age_convert));
        }
    }

    if (($count_backups == 0) && (!defined($self->{option_results}->{skip_no_backup}))) {
        $self->{output}->output_add(severity => 'CRITICAL',
                                    short_msg => sprintf("Rman online backups never executed."));
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Oracle rman online backup age.

=over 8

=item B<--warning>

Threshold warning in seconds.

=item B<--critical>

Threshold critical in seconds.

=item B<--skip-bo-backup>

Return ok if no backup found.

=back

=cut
