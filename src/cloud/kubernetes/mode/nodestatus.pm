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

package cloud::kubernetes::mode::nodestatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_condition_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "Status is '%s', Reason: '%s', Message: '%s'",
        $self->{result_values}->{status},
        $self->{result_values}->{reason},
        $self->{result_values}->{message}
    );
}

sub prefix_output {
    my ($self, %options) = @_;

    return "Node '" . $options{instance_value}->{display} . "' ";
}

sub prefix_condition_output {
    my ($self, %options) = @_;
    
    return "Condition '" . $options{instance_value}->{type} . "' ";
}

sub long_output {
    my ($self, %options) = @_;

    return "Checking node '" . $options{instance_value}->{display} . "'";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'nodes', type => 3, cb_prefix_output => 'prefix_output', cb_long_output => 'long_output',
          message_multiple => 'All Nodes status are ok', indent_long_output => '    ',
            group => [
                { name => 'conditions', display_long => 1, cb_prefix_output => 'prefix_condition_output',
                  message_multiple => 'Conditions are ok', type => 1, skipped_code => { -10 => 1 } },
            ]
        }
    ];

    $self->{maps_counters}->{conditions} = [
        {
            label => 'status',
            type => 2,
            critical_default => '(%{type} =~ /Ready/i && %{status} !~ /True/i) || (%{type} =~ /.*Pressure/i && %{status} !~ /False/i)', 
            set => {
                key_values => [
                    { name => 'type' }, { name => 'status' }, { name => 'reason' },
                    { name => 'message' }, { name => 'name' }
                ],
                closure_custom_output => $self->can('custom_condition_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
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

    my $results = $options{custom}->kubernetes_list_nodes();

    $self->{nodes} = {};
    foreach my $node (@{$results}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $node->{metadata}->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $node->{metadata}->{name} . "': no matching filter name.", debug => 1);
            next;
        }

        $self->{nodes}->{$node->{metadata}->{uid}}->{display} = $node->{metadata}->{name};

        foreach my $condition (@{$node->{status}->{conditions}}) {
            $self->{nodes}->{$node->{metadata}->{uid}}->{conditions}->{$condition->{type}} = {
                name => $node->{metadata}->{name},
                type => $condition->{type},
                status => $condition->{status},
                reason => $condition->{reason},
                message => $condition->{message}
            };
        }
    }
    
    if (scalar(keys %{$self->{nodes}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No Nodes found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check node status.

=over 8

=item B<--filter-name>

Filter node name (can be a regexp).

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '').
You can use the following variables: %{type}, %{status}, %{reason}, %{message}, %{name}.

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '(%{type} =~ /Ready/i && %{status} !~ /True/i) || (%{type} =~ /.*Pressure/i && %{status} !~ /False/i)').
You can use the following variables: %{type}, %{status}, %{reason}, %{message}, %{name}.

=back

=cut
