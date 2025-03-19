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

package apps::scalecomputing::restapi::mode::listvdomains;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(
        arguments => {
            'node-uuid:s'    => { name => 'node_uuid' },
            'filter-os:s'    => { name => 'filter_os' },
            'filter-tag:s'   => { name => 'filter_tag' },
            'filter-state:s' => { name => 'filter_state' }
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

    my $virtual_domains = $options{custom}->list_virtual_domains();
    foreach my $virtual_domain (@{$virtual_domains}) {
        if (defined($self->{option_results}->{node_uuid}) && $self->{option_results}->{node_uuid} ne '' &&
            $virtual_domain->{nodeUUID} !~ /$self->{option_results}->{node_uuid}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $virtual_domain->{nodeUUID} . "'.", debug => 1);
            next;
        }

        if (defined($self->{option_results}->{filter_os}) && $self->{option_results}->{filter_os} ne '' &&
            $virtual_domain->{operatingSystem} !~ /$self->{option_results}->{filter_os}/) {
            $self->{output}->output_add(long_msg =>
                "skipping '" . $virtual_domain->{operatingSystem} . "'.",
                debug                            =>
                    1);
            next;
        }

        if (defined($self->{option_results}->{filter_tag}) && $self->{option_results}->{filter_tag} ne '' &&
            $virtual_domain->{tags} !~ /$self->{option_results}->{filter_tag}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $virtual_domain->{tags} . "'.", debug => 1);
            next;
        }

        if (defined($self->{option_results}->{filter_state}) && $self->{option_results}->{filter_state} ne '' &&
            $virtual_domain->{state} !~ /$self->{option_results}->{filter_state}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $virtual_domain->{state} . "'.", debug => 1);
            next;
        }

        push @{$self->{vdomains}}, $virtual_domain;
    }
}

sub run {
    my ($self, %options) = @_;

    $self->manage_selection(%options);

    if (scalar(keys @{$self->{vdomains}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No virtual domain found matching.");
        $self->{output}->option_exit();
    }

    foreach (sort @{$self->{vdomains}}) {
        $self->{output}->output_add(
            long_msg =>
                sprintf(
                    "[uuid = %s] [name = %s] [description = %s] [operating system = %s] [state = %s] [tags = %s] [machine type = %s]",
                    $_->{uuid},
                    $_->{name},
                    $_->{description},
                    $_->{operatingSystem},
                    $_->{state},
                    $_->{tags},
                    $_->{machineType},
                )
        );
    }

    $self->{output}->output_add(
        severity  => 'OK',
        short_msg => 'List virtual domains:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(
        elements => [ 'uuid', 'name', 'description', 'operating_system', 'state', 'tags', 'machine_type' ]
    );
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $virtual_domain (@{$self->{vdomains}}) {
        $self->{output}->add_disco_entry(
            uuid             => $virtual_domain->{uuid},
            name             => $virtual_domain->{name},
            description      => $virtual_domain->{description},
            operating_system => $virtual_domain->{operatingSystem},
            state            => $virtual_domain->{state},
            tags             => $virtual_domain->{tags},
            machine_type     => $virtual_domain->{machineType}
        );
    }
}

1;

__END__

=head1 MODE

List virtual domains.

=over 8

=item B<--node-uuid>

Gets all virtual domains of a node

=item B<--filter-os>

Filters all virtual domains by operating system (can be a regexp).

=item B<--filter-tag>

Filters all virtual domains by tag (can be a regexp).

=item B<--filter-state>

Filters all virtual domains by state (can be a regexp).

=back

=cut
