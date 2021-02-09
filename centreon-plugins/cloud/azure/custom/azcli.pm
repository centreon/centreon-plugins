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
        $options{options}->add_options(arguments => {
            'subscription:s'      => { name => 'subscription' },
            'tenant:s'            => { name => 'tenant' },
            'client-id:s'         => { name => 'client_id' },
            'client-secret:s'     => { name => 'client_secret' },
            'timeframe:s'         => { name => 'timeframe' },
            'interval:s'          => { name => 'interval' },
            'aggregation:s@'      => { name => 'aggregation' },
            'zeroed'              => { name => 'zeroed' },
            'timeout:s'           => { name => 'timeout', default => 50 },
            'sudo'                => { name => 'sudo' },
            'command:s'           => { name => 'command', default => 'az' },
            'command-path:s'      => { name => 'command_path' },
            'command-options:s'   => { name => 'command_options', default => '' },
            'proxyurl:s'          => { name => 'proxyurl' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'AZCLI OPTIONS', once => 1);

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

sub execute {
    my ($self, %options) = @_;

    $self->{output}->output_add(long_msg => "Command line: '" . $self->{option_results}->{command} . " " . $options{cmd_options} . "'", debug => 1);

    my ($response) = centreon::plugins::misc::execute(
        output => $self->{output},
        options => $self->{option_results},
        sudo => $self->{option_results}->{sudo},
        command => $self->{option_results}->{command},
        command_path => $self->{option_results}->{command_path},
        command_options => $options{cmd_options});

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

sub convert_duration {
    my ($self, %options) = @_;

    my $duration;
    if ($options{time_string} =~ /^P.*S$/) {
        centreon::plugins::misc::mymodule_load(
            output => $self->{output},
            module => 'DateTime::Format::Duration::ISO8601',
            error_msg => "Cannot load module 'DateTime::Format::Duration::ISO8601'."
        );

        my $format = DateTime::Format::Duration::ISO8601->new;
        my $d = $format->parse_duration($options{time_string});
        $duration = $d->minutes * 60 + $d->seconds;
    } elsif ($options{time_string} =~ /^(\d+):(\d+):(\d+)\.\d+$/) {
        centreon::plugins::misc::mymodule_load(
            output => $self->{output},
            module => 'DateTime::Duration',
            error_msg => "Cannot load module 'DateTime::Format::Duration'."
        );

        my $d = DateTime::Duration->new(hours => $1, minutes => $2, seconds => $3);
        $duration = $d->minutes * 60 + $d->seconds;
    }

    return $duration;
}

sub azure_get_metrics_set_cmd {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');

    my $cmd_options = "monitor metrics list --metrics '" . join('\' \'', @{$options{metrics}}) . "' --start-time $options{start_time} --end-time $options{end_time} " .
        "--interval $options{interval} --aggregation '" . join('\' \'', @{$options{aggregations}}) . "' --only-show-errors --output json --resource '$options{resource}' " .
        "--resource-group '$options{resource_group}' --resource-type '$options{resource_type}' --resource-namespace '$options{resource_namespace}'";
    $cmd_options .= " --subscription '$self->{subscription}'" if (defined($self->{subscription}) && $self->{subscription} ne '');
    $cmd_options .= " --filter '$options{dimension}'" if defined($options{dimension});
    
    return $cmd_options;
}

sub azure_get_metrics {
    my ($self, %options) = @_;

    my $results = {};
    my $start_time = DateTime->now->subtract(seconds => $options{timeframe})->iso8601.'Z';
    my $end_time = DateTime->now->iso8601.'Z';

    my $cmd_options = $self->azure_get_metrics_set_cmd(%options, start_time => $start_time, end_time => $end_time);
    my $raw_results = $self->execute(cmd_options => $cmd_options);

    foreach my $metric (@{$raw_results->{value}}) {
        my $metric_name = lc($metric->{name}->{value});
        $metric_name =~ s/ /_/g;

        $results->{$metric_name} = { points => 0, name => $metric->{name}->{localizedValue} };
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

    return $results, $raw_results;
}

sub azure_get_resource_health_set_cmd {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');
    
    my $cmd_options = "rest --only-show-errors --output json";
    $cmd_options .= " --uri /subscriptions/" . $self->{subscription} . "/resourceGroups/" .
        $options{resource_group} . "/providers/" . $options{resource_namespace} . "/" . $options{resource_type} .
        "/" . $options{resource} . "/providers/Microsoft.ResourceHealth/availabilityStatuses/current?api-version=" . $options{api_version};

    return $cmd_options; 
}

sub azure_get_resource_health {
    my ($self, %options) = @_;

    my $cmd_options = $self->azure_get_resource_health_set_cmd(%options);
    my $raw_results = $self->execute(cmd_options => $cmd_options);

    return $raw_results;
}

sub azure_list_resources_set_cmd {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');
    
    my $cmd_options = "resource list --only-show-errors --output json";
    $cmd_options .= " --namespace '$options{namespace}'" if (defined($options{namespace}) && $options{namespace} ne '');
    $cmd_options .= " --resource-type '$options{resource_type}'" if (defined($options{resource_type}) && $options{resource_type} ne '');
    $cmd_options .= " --location '$options{location}'" if (defined($options{location}) && $options{location} ne '');
    $cmd_options .= " --resource-group '$options{resource_group}'" if (defined($options{resource_group}) && $options{resource_group} ne '');
    $cmd_options .= " --subscription '$self->{subscription}'" if (defined($self->{subscription}) && $self->{subscription} ne '');
    
    return $cmd_options; 
}

sub azure_list_resources {
    my ($self, %options) = @_;

    my $cmd_options = $self->azure_list_resources_set_cmd(%options);
    my $raw_results = $self->execute(cmd_options => $cmd_options);
    
    return $raw_results;
}

sub azure_list_vm_sizes_set_cmd {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');
    
    my $cmd_options = "vm list-sizes --location '$options{location}' --only-show-errors --output json";
    $cmd_options .= " --subscription '$self->{subscription}'" if (defined($self->{subscription}) && $self->{subscription} ne '');
        
    return $cmd_options; 
}

sub azure_list_vm_sizes {
    my ($self, %options) = @_;

    my $cmd_options = $self->azure_list_vm_sizes_set_cmd(%options);
    my $raw_results = $self->execute(cmd_options => $cmd_options);
    
    return $raw_results;
}

sub azure_list_vms_set_cmd {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');
    
    my $cmd_options = "vm list --only-show-errors --output json";
    $cmd_options .= " --resource-group '$options{resource_group}'" if (defined($options{resource_group}) && $options{resource_group} ne '');
    $cmd_options .= " --show-details" if (defined($options{show_details}));
    $cmd_options .= " --subscription '$self->{subscription}'" if (defined($self->{subscription}) && $self->{subscription} ne '');

    return $cmd_options; 
}

sub azure_list_vms {
    my ($self, %options) = @_;

    my $cmd_options = $self->azure_list_vms_set_cmd(%options);
    my $raw_results = $self->execute(cmd_options => $cmd_options);
    
    return $raw_results;
}

sub azure_list_groups_set_cmd {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');
    
    my $cmd_options = "group list --only-show-errors --output json";
    $cmd_options .= " --subscription '$self->{subscription}'" if (defined($self->{subscription}) && $self->{subscription} ne '');
    
    return $cmd_options; 
}

sub azure_list_groups {
    my ($self, %options) = @_;

    my $cmd_options = $self->azure_list_groups_set_cmd(%options);
    my $raw_results = $self->execute(cmd_options => $cmd_options);
    
    return $raw_results;
}

sub azure_list_deployments_set_cmd {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');

    my $cmd_options = "group deployment list --resource-group '$options{resource_group}' --only-show-errors --output json";
    $cmd_options .= " --subscription '$self->{subscription}'" if (defined($self->{subscription}) && $self->{subscription} ne '');
    
    return $cmd_options; 
}

sub azure_list_deployments {
    my ($self, %options) = @_;

    my $cmd_options = $self->azure_list_deployments_set_cmd(%options);
    my $raw_results = $self->execute(cmd_options => $cmd_options);
    
    return $raw_results;
}

sub azure_list_vaults_set_cmd {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');

    my $cmd_options = "backup vault list --only-show-errors --output json";
    $cmd_options .= " --resource-group '$options{resource_group}'" if (defined($options{resource_group}) && $options{resource_group} ne '');
    $cmd_options .= " --subscription '$self->{subscription}'" if (defined($self->{subscription}) && $self->{subscription} ne '');
    
    return $cmd_options; 
}

sub azure_list_vaults {
    my ($self, %options) = @_;

    my $cmd_options = $self->azure_list_vaults_set_cmd(%options);
    my $raw_results = $self->execute(cmd_options => $cmd_options);
    
    return $raw_results;
}

sub azure_list_backup_jobs_set_cmd {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');

    my $cmd_options = "backup job list --resource-group '$options{resource_group}' --vault-name '$options{vault_name}' --only-show-errors --output json";
    $cmd_options .= " --subscription '$self->{subscription}'" if (defined($self->{subscription}) && $self->{subscription} ne '');
    
    return $cmd_options; 
}

sub azure_list_backup_jobs {
    my ($self, %options) = @_;

    my $cmd_options = $self->azure_list_backup_jobs_set_cmd(%options);
    my $raw_results = $self->execute(cmd_options => $cmd_options);
    
    return $raw_results;
}

sub azure_list_backup_items_set_cmd {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');

    my $cmd_options = "backup item list --resource-group '$options{resource_group}' --vault-name '$options{vault_name}' --only-show-errors --output json";
    $cmd_options .= " --subscription '$self->{subscription}'" if (defined($self->{subscription}) && $self->{subscription} ne '');
    
    return $cmd_options; 
}

sub azure_list_backup_items {
    my ($self, %options) = @_;

    my $cmd_options = $self->azure_list_backup_items_set_cmd(%options);
    my $raw_results = $self->execute(cmd_options => $cmd_options);
    
    return $raw_results;
}

sub azure_list_expressroute_circuits_set_cmd {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');

    my $cmd_options = "network express-route list --only-show-errors --output json";
    $cmd_options .= " --resource-group '$options{resource_group}'" if (defined($options{resource_group}) && $options{resource_group} ne '');
    $cmd_options .= " --subscription '$self->{subscription}'" if (defined($self->{subscription}) && $self->{subscription} ne '');
    
    return $cmd_options; 
}

sub azure_list_expressroute_circuits {
    my ($self, %options) = @_;

    my $cmd_options = $self->azure_list_expressroute_circuits_set_cmd(%options);
    my $raw_results = $self->execute(cmd_options => $cmd_options);
    
    return $raw_results;
}

sub azure_list_vpn_gateways_set_cmd {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');

    my $cmd_options = "network vnet-gateway list --resource-group '$options{resource_group}' --only-show-errors --output json";
    $cmd_options .= " --subscription '$self->{subscription}'" if (defined($self->{subscription}) && $self->{subscription} ne '');
    
    return $cmd_options; 
}

sub azure_list_vpn_gateways {
    my ($self, %options) = @_;

    my $cmd_options = $self->azure_list_vpn_gateways_set_cmd(%options);
    my $raw_results = $self->execute(cmd_options => $cmd_options);
    
    return $raw_results;
}

sub azure_list_virtualnetworks_set_cmd {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');

    my $cmd_options = "network vnet list --only-show-errors --output json";
    $cmd_options .= " --resource-group '$options{resource_group}'" if (defined($options{resource_group}) && $options{resource_group} ne '');
    $cmd_options .= " --subscription '$self->{subscription}'" if (defined($self->{subscription}) && $self->{subscription} ne '');
    
    return $cmd_options; 
}

sub azure_list_virtualnetworks {
    my ($self, %options) = @_;

    my $cmd_options = $self->azure_list_virtualnetworks_set_cmd(%options);
    my $raw_results = $self->execute(cmd_options => $cmd_options);
    
    return $raw_results;
}

sub azure_list_vnet_peerings_set_cmd {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');

    my $cmd_options = "network vnet peering list --resource-group '$options{resource_group}' --vnet-name '$options{vnet_name}' --only-show-errors --output json";
    $cmd_options .= " --subscription '$self->{subscription}'" if (defined($self->{subscription}) && $self->{subscription} ne '');
    
    return $cmd_options; 
}

sub azure_list_vnet_peerings {
    my ($self, %options) = @_;

    my $cmd_options = $self->azure_list_vnet_peerings_set_cmd(%options);
    my $raw_results = $self->execute(cmd_options => $cmd_options);
    
    return $raw_results;
}

sub azure_list_sqlservers_set_cmd {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');

    my $cmd_options = "sql server list --only-show-errors --output json";
    $cmd_options .= " --resource-group '$options{resource_group}'" if (defined($options{resource_group}) && $options{resource_group} ne '');
    $cmd_options .= " --subscription '$self->{subscription}'" if (defined($self->{subscription}) && $self->{subscription} ne '');
    
    return $cmd_options; 
}

sub azure_list_sqlservers {
    my ($self, %options) = @_;

    my $cmd_options = $self->azure_list_sqlservers_set_cmd(%options);
    my $raw_results = $self->execute(cmd_options => $cmd_options);
    
    return $raw_results;
}

sub azure_list_sqldatabases_set_cmd {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');

    my $cmd_options = "sql db list --resource-group '$options{resource_group}' --server '$options{server}' --only-show-errors --output json";
    $cmd_options .= " --subscription '$self->{subscription}'" if (defined($self->{subscription}) && $self->{subscription} ne '');
    
    return $cmd_options; 
}

sub azure_list_sqldatabases {
    my ($self, %options) = @_;

    my $cmd_options = $self->azure_list_sqldatabases_set_cmd(%options);
    my $raw_results = $self->execute(cmd_options => $cmd_options);
    
    return $raw_results;
}

sub azure_get_log_analytics_set_cmd {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');

    my $cmd_options = "monitor log-analytics query --workspace '$options{workspace_id}' --analytics-query \"$options{query}\" --only-show-errors";
    $cmd_options .= " --timespan '$options{timespan}'" if (defined($options{timespan}));
    return $cmd_options; 
}

sub azure_get_log_analytics {
    my ($self, %options) = @_;

    my $cmd_options = $self->azure_get_log_analytics_set_cmd(%options);
    return $self->execute(cmd_options => $cmd_options);
}

sub azure_get_publicip_set_cmd {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');

    my $cmd_options = "network public-ip show --resource-group '$options{resource_group}' --name '$options{resource}'";
    $cmd_options .= " --subscription '$self->{subscription}'" if (defined($self->{subscription}) && $self->{subscription} ne '');
    return $cmd_options;
}

sub azure_get_publicip {
    my ($self, %options) = @_;

    my $cmd_options = $self->azure_get_log_analytics_set_cmd(%options);
    return $self->execute(cmd_options => $cmd_options);
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
