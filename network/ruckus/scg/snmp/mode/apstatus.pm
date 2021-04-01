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

package network::ruckus::scg::snmp::mode::apstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = "connection status is '" . $self->{result_values}->{connection_status} . "'";
    $msg .= ", registration status is '" . $self->{result_values}->{registration_status} . "'";
    $msg .= ", configuration status is '" . $self->{result_values}->{configuration_status} . "'";
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{connection_status} = $options{new_datas}->{$self->{instance} . '_ruckusSCGAPConnStatus'};
    $self->{result_values}->{registration_status} = $options{new_datas}->{$self->{instance} . '_ruckusSCGAPRegStatus'};
    $self->{result_values}->{configuration_status} = $options{new_datas}->{$self->{instance} . '_ruckusSCGAPConfigStatus'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'ap', type => 1, cb_prefix_output => 'prefix_ap_output', message_multiple => 'All APs are ok' }
    ];
    
    $self->{maps_counters}->{ap} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'ruckusSCGAPConnStatus' }, { name => 'ruckusSCGAPRegStatus' },
                    { name => 'ruckusSCGAPConfigStatus' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub prefix_ap_output {
    my ($self, %options) = @_;
    
    return "AP '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                  "filter-name:s"       => { name => 'filter_name' },
                                  "warning-status:s"    => { name => 'warning_status', default => '%{configuration_status} !~ /^Up-to-date$/i' },
                                  "critical-status:s"   => { name => 'critical_status', default => '%{connection_status} =~ /^Disconnect$/i' },
                                });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

my $oid_ruckusSCGAPName = '.1.3.6.1.4.1.25053.1.3.2.1.1.2.2.1.5',
my $mapping = {
    ruckusSCGAPConnStatus   => { oid => '.1.3.6.1.4.1.25053.1.3.2.1.1.2.2.1.16' },
    ruckusSCGAPRegStatus    => { oid => '.1.3.6.1.4.1.25053.1.3.2.1.1.2.2.1.17' },
    ruckusSCGAPConfigStatus => { oid => '.1.3.6.1.4.1.25053.1.3.2.1.1.2.2.1.18' },
};

sub manage_selection {
    my ($self, %options) = @_;

    $self->{ap} = {};
    my $snmp_result = $options{snmp}->get_table(oid => $oid_ruckusSCGAPName, nothing_quit => 1);
    foreach my $oid (keys %{$snmp_result}) {
        $oid =~ /^$oid_ruckusSCGAPName\.(.*)$/;
        my $instance = $1;
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $snmp_result->{$oid} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $snmp_result->{$oid} . "'.", debug => 1);
            next;
        }
        
        $self->{ap}->{$instance} = { display => $snmp_result->{$oid} };
    }
    
    $options{snmp}->load(oids => [ $mapping->{ruckusSCGAPConnStatus}->{oid},
                                   $mapping->{ruckusSCGAPRegStatus}->{oid},
                                   $mapping->{ruckusSCGAPConfigStatus}->{oid} ],
                         instances => [ keys %{$self->{ap}} ],
                         instance_regexp => '^(.*)$');
    $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);
    
    foreach (keys %{$self->{ap}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $_);        
                
        foreach my $name (keys %$mapping) {
            $self->{ap}->{$_}->{$name} = $result->{$name};
        }
    }
    
    if (scalar(keys %{$self->{ap}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No AP found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check AP status.

=over 8

=item B<--filter-name>

Filter by AP name (can be a regexp).

=item B<--warning-status>

Set warning threshold for status (Default: '%{configuration_status} !~ /^Up-to-date$/i').
Can used special variables like: %{connection_status}, %{registration_status}, %{configuration_status}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{connection_status} =~ /^Disconnect$/i').
Can used special variables like: %{connection_status}, %{registration_status}, %{configuration_status}, %{display}

=back

=cut
