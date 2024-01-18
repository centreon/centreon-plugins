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

package network::cisco::standard::ssh::custom::custom;

use base qw(centreon::plugins::script_custom::cli);

use strict;
use warnings;

sub execute_command {
    my ($self, %options) = @_;

    my $append = '';
    foreach (@{$options{commands}}) {
       $options{command} .= $append . " $_"; 
       $append = "\n";
    }

    my ($stdout) = $self->SUPER::execute_command(%options, ssh_pipe => 1,);
    $stdout =~ s/\r//mg;

    return $stdout;
}

1;

__END__

=head1 NAME

ssh

=head1 SYNOPSIS

my ssh

=head1 CLI OPTIONS

=over 8

=item B<--hostname>

Hostname to query.

=item B<--timeout>

Timeout in seconds for the command (default: 45). Default value can be override by the mode.

=item B<--command>

Command to get information. Used it you have output in a file.

=item B<--command-path>

Command path.

=item B<--command-options>

Command options.

=item B<--sudo>

sudo command.

=back

=head1 DESCRIPTION

B<custom>.

=cut
