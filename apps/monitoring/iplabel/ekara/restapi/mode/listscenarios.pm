#
# Copyright 2022 Centreon (http://www.centreon.com/)
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

package apps::monitoring::iplabel::ekara::restapi::mode::listscenarios;

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

sub manage_selection {
    my ($self, %options) = @_;

    my $body_options = {};
    return $options{custom}->request_api(endpoint => '/results-api/scenarios/status', method => 'GET', query_form_post => $body_options);
}

sub run {
    my ($self, %options) = @_;

    my $instances = $self->manage_selection(%options);
    foreach (@$instances) {
        $self->{output}->output_add(long_msg => sprintf(
            '[name = %s][id = %s][status = %s][start_time = %s]',
                $_->{scenarioName},
                $_->{scenarioId},
                $_->{currentStatus},
                $_->{startTime}
        ));
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List scenarios:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements =>
    ['id', 'name', 'status', 'start_time']
    );
}

sub disco_show {
    my ($self, %options) = @_;

    my $instances = $self->manage_selection(%options);
    foreach (@$instances) {
        $self->{output}->add_disco_entry(
            name       => $_->{scenarioName},
            id         => $_->{scenarioId},
            status     => $_->{currentStatus},
            start_time => $_->{startTime}
        );
    }
}


1;

__END__

=head1 MODE

List IP Label Ekara scenarios.

=over 8

=back

=cut
