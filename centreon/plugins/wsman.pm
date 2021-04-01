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

package centreon::plugins::wsman;

use strict;
use warnings;
use openwsman;
use MIME::Base64;

my %auth_method_map = (
    noauth          => $openwsman::NO_AUTH_STR,
    basic           => $openwsman::BASIC_AUTH_STR,
    digest          => $openwsman::DIGEST_AUTH_STR,
    pass            => $openwsman::PASS_AUTH_STR,
    ntlm            => $openwsman::NTLM_AUTH_STR,
    gssnegotiate    => $openwsman::GSSNEGOTIATE_AUTH_STR,
);

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;
    # $options{options} = options object
    # $options{output} = output object
    # $options{exit_value} = integer
    
    if (!defined($options{output})) {
        print "Class wsman: Need to specify 'output' argument.\n";
        exit 3;
    }
    if (!defined($options{options})) {
        $options{output}->add_option_msg(short_msg => "Class wsman: Need to specify 'options' argument.");
        $options{output}->option_exit();
    }

    $options{options}->add_options(arguments => 
                { "hostname|host:s"           => { name => 'host' },
                  "wsman-port:s"              => { name => 'wsman_port', default => 5985 },
                  "wsman-path:s"              => { name => 'wsman_path', default => '/wsman' },
                  "wsman-scheme:s"            => { name => 'wsman_scheme', default => 'http' },
                  "wsman-username:s"          => { name => 'wsman_username' },
                  "wsman-password:s"          => { name => 'wsman_password' },
                  "wsman-timeout:s"           => { name => 'wsman_timeout', default => 30 },
                  "wsman-proxy-url:s"         => { name => 'wsman_proxy_url', },
                  "wsman-proxy-username:s"    => { name => 'wsman_proxy_username', },
                  "wsman-proxy-password:s"    => { name => 'wsman_proxy_password', },
                  "wsman-debug"               => { name => 'wsman_debug', },
                  "wsman-auth-method:s"       => { name => 'wsman_auth_method', default => 'basic' },
                  "wsman-errors-exit:s"       => { name => 'wsman_errors_exit', default => 'unknown' },
    });
    $options{options}->add_help(package => __PACKAGE__, sections => 'WSMAN OPTIONS');

    #####
    $self->{client} = undef;
    $self->{output} = $options{output};
    $self->{wsman_params} = {};

    $self->{error_msg} = undef;
    $self->{error_status} = 0;
    
    return $self;
}

sub connect {
    my ($self, %options) = @_;

    if (!$self->{output}->is_litteral_status(status => $self->{wsman_errors_exit})) {
        $self->{output}->add_option_msg(short_msg => "Unknown value '" . $self->{wsman_errors_exit}  . "' for --wsman-errors-exit.");
        $self->{output}->option_exit(exit_litteral => 'unknown');
    }
    
    openwsman::set_debug(1) if (defined($self->{wsman_params}->{wsman_debug}));
    $self->{client} = new openwsman::Client::($self->{wsman_params}->{host}, $self->{wsman_params}->{wsman_port}, 
                                              $self->{wsman_params}->{wsman_path}, $self->{wsman_params}->{wsman_scheme},
                                              $self->{wsman_params}->{wsman_username}, $self->{wsman_params}->{wsman_password});
    if (!defined($self->{client})) {
        $self->{output}->add_option_msg(short_msg => 'Could not create client handler');
        $self->{output}->option_exit(exit_litteral => $self->{wsman_errors_exit});
    }
    
    if ($self->{wsman_params}->{wsman_scheme} eq 'https') {
        # Dont verify
        $self->{client}->transport()->set_verify_peer(0);
        $self->{client}->transport()->set_verify_host(0);
    }
    
    $self->{client}->transport()->set_auth_method($auth_method_map{$self->{wsman_params}->{wsman_auth_method}});
    $self->{client}->transport()->set_timeout($self->{wsman_params}->{wsman_timeout});
    if (defined($self->{wsman_params}->{wsman_proxy_url})) {
        $self->{client}->transport()->set_proxy($self->{wsman_params}->{wsman_proxy_url});
        if (defined($self->{wsman_params}->{wsman_proxy_username}) && defined($self->{wsman_params}->{wsman_proxy_password})) {
            $self->{client}->transport()->set_proxyauth($self->{wsman_params}->{wsman_proxy_username} . ':' . $self->{wsman_params}->{wsman_proxy_password});
        }
    }
}

