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

package network::juniper::common::ive::mode::users;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_node_output {
    my ($self, %options) = @_;

    if ($self->{result_values}->{node_total} ne '') {
        return sprintf(
            'concurrent users licenses usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
            $self->{result_values}->{node_total},
            $self->{result_values}->{node_used},
            $self->{result_values}->{node_used} * 100 / $self->{result_values}->{node_total},
            $self->{result_values}->{node_total} - $self->{result_values}->{node_used},
            ($self->{result_values}->{node_total} - $self->{result_values}->{node_used}) * 100 / $self->{result_values}->{node_total}
        );
    } else {
        return sprintf(
            'concurrent users licenses used: %s',
            $self->{result_values}->{node_used}
        );
    }
}

sub custom_cluster_output {
    my ($self, %options) = @_;

    if ($self->{result_values}->{cluster_total} ne '') {
        return sprintf(
            'concurrent cluster users licenses usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
            $self->{result_values}->{cluster_total},
            $self->{result_values}->{cluster_used},
            $self->{result_values}->{cluster_used} * 100 / $self->{result_values}->{cluster_total},
            $self->{result_values}->{cluster_total} - $self->{result_values}->{cluster_used},
            ($self->{result_values}->{cluster_total} - $self->{result_values}->{cluster_used}) * 100 / $self->{result_values}->{cluster_total}
        );
    } else {
        return sprintf(
            'concurrent cluster users licenses used: %s',
            $self->{result_values}->{cluster_used}
        );
    }
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ', skipped_code => { -10 => 1 }  },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'node-users-usage', nlabel => 'node.users.usage.count', set => {
                key_values => [ { name => 'node_used' }, { name => 'node_total' } ],
                closure_custom_output => $self->can('custom_node_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'node_total' }
                ]
            }
        },
        { label => 'node-users-free', nlabel => 'node.users.free.count', display_ok => 0, set => {
                key_values => [ { name => 'node_free' }, { name => 'node_used' }, { name => 'node_total' } ],
                closure_custom_output => $self->can('custom_node_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'node_total' }
                ]
            }
        },
        { label => 'node-users-usage-prct', nlabel => 'node.users.usage.percentage', display_ok => 0, set => {
                key_values => [ { name => 'node_prct_used' }, { name => 'node_free' }, { name => 'node_used' }, { name => 'node_total' } ],
                closure_custom_output => $self->can('custom_node_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        { label => 'cluster-users-usage', nlabel => 'cluster.users.usage.count', set => {
                key_values => [ { name => 'cluster_used' }, { name => 'cluster_total' }  ],
                closure_custom_output => $self->can('custom_cluster_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'cluster_total' }
                ]
            }
        },
        { label => 'cluster-users-free', nlabel => 'cluster.users.free.count', display_ok => 0, set => {
                key_values => [ { name => 'cluster_free' }, { name => 'cluster_used' }, { name => 'cluster_total' } ],
                closure_custom_output => $self->can('custom_cluster_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'cluster_total' }
                ]
            }
        },
        { label => 'cluster-users-usage-prct', nlabel => 'cluster.users.usage.percentage', display_ok => 0, set => {
                key_values => [ { name => 'cluster_prct_used' }, { name => 'cluster_free' }, { name => 'cluster_used' }, { name => 'cluster_total' } ],
                closure_custom_output => $self->can('custom_cluster_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        { label => 'web-users-signedin-usage', nlabel => 'web.users.signedin.usage.count', set => {
                key_values => [ { name => 'web' } ],
                output_template => 'current concurrent signed-in web users connections: %s',
                perfdatas => [
                    { value => 'web', template => '%s', min => 0 }
                ]
            }
        },
        { label => 'meeting-users-usage', nlabel => 'meeting.users.usage.count', set => {
                key_values => [ { name => 'meeting' } ],
                output_template => 'current concurrent meeting users connections: %s',
                perfdatas => [
                    { value => 'meeting', template => '%s', min => 0 }
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
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_signedInWebUsers = '.1.3.6.1.4.1.12532.2.0';
    my $oid_meetingUserCount = '.1.3.6.1.4.1.12532.9.0';
    my $oid_iveConcurrentUsers = '.1.3.6.1.4.1.12532.12.0';
    my $oid_clusterConcurrentUsers = '.1.3.6.1.4.1.12532.13.0';
    my $oid_iveMaxConcurrentUsersLicenseCapacity = '.1.3.6.1.4.1.12532.55.0';
    my $result = $options{snmp}->get_leef(
        oids => [
            $oid_signedInWebUsers, $oid_meetingUserCount, 
            $oid_iveConcurrentUsers, $oid_clusterConcurrentUsers,
            $oid_iveMaxConcurrentUsersLicenseCapacity
        ],
        nothing_quit => 1
    );

    $self->{global} = {
        web => $result->{$oid_signedInWebUsers},
        meeting => $result->{$oid_meetingUserCount},
        cluster_used => $result->{$oid_clusterConcurrentUsers},
        cluster_free => defined($result->{$oid_iveMaxConcurrentUsersLicenseCapacity}) && $result->{$oid_iveMaxConcurrentUsersLicenseCapacity} > 0 ? 
            $result->{$oid_iveMaxConcurrentUsersLicenseCapacity} - $result->{$oid_clusterConcurrentUsers} : undef,
        cluster_total => defined($result->{$oid_iveMaxConcurrentUsersLicenseCapacity}) && $result->{$oid_iveMaxConcurrentUsersLicenseCapacity} > 0 ? $result->{$oid_iveMaxConcurrentUsersLicenseCapacity} : '',
        cluster_prct_used => 
            defined($result->{$oid_iveMaxConcurrentUsersLicenseCapacity}) && $result->{$oid_iveMaxConcurrentUsersLicenseCapacity} > 0 ?
                $result->{$oid_clusterConcurrentUsers} * 100 / $result->{$oid_iveMaxConcurrentUsersLicenseCapacity} : undef,
        node_used => $result->{$oid_iveConcurrentUsers},
        node_free => defined($result->{$oid_iveMaxConcurrentUsersLicenseCapacity}) && $result->{$oid_iveMaxConcurrentUsersLicenseCapacity} > 0 ? 
            $result->{$oid_iveMaxConcurrentUsersLicenseCapacity} - $result->{$oid_iveConcurrentUsers} : undef,
        node_total => defined($result->{$oid_iveMaxConcurrentUsersLicenseCapacity}) && $result->{$oid_iveMaxConcurrentUsersLicenseCapacity} > 0 ? $result->{$oid_iveMaxConcurrentUsersLicenseCapacity} : '',
        node_prct_used => 
            defined($result->{$oid_iveMaxConcurrentUsersLicenseCapacity}) && $result->{$oid_iveMaxConcurrentUsersLicenseCapacity} > 0 ?
                $result->{$oid_iveConcurrentUsers} * 100 / $result->{$oid_iveMaxConcurrentUsersLicenseCapacity} : undef
    };
}

1;

__END__

=head1 MODE

Check users connections (web users, cluster users, node users, meeting users) (JUNIPER-IVE-MIB).

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='web|meeting'

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'node-users-usage', 'node-users-free', 'node-users-usage-prct',
'cluster-users-usage', 'cluster-users-free', 'cluster-users-usage-prct',
'web-users-signedin-usage', 'meeting-users-usage'.

=back

=cut
