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

package centreon::common::aruba::snmp::mode::controllerstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf("Status is '%s', Role is '%s' [Ip: %s][Version: %s][Location: %s]",
        $self->{result_values}->{status},
        $self->{result_values}->{role},
        $self->{result_values}->{ip},
        $self->{result_values}->{version},
        $self->{result_values}->{location});
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{name} = $options{new_datas}->{$self->{instance} . '_sysExtSwitchName'};
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_sysExtSwitchStatus'};
    $self->{result_values}->{role} = $options{new_datas}->{$self->{instance} . '_sysExtSwitchRole'};
    $self->{result_values}->{ip} = $options{new_datas}->{$self->{instance} . '_sysExtSwitchIPAddress'};
    $self->{result_values}->{version} = $options{new_datas}->{$self->{instance} . '_sysExtSwitchSWVersion'};
    $self->{result_values}->{location} = $options{new_datas}->{$self->{instance} . '_sysExtSwitchLocation'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_init => 'skip_global' },
        { name => 'controllers', type => 1, cb_prefix_output => 'prefix_output',
          message_multiple => 'All controllers status are ok' },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'connected-current', nlabel => 'controllers.connected.current.count', set => {
                key_values => [ { name => 'current' } ],
                output_template => 'Total controllers: %d',
                perfdatas => [
                    { value => 'current', template => '%d', min => 0 },
                ],
            }
        },
    ];

    $self->{maps_counters}->{controllers} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'sysExtSwitchIPAddress' }, { name => 'sysExtSwitchName' },
                    { name => 'sysExtSwitchLocation' }, { name => 'sysExtSwitchSWVersion' },
                    { name => 'sysExtSwitchRole' }, { name => 'sysExtSwitchStatus' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub skip_global {
    my ($self, %options) = @_;

    scalar(keys %{$self->{controllers}}) > 1 ? return(0) : return(1);
}

sub prefix_output {
    my ($self, %options) = @_;

    return "Controller '" . $options{instance_value}->{sysExtSwitchName} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        "filter-name:s"     => { name => 'filter_name' },
        "filter-ip:s"       => { name => 'filter_ip' },
        "filter-location:s" => { name => 'filter_location' },
        "warning-status:s"  => { name => 'warning_status' },
        "critical-status:s" => { name => 'critical_status', default => '%{status} !~ /active/i' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

my %map_status = (
    1 => 'active', 2 => 'inactive'
);
my %map_role = (
    1 => 'master', 2 => 'local', 3 => 'backupmaster'
);

my $oid_wlsxSysExtSwitchListTable = '.1.3.6.1.4.1.14823.2.2.1.2.1.19.1';

my $mapping = {
    sysExtSwitchRole => { oid => '.1.3.6.1.4.1.14823.2.2.1.2.1.19.1.2', map => \%map_role },
    sysExtSwitchLocation=> { oid => '.1.3.6.1.4.1.14823.2.2.1.2.1.19.1.3' },
    sysExtSwitchSWVersion => { oid => '.1.3.6.1.4.1.14823.2.2.1.2.1.19.1.4' },
    sysExtSwitchStatus => { oid => '.1.3.6.1.4.1.14823.2.2.1.2.1.19.1.5', map => \%map_status },
    sysExtSwitchName => { oid => '.1.3.6.1.4.1.14823.2.2.1.2.1.19.1.6' },
};
sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_wlsxSysExtSwitchListTable,
        start => $mapping->{sysExtSwitchRole}->{oid},
        end => $mapping->{sysExtSwitchName}->{oid},
        nothing_quit => 1
    );
    
    $self->{global}->{current} = 0;
    $self->{controllers} = {};
    
    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{sysExtSwitchRole}->{oid}\.(.*)/);
        my $instance = $1;
        
        my $result = $options{snmp}->map_instance(
            mapping => $mapping,
            results => $snmp_result,
            instance => $instance
        );
        $result->{sysExtSwitchIPAddress} = $instance;
        
        if (defined($self->{option_results}->{filter_ip}) && $self->{option_results}->{filter_ip} ne '' &&
            $result->{sysExtSwitchIPAddress} !~ /$self->{option_results}->{filter_ip}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{sysExtSwitchIPAddress} . "': no matching filter ip.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{sysExtSwitchName} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{sysExtSwitchName} . "': no matching filter name.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_location}) && $self->{option_results}->{filter_location} ne '' &&
            $result->{sysExtSwitchLocation} !~ /$self->{option_results}->{filter_location}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{sysExtSwitchLocation} . "': no matching filter location.", debug => 1);
            next;
        }
        
        $self->{controllers}->{$result->{sysExtSwitchName}} = { %{$result} };
        $self->{global}->{current}++;
    }
    
    if (scalar(keys %{$self->{controllers}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No controller found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check controller status (WLSX-SYSTEMEXT-MIB).
(Works only on master controller).

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'connected-current' (global), 'status' (per controller).
'status' can use special variables like: %{name},
%{status}, %{ip}, %{role}, %{location} (Default: '')

=item B<--critical-*>

Threshold critical.
Can be: 'connected-current' (global), 'status' (per controller).
'status' can use special variables like: %{name},
%{status}, %{ip}, %{role}, %{location} (Default: '%{status} !~ /active/i')

=item B<--filter-*>

Filter by 'ip', 'name', 'location' (regexp can be used).

=back

=cut
