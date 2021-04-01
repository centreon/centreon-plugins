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

package network::ruckus::smartzone::snmp::mode::listaccesspoints;

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

my $mapping = {
    name                => { oid => '.1.3.6.1.4.1.25053.1.4.2.1.1.2.2.1.5' }, # ruckusSZAPName
    model               => { oid => '.1.3.6.1.4.1.25053.1.4.2.1.1.2.2.1.8' }, # ruckusSZAPModel
    serial_number       => { oid => '.1.3.6.1.4.1.25053.1.4.2.1.1.2.2.1.9' }, # ruckusSZAPSerial
    connection_status   => { oid => '.1.3.6.1.4.1.25053.1.4.2.1.1.2.2.1.16' }, # ruckusSZAPConnStatus
    registration_status => { oid => '.1.3.6.1.4.1.25053.1.4.2.1.1.2.2.1.17' }, # ruckusSZAPRegStatus
    config_status       => { oid => '.1.3.6.1.4.1.25053.1.4.2.1.1.2.2.1.18' }, # ruckusSZAPConfigStatus    
};
my $oid_ruckusSZAPEntry = '.1.3.6.1.4.1.25053.1.4.2.1.1.2.2.1';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_ruckusSZAPEntry,
        start => $mapping->{name}->{oid},
        end => $mapping->{config_status}->{oid},
        nothing_quit => 1
    );

    my $accesspoints = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{name}->{oid}\.(.*)$/);
        my $instance = $1;
        $accesspoints->{$instance} = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
    }

    return $accesspoints;
}

sub run {
    my ($self, %options) = @_;
  
    my $accesspoints = $self->manage_selection(%options);
    foreach (sort keys %$accesspoints) {
        $self->{output}->output_add(
            long_msg => sprintf(
                '[name: %s] [serial number: %s] [model: %s] [connection status: %s] [config status: %s] [registration status: %s]',
                $accesspoints->{$_}->{name},
                $accesspoints->{$_}->{serial_number},
                $accesspoints->{$_}->{model},
                $accesspoints->{$_}->{connection_status},
                $accesspoints->{$_}->{config_status},
                $accesspoints->{$_}->{registration_status}
            )
        );
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List acess points:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => [keys %$mapping]);
}

sub disco_show {
    my ($self, %options) = @_;

    my $accesspoints = $self->manage_selection(%options);
    foreach (sort keys %$accesspoints) { 
        $self->{output}->add_disco_entry(
            %{$accesspoints->{$_}}
        );
    }
}

1;

__END__

=head1 MODE

List acess points.

=over 8

=back

=cut
    
