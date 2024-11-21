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

package hardware::devices::hikvision::nvr::snmp::mode::disks;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'status: %s',
        $self->{result_values}->{status}
    );
}

sub custom_space_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total_space});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used_space});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free_space});
    return sprintf(
        'space usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used_space},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free_space}
    );
}

sub prefix_disk_output {
    my ($self, %options) = @_;

    return "Disk '" . $options{instance}. "' ";
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Disks ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', cb_prefix_output => 'prefix_global_output', type => 0, skipped_code => { -10 => 1 }  },
        { name => 'disks', type => 1, cb_prefix_output => 'prefix_disk_output', message_multiple => 'All disks are ok' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'disks-total', nlabel => 'disks.total.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'disks-errors', nlabel => 'disks.errors.count', set => {
                key_values => [ { name => 'errors' }, { name => 'total' } ],
                output_template => 'errors: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{disks} = [
         {
            label => 'status',
            type => 2,
            warning_default => '%{status} =~ /reparing|formatting/i',
            critical_default => '%{status} =~ /abnormal|smartfailed/i',
            set => {
                key_values => [ { name => 'status' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'space-usage', nlabel => 'disk.space.usage.bytes', set => {
                key_values => [ { name => 'used_space' }, { name => 'free_space' }, { name => 'prct_used_space' }, { name => 'prct_free_space' }, { name => 'total_space' } ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total_space', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'space-usage-free', nlabel => 'disk.space.free.bytes', display_ok => 0, set => {
                key_values => [ { name => 'free_space' }, { name => 'used_space' }, { name => 'prct_used_space' }, { name => 'prct_free_space' }, { name => 'total_space' } ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total_space', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'space-usage-prct', nlabel => 'disk.space.usage.percentage', display_ok => 0, set => {
                key_values => [ { name => 'prct_used_space' }, { name => 'used_space' }, { name => 'free_space' }, { name => 'prct_free_space' }, { name => 'total_space' } ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'filter-name:s' => { name => 'filter_name' }
    });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $map_status = {
        0 => 'normal', 1 => 'unformatted', 2 => 'abnormal',
        3 => 'smartfailed', 4 => 'mismatch', 5 => 'idle',
        6 => 'notOnline', 10 => 'reparing', 11 => 'formatting'
    };
    my $mapping = {
        name   => { oid => '.1.3.6.1.4.1.50001.1.241.1.2' }, # hikDiskVolume
        status => { oid => '.1.3.6.1.4.1.50001.1.241.1.3', map => $map_status }, # hikDiskStatus
        free   => { oid => '.1.3.6.1.4.1.50001.1.241.1.4' }, # hikDiskFreeSpace
        total  => { oid => '.1.3.6.1.4.1.50001.1.241.1.5' }  # hikDiskCapability
    };
    my $oid_diskEntry = '.1.3.6.1.4.1.50001.1.241.1';

    my $snmp_result = $options{snmp}->get_table(oid => $oid_diskEntry, nothing_quit => 1);

    $self->{global} = { total => 0, errors => 0 };
    $self->{disks} = {};
     foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{status}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        my $name = defined($result->{name}) && $result->{name} ne '' ? $result->{name} : $instance;
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping disk '" . $name . "': no matching filter.", debug => 1);
            next;
        }

        $result->{total} *= 1024 * 1024;
        $result->{free} *= 1024 * 1024;
        $self->{disks}->{$name} = {
            name => $name,
            status => $result->{status},
            free_space => $result->{free},
            total_space => $result->{total},
            used_space => $result->{total} - $result->{free},
            prct_used_space => ($result->{total} - $result->{free}) * 100 / $result->{total},
            prct_free_space => $result->{free} * 100 / $result->{total},
        };

        if ($result->{status} =~ /abnormal|smartfailed/) {
            $self->{global}->{errors}++;
        }
        $self->{global}->{total}++;
    }
}

1;

__END__

=head1 MODE

Check disks.

=over 8

=item B<--filter-name>

Filter disks by name (can be a regexp).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{status}, %{name}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '%{status} =~ /reparing|formatting/i').
You can use the following variables: %{status}, %{name}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} =~ /abnormal|smartfailed/i').
You can use the following variables: %{status}, %{name}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'space-usage', 'space-usage-free', 'space-usage-prct',
'disks-total', 'disks-errors'.

=back

=cut
