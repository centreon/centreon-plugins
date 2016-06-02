#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package network::netasq::snmp::mode::hanodes;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

my $instance_mode;

sub custom_threshold_output {
    my ($self, %options) = @_;
    my $status = 'ok';
    my $message;

    eval {
        local $SIG{__WARN__} = sub { $message = $_[0]; };
        local $SIG{__DIE__} = sub { $message = $_[0]; };

        if (defined($instance_mode->{option_results}->{critical_state}) && $instance_mode->{option_results}->{critical_state} ne '' &&
            eval "$instance_mode->{option_results}->{critical_state}") {
            $status = 'critical';
        } elsif (defined($instance_mode->{option_results}->{warning_state}) && $instance_mode->{option_results}->{warning_state} ne '' &&
                 eval "$instance_mode->{option_results}->{warning_state}") {
            $status = 'warning';
        }
    };
    if (defined($message)) {
        $self->{output}->output_add(long_msg => 'filter status issue: ' . $message);
    }

    return $status;
}

sub custom_state_output {
    my ($self, %options) = @_;

    my $msg = sprintf("state is '%s'", $self->{result_values}->{state});
    return $msg;
}

sub custom_state_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{state} = $options{new_datas}->{$self->{instance} . '_state'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'nodes', type => 1, cb_prefix_output => 'prefix_node_output', message_multiple => 'All HA nodes are OK' },
    ];

    $self->{maps_counters}->{nodes} = [
        { label => 'state', threshold => 0,  set => {
                key_values => [ { name => 'state' }, { name => 'display' } ],
                closure_custom_calc => \&custom_state_calc,
                closure_custom_output => \&custom_state_output,
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&custom_threshold_output,
            }
        },
        { label => 'health', set => {
                key_values => [ { name => 'health' }, { name => 'display' } ],
                output_template => 'node Health: %s%%',
                perfdatas => [
                    { label => 'health', value => 'health_absolute', template => '%d',
                      min => 0, max => 100, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        }
    ];
}

sub prefix_node_output {
    my ($self, %options) = @_;

    return "Node '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                "filter-node:s"         => { name => 'filter_node' },
                                "warning-state:s"       => { name => 'warning_state', default => '' },
                                "critical-state:s"      => { name => 'critical_state', default => '%{state} eq "offline"' },
                                });
    return $self;
}

sub change_macros {
    my ($self, %options) = @_;

    foreach (('warning_state', 'critical_state')) {
        if (defined($self->{option_results}->{$_})) {
            $self->{option_results}->{$_} =~ s/%\{(.*?)\}/\$self->{result_values}->{$1}/g;
        }
    }
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros();
    $instance_mode = $self;
}

my %map_status = (
    1 => 'online',
    2 => 'offline',
);

my $mapping = {
    ntqFwSerial  => { oid => '.1.3.6.1.4.1.11256.1.11.7.1.2' },
    ntqHAQuality => { oid => '.1.3.6.1.4.1.11256.1.11.7.1.7' },
    ntqOnline    => { oid => '.1.3.6.1.4.1.11256.1.11.7.1.3', map => \%map_status },
};

my $oid_ntqNodeTable = '.1.3.6.1.4.1.11256.1.11.7';

sub manage_selection {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    $self->{results} = $options{snmp}->get_table(oid => $oid_ntqNodeTable,
                                                 nothing_quit => 1);
    foreach my $oid (keys %{$self->{results}}) {
        $oid =~ /^$mapping->{ntqOnline}->{oid}\.(.*)$/;
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}, instance => $instance);

        if (defined($self->{option_results}->{filter_nodes}) && $self->{option_results}->{filter_nodes} ne '' &&
            $result->{ntqFwSerial} !~ /$self->{option_results}->{filter_nodes}/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $result->{ntqFwSerial} . "': no matching filter.", debug => 1);
            next;
        }
        $self->{nodes}->{$result->{ntqFwSerial}} = { state   => $result->{ntqOnline},
                                                     health  => $result->{ntqHAQuality},
                                                     display => $result->{ntqFwSerial} };
    }
}

1;

__END__

=head1 MODE

Check Netasq node state and health

=over 8

=item B<--filter-node>

Filter name with regexp.

=item B<--warning-health>

Warning on health level. (e.g --warning 90:)

=item B<--critical-health>

Critical on health level. (e.g --critical 80:)

=item B<--warning-state>

Set warning threshold for status. Use "%{state}" as a special variable.
Value can be 'online' or 'offline'.

=item B<--critical-state>

Set critical threshold for status. Use "%{state}" as a special variable.
Value can be 'online' or 'offline'.

=back

=cut
