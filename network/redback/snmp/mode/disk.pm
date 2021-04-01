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

package network::redback::snmp::mode::disk;

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
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_total'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_used'} * $options{new_datas}->{$self->{instance} . '_total'} / 100;
    $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used};
    $self->{result_values}->{prct_free} = $self->{result_values}->{free} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'disk', type => 1, cb_prefix_output => 'prefix_disk_output', message_multiple => 'All disk usages are ok' }
    ];
    
    $self->{maps_counters}->{disk} = [
        { label => 'usage', set => {
                key_values => [ { name => 'display' }, { name => 'total' }, { name => 'used' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
            }
        },
    ];
}

sub prefix_disk_output {
    my ($self, %options) = @_;
    
    return "Disk '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        "filter-name:s"     => { name => 'filter_name' },
    });

    return $self;
}

my $mapping = {
    rbnSRStorageDescr        => { oid => '.1.3.6.1.4.1.2352.2.24.1.2.1.1.2' },
    rbnSRStorageSize         => { oid => '.1.3.6.1.4.1.2352.2.24.1.2.1.1.5' }, # KB
    rbnSRStorageUtilization  => { oid => '.1.3.6.1.4.1.2352.2.24.1.2.1.1.6' }, # %
};

sub manage_selection {
    my ($self, %options) = @_;

    $self->{disk} = {};
    my $oid_rbnSRStorageEntry = '.1.3.6.1.4.1.2352.2.24.1.2.1.1';
    $self->{results} = $options{snmp}->get_table(oid => $oid_rbnSRStorageEntry,
                                                nothing_quit => 1);
    foreach my $oid (keys %{$self->{results}}) {
        next if ($oid !~ /^$mapping->{rbnSRStorageSize}->{oid}\.(\d+)/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $self->{results}, instance => $instance);
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{rbnSRStorageDescr} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $result->{rbnSRStorageDescr} . "': no matching filter.");
            next;
        }
        if ($result->{rbnSRStorageSize} == 0) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $result->{rbnSRStorageDescr} . "': media is removed.");
            next;
        }
        
        $self->{disk}->{$instance} = { display => $result->{rbnSRStorageDescr}, 
                                       used => $result->{rbnSRStorageUtilization}, total =>  $result->{rbnSRStorageSize} * 1024};
    }
    
    if (scalar(keys %{$self->{disk}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check disk usages.

=over 8

=item B<--warning-usage>

Threshold warning (in percent).

=item B<--critical-usage>

Threshold critical (in percent).

=item B<--filter-name>

Filter disk name (can be a regexp).

=back

=cut
