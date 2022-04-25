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
# Authors : Roman Morandell - ivertix
#

package notification::centreon::opentickets::api::mode::openservice;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'provider-name:s'  => { name => 'provider_name' },
        'host-id:s'        => { name => 'host_id' },
        'service-id:s'     => { name => 'service_id' },
        'service-output:s' => { name => 'service_output' },
        'service-state:s'  => { name => 'service_state' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{provider_name}) || $self->{option_results}->{provider_name} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Set --provider-name option');
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{host_id}) || $self->{option_results}->{host_id} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Set --host-id option');
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{service_id}) || $self->{option_results}->{service_id} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Set --service-id option');
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{service_state}) || $self->{option_results}->{service_state} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Set --service-state option');
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{service_output})) {
        $self->{output}->add_option_msg(short_msg => 'Set --service-output option');
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;

    my $response = $options{custom}->request_api(
        action => 'openService',
        data => {
            provider_name  => $self->{option_results}->{provider_name},
            host_id        => $self->{option_results}->{host_id},
            service_id     => $self->{option_results}->{service_id},
            service_state  => $self->{option_results}->{service_state},
            service_output => $self->{option_results}->{service_output},
        }
    );

    $self->{output}->output_add(short_msg => 'open-ticket response: ' . $response);
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Open a service ticket.

=over 8

=item B<--provider-name>

Provider name used (Required).

=item B<--host-id>

Centreon host ID (Required).

=item B<--service-id>

Centreon service ID (Required).

=item B<--service-state>

Service state (Eg: CRITICAL, UNKNOWN, WARNING, OK) (Required).

=item B<--service-output>

Service output (Required).

=back

=cut
