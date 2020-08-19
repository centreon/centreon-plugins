#
# Copyright 2020 Centreon (http://www.centreon.com/)
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
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'cluster-status', threshold => 0, set => {
                key_values => [ { name => 'cluster_status' } ],
                output_template => 'Current status %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        },
        { label => 'cluster-change-cause', threshold => 0, set => {
                key_values => [ { name => 'cluster_change_cause' } ],
                output_template => 'Last change cause: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        }
    ];
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'RPRM HA Super Cluster: ';
}


sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => [ 'warning_cluster_status', 'critical_cluster_status', 'warning_cluster_change_cause', 'critical_cluster_change_cause' ]);

    return $self;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

   $options{options}->add_options(arguments => {
        'warning-cluster-status:s'        => { name => 'warning_cluster_status', default => '' },
        'critical-cluster-status:s'       => { name => 'critical_cluster_status', default => '%{cluster_status} =~ /outOfService/i' },
        'warning-cluster-change-cause:s'  => { name => 'warning_cluster_change_cause', default => '' },
        'critical-cluster-change-cause:s' => { name => 'critical_cluster_change_cause', default => '' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_serviceHASuperClstrStatus = '.1.3.6.1.4.1.13885.102.1.2.16.1.0';
    my $oid_serviceHAStatusChgReason = '.1.3.6.1.4.1.13885.102.1.2.16.2.0';

    my %cluster_status = ( 1 => 'inService', 2 => 'busyOut', 3 => 'outOfService' );

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

Check Polycom RPRM updates jobs

=over 8

=item B<--warning-updates-status>

Custom Warning threshold of the updates state (Default: none)
Syntax: --warning-updates-status='%{updates_status} =~ /clear/i'


=item B<--critical-updates-status>

Custom Critical threshold of the updates state
(Default: '%{updates_status} =~ /failed/i' )
Syntax: --critical-updates-status='%{updates_status} =~ /failed/i'


=item B<--warning-* --critical-*>

Warning and Critical thresholds.
Possible values are: updates-failed, updates-successed

=back

=cut