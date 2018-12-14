#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

package cloud::azure::custom::azcli;

use strict;
use warnings;
use DateTime;
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
        $options{options}->add_options(arguments => 
                    {
                        "subscription:s"      => { name => 'subscription' },
                        "tenant:s"            => { name => 'tenant' },
                        "client-id:s"         => { name => 'client_id' },
                        "client-secret:s"     => { name => 'client_secret' },
                        "timeframe:s"         => { name => 'timeframe' },
                        "interval:s"          => { name => 'interval' },
                        "aggregation:s@"      => { name => 'aggregation' },
                        "zeroed"              => { name => 'zeroed' },
                        "timeout:s"           => { name => 'timeout', default => 50 },
                        "sudo"                => { name => 'sudo' },
                        "command:s"           => { name => 'command', default => 'az' },
                        "command-path:s"      => { name => 'command_path' },
                        "command-options:s"   => { name => 'command_options', default => '' },
                        "proxyurl:s"          => { name => 'proxyurl' },
                    });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'AZCLI OPTIONS', once => 1);

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

    if (defined($self->{option_results}->{proxyurl}) && $self->{option_results}->{proxyurl} ne '') {
        $ENV{HTTP_PROXY} = $self->{option_results}->{proxyurl};
        $ENV{HTTPS_PROXY} = $self->{option_results}->{proxyurl};
    }

    if (defined($self->{option_results}->{aggregation})) {
        foreach my $aggregation (@{$self->{option_results}->{aggregation}}) {
            if ($aggregation !~ /average|maximum|minimum|total/i) {
                $self->{output}->add_option_msg(short_msg => "Aggregation '" . $aggregation . "' is not handled");
                $self->{output}->option_exit();
            }
        }
    }

    $self->{subscription} = (defined($self->{option_results}->{subscription})) ? $self->{option_results}->{subscription} : undef;

    return 0;
}

sub azure_get_metrics_set_cmd {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');
    
    my $cmd_options = "monitor metrics list --metrics '" . join('\' \'', @{$options{metrics}}) . "' --start-time $options{start_time} --end-time $options{end_time} " .
        "--interval $options{interval} --aggregation '" . join('\' \'', @{$options{aggregations}}) . "' --output json --resource '$options{resource}' " .
        "--resource-group '$options{resource_group}' --resource-type '$options{resource_type}' --resource-namespace '$options{resource_namespace}'";
    $cmd_options .= " --subscription '$self->{subscription}'" if (defined($self->{subscription}) && $self->{subscription} ne '');
    
    return $cmd_options; 
}

sub azure_get_metrics {
    my ($self, %options) = @_;
    
    my $results = {};
    my $start_time = DateTime->now->subtract(seconds => $options{timeframe})->iso8601.'Z';
    my $end_time = DateTime->now->iso8601.'Z';

    my $cmd_options = $self->azure_get_metrics_set_cmd(%options, start_time => $start_time, end_time => $end_time);
    
    my ($response) = centreon::plugins::misc::execute(
        output => $self->{output},
        options => $self->{option_results},
        sudo => $self->{option_results}->{sudo},
        command => $self->{option_results}->{command},
        command_path => $self->{option_results}->{command_path},
        command_options => $cmd_options);

    my $raw_results;
    my $command_line = $self->{option_results}->{command} . " " . $cmd_options;

    eval {
        $raw_results = JSON::XS->new->utf8->decode($response);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }
    
    foreach my $metric (@{$raw_results->{value}}) {
        my $metric_name = lc($metric->{name}->{value});
        $metric_name =~ s/ /_/g;

        $results->{$metric_name} = { points => 0 };
        foreach my $timeserie (@{$metric->{timeseries}}) {
            foreach my $point (@{$timeserie->{data}}) {
                if (defined($point->{average})) {
                    $results->{$metric_name}->{average} = 0 if (!defined($results->{$metric_name}->{average}));
                    $results->{$metric_name}->{average} += $point->{average};
                    $results->{$metric_name}->{points}++;
                }
                if (defined($point->{minimum})) {
                    $results->{$metric_name}->{minimum} = $point->{minimum}
                        if (!defined($results->{$metric_name}->{minimum}) || $point->{minimum} < $results->{$metric_name}->{minimum});
                }
                if (defined($point->{maximum})) {
                    $results->{$metric_name}->{maximum} = $point->{maximum}
                        if (!defined($results->{$metric_name}->{maximum}) || $point->{maximum} > $results->{$metric_name}->{maximum});
                }
                if (defined($point->{total})) {
                    $results->{$metric_name}->{total} = 0 if (!defined($results->{$metric_name}->{total}));
                    $results->{$metric_name}->{total} += $point->{total};
                    $results->{$metric_name}->{points}++;
                }
            }
        }
        
        if (defined($results->{$metric_name}->{average})) {
            $results->{$metric_name}->{average} /= $results->{$metric_name}->{points};
        }
    }
    
    return $results, $raw_results, $command_line;
}

