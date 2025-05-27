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

package apps::scalecomputing::restapi::mode::listdrives;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(
        arguments => {
            'node-uuid:s'   => { name => 'node_uuid' },
            'filter-type:s' => { name => 'filter_type' }
        }
    );

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $drives = $options{custom}->list_drives();
    foreach my $drive (@{$drives}) {
        if (defined($self->{option_results}->{node_uuid}) && $self->{option_results}->{node_uuid} ne '' &&
            $drive->{nodeUUID} !~ /$self->{option_results}->{node_uuid}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $drive->{nodeUUID} . "'.", debug => 1);
            next;
        }

        if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
            $drive->{type} !~ /$self->{option_results}->{filter_type}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $drive->{type} . "'.", debug => 1);
            next;
        }

        push @{$self->{drives}}, $drive;
    }
}

sub run {
    my ($self, %options) = @_;

    $self->manage_selection(%options);

    if (scalar(keys @{$self->{drives}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No drive found matching.");
        $self->{output}->option_exit();
    }

    foreach (sort @{$self->{drives}}) {
        $self->{output}->output_add(
            long_msg =>
                sprintf(
                    "[uuid = %s] [serial = %s] [type = %s] [slot = %s] [node uuid = %s] [capacity = %s] [block device path = %s]",
                    $_->{uuid},
                    $_->{serialNumber},
                    $_->{type},
                    $_->{slot},
                    $_->{nodeUUID},
                    $_->{capacityBytes},
                    $_->{blockDevicePath},
                )
        );
    }

    $self->{output}->output_add(
        severity  => 'OK',
        short_msg => 'List drives:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(
        elements => [
            'uuid', 'serial_number', 'type', 'slot', 'node_uuid', 'capacity', 'block_device_path'
        ]
    );
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $drive (@{$self->{drives}}) {
        $self->{output}->add_disco_entry(
            uuid              => $drive->{uuid},
            serial            => $drive->{serialNumber},
            type              => $drive->{type},
            slot              => $drive->{slot},
            node_uuid         => $drive->{nodeUUID},
            capacity          => $drive->{capacityBytes},
            block_device_path => $drive->{blockDevicePath}
        );
    }
}

1;

__END__

=head1 MODE

List drives.

=over 8

=item B<--node-uuid>

Gets all drives of a node

=item B<--filter-type>

Filters the drive list by type (can be a regexp).

=back

=cut
