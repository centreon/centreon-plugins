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

package network::huawei::wlc::snmp::mode::wlanglobal;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_normal_output {
    my ($self, %options) = @_;

    return sprintf(
        'Access Points normal state %s on %s (%.2f%%)',
        $self->{result_values}->{normal},
        $self->{result_values}->{total},
        $self->{result_values}->{normal_prct},
    );
}

sub custom_success_auth_user_output {
    my ($self, %options) = @_;

    return sprintf(
        'Access Points user authentications %s on %s (%.2f%%)',
        $self->{result_values}->{current_auth_user},
        $self->{result_values}->{current_user},
        $self->{result_values}->{current_auth_user_prct},
    );
}

sub custom_current_auth_user_prct_output {
    my ($self, %options) = @_;

    return sprintf(
        'Access Points user authentications %.2f%% (%s on %s)',
        $self->{result_values}->{current_auth_user_prct},
        $self->{result_values}->{current_auth_user},
        $self->{result_values}->{current_user},
    );
}

sub custom_normal_prct_output {
    my ($self, %options) = @_;

    return sprintf(
        'Access Points normal state %.2f%% (%s on %s)',
        $self->{result_values}->{normal_prct},
        $self->{result_values}->{normal},
        $self->{result_values}->{total},
    );
}

sub custom_fault_prct_output {
    my ($self, %options) = @_;

    return sprintf(
        'Access Points fault state %.2f%% (%s on %s)',
        $self->{result_values}->{fault_prct},
        $self->{result_values}->{fault},
        $self->{result_values}->{total},
    );
}

sub custom_fault_output {
    my ($self, %options) = @_;

    return sprintf(
        'Access Points fault state %s on %s (%.2f%%)',
        $self->{result_values}->{fault},
        $self->{result_values}->{total},
        $self->{result_values}->{fault_prct}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total', nlabel => 'accesspoints.total.count', display_ok => 0, set => {
            key_values      => [ { name => 'total' } ],
            output_template => 'total: %s',
            perfdatas       => [
                { template => '%s', min => 0 }
            ]
        }
        },
        { label => 'normal', nlabel => 'accesspoints.normal.count', display_ok => 1, set => {
            key_values            => [ { name => 'normal' }, { name => 'total' }, { name => 'normal_prct' } ],
            closure_custom_output => $self->can('custom_normal_output'),
            perfdatas             => [
                { template => '%s', min => 0 }
            ]
        }
        },
        { label => 'fault', nlabel => 'accesspoints.fault.count', display_ok => 0, set => {
            key_values            => [ { name => 'fault' }, { name => 'total' }, { name => 'fault_prct' } ],
            closure_custom_output => $self->can('custom_fault_output'),
            perfdatas             => [
                { template => '%s', min => 0 }
            ]
        }
        },
        { label => 'normal-prct', nlabel => 'accesspoints.normal.percentage', display_ok => 0, set => {
            key_values            => [ { name => 'normal_prct' }, { name => 'total' }, { name => 'normal' } ],
            closure_custom_output => $self->can('custom_normal_output_prct'),
            perfdatas             => [
                { template => '%.2f', unit => '%', min => 0, max => 100 }
            ]
        }
        },
        { label => 'fault-prct', nlabel => 'accesspoints.fault.percentage', display_ok => 0, set => {
            key_values            => [ { name => 'fault_prct' }, { name => 'total' }, { name => 'fault' } ],
            closure_custom_output => $self->can('custom_fault_output_prct'),
            perfdatas             => [
                { template => '%.2f', unit => '%', min => 0, max => 100 }
            ]
        }
        },
        { label => 'current-user', nlabel => 'accesspoints.user.count', display_ok => 0, set => {
            key_values      => [ { name => 'current_user' } ],
            output_template => 'current user: %s',
            perfdatas       => [
                { template => '%s', min => 0 }
            ]
        }
        },
        { label => 'current-auth-user', nlabel => 'accesspoints.user.auth.count', display_ok => 0, set => {
            key_values            => [ { name => 'current_auth_user' }, { name => 'current_auth_user_prct' }, { name => 'current_user' } ],
            closure_custom_output => $self->can('custom_success_auth_user_output'),
            perfdatas             => [
                { template => '%s', min => 0 }
            ]
        }
        },
        { label => 'current-auth-user-prct', nlabel => 'accesspoints.user.auth.percentage', display_ok => 1, set => {
            key_values            => [ { name => 'current_auth_user_prct' }, { name => 'current_auth_user' }, { name => 'current_user' }  ],
            closure_custom_output => $self->can('custom_current_auth_user_prct_output'),
            perfdatas             => [
                { template => '%.2f', unit => '%', min => 0, max => 100 }
            ]
        }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

my $oid_normal = '.1.3.6.1.4.1.2011.6.139.12.1.5.6.0';# hwWlanServiceNormalAPCount
my $oid_total = '.1.3.6.1.4.1.2011.6.139.12.1.5.7.0';# hwWlanApCount
my $oid_cur_user = '.1.3.6.1.4.1.2011.6.139.12.1.2.2.0';# hwWlanCurAssocStaNum
my $oid_cur_auth_user = '.1.3.6.1.4.1.2011.6.139.12.1.2.3.0';# hwWlanCurAuthSuccessStaNum

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = {
        total             => 0,
        normal            => 0,
        normal_prct       => 0,
        fault             => 0,
        fault_prct        => 0,
        current_user      => 0,
        current_auth_user => 0
    };

    my $snmp_result = $options{snmp}->get_leef(
        oids         => [ $oid_normal, $oid_total, $oid_cur_user, $oid_cur_auth_user ],
        nothing_quit => 0
    );

    $self->{global} = {
        total             => $snmp_result->{$oid_total},
        normal            => $snmp_result->{$oid_normal},
        current_user      => $snmp_result->{$oid_cur_user},
        current_auth_user => $snmp_result->{$oid_cur_auth_user}
    };

    $self->{global}->{fault} = $self->{global}->{total} > 0 && $self->{global}->{normal} > 0 ?
        $self->{global}->{total} - $self->{global}->{normal} : 0;

    $self->{global}->{normal_prct} = $self->{global}->{total} > 0 ?
        $self->{global}->{normal} * 100 / $self->{global}->{total} : 0;

    $self->{global}->{fault_prct} = $self->{global}->{total} > 0 ?
        $self->{global}->{fault} * 100 / $self->{global}->{total} : 0;

    $self->{global}->{current_auth_user_prct} = $self->{global}->{current_user} > 0 ?
        $self->{global}->{current_auth_user} * 100 / $self->{global}->{current_user} : 0;
}

1;

__END__

=head1 MODE

Check global WLAN access point count and user associated and authenticated.

=over 8

=item B<--warning-total>

Thresholds.

=item B<--critical-total>

Thresholds.

=item B<--warning-normal>

Thresholds.

=item B<--critical-normal>

Thresholds.

=item B<--warning-normal-prct>

Thresholds.

=item B<--critical-normal-prct>

Thresholds.

=item B<--warning-fault>

Thresholds.

=item B<--critical-fault>

Thresholds.

=item B<--warning-fault-prct>

Thresholds.

=item B<--critical-fault-prct>

Thresholds.

=item B<--warning-current-user>

Thresholds.

=item B<--critical-current-user>

Thresholds.

=item B<--warning-current-auth-user>

Thresholds.

=item B<--critical-current-auth-user>

Thresholds.

=item B<--warning-current-auth-user-prct>

Thresholds.

=item B<--critical-current-auth-user-prct>

Thresholds.

=back

=cut
