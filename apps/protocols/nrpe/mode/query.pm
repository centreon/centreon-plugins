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

package apps::protocols::nrpe::mode::query;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'command:s'          => { name => 'command' },
        'arg:s@'             => { name => 'arg' },
        'sanitize-message:s' => { name => 'sanitize_message' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{command}) || $self->{option_results}->{command} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Please set --command option');
        $self->{output}->option_exit();
    }
}

sub sanitize_message {
    my ($self, %options) = @_;

    $self->{display_options}->{nolabel} = 1;
    return $options{message} unless (defined($self->{option_results}->{sanitize_message}));

    my $message = $options{message};
    foreach my $code (('OK', 'WARNING', 'CRITICAL', 'UNKNOWN')) {
        foreach my $separator (('-', ':')) {
            if ($message =~ /^\w+\s*$code\s*$separator\s*(.*)$/) {
                delete $self->{display_options}->{nolabel};
                return $1;
            }
        }
    }
    return $message;
}

sub run {
    my ($self, %options) = @_;
    
    my $result = $options{custom}->request(
        command => $self->{option_results}->{command},
        arg => $self->{option_results}->{arg}
    );
    
    $self->{output}->output_add(
        severity => $result->{code},
        short_msg => $self->sanitize_message(message => $result->{message})
    );

    foreach (@{$result->{perf}}) {
        $self->{output}->perfdata_add(%{$_});
    }
    $self->{display_options}->{force_ignore_perfdata} = 1 if (scalar(@{$result->{perf}}) == 0);
    
    $self->{output}->display(%{$self->{display_options}});
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Trigger commands against NRPE/NSClient agent.

=item B<--command>

Set command.
In nrpe use following command to get server version: --command='_NRPE_CHECK'

=item B<--arg>

Set arguments (Multiple option. Example: --arg='arg1' --arg='arg2').

=item B<--sanitize-message>

Sanitize message by removing heading code and
separator from returned message (ie "OK - ").

=back

=cut
