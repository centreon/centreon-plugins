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

package apps::vmware::vsphere8::vcsa::mode::health;

use base qw(apps::vmware::vsphere8::vcsa::mode);

use strict;
use warnings;
use Date::Parse qw(&str2time);
use centreon::plugins::misc qw(change_seconds is_empty is_excluded);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

my @_options = qw/include_check exclude_check/;
my @_health_checks = qw/applmgmt database-storage load mem software-packages storage swap system/;

sub custom_health_output {
    my ($self, %options) = @_;

    my $msg = sprintf(
        '"%s" is "%s"',
        $self->{result_values}->{health_check},
        $self->{result_values}->{color}
    );

    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'health', type => 1, message_multiple => 'All health checks are OK' },
    ];

    $self->{maps_counters}->{health} = [
        {
            label  => 'status',
            type   => 2,
            warning_default  => '%{color} ne "green"',
            critical_default => '%{color} eq "red"',
            set    => {
                key_values      => [ { name => 'color' }, { name => 'health_check' } ],
                closure_custom_output => $self->can('custom_health_output'),
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self              = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);

    $options{options}->add_options(arguments => {
        ( map { ($_ =~ s/_/-/gr).':s' => { name => $_, default => '' } } @_options )
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    # Retrieve the data
    foreach my $health_check (@_health_checks) {
        next if is_excluded(
            $health_check,
            $self->{option_results}->{include_check},
            $self->{option_results}->{exclude_check});

        my $color = $options{custom}->request_api(
            'endpoint' => '/appliance/health/' . $health_check,
            'method' => 'GET');
        $color =~ s/^"//;
        $color =~ s/"$//;
        $self->{health}->{$health_check} = {
            health_check => $health_check,
            color        => $color
        };
    }

    $self->{output}->option_exit(short_msg => 'No health checks found with current filters.') if (keys(%{$self->{health}}) == 0);

}

1;

__END__

=head1 MODE

Monitor the health status of VMware vCenter Server Appliance (VCSA) through the vSphere REST API.

=over 8

=item B<--include-check>

Regular expression to include health checks to monitor by their name.
The list of supported health checks is: C<applmgmt>, C<database-storage>, C<load>, C<mem>, C<software-packages>,
C<storage>, C<swap>, C<system>.

=item B<--exclude-check>

Regular expression to exclude health checks to monitor by their name.
The list of supported health checks is: C<applmgmt>, C<database-storage>, C<load>, C<mem>, C<software-packages>,
C<storage>, C<swap>, C<system>.

=item B<--warning-status>

Define the condition to match for the status to be WARNING. Available macros: C<%(color)> and C<%(health_check)>.
Default: C<%{state} ne "green">

Color can be:

=over 8

=item - B<green>: Good. All components are healthy.

=item - B<yellow>: Warning. One or more components might become overloaded soon.
View the details in the Health Messages pane.

=item - B<orange>: Alert. One or more components might be degraded. Non-security patches might be available.
View the details in the Health Messages pane.

=item - B<red>: Critical. One or more components might be in an unusable status and vCenter Server might become unresponsive soon. Security patches might be available.
View the details in the Health Messages pane.

=item - B<gray>: Unknown. No data is available.

=back

=item B<--critical-status>

Define the condition to match for the status to be WARNING. Available macros: C<%(color)> and C<%(health_check)>.
Default: C<%{state} eq "red">

Status colors are detailed in C<--warning-status> option.

=back

=cut