sub execute_winshell_commands {
    my ($self, %options) = @_;
    # $options{keep_open} = integer
    # $options{commands} = ref array of hash ([{label => 'myipconfig', value => 'ipconfig /all' }])

    my ($dont_quit) = (defined($options{dont_quit}) && $options{dont_quit} == 1) ? 1 : 0;
    $self->set_error();
    
    my $uri = 'http://schemas.microsoft.com/wbem/wsman/1/windows/shell/cmd';
    my $namespace = 'http://schemas.microsoft.com/wbem/wsman/1/windows/shell';
    my $command_result = {};
    my ($command_id, $client_options, $data, $result, $node);
    
    # Init result
    foreach my $command (@{$options{commands}}) {
        $command_result->{$command->{label}} = {stdout => undef, stderr => undef, exit_code => undef};
    }
    
    if (!defined($self->{shell_id})) { 
        $self->{shell_id} = undef;
    
        ######
        # Start Shell
        $client_options = new openwsman::ClientOptions::() 
                                            or $self->internal_exit(msg => 'Could not create client options handler');
        $client_options->set_timeout(30 * 1000); # 30sec
        $client_options->add_selector('Name', 'Themes');
        $client_options->add_option('WINRS_NOPROFILE', 'FALSE');
        $client_options->add_option('WINRS_CODEPAGE', '437'); # utf-8
    
        $data = new openwsman::XmlDoc::('Shell', $namespace)
                                            or $self->internal_exit(msg => 'Could not create XmlDoc');
        $data->root()->add($namespace, 'InputStreams', 'stdin');
        $data->root()->add($namespace, 'OutputStreams', 'stdout stderr');

        $result = $self->{client}->create($client_options, $uri, $data->string(), length($data->string()), "utf-8");
        return undef if ($self->handle_dialog_fault(result => $result, msg => 'Create failed: ', dont_quit => $dont_quit));
        $node = $result->root()->find(undef, 'Selector')
                                            or $self->internal_exit(msg => 'No shell id returned');
        $self->{shell_id} = $node->text();
    }
    
    foreach my $command (@{$options{commands}}) {
        #######
        # Issue command
        $client_options = new openwsman::ClientOptions::()
                                                or $self->internal_exit(msg => 'Could not create client options handler');
        $client_options->set_timeout(30 * 1000); # 30sec
        $client_options->add_option('WINRS_CONSOLEMODE_STDIN', 'TRUE');
        $client_options->add_option('WINRS_SKIP_CMD_SHELL', 'FALSE');
        $client_options->add_selector('ShellId', $self->{shell_id});
        $data = new openwsman::XmlDoc::('CommandLine', $namespace)
                                                or $self->internal_exit(msg => 'Could not create XmlDoc');
        $data->root()->add($namespace, 'Command', $command->{value});

        $result = $self->{client}->invoke($client_options, $uri, 'http://schemas.microsoft.com/wbem/wsman/1/windows/shell/Command',
                                          $data);
        return undef if ($self->handle_dialog_fault(result => $result, msg => 'Invoke failed: ', dont_quit => $dont_quit));

        $node = $result->root()->find(undef, 'CommandId')
                                                or $self->internal_exit(msg => 'No command id returned');
        $command_id = $node->text();
        
        #######
        # Request stdout/stderr
        $client_options = new openwsman::ClientOptions::()
                                                or $self->internal_exit(msg => 'Could not create client options handler');
        $client_options->set_timeout(30 * 1000); # 30sec
        $client_options->add_selector('ShellId', $self->{shell_id});

        $data = new openwsman::XmlDoc::('Receive', $namespace);
        $node = $data->root()->add($namespace, 'DesiredStream', 'stdout stderr')
                                                or $self->internal_exit(msg => 'Could not create XmlDoc');
        $node->attr_add(undef, 'CommandId', $command_id);
        
        my $timeout_global = 30; #seconds
        my $wait_timeout_done = 0;
        my $loop_out = 1;
        my ($current_stdout, $current_stderr) = ('', '');
        
        while ($loop_out == 1 && $wait_timeout_done < $timeout_global) {
            
        
            $result = $self->{client}->invoke($client_options, $uri, 'http://schemas.microsoft.com/wbem/wsman/1/windows/shell/Receive',
                                            $data);
            return undef if ($self->handle_dialog_fault(result => $result, msg => 'Invoke failed: ', dont_quit => $dont_quit));
            my $response = $result->root()->find($namespace, 'ReceiveResponse')
                                                    or $self->internal_exit(msg => 'No ReceiveResponse');
            ######
            # Parsing Reponse
            for (my $cnt = 0; $cnt < $response->size(); $cnt++) {
                my $node = $response->get($cnt);
                my $node_command = $node->attr_find(undef, 'CommandId')
                                                    or $self->internal_exit(msg => 'No CommandId in ReceiveResponse');
                if ($node_command->value() ne $command_id) {
                    $self->internal_exit(msg => 'Wrong CommandId in ReceiveResponse node');
                }
                
                if ($node->name() eq 'Stream') {
                    my $node_tmp = $node->attr_find(undef, 'Name');
                    if (!defined($node_tmp)) {
                        next;
                    }
                    my $stream_type = $node_tmp->value();
                    my $output = decode_base64($node->text());
                    next if (!defined($output) || $output eq '');

                    if ($stream_type eq 'stderr') {
                        $current_stderr .= $output;
                    }
                    if ($stream_type eq 'stdout') {
                        $current_stdout .= $output;
                    }
                }
                if ($node->name() eq 'CommandState') {
                    my $node_tmp = $node->attr_find(undef, 'State');
                    if (!defined($node_tmp)) {
                        next;
                    }
                    my $state = $node_tmp->value();
                    if ($state eq 'http://schemas.microsoft.com/wbem/wsman/1/windows/shell/CommandState/Done') {
                        my $exit_code = $node->find(undef, 'ExitCode');
                        if (defined($exit_code)) {
                            $command_result->{$command->{label}}->{exit_code} = $exit_code->text();
                        } else {
                            $self->internal_exit(msg => "No exit code for 'done' command");
                        }
                        $loop_out = 0;
                    } elsif ($state eq 'http://schemas.microsoft.com/wbem/wsman/1/windows/shell/CommandState/Running') {
                        # we wait
                        $wait_timeout_done += 3;
                        sleep 3;
                    } elsif ($state eq 'http://schemas.microsoft.com/wbem/wsman/1/windows/shell/CommandState/Pending') {
                       # no-op
                       # WinRM 1.1 sends this with ExitCode:0
                       $loop_out = 0;
                    } else {
                        # unknown
                        $self->internal_exit(msg => 'Unknown command state: ' . $state);
                    }
                }
                
            }
            
        }
        
        if ($loop_out == 1) {
            $self->internal_exit(msg => 'Command to long to execute...');
        }
        
        $current_stderr =~ s/\r//mg;
        $current_stdout =~ s/\r//mg;
        
        $command_result->{$command->{label}}->{stderr} = $current_stderr if ($current_stderr ne '');
        $command_result->{$command->{label}}->{stdout} = $current_stdout if ($current_stdout ne '');
        
        #
        # terminate shell command
        #
        # not strictly needed for WinRM 2.0, but WinRM 1.1 requires this
        #
        $data = new openwsman::XmlDoc::('Signal', $namespace)
                                            or $self->internal_exit(msg => 'Could not create XmlDoc');
        $data->root()->attr_add(undef, 'CommandId', $command_id);
        $data->root()->add($namespace, 'Code', 'http://schemas.microsoft.com/wbem/wsman/1/windows/shell/signal/terminate');
        $result = $self->{client}->invoke($client_options, $uri, 'http://schemas.microsoft.com/wbem/wsman/1/windows/shell/Signal',
                                          $data);
        return undef if ($self->handle_dialog_fault(result => $result, msg => 'Invoke failed: ', dont_quit => $dont_quit));
    }
    
    # Delete Shell resource
    if (defined($self->{shell_id}) && !(defined($options{keep_open}) && $options{keep_open} == 1)) {
        my $client_options = new openwsman::ClientOptions::()
            or die print "[ERROR] Could not create client options handler.\n";
        $client_options->set_timeout(30 * 1000); # 30sec
        $client_options->add_selector('ShellId', $self->{shell_id});
        $self->{shell_id} = undef;
        $result = $self->{client}->invoke($client_options, $uri, 'http://schemas.xmlsoap.org/ws/2004/09/transfer/Delete', undef);
        return undef if ($self->handle_dialog_fault(result => $result, msg => 'Invoke failed: ', dont_quit => $dont_quit));
    }
    
    return $command_result;
}

