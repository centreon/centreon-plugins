#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package cloud::kubernetes::custom::kubectl;

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
            "hostname:s"        => { name => 'hostname' },
            "port:s"            => { name => 'port' },
            "proto:s"           => { name => 'proto' },
            "token:s"           => { name => 'token' },
            "timeout:s"         => { name => 'timeout', default => 10 },
            "config-file:s"     => { name => 'config_file' },
            "sudo"              => { name => 'sudo' },
            "command:s"         => { name => 'command', default => 'kubectl' },
            "command-path:s"    => { name => 'command_path' },
            "command-options:s" => { name => 'command_options', default => '' },
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'CLI OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{mode} = $options{mode};

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {
    my ($self, %options) = @_;

    foreach (keys %{$options{default}}) {
        if ($_ eq $self->{mode}) {
            for (my $i = 0; $i < scalar(@{$options{default}->{$_}}); $i++) {
                foreach my $opt (keys %{$options{default}->{$_}[$i]}) {
                    if (!defined($self->{option_results}->{$opt}[$i])) {
                        $self->{option_results}->{$opt}[$i] = $options{default}->{$_}[$i]->{$opt};
                    }
                }
            }
        }
    }
}

sub check_options {
    my ($self, %options) = @_;

    $self->{config_file} = (defined($self->{option_results}->{config_file})) ? $self->{option_results}->{config_file} : '';
 
    if (!defined($self->{config_file}) || $self->{config_file} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --config-file option.");
        $self->{output}->option_exit();
    }
    
    return 0;
}

sub execute {
    my ($self, %options) = @_;

    $self->{output}->output_add(long_msg => "Command line: '" . $self->{option_results}->{command} . " " . $options{cmd_options} . "'", debug => 1);
    
    my ($response, $exit_code) = centreon::plugins::misc::execute(
        output => $self->{output},
        options => $self->{option_results},
        sudo => $self->{option_results}->{sudo},
        command => $self->{option_results}->{command},
        command_path => $self->{option_results}->{command_path},
        command_options => $options{cmd_options},
        no_quit => 1
    );

    if ($exit_code != 0) {
        $self->{output}->output_add(long_msg => "Error message: " . $response, debug => 1);
        $self->{output}->add_option_msg(short_msg => "CLI return error code '" . $exit_code . "' (add --debug option for detailed message)");
        $self->{output}->option_exit();
    }

    my $decoded;
    eval {
        $decoded = JSON::XS->new->utf8->decode($response);
    };
    if ($@) {
        $self->{output}->output_add(long_msg => $response, debug => 1);
        $self->{output}->add_option_msg(short_msg => "Cannot decode response (add --debug option to display returned content)");
        $self->{output}->option_exit();
    }

    return $decoded; 
}

sub kubernetes_list_daemonsets {
    my ($self, %options) = @_;

    my $response = $self->execute(cmd_options => 'get daemonsets --all-namespaces --output=json --kubeconfig ' . $self->{config_file});
    
    return $response;
}

sub kubernetes_list_deployments {
    my ($self, %options) = @_;

    my $response = $self->execute(cmd_options => 'get deployments --all-namespaces --output=json --kubeconfig ' . $self->{config_file});
    
    return $response;
}

sub kubernetes_list_ingresses {
    my ($self, %options) = @_;

    my $response = $self->execute(cmd_options => 'get ingresses --all-namespaces --output=json --kubeconfig ' . $self->{config_file});
    
    return $response;
}

sub kubernetes_list_namespaces {
    my ($self, %options) = @_;

    my $response = $self->execute(cmd_options => 'get namespaces --all-namespaces --output=json --kubeconfig ' . $self->{config_file});
    
    return $response;
}

sub kubernetes_list_nodes {
    my ($self, %options) = @_;

    my $response = $self->execute(cmd_options => 'get nodes --all-namespaces --output=json --kubeconfig ' . $self->{config_file});
    
    return $response;
}

sub kubernetes_list_replicasets {
    my ($self, %options) = @_;

    my $response = $self->execute(cmd_options => 'get replicasets --all-namespaces --output=json --kubeconfig ' . $self->{config_file});
    
    return $response;
}

sub kubernetes_list_services {
    my ($self, %options) = @_;

    my $response = $self->execute(cmd_options => 'get services --all-namespaces --output=json --kubeconfig ' . $self->{config_file});
    
    return $response;
}

sub kubernetes_list_statefulsets {
    my ($self, %options) = @_;

    my $response = $self->execute(cmd_options => 'get statefulsets --all-namespaces --output=json --kubeconfig ' . $self->{config_file});
    
    return $response;
}

sub kubernetes_list_pods {
    my ($self, %options) = @_;

    my $response = $self->execute(cmd_options => 'get pods --all-namespaces --output=json --kubeconfig ' . $self->{config_file});
    
    return $response;
}

1;

__END__

=head1 NAME

Kubernetes CLI (kubectl)

=head1 SYNOPSIS

Kubernetes CLI (kubectl) custom mode

=head1 CLI OPTIONS

Kubernetes CLI (kubectl)

=over 8

=item B<--config-file>

Kubernetes configuration file path
(Example: --config-file='/root/.kube/config').

=item B<--timeout>

Set timeout in seconds (Default: 10).

=item B<--sudo>

Use 'sudo' to execute the command.

=item B<--command>

Command to get information (Default: 'kubectl').
Can be changed if you have output in a file.

=item B<--command-path>

Command path (Default: none).

=item B<--command-options>

Command options (Default: none).

=back

=head1 DESCRIPTION

B<custom>.

=cut
