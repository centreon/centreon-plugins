#
# Copyright 2026 Centreon (http://www.centreon.com/)
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

package apps::centreon::dem::restapi::mode::listuserjourneys;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'site-id:s' => { name => 'site_id', default => '' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if ($self->{option_results}->{site_id} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --site-id option.");
        $self->{output}->option_exit();
    }

    $self->{site_id} = $self->{option_results}->{site_id};
}

sub manage_selection {
    my ($self, %options) = @_;
    $self->{results} = $options{custom}->list_objects(
        type => 'journeys',
        site_id => $self->{site_id}
    );
}

sub run {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $user_journey (@{$self->{results}->{user_journeys}}){
        $self->{output}->output_add(
            long_msg => sprintf("[name: %s][id: %s]", 
                $user_journey->{name},
                $user_journey->{id},
            )
        );
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'User journeys:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['name', 'id']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);

    foreach my $user_journey (@{$self->{results}->{user_journeys}}){
        $self->{output}->add_disco_entry( 
            id   => $user_journey->{id},
            name => $user_journey->{name}
        );
    }
}

1;

__END__

=head1 MODE

List Centreon DEM (formerly Quanta) user journeys for a given site.

=over 8

=item B<--site-id>

Set ID of the site (mandatory option).

=back

=cut
