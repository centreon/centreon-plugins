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

package os::windows::wsman::custom::omicli;

use strict;
use warnings;
use centreon::plugins::misc;
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
            'hostname:s'            => { name => 'hostname' },
            'wsman-auth-method:s'   => { name => 'wsman_auth_method', default => 'Basic' },
            'wsman-username:s'      => { name => 'wsman_username' },
            'wsman-password:s'      => { name => 'wsman_password' },
            'wsman-port:s'          => { name => 'wsman_port', default => 5985},
            'wsman-scheme:s'        => { name => 'wsman_scheme', dafault => 'http' },
            'timeout:s'             => { name => 'timeout', default => 50 },
            'sudo'                  => { name => 'sudo' },
            'command:s'             => { name => 'command' },
            'command-path:s'        => { name => 'command_path' },
            'command-options:s'     => { name => 'command_options' }

        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'OMICLI OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{custommode_name} = $options{custommode_name};

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {
    my ($self, %options) = @_;

    foreach (keys %{$options{default}}) {
        if ($_ eq $self->{custommode_name}) {
            if (ref($options{default}->{$_}) eq 'ARRAY') {
                for (my $i = 0; $i < scalar(@{$options{default}->{$_}}); $i++) {
                    foreach my $opt (keys %{$options{default}->{$_}[$i]}) {
                        if (!defined($self->{option_results}->{$opt}[$i])) {
                            $self->{option_results}->{$opt}[$i] = $options{default}->{$_}[$i]->{$opt};
                        }
                    }
                }
            }
            
            if (ref($options{default}->{$_}) eq 'HASH') {
                foreach my $opt (keys %{$options{default}->{$_}}) {
                    if (!defined($self->{option_results}->{$opt})) {
                        $self->{option_results}->{$opt} = $options{default}->{$_}->{$opt};
                    }
                }
            }
        }
    }  
}

sub check_options {
    my ($self, %options) = @_;

    centreon::plugins::misc::check_security_command(
        output => $self->{output},
        command => $self->{option_results}->{command},
        command_options => $self->{option_results}->{command_options},
        command_path => $self->{option_results}->{command_path}
    );

    return 0;
}

sub execute {
    my ($self, %options) = @_;

    my $command = defined($self->{option_results}->{command}) && $self->{option_results}->{command} ne '' ? $self->{option_results}->{command} : 'omicli';
    my $command_path = defined($self->{option_results}->{command_path}) && $self->{option_results}->{command_path} ne '' ? $self->{option_results}->{command_path} : '/opt/omi/bin';

    my $cmd_options = $options{cmd_options};
    $cmd_options .= " --debug" if ($self->{output}->is_debug());

    $self->{output}->output_add(long_msg => "Command line: '" . $command . " " . $cmd_options . "'", debug => 1);

    my ($response) = centreon::plugins::misc::execute(
        output => $self->{output},
        options => $self->{option_results},
        sudo => $self->{option_results}->{sudo},
        command => $command,
        command_path => $command_path,
        command_options => $cmd_options,
        redirect_stderr => ($self->{output}->is_debug()) ? 0 : 1
    );

    my %response_hash;
    my $raw_results;
    my @array_results;

    while ($response =~ m/(\w+)=(.*)/g) {
        $response_hash{$1} = $2;
    }
    
    eval {
        push @array_results, \%response_hash if (%response_hash ne '');
        $raw_results = JSON::XS->new->utf8->encode(\@array_results);
    };
    use Data::Dumper;
    #print Dumper($raw_results);
    if ($@) {
        $self->{output}->output_add(long_msg => $response, debug => 1);
        $self->{output}->add_option_msg(short_msg => "Cannot decode response (add --debug option to display returned content)");
        $self->{output}->option_exit();
    }

    return $raw_results;
}

sub wmi_request_set_cmd {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');

    my $cmd_options = "wql root/cimv2 \"$options{wql}\" --auth $self->{option_results}->{wsman_auth_method} --hostname $self->{option_results}->{hostname}" .
        " -u $self->{option_results}->{wsman_username} -p $self->{option_results}->{wsman_password} --port $self->{option_results}->{wsman_port} --encryption $self->{option_results}->{wsman_scheme}";
    $cmd_options .= " $self->{option_results}->{command_options}" if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');

    return $cmd_options;
}

sub wmi_request {
    my ($self, %options) = @_;

    my $metric_results = {};

    my $cmd_options = $self->wmi_request_set_cmd(%options);
    my $raw_results = $self->execute(cmd_options => $cmd_options);

    return $raw_results;
}

1;