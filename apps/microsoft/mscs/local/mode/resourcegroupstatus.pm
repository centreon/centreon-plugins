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

package apps::microsoft::mscs::local::mode::resourcegroupstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Win32::OLE;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'rg', type => 1, cb_prefix_output => 'prefix_rg_output', message_multiple => 'All resource groups are ok' }
    ];
    
    $self->{maps_counters}->{rg} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'state' }, { name => 'display' }, { name => 'owner_node' }, { name => 'preferred_owners' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_threshold_output'),
            }
        },
    ];
}

my $instance_current;

sub is_preferred_node {
    if (!defined($instance_current->{result_values}->{preferred_owners}) ||
        scalar(@{$instance_current->{result_values}->{preferred_owners}}) == 0) {
        return 1;
    }
    
    foreach my $pref_node (@{$instance_current->{result_values}->{preferred_owners}}) {
        if ($pref_node eq $instance_current->{result_values}->{owner_node}) {
            return 1;
        }
    }
    
    return 0;
}

sub custom_threshold_output {
    my ($self, %options) = @_; 
    my $status = 'ok';
    my $message;
    
    $instance_current = $self;
    eval {
        local $SIG{__WARN__} = sub { $message = $_[0]; };
        local $SIG{__DIE__} = sub { $message = $_[0]; };
        
        if (defined($self->{instance_mode}->{option_results}->{critical_status}) && $self->{instance_mode}->{option_results}->{critical_status} ne '' &&
            eval "$self->{instance_mode}->{option_results}->{critical_status}") {
            $status = 'critical';
        } elsif (defined($self->{instance_mode}->{option_results}->{warning_status}) && $self->{instance_mode}->{option_results}->{warning_status} ne '' &&
                 eval "$self->{instance_mode}->{option_results}->{warning_status}") {
            $status = 'warning';
        } elsif (defined($self->{instance_mode}->{option_results}->{unknown_status}) && $self->{instance_mode}->{option_results}->{unknown_status} ne '' &&
                 eval "$self->{instance_mode}->{option_results}->{unknown_status}") {
            $status = 'unknown';
        }
    };
    if (defined($message)) {
        $self->{output}->output_add(long_msg => 'filter status issue: ' . $message);
    }

    return $status;
}

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $pref_nodes = 'any';
    if (defined($instance_current->{result_values}->{preferred_owners}) &&
        scalar(@{$instance_current->{result_values}->{preferred_owners}}) > 0) {
        $pref_nodes = join(', ', @{$instance_current->{result_values}->{preferred_owners}});
    }

    my $msg = 'state : ' . $self->{result_values}->{state} . ' [node: ' . $self->{result_values}->{owner_node}  . '] [preferred nodes: ' . $pref_nodes . ']';
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{state} = $options{new_datas}->{$self->{instance} . '_state'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{owner_node} = $options{new_datas}->{$self->{instance} . '_owner_node'};
    $self->{result_values}->{preferred_owners} = $options{new_datas}->{$self->{instance} . '_preferred_owners'};
    return 0;
}

sub prefix_rg_output {
    my ($self, %options) = @_;
    
    return "Resource group '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                "filter-name:s"           => { name => 'filter_name' },
                                "unknown-status:s"        => { name => 'unknown_status', default => '%{state} =~ /unknown/' },
                                "warning-status:s"        => { name => 'warning_status', default => 'not is_preferred_node()' },
                                "critical-status:s"       => { name => 'critical_status', default => '%{state} =~ /failed|offline/' },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
    $self->change_macros(macros => ['warning_status', 'critical_status', 'unknown_status']);
}

my %map_state = (
    -1 => 'unknown',
    0 => 'online',
    1 => 'offline',
    2 => 'failed',
    3 => 'partial online',
    4 => 'pending',
);

sub manage_selection {
    my ($self, %options) = @_;

    # winmgmts:{impersonationLevel=impersonate,authenticationLevel=pktPrivacy}!\\.\root\mscluster
    my $wmi = Win32::OLE->GetObject('winmgmts:root\mscluster');
    if (!defined($wmi)) {
        $self->{output}->add_option_msg(short_msg => "Cant create server object:" . Win32::OLE->LastError());
        $self->{output}->option_exit();
    }
    
    my $query = "Select * from MSCluster_ResourceGroupToPreferredNode";
    my $resultset = $wmi->ExecQuery($query);
    my $preferred_nodes = {};
    foreach my $obj (in $resultset) {
        use Data::Dumper;
        
        # MSCluster_ResourceGroup.Name="xxx"
        if ($obj->GroupComponent =~ /MSCluster_ResourceGroup.Name="(.*?)"/i) {
            my $rg = $1;
            next if ($obj->PartComponent !~ /MSCluster_Node.Name="(.*?)"/i);
            my $node = $1;
            $preferred_nodes->{$rg} = [] if (!defined($preferred_nodes->{$rg}));
            push @{$preferred_nodes->{$rg}}, $node;
        }
    }
    
    $self->{rg} = {};
    $query = "Select * from MSCluster_ResourceGroup";
    $resultset = $wmi->ExecQuery($query);
    foreach my $obj (in $resultset) {
        my $name = $obj->{Name};
        my $state = $map_state{$obj->{State}};
        my $id = defined($obj->{Id}) ? $obj->{Id} : $name;
        my $owner_node = defined($obj->{OwnerNode}) ? $obj->{OwnerNode} : '-';

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $name . "': no matching filter.", debug => 1);
            next;
        }
    
        $self->{rg}->{$id} = { display => $name, state => $state, owner_node => $owner_node,
                               preferred_owners => defined($preferred_nodes->{$name}) ? $preferred_nodes->{$name} : [] };
    }
}

1;

__END__

=head1 MODE

Check resource group status.

=over 8

=item B<--filter-name>

Filter resource group name (can be a regexp).

=item B<--unknown-status>

Set warning threshold for status (Default: '%{state} =~ /unknown/').
Can used special variables like: %{state}, %{display}, %{owner_node}

=item B<--warning-status>

Set warning threshold for status (Default: 'not is_preferred_node()').
Can used special variables like: %{state}, %{display}, %{owner_node}

=item B<--critical-status>

Set critical threshold for status (Default: '%{state} =~ /failed|offline/').
Can used special variables like: %{state}, %{display}, %{owner_node}

=back

=cut
