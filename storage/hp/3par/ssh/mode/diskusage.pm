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

package storage::hp::3par::ssh::mode::diskusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = 'status : ' . $self->{result_values}->{status};
    return $msg;
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

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'disk', type => 1, cb_prefix_output => 'prefix_disk_output', message_multiple => 'All disks are ok', sort_method => 'num' },
    ];
    
    $self->{maps_counters}->{disk} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'usage', nlabel => 'disk.space.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'display' },  ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { label => 'used', value => 'used', template => '%d', min => 0, max => 'total',
                      unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'usage-free', display_ok => 0, nlabel => 'disk.space.free.bytes', set => {
                    key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'display' },  ],
                    closure_custom_output => $self->can('custom_usage_output'),
                    perfdatas => [
                        { label => 'free', value => 'free', template => '%d', min => 0, max => 'total',
                          unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'display' },
                    ],
                }
        },
        { label => 'usage-prct', display_ok => 0, nlabel => 'disk.space.usage.percentage', set => {
                    key_values => [ { name => 'prct_used' }, { name => 'display' } ],
                    output_template => 'Used : %.2f %%',
                    perfdatas => [
                        { label => 'used_prct', value => 'prct_used', template => '%.2f', min => 0, max => 100,
                          unit => '%', label_extra_instance => 1, instance_use => 'display' },
                    ],
                }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        "filter-name:s"       => { name => 'filter_name' },
        "warning-status:s"    => { name => 'warning_status', default => '' },
        "critical-status:s"   => { name => 'critical_status', default => '%{status} !~ /normal/i' },
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub prefix_disk_output {
    my ($self, %options) = @_;
    
    return "Disk '" . $options{instance_value}->{display} . "' ";
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($result, $exit) = $options{custom}->execute_command(commands => ['showpd -showcols Id,State,Type,Size_MB,Free_MB']);

    #Id State  Type   Size_MB  Free_MB
    # 0 normal FC      838656   133120
    # 1 normal FC      838656   101376
    # 2 normal FC      838656   133120

    $self->{disk} = {};
    my @lines = split /\n/, $result;
    foreach (@lines) {
        next if (!/^\s*(\d+)\s+(\S+)\s+\S+\s+(\d+)\s+(\d+)/);
        my ($disk_id, $status, $total, $free) = ($1, $2, $3 * 1024 * 1024, $4 * 1024 * 1024);

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $disk_id !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping disk '" . $disk_id . "': no matching filter.", debug => 1);
            next;
        }

        $self->{disk}->{$disk_id} = {
            display => $disk_id,
            status => $status,
            total => $total,
            used => $total - $free,
            free => $free,
            prct_used => ($total - $free) * 100 / $total,
            prct_free => 100 - (($total - $free) * 100 / $total),
        };
    }
    
    if (scalar(keys %{$self->{disk}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No disk found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check disk usages.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^status$'

=item B<--filter-name>

Filter disk name (can be a regexp).

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{status}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} !~ /normal/i').
Can used special variables like: %{status}, %{display}

=item B<--warning-*> B<--critical-*>

Threshold warning.
Can be: 'usage' (B), 'usage-free' (B), 'usage-prct' (%).

=back

=cut
