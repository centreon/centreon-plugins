#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package apps::haproxy::web::mode::backendusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub prefix_backend_output {
    my ($self, %options) = @_;

    return "Backend '" . $options{instance_value}->{display} . "' ";
}

sub prefix_server_output {
    my ($self, %options) = @_;

    return "Server '" . $options{instance_value}->{svname} . "' ";
}

sub prefix_global_backend_output {
    my ($self, %options) = @_;

    return 'backend ';
}

sub backend_long_output {
    my ($self, %options) = @_;

    return "Backend '" . $options{instance_value}->{display} . "':";
}

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf("status: %s", $self->{result_values}->{status});
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { 
            name => 'backends', 
            type => 3, 
            cb_prefix_output => 'prefix_backend_output', 
            cb_long_output => 'backend_long_output', 
            message_multiple => 'All Backends are ok', 
            indent_long_output => '    ', 
            skipped_code => { -10 => 1 },            
            group => [
                { 
                    name => 'backend', 
                    type => 0, 
                    cb_prefix_output => 'prefix_global_backend_output' 
                },
                { 
                    name => 'servers', 
                    type => 1, 
                    display_long => 1, 
                    cb_prefix_output => 'prefix_server_output', 
                    message_multiple => 'Servers are ok', 
                    skipped_code => { -10 => 1 } 
                }
            ]
        }
    ];
    
    $self->{maps_counters}->{backend} = [
        {
            label => 'backend-status',
            type => 2,
            critical_default => '%{status} !~ /UP/i',
            set => {
                key_values => [ { name => 'status' }, { name => 'pxname' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'backend-current-queue', nlabel => 'backend.queue.current.count', set => {
                key_values => [ { name => 'qcur' }, { name => 'pxname' } ],
                output_template => 'current queue: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'pxname' }
                ]
            }
        },
        { label => 'backend-current-session-rate', nlabel => 'backend.session.current.rate.countpersecond', set => {
                key_values => [ { name => 'rate' }, { name => 'pxname' } ],
                output_template => 'current session rate: %s/s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'pxname' }
                ]
            }
        },
        { label => 'backend-max-session-rate', nlabel => 'backend.session.max.rate.countpersecond', set => {
                key_values => [ { name => 'rate_max' }, { name => 'pxname' } ],
                output_template => 'max session rate: %s/s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'pxname' }
                ]
            }
        },
        { label => 'backend-current-sessions', nlabel => 'backend.sessions.current.count', set => {
                key_values => [ { name => 'scur' }, { name => 'pxname' } ],
                output_template => 'current sessions: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'pxname' }
                ]
            }
        },
        { label => 'backend-total-sessions', nlabel => 'backend.sessions.total.count', set => {
                key_values => [ { name => 'stot', diff => 1 }, { name => 'pxname' } ],
                output_template => 'total sessions: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'pxname' }
                ]
            }
        },
        { label => 'backend-traffic-in', nlabel => 'backend.traffic.in.bitpersecond', set => {
                key_values => [ { name => 'bin', per_second => 1 }, { name => 'pxname' } ],
                output_template => 'traffic in: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%.2f', min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'pxname' }
                ]
            }
        },
        { label => 'backend-traffic-out', nlabel => 'backend.traffic.out.bitpersecond', set => {
                key_values => [ { name => 'bout', per_second => 1 }, { name => 'pxname' } ],
                output_template => 'traffic out: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%.2f', min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'pxname' }
                ]
            }
        },
        { label => 'backend-denied-requests', nlabel => 'backend.requests.denied.count', set => {
                key_values => [ { name => 'dreq' }, { name => 'pxname' } ],
                output_template => 'denied requests: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'pxname' }
                ]
            }
        },
        { label => 'backend-denied-responses', nlabel => 'backend.responses.denied.count', set => {
                key_values => [ { name => 'dresp' }, { name => 'pxname' } ],
                output_template => 'denied responses: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'pxname' }
                ]
            }
        },
        { label => 'backend-connections-errors', nlabel => 'backend.connections.error.count', set => {
                key_values => [ { name => 'econ' }, { name => 'pxname' } ],
                output_template => 'connection errors: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'pxname' }
                ]
            }
        },
        { label => 'backend-responses-errors', nlabel => 'backend.responses.error.count', set => {
                key_values => [ { name => 'eresp' }, { name => 'pxname' } ],
                output_template => 'responses errors: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'pxname' }
                ]
            }
        }
    ];
    $self->{maps_counters}->{servers} = [
        {
            label => 'server-status',
            type => 2,
            critical_default => '%{status} !~ /UP/i',
            set => {
                key_values => [ { name => 'status' }, { name => 'svname' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'server-current-sessions', nlabel => 'server.sessions.current.count', set => {
                key_values => [ { name => 'scur' }, { name => 'svname' } ],
                output_template => 'current sessions: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'svname'}
                ]
            }
        },
        { label => 'server-current-session-rate', nlabel => 'server.session.current.rate.countpersecond', set => {
                key_values => [ { name => 'rate' }, { name => 'svname' } ],
                output_template => 'current session rate: %s/s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'svname' }
                ]
            }
        },
        { label => 'server-max-session-rate', nlabel => 'server.session.max.rate.countpersecond', set => {
                key_values => [ { name => 'rate_max' }, { name => 'svname' } ],
                output_template => 'max session rate: %s/s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'svname' }
                ]
            }
        },
        { label => 'server-denied-responses', nlabel => 'server.responses.denied.count', set => {
                key_values => [ { name => 'dresp' }, { name => 'svname' } ],
                output_template => 'denied responses: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'svname' }
                ]
            }
        },
        { label => 'server-connections-errors', nlabel => 'server.connections.error.count', set => {
                key_values => [ { name => 'econ' }, { name => 'svname' } ],
                output_template => 'connection errors: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'svname' }
                ]
            }
        },
        { label => 'server-responses-errors', nlabel => 'server.responses.error.count', set => {
                key_values => [ { name => 'eresp' }, { name => 'svname' } ],
                output_template => 'responses errors: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'svname' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'add-servers'   => { name => 'add_servers' },
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->get_stats();
    my $stats;
    foreach (@$result) {
        foreach my $entry (@$_) {
            if ($entry->{objType} eq 'Backend') {
                $stats->{$entry->{proxyId}}->{$entry->{field}->{name}} = $entry->{value}->{value};
            }
            if ($entry->{objType} eq 'Server') {
                $stats->{$entry->{proxyId}}->{servers}->{$entry->{id}}->{$entry->{field}->{name}} = $entry->{value}->{value};
            }
        }
    }
    foreach (keys %$stats) {
        my $name;
        $name =  $stats->{$_}->{pxname}; 

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
        $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping Backend '" . $name . "'.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{add_servers})) {
            $self->{backends}->{$_}->{servers} = $stats->{$_}->{servers};
        }
        
        $self->{backends}->{$_}->{backend} = $stats->{$_};
        $self->{backends}->{$_}->{display} = $name;
    }

    if (scalar(keys %{$self->{backends}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No Backend found.");
        $self->{output}->option_exit();
    }

    $self->{cache_name} = 'haproxy_' . $self->{mode} . '_' . $options{custom}->get_hostname()  . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));

}