sub azure_list_resources_set_cmd {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');
    
    my $cmd_options = "resource list --namespace '$options{namespace}' --resource-type '$options{resource_type}' --output json";
    $cmd_options .= " --location '$options{location}'" if (defined($options{location}) && $options{location} ne '');
    $cmd_options .= " --resource-group '$options{resource_group}'" if (defined($options{resource_group}) && $options{resource_group} ne '');
    $cmd_options .= " --subscription '$self->{subscription}'" if (defined($self->{subscription}) && $self->{subscription} ne '');
    
    return $cmd_options; 
}

sub azure_list_resources {
    my ($self, %options) = @_;
    
    my $results = {};

    my $cmd_options = $self->azure_list_resources_set_cmd(%options);
    
    my ($response) = centreon::plugins::misc::execute(
        output => $self->{output},
        options => $self->{option_results},
        sudo => $self->{option_results}->{sudo},
        command => $self->{option_results}->{command},
        command_path => $self->{option_results}->{command_path},
        command_options => $cmd_options);

    my $raw_results;
    my $command_line = $self->{option_results}->{command} . " " . $cmd_options;

    eval {
        $raw_results = JSON::XS->new->utf8->decode($response);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }
    
    return $raw_results;
}

sub azure_list_vm_sizes_set_cmd {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');
    
    my $cmd_options = "vm list-sizes --location '$options{location}' --output json";
    $cmd_options .= " --subscription '$self->{subscription}'" if (defined($self->{subscription}) && $self->{subscription} ne '');
        
    return $cmd_options; 
}

sub azure_list_vm_sizes {
    my ($self, %options) = @_;
    
    my $results = {};

    my $cmd_options = $self->azure_list_vm_sizes_set_cmd(%options);
    
    my ($response) = centreon::plugins::misc::execute(
        output => $self->{output},
        options => $self->{option_results},
        sudo => $self->{option_results}->{sudo},
        command => $self->{option_results}->{command},
        command_path => $self->{option_results}->{command_path},
        command_options => $cmd_options);

    my $raw_results;
    my $command_line = $self->{option_results}->{command} . " " . $cmd_options;

    eval {
        $raw_results = JSON::XS->new->utf8->decode($response);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }
    
    return $raw_results;
}

sub azure_list_vms_set_cmd {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');
    
    my $cmd_options = "vm list --output json";
    $cmd_options .= " --resource-group '$options{resource_group}'" if (defined($options{resource_group}) && $options{resource_group} ne '');
    $cmd_options .= " --show-details" if (defined($options{show_details}));
    $cmd_options .= " --subscription '$self->{subscription}'" if (defined($self->{subscription}) && $self->{subscription} ne '');

    return $cmd_options; 
}

