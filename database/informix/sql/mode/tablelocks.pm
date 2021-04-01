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

package database::informix::sql::mode::tablelocks;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::plugins::statefile;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                  "warning-deadlks:s"       => { name => 'warning_deadlks', },
                                  "critical-deadlks:s"      => { name => 'critical_deadlks', },
                                  "warning-lockwts:s"       => { name => 'warning_lockwts', },
                                  "critical-lockwts:s"      => { name => 'critical_lockwts', },
                                  "warning-lockreqs:s"      => { name => 'warning_lockreqs', },
                                  "critical-lockreqs:s"     => { name => 'critical_lockreqs', },
                                  "warning-lktouts:s"       => { name => 'warning_lktouts', },
                                  "critical-lktouts:s"      => { name => 'critical_lktouts', },
                                  "name:s"                  => { name => 'name', },
                                  "regexp"                  => { name => 'use_regexp' },
                                  "filter-tables:s"         => { name => 'filter_tables' },
                                  "only-databases"          => { name => 'only_databases' },
                                });
    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);
                                
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning-deadlks', value => $self->{option_results}->{warning_deadlks})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning-deadlks threshold '" . $self->{option_results}->{warning_deadlks} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-deadlks', value => $self->{option_results}->{critical_deadlks})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical-deadlks threshold '" . $self->{option_results}->{critical_deadlks} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning-lockwts', value => $self->{option_results}->{warning_lockwts})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning-lockwts threshold '" . $self->{option_results}->{warning_lockwts} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-lockwts', value => $self->{option_results}->{critical_lockwts})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical-lockwts threshold '" . $self->{option_results}->{critical_lockwts} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning-lockreqs', value => $self->{option_results}->{warning_lockreqs})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning-lockreqs threshold '" . $self->{option_results}->{warning_lockreqs} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-lockreqs', value => $self->{option_results}->{critical_lockreqs})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical-lockreqs threshold '" . $self->{option_results}->{critical_lockreqs} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning-lktouts', value => $self->{option_results}->{warning_block})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning-lktouts threshold '" . $self->{option_results}->{warning_block} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-lktouts', value => $self->{option_results}->{critical_lktouts})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical-lktouts threshold '" . $self->{option_results}->{critical_lktouts} . "'.");
       $self->{output}->option_exit();
    }
    
    $self->{statefile_cache}->check_options(%options);
}

