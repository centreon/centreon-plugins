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

package os::as400::connector::mode::command;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "command '%s' status: %s",
        $self->{result_values}->{command_name},
        $self->{result_values}->{status}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', cb_prefix_output => 'prefix_global_output', type => 0, skipped_code => { -10 => 1 }  }
    ];

    $self->{maps_counters}->{global} = [
        {
            label => 'status',
            type => 2,
            critical_default => '%{status} =~ /failed/i',
            set => {
                key_values => [ { name => 'status' }, { name => 'command_name' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'command-name:s' => { name => 'command_name' }
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{command_name}) || $self->{option_results}->{command_name} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --command-name option');
        $self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $infos = $options{custom}->request_api(command => 'executeCommand', args => { cmdName => $self->{option_results}->{command_name} });

    $self->{global} = {
        status => $infos->{result}->[0]->{status},
        command_name => $self->{option_results}->{command_name}
    };
    if (defined($infos->{result}->[0]->{output}) && $infos->{result}->[0]->{output} ne '') {
        $self->{output}->output_add(
            long_msg => sprintf(
                'command output: %s',
                $infos->{result}->[0]->{output}
            )
        );
    }
}

1;

__END__

=head1 MODE

Execute command and check result.

=over 8

=item B<--command-name>

Specify the command to execute (required).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{status}, %{name}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{status}, %{name}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} =~ /failed/i').
You can use the following variables: %{status}, %{name}

=back

=cut
