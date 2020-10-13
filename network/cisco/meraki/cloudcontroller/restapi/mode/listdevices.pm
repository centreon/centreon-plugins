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

package network::cisco::meraki::cloudcontroller::restapi::mode::listdevices;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $organizations = $options{custom}->get_organizations(disable_cache => 1);
    my $networks = $options{custom}->get_networks(
        organizations => [keys %$organizations],
        disable_cache => 1
    );
    my $devices = $options{custom}->get_devices(
        organizations => [keys %$organizations],
        disable_cache => 1
    );

    my $devices_statuses = $options{custom}->get_organization_device_statuses();
    foreach (keys %$devices) {
        $devices->{$_}->{status} = $devices_statuses->{ $devices->{$_}->{serial} }->{status};
        $devices->{$_}->{public_ip} = $devices_statuses->{ $devices->{$_}->{serial} }->{publicIp};
        $devices->{$_}->{network_name} = $networks->{ $devices_statuses->{ $devices->{$_}->{serial} }->{networkId} }->{name};
        $devices->{$_}->{organization_name} = $organizations->{ $networks->{ $devices_statuses->{ $devices->{$_}->{serial} }->{networkId} }->{organizationId} }->{name};
    }

    return $devices;
}

sub run {
    my ($self, %options) = @_;

    my $devices = $self->manage_selection(%options);
    foreach (values %$devices) {
        $self->{output}->output_add(long_msg => sprintf(
                '[name: %s][status: %s][network name: %s][organization name: %s]',
                $_->{name},
                $_->{status},
                $_->{network_name},
                $_->{organization_name}
            )
        );
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List devices:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => [
        'name', 'status', 'tags', 'organization_name', 'network_id', 'network_name'
    ]);
}

sub disco_show {
    my ($self, %options) = @_;

    my $devices = $self->manage_selection(%options);
    foreach (values %$devices) {
        $self->{output}->add_disco_entry(
            name => $_->{name},
            status => $_->{status},
            network_name => $_->{network_name},
            network_id => $_->{networkId},
            organization_name => $_->{organization_name},
            tags => defined($_->{tags}) ? $_->{tags} : ''
        );
    }
}

1;

__END__

=head1 MODE

List devices.

=over 8

=back

=cut
