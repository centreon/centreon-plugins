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

package os::linux::local::mode::systemdscstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'status : %s/%s/%s [boot: %s]',
        $self->{result_values}->{load},
        $self->{result_values}->{active},
        $self->{result_values}->{sub},
        $self->{result_values}->{boot}
    );
}

sub prefix_sc_output {
    my ($self, %options) = @_;

    return "Service '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'sc', type => 1, cb_prefix_output => 'prefix_sc_output', message_multiple => 'All services are ok' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total-running', nlabel => 'systemd.services.running.count', set => {
                key_values => [ { name => 'running' }, { name => 'total' } ],
                output_template => 'Total Running: %s',
                perfdatas => [
                    { label => 'total_running', template => '%s', min => 0, max => 'total' }
                ]
            }
        },
        { label => 'total-failed', nlabel => 'systemd.services.failed.count', set => {
                key_values => [ { name => 'failed' }, { name => 'total' } ],
                output_template => 'Total Failed: %s',
                perfdatas => [
                    { label => 'total_failed', template => '%s', min => 0, max => 'total' }
                ]
            }
        },
        { label => 'total-dead', nlabel => 'systemd.services.dead.count', set => {
                key_values => [ { name => 'dead' }, { name => 'total' } ],
                output_template => 'Total Dead: %s',
                perfdatas => [
                    { label => 'total_dead', template => '%s', min => 0, max => 'total' }
                ]
            }
        },
        { label => 'total-exited', nlabel => 'systemd.services.exited.count', set => {
                key_values => [ { name => 'exited' }, { name => 'total' } ],
                output_template => 'Total Exited: %s',
                perfdatas => [
                    { label => 'total_exited', template => '%s', min => 0, max => 'total' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{sc} = [
        { label => 'status', type => 2, critical_default => '%{active} =~ /failed/i', set => {
                key_values => [ { name => 'load' }, { name => 'active' },  { name => 'sub' }, { name => 'boot' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s'  => { name => 'filter_name' },
        'exclude-name:s' => { name => 'exclude_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    # check systemctl version to convert no-legend in legend=false (change in versions >= 248)
    my $legend_format= ' --no-legend';
    my ($stdout_version) = $options{custom}->execute_command(
        command         => 'systemctl',
        command_options => '--version'
    );
    $stdout_version =~ /^systemd\s(\d+)\s/;
    my $systemctl_version=$1;
    if($systemctl_version >= 248){
        $legend_format = ' --legend=false';
    }

    my $command_options_1 = '-a --no-pager --plain';
    my ($stdout)  = $options{custom}->execute_command(
        command         => 'systemctl',
        command_options => $command_options_1.$legend_format
    );

    $self->{global} = { running => 0, exited => 0, failed => 0, dead => 0, total => 0 };
    $self->{sc} = {};
    #auditd.service                                                        loaded    active   running Security Auditing Service
    #avahi-daemon.service                                                  loaded    active   running Avahi mDNS/DNS-SD Stack
    #brandbot.service                                                      loaded    inactive dead    Flexible Branding Service
    while ($stdout =~ /^(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/msig) {
        my ($name, $load, $active, $sub) = ($1, $2, $3, lc($4));

        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/);
        next if (defined($self->{option_results}->{exclude_name}) && $self->{option_results}->{exclude_name} ne '' &&
            $name =~ /$self->{option_results}->{exclude_name}/);

        $self->{sc}->{$name} = { display => $name, load => $load, active => $active, sub => $sub, boot => '-' };
        $self->{global}->{$sub} += 1 if (defined($self->{global}->{$sub}));
        $self->{global}->{total} += 1;
    }

    if (scalar(keys %{$self->{sc}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No service found.");
        $self->{output}->option_exit();
    }

    my $command_options_2 = 'list-unit-files --no-pager --plain';
    my ($stdout_2)  = $options{custom}->execute_command(
        command         => 'systemctl',
        command_options => $command_options_2.$legend_format
    );

    # vendor preset is a new column
    #UNIT FILE                 STATE           VENDOR PRESET
    #runlevel4.target          enabled 
    #runlevel5.target          static  
    #runlevel6.target          disabled
    #irqbalance.service        enabled         enabled
    while ($stdout_2 =~ /^(.*?)\s+(\S+)\s*/msig) {
        my ($name, $boot) = ($1, $2);
        next if (!defined($self->{sc}->{$name}));
        $self->{sc}->{$name}->{boot} = $boot;
    }
}

1;

__END__

=head1 MODE

Check systemd services status.

Command used: 'systemctl -a --no-pager --no-legend' and 'systemctl list-unit-files --no-pager --no-legend'
Command change for systemctl version >= 248 : --no-legend is converted in legend=false

=over 8

=item B<--filter-name>

Filter service name (can be a regexp).

=item B<--exclude-name>

Exclude service name (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total-running', 'total-dead', 'total-exited',
'total-failed'.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{display}, %{active}, %{sub}, %{load}, %{boot}
Example of statuses for the majority of these variables:
%{active}: active, inactive
%{sub}: waiting, plugged, mounted, dead, failed, running, exited, listening, active
%{load}: loaded, not-found
%{boot}: enabled, disabled, static, indirect

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{active} =~ /failed/i').
You can use the following variables: %{display}, %{active}, %{sub}, %{load}, %{boot}
Example of statuses for the majority of these variables:
%{active}: active, inactive
%{sub}: waiting, plugged, mounted, dead, failed, running, exited, listening, active
%{load}: loaded, not-found
%{boot}: enabled, disabled, static, indirect

=back

=cut
