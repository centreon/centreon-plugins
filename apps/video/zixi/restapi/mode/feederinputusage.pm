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

package apps::video::zixi::restapi::mode::feederinputusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    my $msg = 'active : ' . $self->{result_values}->{active} . ' [error: ' . ($self->{result_values}->{error} ne '' ? $self->{result_values}->{error} : '-') . ']';

    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{active} = $options{new_datas}->{$self->{instance} . '_active'};
    $self->{result_values}->{name} = $options{new_datas}->{$self->{instance} . '_name'};
    $self->{result_values}->{error} = $options{new_datas}->{$self->{instance} . '_error'};
    
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'input', type => 1, cb_prefix_output => 'prefix_input_output', message_multiple => 'All inputs are ok', skipped_code => { -11 => 1 } },
    ];
    
    $self->{maps_counters}->{input} = [
         { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'active' }, { name => 'name' }, { name => 'error' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_status_threshold')
            }
        },
        { label => 'traffic-in', set => {
                key_values => [ { name => 'traffic_in', per_second => 1 }, { name => 'name' } ],
                output_change_bytes => 2,
                output_template => 'Traffic In : %s %s/s',
                perfdatas => [
                    { label => 'traffic_in', template => '%.2f',
                      min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-name:s'     => { name => 'filter_name' },
        'warning-status:s'  => { name => 'warning_status' },
        'critical-status:s' => { name => 'critical_status' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub prefix_input_output {
    my ($self, %options) = @_;
    
    return "Input '" . $options{instance_value}->{name} . "' ";
}

sub manage_selection {
    my ($self, %options) = @_;
                                                           
    $self->{input} = {};
    my $result = $options{custom}->get(path => '/inputs_data');
    foreach my $entry (@{$result->{inputs}}) {        
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $entry->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $entry->{source} . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{input}->{$entry->{name}} = { 
            name => $entry->{name},
            active => $entry->{active} == 0 ? 'false' : 'true',
            error => $entry->{error},
            traffic_in => $entry->{bytes} * 8,
        };
    }
    
    if (scalar(keys %{$self->{input}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No input found.");
        $self->{output}->option_exit();
    }
    
    $self->{cache_name} = "zixi_" . $self->{mode} . '_' . $options{custom}->{hostname} . '_' . $options{custom}->{port} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check feeder input usage.

=over 8

=item B<--filter-name>

Filter name (can be a regexp).

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^status$'

=item B<--warning-*>

Threshold warning.
Can be: 'traffic-in'.

=item B<--critical-*>

Threshold critical.
Can be: 'traffic-in'.

=item B<--warning-status>

Set warning threshold for status (Default: -)
Can used special variables like: %{name}, %{active}, %{error}.

=item B<--critical-status>

Set critical threshold for status (Default: -).
Can used special variables like: %{name}, %{active}, %{error}.

=back

=cut
