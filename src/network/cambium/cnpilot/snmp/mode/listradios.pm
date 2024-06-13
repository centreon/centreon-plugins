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

package network::cambium::cnpilot::snmp::mode::listradios;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    # Select relevant oids for discovery function for Radio CnPilot
    my $mapping = {
        cambiumRadioIndex      => { oid => '.1.3.6.1.4.1.17713.22.1.2.1.1' },
        cambiumRadioMACAddress => { oid => '.1.3.6.1.4.1.17713.22.1.2.1.2' },
        cambiumBandType        => { oid => '.1.3.6.1.4.1.17713.22.1.2.1.3' },
        cambiumRadioState      => { oid => '.1.3.6.1.4.1.17713.22.1.2.1.13' },
        cambiumRadioChannel    => { oid => '.1.3.6.1.4.1.17713.22.1.2.1.6' }
    };

    # Point at the begining of the table 
    my $oid_cambiumRadioEntry = '.1.3.6.1.4.1.17713.22.1.2.1';

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_cambiumRadioEntry,
        nothing_quit => 1
    );

    my $results = {};
    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{cambiumRadioMACAddress}->{oid}\.(.*)$/);
        # Catch instance in table
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        $results->{$result->{cambiumRadioMACAddress}} = {
            id => $result->{cambiumRadioIndex},
            name => $result->{cambiumRadioMACAddress},
            band_type => $result->{cambiumBandType},
            transmit_power => $result->{cambiumRadioState},
            radio_channel => $result->{cambiumRadioChannel}
        };
    }

    return $results;
}

sub run {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(snmp => $options{snmp});
    foreach my $oid_path (sort keys %$results) {
        $self->{output}->output_add(
            long_msg => sprintf(
                '[id: %s][name: %s][radio channel: %s][transmit power: %s][band type: %s]',
                $results->{$oid_path}->{id},
                $results->{$oid_path}->{name},
                $results->{$oid_path}->{radio_channel},
                $results->{$oid_path}->{transmit_power},
                $results->{$oid_path}->{band_type}
            )
        );
    }
    
    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List Radio'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['id', 'name', 'radio_channel', 'transmit_power', 'band_type']);
}

sub disco_show {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(snmp => $options{snmp});
    foreach my $oid_path (sort keys %$results) {
        $self->{output}->add_disco_entry(
            id => $results->{$oid_path}->{id},
            name => $results->{$oid_path}->{name},
            radio_channel => $results->{$oid_path}->{radio_channel},
            transmit_power => $results->{$oid_path}->{transmit_power},
            band_type => $results->{$oid_path}->{band_type}
        );
    }
}

1;

__END__

=head1 MODE

List radio interfaces.

=over 8

=back

=cut
