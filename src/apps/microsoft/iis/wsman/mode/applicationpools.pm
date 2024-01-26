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

package apps::microsoft::iis::wsman::mode::applicationpools;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'state: %s [auto: %s]',
        $self->{result_values}->{state},
        $self->{result_values}->{auto_start}
    );
}

sub prefix_pool_output {
    my ($self, %options) = @_;

    return "Application pool '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'pools', type => 1, cb_prefix_output => 'prefix_pool_output', message_multiple => 'All application pools are ok' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'pools-detected', display_ok => 0, nlabel => 'pools.detected.count', set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'application pools detected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{pools} = [
        { label => 'status', type => 2, critical_default => '%{auto_start} eq "on" and not %{state} =~ /started|starting/', set => {
                key_values => [ { name => 'name' }, { name => 'auto_start' }, { name => 'state' } ],
                closure_custom_output => $self->can('custom_status_output'),
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

my $state_map = {
    1   => 'started',
    2   => 'starting',
    3   => 'stopped',
    4   => 'stopping'
};

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{wsman}->request(
        uri => 'http://schemas.microsoft.com/wbem/wsman/1/wmi/root/MicrosoftIISv2/*',
        wql_filter => 'Select Name, AppPoolState, AppPoolAutoStart From IIsApplicationPoolSetting',
        result_type => 'hash',
        hash_key => 'Name'
    );

    $self->{pools} = {};
    foreach my $name (keys %$results) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping pool '" . $name . "': no matching filter.", debug => 1);
            next;
        }

        $self->{pools}->{$name} = {
            name => $name,
            state => $state_map->{ $results->{$name}->{AppPoolState} },
            auto_start => $results->{$name}->{AppPoolAutoStart} =~ /^(?:1|true)$/i ? 'on' : 'off'
        };
    }

    if (scalar(keys %{$self->{pools}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No application pool found');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check IIS application pools.

=over 8

=item B<--filter-name>

Filter application pool name (can be a regexp).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{name}, %{state}, %{auto_start}.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{name}, %{state}, %{auto_start}.

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{auto_start} eq "on" and not %{state} =~ /started|starting/').
You can use the following variables: %{name}, %{state}, %{auto_start}.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'pools-detected'.

=back

=cut
