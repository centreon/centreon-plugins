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

package network::juniper::common::junos::mode::rsvpsessionstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = "status is '" . $self->{result_values}->{state} . "'";
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{state} = $options{new_datas}->{$self->{instance} . '_jnxRsvpSessionState'};
    return 0;
}

sub prefix_session_output {
    my ($self, %options) = @_;
    
    return "Session '" . $options{instance_value}->{jnxRsvpSessionName} . "' [From '" . $options{instance_value}->{jnxRsvpSessionFrom} . "' to '" . $options{instance_value}->{jnxRsvpSessionTo} . "'] ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'sessions', type => 1, cb_prefix_output => 'prefix_session_output', message_multiple => 'All sessions status are ok' },
    ];
    
    $self->{maps_counters}->{sessions} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'jnxRsvpSessionState' }, { name => 'jnxRsvpSessionFrom' },
                    { name => 'jnxRsvpSessionTo' }, { name => 'jnxRsvpSessionName' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                    "filter-name:s"             => { name => 'filter_name' },
                                    "filter-from:s"             => { name => 'filter_from' },
                                    "filter-to:s"               => { name => 'filter_to' },
                                    "warning-status:s"          => { name => 'warning_status' },
                                    "critical-status:s"         => { name => 'critical_status', default => '%{state} !~ /up/i' },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

my %map_state = (
    1 => 'up',
    2 => 'down',
);

my $mapping = {
    jnxRsvpSessionState => { oid => '.1.3.6.1.4.1.2636.3.30.1.1.1.3', map => \%map_state },
    jnxRsvpSessionFrom => { oid => '.1.3.6.1.4.1.2636.3.30.1.1.1.4' },
    jnxRsvpSessionTo => { oid => '.1.3.6.1.4.1.2636.3.30.1.1.1.5' },
};

my $oid_JnxRsvpSessionEntry = '.1.3.6.1.4.1.2636.3.30.1.1.1';

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{sessions} = {};

    my $results = $options{snmp}->get_table(oid => $oid_JnxRsvpSessionEntry, start => $mapping->{jnxRsvpSessionState}->{oid},
        end => $mapping->{jnxRsvpSessionTo}->{oid}, nothing_quit => 1);
    
    foreach my $oid (keys %{$results}) {
        next if ($oid !~ /^$mapping->{jnxRsvpSessionState}->{oid}\.(.*)/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $results, instance => $instance);
        
        my $jnxRsvpSessionName = '';
        foreach (split /\./, $instance) {
            $jnxRsvpSessionName .= chr if ($_ >= 32 && $_ <= 126);
        }
        $jnxRsvpSessionName = centreon::plugins::misc::trim($jnxRsvpSessionName);

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $jnxRsvpSessionName !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping session '" . $jnxRsvpSessionName . "': no matching filter name.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_from}) && $self->{option_results}->{filter_from} ne '' &&
            $result->{jnxRsvpSessionFrom} !~ /$self->{option_results}->{filter_from}/) {
            $self->{output}->output_add(long_msg => "skipping session '" . $result->{jnxRsvpSessionFrom} . "': no matching filter from.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_to}) && $self->{option_results}->{filter_to} ne '' &&
            $result->{jnxRsvpSessionTo} !~ /$self->{option_results}->{filter_to}/) {
            $self->{output}->output_add(long_msg => "skipping peer '" . $result->{jnxRsvpSessionTo} . "': no matching filter to.", debug => 1);
            next;
        }

        $self->{sessions}->{$instance} = {
            jnxRsvpSessionName => $jnxRsvpSessionName,
            jnxRsvpSessionState => $result->{jnxRsvpSessionState},
            jnxRsvpSessionFrom => $result->{jnxRsvpSessionFrom},
            jnxRsvpSessionTo => $result->{jnxRsvpSessionTo},
        }
    }

    if (scalar(keys %{$self->{sessions}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No sessions found.');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check RSVP sessions status.

=over 8

=item B<--filter-*>

Filter sessions.
Can be: 'name', 'from', 'to' (can be a regexp).

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{state}

=item B<--critical-status>

Set critical threshold for status (Default: '%{state} !~ /up/i').
Can used special variables like: %{state}

=back

=cut
