#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package network::cisco::prime::restapi::mode::apusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::statefile;

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
    my $msg = 'status : ' . $self->{result_values}->{status};
    if ($self->{result_values}->{information} ne '') {
        $msg .= ' [information: ' . $self->{result_values}->{information} . ']';
    }

    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{name} = $options{new_datas}->{$self->{instance} . '_name'};
    $self->{result_values}->{environment} = $options{new_datas}->{$self->{instance} . '_environment'};
    $self->{result_values}->{application} = $options{new_datas}->{$self->{instance} . '_application'};
    $self->{result_values}->{exit_code} = $options{new_datas}->{$self->{instance} . '_exit_code'};
    $self->{result_values}->{family} = $options{new_datas}->{$self->{instance} . '_family'};
    $self->{result_values}->{information} = $options{new_datas}->{$self->{instance} . '_information'};
    
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'ctrl', type => 1, cb_prefix_output => 'prefix_controller_output', message_multiple => 'All controllers are ok', , skipped_code => { -11 => 1 } },
        { name => 'ap', type => 1, cb_prefix_output => 'prefix_ap_output', message_multiple => 'All access points are ok', , skipped_code => { -11 => 1 } },
    ];
    
    $self->{maps_counters}->{ap} = [
        { label => 'ap-status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'name' }, { name => 'environment' }, 
                                { name => 'application' }, { name => 'exit_code' }, { name => 'family' }, { name => 'information' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_status_threshold'),
            }
        },
        { label => 'ap-clients', set => {
                key_values => [ { name => 'error' }, { name => 'total' } ],
                output_template => 'Error : %s',
                perfdatas => [
                    { label => 'total_error', value => 'error_absolute', template => '%s',
                      min => 0, max => 'total_absolute' },
                ],
            }
        },
    ];
    
    $self->{maps_counters}->{ctrl} = [
        { label => 'ctrl-ap-count', set => {
                key_values => [ { name => 'error' }, { name => 'total' } ],
                output_template => 'Error : %s',
                perfdatas => [
                    { label => 'total_error', value => 'error_absolute', template => '%s',
                      min => 0, max => 'total_absolute' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "filter-controller:s"     => { name => 'filter_controller' },
                                  "filter-ap:s"             => { name => 'filter_ap' },
                                  "warning-status:s"        => { name => 'warning_status' },
                                  "critical-status:s"       => { name => 'critical_status', default => '%{status} =~ /Error/i' },
                                  "reload-cache-time:s"     => { name => 'reload_cache_time', default => 180 },
                                });
    $self->{statefile_cache_ap} = centreon::plugins::statefile->new(%options);
   
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{statefile_cache_ap}->check_options(%options);
    $instance_mode = $self;
    $self->change_macros();
}

sub prefix_controller_output {
    my ($self, %options) = @_;
    
    return "Controller '" . $options{instance_value}->{controllerName} . "' ";
}

sub prefix_ap_output {
    my ($self, %options) = @_;
    
    return "Access point '" . $options{instance_value}->{name} . "' ";
}

sub change_macros {
    my ($self, %options) = @_;
    
    foreach (('warning_status', 'critical_status')) {
        if (defined($self->{option_results}->{$_})) {
            $self->{option_results}->{$_} =~ s/%\{(.*?)\}/\$self->{result_values}->{$1}/g;
        }
    }
}

sub manage_selection {
    my ($self, %options) = @_;
 
    my $access_points = $options{custom}->cache_ap(statefile => $self->{statefile_cache_ap}, 
                                                   reload_cache_time => $self->{option_results}->{reload_cache_time});
                                                           
    ($self->{ap}, $self->{ctrl}) = ({}, {});
    
    foreach my $ap_name (keys %{$access_points}) {        
        if (defined($self->{option_results}->{filter_ap}) && $self->{option_results}->{filter_ap} ne '' &&
            $ap_name !~ /$self->{option_results}->{filter_ap}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $ap_name . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_controller}) && $self->{option_results}->{filter_controller} ne '' &&
            $access_points->{$ap_name}->{controllerName} !~ /$self->{option_results}->{filter_controller}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $access_points->{$ap_name}->{controllerName} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{ap}->{$ap_name} = { 
            name => $ap_name, controller => $access_points->{$ap_name}->{controllerName},
            status => $access_points->{$ap_name}->{status},
            admin_status => $access_points->{$ap_name}->{adminStatus},
            client_count => $access_points->{$ap_name}->{clientCount},
            lwapp_uptime => $access_points->{$ap_name}->{lwappUpTime},
            uptime => $access_points->{$ap_name}->{upTime},
        };
    }
    
    if (scalar(keys %{$self->{ap}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No AP found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check AP usages (also the number of access points by controller).

=over 8

=item B<--filter-ap>

Filter ap name (can be a regexp).

=item B<--filter-controller>

Filter controller name (can be a regexp).

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^total-error$'

=item B<--warning-*>

Threshold warning.
Can be: 'total-error', 'total-running', 'total-unplanned',
'total-finished', 'total-coming'.

=item B<--critical-*>

Threshold critical.
Can be: 'total-error', 'total-running', 'total-unplanned',
'total-finished', 'total-coming'.

=item B<--warning-status>

Set warning threshold for status (Default: -)
Can used special variables like: %{name}, %{status}, 
%{exit_code}, %{family}, %{information}, %{environment}, %{application}

=item B<--critical-status>

Set critical threshold for status (Default: '%{exit_code} =~ /Error/i').
Can used special variables like: %{name}, %{status}, 
%{exit_code}, %{family}, %{information}, %{environment}, %{application}

=item B<--reload-cache-time>

Time in seconds before reloading cache file (default: 180).

=back

=cut
