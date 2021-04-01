#
# Copyright 2021 Centreon (http://www.centreon.com/)
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

package apps::monitoring::mip::restapi::mode::listscenarios;

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

    my $api_results = $options{custom}->request_api(
        url_path => '/api/measures/?type=ASA_DESKTOP&engineActivated=true&fields=name,alias,displayName,frequency,scenario.name,scenario.application.name,timeout,agent.id,agent.name,activated,engineActivated&limit=-1'
    );
    my $results = {};
    foreach (@{$api_results->{results}}) {
        $results->{$_->{id}} = {
            id => $_->{id},
            name => $_->{name},
            alias => $_->{alias},
            display_name => $_->{displayName},
            app_name => defined($_->{scenario}->{application}->{name}) ? $_->{scenario}->{application}->{name} : '-',
        };
    }

    return $results;
}

sub run {
    my ($self, %options) = @_;

    my $scenarios = $self->manage_selection(%options);
    foreach (sort {lc $a->{name} cmp lc $b->{name}} values %$scenarios) {
        $self->{output}->output_add(long_msg => sprintf(
            '[name = %s][id = %s][alias = %s][display_name = %s][app_name = %s]',
            $_->{name},
            $_->{id},
            $_->{alias},
            $_->{display_name},
            $_->{app_name}
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

    $self->{output}->add_disco_format(elements => ['id', 'name', 'alias', 'display_name', 'app_name']);
}

sub disco_show {
    my ($self, %options) = @_;

    my $scenarios = $self->manage_selection(%options);
    foreach (sort {lc $a->{name} cmp lc $b->{name}} values %$scenarios) {
        $self->{output}->add_disco_entry(%$_);
    }
}

1;

__END__

=head1 MODE

List scenarios.

=over 8

=back

=cut
