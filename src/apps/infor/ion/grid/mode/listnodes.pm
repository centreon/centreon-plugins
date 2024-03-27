#
# Copyright 2023 Centreon (http://www.centreon.com/)
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

package apps::infor::ion::grid::mode::listnodes;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self              = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->request_api(
        method   => 'GET',
        url_path => '/grid/rest/nodes'
    );

    my @nodes;
    foreach my $entry (@{$result}) {
        push @nodes, {
            type             => ucfirst(lc($entry->{entityType})),
            name             => $entry->{name},
            application_name => $entry->{applicationName},
            host_name        => $entry->{hostName},
            state            => ($entry->{online}) ? "online" : "offline"
        }
    }

    return \@nodes;
}

sub run {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(%options);
    foreach (@$results) {
        $self->{output}->output_add(
            long_msg => sprintf(
                '[type: %s][name: %s][application_name: %s][host_name: %s][state: %s]',
                $_->{type},
                $_->{name},
                $_->{application_name},
                $_->{host_name},
                $_->{state}
            )
        );
    }

    $self->{output}->output_add(
        severity  => 'OK',
        short_msg => 'List nodes:'
    );

    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['type', 'name', 'application_name', 'host_name', 'state']);
}

sub disco_show {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(%options);
    foreach (@$results) {
        $self->{output}->add_disco_entry(%$_);
    }
}

1;


=head1 MODE

List nodes.

=over 8

=back

=cut