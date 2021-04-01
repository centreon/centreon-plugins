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

package network::fortinet::fortiauthenticator::snmp::mode::authenticator;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub custom_remaining_output {
    my ($self, %options) = @_;

    return sprintf(
        'total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $self->{result_values}->{total},
        $self->{result_values}->{used}, 
        $self->{result_values}->{prct_used},
        $self->{result_values}->{free},
        $self->{result_values}->{prct_free}
    );
}

sub auth_long_output {
    my ($self, %options) = @_;

    return 'checking authenticator';
}

sub prefix_auth_output {
    my ($self, %options) = @_;

    return 'Authenticator ';
}

sub prefix_users_output {
    my ($self, %options) = @_;

    return 'users ';
}

sub prefix_groups_output {
    my ($self, %options) = @_;

    return 'groups ';
}

sub prefix_radius_nas_output {
    my ($self, %options) = @_;

    return 'radius nas ';
}

sub prefix_authentication_output {
    my ($self, %options) = @_;

    return 'authentication ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'auth', type => 3, cb_prefix_output => 'prefix_auth_output', cb_long_output => 'auth_long_output', indent_long_output => '    ',
            group => [
                { name => 'users', type => 0, display_short => 0, cb_prefix_output => 'prefix_users_output', skipped_code => { -10 => 1 } },
                { name => 'groups', type => 0, display_short => 0, cb_prefix_output => 'prefix_groups_output', skipped_code => { -10 => 1 } },
                { name => 'radius_nas', type => 0, display_short => 0, cb_prefix_output => 'prefix_radius_nas_output', skipped_code => { -10 => 1 } },
                { name => 'authentication', type => 0, display_short => 0, cb_prefix_output => 'prefix_authentication_output', skipped_code => { -10 => 1 } },
            ]
        }
    ];

    $self->{maps_counters}->{users} = [
        { label => 'users-usage', nlabel => 'authenticator.users.count', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_remaining_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', cast_int => 1 }
                ]
            }
        },
        { label => 'users-usage-prct', nlabel => 'authenticator.users.percentage', display_ok => 0, set => {
                key_values => [ { name => 'prct_used' }, { name => 'free' }, { name => 'used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_remaining_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{groups} = [
        { label => 'groups-usage', nlabel => 'authenticator.groups.count', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_remaining_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', cast_int => 1 }
                ]
            }
        },
        { label => 'groups-usage-prct', nlabel => 'authenticator.groups.percentage', display_ok => 0, set => {
                key_values => [ { name => 'prct_used' }, { name => 'free' }, { name => 'used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_remaining_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{radius_nas} = [
        { label => 'radius-nas-usage', nlabel => 'authenticator.radius.nas.count', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_remaining_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', cast_int => 1 }
                ]
            }
        },
        { label => 'radius-nas-usage-prct', nlabel => 'authenticator.radius.nas.percentage', display_ok => 0, set => {
                key_values => [ { name => 'prct_used' }, { name => 'free' }, { name => 'used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_remaining_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{authentication} = [
        { label => 'authentication-events', nlabel => 'authenticator.authentication.events.persecond', set => {
                key_values => [ { name => 'events_total', per_second => 1 } ],
                output_template => 'events: %d/s',
                perfdatas => [
                    { template => '%d', min => 0, unit => '/s', cast_int => 1 }
                ]
            }
        },
        { label => 'authentication-failures', nlabel => 'authenticator.authentication.failures.persecond', set => {
                key_values => [ { name => 'failures_total', per_second => 1 } ],
                output_template => 'failures: %d/s',
                perfdatas => [
                    { template => '%d', min => 0, unit => '/s', cast_int => 1 }
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
    });

    return $self;
}

my $mapping = {
    users                => { oid => '.1.3.6.1.4.1.12356.113.1.202.1' }, # facAuthUserCount
    groups               => { oid => '.1.3.6.1.4.1.12356.113.1.202.2' }, # facAuthUserCount
    users_remaining      => { oid => '.1.3.6.1.4.1.12356.113.1.202.4' }, # facAuthUsersRemaining
    groups_remaining     => { oid => '.1.3.6.1.4.1.12356.113.1.202.5' }, # facAuthGroupRemaining
    radius_nas           => { oid => '.1.3.6.1.4.1.12356.113.1.202.7' }, # facRadiusNasCount
    radius_nas_remaining => { oid => '.1.3.6.1.4.1.12356.113.1.202.8' }, # facRadiusNasRemaining
    events_total         => { oid => '.1.3.6.1.4.1.12356.113.1.202.20' }, # facAuthEventsTotal
    failures_total       => { oid => '.1.3.6.1.4.1.12356.113.1.202.22' }  # facAuthFailuresTotal
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_leef(oids => [ map($_->{oid} . '.0', values(%$mapping)) ], nothing_quit => 1);
    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => 0);

    $self->{output}->output_add(short_msg => 'Authenticator statistics are ok');

    $self->{auth} = {
        global => {
            users => {
                used => $result->{users},
                free => $result->{users_remaining},
                total => $result->{users} + $result->{users_remaining},
                prct_used => $result->{users}  * 100 / ($result->{users} + $result->{users_remaining}),
                prct_free => 100 - ($result->{users} * 100 / ($result->{users} + $result->{users_remaining}))
            },
            groups => {
                used => $result->{groups},
                free => $result->{groups_remaining},
                total => $result->{groups} + $result->{groups_remaining},
                prct_used => $result->{groups} * 100 / ($result->{groups} + $result->{groups_remaining}),
                prct_free => 100 - ($result->{groups} * 100 / ($result->{groups} + $result->{groups_remaining}))
            },
            radius_nas => {
                used => $result->{radius_nas},
                free => $result->{radius_nas_remaining},
                total => $result->{radius_nas} + $result->{radius_nas_remaining},
                prct_used => $result->{radius_nas} * 100 / ($result->{radius_nas} + $result->{radius_nas_remaining}),
                prct_free => 100 - ($result->{radius_nas} * 100 / ($result->{radius_nas} + $result->{radius_nas_remaining}))
            },
            authentication => {
                events_total => $result->{events_total},
                failures_total => $result->{failures_total}
            }
        }
    };

    $self->{cache_name} = 'fortinet_fortiauthenticator_' . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check authenticator statistics.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'radius-nas-usage', 'radius-nas-usage-prct', 
'groups-usage', 'groups-usage-prct', 'users-usage', 'users-usage-prct',
'authentication-events', 'authentication-failures'.

=back

=cut
