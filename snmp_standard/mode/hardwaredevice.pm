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

package snmp_standard::mode::hardwaredevice;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;
    
    $self->{cb_hook2} = 'snmp_execute';
    
    $self->{thresholds} = {
        default => [
            ['unknown', 'UNKNOWN'],
            ['running', 'OK'],
            ['warning', 'WARNING'],
            ['testing', 'OK'],
            ['down', 'CRITICAL'],
        ],
    };
    
    $self->{components_path} = 'snmp_standard::mode::components';
    $self->{components_module} = ['device'];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1, no_performance => 1, no_load_components => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

sub snmp_execute {
    my ($self, %options) = @_;
    
    $self->{snmp} = $options{snmp};
    $self->{results} = $self->{snmp}->get_multiple_table(oids => $self->{request});
}

1;

=head1 MODE

Check hardware devices (HOST-RESOURCES-MIB).

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'device'.

=item B<--filter>

Exclude some parts (comma seperated list)
Can also exclude specific instance: --filter=device,network.*

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='device.network,OK,down'

=back

=cut

package snmp_standard::mode::components::device;

use strict;
use warnings;
use centreon::plugins::misc;

my %map_status = (1 => 'unknown', 2 => 'running', 3 => 'warning', 4 => 'testing', 5 => 'down');
my %map_type = (
    '.1.3.6.1.2.1.25.3.1.1'     => 'other',
    '.1.3.6.1.2.1.25.3.1.2'     => 'unknown',
    '.1.3.6.1.2.1.25.3.1.3'     => 'processor',
    '.1.3.6.1.2.1.25.3.1.4'     => 'network',
    '.1.3.6.1.2.1.25.3.1.5'     => 'printer',
    '.1.3.6.1.2.1.25.3.1.6'     => 'diskStorage',
    '.1.3.6.1.2.1.25.3.1.10',   => 'video',
    '.1.3.6.1.2.1.25.3.1.11'    => 'audio',
    '.1.3.6.1.2.1.25.3.1.12'    => 'coprocessor',
    '.1.3.6.1.2.1.25.3.1.13'    => 'keyboard',
    '.1.3.6.1.2.1.25.3.1.14'    => 'modem',
    '.1.3.6.1.2.1.25.3.1.15'    => 'parallelPort',
    '.1.3.6.1.2.1.25.3.1.16'    => 'pointing',
    '.1.3.6.1.2.1.25.3.1.17'    => 'serialPort',
    '.1.3.6.1.2.1.25.3.1.18'    => 'tape',
    '.1.3.6.1.2.1.25.3.1.19'    => 'clock',
    '.1.3.6.1.2.1.25.3.1.20'    => 'volatileMemory',
    '.1.3.6.1.2.1.25.3.1.21'    => 'nonVolatileMemory',
);

my $mapping = {
    hrDeviceType    => { oid => '.1.3.6.1.2.1.25.3.2.1.2', map => \%map_type },
    hrDeviceDescr   => { oid => '.1.3.6.1.2.1.25.3.2.1.3' },
    hrDeviceStatus  => { oid => '.1.3.6.1.2.1.25.3.2.1.5', map => \%map_status },    
};
my $oid_hrDeviceEntry = '.1.3.6.1.2.1.25.3.2.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_hrDeviceEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking devices");
    $self->{components}->{device} = {name => 'devices', total => 0, skip => 0};
    return if ($self->check_filter(section => 'device'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_hrDeviceEntry}})) {
        next if ($oid !~ /^$mapping->{hrDeviceStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_hrDeviceEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'device', instance => $result->{hrDeviceType} . '.' . $instance));

        $result->{hrDeviceDescr} = centreon::plugins::misc::trim($result->{hrDeviceDescr});
        $self->{components}->{device}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("device '%s' status is '%s' [instance = %s]",
                                                        $result->{hrDeviceDescr}, $result->{hrDeviceStatus}, $result->{hrDeviceType} . '.' . $instance));
        my $exit = $self->get_severity(label => 'default', section => 'device.' . $result->{hrDeviceType}, value => $result->{hrDeviceStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Device '%s' status is '%s'", $result->{hrDeviceDescr}, $result->{hrDeviceStatus}));
        }
    }
}

1;
