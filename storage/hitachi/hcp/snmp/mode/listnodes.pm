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

package storage::hitachi::hcp::snmp::mode::listnodes;

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

my $map_node_status = {
    0 => 'unavailable', 4 => 'available'
};
my $mapping = {
    ip_address => { oid => '.1.3.6.1.4.1.116.5.46.1.1.1.2' }, # nodeIP
    status     => { oid => '.1.3.6.1.4.1.116.5.46.1.1.1.7', map => $map_node_status }  # nodeStatus 
};
my $oid_node_entry = '.1.3.6.1.4.1.116.5.46.1.1.1'; # hcpNodeTableEntry

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_node_entry,
        start => $mapping->{ip_address}->{oid},
        end => $mapping->{status}->{oid}
    );

    my $nodes = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{ip_address}->{oid}\.(.*)$/);
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $1);
        $nodes->{$1} = $result;
    }

    return $nodes;
}

sub run {
    my ($self, %options) = @_;
  
    my $nodes = $self->manage_selection(%options);
    foreach (sort keys %$nodes) {
        $self->{output}->output_add(
            long_msg => sprintf(
                '[id: %s] [ip address: %s] [status: %s]',
                $_,
                $nodes->{$_}->{ip_address},
                $nodes->{$_}->{status}
            )
        );
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List nodes:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['id', keys %$mapping]);
}

sub disco_show {
    my ($self, %options) = @_;

    my $nodes = $self->manage_selection(%options);
    foreach (sort keys %$nodes) { 
        $self->{output}->add_disco_entry(
            id => $_,
            %{$nodes->{$_}}
        );
    }
}

1;

__END__

=head1 MODE

List nodes.

=over 8

=back

=cut
    
