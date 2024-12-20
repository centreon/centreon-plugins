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

package network::smseagle::restapi::mode::modemstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "Modem Status: %s, SIM Status: %s, SIM Network Registration: %s",
        $self->{result_values}->{modem_enabled},
        $self->{result_values}->{sim_status},
        $self->{result_values}->{sim_network_registration_status}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'modem', type => 0 },
    ];

    $self->{maps_counters}->{modem} = [
        {
            label            => 'status',
            type             => 2,
            warning_default  => '',
            critical_default =>
                '%{sim_status} !~ /Operational/i or %{modem_enabled} =~ /false/i or %{sim_network_registration_status} !~ /Registered Home/i',
            set              =>
                {
                    key_values                     =>
                        [
                            { name => 'modem_enabled' },
                            { name => 'sim_status' },
                            { name => 'sim_network_registration_status' }
                        ],
                    closure_custom_output          => $self->can('custom_status_output'),
                    closure_custom_perfdata        => sub {return 0;},
                    closure_custom_threshold_check => \&catalog_status_threshold_ng,
                }
        },
        {
            label  => 'signal',
            nlabel => 'modem.signal.strength.percentage',
            set    => {
                key_values      => [ { name => 'signal_strength' } ],
                output_template => 'Signal : %.2f %%',
                perfdatas       => [ { template => '%s', unit => '%' } ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(
        arguments => { "modem-no:s" => { name => 'modem_no', default => 1 } }
    );

    $options{options}->add_help(package => __PACKAGE__, sections => 'SMS Eagle API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options);

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (centreon::plugins::misc::is_empty($self->{option_results}->{modem_no})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify --modem-no option.");
        $self->{output}->option_exit();
    }
}

sub get_modem_info($) {
    my ($self, %options) = @_;

    my ($response, $http_status_code, $api_response) = $options{custom}->request_api(
        method   => 'GET',
        endpoint => $options{endpoint}
    );

    if ($response == 1) {
        if ($http_status_code >= 400) {
            $self->{output}->add_option_msg(
                short_msg => "Could not get modem status. HTTP Status: $http_status_code. Response: $api_response"
            );
            $self->{output}->option_exit();
        }
    } else {
        $self->{output}->add_option_msg(
            short_msg => "Could not get modem status $options{endpoint}. Response: $api_response");
        $self->{output}->option_exit();
    }

    my $decoded;
    eval {
        $decoded = JSON::XS->new->utf8->decode($api_response);
    };
    if ($@) {
        $self->{output}->add_option_msg(
            short_msg => "Could not get modem status. An error occurred while decoding the response ('$api_response')."
        );
        $self->{output}->option_exit();
    }

    return $decoded;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $modem_no = $self->{option_results}->{modem_no};

    $options{endpoint} = "modem/status/$modem_no";
    my $response = $self->get_modem_info(%options);
    my $modem_enabled = $response->{modem_enabled} == 1 ? "true" : "false";

    $options{endpoint} = "modem/sim_status/$modem_no";
    $response = $self->get_modem_info(%options);
    my $sim_status = $response->{sim_status};

    $options{endpoint} = "modem/network_registration_status/$modem_no";
    $response = $self->get_modem_info(%options);
    my $sim_network_registration_status = $response->{sim_network_registration_status};

    $options{endpoint} = "modem/signal/$self->{option_results}->{modem_no}";
    $response = $self->get_modem_info(%options);
    my $signal_strength = $response->{signal_strength};

    $self->{modem} = {
        modem_enabled                   => $modem_enabled,
        sim_status                      => $sim_status,
        sim_network_registration_status => $sim_network_registration_status,
        signal_strength                 => $signal_strength
    };
}

1;

__END__

=head1 MODE

Check modem and SIM status.

=over 8

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{modem_enabled}, %{sim_status}, %{sim_network_registration_status}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{sim_status} !~ /Operational/i or %{modem_enabled} =~ /false/i or %{sim_network_registration_status} !~ /Registered Home/i'
You can use the following variables: %{modem_enabled}, %{sim_status}, %{sim_network_registration_status}


=item B<--warning-signal>

Warning threshold for signal strength.

=item B<--critical-signal>

Critical threshold  for signal strength.

=back

=cut
