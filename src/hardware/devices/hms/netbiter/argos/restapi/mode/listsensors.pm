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

package hardware::devices::hms::netbiter::argos::restapi::mode::listsensors;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "system-id:s" => { name => 'system_id' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!(defined($self->{option_results}->{system_id})) || $self->{option_results}->{system_id} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --system-id option.");
        $self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;
    return $options{custom}->list_sensors(system_id => $self->{option_results}->{system_id}, force => 1);
}

sub run {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(%options);
    foreach (@$results) {
        next if ($_->{pointType} ne 'R');
        $self->{output}->output_add(
        long_msg => sprintf(
            '[id: %s][name: %s][device name: %s][unit: %s][log interval: %s]',
            $_->{id},
            $_->{name},
            $_->{deviceName},
            $_->{unit},
            $_->{logInterval}
        ));
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List sensors:'
    );

    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['id', 'name', 'deviceName', 'unit', 'logInterval']);
}

sub disco_show {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(%options);
    foreach (@$results) {
        $self->{output}->add_disco_entry(
            deviceName  => $_->{deviceName},
            id          => $_->{id},
            logInterval => $_->{logInterval},
            name        => $_->{name},
            unit        => defined($_->{unit}) ? $_->{unit} : ''
        );
    }
}

1;

__END__

=head1 MODE

List Netbiter log sensors using Argos RestAPI.

=over 8

=item B<--system-id>

Set the Netbiter Argos System ID (mandatory).

=back

=cut