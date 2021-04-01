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

package storage::netapp::ontap::snmp::mode::sis;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);
use Digest::MD5 qw(md5_hex);

sub custom_status_output { 
    my ($self, %options) = @_;

    my $msg = sprintf('status : %s [state: %s] [lastOpError: %s]',
        $self->{result_values}->{status},
        $self->{result_values}->{state},
        $self->{result_values}->{lastOpError},
    );
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_sisStatus'};
    $self->{result_values}->{state} = $options{new_datas}->{$self->{instance} . '_sisState'};
    $self->{result_values}->{lastOpError} = $options{new_datas}->{$self->{instance} . '_sisLastOpError'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'sis', type => 1, cb_prefix_output => 'prefix_sis_output', message_multiple => 'All single instance storages are ok', skipped_code => { -10 => 1, -11 => 1 } }
    ];

    $self->{maps_counters}->{sis} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'sisStatus' }, { name => 'sisState' }, { name => 'sisLastOpError' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub prefix_sis_output {
    my ($self, %options) = @_;

    return "Single instance storage '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s'     => { name => 'filter_name' },
        'unknown-status:s'  => { name => 'unknown_status', default => '' },
        'warning-status:s'  => { name => 'warning_status', default => '' },
        'critical-status:s' => { name => 'critical_status', default => '%{state} eq "enabled" and %{lastOpError} !~ /-|Success/i' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status', 'unknown_status']);
}

my $map_status = {
    1 => 'idle', 2 => 'active', 3 => 'undoing',
    4 => 'pending', 5 => 'initializing',
    6 => 'downgrading', 7 => 'disabled',
};

my $map_state = { 1 => 'disabled', 2 => 'enabled' };

my $mapping = {
    sisState        => { oid => '.1.3.6.1.4.1.789.1.23.2.1.3', map => $map_state }, 
    sisStatus       => { oid => '.1.3.6.1.4.1.789.1.23.2.1.4', map => $map_status },
    sisLastOpError  => { oid => '.1.3.6.1.4.1.789.1.23.2.1.12' },
};

sub manage_selection {
    my ($self, %options) = @_;
    
    my $oid_sisIsLicensed = '.1.3.6.1.4.1.789.1.23.1.0';
    my $snmp_result = $options{snmp}->get_leef(oids => [$oid_sisIsLicensed]);
    if (!defined($snmp_result->{$oid_sisIsLicensed}) || $snmp_result->{$oid_sisIsLicensed} != 2) {
        $self->{output}->add_option_msg(short_msg => 'single instance storage is not licensed');
        $self->{output}->option_exit();
    }
    
    my $oid_sisPath = '.1.3.6.1.4.1.789.1.23.2.1.2';
    my $oid_sisVserver = '.1.3.6.1.4.1.789.1.23.2.1.16';
    
    $self->{snapvault} = {};
    $snmp_result = $options{snmp}->get_multiple_table(oids => [ { oid => $oid_sisPath }, { oid => $oid_sisVserver }], return_type => 1, nothing_quit => 1);
    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$oid_sisPath\.(.*)$/);
        my $instance = $1;
        my $name = defined($snmp_result->{$oid_sisVserver . '.' . $instance}) && $snmp_result->{$oid_sisVserver . '.' . $instance} ne '' ?
            $snmp_result->{$oid_sisVserver . '.' . $instance} . ':' . $snmp_result->{$oid} :
            $snmp_result->{$oid};

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping sis '" . $name . "'.", debug => 1);
            next;
        }

        $self->{sis}->{$instance} = { display => $name };
    }

    if (scalar(keys %{$self->{sis}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found.");
        $self->{output}->option_exit();
    }
    
    $options{snmp}->load(oids => [
            map($_->{oid}, values(%$mapping)) 
        ],
        instances => [keys %{$self->{sis}}], instance_regexp => '^(.*)$');
    $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);
    
    foreach (keys %{$self->{sis}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $_);
        
        $self->{sis}->{$_} = { %{$self->{sis}->{$_}}, %$result };
    }
}

1;

__END__

=head1 MODE

Check single instance storage.

=over 8

=item B<--filter-name>

Filter name (can be a regexp).

=item B<--unknown-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{state}, %{status}, %{lastOpError}, %{display}

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{state}, %{status}, %{lastOpError}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{state} eq "enabled" and %{lastOpError} !~ /-|Success/i').
Can used special variables like: %{state}, %{status}, %{lastOpError}, %{display}

=back

=cut
