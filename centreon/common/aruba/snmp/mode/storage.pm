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

package centreon::common::aruba::snmp::mode::storage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        instances => $self->{instance},
        label => 'usage', nlabel => 'storage.usage.bytes',
        unit => 'B',
        value => $self->{result_values}->{used},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}, total => $self->{result_values}->{total}, cast_int => 1),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}, total => $self->{result_values}->{total}, cast_int => 1),
        min => 0, max => $self->{result_values}->{total});
}

sub custom_usage_threshold {
    my ($self, %options) = @_;

    my $exit = $self->{perfdata}->threshold_check(
        value => $self->{result_values}->{prct_used},
        threshold => [ { label => 'critical-' . $self->{label}, exit_litteral => 'critical' },
                       { label => 'warning-' . $self->{label}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});

    my $msg = sprintf("Usage Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free});
    return $msg;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_sysExtStorageSize'} * 1024 * 1024;
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_sysExtStorageUsed'} * 1024 * 1024;
    $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used};
    $self->{result_values}->{prct_free} = $self->{result_values}->{free} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'storage', type => 1, cb_prefix_output => 'prefix_output',
          message_multiple => 'All storages are ok' },
    ];

    $self->{maps_counters}->{storage} = [
        { label => 'usage', set => {
                key_values => [ { name => 'sysExtStorageUsed' }, { name => 'sysExtStorageSize' },
                    { name => 'sysExtStorageName' } ],
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

    return "Storage '" . $options{instance_value}->{sysExtStorageName} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "filter-name:s"   => { name => 'filter_name' },
        "filter-type:s"   => { name => 'filter_type' },
    });
                                
    return $self;
}
    
my $oid_wlsxSysExtStorageEntry = '.1.3.6.1.4.1.14823.2.2.1.2.1.14.1';

my %map_storage_type = (
    1 => 'ram', 2 => 'flashMemory'
);

my $mapping = {
    sysExtStorageType => { oid => '.1.3.6.1.4.1.14823.2.2.1.2.1.14.1.2', map => \%map_storage_type },
    sysExtStorageSize => { oid => '.1.3.6.1.4.1.14823.2.2.1.2.1.14.1.3' }, # MB
    sysExtStorageUsed => { oid => '.1.3.6.1.4.1.14823.2.2.1.2.1.14.1.4' }, # MB
    sysExtStorageName => { oid => '.1.3.6.1.4.1.14823.2.2.1.2.1.14.1.5' },
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_wlsxSysExtStorageEntry,
        start => $mapping->{sysExtStorageType}->{oid},
        end => $mapping->{sysExtStorageName}->{oid},
        nothing_quit => 1
    );
    
    $self->{storage} = {};
    
    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{sysExtStorageType}->{oid}\.(.*)/);
        my $instance = $1;
        
        my $result = $options{snmp}->map_instance(
            mapping => $mapping,
            results => $snmp_result,
            instance => $instance
        );
        
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{sysExtStorageName} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => sprintf("Skipping storage '%s'.", $result->{sysExtStorageName}), debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
            $result->{sysExtStorageType} !~ /$self->{option_results}->{filter_type}/i) {
            $self->{output}->output_add(long_msg => sprintf("Skipping storage '%s'.", $result->{sysExtStorageType}), debug => 1);
            next;
        }
        
        $self->{storage}->{$result->{sysExtStorageName}} = { %{$result} };
    }

    if (scalar(keys %{$self->{storage}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No storage found");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check storage device usage (WLSX-SYSTEMEXT-MIB).

=over 8

=item B<--warning-usage>

Threshold warning in percent.

=item B<--critical-usage>

Threshold critical in percent.

=item B<--filter-name>

Filter storage device name (regexp can be used).

=item B<--filter-type>

Filter storage device type (regexp can be used).
Can use: 'ram', 'flashMemory'

=back

=cut