1;

__END__

=head1 MODE

Check HAProxy backend usage.

=over 8

=item B<--add-servers>

Also display and monitor Servers related to a given backend.

=item B<--filter-counters>

Define which counters should appear in the performance data (metrics).
This option will be treated as a regular expression.

Example: C<--filter-counters='^total-connections$'>.

=item B<--filter-name>

Define which backends should be monitored based on their names.
This option will be treated as a regular expression.

=item B<--warning-backend-status>

Define the conditions to match for the backend status to be WARNING.
You can use the following variables: %{status}.

Example: C<--warning-backend-status='%{status} !~ /UP/i'>

=item B<--critical-backend-status>

Define the conditions to match for the backend status to be CRITICAL.
Default: C<'%{status} !~ /UP/i'>.
You can use the following variables: C<%{status}>.

Example: C<--critical-backend-status='%{status} !~ /UP/i'>

=item B<--warning-server-status>

Define the conditions to match for the server status to be WARNING.
You can use the following variables: C<%{status}>.

Example: C<--warning-backend-status='%{status} !~ /UP/i'>

=item B<--critical-server-status>

Define the conditions to match for the status to be CRITICAL. Default: C<'%{status} !~ /UP/i'>.
You can use the following variables: C<%{status}>.

Example: C<--critical-backend-status='%{status} !~ /UP/i'>

=item B<--warning-backend-current-queue>

Thresholds.

=item B<--critical-backend-current-queue>

Thresholds.

=item B<--warning-backend-current-session-rate>

Thresholds.

=item B<--critical-backend-current-session-rate>

Thresholds.

=item B<--warning-backend-max-session-rate>

Thresholds.

=item B<--critical-backend-max-session-rate>

Thresholds.

=item B<--warning-backend-current-sessions>

Thresholds.

=item B<--critical-backend-current-sessions>

Thresholds.

=item B<--warning-backend-total-sessions>

Thresholds.

=item B<--critical-backend-total-sessions>

Thresholds.

=item B<--warning-backend-traffic-in>

Thresholds in b/s.

=item B<--critical-backend-traffic-in>

Thresholds in b/s.

=item B<--warning-backend-traffic-out>

Thresholds in b/s.

=item B<--critical-backend-traffic-out>

Thresholds in b/s.

=item B<--warning-backend-denied-requests>

Thresholds.

=item B<--critical-backend-denied-requests>

Thresholds.

=item B<--warning-backend-denied-responses>

Thresholds.

=item B<--critical-backend-denied-responses>

Thresholds.

=item B<--warning-backend-connections-errors>

Thresholds.

=item B<--critical-backend-connections-errors>

Thresholds.

=item B<--warning-backend-responses-errors>

Thresholds.

=item B<--critical-backend-responses-errors>

Thresholds.

=item B<--warning-server-current-sessions>

Thresholds.

=item B<--critical-server-current-sessions>

Thresholds.

=item B<--warning-server-current-session-rate>

Thresholds.

=item B<--critical-server-current-session-rate>

Thresholds.

=item B<--warning-server-max-session-rate>

Thresholds.

=item B<--critical-server-max-session-rate>

Thresholds.

=item B<--warning-server-denied-responses>

Thresholds.

=item B<--critical-server-denied-responses>

Thresholds.

=item B<--warning-server-connections-errors>

Thresholds.

=item B<--critical-server-connections-errors>

Thresholds.

=item B<--warning-server-responses-errors>

Thresholds.

=item B<--critical-server-responses-errors>

Thresholds.

=back

=cut