sub request {
    my ($self, %options) = @_;
    # $options{nothing_quit} = integer
    # $options{dont_quit} = integer
    # $options{uri} = string
    # $options{wql_filter} = string
    # $options{result_type} = string ('array' or 'hash' with a key)
    # $options{hash_key} = string
    
    my ($dont_quit) = (defined($options{dont_quit}) && $options{dont_quit} == 1) ? 1 : 0;
    my ($nothing_quit) = (defined($options{nothing_quit}) && $options{nothing_quit} == 1) ? 1 : 0;
    my ($result_type) = (defined($options{result_type}) && $options{result_type} =~ /^(array|hash)$/) ? $options{result_type} : 'array';
    $self->set_error();
    
    ######
    # Check options
    if (!defined($options{uri})) {
        $self->{output}->add_option_msg(short_msg => 'Need to specify uri option');
        $self->{output}->option_exit(exit_litteral => $self->{wsman_errors_exit});
    }
    
    ######
    # ClientOptions object
    my $client_options = new openwsman::ClientOptions::() 
                                            or $self->internal_exit(msg => 'Could not create client options handler');

    # Optimization
    $client_options->set_flags($openwsman::FLAG_ENUMERATION_OPTIMIZATION);
    $client_options->set_max_elements(999);
    
    ######
    # Filter/Enumerate
    my $filter;
    if (defined($options{wql_filter})) {
        $filter = new openwsman::Filter::()
                                        or $self->internal_exit(msg => 'Could not create filter');
        $filter->wql($options{wql_filter});
    }

    my $result = $self->{client}->enumerate($client_options, $filter, $options{uri});
    return undef if ($self->handle_dialog_fault(result => $result, msg => 'Could not enumerate instances: ', dont_quit => $dont_quit));

    ######
    # Fetch values
    my ($array_return, $hash_return);
    
    $array_return = [] if ($result_type eq 'array');
    $hash_return = {} if ($result_type eq 'hash');
    my $context;
    my $total = 0;

    while (1) {
        my $nodes = $result->body()->find(undef, "Items");
        
        # Get items.
        my $items;
        for (my $cnt = 0; defined($nodes) && ($cnt<$nodes->size()); $cnt++) {
            my $row_return = {};
            for (my $cnt2 = 0; ($cnt2<$nodes->get($cnt)->size()); $cnt2++) {
                $row_return->{$nodes->get($cnt)->get($cnt2)->name()} = $nodes->get($cnt)->get($cnt2)->text();
            }
            $total++;
            push @{$array_return}, $row_return if ($result_type eq 'array');
            $hash_return->{$row_return->{$options{hash_key}}} = $row_return if ($result_type eq 'hash');
        }
        
        $context = $result->context()
                                or last;
        $result = $self->{client}->pull($client_options, $filter, $options{uri}, $context)
                                or last;

    }

    # Release context.
    $self->{client}->release($client_options, $options{uri}, $context) if($context);
    
    if ($nothing_quit == 1 && $total == 0) {
        $self->{output}->add_option_msg(short_msg => "Cant get a single value.");
        $self->{output}->option_exit(exit_litteral => $self->{option_results}->{wsman_errors_exit});
    }
    
    if ($result_type eq 'array') {
        return $array_return;
    }
    return $hash_return;
}

