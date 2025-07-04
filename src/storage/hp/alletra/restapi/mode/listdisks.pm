#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package storage::hp::alletra::restapi::mode::listdisks;

use strict;
use warnings;

use base qw(centreon::plugins::mode);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-id:s'       => { name => 'filter_id' },
        'filter-protocol:s' => { name => 'filter_protocol' },
        'filter-type:s'     => { name => 'filter_type' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

my %connection_type = (
    1  => 'FC',
    2  => 'SATA',
    4  => 'NVMe',
    99 => 'unknown'
);

my %media_type = (
    1  => 'Magnetic',
    2  => 'SLC',
    3  => 'MLC',
    4  => 'cMLC',
    5  => '3DX',
    99 => 'unknown'
);

sub run {
    my ($self, %options) = @_;

    my $response = $options{custom}->request_api(endpoint => '/api/v1/disks');
    my $disks = $response->{members};

    $self->{disks} = [];

    for my $disk (@{$disks}) {
        $disk->{type} = $media_type{$disk->{type}};
        $disk->{protocol} = $connection_type{$disk->{protocol}};

        # skip if filtered by protocol
        if (defined($self->{option_results}->{filter_protocol})
            and $self->{option_results}->{filter_protocol} ne '' and $disk->{protocol} !~ /$self->{option_results}->{filter_protocol}/) {
            $self->{output}->output_add(
                long_msg => "Skipping $disk->{protocol} because the protocol does not match the protocol filter.",
                debug    => 1
            );
            next;
        }

        # skip if filtered by type
        if (defined($self->{option_results}->{filter_type})
            and $self->{option_results}->{filter_type} ne '' and $disk->{type} !~ /$self->{option_results}->{filter_type}/) {
            $self->{output}->output_add(
                long_msg => "Skipping $disk->{type} because the type does not match the type filter.",
                debug    => 1
            );
            next;
        }

        # skip if filtered by id
        if (defined($self->{option_results}->{filter_id})
            and $self->{option_results}->{filter_id} ne '' and $disk->{id} !~ /$self->{option_results}->{filter_id}/) {
            $self->{output}->output_add(
                long_msg => "Skipping $disk->{id} because the id does not match the id filter.",
                debug    => 1
            );
            next;
        }

        push @{$self->{disks}}, {
            id           => $disk->{id},
            position     => $disk->{position},
            size         => $disk->{totalSizeMiB},
            manufacturer => $disk->{manufacturer},
            model        => $disk->{model},
            serial       => $disk->{serialNumber},
            protocol     => $disk->{protocol},
            type         => $disk->{type}
        };

        $self->{output}->output_add(
            long_msg => sprintf(
                "[id: %s][position: %s][size: %s][manufacturer: %s][model: %s][serial: %s][protocol: %s][type: %s]",
                $disk->{id},
                $disk->{position},
                $disk->{totalSizeMiB},
                $disk->{manufacturer},
                $disk->{model},
                $disk->{serialNumber},
                $disk->{protocol},
                $disk->{type}
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

    $self->{output}->add_disco_format(elements =>
        [ 'id', 'position', 'size', 'manufacturer', 'model', 'serial', 'protocol', 'type' ]);
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
            serial       => $disk->{serial},
            protocol     => $disk->{protocol},
            type         => $disk->{type}
        );
    }
}

1;

__END__

=head1 MODE

List physical disks using the HPE Alletra REST API.

=over 8

=item B<--filter-id>

Display disks matching the id filter.

=item B<--filter-protocol>

Display disks matching the protocol filter.

=item B<--filter-type>

Display disks matching the media type filter.

=back

=cut
