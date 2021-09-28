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

package storage::huawei::oceanstor::snmp::mode::listcontrollers;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use storage::huawei::oceanstor::snmp::mode::resources qw($health_status $running_status);

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
    id             => { oid => '.1.3.6.1.4.1.34774.4.1.23.5.2.1.1' }, # hwInfoControllerID
    health_status  => { oid => '.1.3.6.1.4.1.34774.4.1.23.5.2.1.2', map => $health_status }, # hwInfoControllerHealthStatus
    running_status => { oid => '.1.3.6.1.4.1.34774.4.1.23.5.2.1.3', map => $running_status }, # hwInfoControllerRunningStatus
};
my $oid_controller_entry = '.1.3.6.1.4.1.34774.4.1.23.5.2.1'; # hwInfoControllerEntry

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_controller_entry,
        end => $mapping->{running_status}->{oid}
    );

    my $controllers = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{id}->{oid}\.(.*)$/);
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $1);
        $controllers->{$1} = $result;
    }

    return $controllers;
}

sub run {
    my ($self, %options) = @_;
  
    my $controllers = $self->manage_selection(%options);
    foreach (sort keys %$controllers) {
        $self->{output}->output_add(
            long_msg => sprintf(
                '[id: %s] [health status: %s] [running status: %s]',
                $controllers->{$_}->{id},
                $controllers->{$_}->{health_status},
                $controllers->{$_}->{running_status}
            )
        );
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List controllers:'
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

    my $controllers = $self->manage_selection(%options);
    foreach (sort keys %$controllers) { 
        $self->{output}->add_disco_entry(
            %{$controllers->{$_}}
        );
    }
}

1;

__END__

=head1 MODE

List controllers.

=over 8

=back

=cut
    