sub check_options {
    my ($self, %options) = @_;
    # $options{option_results} = ref to options result
    
    $self->{wsman_errors_exit} = $options{option_results}->{wsman_errors_exit};

    if (!defined($options{option_results}->{host})) {
        $self->{output}->add_option_msg(short_msg => "Missing parameter --hostname.");
        $self->{output}->option_exit();
    }
    $self->{wsman_params}->{host} = $options{option_results}->{host};

    if (!defined($options{option_results}->{wsman_scheme}) || $options{option_results}->{wsman_scheme} !~ /^(http|https)$/) {
        $self->{output}->add_option_msg(short_msg => "Wrong scheme parameter. Must be 'http' or 'https'.");
        $self->{output}->option_exit();
    }
    $self->{wsman_params}->{wsman_scheme} = $options{option_results}->{wsman_scheme};
    
    if (!defined($options{option_results}->{wsman_auth_method}) || !defined($auth_method_map{$options{option_results}->{wsman_auth_method}})) {
        $self->{output}->add_option_msg(short_msg => "Wrong wsman auth method parameter. Must be 'basic', 'noauth', 'digest', 'pass', 'ntlm' or 'gssnegotiate'.");
        $self->{output}->option_exit();
    }
    $self->{wsman_params}->{wsman_auth_method} = $options{option_results}->{wsman_auth_method};

    if (!defined($options{option_results}->{wsman_port}) || $options{option_results}->{wsman_port} !~ /^([0-9]+)$/) {
        $self->{output}->add_option_msg(short_msg => "Wrong wsman port parameter. Must be an integer.");
        $self->{output}->option_exit();
    }
    $self->{wsman_params}->{wsman_port} = $options{option_results}->{wsman_port};    
    
    $self->{wsman_params}->{wsman_path} = $options{option_results}->{wsman_path};
    $self->{wsman_params}->{wsman_username} = $options{option_results}->{wsman_username};
    $self->{wsman_params}->{wsman_password} = $options{option_results}->{wsman_password};
    $self->{wsman_params}->{wsman_timeout} = $options{option_results}->{wsman_timeout};
    $self->{wsman_params}->{wsman_proxy_url} = $options{option_results}->{wsman_proxy_url};
    $self->{wsman_params}->{wsman_proxy_username} = $options{option_results}->{wsman_proxy_username};
    $self->{wsman_params}->{wsman_proxy_password} = $options{option_results}->{wsman_proxy_password};
    $self->{wsman_params}->{wsman_debug} = $options{option_results}->{wsman_debug};
}

