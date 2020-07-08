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

package blockchain::hyperledger::cli::mode::status;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use JSON::XS;
use Try::Tiny;
use centreon::plugins::misc;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_output {
    my ($self, %options) = @_;
    my $msg = "Status is '" .     $self->{result_values}->{status} . "'";

    return $msg;
}

sub custom_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_peer_node_status'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ' },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'peer_node_status' } ],
                closure_custom_calc => $self->can('custom_calc'),
                closure_custom_output => $self->can('custom_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "hostname:s"        => { name => 'hostname' },
        "remote"            => { name => 'remote' },
        "ssh-option:s@"     => { name => 'ssh_option' },
        "ssh-path:s"        => { name => 'ssh_path' },
        "ssh-command:s"     => { name => 'ssh_command', default => 'ssh' },
        "timeout:s"         => { name => 'timeout', default => 30 },
        "sudo"              => { name => 'sudo' },
        "cli-invocation:s"  => { name => 'cli_invocation'},
        "cli-name:s"        => { name => 'cli_name'},
        "node-name:s"       => { name => 'node_name'},
        "node-port:s"       => { name => 'node_port'},
        "api-operation:s"   => { name => 'api_operation', default => 'healthz'},
        "api-invocation:s"  => { name => 'api_invocation', default => 'curl'},
        "command-path:s"    => { name => 'command_path' },
        "command-options:s" => { name => 'command_options' },
        "warning-status:s"  => { name => 'warning_status' },
        "critical-status:s" => { name => 'critical_status', default => '${status} != "OK"' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub manage_selection {
    my ($self, %options) = @_;
    # use Data::Dumper;
    # print Dumper($self->{option_results}->{cli_invocation} . ' ' . $self->{option_results}->{cli_name} . ' ' . $self->{option_results}->{api_invocation} . 
    #                                                            ' ' . $self->{option_results}->{node_name} . ':' . $self->{option_results}->{node_port} . 
    #                                                            '/' . $self->{option_results}->{api_operation});

    my ($stdout) = centreon::plugins::misc::execute(
        output => $self->{output},
        options => $self->{option_results},
        sudo => $self->{option_results}->{sudo},
        command => $self->{option_results}->{cli_invocation} . ' ' . $self->{option_results}->{cli_name} . ' ' . $self->{option_results}->{api_invocation} . 
                                                               ' ' . $self->{option_results}->{node_name} . ':' . $self->{option_results}->{node_port} . 
                                                               '/' . $self->{option_results}->{api_operation},
        command_path => $self->{option_results}->{command_path},
        command_options => defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '' ? $self->{option_results}->{command_options} : undef
    );

    
    # print Dumper($stdout);

    my $extracted_json = '';
    if ($stdout =~ /(\{"status":.+\})/msi) {
        try {
            $extracted_json = JSON::XS::decode_json($1);
        }
        catch {
            warn "Caught JSON::XS decode error: $_";
        };

        $self->{global}->{peer_node_status} = $extracted_json->{status};
        $self->{output}->output_add(severity  => 'OK', long_msg => 'Last check: ' . $extracted_json->{time});

        if ( $extracted_json->{failed_checks} ) {
            $self->{output}->output_add(severity  => 'OK', long_msg => 'Failed ckeck: [component: ' . $extracted_json->{component} . '] [reason: ' . $extracted_json->{reason} . ' ]');
        }
    } else {
        $self->{output}->add_option_msg(short_msg => "Status check failed.");
        $self->{output}->option_exit();
    }

    # if ($stdout =~ /\{"status":"([A-Z]+)","time":"(\d{4}-\d{2}-\d{2})T(\d{2}:\d{2}:\d{2})\.\w*"\}/msi) {
    #     $self->{global}->{peer_node_status} = $1;
    #     $self->{output}->output_add(severity  => 'OK', long_msg => 'Last check: [date: ' . $2 . 
    #                         '] [time: ' . $3 . ']');
    # } 

}

1;

__END__

=head1 MODE

Check Hyperledger Fabric peers/orderers status through the CLI

=over 8

=item B<--nameservers>

Set nameserver to query (can be multiple).
The system configuration is used by default.

=item B<--remote>

Execute command remotely in 'ssh'.

=item B<--hostname>

Hostname to query (need --remote).

=item B<--ssh-option>

Specify multiple options like the user (example: --ssh-option='-l=centreon-engine' --ssh-option='-p=52').

=item B<--ssh-path>

Specify ssh command path (default: none)

=item B<--ssh-command>

Specify ssh command (default: 'ssh'). Useful to use 'plink'.

=item B<--timeout>

Timeout in seconds for the command (Default: 30).

=item B<--sudo>

Use 'sudo' to execute the command.

=item B<--cli-invocation>

Command to call HF CLI. Used it you have output in a file.

=item B<--cli-name>

Container name of the CLI.

=item B<--node-name>

Container name of the HF node to check.

=item B<--node-port>

Port of the Operation API is listennig. 

=item B<--api-operation>

Name of the operation to request. Defaut value is 'healthz' 

=item B<--api-invocation>

Protocol use to send the request. Defaut value is 'curl'

=item B<--command-path>

Command path.

=item B<--command-options>

Command options (Default: '-report -most_columns').

=item B<--warning-engine-status>

Set warning threshold for status (Default: '')
Can used special variables like: %{last_engine_version}, %{current_engine_version}

=item B<--critical-engine-status>

Set critical threshold for status (Default: '%{last_engine_version} ne %{current_engine_version}').
Can used special variables like: %{last_engine_version}, %{current_engine_version}

=item B<--warning-maindb-status>

Set warning threshold for status (Default: '')
Can used special variables like: %{last_maindb_version}, %{current_maindb_version}, %{current_maindb_timediff}

=item B<--critical-maindb-status>

Set critical threshold for status (Default: '%{last_maindb_version} ne %{current_maindb_version}').
Can used special variables like: %{last_maindb_version}, %{current_maindb_version}, %{current_maindb_timediff}

=item B<--warning-dailydb-status>

Set warning threshold for status (Default: '')
Can used special variables like: %{last_dailydb_version}, %{current_dailydb_version}, %{current_dailydb_timediff}

=item B<--critical-dailydb-status>

Set critical threshold for status (Default: '%{last_dailydb_version} ne %{current_dailydb_version} || %{current_dailydb_timediff} > 432000').
Can used special variables like: %{last_dailydb_version}, %{current_dailydb_version}, %{current_dailydb_timediff}

=back

=cut
