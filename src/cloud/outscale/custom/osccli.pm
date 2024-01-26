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

package cloud::outscale::custom::osccli;

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
            'profile:s'           => { name => 'profile' },
            'virtual-env:s'       => { name => 'virtual_env' },
            'timeout:s'           => { name => 'timeout', default => 50 },
            'sudo'                => { name => 'sudo' },
            'command:s'           => { name => 'command' },
            'command-path:s'      => { name => 'command_path' },
            'command-options:s'   => { name => 'command_options' },
            'proxyurl:s'          => { name => 'proxyurl' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'OSCCLI OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{custommode_name} = $options{custommode_name};

    return $self;
}

sub get_region {
    my ($self, %options) = @_;

    return $self->{option_results}->{region};
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

    if (defined($self->{option_results}->{virtual_env}) && $self->{option_results}->{virtual_env} ne '') {
        $ENV{VIRTUAL_ENV} = $self->{option_results}->{virtual_env};
        $ENV{PATH} = "$ENV{VIRTUAL_ENV}/bin:$ENV{PATH}";
    }

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

    my $command = defined($self->{option_results}->{command}) && $self->{option_results}->{command} ne '' ? $self->{option_results}->{command} : 'osc-cli';

    my $cmd_options = $options{cmd_options};

    $self->{output}->output_add(long_msg => "Command line: '" . $command . " " . $cmd_options . "'", debug => 1);

    my ($response) = centreon::plugins::misc::execute(
        output => $self->{output},
        options => $self->{option_results},
        sudo => $self->{option_results}->{sudo},
        command => $command,
        command_path => $self->{option_results}->{command_path},
        command_options => $cmd_options,
        redirect_stderr => ($self->{output}->is_debug()) ? 0 : 1
    );

    my $raw_results = {};

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

sub load_balancer_read_set_cmd {
    my ($self, %options) = @_;

    return $self->{option_results}->{command_options} if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');

    my $cmd_options = 'api ReadLoadBalancers';
    $cmd_options .= " --profile '$self->{option_results}->{profile}'" if (defined($self->{option_results}->{profile}) && $self->{option_results}->{profile} ne '');

    return $cmd_options;
}

sub load_balancer_read {
    my ($self, %options) = @_;

    my $cmd_options = $self->load_balancer_read_set_cmd(%options);
    my $raw_results = $self->execute(cmd_options => $cmd_options);

    return $raw_results->{LoadBalancers};
}

sub read_vms_health_set_cmd {
    my ($self, %options) = @_;

    return $self->{option_results}->{command_options} if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');

    my $cmd_options = 'api ReadVmsHealth';
    $cmd_options .= " --profile '$self->{option_results}->{profile}'" if (defined($self->{option_results}->{profile}) && $self->{option_results}->{profile} ne '');
    $cmd_options .= " --LoadBalancerName '$options{load_balancer_name}'";

    return $cmd_options;
}

sub read_vms_health {
    my ($self, %options) = @_;

    my $cmd_options = $self->read_vms_health_set_cmd(%options);
    my $raw_results = $self->execute(cmd_options => $cmd_options);

    return $raw_results->{BackendVmHealth};
}

sub read_vms_set_cmd {
    my ($self, %options) = @_;

    return $self->{option_results}->{command_options} if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');

    my $cmd_options = 'api ReadVms';
    $cmd_options .= " --profile '$self->{option_results}->{profile}'" if (defined($self->{option_results}->{profile}) && $self->{option_results}->{profile} ne '');

    return $cmd_options;
}

sub read_vms {
    my ($self, %options) = @_;

    my $cmd_options = $self->read_vms_set_cmd(%options);
    my $raw_results = $self->execute(cmd_options => $cmd_options);

    return $raw_results->{Vms};
}

sub read_client_gateways_set_cmd {
    my ($self, %options) = @_;

    return $self->{option_results}->{command_options} if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');

    my $cmd_options = 'api ReadClientGateways';
    $cmd_options .= " --profile '$self->{option_results}->{profile}'" if (defined($self->{option_results}->{profile}) && $self->{option_results}->{profile} ne '');

    return $cmd_options;
}

sub read_client_gateways {
    my ($self, %options) = @_;

    my $cmd_options = $self->read_client_gateways_set_cmd(%options);
    my $raw_results = $self->execute(cmd_options => $cmd_options);

    return $raw_results->{ClientGateways};
}

sub read_consumption_account_set_cmd {
    my ($self, %options) = @_;

    return $self->{option_results}->{command_options} if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');

    my $cmd_options = 'api ReadConsumptionAccount';
    $cmd_options .= " --profile '$self->{option_results}->{profile}'" if (defined($self->{option_results}->{profile}) && $self->{option_results}->{profile} ne '');
    $cmd_options .= " --FromDate '$options{from_date}' --ToDate '$options{to_date}'";

    return $cmd_options;
}

sub read_consumption_account {
    my ($self, %options) = @_;

    my $cmd_options = $self->read_consumption_account_set_cmd(%options);
    my $raw_results = $self->execute(cmd_options => $cmd_options);

    return $raw_results->{ConsumptionEntries};
}

sub read_virtual_gateways_set_cmd {
    my ($self, %options) = @_;

    return $self->{option_results}->{command_options} if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');

    my $cmd_options = 'api ReadVirtualGateways';
    $cmd_options .= " --profile '$self->{option_results}->{profile}'" if (defined($self->{option_results}->{profile}) && $self->{option_results}->{profile} ne '');

    return $cmd_options;
}

sub read_virtual_gateways {
    my ($self, %options) = @_;

    my $cmd_options = $self->read_virtual_gateways_set_cmd(%options);
    my $raw_results = $self->execute(cmd_options => $cmd_options);

    return $raw_results->{VirtualGateways};
}

sub read_vpn_connections_set_cmd {
    my ($self, %options) = @_;

    return $self->{option_results}->{command_options} if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');

    my $cmd_options = 'api ReadVpnConnections';
    $cmd_options .= " --profile '$self->{option_results}->{profile}'" if (defined($self->{option_results}->{profile}) && $self->{option_results}->{profile} ne '');

    return $cmd_options;
}

sub read_vpn_connections {
    my ($self, %options) = @_;

    my $cmd_options = $self->read_vpn_connections_set_cmd(%options);
    my $raw_results = $self->execute(cmd_options => $cmd_options);

    return $raw_results->{VpnConnections};
}

sub read_volumes_set_cmd {
    my ($self, %options) = @_;

    return $self->{option_results}->{command_options} if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');

    my $cmd_options = 'api ReadVolumes';
    $cmd_options .= " --profile '$self->{option_results}->{profile}'" if (defined($self->{option_results}->{profile}) && $self->{option_results}->{profile} ne '');

    return $cmd_options;
}

sub read_volumes {
    my ($self, %options) = @_;

    my $cmd_options = $self->read_volumes_set_cmd(%options);
    my $raw_results = $self->execute(cmd_options => $cmd_options);

    return $raw_results->{Volumes};
}

sub read_nets_set_cmd {
    my ($self, %options) = @_;

    return $self->{option_results}->{command_options} if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');

    my $cmd_options = 'api ReadNets';
    $cmd_options .= " --profile '$self->{option_results}->{profile}'" if (defined($self->{option_results}->{profile}) && $self->{option_results}->{profile} ne '');

    return $cmd_options;
}

sub read_nets {
    my ($self, %options) = @_;

    my $cmd_options = $self->read_nets_set_cmd(%options);
    my $raw_results = $self->execute(cmd_options => $cmd_options);

    return $raw_results->{Nets};
}

sub read_quotas_set_cmd {
    my ($self, %options) = @_;

    return $self->{option_results}->{command_options} if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');

    my $cmd_options = 'api ReadQuotas';
    $cmd_options .= " --profile '$self->{option_results}->{profile}'" if (defined($self->{option_results}->{profile}) && $self->{option_results}->{profile} ne '');

    return $cmd_options;
}

sub read_quotas {
    my ($self, %options) = @_;

    my $cmd_options = $self->read_quotas_set_cmd(%options);
    my $raw_results = $self->execute(cmd_options => $cmd_options);

    return $raw_results->{QuotaTypes};
}

sub read_subnets_set_cmd {
    my ($self, %options) = @_;

    return $self->{option_results}->{command_options} if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');

    my $cmd_options = 'api ReadSubnets';
    $cmd_options .= " --profile '$self->{option_results}->{profile}'" if (defined($self->{option_results}->{profile}) && $self->{option_results}->{profile} ne '');

    return $cmd_options;
}

sub read_subnets {
    my ($self, %options) = @_;

    my $cmd_options = $self->read_subnets_set_cmd(%options);
    my $raw_results = $self->execute(cmd_options => $cmd_options);

    return $raw_results->{Subnets};
}

sub read_route_tables_set_cmd {
    my ($self, %options) = @_;

    return $self->{option_results}->{command_options} if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');

    my $cmd_options = 'api ReadRouteTables';
    $cmd_options .= " --profile '$self->{option_results}->{profile}'" if (defined($self->{option_results}->{profile}) && $self->{option_results}->{profile} ne '');

    return $cmd_options;
}

sub read_route_tables {
    my ($self, %options) = @_;

    my $cmd_options = $self->read_route_tables_set_cmd(%options);
    my $raw_results = $self->execute(cmd_options => $cmd_options);

    return $raw_results->{RouteTables};
}

sub read_internet_services_set_cmd {
    my ($self, %options) = @_;

    return $self->{option_results}->{command_options} if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');

    my $cmd_options = 'api ReadInternetServices';
    $cmd_options .= " --profile '$self->{option_results}->{profile}'" if (defined($self->{option_results}->{profile}) && $self->{option_results}->{profile} ne '');

    return $cmd_options;
}

sub read_internet_services {
    my ($self, %options) = @_;

    my $cmd_options = $self->read_internet_services_set_cmd(%options);
    my $raw_results = $self->execute(cmd_options => $cmd_options);

    return $raw_results->{InternetServices};
}

sub read_nat_services_set_cmd {
    my ($self, %options) = @_;

    return $self->{option_results}->{command_options} if (defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '');

    my $cmd_options = 'api ReadNatServices';
    $cmd_options .= " --profile '$self->{option_results}->{profile}'" if (defined($self->{option_results}->{profile}) && $self->{option_results}->{profile} ne '');

    return $cmd_options;
}

sub read_nat_services {
    my ($self, %options) = @_;

    my $cmd_options = $self->read_nat_services_set_cmd(%options);
    my $raw_results = $self->execute(cmd_options => $cmd_options);

    return $raw_results->{NatServices};
}

1;

__END__

=head1 NAME

Outscale

=head1 OSCCLI OPTIONS

Outscale CLI

=over 8

=item B<--profile>

Set profile option.

=item B<--virtual-env>

Set python virtual environment (to be used if osc-cli is installed in python venv).

=item B<--timeout>

Set timeout in seconds (default: 50).

=item B<--sudo>

Use 'sudo' to execute the command.

=item B<--command>

Command to get information (default: 'osc-cli').
Can be changed if you have output in a file.

=item B<--command-path>

Command path (default: none).

=item B<--command-options>

Command options (default: none).
Only use for testing purpose, when you want to set ALL parameters of a command by yourself.

=item B<--proxyurl>

Proxy URL if any

=back

=head1 DESCRIPTION

B<custom>.

=cut
