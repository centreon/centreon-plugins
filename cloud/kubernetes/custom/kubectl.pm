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
            'hostname:s'        => { name => 'hostname' },
            'port:s'            => { name => 'port' },
            'proto:s'           => { name => 'proto' },
            'token:s'           => { name => 'token' },
            'timeout:s'         => { name => 'timeout', default => 10 },
            'config-file:s'     => { name => 'config_file', default => '~/.kube/config' },
            'context:s'         => { name => 'context' },
            'sudo'              => { name => 'sudo' },
            'command:s'         => { name => 'command', default => 'kubectl' },
            'command-path:s'    => { name => 'command_path' },
            'command-options:s' => { name => 'command_options', default => '' },
            'proxyurl:s'        => { name => 'proxyurl' },
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

    $self->{config_file} = (defined($self->{option_results}->{config_file})) ? $self->{option_results}->{config_file} : '';
    $self->{context} = (defined($self->{option_results}->{context})) ? $self->{option_results}->{context} : '';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) && $self->{option_results}->{timeout} =~ /(\d+)/ ? $1 : 10;
 
    if (!defined($self->{config_file}) || $self->{config_file} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --config-file option.");
        $self->{output}->option_exit();
    }

    if ($self->{config_file} =~ /^~/) {
        centreon::plugins::misc::mymodule_load(
            output => $self->{output},
            module => 'File::HomeDir',
            error_msg => "Cannot load module 'File::HomeDir'."
        );
        my $home = File::HomeDir->my_home;
        $self->{config_file} =~ s/\~/$home/;
    }
    
    if (defined($self->{option_results}->{proxyurl}) && $self->{option_results}->{proxyurl} ne '') {
        $ENV{HTTP_PROXY} = $self->{option_results}->{proxyurl};
        $ENV{HTTPS_PROXY} = $self->{option_results}->{proxyurl};
    }
    
    return 0;
}

