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

package apps::automation::ansible::cli::custom::cli;

use strict;
use warnings;
use JSON::XS;

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    if (!defined($options{output})) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    if (!defined($options{options})) {
        $options{output}->add_option_msg(short_msg => "Class Custom: Need to specify 'options' argument.");
        $options{output}->option_exit();
    }
    
    if (!defined($options{noptions})) {
        $options{options}->add_options(arguments => {
            'hostname:s'        => { name => 'hostname' },
            'remote'            => { name => 'remote' },
            'ssh-option:s@'     => { name => 'ssh_option' },
            'ssh-path:s'        => { name => 'ssh_path' },
            'ssh-command:s'     => { name => 'ssh_command', default => 'ssh' },
            'timeout:s'         => { name => 'timeout', default => 50 },
            'sudo'              => { name => 'sudo' },
            'command:s'         => { name => 'command', default => 'ANSIBLE_LOAD_CALLBACK_PLUGINS=true ANSIBLE_STDOUT_CALLBACK=json ansible' },
            'command-path:s'    => { name => 'command_path' },
            'command-options:s' => { name => 'command_options', default => '' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'CLI OPTIONS', once => 1);

    $self->{output} = $options{output};
    
    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    return 0;
}

sub execute {
    my ($self, %options) = @_;

    $self->{output}->output_add(long_msg => "Command line: '" . $self->{option_results}->{command} . " " . $options{cmd_options} . "'", debug => 1);
    
    my ($response) = centreon::plugins::misc::execute(
        output => $self->{output},
        options => $self->{option_results},
        sudo => $self->{option_results}->{sudo},
        command => $self->{option_results}->{command},
        command_path => $self->{option_results}->{command_path},
        command_options => $options{cmd_options},
        no_errors => { 4 => 1 }
    );

    my $raw_results;

    eval {
        $raw_results = JSON::XS->new->utf8->decode($response);
    };
    if ($@) {
        $self->{output}->output_add(long_msg => $response, debug => 1);
        $self->{output}->add_option_msg(short_msg => "Cannot decode response (add --debug option to display returned content)");
        $self->{output}->option_exit();
    }

    return $raw_results; 
}

sub ansible_list_hosts_set_cmd {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');
    
    my $cmd_options = "$options{host_pattern} --module-name=setup";
        
    return $cmd_options; 
}

sub ansible_list_hosts {
    my ($self, %options) = @_;

    my $cmd_options = $self->ansible_list_hosts_set_cmd(%options);
    my $raw_results = $self->execute(cmd_options => $cmd_options);
    
    return $raw_results;
}

1;

__END__

=head1 NAME

Ansible CLI

=head1 CLI OPTIONS

Ansible CLI

=over 8

=item B<--timeout>

Set timeout in seconds (Default: 50).

=item B<--sudo>

Use 'sudo' to execute the command.

=item B<--command>

Command to get information (Default: 'ANSIBLE_LOAD_CALLBACK_PLUGINS=true ANSIBLE_STDOUT_CALLBACK=json ansible').
Can be changed if you have output in a file.

=item B<--command-path>

Command path (Default: none).

=item B<--command-options>

Command options (Default: none).

=back

=head1 DESCRIPTION

B<custom>.

=cut
