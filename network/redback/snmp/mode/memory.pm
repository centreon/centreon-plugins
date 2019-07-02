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

package network::redback::snmp::mode::memory;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        label => 'used', unit => 'B',
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
        value => $self->{result_values}->{used},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, total => $self->{result_values}->{total}, cast_int => 1),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, total => $self->{result_values}->{total}, cast_int => 1),
        min => 0, max => $self->{result_values}->{total}
    );
}

sub custom_usage_threshold {
    my ($self, %options) = @_;
    
    my $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{prct_used}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_usage_output {
    my ($self, %options) = @_;
    
    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    
    my $msg = sprintf("Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
                      $total_size_value . " " . $total_size_unit,
                      $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
                      $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free});
    return $msg;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_used'} + $options{new_datas}->{$self->{instance} . '_free'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_used'};
    $self->{result_values}->{free} = $options{new_datas}->{$self->{instance} . '_free'};
    $self->{result_values}->{prct_free} = $self->{result_values}->{free} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'memory', type => 1, cb_prefix_output => 'prefix_memory_output', message_multiple => 'All memory usages are ok' }
    ];
    
    $self->{maps_counters}->{memory} = [
        { label => 'usage', set => {
                key_values => [ { name => 'display' }, { name => 'free' }, { name => 'used' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
            }
        },
    ];
}

sub prefix_memory_output {
    my ($self, %options) = @_;
    
    return "Memory '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                  "filter-name:s"     => { name => 'filter_name' },
                                });
    
    return $self;
}

my $mapping = {
    rbnMemoryModule          => { oid => '.1.3.6.1.4.1.2352.2.16.1.2.1.2' },
    rbnMemoryFreeKBytes      => { oid => '.1.3.6.1.4.1.2352.2.16.1.2.1.3' },
    rbnMemoryKBytesInUse     => { oid => '.1.3.6.1.4.1.2352.2.16.1.2.1.4' },
};

sub manage_selection {
    my ($self, %options) = @_;

    $self->{memory} = {};
    my $oid_rbnMemoryEntry = '.1.3.6.1.4.1.2352.2.16.1.2.1';
    $self->{results} = $options{snmp}->get_table(oid => $oid_rbnMemoryEntry,
                                                 nothing_quit => 1);
    foreach my $oid (keys %{$self->{results}}) {
        next if ($oid !~ /^$mapping->{rbnMemoryModule}->{oid}\.(\d+)/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $self->{results}, instance => $instance);
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{rbnMemoryModule} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $result->{rbnMemoryModule} . "': no matching filter.");
            next;
        }
        
        $self->{memory}->{$instance} = { display => $result->{rbnMemoryModule}, 
                                         free => $result->{rbnMemoryFreeKBytes} * 1024, used =>  $result->{rbnMemoryKBytesInUse} * 1024};
    }
    
    if (scalar(keys %{$self->{memory}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check memory usages.

=over 8

=item B<--warning-usage>

Threshold warning (in percent).

=item B<--critical-usage>

Threshold critical (in percent).

=item B<--filter-name>

Filter memory name (can be a regexp).

=back

=cut
