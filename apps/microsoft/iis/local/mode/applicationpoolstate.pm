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

package apps::microsoft::iis::local::mode::applicationpoolstate;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Win32::OLE;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

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
        { name => 'pools', type => 1, cb_prefix_output => 'prefix_pool_output', message_multiple => 'All application pools are ok' }
    ];

    $self->{maps_counters}->{pools} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'name' }, { name => 'auto_start' }, { name => 'state' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'filter-name:s'     => { name => 'filter_name' },
        'unknown-status:s'  => { name => 'unknown_status', default => '' },
        'warning-status:s'  => { name => 'warning_status', default => '' },
        'critical-status:s' => { name => 'critical_status', default => '%{auto_start} eq "on" and not %{state} =~ /started|starting/' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status', 'unknown_status']);
}

my $state_map = {
    0   => 'starting',
    1   => 'started',
    2   => 'stopping',
    3   => 'stopped',
    4   => 'unknown'
};

sub manage_selection {
    my ($self, %options) = @_;

    my $wmi = Win32::OLE->GetObject('winmgmts:root\WebAdministration');
    if (!defined($wmi)) {
        $self->{output}->add_option_msg(short_msg => "Cant create server object:" . Win32::OLE->LastError());
        $self->{output}->option_exit();
    }
    my $query = "Select Name, AutoStart From ApplicationPool";
    my $resultset = $wmi->ExecQuery($query);

    $self->{pools} = {};
    foreach my $obj (in $resultset) {
        my $name = $obj->{Name};
        my $state = $state_map->{ $obj->GetState() };

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping pool '" . $name . "': no matching filter.", debug => 1);
            next;
        }

        $self->{pools}->{$name} = {
            name => $name,
            state => $state,
            auto_start => $obj->{AutoStart} == 0 ? 'off' : 'on'
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

Set unknown threshold for status.
Can used special variables like: %{name}, %{state}, %{auto_start}.

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{name}, %{state}, %{auto_start}.

=item B<--critical-status>

Set critical threshold for status (Default: '%{auto_start} eq "on" and not %{state} =~ /started|starting/').
Can used special variables like: %{name}, %{state}, %{auto_start}.

=back

=cut
