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

package database::mysql::mode::backup;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg;
    if ($self->{result_values}->{has_backup} eq 'no') {
        $msg = 'never executed';
    } else {
        $msg = sprintf(
            'exit state: %s [last_error: %s]', 
            $self->{result_values}->{exit_state},
            $self->{result_values}->{last_error}
        );
    }
    return $msg;
}

sub prefix_backup_output {
    my ($self, %options) = @_;

    return "Backup '" . $options{instance_value}->{type} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'backups', type => 1, cb_prefix_output => 'prefix_backup_output', message_multiple => 'All backup types are ok', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{backups} = [
        {
            label => 'status',
            type => 2,
            critical_default => '%{has_backup} eq "yes" and %{exit_state} ne "SUCCESS" and %{last_error} ne "NO_ERROR"',
            set => {
                key_values => [
                    { name => 'type' }, { name => 'exit_state' }, 
                    { name => 'last_error' }, { name => 'has_backup' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'time-last-execution', nlabel => 'backup.time.last.execution.seconds', set => {
                key_values => [ { name => 'last_execution_time' }, { name => 'last_execution_human' } ],
                output_template => 'last execution time: %s',
                output_use => 'last_execution_human',
                perfdatas => [
                    { template => '%d', min => 0, unit => 's', label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-type:s' => { name => 'filter_type' }
    });
 
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $options{sql}->connect();
    my $query = q{
        SELECT
            backup_type, 
            exit_state,
            last_error,
            UNIX_TIMESTAMP(start_time)
        FROM mysql.backup_history
        WHERE
            backup_id IN (
                SELECT MAX(backup_id)
                FROM mysql.backup_history
                GROUP BY backup_type
            )
    };
    $options{sql}->query(query => $query);
    my $result = $options{sql}->fetchall_arrayref();

    $self->{backups} = {
        FULL => { type => 'FULL', has_backup => 'no' , exit_state => '-', last_error => '-' },
        PARTIAL => { type => 'PARTIAL', has_backup => 'no' , exit_state => '-', last_error => '-' },
        DIFFERENTIAL => { type => 'DIFFERENTIAL', has_backup => 'no' , exit_state => '-', last_error => '-' },
        INCREMENTAL => { type => 'INCREMENTAL', has_backup => 'no' , exit_state => '-', last_error => '-' },
        TTS => { type => 'TTS', has_backup => 'no', exit_state => '-', last_error => '-' }
    };
    foreach my $row (@$result) {
        my ($name, $state, $type, $total_mb, $usable_file_mb, $offline_disks, $free_mb) = @$row;
        
        if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
            $row->[0] !~ /$self->{option_results}->{filter_type}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $row->[0] . "': no matching filter name.", debug => 1);
            next;
        }

        $self->{backups}->{ $row->[0] }->{has_backup} = 'yes';
        $self->{backups}->{ $row->[0] }->{exit_state} = $row->[1];
        $self->{backups}->{ $row->[0] }->{last_error} = $row->[2];
        $self->{backups}->{ $row->[0] }->{last_execution_time} = time() - $row->[3];
        $self->{backups}->{ $row->[0] }->{last_execution_human} = centreon::plugins::misc::change_seconds(
            value => $self->{backups}->{ $row->[0] }->{last_execution_time}
        );
    }
}

1;

__END__

=head1 MODE

Check backups (only with mysql enterprise backup).

=over 8

=item B<--filter-type>

Filter backups by type (regexp can be used).

=item B<--unknown-status>

Set unknown threshold for status.
Can used special variables like: %{has_backup}, %{last_error}, %{exit_state}, %{type}

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{has_backup}, %{last_error}, %{exit_state}, %{type}

=item B<--critical-status>

Set critical threshold for status (Default: '%{has_backup} eq "yes" and %{exit_state} ne "SUCCESS" and %{last_error} ne "NO_ERROR"').
Can used special variables like: %{has_backup}, %{last_error}, %{exit_state}, %{type}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'time-last-execution'.

=back

=cut
