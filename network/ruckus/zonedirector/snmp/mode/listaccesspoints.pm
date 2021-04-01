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

package network::ruckus::zonedirector::snmp::mode::listaccesspoints;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $map_zd_connection_status = {
    0 => 'disconnected', 1 => 'connected', 2 => 'approvalPending', 3 => 'upgradingFirmware', 4 => 'provisioning'
};

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
    description          => { oid => '.1.3.6.1.4.1.25053.1.2.2.1.1.2.1.1.2' }, # ruckusZDWLANAPDescription
    zd_connection_status => { oid => '.1.3.6.1.4.1.25053.1.2.2.1.1.2.1.1.3', map => $map_zd_connection_status },  # ruckusZDWLANAPStatus
    model                => { oid => '.1.3.6.1.4.1.25053.1.2.2.1.1.2.1.1.4' },  # ruckusZDWLANAPModel
    serial_number        => { oid => '.1.3.6.1.4.1.25053.1.2.2.1.1.2.1.1.5' }, # ruckusZDWLANAPSerialNumber
};
my $oid_ruckusZDWLANAPEntry = '.1.3.6.1.4.1.25053.1.2.2.1.1.2.1.1';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_ruckusZDWLANAPEntry,
        start => $mapping->{description}->{oid},
        end => $mapping->{serial_number}->{oid},
        nothing_quit => 1
    );

    my $accesspoints = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{description}->{oid}\.(.*)$/);
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
                '[description: %s] [serial number: %s] [model: %s] [zonedirector connection status: %s]',
                $accesspoints->{$_}->{description},
                $accesspoints->{$_}->{serial_number},
                $accesspoints->{$_}->{model},
                $accesspoints->{$_}->{zd_connection_status}
                
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
    
