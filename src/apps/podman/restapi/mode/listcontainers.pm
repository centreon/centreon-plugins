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

package apps::podman::restapi::mode::listcontainers;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments =>
                                   {
                                   });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;

    my $containers = $options{custom}->list_containers();
    foreach my $container_id (sort keys %{$containers}) {
        $self->{output}->output_add(long_msg => '[id = ' . $container_id . "]" .
                                                " [name = '" . $containers->{$container_id}->{Name} . "']" .
                                                " [pod = '" . $containers->{$container_id}->{PodName} . "']" .
                                                " [state = '" . $containers->{$container_id}->{State} . "']"
        );
    }

    $self->{output}->output_add(severity  => 'OK',
                                short_msg => 'Containers:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => [ 'id', 'name', 'pod', 'state' ]);
}

sub disco_show {
    my ($self, %options) = @_;

    my $containers = $options{custom}->list_containers();
    foreach my $container_id (sort keys %{$containers}) {
        $self->{output}->add_disco_entry(name  => $containers->{$container_id}->{Name},
                                         pod   => $containers->{$container_id}->{PodName},
                                         state => $containers->{$container_id}->{State},
                                         id    => $container_id,
        );
    }
}

1;

__END__

=head1 MODE

List containers.

=over 8

=back

=cut
    
