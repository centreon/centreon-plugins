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

package network::fortinet::fortiadc::snmp::mode::listvirtualservers;

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

my $mapping = {
    name   => { oid => '.1.3.6.1.4.1.12356.112.3.2.1.2' }, # fadcVSName
    state  => { oid => '.1.3.6.1.4.1.12356.112.3.2.1.3' }, # fadcVSStatus
    status => { oid => '.1.3.6.1.4.1.12356.112.3.2.1.4' }, # fadcVSHealth
    vdom   => { oid => '.1.3.6.1.4.1.12356.112.3.2.1.8' }  # fadcVSVdom
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_table = '.1.3.6.1.4.1.12356.112.3.2'; # fadcVSTable
    my $snmp_result = $options{snmp}->get_table(oid => $oid_table);
    my $results = {};
    foreach (keys %$snmp_result) {
        next if (! /^$mapping->{name}->{oid}\.(.*)$/);

        $results->{$1} = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $1);
        $results->{$1}->{state} = lc($results->{$1}->{state});
        $results->{$1}->{status} = lc($results->{$1}->{status});
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
        short_msg => 'List virtual servers:'
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

List virtual servers.

=over 8

=back

=cut
