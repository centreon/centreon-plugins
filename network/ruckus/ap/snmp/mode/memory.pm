#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package network::ruckus::ap::snmp::mode::memory;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_usage_perfdata {
    my ($self, %options) = @_;
    
    if ($self->{result_values}->{total} > 0) {
        $self->{output}->perfdata_add(label => 'used', unit => 'B',
                                      value => $self->{result_values}->{used},
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}, total => $self->{result_values}->{total}, cast_int => 1),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}, total => $self->{result_values}->{total}, cast_int => 1),
                                      min => 0, max => $self->{result_values}->{total});
    } else {
        $self->{output}->perfdata_add(label => 'used', unit => '%',
                                      value => $self->{result_values}->{prct_used},
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}),
                                      min => 0, max => 100);
    }
}

sub custom_usage_threshold {
    my ($self, %options) = @_;
    
    my $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{prct_used}, threshold => [ { label => 'critical-' . $self->{label}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{label}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_usage_output {
    my ($self, %options) = @_;
    
    my $msg = 'Memory Used: ' . $self->{result_values}->{prct_used} . '%';
    if ($self->{result_values}->{total} > 0) {
        my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
        my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
        my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    
        $msg = sprintf("Memory Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
                      $total_size_value . " " . $total_size_unit,
                      $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
                      $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free});
    }
    return $msg;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_total'};
    $self->{result_values}->{prct_used} = $options{new_datas}->{$self->{instance} . '_prct_used'};

    if ($self->{result_values}->{total} > 0) {
        $self->{result_values}->{used} = int($self->{result_values}->{prct_used} * $self->{result_values}->{total} / 100);
        $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used};
        $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};
    }
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'memory', type => 0 }
    ];
    
    $self->{maps_counters}->{memory} = [
        { label => 'usage', set => {
                key_values => [ { name => 'prct_used' }, { name => 'total' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_ruckusSystemMemoryUtil = '.1.3.6.1.4.1.25053.1.1.11.1.1.1.2.0';
    my $oid_ruckusSystemMemSize = '.1.3.6.1.4.1.25053.1.1.11.1.1.1.10.0';
    my $oid_ruckusUnleashedSystemStatsMemoryUtil = '.1.3.6.1.4.1.25053.1.15.1.1.1.15.14.0';
    my $snmp_result = $options{snmp}->get_leef(oids => [$oid_ruckusSystemMemoryUtil, $oid_ruckusSystemMemSize, $oid_ruckusUnleashedSystemStatsMemoryUtil], nothing_quit => 1);

    $self->{memory} = {
        prct_used => defined($snmp_result->{$oid_ruckusSystemMemoryUtil}) ? $snmp_result->{$oid_ruckusSystemMemoryUtil} : $snmp_result->{$oid_ruckusUnleashedSystemStatsMemoryUtil}, 
        total => defined($snmp_result->{$oid_ruckusSystemMemSize}) ? $snmp_result->{$oid_ruckusSystemMemSize} : 0,
    };
}

1;

__END__

=head1 MODE

Check memory usage.

=over 8

=item B<--warning-usage>

Threshold warning (in percent).

=item B<--critical-usage>

Threshold critical (in percent).

=back

=cut
