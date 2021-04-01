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

package apps::automation::ansible::tower::custom::towercli;

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
            'username:s'        => { name => 'username' },
            'password:s'        => { name => 'password' },
            'timeout:s'         => { name => 'timeout', default => 50 },
            'sudo'              => { name => 'sudo' },
            'command:s'         => { name => 'command', default => 'tower-cli' },
            'command-path:s'    => { name => 'command_path' },
            'command-options:s' => { name => 'command_options', default => '' },
            'nossl'             => { name => 'nossl' },
            'proxyurl:s'        => { name => 'proxyurl' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'TOWERCLI OPTIONS', once => 1);

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

    if (defined($self->{option_results}->{proxyurl}) && $self->{option_results}->{proxyurl} ne '') {
        $ENV{HTTP_PROXY} = $self->{option_results}->{proxyurl};
        $ENV{HTTPS_PROXY} = $self->{option_results}->{proxyurl};
    }

    $self->{hostname} = (defined($self->{option_results}->{hostname})) && $self->{option_results}->{hostname} ne '' ? $self->{option_results}->{hostname} : undef;
    $self->{username} = (defined($self->{option_results}->{username})) && $self->{option_results}->{username} ne '' ? $self->{option_results}->{username} : undef;
    $self->{password} = (defined($self->{option_results}->{password})) && $self->{option_results}->{password} ne '' ? $self->{option_results}->{password} : undef;

    if (defined($self->{option_results}->{nossl})) {
        $ENV{TOWER_VERIFY_SSL} = 'no';
        $self->{hostname} = 'http://' . $self->{hostname} if (defined($self->{hostname}));
        $ENV{HTTPS_PROXY} = $self->{option_results}->{proxyurl};
    }

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
        command_options => $options{cmd_options}
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

sub tower_list_hosts_set_cmd {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');

    my $cmd_options = "host list --insecure --all-pages --format json";
    $cmd_options .= " --tower-host '$self->{hostname}'" if (defined($self->{hostname}));
    $cmd_options .= " --tower-username '$self->{username}'" if (defined($self->{username}));
    $cmd_options .= " --tower-password '$self->{password}'" if (defined($self->{password}));
    $cmd_options .= " --group '$options{group}'" if (defined($options{group}) && $options{group} ne '');
    $cmd_options .= " --inventory '$options{inventory}'" if (defined($options{inventory}) && $options{inventory} ne '');
        
    return $cmd_options; 
}

sub tower_list_hosts {
    my ($self, %options) = @_;

    my $cmd_options = $self->tower_list_hosts_set_cmd(%options);
    my $raw_results = $self->execute(cmd_options => $cmd_options);
    
    return $raw_results->{results};
}

sub tower_list_inventories_set_cmd {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');
    
    my $cmd_options = 'inventory list --insecure --all-pages --format json';
    $cmd_options .= " --tower-host '$self->{hostname}'" if (defined($self->{hostname}));
    $cmd_options .= " --tower-username '$self->{username}'" if (defined($self->{username}));
    $cmd_options .= " --tower-password '$self->{password}'" if (defined($self->{password}));
        
    return $cmd_options; 
}

sub tower_list_inventories {
    my ($self, %options) = @_;

    my $cmd_options = $self->tower_list_inventories_set_cmd(%options);
    my $raw_results = $self->execute(cmd_options => $cmd_options);
    
    return $raw_results->{results};
}

sub tower_list_projects_set_cmd {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');
    
    my $cmd_options = "project list --insecure --all-pages --format json";
    $cmd_options .= " --tower-host '$self->{hostname}'" if (defined($self->{hostname}));
    $cmd_options .= " --tower-username '$self->{username}'" if (defined($self->{username}));
    $cmd_options .= " --tower-password '$self->{password}'" if (defined($self->{password}));
        
    return $cmd_options; 
}

sub tower_list_projects {
    my ($self, %options) = @_;

    my $cmd_options = $self->tower_list_projects_set_cmd(%options);
    my $raw_results = $self->execute(cmd_options => $cmd_options);
    
    return $raw_results->{results};
}

