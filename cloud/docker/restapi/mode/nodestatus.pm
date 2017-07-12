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

package cloud::docker::restapi::mode::nodestatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

my $instance_mode;

sub custom_status_threshold {
    my ($self, %options) = @_; 
    my $status = 'ok';
    my $message;
    
    eval {
        local $SIG{__WARN__} = sub { $message = $_[0]; };
        local $SIG{__DIE__} = sub { $message = $_[0]; };
        
        if (defined($instance_mode->{option_results}->{critical_node_status}) && $instance_mode->{option_results}->{critical_node_status} ne '' &&
            eval "$instance_mode->{option_results}->{critical_node_status}") {
            $status = 'critical';
        } elsif (defined($instance_mode->{option_results}->{warning_node_status}) && $instance_mode->{option_results}->{warning_node_status} ne '' &&
                 eval "$instance_mode->{option_results}->{warning_node_status}") {
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
    my $msg = 'status : ' . $self->{result_values}->{status} . ' [manager status: ' . $self->{result_values}->{manager_status} . ']';

    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{manager_status} = $options{new_datas}->{$self->{instance} . '_manager_status'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'nodes', type => 1, cb_prefix_output => 'prefix_node_output', message_multiple => 'All nodes are ok', skipped_code => { -11 => 1 } },
    ];
    
    $self->{maps_counters}->{nodes} = [
         { label => 'node-status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'manager_status' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_status_threshold'),
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
                                  "warning-node-status:s"  => { name => 'warning_node_status', default => '' },
                                  "critical-node-status:s" => { name => 'critical_node_status', default => '%{status} !~ /ready/ || %{manager_status} !~ /reachable|-/' },
                                });
   
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $instance_mode = $self;
    $self->change_macros();
}

sub prefix_node_output {
    my ($self, %options) = @_;
    
    return "Node '" . $options{instance_value}->{display} . "' ";
}

sub change_macros {
    my ($self, %options) = @_;
    
    foreach (('warning_node_status', 'critical_node_status')) {
        if (defined($self->{option_results}->{$_})) {
            $self->{option_results}->{$_} =~ s/%\{(.*?)\}/\$self->{result_values}->{$1}/g;
        }
    }
}

sub manage_selection {
    my ($self, %options) = @_;
                                                           
    $self->{nodes} = {};
    my $result = $options{custom}->api_list_nodes();

    foreach my $node_name (keys %{$result}) {
        foreach my $entry (@{$result->{$node_name}}) {
            my $name = $node_name . '/' . $entry->{Addr};
            $self->{nodes}->{$name} = {
                display => $name ,
                status => $entry->{Status},
                manager_status => defined($entry->{ManagerStatus}) ? $entry->{ManagerStatus} : '-',
            };
        }
    }
    
    if (scalar(keys %{$self->{nodes}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No node found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check node status.

=over 8

=item B<--warning-node-status>

Set warning threshold for status (Default: -)
Can used special variables like: %{display}, %{status}, %{manager_status}.

=item B<--critical-node-status>

Set critical threshold for status (Default: '%{status} !~ /ready/ || %{manager_status} !~ /reachable|-/').
Can used special variables like: %{display}, %{status}, %{manager_status}.

=back

=cut
