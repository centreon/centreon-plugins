#
# Copyright 2025-Present Centreon (http://www.centreon.com/)
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

package apps::vmware::vsphere8::vcsa::mode::updates;

use base qw(apps::vmware::vsphere8::vcsa::mode);

use strict;
use warnings;
use Date::Parse qw(&str2time);
use centreon::plugins::misc qw(change_seconds);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_uptime_output {
    my ($self, %options) = @_;

    my $msg = sprintf(
        'Last repository update was done %s, %d day(s) ago',
        $self->{result_values}->{latest_query_time},
        $self->{result_values}->{age_in_days}
    );

    return $msg;
}

sub custom_version_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "version '%s' is '%s'",
        $self->{result_values}->{version},
        $self->{result_values}->{state}
    );
}


sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];

    $self->{maps_counters}->{global} = [
        {
            label  => 'version-status',
            type   => 2,
            warning_default  => '%{state} ne "UP_TO_DATE"',
            critical_default => '%{state} =~ /^(INSTALL_FAILED|ROLLBACK_IN_PROGRESS)$/',
            unknown_default  => '%{state} eq ""',
            set    => {
                key_values      => [ { name => 'state' }, { name => 'version' } ],
                closure_custom_output => $self->can('custom_version_status_output'),
                closure_custom_threshold_check => \&catalog_status_threshold_ng

            }
        },
        {
            label  => 'repository-age',
            nlabel => 'repository.age.days',
            type   => 1,
            set    => {
                key_values      => [ { name => 'latest_query_time' }, { name => 'age_in_days' } ],
                closure_custom_output => $self->can('custom_uptime_output'),
                threshold_use => 'age_in_days',
                perfdatas => [
                    { value => 'age_in_days', template => '%d', unit => 'd' }
                ],
                closure_custom_threshold_check => $self->can('custom_uptime_threshold')

            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);

    $options{options}->add_options( arguments => {} );

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $response = $self->get_value(%options, endpoint => 'update');



    my $age_in_days = (time() - str2time($response->{latest_query_time})) / 86400
        if defined($response->{latest_query_time});

    $self->{global} = {
        state => $response->{state} // '',
        version => $response->{version} // '',
        age_in_days => $age_in_days // 0,
        latest_query_time => $response->{latest_query_time} // 0,
    }

}

1;

__END__

=head1 MODE

Monitor the number of VMware VMs through vSphere 8 REST API.

=over 8

=item B<--warning-repository-age>

Threshold in days.

=item B<--critical-repository-age>

Threshold in days.

=item B<--warning-version-status>

Define the condition to match for the status to be WARNING. Available macros: C<%(state)> and C<%(version)>.
Default: C<%{state} ne "UP_TO_DATE">

Version and state meanings can be:

    - Version of base appliance if state is UP_TO_DATE
    - Version of update being staged or installed if state is INSTALL_IN_PROGRESS or STAGE_IN_PROGRESS
    - Version of update staged if state is UPDATES_PENDING
    - Version of update failed if state is INSTALL_FAILED or ROLLBACK_IN_PROGRESS

=item B<--critical-version-status>

Define the condition to match for the status to be CRITICAL. Available macros: C<%(state)> and C<%(version)>.
Default: C<%{state} =~ /^(INSTALL_FAILED|ROLLBACK_IN_PROGRESS)$/">

Version and state meanings can be:

    - Version of base appliance if state is UP_TO_DATE
    - Version of update being staged or installed if state is INSTALL_IN_PROGRESS or STAGE_IN_PROGRESS
    - Version of update staged if state is UPDATES_PENDING
    - Version of update failed if state is INSTALL_FAILED or ROLLBACK_IN_PROGRESS

=back

=cut
