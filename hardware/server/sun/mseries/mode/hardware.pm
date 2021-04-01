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

package hardware::server::sun::mseries::mode::hardware;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;
use Digest::MD5 qw(md5_hex);

my %components_board_types = (
    1 => 'cmu',
    2 => 'ddc',
    3 => 'cpum',
    4 => 'cpuChip',
    5 => 'cpuCore',
    6 => 'cpuStrand',
    7 => 'way',
    9 => 'mem',
    10 => 'sc',
    11 => 'tag',
    12 => 'xsb',
    13 => 'mac',
    14 => 'bank',
    15 => 'block',
    16 => 'xbuA',
    17 => 'half',
    19 => 'xbuB',
    21 => 'iou',
    23 => 'pcir',
    24 => 'ioc',
    25 => 'flp',
    26 => 'iocCh',
    27 => 'iocLeaf',
    28 => 'hdd',
    29 => 'pci',
    30 => 'pcic',
    31 => 'xscfA',
    32 => 'xscfB',
    33 => 'xscfC',
    34 => 'clkuA',
    36 => 'clkuB',
    38 => 'psubpA',
    39 => 'psubpB',
    40 => 'acsA',
    41 => 'acsB',
    42 => 'psu',
    43 => 'bpA',
    44 => 'bpB',
    45 => 'ddcA',
    46 => 'fanbpA',
    47 => 'fanbpB',
    48 => 'fanbpC',
    49 => 'fanA',
    50 => 'fan',
    51 => 'fanB',
    53 => 'opnl',
    54 => 'tape',
    55 => 'dvd',
    56 => 'swbp',
    57 => 'medbp',
    96 => 'mbuA',
    97 => 'riser',
    98 => 'pcmu',
    100 => 'ddcB',
    110 => 'memb',
    115 => 'mbuB',
    133 => 'bpuA',
    134 => 'iob',
    135 => 'pdb',
    136 => 'bpuB',
    137 => 'busbar',
    141 => 'ddcr',
    148 => 'sw',
    149 => 'bridge',
    150 => 'gbe',
    151 => 'sas',
    155 => 'xscfu',
    157 => 'psuFan',
    158 => 'airA',
    159 => 'airB',
    160 => 'airC',
    161 => 'acInlet',
    169 => 'hddbp',
    171 => 'tapebp',
    173 => 'dvdbpA',
    175 => 'dvdbpB',
    180 => 'cable',
    190 => 'ioua',
    192 => 'snsu',
    196 => 'ups',
    200 => 'environment',
    201 => 'firm',
    203 => 'domain',
    253 => 'unspecified',
    254 => 'notApplicable',
    255 => 'unknown' 
);
my %error_status = (
    1 => ["The component '%s' status is normal", 'OK'], 2 => ["The component '%s' status is degraded", 'WARNING'], 
    3 => ["The component '%s' status is faulted", 'CRITICAL'],
    254 => ["The component '%s' status has changed", 'WARNING'],
    255 => ["The component '%s' status is unknown", 'UNKNOWN'],
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "with-sensors"  => { name => 'with_sensors' },
        "exclude:s@"    => { name => 'exclude' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub check_exclude {
    my ($self, %options) = @_;

    foreach (@{$self->{option_results}->{exclude}}) {
        if ($options{value} =~ /$_/) {
            $self->{output}->output_add(long_msg => sprintf("Skipping $options{value}"));
            return 1;
        }
    }
    return 0;
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    my $oid_scfComponentErrorStatus = '.1.3.6.1.4.1.211.1.15.3.1.1.12.2.1.14';
    my $oid_scfComponentPartNumber = '.1.3.6.1.4.1.211.1.15.3.1.1.12.2.1.8';
    my $oid_scfMonitorValue = '.1.3.6.1.4.1.211.1.15.3.1.1.3.2.1.11';
    my $oid_scfMonitorUnits = '.1.3.6.1.4.1.211.1.15.3.1.1.3.2.1.9';

    my $oids_components_error_status = $self->{snmp}->get_table(oid => $oid_scfComponentErrorStatus, nothing_quit => 1);
    my $oids_components_part_number = $self->{snmp}->get_table(oid => $oid_scfComponentPartNumber, nothing_quit => 1);
    $self->{output}->output_add(severity => 'OK', 
                                short_msg => "All components are ok.");
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %$oids_components_error_status)) {
        # get last value from oid. And components oid is the concatenate of 'boardtype', 'boardid',...
        $oid =~ /^${oid_scfComponentErrorStatus}\.(.*?)\.(.*)/;
        my $board_type = $1;
        my $oid_end = $2;

        my $component_status = $oids_components_error_status->{$oid};
        # with '--'. there is 0x00 at the end str
        my $component_part = centreon::plugins::misc::trim($oids_components_part_number->{$oid_scfComponentPartNumber . '.' . $board_type . '.' . $oid_end});
        
        next if ($self->check_exclude(value => $components_board_types{$board_type} . '.' . $component_part));
        
        if ($component_status != 1) {
           $self->{output}->output_add(severity => ${$error_status{$component_status}}[1],
                                        short_msg => sprintf(${$error_status{$component_status}}[0], $components_board_types{$board_type} . " (" . $component_part . ")"));
        }
        $self->{output}->output_add(long_msg => sprintf(${$error_status{$component_status}}[0], $components_board_types{$board_type} . " (" . $component_part . ")"));
    }
    
    if (defined($self->{option_results}->{with_sensors})) {
        my $oids_monitor_values = $self->{snmp}->get_table(oid => $oid_scfMonitorValue);
        my $oids_monitor_units = $self->{snmp}->get_table(oid => $oid_scfMonitorUnits);
        foreach my $oid ($self->{snmp}->oid_lex_sort(keys %$oids_monitor_values)) {
            # get last value from oid. And components oid is the concatenate of 'boardtype', 'boardid',...
            $oid =~ /^${oid_scfMonitorValue}\.(.*?)\.(.*)/;
            my $board_type = $1;
            my $oid_end = $2;
            my $hex_val = md5_hex($board_type . '.' . $oid_end);
            
            # need some snmpwalk to do unit mapping!! experimental
            $self->{output}->perfdata_add(
                label => $components_board_types{$board_type}, 
                unit => $oids_monitor_units->{$oid_scfMonitorUnits . '.' . $board_type . '.' . $oid_end},
                nlabel => 'hardware.' . lc($components_board_types{$board_type}) . '.' . $oids_monitor_units->{$oid_scfMonitorUnits . '.' . $board_type . '.' . $oid_end},
                instances => $hex_val,
                value => $oids_monitor_values->{$oid}
            );
        }
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Mseries hardware components.

=over 8

=item B<--with-sensors>

Get sensors perfdatas.

=item B<--exclude>

Exclude some parts (multiple values) (Example: --exclude=TYPE.PART)
TYPE = board type ('cpum', 'mem', ...)
PART = name
(a regexp can be used)

=back

=cut
    
