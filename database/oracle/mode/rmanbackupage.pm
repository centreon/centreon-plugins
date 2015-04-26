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
use DateTime;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "skip-no-backup"          => { name => 'skip_no_backup', },
                                  "filter-type:s"           => { name => 'filter_type', },
                                  "timezone:s"              => { name => 'timezone', },
                                });
    foreach (('db incr', 'db full', 'archivelog', 'controlfile')) {
        my $label = $_;
        $label =~ s/ /-/g;
        $options{options}->add_options(arguments => {	
                                                     'warning-' . $label . ':s'     => { name => 'warning-' . $label },
                                                     'critical-' . $label . ':s'    => { name => 'critical-' . $label },
                                                     'no-' . $label                 => { name => 'no-' . $label },
                                      });
    }

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    foreach (('db incr', 'db full', 'archivelog', 'controlfile')) {
        my $label = $_;
        $label =~ s/ /-/g;
        foreach my $threshold (('warning', 'critical')) {
            if (($self->{perfdata}->threshold_validate(label => $threshold . '-' . $label, value => $self->{option_results}->{$threshold . '-' . $label})) == 0) {
                $self->{output}->add_option_msg(short_msg => "Wrong " . $threshold . '-' . $label . " threshold '" . $self->{option_results}->{warning_db_incr} . "'.");
                $self->{output}->option_exit();
            }
        }
    }

    if (defined($self->{option_results}->{timezone})) {
        $ENV{TZ} = $self->{option_results}->{timezone};
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{sql} = sqlmode object
    $self->{sql} = $options{sql};

    $self->{sql}->connect();
    my $query = q{SELECT object_type, count(*) as num,
                    ((max(start_time) - date '1970-01-01')*24*60*60) as last_time
                    FROM v$rman_status
                    WHERE operation='BACKUP'
                    GROUP BY object_type};
    $self->{sql}->query(query => $query);
    my $result = $self->{sql}->fetchall_arrayref();

    $self->{output}->output_add(severity => 'OK',
                                short_msg => sprintf("Rman backup age are ok."));

    my $count_backups = 0;
    foreach (('db incr', 'db full', 'archivelog', 'controlfile')) {
        my $executed = 0;
        my $label = $_;
        $label =~ s/ /-/g;
        foreach my $row (@$result) {
            next if ($$row[0] !~ /$_/i);
            
            $count_backups++;
            $executed = 1;
            my ($type, $count, $last_time) = @$row;
            next if (defined($self->{option_results}->{filter_type}) && $type !~ /$self->{option_results}->{filter_type}/);

            my @values = localtime($last_time);
            my $dt = DateTime->new(
                            year       => $values[5] + 1900,
                            month      => $values[4] + 1,
                            day        => $values[3],
                            hour       => $values[2],
                            minute     => $values[1],
                            second     => $values[0],
                            time_zone  => 'UTC',
            );
            my $offset = $last_time - $dt->epoch;
            $last_time = $last_time + $offset;

            my $backup_age = time() - $last_time;
        
            my $backup_age_convert = centreon::plugins::misc::change_seconds(value => $backup_age);
            my $type_perfdata = $type;
            $type_perfdata =~ s/ /_/g;
            $self->{output}->output_add(long_msg => sprintf("Last Rman '%s' backups : %s", $type, $backup_age_convert));
            $self->{output}->perfdata_add(label => sprintf('%s_backup_age',$type_perfdata),
                                          value => $backup_age,
                                          unit => 's',
                                          warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $label),
                                          critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $label),
                                          min => 0);
            my $exit_code = $self->{perfdata}->threshold_check(value => $backup_age, threshold => [ { label => 'critical-' . $label, 'exit_litteral' => 'critical' }, { label => 'warning-' . $label, exit_litteral => 'warning' } ]);
            
            if (!$self->{output}->is_status(value => $exit_code, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit_code,
                                            short_msg => sprintf("Last Rman '%s' backups : %s", $type, $backup_age_convert));
            }
        }
        
        if ($executed == 0 && !defined($self->{option_results}->{'no-' . $label})) {
            $self->{output}->output_add(severity => 'CRITICAL',
                                        short_msg => sprintf("Rman '%s' backups never executed", uc($_)));
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

Check Oracle rman backup age.

=over 8

=item B<--warning-*>

Threshold warning in seconds.
Can be: 'db-incr', 'db-full', 'archivelog', 'controlfile'.

=item B<--critical-*>

Threshold critical in seconds.
Can be: 'db-incr', 'db-full', 'archivelog', 'controlfile'.

=item B<--no-*>

Skip error if never executed.
Can be: 'db-incr', 'db-full', 'archivelog', 'controlfile'.

=item B<--filter-type>

Filter backup type.
(type can be : 'DB INCR', 'DB FULL', 'ARCHIVELOG')

=item B<--skip-no-backup>

Return ok if no backup found.

=item B<--timezone>

Timezone of oracle server (If not set, we use current server execution timezone)

=back

=cut
