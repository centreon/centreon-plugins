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

package storage::huawei::oceanstor::snmp::mode::listluns;

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
    name       => { oid => '.1.3.6.1.4.1.34774.4.1.23.4.8.1.2' }, # hwInfoLunName
    capacity   => { oid => '.1.3.6.1.4.1.34774.4.1.23.4.8.1.5' }, # hwInfoLunCapacity (MB)
    usage      => { oid => '.1.3.6.1.4.1.34774.4.1.23.4.8.1.6' }, # hwInfoLunSubscribedCapacity (MB)
    protection => { oid => '.1.3.6.1.4.1.34774.4.1.23.4.8.1.7' }, # hwInfoLunProtectionCapacity (KB)
    isexposed  => { oid => '.1.3.6.1.4.1.34774.4.1.23.4.8.1.14'}, # hwInfoLunExposedToInitiator (1 if exposed, 0 if not, i.e : snapshot are not exposed by default) 
};
my $oid_lun_entry = '.1.3.6.1.4.1.34774.4.1.23.4.8.1'; # hwInfoLunTable

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(oid => $oid_lun_entry);

    my $lun = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{name}->{oid}\.(.*)$/);
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $1);
        next if ($result->{isexposed} == 0);

        $lun->{$1} = $result;
    }

    return $lun;
}

sub run {
    my ($self, %options) = @_;

    my $lun = $self->manage_selection(%options);
    foreach (sort keys %$lun) {
        $self->{output}->output_add(
            long_msg => sprintf(
                '[exposed: %s] [name: %s] [capacity: %s] [usage: %s] [protection: %s]',
                $lun->{$_}->{isexposed},
                $lun->{$_}->{name},
                $lun->{$_}->{capacity}*1024*1024,
                $lun->{$_}->{usage}*1024*1024,
                $lun->{$_}->{protection}*1024                
            )
        );
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List LUNs:'
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

    my $lun = $self->manage_selection(%options);
    foreach (sort keys %$lun) { 
        $self->{output}->add_disco_entry(%{$lun->{$_}});
    }
}

1;

__END__

=head1 MODE

List LUNs.

=over 8

=back

=cut
