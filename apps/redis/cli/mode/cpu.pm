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

package apps::redis::cli::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_output' }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'sys', set => {
                key_values => [ { name => 'used_cpu_sys', diff => 1 } ],
                closure_custom_calc => $self->can('custom_usage_calc'), closure_custom_calc_extra_options => { label_ref => 'used_cpu_sys' },
                output_template => 'System: %.2f %%', output_use => 'used_delta', threshold_use => 'used_delta',
                perfdatas => [
                    { label => 'sys', value => 'used_delta', template => '%.2f', min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'user', set => {
                key_values => [ { name => 'used_cpu_user', diff => 1 } ],
                closure_custom_calc => $self->can('custom_usage_calc'), closure_custom_calc_extra_options => { label_ref => 'used_cpu_user' },
                output_template => 'User: %.2f %%', output_use => 'used_delta', threshold_use => 'used_delta',
                perfdatas => [
                    { label => 'user', value => 'used_delta', template => '%.2f', min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'sys-children', set => {
                key_values => [ { name => 'used_cpu_sys_children', diff => 1 } ],
                closure_custom_calc => $self->can('custom_usage_calc'), closure_custom_calc_extra_options => { label_ref => 'used_cpu_sys_children' },
                output_template => 'System children: %.2f %%', output_use => 'used_delta', threshold_use => 'used_delta',
                perfdatas => [
                    { label => 'sys_children', value => 'used_delta', template => '%.2f', min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'user-children', set => {
                key_values => [ { name => 'used_cpu_user_children', diff => 1 } ],
                closure_custom_calc => $self->can('custom_usage_calc'), closure_custom_calc_extra_options => { label_ref => 'used_cpu_user_children' },
                output_template => 'User children: %.2f %%', output_use => 'used_delta', threshold_use => 'used_delta',
                perfdatas => [
                    { label => 'user_children', value => 'used_delta', template => '%.2f', min => 0, max => 100, unit => '%' },
                ],
            }
        }
    ];
}

sub prefix_output {
    my ($self, %options) = @_;
    
    return "CPU usage: ";
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    my $delta_total = $options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref}} - $options{old_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref}};
    $self->{result_values}->{used_delta} = 100 * $delta_total / $options{delta_time};
    
    return 0;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments =>  {
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = "redis_" . $self->{mode} . '_' . $options{custom}->get_connection_info() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
    
    my $results = $options{custom}->get_info();
         
    $self->{global} = {
        used_cpu_sys            => $results->{used_cpu_sys},
        used_cpu_user           => $results->{used_cpu_user},
        used_cpu_sys_children   => $results->{used_cpu_sys_children},
        used_cpu_user_children  => $results->{used_cpu_user_children},
    };
}

1;

__END__

=head1 MODE

Check CPU utilization.

=over 8

=item B<--warning-sys>

Warning threshold for Sys CPU utilization

=item B<--critical-sys>

Critical threshold for Sys CPU utilization

=item B<--warning-user>

Warning threshold for User CPU utilization

=item B<--critical-user>

Critical threshold for User CPU utilization

=item B<--warning-sys-children>

Warning threshold for Sys Children CPU utilization

=item B<--critical-sys-children>

Critical threshold for Sys Children CPU utilization

=item B<--warning-user-children>

Warning threshold for User Children CPU utilization

=item B<--critical-user-children>

Critical threshold for User Children CPU utilization

=back

=cut
