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

package network::juniper::common::junos::mode::lspstatus;

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
    
    $self->{result_values}->{state} = $options{new_datas}->{$self->{instance} . '_mplsLspState'};
    return 0;
}

sub prefix_session_output {
    my ($self, %options) = @_;
    
    return "LSP '" . $options{instance_value}->{mplsLspName} . "' [From '" . $options{instance_value}->{mplsLspFrom} . "' to '" . $options{instance_value}->{mplsLspTo} . "'] ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'lsps', type => 1, cb_prefix_output => 'prefix_session_output', message_multiple => 'All LSP status are ok' },
    ];
    
    $self->{maps_counters}->{lsps} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'mplsLspState' }, { name => 'mplsLspFrom' },
                    { name => 'mplsLspTo' }, { name => 'mplsLspName' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'transition-count', set => {
                key_values => [ { name => 'mplsLspInfoTransitions' }, { name => 'mplsLspName' } ],
                output_template => 'Transition count: %d',
                perfdatas => [
                    { label => 'transition_count', value => 'mplsLspInfoTransitions', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'mplsLspName' },
                ],
            }
        },
        { label => 'last-transition', set => {
                key_values => [ { name => 'mplsLspInfoLastTransitionHuman' }, { name => 'mplsLspInfoLastTransition' },
                    { name => 'mplsLspName' } ],
                output_template => 'Last transition: %s',
                perfdatas => [
                    { label => 'last_transition', value => 'mplsLspInfoLastTransition', template => '%d',
                      min => 0, unit => 's', label_extra_instance => 1, instance_use => 'mplsLspName' },
                ],
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
    1 => 'unknown',
    2 => 'up',
    3 => 'down',
    4 => 'notInService',
    5 => 'backupActive',
);

my $mapping = {
    mplsLspState => { oid => '.1.3.6.1.4.1.2636.3.2.5.1.2', map => \%map_state },
    mplsLspInfoTransitions => { oid => '.1.3.6.1.4.1.2636.3.2.5.1.8' },
    mplsLspInfoLastTransition => { oid => '.1.3.6.1.4.1.2636.3.2.5.1.9' },
    mplsLspFrom => { oid => '.1.3.6.1.4.1.2636.3.2.5.1.15' },
    mplsLspTo => { oid => '.1.3.6.1.4.1.2636.3.2.5.1.16' },
};

my $oid_mplsLspEntry = '.1.3.6.1.4.1.2636.3.2.5.1';

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{lsps} = {};

    my $results = $options{snmp}->get_table(oid => $oid_mplsLspEntry, start => $mapping->{mplsLspState}->{oid},
        end => $mapping->{mplsLspTo}->{oid}, nothing_quit => 1);
    
    foreach my $oid (keys %{$results}) {
        next if ($oid !~ /^$mapping->{mplsLspState}->{oid}\.(.*)/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $results, instance => $instance);
        
        my $mplsLspName = '';
        foreach (split /\./, $instance) {
            $mplsLspName .= chr if ($_ >= 32 && $_ <= 126);
        }
        $mplsLspName = centreon::plugins::misc::trim($mplsLspName);

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $mplsLspName !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping session '" . $mplsLspName . "': no matching filter name.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_from}) && $self->{option_results}->{filter_from} ne '' &&
            $result->{mplsLspFrom} !~ /$self->{option_results}->{filter_from}/) {
            $self->{output}->output_add(long_msg => "skipping session '" . $result->{mplsLspFrom} . "': no matching filter from.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_to}) && $self->{option_results}->{filter_to} ne '' &&
            $result->{mplsLspTo} !~ /$self->{option_results}->{filter_to}/) {
            $self->{output}->output_add(long_msg => "skipping peer '" . $result->{mplsLspTo} . "': no matching filter to.", debug => 1);
            next;
        }
        
        $self->{lsps}->{$instance} = {
            mplsLspName => $mplsLspName,
            mplsLspState => $result->{mplsLspState},
            mplsLspInfoTransitions => $result->{mplsLspInfoTransitions},
            mplsLspInfoLastTransition => $result->{mplsLspInfoLastTransition} / 100,
            mplsLspInfoLastTransitionHuman => centreon::plugins::misc::change_seconds(value => $result->{mplsLspInfoLastTransition} / 100),
            mplsLspFrom => $result->{mplsLspFrom},
            mplsLspTo => $result->{mplsLspTo},
        }
    }

    if (scalar(keys %{$self->{lsps}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No entries found.');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check LSPs (Label Switched Path) status.

=over 8

=item B<--filter-*>

Filter LSPs.
Can be: 'name', 'from', 'to' (can be a regexp).

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{state}

=item B<--critical-status>

Set critical threshold for status (Default: '%{state} !~ /up/i').
Can used special variables like: %{state}

=item B<--warning-*>

Threshold warning.
Can be: 'transition-count', 'last-transition' (seconds).

=item B<--critical-*>

Threshold critical.
Can be: 'transition-count', 'last-transition' (seconds).

=back

=cut
