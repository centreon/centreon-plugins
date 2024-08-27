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

package notification::centreon::opentickets::api::mode::openservice;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'rule-name:s'           => { name => 'rule_name' },
        'contact-name:s'        => { name => 'contact_name' },
        'contact-alias:s'       => { name => 'contact_alias' },
        'contact-email:s'       => { name => 'contact_email' },
        'host-id:s'             => { name => 'host_id' },
        'host-name:s'           => { name => 'host_name' },
        'host-alias:s'          => { name => 'host_alias' },
        'service-id:s'          => { name => 'service_id' },
        'service-description:s' => { name => 'service_description' },
        'service-output:s'      => { name => 'service_output' },
        'service-state:s'       => { name => 'service_state' },
        'last-service-state-change:s' => { name => 'last_service_state_change' },
        'extra-property:s%'           => { name => 'extra_property' },
        'select:s%'                   => { name => 'select' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{rule_name}) || $self->{option_results}->{rule_name} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Set --rule-name option');
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

    my $extra_properties = {};
    foreach (keys %{$self->{option_results}->{extra_property}}) {
        $extra_properties->{$_} = $self->{option_results}->{extra_property}->{$_};
    }

    my $select = {};
    foreach (keys %{$self->{option_results}->{select}}) {
        $select->{$_} = $self->{option_results}->{select}->{$_};
    }

    my $properties = {};
    foreach ('contact_name', 'contact_alias', 'contact_email', 'host_name', 'host_alias', 'service_description', 'last_service_state_change') {
        if (defined($self->{option_results}->{$_}) && $self->{option_results}->{$_} ne '') {
            $properties->{$_} = $self->{option_results}->{$_};
        }
    }

    my $response = $options{custom}->request_api(
        action => 'openService',
        data => {
            rule_name      => $self->{option_results}->{rule_name},
            host_id        => $self->{option_results}->{host_id},
            service_id     => $self->{option_results}->{service_id},
            service_state  => $self->{option_results}->{service_state},
            service_output => $self->{option_results}->{service_output},
            extra_properties => $extra_properties,
            select => $select,
            %$properties
        }
    );

    $self->{output}->output_add(short_msg => $response->{message});
    $self->{output}->display(force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Open a service ticket.

=over 8

=item B<--rule-name>

Rule name used (required).

=item B<--host-id>

Centreon host ID (required).

=item B<--service-id>

Centreon service ID (required).

=item B<--service-state>

Service state (example: CRITICAL, UNKNOWN, WARNING, OK) (required).

=item B<--service-output>

Service output (required).

=item B<--contact-name>

Contact name (default: --api-username contact information).

=item B<--contact-alias>

Contact alias (default: --api-username contact information).

=item B<--contact-email>

Contact email (default: --api-username contact information).

=item B<--host-name>

Host name.

=item B<--host-alias>

Host alias.

=item B<--service-description>

Service description.

=item B<--last-service-state-change>

Last service state change.

=item B<--extra-property>

Add a extra property.
Example: --extra-property='custom_message=test my message'

=item B<--select>

Add a select property (open-ticket list).
Example: --select='list-id=value'

=back

=cut
