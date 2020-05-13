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

package centreon::common::airespace::snmp::mode::apstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    my $msg;
    
    if ($self->{result_values}->{admstatus} eq 'disabled') {
        $msg = ' is disabled';
    } else {
        $msg = 'Status : ' . $self->{result_values}->{opstatus};
    }

    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{opstatus} = $options{new_datas}->{$self->{instance} . '_opstatus'};
    $self->{result_values}->{admstatus} = $options{new_datas}->{$self->{instance} . '_admstatus'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_init => 'skip_global', },
        { name => 'ap', type => 1, cb_prefix_output => 'prefix_ap_output', message_multiple => 'All AP status are ok' }
    ];
    $self->{maps_counters}->{global} = [
        { label => 'total', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'Total ap : %s',
                perfdatas => [
                    { label => 'total', value => 'total', template => '%s', 
                      min => 0 },
                ],
            }
        },
        { label => 'total-associated', set => {
                key_values => [ { name => 'associated' } ],
                output_template => 'Total ap associated : %s',
                perfdatas => [
                    { label => 'total_associated', value => 'associated', template => '%s', 
                      min => 0 },
                ],
            }
        },
        { label => 'total-disassociating', set => {
                key_values => [ { name => 'disassociating' } ],
                output_template => 'Total ap disassociating : %s',
                perfdatas => [
                    { label => 'total_disassociating', value => 'disassociating', template => '%s', 
                      min => 0 },
                ],
            }
        },
        { label => 'total-enabled', set => {
                key_values => [ { name => 'enable' } ],
                output_template => 'Total ap enabled : %s',
                perfdatas => [
                    { label => 'total_enabled', value => 'enable', template => '%s', 
                      min => 0 },
                ],
            }
        },
        { label => 'total-disabled', set => {
                key_values => [ { name => 'disable' } ],
                output_template => 'Total ap disabled : %s',
                perfdatas => [
                    { label => 'total_disabled', value => 'disable', template => '%s', 
                      min => 0 },
                ],
            }
        },
    ];
    
    $self->{maps_counters}->{ap} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'opstatus' }, { name => 'admstatus' }, { name => 'display' } ],
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
                                  "filter-name:s"           => { name => 'filter_name' },
                                  "warning-status:s"        => { name => 'warning_status', default => '' },
                                  "critical-status:s"       => { name => 'critical_status', default => '%{admstatus} eq "enable" and %{opstatus} !~ /associated|downloading/' },
                                });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub skip_global {
    my ($self, %options) = @_;
    
    scalar(keys %{$self->{ap}}) == 1 ? return(1) : return(0);
}

sub prefix_ap_output {
    my ($self, %options) = @_;
    
    return "AP '" . $options{instance_value}->{display} . "' ";
}

my %map_admin_status = (
    1 => 'enable',
    2 => 'disable',
);
my %map_operation_status = (
    1 => 'associated',
    2 => 'disassociating',
    3 => 'downloading',
);
my $mapping = {
    bsnAPName        => { oid => '.1.3.6.1.4.1.14179.2.2.1.1.3' },
};
my $mapping2 = {
    bsnAPOperationStatus    => { oid => '.1.3.6.1.4.1.14179.2.2.1.1.6', map => \%map_operation_status },
};
my $mapping3 = {
    bsnAPAdminStatus        => { oid => '.1.3.6.1.4.1.14179.2.2.1.1.37', map => \%map_admin_status },
};
my $oid_agentInventoryMachineModel = '.1.3.6.1.4.1.14179.1.1.1.3';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{ap} = {};
    $self->{global} = { total => 0, associated => 0, disassociating => 0, downloading => 0, enable => 0, disable => 0 };
    $self->{results} = $options{snmp}->get_multiple_table(oids => [ { oid => $oid_agentInventoryMachineModel },
                                                                   { oid => $mapping->{bsnAPName}->{oid} },
                                                                   { oid => $mapping2->{bsnAPOperationStatus}->{oid} },
                                                                   { oid => $mapping3->{bsnAPAdminStatus}->{oid} },
                                                                 ],
                                                         nothing_quit => 1);
    $self->{output}->output_add(long_msg => "Model: " . 
        (defined($self->{results}->{$oid_agentInventoryMachineModel}->{$oid_agentInventoryMachineModel . '.0'}) ? $self->{results}->{$oid_agentInventoryMachineModel}->{$oid_agentInventoryMachineModel . '.0'} : 'unknown'));
    foreach my $oid (keys %{$self->{results}->{ $mapping->{bsnAPName}->{oid} }}) {
        $oid =~ /^$mapping->{bsnAPName}->{oid}\.(.*)$/;
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{ $mapping->{bsnAPName}->{oid} }, instance => $instance);
        my $result2 = $options{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{ $mapping2->{bsnAPOperationStatus}->{oid} }, instance => $instance);
        my $result3 = $options{snmp}->map_instance(mapping => $mapping3, results => $self->{results}->{ $mapping3->{bsnAPAdminStatus}->{oid} }, instance => $instance);
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{bsnAPName} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $result->{bsnAPName} . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{global}->{total}++;
        $self->{global}->{$result2->{bsnAPOperationStatus}}++;
        $self->{global}->{$result3->{bsnAPAdminStatus}}++;
        
        $self->{ap}->{$instance} = { display => $result->{bsnAPName}, 
                                     opstatus => $result2->{bsnAPOperationStatus}, admstatus => $result3->{bsnAPAdminStatus}};
    }
    
    if (scalar(keys %{$self->{ap}}) <= 0) {
        $self->{output}->output_add(long_msg => 'no AP associated (can be: slave wireless controller or your filter)');
    }
}

1;

__END__

=head1 MODE

Check AP status.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^total-disassociating|total-associated$'

=item B<--filter-name>

Filter AP name (can be a regexp).

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{admstatus}, %{opstatus}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{admstatus} eq "enable" and %{opstatus} !~ /associated|downloading/').
Can used special variables like: %{admstatus}, %{opstatus}, %{display}

=item B<--warning-*>

Threshold warning.
Can be: 'total', 'total-associated', 'total-disassociating', 'total-enabled', 'total-disabled'.

=item B<--critical-*>

Threshold critical.
Can be: 'total', 'total-associated', 'total-disassociating', 'total-enabled', 'total-disabled'.

=back

=cut
