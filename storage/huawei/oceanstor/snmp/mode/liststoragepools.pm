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

package storage::huawei::oceanstor::snmp::mode::liststoragepools;

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
    name           => { oid => '.1.3.6.1.4.1.34774.4.1.23.4.2.1.2' }, # hwInfoStoragePoolName
    domain_name    => { oid => '.1.3.6.1.4.1.34774.4.1.23.4.2.1.4' }, # hwInfoStoragePoolDiskDomainName
    health_status  => { oid => '.1.3.6.1.4.1.34774.4.1.23.4.2.1.5', map => $health_status }, # hwInfoStoragePoolHealthStatus
    running_status => { oid => '.1.3.6.1.4.1.34774.4.1.23.4.2.1.6', map => $running_status }, # hwInfoStoragePoolRunningStatus
};
my $oid_sp_entry = '.1.3.6.1.4.1.34774.4.1.23.4.2.1'; # hwInfoStoragePoolEntry

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_sp_entry,
        end => $mapping->{running_status}->{oid}
    );

    my $sp = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{name}->{oid}\.(.*)$/);
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $1);
        $sp->{$1} = $result;
    }

    return $sp;
}

sub run {
    my ($self, %options) = @_;
  
    my $sp = $self->manage_selection(%options);
    foreach (sort keys %$sp) {
        $self->{output}->output_add(
            long_msg => sprintf(
                '[name: %s] [domain name: %s] [health status: %s] [running status: %s]',
                $sp->{$_}->{name},
                $sp->{$_}->{domain_name},
                $sp->{$_}->{health_status},
                $sp->{$_}->{running_status}
            )
        );
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List storage pools:'
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

    my $sp = $self->manage_selection(%options);
    foreach (sort keys %$sp) { 
        $self->{output}->add_disco_entry(
            %{$sp->{$_}}
        );
    }
}

1;

__END__

=head1 MODE

List storage pools.

=over 8

=back

=cut
    
