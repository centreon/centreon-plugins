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

package storage::hp::storeonce::4::restapi::mode::hardwarestorage;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^(?:fan\.speed|temperature)$';

    $self->{cb_hook2} = 'snmp_execute';

    $self->{thresholds} = {
        default => [
            ['ok', 'OK'],
            ['missing', 'OK'],
            ['degraded', 'OK'],
            ['critical', 'CRITICAL'],
            ['failed', 'CRITICAL']
        ]
    };

    $self->{components_path} = 'storage::hp::storeonce::4::restapi::mode::components';
    $self->{components_module} = ['drive', 'driveencl', 'fan', 'iomodule', 'pool', 'psu', 'temperature'];
}

sub browse_components {
    my ($self, %options) = @_;

    foreach my $comp (@{${$options{components}}}) {
        if ($comp->{name} =~ /tempSensor|pool|driveEnclosure|powerSupply|IOmodule|fan|drive/) {
            my $entry = {
                name => join(':', @{$options{path}}, (defined($comp->{value}->{location}) ? $comp->{value}->{location} : $comp->{value}->{name})),
                status => $comp->{value}->{status}
            };
            if ($comp->{name} eq 'tempSensor') {
                $entry->{temperature} = defined($comp->{value}->{temperature}) && $comp->{value}->{temperature} =~ /^\s*(\d+)\s*C/ ? $1 : undef;
                $entry->{upperNonCriticalThreshold} = defined($comp->{value}->{upperNonCriticalThreshold}) && $comp->{value}->{upperNonCriticalThreshold} =~ /^\s*(\d+)\s*C/ ? $1 : undef;
                $entry->{upperCriticalThreshold} = defined($comp->{value}->{upperCriticalThreshold}) && $comp->{value}->{upperCriticalThreshold} =~ /^\s*(\d+)\s*C/ ? $1 : undef;
            } elsif ($comp->{name} eq 'fan') {
                $entry->{speed} = defined($comp->{value}->{speed}) && $comp->{value}->{speed} =~ /^\s*(\d+)\s*RPM/i ? $1 : undef;
            }
            push @{$self->{subsystems}->{ $comp->{name} }}, $entry;
        }

        $self->browse_components(
            components => \$comp->{value}->{component},
            path => [@{$options{path}}, (defined($comp->{value}->{location}) ? $comp->{value}->{location} : $comp->{value}->{name})]
        );
    }
}

sub snmp_execute {
    my ($self, %options) = @_;
    
    $self->{subsystems} = {
        tempSensor => [],
        pool => [],
        driveEnclosure => [],
        powerSupply => [],
        IOmodule => [],
        fan => [],
        drive => []
    };
    my $storages = $options{custom}->request_api(endpoint => '/hwmonitor/storage');
    foreach my $storage (@{$storages->{storageCluster}}) {
        my $sc_infos = $options{custom}->request_api(endpoint => '/hwmonitor/storage/' . $storage->{name});
        $self->browse_components(
            components => \$sc_infos->{hardwareReportResponse}->{hardwareReport}->{component}->[0]->{value}->{component},
            path => [$storage->{name}]
        );
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

1;

__END__

=head1 MODE

Check hardware.

=over 8

=item B<--component>

Which component to check.
Can be: 'drive', 'driveencl', 'fan', 'iomodule', 'pool', 'psu', 'temperature'.

=item B<--filter>

Exclude the items given as a comma-separated list (example: --filter=psu).
You can also exclude items from specific instances: --filter=fan,fan slot 1

=item B<--absent-problem>

Return an error if a component is not 'present' (default is skipping).
It can be set globally or for a specific instance: --absent-problem='component_name' or --absent-problem='component_name,instance_value'.

=item B<--no-component>

Define the expected status if no components are found (default: critical).

=item B<--threshold-overload>

Use this option to override the status returned by the plugin when the status label matches a regular expression (syntax: section,status,regexp).
Example: --threshold-overload='fan,WARNING,missing'

=item B<--warning>

Set warning threshold for 'fan.speed' (syntax: section,[instance,]status,regexp)
Example: --warning='fan.speed,.*,10000'

=item B<--critical>

Set critical threshold for 'fan.speed' (syntax: section,[instance,]status,regexp)
Example: --critical='fan.speed,.*,11000'

=item B<--warning-count-*>

Define the warning threshold for the number of components of one type (replace '*' with the component type).

=item B<--critical-count-*>

Define the critical threshold for the number of components of one type (replace '*' with the component type).

=back

=cut
