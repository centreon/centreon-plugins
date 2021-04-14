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

package apps::microsoft::dhcp::snmp::mode::listsubnets;

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
    address        => { oid => '.1.3.6.1.4.1.311.1.3.2.1.1.1' }, # subnetAdd
    used           => { oid => '.1.3.6.1.4.1.311.1.3.2.1.1.2' }, # noAddInUse
    free           => { oid => '.1.3.6.1.4.1.311.1.3.2.1.1.3' }, # noAddFree
    pending_offers => { oid => '.1.3.6.1.4.1.311.1.3.2.1.1.4' }  # noPendingOffers
};
my $oid_scope_table = '.1.3.6.1.4.1.311.1.3.2.1.1';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(oid => $oid_scope_table);

    my $results = {};
    foreach (keys %$snmp_result) {
        next if (! /^$mapping->{address}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $1);

        my $status = 'enabled';
        if ($result->{free} == 0 && $result->{used} == 0 && $result->{pending_offers} == 0) {
            $status = 'disabled';
        }
        $results->{$instance} = { address => $result->{address}, status => $status };
    }

    return $results;
}

sub run {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(snmp => $options{snmp});
    foreach (sort keys %$results) {
        $self->{output}->output_add(long_msg => 
            sprintf(
                '[address: %s][status: %s]',
                $results->{$_}->{address},
                $results->{$_}->{status}
            )
        );
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List subnets:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['address', 'status']);
}

sub disco_show {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(snmp => $options{snmp});
    foreach (sort keys %$results) {        
        $self->{output}->add_disco_entry(%{$results->{$_}});
    }
}

1;

__END__

=head1 MODE

List dhcp subnets.

=over 8

=back

=cut
