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

package database::oracle::mode::rmanbackupage;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use DateTime;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'skip-no-backup'    => { name => 'skip_no_backup', },
        'filter-type:s'     => { name => 'filter_type', },
        'timezone:s'        => { name => 'timezone', },
        'incremental-level' => { name => 'incremental_level', },
    });

    foreach (('db incr', 'db full', 'archivelog', 'controlfile')) {
        my $label = $_;
        $label =~ s/ /-/g;
        $options{options}->add_options(arguments => {	
            'warning-' . $label . ':s'  => { name => 'warning-' . $label },
            'critical-' . $label . ':s' => { name => 'critical-' . $label },
            'no-' . $label              => { name => 'no-' . $label },
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

    if (defined($self->{option_results}->{timezone}) && $self->{option_results}->{timezone} ne '') {
        $ENV{TZ} = $self->{option_results}->{timezone};
    }

    if (defined($self->{option_results}->{incremental_level})) {
        # the special request don't retrieve controlfiles. But controlfiles are saved with archivelog.
        $self->{option_results}->{'no-controlfile'} = 1;
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{sql} = sqlmode object
    $self->{sql} = $options{sql};

    $self->{sql}->connect();
    my $query;
    if (defined($self->{option_results}->{incremental_level})) {
        $query = q{SELECT v$rman_status.object_type,
                    ((max(v$rman_status.start_time) - date '1970-01-01')*24*60*60) as last_time,
                    SUM(v$backup_set_details.incremental_level)
                    FROM v$rman_status LEFT JOIN v$backup_set_details ON v$rman_status.session_recid = v$backup_set_details.session_recid
                    WHERE operation='BACKUP'
                    GROUP BY object_type, v$backup_set_details.session_recid ORDER BY last_time DESC
        };
    } else {
        $query = q{SELECT object_type,
                    ((max(start_time) - date '1970-01-01')*24*60*60) as last_time
                    FROM v$rman_status
                    WHERE operation='BACKUP'
                    GROUP BY object_type};
    }
    $self->{sql}->query(query => $query);
    my $result = $self->{sql}->fetchall_arrayref();
    $self->{sql}->disconnect();

    $self->{output}->output_add(severity => 'OK',
                                short_msg => sprintf("Rman backup age are ok."));

    my $count_backups = 0;
    my $already_checked = {};
    foreach (('db full', 'db incr', 'archivelog', 'controlfile')) {
        my $executed = 0;
        my $label = $_;
        $label =~ s/ /-/g;
        foreach my $row (@$result) {
            if (defined($self->{option_results}->{incremental_level})) {
                # db incr with incremental level 0 = DB FULL
                 if (/db full/ && $$row[0] =~ /db incr/i && (!defined($$row[2]) || $$row[2] == 0)) { # it's a full. we get
                    $$row[0] = 'DB FULL';
                } else {
                    next if (/db incr/ && $$row[0] =~ /db incr/i && (!defined($$row[2]) || $$row[2] == 0)); # it's a full. we skip.
                    next if ($$row[0] !~ /$_/i);
                }
            } else {
                next if ($$row[0] !~ /$_/i);
            }

            next if (defined($already_checked->{$$row[0]}));

            $already_checked->{$$row[0]} = 1;
            
            $count_backups++;
            $executed = 1;
            my ($type, $last_time) = @$row;
            next if (defined($self->{option_results}->{filter_type}) && $type !~ /$self->{option_results}->{filter_type}/);

            my @values = localtime($last_time);
            my $dt = DateTime->new(
                year       => $values[5] + 1900,
                month      => $values[4] + 1,
                day        => $values[3],
                hour       => $values[2],
                minute     => $values[1],
                second     => $values[0],
                time_zone  => 'UTC'
            );
            my $offset = $last_time - $dt->epoch;
            $last_time = $last_time + $offset;

            my $backup_age = time() - $last_time;
        
            my $backup_age_convert = centreon::plugins::misc::change_seconds(value => $backup_age);
            my $type_perfdata = $type;
            $type_perfdata =~ s/ /_/g;
            $self->{output}->output_add(long_msg => sprintf("Last Rman '%s' backups : %s", $type, $backup_age_convert));
            $self->{output}->perfdata_add(
                label => sprintf('%s_backup_age', $type_perfdata),
                value => $backup_age,
                unit => 's',
                warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $label),
                critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $label),
                min => 0
            );
            my $exit_code = $self->{perfdata}->threshold_check(value => $backup_age, threshold => [ { label => 'critical-' . $label, exit_litteral => 'critical' }, { label => 'warning-' . $label, exit_litteral => 'warning' } ]);
            
            if (!$self->{output}->is_status(value => $exit_code, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit_code,
                    short_msg => sprintf("Last Rman '%s' backups : %s", $type, $backup_age_convert)
                );
            }
        }
        
        if ($executed == 0 && !defined($self->{option_results}->{'no-' . $label})) {
            $self->{output}->output_add(
                severity => 'CRITICAL',
                short_msg => sprintf("Rman '%s' backups never executed", uc($_))
            );
        }
    }

    if (($count_backups == 0) && (!defined($self->{option_results}->{skip_no_backup}))) {
        $self->{output}->output_add(
            severity => 'CRITICAL',
            short_msg => sprintf("Rman backups never executed.")
        );
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

=item B<  --no-*>

Skip error if never executed.
Can be: 'db-incr', 'db-full', 'archivelog', 'controlfile'.

=item B<--filter-type>

Filter backup type.
(type can be : 'DB INCR', 'DB FULL', 'ARCHIVELOG')

=item B<--skip-no-backup>

Return ok if no backup found.

=item B<--timezone>

Timezone of oracle server (If not set, we use current server execution timezone).

=item B<--incremental-level>

Please use the following option if your using incremental level 0 for full backup.

=back

=cut