sub execute {
    my ($self, %options) = @_;

    my $cmd_options = $options{cmd_options};
    # See https://kubernetes.io/docs/reference/kubectl/cheatsheet/#kubectl-output-verbosity-and-debugging
    $cmd_options .= " --v='9'" if ($self->{output}->is_debug());

    $self->{output}->output_add(long_msg => "Command line: '" . $self->{option_results}->{command} . " " . $cmd_options . "'", debug => 1);
    
    my ($response, $exit_code) = centreon::plugins::misc::execute(
        output => $self->{output},
        options => $self->{option_results},
        sudo => $self->{option_results}->{sudo},
        command => $self->{option_results}->{command},
        command_path => $self->{option_results}->{command_path},
        command_options => $cmd_options,
        redirect_stderr => ($self->{output}->is_debug()) ? 0 : 1,
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

    return $decoded->{items}; 
}

sub kubernetes_list_cronjobs {
    my ($self, %options) = @_;

    my $cmd = "get cronjobs --all-namespaces --output='json' --kubeconfig='" . $self->{config_file} . "'"
        . " --request-timeout='" . $self->{timeout} . "'";
    $cmd .= " --context='" . $self->{context} . "'" if (defined($self->{context}) && $self->{context} ne '');

    my $response = $self->execute(cmd_options => $cmd);
    
    return $response;
}

sub kubernetes_list_daemonsets {
    my ($self, %options) = @_;

    my $cmd = "get daemonsets --all-namespaces --output='json' --kubeconfig='" . $self->{config_file} . "'"
        . " --request-timeout='" . $self->{timeout} . "'";
    $cmd .= " --context='" . $self->{context} . "'" if (defined($self->{context}) && $self->{context} ne '');

    my $response = $self->execute(cmd_options => $cmd);
    
    return $response;
}

sub kubernetes_list_deployments {
    my ($self, %options) = @_;

    my $cmd = "get deployments --all-namespaces --output='json' --kubeconfig='" . $self->{config_file} . "'"
        . " --request-timeout='" . $self->{timeout} . "'";
    $cmd .= " --context='" . $self->{context} . "'" if (defined($self->{context}) && $self->{context} ne '');

    my $response = $self->execute(cmd_options => $cmd);
    
    return $response;
}

sub kubernetes_list_events {
    my ($self, %options) = @_;

    my $cmd = "get events --all-namespaces --output='json' --kubeconfig='" . $self->{config_file} . "'"
        . " --request-timeout='" . $self->{timeout} . "'";
    $cmd .= " --context='" . $self->{context} . "'" if (defined($self->{context}) && $self->{context} ne '');

    my $response = $self->execute(cmd_options => $cmd);
    
    return $response;
}

sub kubernetes_list_namespaces {
    my ($self, %options) = @_;

    my $cmd = "get namespaces --all-namespaces --output='json' --kubeconfig='" . $self->{config_file} . "'"
        . " --request-timeout='" . $self->{timeout} . "'";
    $cmd .= " --context='" . $self->{context} . "'" if (defined($self->{context}) && $self->{context} ne '');

    my $response = $self->execute(cmd_options => $cmd);
    
    return $response;
}

sub kubernetes_list_nodes {
    my ($self, %options) = @_;

    my $cmd = "get nodes --all-namespaces --output='json' --kubeconfig='" . $self->{config_file} . "'"
        . " --request-timeout='" . $self->{timeout} . "'";
    $cmd .= " --context='" . $self->{context} . "'" if (defined($self->{context}) && $self->{context} ne '');

    my $response = $self->execute(cmd_options => $cmd);

    return $response;
}

sub kubernetes_list_rcs {
    my ($self, %options) = @_;

    my $cmd = "get replicationcontroller --all-namespaces --output='json' --kubeconfig='" . $self->{config_file} . "'"
        . " --request-timeout='" . $self->{timeout} . "'";
    $cmd .= " --context='" . $self->{context} . "'" if (defined($self->{context}) && $self->{context} ne '');

    my $response = $self->execute(cmd_options => $cmd);
    
    return $response;
}

sub kubernetes_list_replicasets {
    my ($self, %options) = @_;

    my $cmd = "get replicasets --all-namespaces --output='json' --kubeconfig='" . $self->{config_file} . "'"
        . " --request-timeout='" . $self->{timeout} . "'";
    $cmd .= " --context='" . $self->{context} . "'" if (defined($self->{context}) && $self->{context} ne '');

    my $response = $self->execute(cmd_options => $cmd);
    
    return $response;
}

sub kubernetes_list_services {
    my ($self, %options) = @_;

    my $cmd = "get services --all-namespaces --output='json' --kubeconfig='" . $self->{config_file} . "'"
        . " --request-timeout='" . $self->{timeout} . "'";
    $cmd .= " --context='" . $self->{context} . "'" if (defined($self->{context}) && $self->{context} ne '');

    my $response = $self->execute(cmd_options => $cmd);
    
    return $response;
}

sub kubernetes_list_statefulsets {
    my ($self, %options) = @_;

    my $cmd = "get statefulsets --all-namespaces --output='json' --kubeconfig='" . $self->{config_file} . "'"
        . " --request-timeout='" . $self->{timeout} . "'";
    $cmd .= " --context='" . $self->{context} . "'" if (defined($self->{context}) && $self->{context} ne '');

    my $response = $self->execute(cmd_options => $cmd);
    
    return $response;
}

sub kubernetes_list_pods {
    my ($self, %options) = @_;

    my $cmd = "get pods --all-namespaces --output='json' --kubeconfig='" . $self->{config_file} . "'"
        . " --request-timeout='" . $self->{timeout} . "'";
    $cmd .= " --context='" . $self->{context} . "'" if (defined($self->{context}) && $self->{context} ne '');

    my $response = $self->execute(cmd_options => $cmd);
    
    return $response;
}

sub kubernetes_list_pvs {
    my ($self, %options) = @_;

    my $cmd = "get pv --all-namespaces --output='json' --kubeconfig='" . $self->{config_file} . "'"
        . " --request-timeout='" . $self->{timeout} . "'";
    $cmd .= " --context='" . $self->{context} . "'" if (defined($self->{context}) && $self->{context} ne '');

    my $response = $self->execute(cmd_options => $cmd);
    
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

Kubernetes configuration file path (Default: '~/.kube/config').
(Example: --config-file='/root/.kube/config').

=item B<--context>

Context to use in configuration file.

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

=item B<--proxyurl>

Proxy URL if any

=back

=head1 DESCRIPTION

B<custom>.

=cut
