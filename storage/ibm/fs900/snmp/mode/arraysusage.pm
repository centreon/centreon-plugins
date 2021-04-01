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

package storage::ibm::fs900::snmp::mode::arraysusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        label => "used", unit => 'B',
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
        value => $self->{result_values}->{used},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0, max => $self->{result_values}->{total},
    );
}

sub custom_usage_threshold {
    my ($self, %options) = @_;

    my $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{used_prct},
                                                  threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
                                                                 { label => 'warning-' .  $self->{thlabel}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_usage_output {
    my ($self, %options) = @_;
    
    my ($total, $total_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($used, $used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($free, $free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    
    my $msg = sprintf("Usage Total: %s %s, Used: %s %s (%.2f%%), Free: %s %s (%.2f%%)", $total, $total_unit, $used, $used_unit, $self->{result_values}->{used_prct}, $free, $free_unit, $self->{result_values}->{free_prct});
    return $msg;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    ($self->{result_values}->{total}, $self->{result_values}->{total_unit}) = (split(' ', $options{new_datas}->{$self->{instance} . '_arrayCapacity'}));
    ($self->{result_values}->{used}, $self->{result_values}->{used_unit}) = (split(' ', $options{new_datas}->{$self->{instance} . '_arrayCapacityUsed'}));
    ($self->{result_values}->{free}, $self->{result_values}->{free_unit}) = (split(' ', $options{new_datas}->{$self->{instance} . '_arrayCapacityFree'}));

    $self->{result_values}->{total} = storage::ibm::fs900::snmp::mode::arraysusage->change_to_bytes(value => $self->{result_values}->{total}, unit => $self->{result_values}->{total_unit});
    $self->{result_values}->{used} = storage::ibm::fs900::snmp::mode::arraysusage->change_to_bytes(value => $self->{result_values}->{used}, unit => $self->{result_values}->{used_unit});
    $self->{result_values}->{free} = storage::ibm::fs900::snmp::mode::arraysusage->change_to_bytes(value => $self->{result_values}->{free}, unit => $self->{result_values}->{free_unit});

    $self->{result_values}->{used_prct} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{free_prct} = 100 - $self->{result_values}->{used_prct};

    return 0;
}

sub change_to_bytes {
    my ($self, %options) = @_;

    my $value = '';
    
    if ($options{unit} =~ /KiB*/i) {
        $value = $options{value} * 1024;
    } elsif ($options{unit} =~ /MiB*/i) {
        $value = $options{value} * 1024 * 1024;
    } elsif ($options{unit} =~ /GiB*/i) {
        $value = $options{value} * 1024 * 1024 * 1024;
    } elsif ($options{unit} =~ /TiB*/i) {
        $value = $options{value} * 1024 * 1024 * 1024 * 1024;
    }

    return $value
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 1, cb_prefix_output => 'prefix_output', message_multiple => "All arrays usage are ok" }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'usage', set => {
                key_values => [ { name => 'arrayCapacity' }, { name => 'arrayCapacityUsed' }, { name => 'arrayCapacityFree' }, { name => 'arrayId' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
            }
        },
    ];
}

sub prefix_output {
    my ($self, %options) = @_;

    return "Array '" . $options{instance_value}->{arrayId} . "' ";
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

my $mapping = {
    arrayId => { oid => '.1.3.6.1.4.1.2.6.255.1.1.1.52.1.2' },
    arrayCapacity => { oid => '.1.3.6.1.4.1.2.6.255.1.1.1.52.1.4' },
    arrayCapacityUsed => { oid => '.1.3.6.1.4.1.2.6.255.1.1.1.52.1.5' },
    arrayCapacityFree => { oid => '.1.3.6.1.4.1.2.6.255.1.1.1.52.1.6' },
};

my $oid_arrayIndex = '.1.3.6.1.4.1.2.6.255.1.1.1.52.1';

sub manage_selection {
    my ($self, %options) = @_;
    
    my $snmp_result = $options{snmp}->get_table(oid => $oid_arrayIndex,
                                                nothing_quit => 1);

    $self->{global} = {};

    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{arrayId}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        
        $self->{global}->{$result->{arrayId}} = $result;
    }
}

1;

__END__

=head1 MODE

Check arrays usage.

=over 8

=item B<--warning-usage>

Threshold warning.

=item B<--critical-usage>

Threshold critical.

=back

=cut
