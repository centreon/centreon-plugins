#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_output' }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'sys', set => {
                key_values => [ { name => 'used_cpu_sys' } ],
                output_template => 'System: %.2f %%',
                perfdatas => [
                    { label => 'sys', value => 'used_cpu_sys_absolute', template => '%.2f', min => 0, max => 100, unit => '%' },
                ],
            },
        },
        { label => 'user', set => {
                key_values => [ { name => 'used_cpu_user' } ],
                output_template => 'User: %.2f %%',
                perfdatas => [
                    { label => 'user', value => 'used_cpu_user_absolute', template => '%.2f', min => 0, max => 100, unit => '%' },
                ],
            },
        },
        { label => 'sys-children', set => {
                key_values => [ { name => 'used_cpu_sys_children' } ],
                output_template => 'System children: %.2f %%',
                perfdatas => [
                    { label => 'sys_children', value => 'used_cpu_sys_children_absolute', template => '%.2f', min => 0, max => 100, unit => '%' },
                ],
            },
        },
        { label => 'user-children', set => {
                key_values => [ { name => 'used_cpu_user_children' } ],
                output_template => 'User children: %.2f %%',
                perfdatas => [
                    { label => 'user_children', value => 'used_cpu_user_children_absolute', template => '%.2f', min => 0, max => 100, unit => '%' },
                ],
            },
        },
    ];
}

sub prefix_output {
    my ($self, %options) = @_;
    
    return "CPU usage: ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';

    $options{options}->add_options(arguments => 
                    {
                    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{redis} = $options{custom};
    $self->{results} = $self->{redis}->get_info();
         
    $self->{global} = { 'used_cpu_sys' => $self->{results}->{used_cpu_sys},
                        'used_cpu_user' => $self->{results}->{used_cpu_user},
                        'used_cpu_sys_children' => $self->{results}->{used_cpu_sys_children},
                        'used_cpu_user_children' => $self->{results}->{used_cpu_user_children}};
}

1;

__END__

=head1 MODE

Check CPU utilization

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
