#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package network::f5::bigip::snmp::mode::virtualserverstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'status: %s [state: %s] [reason: %s]',
        $self->{result_values}->{status},
        $self->{result_values}->{state},
        $self->{result_values}->{reason}
    );
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'vs', type => 1, cb_prefix_output => 'prefix_vs_output', message_multiple => 'All virtual servers are ok' }
    ];

    $self->{maps_counters}->{vs} = [
        {
            label => 'status',
            type => 2,
            warning_default => '%{state} eq "enabled" and %{status} eq "yellow"',
            critical_default => '%{state} eq "enabled" and %{status} eq "red"',
            set => {
                key_values => [ { name => 'state' }, { name => 'status' }, { name => 'reason' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'current-client-connections', nlabel => 'virtualserver.connections.client.current.count', set => {
                key_values => [ { name => 'client_current_connections' }, { name => 'display' } ],
                output_template => 'current client connections: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];
}

sub prefix_vs_output {
    my ($self, %options) = @_;
    
    return "Virtual server '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'filter-name:s' => { name => 'filter_name' }
    });
    
    return $self;
}

my $map_vs_status = {
    0 => 'none', 1 => 'green',
    2 => 'yellow', 3 => 'red',
    4 => 'blue', 5 => 'gray'
};
my $map_vs_enabled = {
    0 => 'none', 1 => 'enabled',
    2 => 'disabled', 3 => 'disabledbyparent'
};

my $mapping = {
    new => {
        state  => { oid => '.1.3.6.1.4.1.3375.2.2.10.13.2.1.3', map => $map_vs_enabled }, # EnabledState
        reason => { oid => '.1.3.6.1.4.1.3375.2.2.10.13.2.1.5' }, # StatusReason
        client_current_connections => { oid => '.1.3.6.1.4.1.3375.2.2.10.2.3.1.12' } # ltmVirtualServStatClientCurConns
    },
    old => {
        state  => { oid => '.1.3.6.1.4.1.3375.2.2.10.1.2.1.23', map => $map_vs_enabled }, # EnabledState
        reason => { oid => '.1.3.6.1.4.1.3375.2.2.10.1.2.1.25' }, # StatusReason
        client_current_connections => { oid => '.1.3.6.1.4.1.3375.2.2.10.2.3.1.12' } # ltmVirtualServStatClientCurConns
    }
};
# AvailState
my $oid_status = {
    new => '.1.3.6.1.4.1.3375.2.2.10.13.2.1.2',
    old => '.1.3.6.1.4.1.3375.2.2.10.1.2.1.22'
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_status->{new} },
            { oid => $oid_status->{old} }
        ],
        nothing_quit => 1
    );
    
    my $map = 'new';
    if (!defined($snmp_result->{ $oid_status->{new} }) || scalar(keys %{$snmp_result->{ $oid_status->{new} }}) == 0)  {
        $map = 'old';
    }

    $self->{vs} = {};
    foreach my $oid (keys %{$snmp_result->{ $oid_status->{$map} }}) {
        $oid =~ /^$oid_status->{$map}\.(.*?)\.(.*)$/;
        my ($num, $index) = ($1, $2);

        my $name = $self->{output}->to_utf8(join('', map(chr($_), split(/\./, $index))));
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $name . "': no matching filter name.", debug => 1);
            next;
        }
        

        $self->{vs}->{$num . '.' . $index} = {
            display => $name,
            status => $map_vs_status->{ $snmp_result->{ $oid_status->{$map} }->{$oid} }
        };
    }

    if (scalar(keys %{$self->{vs}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No entry found.');
        $self->{output}->option_exit();
    }

    $options{snmp}->load(
        oids => [ map($_->{oid}, values(%{$mapping->{$map}})) ],
        instances => [ keys %{$self->{vs}} ],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef();
    foreach (keys %{$self->{vs}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping->{$map}, results => $snmp_result, instance => $_);

        $result->{StatusReason} = '-' if (!defined($result->{StatusReason}) || $result->{StatusReason} eq '');
        $self->{vs}->{$_} = { %{$self->{vs}->{$_}}, %$result };
    }
}

1;

__END__

=head1 MODE

Check virtual servers.

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
Can be: 'current-client-connections'.

=back

=cut
