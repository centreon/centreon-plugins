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

package os::aix::snmp::mode::memory;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

my $oid_hrStorageType            = '.1.3.6.1.2.1.25.2.3.1.2';
my $oid_hrStorageAllocationUnits = '.1.3.6.1.2.1.25.2.3.1.4';
my $oid_hrStorageSize            = '.1.3.6.1.2.1.25.2.3.1.5';
my $oid_hrStorageUsed            = '.1.3.6.1.2.1.25.2.3.1.6';
my $oid_hrStorageRam             = '.1.3.6.1.2.1.25.2.1.2';

sub custom_usage_calc {
    my ($self, %options) = @_;

    return -10 if ($options{new_datas}->{$self->{instance} . '_total'} <= 0);
    $self->{result_values}->{total}     = $options{new_datas}->{$self->{instance} . '_total'};
    $self->{result_values}->{used}      = $options{new_datas}->{$self->{instance} . '_used'};
    $self->{result_values}->{free}      = $self->{result_values}->{total} - $self->{result_values}->{used};
    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};

    return 0;
}

sub custom_usage_output {
    my ($self, %options) = @_;

    my ($total_h, $total_u) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($used_h,  $used_u)  = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($free_h,  $free_u)  = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});

    return sprintf(
        'Ram Total: %s %s Used: %s %s (%.2f%%) Free: %s %s (%.2f%%)',
        $total_h, $total_u,
        $used_h,  $used_u,  $self->{result_values}->{prct_used},
        $free_h,  $free_u,  $self->{result_values}->{prct_free}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'memory', type => 0, skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{memory} = [
        { label => 'usage', nlabel => 'memory.usage.bytes', set => {
            key_values => [ { name => 'used' }, { name => 'total' } ],
            closure_custom_calc   => $self->can('custom_usage_calc'),
            closure_custom_output => $self->can('custom_usage_output'),
            threshold_use => 'prct_used',
            perfdatas => [
                { label => 'memory_used',  value => 'used',      template => '%d',   cast_int => 1,
                  unit  => 'B', min => 0, max => 'total', threshold_total => 'total' },
                { label => 'memory_free',  value => 'free',      template => '%d',   cast_int => 1,
                  unit  => 'B', min => 0, max => 'total' },
                { label => 'memory_usage', value => 'prct_used', template => '%.2f',
                  unit  => '%', min => 0, max => 100 }
            ]
        }}
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(
        oid          => '.1.3.6.1.2.1.25.2.3',
        nothing_quit => 1
    );

    $self->{memory} = {};

    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$oid_hrStorageType\.(\d+)$/);
        my $index = $1;
        my $type  = $snmp_result->{$oid};

        next if ($type ne $oid_hrStorageRam);

        my $alloc = $snmp_result->{ $oid_hrStorageAllocationUnits . '.' . $index };
        my $size  = $snmp_result->{ $oid_hrStorageSize            . '.' . $index };
        my $used  = $snmp_result->{ $oid_hrStorageUsed            . '.' . $index };

        next if (!defined($size) || !defined($used) || !defined($alloc) || $size == 0);

        $self->{memory} = {
            total => $size * $alloc,
            used  => $used * $alloc
        };

        last; # RAM entry found, no need to continue
    }

    if (!defined($self->{memory}->{total})) {
        $self->{output}->add_option_msg(
            short_msg => 'Cannot find RAM entry in hrStorageTable. ' .
                         'Check that hrStorageRam OID (.1.3.6.1.2.1.25.2.1.2) is exposed by the SNMP agent.'
        );
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check physical memory (RAM) usage on AIX servers via SNMP HOST-RESOURCES-MIB.

AIX SNMP agents expose RAM under hrStorageType = hrStorageRam (.1.3.6.1.2.1.25.2.1.2).
Unlike Linux, the storage index for RAM is dynamic and discovered by scanning hrStorageTable.

For swap monitoring on AIX, use the dedicated 'swap' mode which leverages
AIX-specific IBM MIB OIDs for more detailed paging space information.

=over 8

=item B<--warning-usage>

Warning threshold on RAM usage (%).

=item B<--critical-usage>

Critical threshold on RAM usage (%).

=back

=cut
