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

package network::cisco::standard::ssh::mode::voicedialpeer;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_status_output { 
    my ($self, %options) = @_;

    my $msg = 'operation state: ' . $self->{result_values}->{oper} . ' [admin state: ' . $self->{result_values}->{admin} . ']';
    if ($self->{result_values}->{keepalive} ne '') {
        $msg .= '[keepalive: ' . $self->{result_values}->{keepalive} . ']';
    }
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'voice_peers', type => 1, cb_prefix_output => 'prefix_voice_output', message_multiple => 'All voice dial peers are ok', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total', nlabel => 'peers.total.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'peers total %s',
                perfdatas => [
                    { value => 'total', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'total-operational-up', nlabel => 'peers.total.operational.up.count', display_ok => 0, set => {
                key_values => [ { name => 'oper_up' } ],
                output_template => 'peers operational up %s',
                perfdatas => [
                    { value => 'oper_up', template => '%s', min => 0 },
                ],
            }
        },
    ];

    $self->{maps_counters}->{voice_peers} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'admin' }, { name => 'oper' }, { name => 'keepalive' }, { name => 'display' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub prefix_voice_output {
    my ($self, %options) = @_;

    return "Voice peer dial '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-name:s'     => { name => 'filter_name' },
        'unknown-status:s'  => { name => 'unknown_status', default => '' },
        'warning-status:s'  => { name => 'warning_status', default => '' },
        'critical-status:s' => { name => 'critical_status', default => '%{admin} eq "up" and %{oper} eq "down"' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status', 'unknown_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($result) = $options{custom}->execute_command(commands => ['term length 0', 'show dial-peer voice']);
    #VoiceOverIpPeer100
    #   peer type = voice, system default peer = FALSE, information type = voice,
    #    ...
    #	group = 100, Admin state is up, Operation state is up,
    #   incoming called-number = `.T',
    #connections/maximum = 0/unlimited,
    #    bandwidth/maximum = 0/unlimited,
    #    voice class sip options-keepalive dial-peer action = busyout,
    #...
    #VoiceOverIpPeer200
    #...
    #    voice class sip options-keepalive dial-peer action = active,
    #...

    $self->{global} = { total => 0, oper_up => 0, oper_down => 0 };
    $self->{voice_peers} = {};
    while ($result =~ /^(\S+)\n(.*?)(?=\n\S+\n|\Z$)/msg) {
        my ($display, $content) = ($1, $2);
        next if ($content !~ /Admin\s+state\s+is\s+(\S+),\s*Operation\s+state\s+is\s+(\S+?),/msi);

        my ($admin, $oper) = ($1, $2);
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $display !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $display . "': no matching filter.", debug => 1);
            next;
        }

        my $keepalive = '';
        $keepalive = $1 if ($content =~ /options-keepalive\s+dial-peer\s+action\s+=\s+(\S+?),/msi);
        $self->{voice_peers}->{$display} = {
            display => $display,
            admin => $admin,
            oper => $oper,
            keepalive => $keepalive,
        };
        $self->{global}->{total}++;
        $self->{global}->{'oper_' . $oper}++;
    }
}

1;

__END__

=head1 MODE

Check voice dial peers status.

=over 8

=item B<--filter-name>

Filter name (can be a regexp).

=item B<--unknown-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{admin}, %{oper}, %{keepalive}, %{display}

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{admin}, %{oper}, %{keepalive}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{admin} eq "up" and %{oper} eq "down"').
Can used special variables like: %{admin}, %{oper}, %{keepalive}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total', 'total-operational-up'.

=back

=cut
