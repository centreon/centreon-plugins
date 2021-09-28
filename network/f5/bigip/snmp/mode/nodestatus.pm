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

package network::f5::bigip::snmp::mode::nodestatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf(
        'status: %s [state: %s] [reason: %s]',
        $self->{result_values}->{status},
        $self->{result_values}->{state},
        $self->{result_values}->{reason},
    );
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'node', type => 1, cb_prefix_output => 'prefix_node_output', message_multiple => 'All Nodes are ok', skipped_code => { -10 => 1 } },
    ];
    $self->{maps_counters}->{node} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'state' }, { name => 'status' }, { name => 'reason' },{ name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'current-server-connections', set => {
                key_values => [ { name => 'ltmNodeAddrStatServerCurConns' }, { name => 'display' } ],
                output_template => 'current server connections : %s',
                perfdatas => [
                    { label => 'current_server_connections', value => 'ltmNodeAddrStatServerCurConns',  template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
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
    
    $options{options}->add_options(arguments => { 
        'filter-name:s'     => { name => 'filter_name' },
        'unknown-status:s'  => { name => 'unknown_status', default => '' },
        'warning-status:s'  => { name => 'warning_status', default => '%{state} eq "enabled" and %{status} eq "yellow"' },
        'critical-status:s' => { name => 'critical_status', default => '%{state} eq "enabled" and %{status} eq "red"' },
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status', 'unknown_status']);
}

my $map_node_status = {
    0 => 'none', 1 => 'green',
    2 => 'yellow', 3 => 'red',
    4 => 'blue', 5 => 'gray',
};
my $map_node_enabled = {
    0 => 'none', 1 => 'enabled',
    2 => 'disabled', 3 => 'disabledbyparent',
};

# New OIDS
my $mapping = {
    new => {
        AvailState      => { oid => '.1.3.6.1.4.1.3375.2.2.4.3.2.1.3', map => $map_node_status },
        EnabledState    => { oid => '.1.3.6.1.4.1.3375.2.2.4.3.2.1.4', map => $map_node_enabled },
        StatusReason    => { oid => '.1.3.6.1.4.1.3375.2.2.4.3.2.1.6' },
    },
    old => {
        AvailState => { oid => '.1.3.6.1.4.1.3375.2.2.4.1.2.1.13', map => $map_node_status },
        EnabledState => { oid => '.1.3.6.1.4.1.3375.2.2.4.1.2.1.14', map => $map_node_enabled },
        StatusReason => { oid => '.1.3.6.1.4.1.3375.2.2.4.1.2.1.16' },
    },
};
my $mapping2 = {
    ltmNodeAddrStatServerCurConns => { oid => '.1.3.6.1.4.1.3375.2.2.4.2.3.1.9' },
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $mapping->{new}->{AvailState}->{oid} },
            { oid => $mapping->{old}->{AvailState}->{oid} },
        ],
        nothing_quit => 1
    );

    my ($branch_name, $map) = ($mapping->{new}->{AvailState}->{oid}, 'new');
    if (!defined($snmp_result->{$mapping->{new}->{AvailState}->{oid}}) || scalar(keys %{$snmp_result->{$mapping->{new}->{AvailState}->{oid}}}) == 0)  {
        ($branch_name, $map) = ($mapping->{old}->{AvailState}->{oid}, 'old');
    }

    $self->{node} = {};
    foreach my $oid (keys %{$snmp_result->{$branch_name}}) {
        $oid =~ /^$branch_name\.(.*?)\.(.*)$/;
        my ($num, $index) = ($1, $2);
        
        my $result = $options{snmp}->map_instance(mapping => $mapping->{$map}, results => $snmp_result->{$branch_name}, instance => $num . '.' . $index);
        my $name = $self->{output}->decode(join('', map(chr($_), split(/\./, $index))));
        
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping node '" . $name . "'.", debug => 1);
            next;
        }

        $self->{node}->{$num . '.' . $index} = {
            display => $name,
            status => $result->{AvailState}
        };
    }

    $options{snmp}->load(
        oids => [
            $mapping->{$map}->{EnabledState}->{oid},
            $mapping->{$map}->{StatusReason}->{oid},
            $mapping2->{ltmNodeAddrStatServerCurConns}->{oid}
        ], 
        instances => [keys %{$self->{node}}], 
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);

    foreach (keys %{$self->{node}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping->{$map}, results => $snmp_result, instance => $_);
        my $result2 = $options{snmp}->map_instance(mapping => $mapping2, results => $snmp_result, instance => $_);
        
        $result->{StatusReason} = '-' if (!defined($result->{StatusReason}) || $result->{StatusReason} eq '');
        $self->{node}->{$_}->{reason} = $result->{StatusReason};
        $self->{node}->{$_}->{state} = $result->{EnabledState};
        $self->{node}->{$_}->{ltmNodeAddrStatServerCurConns} = $result2->{ltmNodeAddrStatServerCurConns};
    }

    if (scalar(keys %{$self->{node}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check Nodes status.

=over 8

=item B<--filter-name>

Filter by name (regexp can be used).

=item B<--unknown-status>

Set unknown threshold for status (Default: '').
Can used special variables like: %{state}, %{status}, %{display}

=item B<--warning-status>

Set warning threshold for status (Default: '%{state} eq "enabled" and %{status} eq "yellow"').
Can used special variables like: %{state}, %{status}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{state} eq "enabled" and %{status} eq "red"').
Can used special variables like: %{state}, %{status}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'current-server-connections'.

=back

=cut
