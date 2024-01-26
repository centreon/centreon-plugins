#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package database::oracle::mode::dataguard;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "dataguard role '%s' [open mode: '%s'] - managed recovery process %s status is %s [log transport: %s]",
        $self->{result_values}->{role},
        $self->{result_values}->{open_mode},
        $self->{result_values}->{mrp_process},
        $self->{result_values}->{mrp_status},
        $self->{result_values}->{log_transport}
    );
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{roleLast} = $options{old_datas}->{$self->{instance} . '_role'};
    $self->{result_values}->{role} = $options{new_datas}->{$self->{instance} . '_role'};
    $self->{result_values}->{open_mode} = $options{new_datas}->{$self->{instance} . '_open_mode'};
    $self->{result_values}->{mrp_status} = $options{new_datas}->{$self->{instance} . '_mrp_status'};
    $self->{result_values}->{mrp_process} = $options{new_datas}->{$self->{instance} . '_mrp_process'};
    $self->{result_values}->{log_transport} = $options{new_datas}->{$self->{instance} . '_log_transport'};
    if (!defined($options{old_datas}->{$self->{instance} . '_role'})) {
        $self->{error_msg} = "buffer creation";
        return -2;
    }

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'status', threshold => 0, set => {
                key_values => [
                    { name => 'role' }, { name => 'open_mode' },
                    { name => 'mrp_status' }, { name => 'mrp_process' },
                    { name => 'log_transport' }
                ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        },
        { label => 'standby-lag', nlabel => 'dataguard.standby.lag.minutes', set => {
                key_values => [ { name => 'lag_minutes' } ],
                output_template => 'dataguard standby lag %d minutes: %s',
                perfdatas => [
                    { template => '%s', min => 0, unit => 'm' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'unknown-status:s'  => { name => 'unknown_status', default => '%{mrp_status} =~ /undefined/ || %{log_transport} =~ /undefined/' },
        'warning-status:s'  => { name => 'warning_status', default => '%{mrp_status} =~ /WAIT_FOR_LOG/i and %{log_transport} =~ /LGWR/i' },
        'critical-status:s' => { name => 'critical_status', default => '%{roleLast} ne %{role} || %{mrp_status} !~ /undefined|APPLYING_LOG|WAIT_FOR_LOG/i' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(
        macros => [
            'unknown_status', 'warning_status', 'critical_status'
        ]
    );
}

sub manage_selection {
    my ($self, %options) = @_;

    $options{sql}->connect();
    $options{sql}->query(
        query => q{
            SELECT name, open_mode, database_role FROM v$database
        }
    );
    my @result = $options{sql}->fetchrow_array();
    $self->{global} = {
        role => $result[2],
        open_mode => $result[1]
    };

    $options{sql}->query(
        query => q{
            SELECT process, status FROM v$managed_standby WHERE process LIKE 'MR%'
        }
    );
    @result = $options{sql}->fetchrow_array();
    $self->{global}->{mrp_process} = defined($result[0]) && $result[0] ne '' ? $result[0] : 'undefined';
    $self->{global}->{mrp_status} = defined($result[1]) && $result[1] ne '' ? $result[1] : 'undefined';

    $options{sql}->query(
        query => q{
            SELECT DECODE(COUNT(*),0,'ARCH','LGWR') AS log_transport FROM v$managed_standby WHERE client_process = 'LGWR'
        }
    );
    @result = $options{sql}->fetchrow_array();
    $self->{global}->{log_transport} = defined($result[0]) && $result[0] ne '' ? $result[0] : 'undefined';

    $options{sql}->query(
        query => q{
            SELECT round(
                extract(DAY from cast(value AS INTERVAL DAY TO SECOND)) * 1440
                + extract(HOUR from cast(value AS INTERVAL DAY TO SECOND)) * 60
                + extract(MINUTE from cast(value AS INTERVAL DAY TO SECOND))
                + extract(SECOND from cast(value AS INTERVAL DAY TO SECOND)) / 60,
                0
            ) AS "Lag minutes"
            from v$dataguard_stats where NAME='apply lag'
        }
    );
    @result = $options{sql}->fetchrow_array();
    if (!defined($result[0]) || $result[0] eq '') {
        $options{sql}->query(
            query => q{
                SELECT 
                  CEIL((SYSDATE - MAX(first_time)) * 24 * 60)
                FROM
                  v$archived_log
                WHERE
                  applied NOT IN ('NO') AND registrar = 'RFS'
            }
        );
        @result = $options{sql}->fetchrow_array();
    }

    $self->{global}->{lag_minutes} = defined($result[0]) && $result[0] ne '' ? $result[0] : -1;

    $options{sql}->disconnect();

    $self->{cache_name} = 'oracle_' . $self->{mode} . '_' . $options{sql}->get_unique_id4save() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check oracle dataguard.

=over 8

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN (default: '%{mrp_status} =~ /undefined/ || %{log_transport} =~ /undefined/').
You can use the following variables: %{roleLast}, %{role}, %{open_mode}, %{mrp_status}, %{mrp_process}, %{log_transport}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '%{mrp_status} =~ /WAIT_FOR_LOG/i and %{log_transport} =~ /LGWR/i').
You can use the following variables: %{roleLast}, %{role}, %{open_mode}, %{mrp_status}, %{mrp_process}, %{log_transport}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{roleLast} ne %{role} || %{mrp_status} !~ /undefined|APPLYING_LOG|WAIT_FOR_LOG/i').
You can use the following variables: %{roleLast}, %{role}, %{open_mode}, %{mrp_status}, %{mrp_process}, %{log_transport}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'standby-lag'.

=back

=cut
