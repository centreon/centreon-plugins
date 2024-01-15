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

package hardware::pdu::gude::epc::snmp::mode::listsppowerchannels;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use hardware::pdu::gude::epc::snmp::mode::resources;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {});

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $branch = hardware::pdu::gude::epc::snmp::mode::resources::find_gude_branch($self, snmp => $options{snmp});

    my $oid_entry = $branch . '.1.3.1.2.1';
    my $port_status_mapping = {
        0 => 'off', 1 => 'on'
    };
    my $sp_mapping = {
        name  => { oid => $branch . '.1.3.1.2.1.2' },
        state => { oid => $branch . '.1.3.1.2.1.3', map => $port_status_mapping }
    };

    my $snmp_result = $options{snmp}->get_table(oid => $oid_entry);
    my $ports = {};
    foreach my $port_oid (keys %$snmp_result) {
        next if ($port_oid !~ /^$sp_mapping->{name}->{oid}\.(.*)$/);
        my $instance = $1;
        $ports->{$instance} = $options{snmp}->map_instance(mapping => $sp_mapping, results => $snmp_result, instance => $instance);
    };

    return $ports;
}

sub run {
    my ($self, %options) = @_;

    my $ports = $self->manage_selection(%options);
    foreach my $instance (sort keys %$ports) {
        $self->{output}->output_add(
            long_msg => sprintf(
                "[id: %s][name: %s][state: %s]",
                $instance,
                $ports->{$instance}->{name},
                $ports->{$instance}->{state}
            )
        );
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List single port power channel interfaces:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['id', 'name', 'state']);
}

sub disco_show {
    my ($self, %options) = @_;

    my $ports = $self->manage_selection(%options);
    foreach my $instance (sort keys %$ports) {
        $self->{output}->add_disco_entry(
            id    => $instance,
            name  => $ports->{$instance}->{name},
            state => $ports->{$instance}->{state}
        );
    }
}

1;

__END__

=head1 MODE

List single port power channel interfaces.

=over 8

=back

=cut
