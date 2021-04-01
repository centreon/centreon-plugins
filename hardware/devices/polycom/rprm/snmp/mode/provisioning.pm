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

package hardware::devices::polycom::rprm::snmp::mode::provisioning;

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
        { label => 'provisioning-status', type => 2, critical_default => '%{provisioning_status} =~ /failed/i', set => {
                key_values => [ { name => 'provisioning_status' } ],
                closure_custom_output => $self->can('custom_provisioning_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'provisioning-failed', nlabel => 'rprm.provisioning.failed.count', set => {
                key_values => [ { name => 'provisioning_failed' } ],
                output_template => 'Failed last 60m: %s',
                perfdatas => [
                    { template => '%s', min => 0, unit => '' }
                ]
            }
        },
        { label => 'provisioning-success', nlabel => 'rprm.provisioning.success.count', set => {
                key_values => [ { name => 'provisioning_success' } ],
                output_template => 'Successed last 60m: %s',
                perfdatas => [
                    { template => '%s', min => 0, unit => '' }
                ]
            }
        }
    ];
}

sub custom_provisioning_status_output {
    my ($self, %options) = @_;

    return sprintf('Current status: "%s"',  $self->{result_values}->{provisioning_status});
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'RPRM Provisioning jobs stats: ';
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

    my $oid_serviceProvisioningStatus = '.1.3.6.1.4.1.13885.102.1.2.2.1.0';
    my $oid_serviceProvisioningFailuresLast60Mins = '.1.3.6.1.4.1.13885.102.1.2.2.2.0';
    my $oid_serviceProvisioningSuccessLast60Mins = '.1.3.6.1.4.1.13885.102.1.2.2.3.0';

    my %provisioning_status = ( 0 => 'clear', 2 => 'in-progress', 3 => 'success', 4 => 'failed' );

    my $result = $options{snmp}->get_leef(
        oids => [
            $oid_serviceProvisioningStatus,
            $oid_serviceProvisioningFailuresLast60Mins,
            $oid_serviceProvisioningSuccessLast60Mins
        ],
        nothing_quit => 1
    );

    $self->{global} = {
        provisioning_status => $provisioning_status{$result->{$oid_serviceProvisioningStatus}},
        provisioning_failed => $result->{$oid_serviceProvisioningFailuresLast60Mins},
        provisioning_success => $result->{$oid_serviceProvisioningSuccessLast60Mins}
    };
}

1;

__END__

=head1 MODE

Check Polycom RPRM provisioning jobs

=over 8

=item B<--warning-provisioning-status>

Custom Warning threshold of the provisioning state (Default: none)
Syntax: --warning-provisioning-status='%{provisioning_status} =~ /clear/i'

=item B<--critical-provisioning-status>

Custom Critical threshold of the provisioning state
(Default: '%{provisioning_status} =~ /failed/i' )
Syntax: --critical-provisioning-status='%{provisioning_status} =~ /failed/i'

=item B<--warning-* --critical-*>

Warning and Critical thresholds.
Possible values are: provisioning-failed, provisioning-success

=back

=cut
