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

package centreon::common::redfish::restapi::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;
        
    $self->{regexp_threshold_numeric_check_section_option} = '^(?:fan|temperature|psu)$';

    $self->{cb_hook2} = 'execute_custom';

    $self->{thresholds} = {
        status => [
            ['ok', 'OK'],
            ['warning', 'WARNING'],
            ['critical', 'CRITICAL'],
            ['n/a', 'OK']
        ],
        state => [
            # can be: absent, deferring, disabled, enabled, 
            #    inTest, quiesced, standbyOffline, standbySpare
            #    starting, unavailableOffline, updating
            ['updating', 'WARNING'],
            ['.*', 'OK']
        ]
    };

    $self->{components_exec_load} = 0;

    $self->{components_path} = 'centreon::common::redfish::restapi::mode::components';
    $self->{components_module} = ['chassis', 'device', 'drive', 'fan', 'psu', 'sc', 'storage', 'temperature', 'volume'];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {});
    
    return $self;
}

sub get_power {
    my ($self, %options) = @_;

    return {} if (!defined($options{chassis}->{Power}->{'@odata.id'}));
    return $self->{custom}->request_api(url_path => $options{chassis}->{Power}->{'@odata.id'});
}

sub get_thermal {
    my ($self, %options) = @_;

    return {} if (!defined($options{chassis}->{Thermal}->{'@odata.id'}));
    return $self->{custom}->request_api(url_path => $options{chassis}->{Thermal}->{'@odata.id'});
}

sub get_devices {
    my ($self, %options) = @_;

    $self->get_chassis() if (!defined($self->{chassis}));
    foreach my $chassis (@{$self->{chassis}}) {
        $chassis->{Devices} = [];
        my $result = $self->{custom}->request_api(
            url_path => $chassis->{'@odata.id'} . 'Devices/',
            ignore_codes => { 404 => 1 }
        );
        next if (!defined($result));

        foreach (@{$result->{Members}}) {
            my $device_detailed = $self->{custom}->request_api(url_path => $_->{'@odata.id'});
            push @{$chassis->{Devices}}, $device_detailed;
        }
    }
}

sub get_chassis {
    my ($self, %options) = @_;

    $self->{chassis} = [];
    #  "Members":[
    #    { "@odata.id":"/redfish/v1/Chassis/1/" }
    #  ],
    my $result = $self->{custom}->request_api(url_path => '/redfish/v1/chassis/');
    foreach (@{$result->{Members}}) {
        my $chassis_detailed = $self->{custom}->request_api(url_path => $_->{'@odata.id'});
        push @{$self->{chassis}}, $chassis_detailed;
    }
}

sub get_drive {
    my ($self, %options) = @_;

    return {} if (!defined($options{drive}->{'@odata.id'}));
    return $self->{custom}->request_api(url_path => $options{drive}->{'@odata.id'});
}

sub get_volumes {
    my ($self, %options) = @_;

    return [] if (!defined($options{storage}->{Volumes}->{'@odata.id'}));

    my $volumes = $self->{custom}->request_api(url_path => $options{storage}->{Volumes}->{'@odata.id'});

    my $result = [];
    foreach my $volume (@{$volumes->{Members}}) {
        my $volume_detailed = $self->{custom}->request_api(url_path => $volume->{'@odata.id'});
        push @$result, $volume_detailed;
    }

    return $result;
}

sub get_storages {
    my ($self, %options) = @_;

    $self->{storages} = [];
    my $systems = $self->{custom}->request_api(url_path => '/redfish/v1/Systems');
    foreach my $system (@{$systems->{Members}}) {
        my $storages = $self->{custom}->request_api(
            url_path => $system->{'@odata.id'} . '/Storage/',
            ignore_codes => { 400 => 1, 404 => 1 }
        );
        next if (!defined($storages));

        foreach my $storage (@{$storages->{Members}}) {
            my $storage_detailed = $self->{custom}->request_api(url_path => $storage->{'@odata.id'});
            push @{$self->{storages}}, $storage_detailed;
        }
    }
}

sub execute_custom {
    my ($self, %options) = @_;

    $self->{custom} = $options{custom};
}

1;

=head1 MODE

Check hardware.

=over 8

=item B<--component>

Which component to check (default: '.*').
Can be: 'chassis', 'device', 'drive', 'fan', 'psu', 'sc', 'storage', 'temperature', 'volume'.

=item B<--filter>

Exclude some parts (comma separated list)
You can also exclude items from specific instances: --filter='fan,1.2'

=item B<--no-component>

Define the expected status if no components are found (default: critical).


=item B<--threshold-overload>

Use this option to override the status returned by the plugin when the status label matches a regular expression (syntax: section,[instance,]status,regexp).
Example: --threshold-overload='chassis.state,WARNING,inTest'

=item B<--warning>

Set warning threshold for 'temperature', 'fan', 'psu' (syntax: type,regexp,threshold)
Example: --warning='temperature,.*,30'

=item B<--critical>

Set critical threshold for 'temperature', 'fan', 'psu' (syntax: type,regexp,threshold)
Example: --critical='temperature,.*,50'

=back

=cut