sub run {
    my ($self, %options) = @_;
    # $options{sql} = sqlmode object
    $self->{sql} = $options{sql};

    $self->{sql}->connect();

    my $query = q{
SELECT dbsname, tabname, deadlks, lockwts, lockreqs, lktouts FROM sysptprof
ORDER BY dbsname, tabname
};
    
    $self->{sql}->query(query => $query);

    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'All database/table locks are ok');
    
    my $new_datas = {};
    $self->{statefile_cache}->read(statefile => 'informix_' . $self->{mode} . '_' . $self->{sql}->get_unique_id4save());
    my $old_timestamp = $self->{statefile_cache}->get(name => 'last_timestamp');
    $new_datas->{last_timestamp} = time();
    
    my $count = 0;
    my $db_found = {};
    while ((my $row = $self->{sql}->fetchrow_hashref())) {
        my $dbname = centreon::plugins::misc::trim($row->{dbsname});
        my $tabname = centreon::plugins::misc::trim($row->{tabname});
        my $longname = $dbname . '.' . $tabname;
        next if (defined($self->{option_results}->{name}) && !defined($self->{option_results}->{use_regexp}) && $dbname ne $self->{option_results}->{name});
        next if (defined($self->{option_results}->{name}) && defined($self->{option_results}->{use_regexp}) && $dbname !~ /$self->{option_results}->{name}/);
        next if (defined($self->{option_results}->{filter_tables}) && $longname !~ /$self->{option_results}->{filter_tables}/);
        
        $count++;
        my $old_datas = {};
        my $get_old_value = 0;
        $db_found->{$dbname} = {deadlks => 0, lockwts => 0, lockreqs => 0, lktouts => 0, process => 0} if (!defined($db_found->{$dbname}));
        foreach (('deadlks', 'lockwts', 'lockreqs', 'lktouts')) {
            $new_datas->{$dbname . '_' . $_} = 0 if (!defined($new_datas->{$dbname . '_' . $_}));
            $new_datas->{$dbname . '_' . $_} += $row->{$_};
            $new_datas->{$longname . '_' . $_} = $row->{$_};
            $old_datas->{$longname . '_' . $_} = $self->{statefile_cache}->get(name => $longname . '_' . $_);
            # Restart or onstat -z - we set to 0
            $old_datas->{$longname . '_' . $_} = 0 if (defined($old_datas->{$longname . '_' . $_}) && $old_datas->{$longname . '_' . $_} > $new_datas->{$longname . '_' . $_});
            # If we have a buffer or not
            if (defined($old_datas->{$longname . '_' . $_})) {
                $get_old_value = 1;
                $db_found->{$dbname}->{$_} += $old_datas->{$longname . '_' . $_};
            }
        }
        
        # Buffer needed
        next if ($get_old_value == 0 || !defined($old_timestamp));
        
        $db_found->{$dbname}->{process} = 1;
        
        next if ($self->{option_results}->{only_databases});
        
        my $diff = {};
        foreach (('deadlks', 'lockwts', 'lockreqs', 'lktouts')) {
            $diff->{$_} = $new_datas->{$longname . '_' . $_} - $old_datas->{$longname . '_' . $_};
        }
        
        my $exit1 = $self->{perfdata}->threshold_check(value => $diff->{deadlks}, threshold => [ { label => 'critical-deadlks', 'exit_litteral' => 'critical' }, { label => 'warning-deadlks', exit_litteral => 'warning' } ]);
        my $exit2 = $self->{perfdata}->threshold_check(value => $diff->{lockwts}, threshold => [ { label => 'critical-lockwts', 'exit_litteral' => 'critical' }, { label => 'warning-lockwts', exit_litteral => 'warning' } ]);
        my $exit3 = $self->{perfdata}->threshold_check(value => $diff->{lockreqs}, threshold => [ { label => 'critical-lockreqs', 'exit_litteral' => 'critical' }, { label => 'warning-lockreqs', exit_litteral => 'warning' } ]);
        my $exit4 = $self->{perfdata}->threshold_check(value => $diff->{lktouts}, threshold => [ { label => 'critical-lktouts', 'exit_litteral' => 'critical' }, { label => 'warning-lktouts', exit_litteral => 'warning' } ]);
        my $exit = $self->{output}->get_most_critical(status => [ $exit1, $exit2, $exit3, $exit4 ]);
        
        
        $self->{output}->output_add(long_msg => sprintf("Table '%s': Deadlocks %d, Lock Waits %d, Lock Requests %d, Lock Timeouts %d",
                                                         $longname, $diff->{deadlks}, $diff->{lockwts}, $diff->{lockreqs}, $diff->{lktouts}));        
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Table '%s': Deadlocks %d, Lock Waits %d, Lock Requests %d, Lock Timeouts %d",
                                                             $longname, $diff->{deadlks}, $diff->{lockwts}, $diff->{lockreqs}, $diff->{lktouts}));
        }
        
        foreach (('deadlks', 'lockwts', 'lockreqs', 'lktouts')) {
            $self->{output}->perfdata_add(label => 'tbl_' . $_ . '_' . $longname,
                                          value => $diff->{$_},
                                          warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $_),
                                          critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $_),
                                          min => 0);
        }
    }

    foreach my $dbname (keys %{$db_found}) {
        next if ($db_found->{$dbname}->{process} == 0);
        
        my $exit1 = $self->{perfdata}->threshold_check(value => $new_datas->{$dbname . '_deadlks'} - $db_found->{$dbname}->{deadlks}, threshold => [ { label => 'critical-deadlks', 'exit_litteral' => 'critical' }, { label => 'warning-deadlks', exit_litteral => 'warning' } ]);
        my $exit2 = $self->{perfdata}->threshold_check(value => $new_datas->{$dbname . '_lockwts'} - $db_found->{$dbname}->{lockwts}, threshold => [ { label => 'critical-lockwts', 'exit_litteral' => 'critical' }, { label => 'warning-lockwts', exit_litteral => 'warning' } ]);
        my $exit3 = $self->{perfdata}->threshold_check(value => $new_datas->{$dbname . '_lockreqs'} - $db_found->{$dbname}->{lockreqs}, threshold => [ { label => 'critical-lockreqs', 'exit_litteral' => 'critical' }, { label => 'warning-lockreqs', exit_litteral => 'warning' } ]);
        my $exit4 = $self->{perfdata}->threshold_check(value => $new_datas->{$dbname . '_lktouts'} - $db_found->{$dbname}->{lktouts}, threshold => [ { label => 'critical-lktouts', 'exit_litteral' => 'critical' }, { label => 'warning-lktouts', exit_litteral => 'warning' } ]);
        my $exit = $self->{output}->get_most_critical(status => [ $exit1, $exit2, $exit3, $exit4 ]);
        
        $self->{output}->output_add(long_msg => sprintf("Database '%s': Deadlocks %d, Lock Waits %d, Lock Requests %d, lock timeouts %d",
                                                         $dbname, 
                                                         $new_datas->{$dbname . '_deadlks'} - $db_found->{$dbname}->{deadlks}, 
                                                         $new_datas->{$dbname . '_lockwts'} - $db_found->{$dbname}->{lockwts}, 
                                                         $new_datas->{$dbname . '_lockreqs'} - $db_found->{$dbname}->{lockreqs}, 
                                                         $new_datas->{$dbname . '_lktouts'} - $db_found->{$dbname}->{lktouts}));
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Database '%s': Deadlocks %d, Lock Waits %d, Lock Requests %d, lock timeouts %d",
                                                             $dbname, 
                                                             $new_datas->{$dbname . '_deadlks'} - $db_found->{$dbname}->{deadlks}, 
                                                             $new_datas->{$dbname . '_lockwts'} - $db_found->{$dbname}->{lockwts}, 
                                                             $new_datas->{$dbname . '_lockreqs'} - $db_found->{$dbname}->{lockreqs}, 
                                                             $new_datas->{$dbname . '_lktouts'} - $db_found->{$dbname}->{lktouts}));
        }
        foreach (('deadlks', 'lockwts', 'lockreqs', 'lktouts')) {
            $self->{output}->perfdata_add(label => 'db_' . $_ . '_' . $dbname,
                                          value => $new_datas->{$dbname . '_' . $_} - $db_found->{$dbname}->{$_},
                                          warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $_),
                                          critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $_),
                                          min => 0);
        }
    }
    
    if ($count == 0) {
        $self->{output}->output_add(severity => 'UNKNOWN',
                                    short_msg => "Cannot find a table (maybe filters).");
    }

    $self->{statefile_cache}->write(data => $new_datas); 
    if (!defined($old_timestamp)) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => "Buffer creation...");
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check table locks:
- deadlks: deadlocks.
- lockwts: lock waits.
- lockreqs: lock requests.
- lktouts: lock timeouts.

=over 8

=item B<--warning-deadlks>

Threshold warning 'deadlks' in absolute.

=item B<--critical-deadlks>

Threshold critical 'deadlks' in absolute.

=item B<--warning-lockwts>

Threshold warning 'lockwts' in absolute.

=item B<--critical-lockwts>

Threshold critical 'lockwts' in absolute.

=item B<--warning-lockreqs>

Threshold warning 'lockreqs' in absolute.

=item B<--critical-lockreqs>

Threshold critical 'lockreqs' in absolute.

=item B<--warning-lktouts>

Threshold warning 'lktouts' in absolute.

=item B<--critical-lktouts>

Threshold critical 'lktouts' in absolute.

=item B<--name>

Set the database (empty means 'check all databases').

=item B<--regexp>

Allows to use regexp to filter database (with option --name).

=item B<--filter-tables>

Filter tables (format of a table name: 'sysmater.dual').

=item B<--only-databases>

only check locks globally on database (no output for tables).

=back

=cut
