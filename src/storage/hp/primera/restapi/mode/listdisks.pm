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

package storage::hp::primera::restapi::mode::listdisks;

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

    my $response = $options{custom}->request_api( endpoint => '/api/v1/disks' );
    my $disks = $response->{members};

    $self->{disks} = [];

    for my $disk (@{$disks}) {
        push @{$self->{disks}}, {
                id           => $disk->{id},
                position     => $disk->{position},
                size         => $disk->{totalSizeMiB},
                manufacturer => $disk->{manufacturer},
                model        => $disk->{model},
                serial       => $disk->{serialNumber}
        };
        $self->{output}->output_add(
            long_msg => sprintf(
                "[id: %s][position: %s][size: %s][manufacturer: %s][model: %s][serial: %s]",
                $disk->{id},
                $disk->{position},
                $disk->{totalSizeMiB},
                $disk->{manufacturer},
                $disk->{model},
                $disk->{serialNumber}
            )
        );
    }

    if (!defined($options{disco_show})) {
        $self->{output}->output_add(severity => 'OK', short_msg => 'Disks:');
        $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    }
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => [ 'id', 'position','size', 'manufacturer', 'model', 'serial' ]);
}

sub disco_show {
    my ($self, %options) = @_;

    $options{disco_show} = 1;
    $self->run(%options);

    for my $disk (@{$self->{disks}}) {
        $self->{output}->add_disco_entry(
            id           => $disk->{id},
            position     => $disk->{position},
            size         => $disk->{size},
            manufacturer => $disk->{manufacturer},
            model        => $disk->{model},
            serial       => $disk->{serial}
        );
    }
}

1;

__END__

=head1 MODE

List physical disks using the HPE Primera REST API.

=back

=cut
