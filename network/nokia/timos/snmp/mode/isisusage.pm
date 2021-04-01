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

package network::nokia::timos::snmp::mode::isisusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    
     my $msg = 'state : ' . $self->{result_values}->{oper_state} . ' (admin: ' . $self->{result_values}->{admin_state} . ')';
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{oper_state} = $options{new_datas}->{$self->{instance} . '_oper_state'};
    $self->{result_values}->{admin_state} = $options{new_datas}->{$self->{instance} . '_admin_state'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}


sub custom_total_sessions_calc {
    my ($self, %options) = @_;

    my $total_sessions = 0;
    foreach (keys %{$options{new_datas}}) {
        if (/$self->{instance}_total_sessions_(\d+)/) {
            my $new_total = $options{new_datas}->{$_};
            next if (!defined($options{old_datas}->{$_}));
            my $old_total = $options{old_datas}->{$_};
            
            $total_sessions += $new_total - $old_total;
            $total_sessions += $old_total if ($total_sessions <= 0);
        }
    }
    
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{total_sessions} = $total_sessions;
    
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'isis', type => 1, cb_prefix_output => 'prefix_isis_output', message_multiple => 'All IS-IS instances are ok' },
        { name => 'int', type => 1, cb_prefix_output => 'prefix_int_output', message_multiple => 'All interfaces are ok' },
    ];
    $self->{maps_counters}->{int} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'oper_state' }, { name => 'admin_state' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
    
    $self->{maps_counters}->{isis} = [
        { label => 'total-int-inservice', set => {
                key_values => [ { name => 'inService' }, { name => 'display' } ],
                output_template => 'Total Interfaces InServices : %s',
                perfdatas => [
                    { label => 'total_int_inservice', value => 'inService', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'total-int-outservice', set => {
                key_values => [ { name => 'outOfService' }, { name => 'display' } ],
                output_template => 'Total Interfaces OutOfServices : %s',
                perfdatas => [
                    { label => 'total_int_outservice', value => 'outOfService', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_isis_output {
    my ($self, %options) = @_;
    
    return "IS-IS instance '" . $options{instance_value}->{display} . "' ";
}

sub prefix_int_output {
    my ($self, %options) = @_;
    
    return "Interface '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                  "filter-name:s"           => { name => 'filter_name' },
                                  "warning-status:s"        => { name => 'warning_status', default => '' },
                                  "critical-status:s"       => { name => 'critical_status', default => '%{admin_state} eq "inService" and %{oper_state} !~ /inService|transition/' },
                                });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

my %map_admin_status = (1 => 'noop', 2 => 'inService', 3 => 'outOfService');
my %map_oper_status = (1 => 'unknown', 2 => 'inService', 3 => 'outOfService', 4 => 'transition');

my $oid_vRtrName = '.1.3.6.1.4.1.6527.3.1.2.3.1.1.4';
my $oid_ifName = '.1.3.6.1.2.1.31.1.1.1.1';
# index = vRtrID + isisInstance + ifIndex
my $mapping = {
    tmnxIsisIfAdminState    => { oid => '.1.3.6.1.4.1.6527.3.1.2.88.2.1.1.3', map => \%map_admin_status },
    tmnxIsisIfOperState     => { oid => '.1.3.6.1.4.1.6527.3.1.2.88.2.1.1.4', map => \%map_oper_status },
};

sub manage_selection {
    my ($self, %options) = @_;
 
    my $snmp_result = $options{snmp}->get_multiple_table(oids => [
                                                            { oid => $oid_vRtrName },
                                                            { oid => $oid_ifName },
                                                            { oid => $mapping->{tmnxIsisIfAdminState}->{oid} },
                                                            { oid => $mapping->{tmnxIsisIfOperState}->{oid} },
                                                         ], return_type => 1, nothing_quit => 1);
    $self->{isis} = {};
    $self->{int} = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{tmnxIsisIfOperState}->{oid}\.(\d+)\.(\d+)\.(\d+)$/);
        my ($vrtr_id, $isis_id, $ifindex) = ($1, $2, $3);
        
        my $vrtr_name = $snmp_result->{$oid_vRtrName . '.' . $vrtr_id};
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $vrtr_id . '.' . $isis_id . '.' . $ifindex);
        my $name = $vrtr_name . '.' . $isis_id;
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $name . "'.", debug => 1);
            next;
        }
        
        $self->{isis}->{$vrtr_id . '.' . $isis_id} = { display => $name, inService => 0, outOfService => 0 } if (!defined($self->{isis}->{$vrtr_id . '.' . $isis_id})); 
        $self->{isis}->{$vrtr_id . '.' . $isis_id}->{$result->{tmnxIsisIfOperState}}++;
        
        $self->{int}->{$vrtr_id . '.' . $isis_id . '.' . $ifindex} = {
            display => $name . '.' . $snmp_result->{$oid_ifName . '.' . $ifindex},
            admin_state => $result->{tmnxIsisIfAdminState},
            oper_state => $result->{tmnxIsisIfOperState},
        };
    }
    
    if (scalar(keys %{$self->{isis}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No IS-IS intance found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check IS-IS usage.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'total-int-inservice', 'total-int-outservice'.

=item B<--critical-*>

Threshold critical.
Can be: 'total-int-inservice', 'total-int-outservice'.

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{display}, %{oper_state}, %{admin_state}.

=item B<--critical-status>

Set critical threshold for status (Default: '%{admin_state} eq "inService" and %{oper_state} !~ /inService|transition/').
Can used special variables like:  %{display}, %{oper_state}, %{admin_state}.

=item B<--filter-name>

Filter by instance name (can be a regexp).

=back

=cut
