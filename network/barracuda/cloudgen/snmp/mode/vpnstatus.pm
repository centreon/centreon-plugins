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

package network::barracuda::cloudgen::snmp::mode::vpnstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = "status is '" . $self->{result_values}->{status} . "'";
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_vpnState'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'vpns', type => 1, cb_prefix_output => 'prefix_vpns_output', message_multiple => 'All VPNs are ok' }
    ];
    
    $self->{maps_counters}->{vpns} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'vpnState' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub prefix_vpns_output {
    my ($self, %options) = @_;
    
    return "VPN '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-name:s'       => { name => 'filter_name' },
        'warning-status:s'    => { name => 'warning_status', default => '' },
        'critical-status:s'   => { name => 'critical_status', default => '%{status} =~ /^down$/i' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

my %map_status = (
    -1 => 'down',
    0 => 'down-disabled',
    1 => 'active',
);

my $oid_vpnName = '.1.3.6.1.4.1.10704.1.6.1.1';
my $mapping = {
    vpnState => { oid => '.1.3.6.1.4.1.10704.1.6.1.2', map => \%map_status },
};

sub manage_selection {
    my ($self, %options) = @_;

    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Need to use SNMP v2c or v3.");
        $self->{output}->option_exit();
    }

    my $snmp_result = $options{snmp}->get_table(oid => $oid_vpnName, nothing_quit => 1);
    $self->{vpns} = {};
    foreach my $oid (keys %{$snmp_result}) {
        $oid =~ /^$oid_vpnName\.(.*)$/;
        my $instance = $1;
        $snmp_result->{$oid} =~ s/\\//g;
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $snmp_result->{$oid} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping VPN '" . $snmp_result->{$oid} . "'.", debug => 1);
            next;
        }
        
        $self->{vpns}->{$instance} = { display => $snmp_result->{$oid} };
    }
    
    $options{snmp}->load(oids => [$mapping->{vpnState}->{oid}], instances => [keys %{$self->{vpns}}], instance_regexp => '^(.*)$');
    $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);
    
    foreach (keys %{$self->{vpns}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $_);        
                
        foreach my $name (keys %$mapping) {
            $self->{vpns}->{$_}->{$name} = $result->{$name};
        }
    }
    
    if (scalar(keys %{$self->{vpns}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No VPNs found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check VPNs status.

=over 8

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{status}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /^down$/i').
Can used special variables like: %{status}, %{display}

=item B<--filter-name>

Filter by VPN name (Can be a regexp).

=back

=cut