sub handle_dialog_fault {
    my ($self, %options) = @_;
    my $result = $options{result};
    my $msg = $options{msg};
    
    unless($result && $result->is_fault eq 0) {
        my $fault_string = $self->{client}->fault_string();
        my $msg = 'Could not enumerate instances: ' . ((defined($fault_string)) ? $fault_string : 'use debug option to have details');
        if ($options{dont_quit} == 1) {
            $self->set_error(error_status => -1, error_msg => $msg);
            return 1;
        }
        $self->{output}->add_option_msg(short_msg => $msg);
        $self->{output}->option_exit(exit_litteral => $self->{wsman_errors_exit});
    }
    
    return 0;
}

sub internal_exit {
    my ($self, %options) = @_;
    
    $self->{output}->add_option_msg(short_msg => $options{msg});
    $self->{output}->option_exit(exit_litteral => $self->{wsman_errors_exit});
}

sub set_error {
    my ($self, %options) = @_;
    # $options{error_msg} = string error
    # $options{error_status} = integer status
    
    $self->{error_status} = defined($options{error_status}) ? $options{error_status} : 0;
    $self->{error_msg} = defined($options{error_msg}) ? $options{error_msg} : undef;
}

sub error_status {
     my ($self) = @_;
    
    return $self->{error_status};
}

sub error {
    my ($self) = @_;
    
    return $self->{error_msg};
}

sub get_hostname {
    my ($self) = @_;

    my $host = $self->{wsman_params}->{host};
    return $host;
}

sub get_port {
    my ($self) = @_;

    return $self->{wsman_params}->{wsman_port};
}

1;

__END__

=head1 NAME

WSMAN global

=head1 SYNOPSIS

wsman class

=head1 WSMAN OPTIONS

Need at least openwsman-perl version >= 2.4.0

=over 8

=item B<--hostname>

Hostname to query (required).

=item B<--wsman-port>

Port (default: 5985).

=item B<--wsman-path>

Set path of URL (default: '/wsman').

=item B<--wsman-scheme>

Set transport scheme (default: 'http').

=item B<--wsman-username>

Set username for authentification.

=item B<--wsman-password>

Set username password for authentification.

=item B<--wsman-timeout>

Set HTTP Transport Timeout in seconds (default: 30).

=item B<--wsman-auth-method>

Set the authentification method (default: 'basic').

=item B<--wsman-proxy-url>

Set HTTP proxy URL.

=item B<--wsman-proxy-username>

Set the proxy username.

=item B<--wsman-proxy-password>

Set the proxy password.

=item B<--wsman-debug>

Set openwsman debug on (Only for test purpose).

=item B<--wsman-errors-exit>

Exit code for wsman Errors (default: unknown)

=back

=head1 DESCRIPTION

B<wsman>.

=cut