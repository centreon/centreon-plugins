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

package network::backbox::restapi::mode::listdevices;

use strict;
use warnings;

use base qw(centreon::plugins::mode);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;

    my $jsondevices = $options{custom}->get_devices();

    $self->{devices} = [];

    for my $jsondevice (@{$jsondevices}) {
        my $device = {
            id           => $jsondevice->{deviceId},
            name         => $jsondevice->{deviceName},
            description  => defined($jsondevice->{description}) ? $jsondevice->{description} : '',
            site         => defined($jsondevice->{siteName}) ? $jsondevice->{siteName} : '',
            group        => defined($jsondevice->{groupName}) ? $jsondevice->{groupName} : '',
            vendor       => defined($jsondevice->{vendorName}) ? $jsondevice->{vendorName} : '',
            product      => defined($jsondevice->{productName}) ? $jsondevice->{productName} : '',
            product_type => defined($jsondevice->{productTypeName}) ? $jsondevice->{productTypeName} : '',
            version      => defined($jsondevice->{versionName}) ? $jsondevice->{versionName} : ''
        };
        push @{$self->{devices}}, $device;
        $self->{output}->output_add(
            long_msg => sprintf(
                "[id: %s][name: %s][description: %s][site: %s][group: %s][vendor: %s][product: %s][product_type: %s][version: %s]",
                $device->{id},
                $device->{name},
                $device->{description},
                $device->{site},
                $device->{group},
                $device->{vendor},
                $device->{product},
                $device->{product_type},
                $device->{version}
            )
        );
    }

    if (!defined($options{disco_show})) {
        $self->{output}->output_add(severity => 'OK', short_msg => 'Devices:');
        $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    }
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => [ 'id', 'name', 'description', 'site', 'group', 'vendor', 'product', 'product_type', 'version' ]);
}

sub disco_show {
    my ($self, %options) = @_;

    $options{disco_show} = 1;
    $self->run(%options);

    for my $device (@{$self->{devices}}) {
        $self->{output}->add_disco_entry(
            id           => $device->{id},
            name         => $device->{name},
            description  => $device->{description},
            site         => $device->{site},
            group        => $device->{group},
            vendor       => $device->{vendor},
            product      => $device->{product},
            product_type => $device->{product_type},
            version      => $device->{version}
        );
    }
}

1;

__END__

=head1 MODE

List devices using the Backbox REST API.

=back

=cut

