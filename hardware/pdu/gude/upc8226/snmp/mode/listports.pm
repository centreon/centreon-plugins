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

package hardware::pdu::gude::upc8226::snmp::mode::listports;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

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

my $epc8226portEntry = '.1.3.6.1.4.1.28507.58.1.3.1.2.1';
my $port_status_mapping = {
        0 => 'off',
        1 => 'on'
    };
my $ports_mapping = {
        epc8226PortName  => { oid => '.1.3.6.1.4.1.28507.58.1.3.1.2.1.2', label => 'port_name' },
        epc8226PortState => { oid => '.1.3.6.1.4.1.28507.58.1.3.1.2.1.3', label => 'port_status', map => $port_status_mapping }
    };

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(oid => $epc8226portEntry);
    my $ports_result;
    foreach my $port_oid (keys %{$snmp_result}) {
        next if ($port_oid !~ /^$ports_mapping->{epc8226PortName}->{oid}\.(.*)$/);
        my $instance = $1;
        $ports_result->{$instance} = $options{snmp}->map_instance(mapping => $ports_mapping, results => $snmp_result, instance => $instance);
    };

    foreach (keys %{$ports_result}) {
        $self->{ports}->{$_}->{id} = $_,
        $self->{ports}->{$_}->{name} = $ports_result->{$_}->{epc8226PortName},
        $self->{ports}->{$_}->{state} = $ports_result->{$_}->{epc8226PortState}
    }
}

sub run {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $instance (sort keys %{$self->{ports}}) {
        $self->{output}->output_add(
            long_msg => sprintf("[id = %s] [name = %s] [state = %s]",
                $self->{ports}->{$instance}->{id},
                $self->{ports}->{$instance}->{name},
                $self->{ports}->{$instance}->{state}
            )
        );
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List ports:'
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

    $self->manage_selection(%options);
    foreach my $instance (sort keys %{$self->{ports}}) {
        $self->{output}->add_disco_entry(
            id    => $self->{ports}->{$instance}->{id},
            name  => $self->{ports}->{$instance}->{name},
            state => $self->{ports}->{$instance}->{state}
        );
    }
}

1;

__END__

=head1 MODE

List ports.

=over 8

=back

=cut
