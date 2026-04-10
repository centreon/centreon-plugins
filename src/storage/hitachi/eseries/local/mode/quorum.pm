#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package storage::hitachi::eseries::local::mode::quorum;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::constants qw(:counters);
use centreon::plugins::misc qw/is_excluded is_empty/;

sub prefix_quorum_output {
    my ($self, %options) = @_;
    return "Quorum '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'quorums', type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_quorum_output',
          message_multiple => 'All quorums are normal' }
    ];

    $self->{maps_counters}->{quorums} = [
        { label => 'status', type => COUNTER_KIND_TEXT, critical_default => '%{status} ne "NORMAL"', set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
		output_template => 'Status: %s',
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
        'quorum-id:s'         => { name => 'quorum_id',         default => '' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{output}->option_exit(short_msg => "Quorum ID is invalid.")
	if $self->{option_results}->{quorum_id} ne '' && $self->{option_results}->{quorum_id} !~ /^\d+$/;

    $self->{quorum_id} = $self->{option_results}->{quorum_id};
}

sub manage_selection {
    my ($self, %options) = @_;

    # https://docs.hitachivantara.com/r/en-us/command-control-interface/01-87-03/mk-90rd7009/configuration-setting-commands/raidcom-get-quorum
    $self->{quorums} = {};

    my $qid = $self->{quorum_id};
    $qid = 0 if $self->{quorum_id} eq '';

    # When no filter is applied on quorum_id we query all quorums starting from 0 and continue as long as raidcom responds
    while (1) {
        my ($stdout, $exit_code) = $options{custom}->execute_command(
            command         => 'raidcom',
            command_options => 'get quorum -quorum_id ' . $qid . ' -I' . $options{custom}->get_baie_id(),
            no_quit         => 1
        );
        last if is_empty($stdout) || $stdout =~ /^\s+$/ || $exit_code != 0;

        # Convert "key: value" formatted output into a hash
        my %q;
        while ($stdout =~ /^([^\s]+)\s*:\s*(.+)$/mg) {
	    my $value = $2;
	    my $key = $1 =~ s/\W//gr;
	    $q{$key} = $value;
        }
        next unless defined $q{STS};

        my $qrdid = $q{QRDID} // $qid;

        $self->{quorums}->{$qrdid} = {
            display    => $qrdid,
            status     => $q{STS},
            qrp_serial => $q{QRP_Serial} // '-',
            ldev       => $q{LDEV}       // '-'
        };

	last if $self->{quorum_id} ne '';
	$qid++
    }

    $self->{output}->option_exit(short_msg => "No quorum found.")
        unless keys %{$self->{quorums}};
}

1;

__END__

=head1 MODE

Check Hitachi E-Series quorum status.

Command used: C<raidcom get quorum -quorum_id <id> -I<baie-id>>

=over 8

=item B<--quorum-id>

Check a specific quorum ID (optional). If not specified, all quorums are discovered automatically starting from ID 0.

=item B<--warning-status>

Warning threshold for quorum status.

=item B<--critical-status>

Critical threshold for quorum status (default: C<'%{status} ne "NORMAL"'>).

=back

=cut
