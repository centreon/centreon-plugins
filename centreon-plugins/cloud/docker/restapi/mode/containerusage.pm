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

package cloud::docker::restapi::mode::containerusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

my $instance_mode;

sub custom_status_threshold {
    my ($self, %options) = @_; 
    my $status = 'ok';
    my $message;
    
    eval {
        local $SIG{__WARN__} = sub { $message = $_[0]; };
        local $SIG{__DIE__} = sub { $message = $_[0]; };
        
        if (defined($instance_mode->{option_results}->{critical_status}) && $instance_mode->{option_results}->{critical_status} ne '' &&
            eval "$instance_mode->{option_results}->{critical_status}") {
            $status = 'critical';
        } elsif (defined($instance_mode->{option_results}->{warning_status}) && $instance_mode->{option_results}->{warning_status} ne '' &&
                 eval "$instance_mode->{option_results}->{warning_status}") {
            $status = 'warning';
        }
    };
    if (defined($message)) {
        $self->{output}->output_add(long_msg => 'filter status issue: ' . $message);
    }

    return $status;
}

sub custom_status_output {
    my ($self, %options) = @_;
    my $msg = 'status : ' . $self->{result_values}->{status} . ' [error: ' . $self->{result_values}->{error} . ']';

    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{name} = $options{new_datas}->{$self->{instance} . '_name'};
    $self->{result_values}->{error} = $options{new_datas}->{$self->{instance} . '_error'};
    
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'containers', type => 1, cb_prefix_output => 'prefix_containers_output', message_multiple => 'All containers are ok', skipped_code => { -11 => 1 } },
    ];
    
    $self->{maps_counters}->{output_stream} = [
         { label => 'container-status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'name' }, { name => 'error' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_status_threshold'),
            }
        },
        { label => 'traffic-in', set => {
                key_values => [ { name => 'traffic_in', diff => 1 }, { name => 'name' } ],
                per_second => 1, output_change_bytes => 2,
                output_template => 'Traffic In : %s %s/s',
                perfdatas => [
                    { label => 'traffic_in', value => 'traffic_in_per_second', template => '%.2f',
                      min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'name_absolute' },
                ],
            }
        },
        { label => 'traffic-out', set => {
                key_values => [ { name => 'traffic_out', diff => 1 }, { name => 'name' } ],
                per_second => 1, output_change_bytes => 2,
                output_template => 'Traffic Out : %s %s/s',
                perfdatas => [
                    { label => 'traffic_out', value => 'traffic_out_per_second', template => '%.2f',
                      min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'name_absolute' },
                ],
            }
        },
        { label => 'dropped-in', set => {
                key_values => [ { name => 'dropped_in', diff => 1 }, { name => 'name' } ],
                output_template => 'Packets Dropped In : %s',
                perfdatas => [
                    { label => 'dropped_in', value => 'dropped_in_absolute', template => '%.2f',
                      min => 0, label_extra_instance => 1, instance_use => 'name_absolute' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "filter-name:s"               => { name => 'filter_name' },
                                  "warning-container-status:s"  => { name => 'warning_container_status' },
                                  "critical-container-status:s" => { name => 'critical_container_status', default => '%{status} !~ /Connecting|Connected/i || %{error} !~ /none/i' },
                                });
   
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $instance_mode = $self;
    $self->change_macros();
}

sub prefix_containers_output {
    my ($self, %options) = @_;
    
    return "Container '" . $options{instance_value}->{display} . "' ";
}

sub change_macros {
    my ($self, %options) = @_;
    
    foreach (('warning_container_status', 'critical_container_status')) {
        if (defined($self->{option_results}->{$_})) {
            $self->{option_results}->{$_} =~ s/%\{(.*?)\}/\$self->{result_values}->{$1}/g;
        }
    }
}

sub manage_selection {
    my ($self, %options) = @_;
                                                           
    $self->{containers} = {};
    my $result = $options{custom}->api_get_containers();
    use Data::Dumper;
    print Data::Dumper::Dumper($result);
    exit(1);

    foreach my $entry (@{$result->{outputs}}) {
        my $name = $entry->{name} . '/' . $entry->{requested_stream_id};
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $name . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{output_stream}->{$entry->{id}} = { 
            display => $name,
            status => $entry->{status},
            traffic_in => $entry->{stats}->{net_recv}->{bytes} * 8,
            traffic_out => $entry->{stats}->{net_send}->{bytes} * 8,
            dropped_in => $entry->{stats}->{net_recv}->{dropped},
        };
    }
    
    if (scalar(keys %{$self->{containers}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No container found.");
        $self->{output}->option_exit();
    }
    
    $self->{cache_name} = "docker_" . $self->{mode} . '_' . $options{custom}->{hostname} . '_' . $options{custom}->{port} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check container usage.

=over 8

=item B<--filter-name>

Filter name (can be a regexp).

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^container-status$'

=item B<--warning-*>

Threshold warning.
Can be: 'traffic-in', 'traffic-out', 'dropped-in'.

=item B<--critical-*>

Threshold critical.
Can be: 'traffic-in', 'traffic-out', 'dropped-in'.

=item B<--warning-container-status>

Set warning threshold for status (Default: -)
Can used special variables like: %{id}, %{name}, %{status}.

=item B<--critical-container-status>

Set critical threshold for status (Default: '%{status} !~ /Connecting|Connected/i').
Can used special variables like: %{id}, %{name}, %{status}.

=back

=cut
