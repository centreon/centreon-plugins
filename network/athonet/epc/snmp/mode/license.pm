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

package network::athonet::epc::snmp::mode::license;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use DateTime;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf('status is %s', $self->{result_values}->{status});
}

sub custom_license_users_output {
    my ($self, %options) = @_;

    return sprintf(
        'active users total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $self->{result_values}->{users_total},
        $self->{result_values}->{users_used},
        $self->{result_values}->{users_prct_used},
        $self->{result_values}->{users_free},
        $self->{result_values}->{users_prct_free}
    );
}

sub custom_license_sessions_output {
    my ($self, %options) = @_;

    return sprintf(
        'active sessions total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $self->{result_values}->{sessions_total},
        $self->{result_values}->{sessions_used},
        $self->{result_values}->{sessions_prct_used},
        $self->{result_values}->{sessions_free},
        $self->{result_values}->{sessions_prct_free}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'License ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' }
    ];

    $self->{maps_counters}->{global} = [
        { 
            label => 'status',
            type => 2,
            critical_default => '%{status} =~ /expired|invalid/i',
            set => {
                key_values => [ { name => 'status' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'expires-seconds', nlabel => 'license.expires.seconds', set => {
                key_values      => [ { name => 'expires_seconds' }, { name => 'expires_human' } ],
                output_template => 'expires in %s',
                output_use => 'expires_human',
                perfdatas => [
                    { template => '%d', min => 0, unit => 's' }
                ]
            }
        },
        { label => 'license-users-usage', nlabel => 'license.users.active.usage.count', set => {
                key_values => [ { name => 'users_used' }, { name => 'users_free' }, { name => 'users_prct_used' }, { name => 'users_prct_free' }, { name => 'users_total' } ],
                closure_custom_output => $self->can('custom_license_users_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'users_total' }
                ]
            }
        },
        { label => 'license-users-free', display_ok => 0, nlabel => 'license.users.active.free.count', set => {
                key_values => [ { name => 'users_free' }, { name => 'users_used' }, { name => 'users_prct_used' }, { name => 'users_prct_free' }, { name => 'users_total' } ],
                closure_custom_output => $self->can('custom_license_users_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'users_total' }
                ]
            }
        },
        { label => 'license-users-usage-prct', display_ok => 0, nlabel => 'license.users.active.usage.percentage', set => {
                key_values => [ { name => 'users_prct_used' }, { name => 'users_free' }, { name => 'users_used' }, { name => 'users_prct_free' }, { name => 'users_total' } ],
                closure_custom_output => $self->can('custom_license_users_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        { label => 'license-sessions-usage', nlabel => 'license.sessions.active.usage.count', set => {
                key_values => [ { name => 'sessions_used' }, { name => 'sessions_free' }, { name => 'sessions_prct_used' }, { name => 'sessions_prct_free' }, { name => 'sessions_total' } ],
                closure_custom_output => $self->can('custom_license_sessions_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'sessions_total' }
                ]
            }
        },
        { label => 'license-sessions-free', display_ok => 0, nlabel => 'license.sessions.active.free.count', set => {
                key_values => [ { name => 'sessions_free' }, { name => 'sessions_used' }, { name => 'sessions_prct_used' }, { name => 'sessions_prct_free' }, { name => 'sessions_total' } ],
                closure_custom_output => $self->can('custom_license_sessions_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'sessions_total' }
                ]
            }
        },
        { label => 'license-sessions-usage-prct', display_ok => 0, nlabel => 'license.sessions.active.usage.percentage', set => {
                key_values => [ { name => 'sessions_prct_used' }, { name => 'sessions_used' }, { name => 'sessions_free' }, { name => 'sessions_prct_free' }, { name => 'sessions_total' } ],
                closure_custom_output => $self->can('custom_license_sessions_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

my $map_status = { 0 => 'ok', 1 => 'expired', 2 => 'invalid' };

my $mapping = {
    users_connected     => { oid => '.1.3.6.1.4.1.35805.10.2.99.1' }, # usersConnected
    active_connections  => { oid => '.1.3.6.1.4.1.35805.10.2.99.4' }, # activeConnections
    max_active_users    => { oid => '.1.3.6.1.4.1.35805.10.4.1' }, # maxActiveUsers
    max_active_sessions => { oid => '.1.3.6.1.4.1.35805.10.4.2' }, # maxActiveSessions
    expire_time         => { oid => '.1.3.6.1.4.1.35805.10.4.4' }, # licenseExpireTime
    status              => { oid => '.1.3.6.1.4.1.35805.10.4.5', map => $map_status } # licenseStatus
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_leef(
        oids => [ map($_->{oid} . '.0', values(%$mapping)) ],
        nothing_quit => 1
    );
    $self->{global} = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => 0);

    #2035-3-30,7:43:58.0,+0:0
    if ($self->{global}->{expire_time} =~ /^\s*(\d+)-(\d+)-(\d+),(\d+):(\d+):(\d+)\.(\d+),(.*)/) {
        my $dt = DateTime->new(
            year      => $1,
            month     => $2,
            day       => $3,
            hour      => $4,
            minute    => $5,
            second    => $6,
            time_zone => $7
        );
        $self->{global}->{expires_seconds} = $dt->epoch() - time();
        $self->{global}->{expires_human} = centreon::plugins::misc::change_seconds(value => $self->{global}->{expires_seconds});
    }

    $self->{global}->{users_used} = $self->{global}->{users_connected};
    $self->{global}->{users_total} = $self->{global}->{max_active_users};
    $self->{global}->{users_free} = $self->{global}->{users_total} - $self->{global}->{users_used};
    $self->{global}->{users_prct_used} = $self->{global}->{users_used} * 100 / $self->{global}->{users_total};
    $self->{global}->{users_prct_free} = 100 - $self->{global}->{users_prct_used};

    $self->{global}->{sessions_used} = $self->{global}->{active_connections};
    $self->{global}->{sessions_total} = $self->{global}->{max_active_sessions};
    $self->{global}->{sessions_free} = $self->{global}->{sessions_total} - $self->{global}->{sessions_used};
    $self->{global}->{sessions_prct_used} = $self->{global}->{sessions_used} * 100 / $self->{global}->{sessions_total};
    $self->{global}->{sessions_prct_free} = 100 - $self->{global}->{sessions_prct_used};
}

1;

__END__

=head1 MODE

Check license.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='users'

=item B<--warning-status>

Set warning threshold for status.
Can use special variables like: %{status}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /expired|invalid/i').
Can use special variables like: %{status}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'expires-seconds', 'license-users-usage', 'license-users-free', 'license-users-usage-prct',
'license-sessions-usage', 'license-sessions-free', 'license-sessions-usage-prct'.

=back

=cut