sub azure_list_vms {
    my ($self, %options) = @_;
    
    my $results = {};

    my $cmd_options = $self->azure_list_vms_set_cmd(%options);
    
    my ($response) = centreon::plugins::misc::execute(
        output => $self->{output},
        options => $self->{option_results},
        sudo => $self->{option_results}->{sudo},
        command => $self->{option_results}->{command},
        command_path => $self->{option_results}->{command_path},
        command_options => $cmd_options);

    my $raw_results;
    my $command_line = $self->{option_results}->{command} . " " . $cmd_options;

    eval {
        $raw_results = JSON::XS->new->utf8->decode($response);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }
    
    return $raw_results;
}

sub azure_list_groups_set_cmd {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');
    
    my $cmd_options = "group list --output json";
    $cmd_options .= " --subscription '$self->{subscription}'" if (defined($self->{subscription}) && $self->{subscription} ne '');
    
    return $cmd_options; 
}

sub azure_list_groups {
    my ($self, %options) = @_;
    
    my $results = {};

    my $cmd_options = $self->azure_list_groups_set_cmd(%options);
    
    my ($response) = centreon::plugins::misc::execute(
        output => $self->{output},
        options => $self->{option_results},
        sudo => $self->{option_results}->{sudo},
        command => $self->{option_results}->{command},
        command_path => $self->{option_results}->{command_path},
        command_options => $cmd_options);

    my $raw_results;
    my $command_line = $self->{option_results}->{command} . " " . $cmd_options;

    eval {
        $raw_results = JSON::XS->new->utf8->decode($response);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }
    
    return $raw_results;
}

sub azure_list_deployments_set_cmd {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');
    
    my $cmd_options = "group deployment list --resource-group '$options{resource_group}' --output json";
    $cmd_options .= " --subscription '$self->{subscription}'" if (defined($self->{subscription}) && $self->{subscription} ne '');
    
    return $cmd_options; 
}

sub azure_list_deployments {
    my ($self, %options) = @_;
    
    my $results = {};

    my $cmd_options = $self->azure_list_deployments_set_cmd(%options);
    
    my ($response) = centreon::plugins::misc::execute(
        output => $self->{output},
        options => $self->{option_results},
        sudo => $self->{option_results}->{sudo},
        command => $self->{option_results}->{command},
        command_path => $self->{option_results}->{command_path},
        command_options => $cmd_options);

    my $raw_results;
    my $command_line = $self->{option_results}->{command} . " " . $cmd_options;

    eval {
        $raw_results = JSON::XS->new->utf8->decode($response);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }
    
    return $raw_results;
}

1;

__END__

=head1 NAME

Microsoft Azure CLI

=head1 AZCLI OPTIONS

Microsoft Azure CLI 2.0

To install the Azure CLI 2.0 in a CentOS/RedHat environment :

(As root)

# rpm --import https://packages.microsoft.com/keys/microsoft.asc

# sh -c 'echo -e "[azure-cli]\nname=Azure CLI\nbaseurl=https://packages.microsoft.com/yumrepos/azure-cli\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/azure-cli.repo'

# yum install azure-cli

(As centreon-engine)

# az login

Go to https://aka.ms/devicelogin and enter the code given by the last command.

For futher informations, visit https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest.

=over 8

=item B<--subscription>

Set Azure subscription (Required if logged to several subscriptions).

=item B<--timeframe>

Set timeframe in seconds (i.e. 3600 to check last hour).

=item B<--interval>

Set interval of the metric query (Can be : PT1M, PT5M, PT15M, PT30M, PT1H, PT6H, PT12H, PT24H).

=item B<--aggregation>

Set monitor aggregation (Can be multiple, Can be: 'minimum', 'maximum', 'average', 'total').

=item B<--zeroed>

Set metrics value to 0 if none. Usefull when Monitor
does not return value when not defined.

=item B<--timeout>

Set timeout in seconds (Default: 50).

=item B<--sudo>

Use 'sudo' to execute the command.

=item B<--command>

Command to get information (Default: 'az').
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
