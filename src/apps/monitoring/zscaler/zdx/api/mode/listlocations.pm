#
# Copyright 2025-Present Centreon (http://www.centreon.com/)
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

package apps::monitoring::zscaler::zdx::api::mode::listlocations;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['name', 'id']);
}

sub disco_show {
    my ($self, %options) = @_;

    my $results = $options{custom}->get_locations(%options);

    foreach my $result (@$results) {
        $self->{output}->add_disco_entry(
            id => $result->{id},
            name => $result->{name}
        );
    }
}

sub run {
    my ($self, %options) = @_;

    my $results = $options{custom}->get_locations(%options);
    foreach my $location (sort { $a->{name} cmp $b->{name}} @$results) {
        $self->{output}->output_add(
            long_msg => sprintf(
                '[id: %s] [name: %s]',
                $location->{id},
                $location->{name}
            )
        );
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List apps'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check storages usage.

=over 8



=back

=cut
