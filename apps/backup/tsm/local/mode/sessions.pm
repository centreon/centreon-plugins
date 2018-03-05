#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

package apps::backup::tsm::local::mode::sessions;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;

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
    
    my $msg = sprintf("[client name: %s] [state: %s] [session type: %s] started since", 
        $self->{result_values}->{client_name}, $self->{result_values}->{state},
        $self->{result_values}->{session_type}, $self->{result_values}->{generation_time});
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{session_id} = $options{new_datas}->{$self->{instance} . '_session_id'};
    $self->{result_values}->{client_name} = $options{new_datas}->{$self->{instance} . '_client_name'};
    $self->{result_values}->{session_type} = $options{new_datas}->{$self->{instance} . '_session_type'};
    $self->{result_values}->{state} = $options{new_datas}->{$self->{instance} . '_state'};
    $self->{result_values}->{since} = $options{new_datas}->{$self->{instance} . '_since'};
    $self->{result_values}->{generation_time} = $options{new_datas}->{$self->{instance} . '_generation_time'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'sessions', type => 1, cb_prefix_output => 'prefix_sessions_output', message_multiple => 'All sessions are ok' },
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'total', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'Total Sessions : %s',
                perfdatas => [
                    { label => 'total', value => 'total_absolute', template => '%s', min => 0 },
                ],
            }
        },
    ];

    $self->{maps_counters}->{sessions} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'session_id' }, { name => 'client_name' }, { name => 'session_type' }, 
                    { name => 'state' }, { name => 'since' }, { name => 'generation_time' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_status_threshold'),
            }
        },
    ];
}

sub prefix_sessions_output {
    my ($self, %options) = @_;

    return "Session '" . $options{instance_value}->{session_id} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "filter-clientname:s"  => { name => 'filter_clientname' },
                                  "filter-sessiontype:s" => { name => 'filter_sessiontype' },
                                  "filter-state:s"       => { name => 'filter_state' },
                                  "warning-status:s"     => { name => 'warning_status', default => '' },
                                  "critical-status:s"    => { name => 'critical_status', default => '' },
                                  "timezone:s"           => { name => 'timezone' },
                                });
    
    centreon::plugins::misc::mymodule_load(output => $self->{output}, module => 'DateTime',
                                           error_msg => "Cannot load module 'DateTime'.");
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $instance_mode = $self;
    $self->change_macros();
    
    $self->{option_results}->{timezone} = 'GMT' if (!defined($self->{option_results}->{timezone}) || $self->{option_results}->{timezone} eq '');
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
    
    my $response = $options{custom}->execute_command(
        query => "SELECT session_id, client_name, start_time, state, session_type FROM sessions"
    );
    $self->{sessions} = {};
    $self->{global} = { total => 0 };

    while ($response =~ /^(.*?),(.*?),(.*?),(.*?),(.*?)$/mg) {
        my ($session_id, $client_name, $start_time, $state, $session_type) = ($1, $2, $3, $4, $5);
        $start_time =~ /^(\d+)-(\d+)-(\d+)\s+(\d+)[:\/](\d+)[:\/](\d+)/;
        
        my $dt = DateTime->new(year => $1, month => $2, day => $3, hour => $4, minute => $5, second => $6,
                               time_zone => $self->{option_results}->{timezone});

        if (defined($self->{option_results}->{filter_clientname}) && $self->{option_results}->{filter_clientname} ne '' &&
            $client_name !~ /$self->{option_results}->{filter_clientname}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $client_name . "': no matching client name filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_sessiontype}) && $self->{option_results}->{filter_sessiontype} ne '' &&
            $session_type !~ /$self->{option_results}->{filter_sessiontype}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $session_type . "': no matching session type filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_state}) && $self->{option_results}->{filter_state} ne '' &&
            $state !~ /$self->{option_results}->{filter_state}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $session_type . "': no matching state filter.", debug => 1);
            next;
        }

        my $diff_time = time() - $dt->epoch;
        $self->{global}->{total}++;

        $self->{sessions}->{$session_id} = {
            session_id => $session_id,
            client_name => $client_name,
            state => $state,
            session_type => $session_type,
            since => $diff_time, generation_time => centreon::plugins::misc::change_seconds(value => $diff_time)
        };
    }
}

1;

__END__

=head1 MODE

Check sessions.

=over 8

=item B<--filter-clientname>

Filter by client name.

=item B<--filter-state>

Filter by state.

=item B<--filter-sessiontype>

Filter by session type.

=item B<--warning-status>

Set warning threshold for status (Default: '')
Can used special variables like: %{client_name}, %{state}, %{session_type}, %{since}

=item B<--critical-status>

Set critical threshold for status (Default: '').
Can used special variables like: %{client_name}, %{state}, %{session_type}, %{since}

=item B<--warning-*>

Set warning threshold. Can be : 'total'.

=item B<--critical-*>

Set critical threshold. Can be : 'total'.

=item B<--timezone>

Timezone of time options. Default is 'GMT'.

=back

=cut

