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

package storage::hp::p2000::xmlapi::mode::vdisks;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = 'status : ' . $self->{result_values}->{status};
    return $msg;
}

sub custom_usage_output {
    my ($self, %options) = @_;
    
    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total_space});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used_space});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free_space});
    my $msg = sprintf('space usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used_space},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free_space}
    );
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'vdisk', type => 1, cb_prefix_output => 'prefix_vdisk_output', message_multiple => 'All virtual disks are ok', skipped_code => { -10 => 1 } },
    ];
    
    $self->{maps_counters}->{vdisk} = [
        {
            label => 'status',
            type => 2,
            unknown_default => '%{status} =~ /unknown/i',
            warning_default => '%{status} =~ /degraded/i',
            critical_default => '%{status} =~ /failed/i',
            set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'usage', nlabel => 'vdisk.space.usage.bytes', set => {
                key_values => [ { name => 'used_space' }, { name => 'free_space' }, { name => 'prct_used_space' }, { name => 'prct_free_space' }, { name => 'total_space' }, { name => 'display' },  ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { value => 'used_space', template => '%d', min => 0, max => 'total_space',
                      unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'usage-free', nlabel => 'vdisk.space.free.bytes', display_ok => 0, set => {
                key_values => [ { name => 'free_space' }, { name => 'used_space' }, { name => 'prct_used_space' }, { name => 'prct_free_space' }, { name => 'total_space' }, { name => 'display' },  ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { value => 'free_space', template => '%d', min => 0, max => 'total_space',
                      unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'usage-prct', nlabel => 'vdisk.space.usage.percentage', display_ok => 0, set => {
                key_values => [ { name => 'prct_used_space' }, { name => 'display' } ],
                output_template => 'used : %.2f %%',
                perfdatas => [
                    { value => 'prct_used_space', template => '%.2f', min => 0, max => 100,
                      unit => '%', label_extra_instance => 1, instance_use => 'display' }
                ],
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

sub prefix_vdisk_output {
    my ($self, %options) = @_;
    
    return "Virtual disk '" . $options{instance_value}->{display} . "' ";
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($result, $code) = $options{custom}->get_infos(
        cmd => 'show vdisks', 
        base_type => 'virtual-disks',
        key => 'name',
        properties_name => '^(?:health-numeric|size-numeric|freespace-numeric)$',
        no_quit => 1,
    );
    if ($code == 0) {
        ($result) = $options{custom}->get_infos(
            cmd => 'show disk-groups', 
            base_type => 'disk-groups',
            key => 'name', 
            properties_name => '^(?:health-numeric|size-numeric|freespace-numeric)$',
        );
    }

    my %health = (
        0 => 'ok',
        1 => 'degraded',
        2 => 'failed',
        3 => 'unknown',
        4 => 'not available',
    );

    $self->{vdisk} = {};
    foreach my $name (keys %$result) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping virtual disk '" . $name . "': no matching filter.", debug => 1);
            next;
        }

        $result->{$name}->{'size-numeric'} *= 512;
        $result->{$name}->{'freespace-numeric'} *= 512;
        $self->{vdisk}->{$name} = {
            display => $name,
            status => $health{ $result->{$name}->{'health-numeric'} },
            total_space => $result->{$name}->{'size-numeric'},
            used_space => $result->{$name}->{'size-numeric'} - $result->{$name}->{'freespace-numeric'},
            free_space => $result->{$name}->{'freespace-numeric'},
            prct_used_space => 
                defined($result->{$name}->{'size-numeric'}) ? (($result->{$name}->{'size-numeric'} - $result->{$name}->{'freespace-numeric'}) * 100 / $result->{$name}->{'size-numeric'}) : undef,
            prct_free_space => 
                defined($result->{$name}->{'size-numeric'}) ? ($result->{$name}->{'freespace-numeric'} * 100 / $result->{$name}->{'size-numeric'}) : undef,
        };
    }
    
    if (scalar(keys %{$self->{vdisk}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No virtual disk found");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check virtual disks.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^usage$'

=item B<--filter-name>

Filter virtual disk name (can be a regexp).

=item B<--unknown-status>

Set unknown threshold for status (Default: '%{status} =~ /unknown/i').
Can used special variables like: %{status}, %{display}

=item B<--warning-status>

Set warning threshold for status (Default: '%{status} =~ /degraded/i').
Can used special variables like: %{status}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /failed/i').
Can used special variables like: %{status}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'usage' (B), 'usage-free' (B), 'usage-prct' (%).

=back

=cut
