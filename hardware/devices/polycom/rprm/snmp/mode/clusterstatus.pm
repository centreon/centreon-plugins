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

package hardware::devices::polycom::rprm::snmp::mode::clusterstatus;

use base qw(centreon::plugins::templates::counter);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'cluster-status', type => 2, critical_default => '%{cluster_status} =~ /outOfService/i', set => {
                key_values => [ { name => 'cluster_status' } ],
                output_template => 'Current status %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'cluster-change-cause', type => 2, set => {
                key_values => [ { name => 'cluster_change_cause' } ],
                output_template => 'Last change cause: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'RPRM HA Super Cluster: ';
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

    my $oid_serviceHASuperClstrStatus = '.1.3.6.1.4.1.13885.102.1.2.16.1.0';
    my $oid_serviceHAStatusChgReason = '.1.3.6.1.4.1.13885.102.1.2.16.2.0';

    my %cluster_status = (  1 => 'inService', 2 => 'busyOut', 3 => 'outOfService' );

    my $result = $options{snmp}->get_leef(
        oids => [
            $oid_serviceHASuperClstrStatus,
            $oid_serviceHAStatusChgReason
        ],
        nothing_quit => 1
    );

    $self->{global} = {
        cluster_status => $cluster_status{$result->{$oid_serviceHASuperClstrStatus}},
        cluster_change_cause => $result->{$oid_serviceHAStatusChgReason}
    };
}

1;

__END__

=head1 MODE

Check Polycom HA SuperCluster status

=over 8

=item B<--warning-cluster-status>

Custom Warning threshold of the cluster state (Default: none)
Syntax: --warning-cluster-status='%{cluster_status} =~ /busyOut/i'

=item B<--critical-cluster-status>

Custom Critical threshold of the cluster state
(Default: '%{cluster_status} =~ /outOfService/i' )
Syntax: --critical-cluster-status='%{cluster_status} =~ /failed/i'

=item B<--warning-cluster-change-cause>

Custom Warning threshold of the cluster state change cause (Default: none)
Syntax: --warning-cluster-change-cause='%{cluster_change_cause} =~ /manualFailover/i'

=item B<--critical-cluster-change-cause>

Custom Critical threshold of the cluster state change cause (Default: none)
Syntax: --critical-cluster-change-cause='%{cluster_change_cause} =~ /manualFailover/i'

=back

=cut
