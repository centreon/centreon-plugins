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

package os::windows::snmp::mode::memory;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    my ($label, $nlabel) = ('used', $self->{nlabel});
    my $value_perf = $self->{result_values}->{used};
    if (defined($self->{instance_mode}->{option_results}->{free})) {
        ($label, $nlabel) = 'memory.free.bytes';
        $value_perf = $self->{result_values}->{free};
    }

    my %total_options = ();
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $total_options{total} = $self->{result_values}->{total};
        $total_options{cast_int} = 1;
    }

    $self->{output}->perfdata_add(
        label => $label,
        nlabel => $self->{nlabel},
        value => $value_perf, unit => 'B',
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}, %total_options),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}, %total_options),
        min => 0, max => $self->{result_values}->{total}
    );
}

sub custom_usage_threshold {
    my ($self, %options) = @_;

    my ($exit, $threshold_value);
    $threshold_value = $self->{result_values}->{used};
    $threshold_value = $self->{result_values}->{free} if (defined($self->{instance_mode}->{option_results}->{free}));
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $threshold_value = $self->{result_values}->{prct_used};
        $threshold_value = $self->{result_values}->{prct_free} if (defined($self->{instance_mode}->{option_results}->{free}));
    }
    $exit = $self->{perfdata}->threshold_check(value => $threshold_value, threshold => [ { label => 'critical-' . $self->{label}, exit_litteral => 'critical' }, { label => 'warning-'. $self->{label}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_usage_output {
    my ($self, %options) = @_;

    my $msg = sprintf("Total: %s%s Used: %s%s (%.2f%%) Free: %s%s (%.2f%%)",
                   $self->{perfdata}->change_bytes(value => $self->{result_values}->{total}),
                   $self->{perfdata}->change_bytes(value => $self->{result_values}->{used}), $self->{result_values}->{prct_used},
                   $self->{perfdata}->change_bytes(value => $self->{result_values}->{free}), $self->{result_values}->{prct_free});
    return $msg;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_total'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_used'};
    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used};
    $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'memory', type => 0, cb_prefix_output => 'prefix_memory_output' },
    ];

    $self->{maps_counters}->{memory} = [
        { label => 'memory', nlabel => 'memory.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'total' }  ],
                closure_custom_calc => \&custom_usage_calc,
                closure_custom_output => \&custom_usage_output,
                closure_custom_perfdata => \&custom_usage_perfdata,
                closure_custom_threshold_check => \&custom_usage_threshold,
            }
        },
    ];
}

sub prefix_memory_output {
    my ($self, %options) = @_;

    return "Ram ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'units:s'   => { name => 'units', default => '%' },
        'free'      => { name => 'free' },
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($total_bytes, $used_bytes, $free_bytes);

    my $oid_hrStorageDescr = '.1.3.6.1.2.1.25.2.3.1.3';

    my $result = $options{snmp}->get_table(oid => $oid_hrStorageDescr);

    foreach my $key (keys %$result) {
        next if ($key !~ /\.([0-9]+)$/);
        my $oid = $1;
        if ($result->{$key} =~ /^Physical (memory|RAM)$/i) {
            $self->{physical_memory_id} = $oid;
        }
    }

    if (!defined($self->{physical_memory_id})) {
        $self->{output}->add_option_msg(short_msg => "Cannot find physical memory informations.");
        $self->{output}->option_exit();
    }

    my $oid_hrStorageAllocationUnits = '.1.3.6.1.2.1.25.2.3.1.4';
    my $oid_hrStorageSize = '.1.3.6.1.2.1.25.2.3.1.5';
    my $oid_hrStorageUsed = '.1.3.6.1.2.1.25.2.3.1.6';

    $options{snmp}->load(oids => [$oid_hrStorageAllocationUnits, $oid_hrStorageSize, $oid_hrStorageUsed],
                        instances => [$self->{physical_memory_id}]);
    $result = $options{snmp}->get_leef();

    $used_bytes = $result->{$oid_hrStorageUsed . "." . $self->{physical_memory_id}} * $result->{$oid_hrStorageAllocationUnits . "." . $self->{physical_memory_id}};
    $total_bytes = $result->{$oid_hrStorageSize . "." . $self->{physical_memory_id}} * $result->{$oid_hrStorageAllocationUnits . "." . $self->{physical_memory_id}};
    $free_bytes = $total_bytes - $used_bytes;

    $self->{memory} = { used => $used_bytes, total => $total_bytes };

}

1;

__END__

=head1 MODE

Check memory usage

=over 8

=item B<--units>

Units of thresholds (Default: '%') ('%', 'absolute').

=item B<--free>

Thresholds are on free space left.

=item B<--warning-*>

Threshold warning.
Can be: 'memory'.

=item B<--critical-*>

Threshold critical.
Can be: 'memory'.

=back

=cut
