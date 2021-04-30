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

package network::cisco::wap::snmp::mode::clients;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_radio_output {
    my ($self, %options) = @_;

    return sprintf(
        "Radio interface '%s' ",
        $options{instance_value}->{name}
    );
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'radios', type => 1, cb_prefix_output => 'prefix_radio_output' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'clients-connected', nlabel => 'clients.connected.count', set => {
                key_values => [ { name => 'clients_connected' } ],
                output_template => 'clients connected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{radios} = [
        { label => 'radio-clients-connected', nlabel => 'radio.clients.connected.count', set => {
                key_values => [ { name => 'clients_connected' } ],
                output_template => 'clients connected: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'filter-radio-name:s' => { name => 'filter_radio_name' }
    });

    return $self;
}

my $map_status = { 0 => 'down', 1 => 'up' };

my $mapping_radio = {
    admin_status => { oid => '.1.3.6.1.4.1.9.6.1.104.1.6.1.1.2', map => $map_status }, # apRadioStatus
    name         => { oid => '.1.3.6.1.4.1.9.6.1.104.1.6.1.1.3' } # apRadioName
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_radio_table = '.1.3.6.1.4.1.9.6.1.104.1.6.1'; # apRadioTable
    my $oid_assoc_interface = '.1.3.6.1.4.1.9.6.1.104.1.7.1.1.2'; # apAssocInterface
    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_radio_table, start => $mapping_radio->{admin_status}->{oid}, end => $mapping_radio->{name}->{oid} },
            { oid => $oid_assoc_interface }
        ],
        nothing_quit => 1
    );

    $self->{global} = { clients_connected => 0 };
    $self->{radios} = {};
    foreach (keys %{$snmp_result->{$oid_radio_table}}) {
        next if (! /^$mapping_radio->{name}->{oid}\.(.*)$/);

        my $result = $options{snmp}->map_instance(mapping => $mapping_radio, results => $snmp_result->{$oid_radio_table}, instance => $1);
        next if ($result->{admin_status} eq 'down');
        if (defined($self->{option_results}->{filter_radio_name}) && $self->{option_results}->{filter_radio_name} ne '' &&
            $result->{name} !~ /$self->{option_results}->{filter_radio_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{name} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{radios}->{ $result->{name} } = {
            name => $result->{name},
            clients_connected => 0
        };
    }

    foreach (keys %{$snmp_result->{$oid_assoc_interface}}) {
        next if (!defined($self->{radios}->{ $snmp_result->{$oid_assoc_interface}->{$_} }));
        $self->{radios}->{ $snmp_result->{$oid_assoc_interface}->{$_} }->{clients_connected}++;
        $self->{global}->{clients_connected}++;
    }
}

1;

__END__

=head1 MODE

Check clients connected.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^clients'

=item B<--filter-radio-name>

Filter radio interfaces by name (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'clients-connected', 'radio-clients-connected'.

=back

=cut
