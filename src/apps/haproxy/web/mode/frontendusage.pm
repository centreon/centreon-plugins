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

package apps::haproxy::web::mode::frontendusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub prefix_frontend_output {
    my ($self, %options) = @_;

    return "Frontend '" . $options{instance_value}->{display} . "' ";
}

sub prefix_listener_output {
    my ($self, %options) = @_;

    return "Listener '" . $options{instance_value}->{svname} . "' ";
}

sub prefix_global_frontend_output {
    my ($self, %options) = @_;

    return 'frontend ';
}

sub frontend_long_output {
    my ($self, %options) = @_;

    return "Frontend '" . $options{instance_value}->{display} . "':";
}

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf("status: %s", $self->{result_values}->{status});
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'frontends', type => 3, cb_prefix_output => 'prefix_frontend_output', cb_long_output => 'frontend_long_output', message_multiple => 'All frontends are ok', indent_long_output => '    ', skipped_code => { -10 => 1 },
            group => [
                { name => 'frontend', type => 0, cb_prefix_output => 'prefix_global_frontend_output' },
                { name => 'listeners', type => 1, display_long => 1, cb_prefix_output => 'prefix_listener_output', message_multiple => 'listeners are ok', skipped_code => { -10 => 1 } }
            ]
        }
    ];
    
    $self->{maps_counters}->{frontend} = [
         {
            label => 'frontend-status', 
            type => 2, 
            critical_default => '%{status} !~ /OPEN/i',
            set => {
                key_values => [ { name => 'status' }, { name => 'pxname' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'frontend-current-session-rate', nlabel => 'frontend.session.current.rate.countpersecond', set => {
                key_values => [ { name => 'rate' }, { name => 'pxname' } ],
                output_template => 'current session rate: %s/s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'pxname' }
                ]
            }
        },
        { label => 'frontend-max-session-rate', nlabel => 'frontend.session.max.rate.countpersecond', set => {
                key_values => [ { name => 'rate_max' }, { name => 'pxname' } ],
                output_template => 'max session rate: %s/s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'pxname' }
                ]
            }
        },
        { label => 'frontend-current-sessions', nlabel => 'frontend.sessions.current.count', set => {
                key_values => [ { name => 'scur' }, { name => 'pxname' } ],
                output_template => 'current sessions: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'pxname' }
                ]
            }
        },
        { label => 'frontend-total-sessions', nlabel => 'frontend.sessions.total.count', set => {
                key_values => [ { name => 'stot' }, { name => 'pxname' } ],
                output_template => 'total sessions: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'pxname' }
                ]
            }
        },
        { label => 'frontend-max-sessions', nlabel => 'frontend.sessions.maximum.count', set => {
                key_values => [ { name => 'smax' }, { name => 'pxname' } ],
                output_template => 'max sessions: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'pxname' }
                ]
            }
        },
        { label => 'frontend-traffic-in', nlabel => 'frontend.traffic.in.bitpersecond', set => {
                key_values => [ { name => 'bin', per_second => 1 }, { name => 'pxname' } ],
                output_template => 'traffic in: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%.2f', min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'pxname' }
                ]
            }
        },
        { label => 'frontend-traffic-out', nlabel => 'frontend.traffic.out.bitpersecond', set => {
                key_values => [ { name => 'bout', per_second => 1 }, { name => 'pxname' } ],
                output_template => 'traffic out: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%.2f', min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'pxname' }
                ]
            }
        },
        { label => 'frontend-denied-requests', nlabel => 'frontend.requests.denied.count', set => {
                key_values => [ { name => 'dreq' }, { name => 'pxname' } ],
                output_template => 'denied requests: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'pxname' }
                ]
            }
        },
        { label => 'frontend-denied-responses', nlabel => 'frontend.responses.denied.count', set => {
                key_values => [ { name => 'dresp' }, { name => 'pxname' } ],
                output_template => 'denied responses: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'pxname' }
                ]
            }
        },
        { label => 'frontend-errors-requests', nlabel => 'frontend.requests.error.count', set => {
                key_values => [ { name => 'ereq' }, { name => 'pxname' } ],
                output_template => 'error requests: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'pxname' }
                ]
            }
        }
    ];
    $self->{maps_counters}->{listeners} = [
        {
            label => 'listener-status', 
            type => 2, 
            critical_default => '%{status} !~ /OPEN/i',
            set => {
                key_values => [ { name => 'status' }, { name => 'pxname' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'listener-current-sessions', nlabel => 'listener.sessions.current.count', set => {
                key_values => [ { name => 'scur' }, { name => 'svname' } ],
                output_template => 'current sessions: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'svname' }
                ]
            }
        },
        { label => 'listener-denied-requests', nlabel => 'listener.requests.denied.count', set => {
                key_values => [ { name => 'dreq' }, { name => 'svname' } ],
                output_template => 'denied requests: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'svname' }
                ]
            }
        },
        { label => 'listener-denied-responses', nlabel => 'listener.responses.denied.count', set => {
                key_values => [ { name => 'dresp' }, { name => 'svname' } ],
                output_template => 'denied responses: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'svname' }
                ]
            }
        },
        { label => 'listener-errors-requests', nlabel => 'listener.requests.error.count', set => {
                key_values => [ { name => 'ereq' }, { name => 'svname' } ],
                output_template => 'error requests: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'svname' }
                ]
            }
        },
        { label => 'listener-traffic-in', nlabel => 'listener.traffic.in.bitpersecond', set => {
                key_values => [ { name => 'bin', per_second => 1 }, { name => 'pxname' } ],
                output_template => 'traffic in: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%.2f', min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'svname' }
                ]
            }
        },
        { label => 'listener-traffic-out', nlabel => 'listener.traffic.out.bitpersecond', set => {
                key_values => [ { name => 'bout', per_second => 1 }, { name => 'svname' } ],
                output_template => 'traffic out: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%.2f', min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'svname' }
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
        'add-listeners' => { name => 'add_listeners' },
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
            if ($entry->{objType} eq 'Frontend') {
                $stats->{$entry->{proxyId}}->{$entry->{field}->{name}} = $entry->{value}->{value};
            }
            if ($entry->{objType} eq 'Listener') {
                $stats->{$entry->{proxyId}}->{listeners}->{$entry->{id}}->{$entry->{field}->{name}} = $entry->{value}->{value};
            }
        }
    }
    foreach (keys %$stats) {
        my $name;
        $name =  $stats->{$_}->{pxname}; 

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
        $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping frontend '" . $name . "'.", debug => 1);
            next;
        }
        
        if (defined($self->{option_results}->{add_listeners})) {
            $self->{frontends}->{$_}->{listeners} = $stats->{$_}->{listeners};
        }
        $self->{frontends}->{$_}->{frontend} = $stats->{$_};
        $self->{frontends}->{$_}->{display} = $name;
    }

    if (scalar(keys %{$self->{frontends}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No Frontend found.");
        $self->{output}->option_exit();
    }

    $self->{cache_name} = 'haproxy_' . $self->{mode} . '_' . $options{custom}->get_hostname()  . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));

}

