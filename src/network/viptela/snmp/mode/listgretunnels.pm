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

package network::viptela::snmp::mode::listgretunnels;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use Socket;

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

my $map_status = {
    0 => 'down', 1 => 'up', 2 => 'invalid'
};
my $mapping = {
    sourceIp   => { oid => '.1.3.6.1.4.1.41916.4.5.2.1.3' }, # tunnelGreKeepalivesSourceIp
    destIp     => { oid => '.1.3.6.1.4.1.41916.4.5.2.1.4' }, # tunnelGreKeepalivesDestIp
    adminState => { oid => '.1.3.6.1.4.1.41916.4.5.2.1.5', map => $map_status }, # tunnelGreKeepalivesAdminState
    operState  => { oid => '.1.3.6.1.4.1.41916.4.5.2.1.6', map => $map_status }  # tunnelGreKeepalivesOperState
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_table = '.1.3.6.1.4.1.41916.4.5.2'; # tunnelGreKeepalivesTable
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_table,
        start => $mapping->{sourceIp}->{oid},
        end => $mapping->{operState}->{oid}
    );
    my $results = {};
    foreach (keys %$snmp_result) {
        next if (! /^$mapping->{sourceIp}->{oid}\.(.*)$/);

        $results->{$1} = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $1);
        $results->{$1}->{sourceIp} = inet_ntoa($results->{$1}->{sourceIp});
        $results->{$1}->{destIp} = inet_ntoa($results->{$1}->{destIp});
    }

    return $results;
}

sub run {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(snmp => $options{snmp});
    foreach my $instance (sort keys %$results) {
        $self->{output}->output_add(long_msg => 
            join('', map("[$_: " . $results->{$instance}->{$_} . ']', keys(%$mapping)))
        );
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List gre tunnels:'
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

    my $results = $self->manage_selection(snmp => $options{snmp});
    foreach (sort keys %$results) {        
        $self->{output}->add_disco_entry(
            %{$results->{$_}}
        );
    }
}
1;

__END__

=head1 MODE

List GRE tunnels.

=over 8

=back

=cut
