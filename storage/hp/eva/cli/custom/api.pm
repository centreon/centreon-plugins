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

package storage::hp::eva::cli::custom::api;

use strict;
use warnings;
use centreon::plugins::misc;
use XML::Simple;

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
            'manager-hostname:s' => { name => 'manager_hostname' },
            'manager-username:s' => { name => 'manager_username' },
            'manager-password:s' => { name => 'manager_password' },
            'manager-system:s'   => { name => 'manager_system' },
            'timeout:s'          => { name => 'timeout', default => 50 },
            'sudo'               => { name => 'sudo' },
            'command:s'          => { name => 'command', default => 'sssu_linux_x64' },
            'command-path:s'     => { name => 'command_path' },
            'command-options:s'  => { name => 'command_options', default => '' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'SSU CLI OPTIONS', once => 1);

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

    if (!defined($self->{option_results}->{manager_hostname}) || $self->{option_results}->{manager_hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to set manager-hostname option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{manager_username}) || $self->{option_results}->{manager_username} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to set manager-username option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{manager_password})) {
        $self->{output}->add_option_msg(short_msg => "Need to set manager-password option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{manager_system}) || $self->{option_results}->{manager_system} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to set manager-system option.");
        $self->{output}->option_exit();
    }

    return 0;
}

sub ssu_build_options {
    my ($self, %options) = @_;
    
    return if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');
    $self->{option_results}->{command_options} = 
        "'select manager \"$self->{option_results}->{manager_hostname}\" USERNAME=$self->{option_results}->{manager_username} PASSWORD=$self->{option_results}->{manager_password}' 'select system $self->{option_results}->{manager_system}'";
    foreach my $cmd (keys %{$options{commands}}) {
        $self->{option_results}->{command_options} .= " '$cmd'";
    }
}

sub ssu_execute {
    my ($self, %options) = @_;
    
    $self->ssu_build_options(%options);
    my ($response) = centreon::plugins::misc::execute(output => $self->{output},
                                                      options => $self->{option_results},
                                                      sudo => $self->{option_results}->{sudo},
                                                      command => $self->{option_results}->{command},
                                                      command_path => $self->{option_results}->{command_path},
                                                      command_options => $self->{option_results}->{command_options});
    my $xml_root = '<root>';
    while ($response =~ /(<object>.*?<\/object>)/msig) {
        $xml_root .= $1;
    }
    $xml_root .= '</root>';
    
    my $xml_result;
    eval {
        $xml_result = XMLin($xml_root, 
            ForceArray => ['object', 'diskslot', 'powersupply', 'sensor', 'fan', 'deviceport', 
                           'module', 'vdcoutput', 'source'],
            KeyAttr => [], SuppressEmpty => '');
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode xml response: $@");
        $self->{output}->option_exit();
    }
    
    $self->{output}->output_add(long_msg => $response, debug => 1);
    return $xml_result;
}

1;

__END__

=head1 NAME

SSU CLI

=head1 SYNOPSIS

ssu cli

=head1 SSU CLI OPTIONS

=over 8

=item B<--manager-hostname>

Manager hostname to query.

=item B<--manager-username>

Manager username.

=item B<--manager-password>

Manager password.

=item B<--manager-system>

Manager system.

=item B<--timeout>

Set timeout (Default: 50).

=item B<--sudo>

Use 'sudo' to execute the command.

=item B<--command>

Command to get information (Default: 'sssu_linux_x64').
Can be changed if you have output in a file.

=item B<--command-path>

Command path (Default: none).

=item B<--command-options>

Command options (Default: none).

=back

=head1 DESCRIPTION

B<custom>.

=cut
