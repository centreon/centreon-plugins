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

package apps::scalecomputing::restapi::mode::listvdomainblockdevs;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(
        arguments => {
            'filter-vdomain-uuid:s' => { name => 'filter_vdomain_uuid' },
            'filter-type:s'         => { name => 'filter_type' }
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

    $self->{vdomains} = $options{custom}->list_virtual_domains();
    $self->{vdomain_names} = {};

    foreach my $vdomain (@{$self->{vdomains}}) {
        $self->{vdomain_names}->{$vdomain->{uuid}} = $vdomain->{name};
    }

    my $vdomain_block_devs = $options{custom}->list_virtual_domain_block_devices();
    foreach my $dev (@{$vdomain_block_devs}) {
        if (defined($self->{option_results}->{filter_vdomain_uuid}) && $self->{option_results}->{filter_vdomain_uuid} ne '' &&
            $dev->{virDomainUUID} !~ /$self->{option_results}->{filter_vdomain_uuid}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $dev->{virDomainUUID} . "'.", debug => 1);
            next;
        }

        if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
            $dev->{type} !~ /$self->{option_results}->{filter_type}/) {
            $self->{output}->output_add(long_msg =>
                "skipping '" . $dev->{type} . "'.",
                debug                            =>
                    1);
            next;
        }

        push @{$self->{vdomain_block_devs}}, $dev;
    }
}

sub run {
    my ($self, %options) = @_;

    $self->manage_selection(%options);

    if (scalar(keys @{$self->{vdomain_block_devs}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No virtual disk found matching.");
        $self->{output}->option_exit();
    }

    foreach my $devs (sort @{$self->{vdomain_block_devs}}) {
        $self->{output}->output_add(
            long_msg =>
                sprintf(
                    "[uuid = %s] [name = %s] [virtual domain uuid = %s] [virtual domain name = %s] [type = %s] [capacity = %s]",
                    $devs->{uuid},
                    $devs->{name},
                    $devs->{virDomainUUID},
                    defined($self->{vdomain_names}->{$devs->{virDomainUUID}}) ?
                        $self->{vdomain_names}->{$devs->{virDomainUUID}} :
                        "",
                    $devs->{type},
                    $devs->{capacity}
                )
        );
    }

    $self->{output}->output_add(
        severity  => 'OK',
        short_msg => 'List virtual domain block devices:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(
        elements => [
            'uuid',
            'name',
            'vir_domain_uuid',
            'vir_domain_name',
            'type',
            'capacity_bytes'
        ]
    );
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $devs (@{$self->{vdomain_block_devs}}) {
        $self->{output}->add_disco_entry(
            uuid            => $devs->{uuid},
            name            => $devs->{name},
            capacity        => $devs->{capacity},
            vir_domain_uuid => $devs->{virDomainUUID},
            vir_domain_name => defined($self->{vdomain_names}->{$devs->{virDomainUUID}}) ?
                $self->{vdomain_names}->{$devs->{virDomainUUID}} :
                "",
            type            => $devs->{type}
        );
    }
}

1;

__END__

=head1 MODE

List virtual disks.

=over 8

=item B<--filter-vdomain-uuid>

Filters all block devices by virtual domains (can be a regexp).

=item B<--filter-type>

Filters all block devices by type (can be a regexp).
Can be 'IDE_DISK', 'SCSI_DISK', 'SCSI_DISK', 'IDE_CDROM', 'IDE_FLOPPY', 'NVRAM', 'VTPM'

=back

=cut
