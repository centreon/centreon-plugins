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

package network::nokia::timos::snmp::mode::sapusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = 'state : ' . $self->{result_values}->{oper_state} . ' (admin: ' . $self->{result_values}->{admin_state} . ')';
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{oper_state} = $options{new_datas}->{$self->{instance} . '_sapOperStatus'};
    $self->{result_values}->{admin_state} = $options{new_datas}->{$self->{instance} . '_sapAdminStatus'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'sap', type => 1, cb_prefix_output => 'prefix_sap_output', message_multiple => 'All service access points are ok' }
    ];
    
    $self->{maps_counters}->{sap} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'sapAdminStatus' }, { name => 'sapOperStatus' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        },
        { label => 'traffic-in-below-cir', set => {
                key_values => [ { name => 'sapBaseStatsIngressQchipForwardedInProfOctets', per_second => 1 }, { name => 'display' } ],
                output_template => 'Traffic In Below CIR : %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'traffic_in_below_cir', template => '%.2f', min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'traffic-in-above-cir', set => {
                key_values => [ { name => 'sapBaseStatsIngressQchipForwardedOutProfOctets', per_second => 1 }, { name => 'display' } ],
                output_template => 'Traffic In Above CIR : %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'traffic_in_above_cir', template => '%.2f', min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'traffic-out-below-cir', set => {
                key_values => [ { name => 'sapBaseStatsEgressQchipForwardedInProfOctets', per_second => 1 }, { name => 'display' } ],
                output_template => 'Traffic Out Below CIR : %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'traffic_out_below_cir', template => '%.2f', min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'traffic-out-above-cir', set => {
                key_values => [ { name => 'sapBaseStatsEgressQchipForwardedOutProfOctets', per_second => 1 }, { name => 'display' } ],
                output_template => 'Traffic Out Above CIR : %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'traffic_out_above_cir', template => '%.2f', min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_sap_output {
    my ($self, %options) = @_;
    
    return "Service Access Point '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-name:s'     => { name => 'filter_name' },
        'warning-status:s'  => { name => 'warning_status', default => '' },
        'critical-status:s' => { name => 'critical_status', default => '%{admin_state} eq "up" and %{oper_state} !~ /up/' }
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

my %map_admin_status = (1 => 'up', 2 => 'down');
my %map_oper_status = (1 => 'up', 2 => 'down', 3 => 'ingressQosMismatch',
    4 => 'egressQosMismatch', 5 => 'portMtuTooSmall', 6 => 'svcAdminDown',
    7 => 'iesIfAdminDown',
);
my $mapping = {
    sapDescription  => { oid => '.1.3.6.1.4.1.6527.3.1.2.4.3.2.1.5' },
    sapAdminStatus  => { oid => '.1.3.6.1.4.1.6527.3.1.2.4.3.2.1.6', map => \%map_admin_status },
    sapOperStatus   => { oid => '.1.3.6.1.4.1.6527.3.1.2.4.3.2.1.7', map => \%map_oper_status },
    sapBaseStatsIngressQchipForwardedInProfOctets   => { oid => '.1.3.6.1.4.1.6527.3.1.2.4.3.6.1.12' },
    sapBaseStatsIngressQchipForwardedOutProfOctets  => { oid => '.1.3.6.1.4.1.6527.3.1.2.4.3.6.1.14' },
    sapBaseStatsEgressQchipForwardedInProfOctets    => { oid => '.1.3.6.1.4.1.6527.3.1.2.4.3.6.1.20' },
    sapBaseStatsEgressQchipForwardedOutProfOctets   => { oid => '.1.3.6.1.4.1.6527.3.1.2.4.3.6.1.22' },
};

sub manage_selection {
    my ($self, %options) = @_;

    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Need to use SNMP v2c or v3.");
        $self->{output}->option_exit();
    }

    my $snmp_result = $options{snmp}->get_multiple_table(oids => [
                                                            { oid => $mapping->{sapDescription}->{oid} },
                                                         ], return_type => 1, nothing_quit => 1);
    my $done_description = {};
    $self->{sap} = {};
    foreach my $oid (keys %{$snmp_result}) {
        $oid =~ /^$mapping->{sapDescription}->{oid}\.(.*)$/;
        my $instance = $1;
        if (!defined($snmp_result->{$oid}) || $snmp_result->{$oid} eq '') {
            $self->{output}->output_add(long_msg => "skipping sap '$instance': cannot get a description. please set it.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $snmp_result->{$oid} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping sap '" . $snmp_result->{$oid} . "'.", debug => 1);
            next;
        }
        
        if (defined($done_description->{$snmp_result->{$oid}})) {
            $self->{output}->output_add(long_msg => "skipping sap '" . $snmp_result->{$oid} . "': duplicated description.", debug => 1);
            next;
        } else {
            $done_description->{$snmp_result->{$oid}} = 1;
        }
        $self->{sap}->{$instance} = { display => $snmp_result->{$oid} };
    }
    
    $options{snmp}->load(oids => [$mapping->{sapAdminStatus}->{oid}, $mapping->{sapOperStatus}->{oid},
        $mapping->{sapBaseStatsIngressQchipForwardedInProfOctets}->{oid}, $mapping->{sapBaseStatsIngressQchipForwardedOutProfOctets}->{oid},
        $mapping->{sapBaseStatsEgressQchipForwardedInProfOctets}->{oid}, $mapping->{sapBaseStatsEgressQchipForwardedOutProfOctets}->{oid},
        ], 
        instances => [keys %{$self->{sap}}], instance_regexp => '^(.*)$');
    $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);
    
    foreach (keys %{$self->{sap}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $_);        
        
        foreach my $name (('sapBaseStatsIngressQchipForwardedInProfOctets', 'sapBaseStatsIngressQchipForwardedOutProfOctets',
                           'sapBaseStatsEgressQchipForwardedInProfOctets', 'sapBaseStatsEgressQchipForwardedOutProfOctets')) {
            $result->{$name} *= 8 if (defined($result->{$name}));
        }
        
        foreach my $name (keys %$mapping) {
            $self->{sap}->{$_}->{$name} = $result->{$name} if (defined($result->{$name}));
        }
    }
    
    if (scalar(keys %{$self->{sap}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No service access point found.");
        $self->{output}->option_exit();
    }
    
    $self->{cache_name} = "nokia_timos_" . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check service access point usage.

=over 8

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{status}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{admin_state} eq "up" and %{oper_state} !~ /up/').
Can used special variables like: %{status}, %{display}

=item B<--warning-*>

Threshold warning.
Can be: 'traffic-in-above-cir', 'traffic-in-below-cir', 'traffic-out-above-cir', 'traffic-out-below-cir'.

=item B<--critical-*>

Threshold critical.
Can be: 'traffic-in-above-cir', 'traffic-in-below-cir', 'traffic-out-above-cir', 'traffic-out-below-cir'.

=item B<--filter-name>

Filter by virtual server name (can be a regexp).

=back

=cut
