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

package apps::automation::ansible::cli::custom::cli;

use base qw(centreon::plugins::script_custom::cli);

use strict;
use warnings;
use JSON::XS;

sub execute_command {
    my ($self, %options) = @_;

    my ($stdout, $exit_code) = $self->SUPER::execute_command(
        %options,
        no_quit => 1
    );
    if ($exit_code != 0 && $exit_code != 4) {
        $self->{output}->add_option_msg(short_msg => "Command error: $stdout");
        $self->{output}->option_exit();
    }

    my $raw_results;
    eval {
        $raw_results = JSON::XS->new->utf8->decode($stdout);
    };
    if ($@) {
        $self->{output}->output_add(long_msg => $stdout, debug => 1);
        $self->{output}->add_option_msg(short_msg => "Cannot decode response (add --debug option to display returned content)");
        $self->{output}->option_exit();
    }

    return $raw_results; 
}

1;

__END__

=head1 NAME

Ansible CLI

=head1 CLI OPTIONS

Ansible CLI

=head1 DESCRIPTION

B<custom>.

=cut
