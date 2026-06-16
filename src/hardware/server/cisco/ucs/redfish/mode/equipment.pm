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

package hardware::server::cisco::ucs::redfish::mode::equipment;

use strict;
use warnings;
use base qw(centreon::plugins::templates::hardware);

sub set_system {
    my ($self, %options) = @_;

    $self->{cb_hook2} = 'load_data';

    $self->{thresholds} = {
        health => [
            ['OK',       'OK'],
            ['Warning',  'WARNING'],
            ['Critical', 'CRITICAL'],
            ['.*',       'UNKNOWN'],
        ],
        state => [
            ['Enabled',            'OK'],
            ['Disabled',           'WARNING'],
            ['StandbyOffline',     'OK'],
            ['StandbySpare',       'OK'],
            ['Absent',             'OK'],
            ['UnavailableOffline', 'CRITICAL'],
            ['.*',                 'UNKNOWN'],
        ],
    };

    $self->{components_path}   = 'hardware::server::cisco::ucs::redfish::mode::components';
    $self->{components_module} = ['chassis', 'cpu', 'fan', 'psu', 'memory', 'localdisk'];
}

# Walk the Redfish tree once and store everything into $self->{data}
sub load_data {
    my ($self, %options) = @_;

    my $api_path = $options{custom}->{api_path};

    $self->{data} = {
        chassis   => [],
        cpu       => [],
        fan       => [],
        psu       => [],
        memory    => [],
        localdisk => [],
    };

    # --- Chassis collection: fans (Thermal) + PSUs (Power) ---
    my $chassis_list = $options{custom}->get_collection(endpoint => '/Chassis');
    for my $chassis (@{$chassis_list}) {
        push @{$self->{data}->{chassis}}, $chassis;

        my $thermal_url = $chassis->{Thermal}->{'@odata.id'} // '';
        if ($thermal_url ne '') {
            $thermal_url =~ s{^\Q$api_path\E}{};
            my $thermal = $options{custom}->request(endpoint => $thermal_url);
            push @{$self->{data}->{fan}}, @{$thermal->{Fans} // []};
        }

        my $power_url = $chassis->{Power}->{'@odata.id'} // '';
        if ($power_url ne '') {
            $power_url =~ s{^\Q$api_path\E}{};
            my $power = $options{custom}->request(endpoint => $power_url);
            push @{$self->{data}->{psu}}, @{$power->{PowerSupplies} // []};
        }
    }

    # --- Systems collection: CPUs, memory, drives ---
    my $systems = $options{custom}->get_collection(endpoint => '/Systems');
    for my $system (@{$systems}) {
        my $proc_url = $system->{Processors}->{'@odata.id'} // '';
        if ($proc_url ne '') {
            $proc_url =~ s{^\Q$api_path\E}{};
            push @{$self->{data}->{cpu}}, @{$options{custom}->get_collection(endpoint => $proc_url)};
        }

        my $mem_url = $system->{Memory}->{'@odata.id'} // '';
        if ($mem_url ne '') {
            $mem_url =~ s{^\Q$api_path\E}{};
            push @{$self->{data}->{memory}}, @{$options{custom}->get_collection(endpoint => $mem_url)};
        }

        my $storage_url = $system->{Storage}->{'@odata.id'} // '';
        if ($storage_url ne '') {
            $storage_url =~ s{^\Q$api_path\E}{};
            my $controllers = $options{custom}->get_collection(endpoint => $storage_url);
            for my $ctrl (@{$controllers}) {
                for my $drive_ref (@{$ctrl->{Drives} // []}) {
                    my $drive_url = $drive_ref->{'@odata.id'} // '';
                    next if $drive_url eq '';
                    $drive_url =~ s{^\Q$api_path\E}{};
                    push @{$self->{data}->{localdisk}}, $options{custom}->request(endpoint => $drive_url);
                }
            }
        }
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    return $self;
}

1;

__END__

=head1 MODE

Check Cisco UCS hardware components via Redfish API.

Navigation path:
  /Chassis -> Thermal (fans) + Power (PSUs)
  /Systems -> Processors, Memory, Storage/Drives

=over 8

=item B<--component>

Filter component type (regexp). Example: --component='fan|psu'

=item B<--filter>

Filter component instance (regexp). Example: --filter='CPU1'

=item B<--no-component>

Status to return when no component is found (default: critical).

=item B<--threshold-overload>

Override default severity. Format: section,[instance,]status,regexp
Example: --threshold-overload='fan,WARNING,Critical'

=back

=cut
