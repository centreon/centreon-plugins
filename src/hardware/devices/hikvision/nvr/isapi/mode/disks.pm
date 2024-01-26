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

package hardware::devices::hikvision::nvr::isapi::mode::disks;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_space_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    return sprintf(
        'space usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free}
    );
}

sub disk_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking disk '%s'",
        $options{instance}
    );
}

sub prefix_disk_output {
    my ($self, %options) = @_;

    return sprintf(
        "disk '%s' ",
        $options{instance}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'disks', type => 3, cb_prefix_output => 'prefix_disk_output', cb_long_output => 'disk_long_output',
          indent_long_output => '    ', message_multiple => 'All disks are ok',
            group => [
                { name => 'status', type => 0, skipped_code => { -10 => 1 } },
                { name => 'space', type => 0, skipped_code => { -10 => 1 } },
                { name => 'temperature', type => 0, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    # status: ok,unformatted,error,idle,mismatch,offline,smartFailed,reparing,formating,notexist,unRecordHostFormatted
    $self->{maps_counters}->{status} = [
        {
            label => 'status',
            type => 2,
            warning_default => '%{status} =~ /reparing/i',
            critical_default => '%{status} =~ /error|smartFailed/i',
            set => {
                key_values => [ { name => 'status' }, { name => 'name' } ],
                output_template => 'status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{space} = [
         { label => 'space-usage', nlabel => 'disk.space.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'space-usage-free', nlabel => 'disk.space.free.bytes', display_ok => 0, set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'space-usage-prct', nlabel => 'disk.space.usage.percentage', display_ok => 0, set => {
                key_values => [ { name => 'prct_used' }, { name => 'used' }, { name => 'free' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_space_usage_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{temperature} = [
        { label => 'temperature', nlabel => 'disk.temperature.celsius', set => {
                key_values => [ { name => 'value' } ],
                output_template => 'temperature: %s C',
                perfdatas => [
                    { template => '%s', unit => 'C', label_extra_instance => 1 }
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

    my $result = $options{custom}->request_api(endpoint => '/ISAPI/ContentMgmt/Storage/hdd', force_array => ['hdd']);
    if (!defined($result->{hdd})) {
        $self->{output}->add_option_msg(short_msg => "Cannot find disk informations");
        $self->{output}->option_exit();
    }

    $self->{disks} = {};
    foreach my $hdd (@{$result->{hdd}}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $hdd->{hddName} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping disk '" . $hdd->{hddName} . "'.", debug => 1);
            next;
        }

        $hdd->{capacity} *= 1024 * 1024;
        $hdd->{freeSpace} *= 1024 * 1024;
        $self->{disks}->{ $hdd->{hddName} } = {
            status => { name => $hdd->{hddName}, status => $hdd->{status} },
            space => {
                total => $hdd->{capacity},
                used => $hdd->{capacity} - $hdd->{freeSpace},
                free => $hdd->{freeSpace},
                prct_used => 100 - ($hdd->{freeSpace} * 100 / $hdd->{capacity}),
                prct_free => ($hdd->{freeSpace} * 100 / $hdd->{capacity})
            }
        };

        my $smart = $options{custom}->request_api(endpoint => '/ISAPI/ContentMgmt/Storage/hdd/' . $hdd->{id} . '/SMARTTest/status');
        $self->{disks}->{ $hdd->{hddName} }->{temperature} = { value => $smart->{temprature} };
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

Define the conditions to match for the status to be WARNING (default: '%{status} =~ /reparing/i').
You can use the following variables: %{status}, %{name}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} =~ /error|smartFailed/i').
You can use the following variables: %{status}, %{name}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'space-usage', 'space-usage-free', 'space-usage-prct',
'temperature'.

=back

=cut
