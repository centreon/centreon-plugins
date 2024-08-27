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

package apps::thales::mistral::vs9::restapi::mode::discovery;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use JSON::XS;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'resource-type:s' => { name => 'resource_type' },
        'prettify'        => { name => 'prettify' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{resource_type}) || $self->{option_results}->{resource_type} eq '') {
        $self->{option_results}->{resource_type} = 'device';
    }
    if ($self->{option_results}->{resource_type} !~ /^device|mmc$/) {
        $self->{output}->add_option_msg(short_msg => 'unknown resource type');
        $self->{output}->option_exit();
    }
}

sub discovery_device {
    my ($self, %options) = @_;

    my $devices = $options{custom}->request_api(
        endpoint => '/ssIpsecGwHws',
        get_param => ['projection=gatewayHwData']
    );

    my $disco_data = [];
    foreach my $device (@{$devices->{content}}) {
        my $entry = {};
        $entry->{id} = $device->{id};
        $entry->{name} = defined($device->{name}) ? $device->{name} : '';
        $entry->{serial_number} = $device->{serialNumber};
        $entry->{firmware_version_current} = $device->{firmwareVersionCurrent};
        $entry->{firmware_version_other} = $device->{firmwareVersionOther};
        $entry->{product_name} = $device->{productName};
        $entry->{platform_model} = $device->{platformModel};
        $entry->{description} = defined($device->{description}) ? $device->{description} : '';

        $entry->{physical_interfaces} = [];
        if (defined($device->{physicalInterfaces})) {
            foreach my $int (@{$device->{physicalInterfaces}}) {
                push @{$entry->{physical_interfaces}}, {
                    name => $int->{name},
                    physical_address => defined($int->{physicalAddress}) ? $int->{physicalAddress} : '',
                    connection_type => $int->{connectionType},
                    domain => $int->{domain}
                };
            }
        }

        $entry->{gateway_name} = defined($device->{gatewayConf}) ? $device->{gatewayConf}->{name} : '';
        $entry->{gateway_responder_only} = '';
        $entry->{gateway_responder_only} = $device->{gatewayConf}->{responderOnly} =~ /true|1/i ? 'yes' : 'no'
            if (defined($device->{gatewayConf}) && defined($device->{gatewayConf}->{responderOnly}));
        $entry->{gateway_administration_ip} = defined($device->{gatewayConf}) ? $device->{gatewayConf}->{administrationIp} : '';
        $entry->{gateway_active} = '';
        $entry->{gateway_active} = $device->{gatewayConf}->{active} =~ /true|1/i ? 'yes' : 'no' if (defined($device->{gatewayConf}));
        $entry->{gateway_offline} = '';
        $entry->{gateway_offline} = $device->{gatewayConf}->{offline} =~ /true|1/i ? 'yes' : 'no' if (defined($device->{gatewayConf}));
        $entry->{gateway_private_address} = defined($device->{gatewayConf}) ? $device->{gatewayConf}->{privateAddress}->{address} : '';
        $entry->{gateway_private_address_netmask} = defined($device->{gatewayConf}) ? $device->{gatewayConf}->{privateAddress}->{netmask} : '';

        $entry->{gateway_blackIpRemote_address} = '';
        $entry->{gateway_blackIpRemote_address_netmask} = '';
        if (defined($device->{gatewayConf}) && defined($device->{gatewayConf}->{gatewayBlackIpRemote})) {
            $entry->{gateway_blackIpRemote_address} = $device->{gatewayConf}->{gatewayBlackIpRemote}->{address};
            $entry->{gateway_blackIpRemote_address_netmask} = $device->{gatewayConf}->{gatewayBlackIpRemote}->{netmask};
        }

        push @$disco_data, $entry;
    }

    return $disco_data;
}

sub discovery_mmc {
    my ($self, %options) = @_;

    my $mmcs = $options{custom}->request_api(
        endpoint => '/managementCenters',
        get_param => ['projection=managementCenterSmall']
    );

    my $disco_data = [];
    foreach my $mmc (@{$mmcs->{content}}) {
        my $entry = {};
        $entry->{id} = $mmc->{id};
        $entry->{name} = $mmc->{name};
        $entry->{ip} = $mmc->{ipAddress};

        push @$disco_data, $entry;
    }

    return $disco_data;
}

sub run {
    my ($self, %options) = @_;

    my $disco_stats;
    $disco_stats->{start_time} = time();

    my $results = [];
    if ($self->{option_results}->{resource_type} eq 'device') {
        $results = $self->discovery_device(
            custom => $options{custom}
        );
    } elsif ($self->{option_results}->{resource_type} eq 'mmc') {
        $results = $self->discovery_mmc(
            custom => $options{custom}
        );
    }

    $disco_stats->{end_time} = time();
    $disco_stats->{duration} = $disco_stats->{end_time} - $disco_stats->{start_time};
    $disco_stats->{discovered_items} = scalar(@$results);
    $disco_stats->{results} = $results;

    my $encoded_data;
    eval {
        if (defined($self->{option_results}->{prettify})) {
            $encoded_data = JSON::XS->new->utf8->canonical(1)->pretty->encode($disco_stats);
        } else {
            $encoded_data = JSON::XS->new->utf8->canonical(1)->encode($disco_stats);
        }
    };
    if ($@) {
        $encoded_data = '{"code":"encode_error","message":"Cannot encode discovered data into JSON format"}';
    }
    
    $self->{output}->output_add(short_msg => $encoded_data);
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1);
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Resources discovery.

=over 8

=item B<--resource-type>

Choose the type of resources to discover (can be: 'device', 'mmc').

=back

=cut
