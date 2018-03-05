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

package network::f5::bigip::snmp::mode::nodestatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

my $thresholds = {
    node => [
        ['none', 'CRITICAL'],
        ['green', 'OK'],
        ['yellow', 'WARNING'],
        ['red', 'CRITICAL'],
        ['blue', 'UNKNOWN'],
        ['gray', 'UNKNOWN'],
    ],
};
my $instance_mode;

sub custom_threshold_output {
    my ($self, %options) = @_;
    
    return $instance_mode->get_severity(section => 'node', value => $self->{result_values}->{AvailState});
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{AvailState} = $options{new_datas}->{$self->{instance} . '_AvailState'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'node', type => 1, cb_prefix_output => 'prefix_node_output', message_multiple => 'All Nodes are ok' },
    ];
    $self->{maps_counters}->{node} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'AvailState' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                output_template => 'Status : %s', output_error_template => 'Status : %s',
                output_use => 'AvailState',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_threshold_output'),
            }
        },
        { label => 'current-server-connections', set => {
                key_values => [ { name => 'ltmNodeAddrStatServerCurConns' }, { name => 'Name' } ],
                output_template => 'Current Server Connections : %s', output_error_template => "Current Server Connections : %s",
                perfdatas => [
                    { label => 'current_server_connections', value => 'ltmNodeAddrStatServerCurConns_absolute',  template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'Name_absolute' },
                ],
            }
        },
    ];
}

sub prefix_node_output {
    my ($self, %options) = @_;
    
    return "Node '" . $options{instance_value}->{Name} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "filter-name:s"           => { name => 'filter_name' },
                                  "threshold-overload:s@"   => { name => 'threshold_overload' },
                                });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
    $instance_mode = $self;
    
    $self->{overload_th} = {};
    foreach my $val (@{$self->{option_results}->{threshold_overload}}) {
        if ($val !~ /^(.*?),(.*?),(.*)$/) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload option '" . $val . "'.");
            $self->{output}->option_exit();
        }
        my ($section, $status, $filter) = ($1, $2, $3);
        if ($self->{output}->is_litteral_status(status => $status) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload status '" . $val . "'.");
            $self->{output}->option_exit();
        }
        $self->{overload_th}->{$section} = [] if (!defined($self->{overload_th}->{$section}));
        push @{$self->{overload_th}->{$section}}, {filter => $filter, status => $status};
    }
}

sub get_severity {
    my ($self, %options) = @_;
    my $status = 'UNKNOWN'; # default 
    
    if (defined($self->{overload_th}->{$options{section}})) {
        foreach (@{$self->{overload_th}->{$options{section}}}) {            
            if ($options{value} =~ /$_->{filter}/i) {
                $status = $_->{status};
                return $status;
            }
        }
    }
    foreach (@{$thresholds->{$options{section}}}) {           
        if ($options{value} =~ /$$_[0]/i) {
            $status = $$_[1];
            return $status;
        }
    }
    
    return $status;
}

my %map_node_status = (
    0 => 'none',
    1 => 'green',
    2 => 'yellow',
    3 => 'red',
    4 => 'blue', # unknown
    5 => 'gray',
);
my %map_node_enabled = (
    0 => 'none',
    1 => 'enabled',
    2 => 'disabled',
    3 => 'disabledbyparent',
);

# New OIDS
my $mapping = {
    new => {
        AvailState      => { oid => '.1.3.6.1.4.1.3375.2.2.4.3.2.1.3', map => \%map_node_status },
        EnabledState    => { oid => '.1.3.6.1.4.1.3375.2.2.4.3.2.1.4', map => \%map_node_enabled },
        StatusReason    => { oid => '.1.3.6.1.4.1.3375.2.2.4.3.2.1.6' },
    },
    old => {
        AvailState => { oid => '.1.3.6.1.4.1.3375.2.2.4.1.2.1.13', map => \%map_node_status },
        EnabledState => { oid => '.1.3.6.1.4.1.3375.2.2.4.1.2.1.14', map => \%map_node_enabled },
        StatusReason => { oid => '.1.3.6.1.4.1.3375.2.2.4.1.2.1.16' },
    },
};
my $mapping2 = {
    ltmNodeAddrStatServerCurConns => { oid => '.1.3.6.1.4.1.3375.2.2.4.2.3.1.9' },
};
my $oid_ltmNodeAddrName = '.1.3.6.1.4.1.3375.2.2.4.1.2.1.17'; # old
my $oid_ltmNodeAddrStatusName = '.1.3.6.1.4.1.3375.2.2.4.3.2.1.7'; # new

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_multiple_table(oids => [
                                                            { oid => $oid_ltmNodeAddrName },
                                                            { oid => $oid_ltmNodeAddrStatusName },
                                                         ],
                                                         , nothing_quit => 1);
    
    my ($branch_name, $map) = ($oid_ltmNodeAddrStatusName, 'new');
    if (!defined($snmp_result->{$oid_ltmNodeAddrStatusName}) || scalar(keys %{$snmp_result->{$oid_ltmNodeAddrStatusName}}) == 0)  {
        ($branch_name, $map) = ($oid_ltmNodeAddrName, 'old');
    }
    
    $self->{node} = {};
    foreach my $oid (keys %{$snmp_result->{$branch_name}}) {
        $oid =~ /^$branch_name\.(.*)$/;
        my $instance = $1;
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $snmp_result->{$branch_name}->{$oid} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping node '" . $snmp_result->{$branch_name}->{$oid} . "'.", debug => 1);
            next;
        }
        
        $self->{node}->{$instance} = { Name => $snmp_result->{$branch_name}->{$oid} };
    }
    
    $options{snmp}->load(oids => [$mapping->{$map}->{AvailState}->{oid}, $mapping->{$map}->{EnabledState}->{oid},
        $mapping->{$map}->{StatusReason}->{oid}, $mapping2->{ltmNodeAddrStatServerCurConns}->{oid}
        ], 
        instances => [keys %{$self->{node}}], instance_regexp => '^(.*)$');
    $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);
    
    foreach (keys %{$self->{node}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping->{$map}, results => $snmp_result, instance => $_);
        my $result2 = $options{snmp}->map_instance(mapping => $mapping2, results => $snmp_result, instance => $_);
        
        if ($result->{EnabledState} !~ /enabled/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $self->{node}->{$_}->{Name} . "': state is '$result->{EnabledState}'.", debug => 1);
            delete $self->{node}->{$_};
            next;
        }
        $self->{node}->{$_}->{ltmNodeAddrStatServerCurConns} = $result2->{ltmNodeAddrStatServerCurConns};
        $result->{StatusReason} = '-' if (!defined($result->{StatusReason}) || $result->{StatusReason} eq '');
        foreach my $name (keys %{$mapping->{$map}}) {
            $self->{node}->{$_}->{$name} = $result->{$name};
        }
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

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='node,CRITICAL,^(?!(green)$)'

=item B<--warning-*>

Threshold warning.
Can be: 'current-server-connections'.

=item B<--critical-*>

Threshold critical.
Can be: 'current-server-connections'.

=back

=cut