sub tower_list_job_templates_set_cmd {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');
    
    my $cmd_options = "job_template list --insecure --all-pages --format json";
    $cmd_options .= " --tower-host '$self->{hostname}'" if (defined($self->{hostname}));
    $cmd_options .= " --tower-username '$self->{username}'" if (defined($self->{username}));
    $cmd_options .= " --tower-password '$self->{password}'" if (defined($self->{password}));
        
    return $cmd_options; 
}

sub tower_list_job_templates {
    my ($self, %options) = @_;

    my $cmd_options = $self->tower_list_job_templates_set_cmd(%options);
    my $raw_results = $self->execute(cmd_options => $cmd_options);
    
    return $raw_results->{results};
}

sub tower_list_schedules {
    my ($self, %options) = @_;

    $self->{output}->add_option_msg(short_msg => 'method unsupported (try to use --custommode=api)');
    $self->{output}->option_exit();
}

sub tower_list_unified_jobs {
    my ($self, %options) = @_;

    $self->{output}->add_option_msg(short_msg => 'method unsupported (try to use --custommode=api)');
    $self->{output}->option_exit();
}

sub tower_launch_job_template_set_cmd {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');
    
    my $cmd_options = "job launch --job-template=$options{launch_job_template_id} ";
    $cmd_options .= " --inventory '$options{launch_inventory}'" if (defined($options{launch_inventory}));
    $cmd_options .= " --credential '$options{launch_credential}'" if (defined($options{launch_credential}));
    $cmd_options .= " --tags '$options{launch_tags}'" if (defined($options{launch_tags}));
    $cmd_options .= " --limit '$options{launch_limit}'" if (defined($options{launch_limit}));
    $cmd_options .= " --extra-vars '$options{launch_extra_vars}'" if (defined($options{launch_extra_vars}));
    $cmd_options .= ' --insecure --format json';
    $cmd_options .= " --tower-host '$self->{hostname}'" if (defined($self->{hostname}));
    $cmd_options .= " --tower-username '$self->{username}'" if (defined($self->{username}));
    $cmd_options .= " --tower-password '$self->{password}'" if (defined($self->{password}));
        
    return $cmd_options; 
}

sub tower_launch_job_template {
    my ($self, %options) = @_;

    my $cmd_options = $self->tower_launch_job_template_set_cmd(%options);
    my $raw_results = $self->execute(cmd_options => $cmd_options);

    return $raw_results;
}

sub tower_get_job_set_cmd {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');
    
    my $cmd_options = "job get $options{job_id} --insecure --format json";
    $cmd_options .= " --tower-host '$self->{hostname}'" if (defined($self->{hostname}));
    $cmd_options .= " --tower-username '$self->{username}'" if (defined($self->{username}));
    $cmd_options .= " --tower-password '$self->{password}'" if (defined($self->{password}));
        
    return $cmd_options; 
}

sub tower_get_job {
    my ($self, %options) = @_;

    my $cmd_options = $self->tower_get_job_set_cmd(%options);
    my $raw_results = $self->execute(cmd_options => $cmd_options);
    
    return $raw_results;
}

1;

__END__

=head1 NAME

Ansible Tower CLI

=head1 TOWERCLI OPTIONS

Ansible Tower CLI

To install the Tower CLI : https://docs.ansible.com/ansible-tower/latest/html/towerapi/tower_cli.html#installation

=over 8

=item B<--hostname>

Ansible Tower hostname (Default uses setting in 'tower config').

=item B<--username>

Ansible Tower username (Default uses setting in 'tower config').

=item B<--password>

Ansible Tower password (Default uses setting in 'tower config').

=item B<--nossl>

Use http connection.

=item B<--timeout>

Set timeout in seconds (Default: 50).

=item B<--sudo>

Use 'sudo' to execute the command.

=item B<--command>

Command to get information (Default: 'tower-cli').
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
