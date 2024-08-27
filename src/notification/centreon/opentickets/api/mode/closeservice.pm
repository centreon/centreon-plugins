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

package notification::centreon::opentickets::api::mode::closeservice;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'rule-name:s'           => { name => 'rule_name' },
        'host-id:s'             => { name => 'host_id' },
        'service-id:s'          => { name => 'service_id' }
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
}

sub run {
    my ($self, %options) = @_;

    my $response = $options{custom}->request_api(
        action => 'closeService',
        data => {
            rule_name      => $self->{option_results}->{rule_name},
            host_id        => $self->{option_results}->{host_id},
            service_id     => $self->{option_results}->{service_id}
        }
    );

    $self->{output}->output_add(short_msg => $response->{message});
    $self->{output}->display(force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Close a service ticket.

=over 8

=item B<--rule-name>

Rule name used (required).

=item B<--host-id>

Centreon host ID (required).

=item B<--service-id>

Centreon service ID (required).

=back

=cut