1;

__END__

=head1 MODE

Check HAProxy frontend usage.

=over 8

=item B<--add-listeners>

Also display and monitor listeners related to a given frontend.

=item B<--filter-counters>

Define which counters should appear in the performance data (metrics).
This option will be treated as a regular expression.

Example: --filter-counters='^total-connections$'.

=item B<--filter-name>

Define which frontends should be monitored based on their names.
This option will be treated as a regular expression.

=item B<--warning-frontend-status>

Define the conditions to match for the status to be B<WARNING>.

You can use the following variables: C<%{status}>.

Example: C<--warning-frontend-status='%{status} !~ /UP/i'>

=item B<--critical-frontend-status>

Define the conditions to match for the status to be B<CRITICAL>. Default: C<%{status} !~ /OPEN/i>.

You can use the following variables: C<%{status}>.

Example: C<--critical-frontend-status='%{status} !~ /UP/i'>

=item B<--warning-listener-status>

Define the conditions to match for the status to be B<WARNING>

You can use the following variables: C<%{status}>.

Example: C<--warning-listener-status='%{status} !~ /UP/i'>

=item B<--critical-listener-status>

Define the conditions to match for the status to be B<CRITICAL>. Default: C<%{status} !~ /OPEN/i>.

You can use the following variables: C<%{status}>.

Example: C<--critical-listener-status='%{status} !~ /UP/i'>

=item B<--warning-frontend-current-session-rate>

Thresholds.

=item B<--critical-frontend-current-session-rate>

Thresholds.

=item B<--warning-frontend-max-session-rate>

Thresholds.

=item B<--critical-frontend-max-session-rate>

Thresholds.

=item B<--warning-frontend-current-sessions>

Thresholds.

=item B<--critical-frontend-current-sessions>

Thresholds.

=item B<--warning-frontend-total-sessions>

Thresholds.

=item B<--critical-frontend-total-sessions>

Thresholds.

=item B<--warning-frontend-max-sessions>

Thresholds.

=item B<--critical-frontend-max-sessions>

Thresholds.

=item B<--warning-frontend-traffic-in>

Thresholds in b/s.

=item B<--critical-frontend-traffic-in>

Thresholds in b/s.

=item B<--warning-frontend-traffic-out>

Thresholds in b/s.

=item B<--critical-frontend-traffic-out>

Thresholds in b/s.

=item B<--warning-frontend-denied-requests>

Thresholds.

=item B<--critical-frontend-denied-requests>

Thresholds.

=item B<--warning-frontend-denied-responses>

Thresholds.

=item B<--critical-frontend-denied-responses>

Thresholds.

=item B<--warning-frontend-errors-requests>

Thresholds.

=item B<--critical-frontend-errors-requests>

Thresholds.

=item B<--warning-listener-current-sessions>

Thresholds.

=item B<--critical-listener-current-sessions>

Thresholds.

=item B<--warning-listener-denied-requests>

Thresholds.

=item B<--critical-listener-denied-requests>

Thresholds.

=item B<--warning-listener-denied-responses>

Thresholds.

=item B<--critical-listener-denied-responses>

Thresholds.

=item B<--warning-listener-errors-requests>

Thresholds.

=item B<--critical-listener-errors-requests>

Thresholds.

=item B<--warning-listener-traffic-in>

Thresholds in b/s.

=item B<--critical-listener-traffic-in>

Thresholds in b/s.

=item B<--warning-listener-traffic-out>

Thresholds in b/s.

=item B<--critical-listener-traffic-out>

Thresholds in b/s.

=back

=cut
