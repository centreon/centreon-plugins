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

package apps::backup::veeam::vbem::restapi::mode::listrepositories;

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

    my $repositories = $options{custom}->get_repository(disable_cache => 1);

    my $results = [];
    foreach my $repo (@{$repositories->{Entities}->{Repositories}->{Repositories}}) {
        push @$results, { uid => $repo->{UID}, name => $repo->{Name} };
    }

    return $results;
}

sub run {
    my ($self, %options) = @_;

    my $repos = $self->manage_selection(%options);
    foreach (@$repos) {
        $self->{output}->output_add(
            long_msg => sprintf(
                '[uid: %s][name: %s]',
                $_->{uid},
                $_->{name}
            )
        );
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List repositories:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['uid', 'name']);
}

sub disco_show {
    my ($self, %options) = @_;

    my $repos = $self->manage_selection(%options);
    foreach (@$repos) {
        $self->{output}->add_disco_entry(%$_);
    }
}

1;

__END__

=head1 MODE

List repositories.

=over 8

=back

=cut
