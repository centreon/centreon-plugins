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

package centreon::common::aruba::snmp::mode::license;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);
use Time::Local;

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf("Status is '%s', Expires in '%s' [%s]",
        $self->{result_values}->{flag},
        $self->{result_values}->{expires_human},
        $self->{result_values}->{expires_date});
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{key} = $options{new_datas}->{$self->{instance} . '_sysExtLicenseKey'};
    $self->{result_values}->{flag} = $options{new_datas}->{$self->{instance} . '_sysExtLicenseFlags'};
    $self->{result_values}->{service} = $options{new_datas}->{$self->{instance} . '_sysExtLicenseService'};
    $self->{result_values}->{expires} = $options{new_datas}->{$self->{instance} . '_sysExtLicenseExpires'};
    $self->{result_values}->{expires_date} = $options{new_datas}->{$self->{instance} . '_sysExtLicenseExpires'};
    $self->{result_values}->{expires_human} = 'Never';
    
    if ($self->{result_values}->{expires} !~ /Never/) {
        my ($year, $mon, $mday, $hour, $min, $sec) = split(/[\s\-:]+/, $self->{result_values}->{expires});
        $self->{result_values}->{expires} = timelocal($sec, $min, $hour, $mday, $mon - 1, $year) - time();
        $self->{result_values}->{expires_human} = centreon::plugins::misc::change_seconds(value => $self->{result_values}->{expires});
        $self->{result_values}->{expires_human} = $self->{result_values}->{expires} = 0 if ($self->{result_values}->{expires} < 0);
    }
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'license', type => 1, cb_prefix_output => 'prefix_output',
          message_multiple => 'All licenses status are ok' },
    ];
    
    $self->{maps_counters}->{license} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'sysExtLicenseKey' }, { name => 'sysExtLicenseFlags' },
                    { name => 'sysExtLicenseService' }, { name => 'sysExtLicenseExpires' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub prefix_output {
    my ($self, %options) = @_;

    return "License '" . $options{instance_value}->{sysExtLicenseService} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "warning-status:s"  => { name => 'warning_status' },
        "critical-status:s" => { name => 'critical_status',
            default => '%{flag} !~ /enabled/i || (%{expires} ne "Never" && %{expires} < 86400)' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

my %map_flags = (
    'E' => 'enabled', 'A' => 'auto-generated', 'R' => 'reboot-required'
);

my $oid_wlsxSysExtSwitchLicenseTable = '.1.3.6.1.4.1.14823.2.2.1.2.1.20.1';

my $mapping = {
    sysExtLicenseKey => { oid => '.1.3.6.1.4.1.14823.2.2.1.2.1.20.1.2' },
    sysExtLicenseInstalled => { oid => '.1.3.6.1.4.1.14823.2.2.1.2.1.20.1.3' },
    sysExtLicenseExpires => { oid => '.1.3.6.1.4.1.14823.2.2.1.2.1.20.1.4' },
    sysExtLicenseFlags => { oid => '.1.3.6.1.4.1.14823.2.2.1.2.1.20.1.5', map => \%map_flags },
    sysExtLicenseService => { oid => '.1.3.6.1.4.1.14823.2.2.1.2.1.20.1.6' },
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_wlsxSysExtSwitchLicenseTable,
        start => $mapping->{sysExtLicenseKey}->{oid},
        end => $mapping->{sysExtLicenseService}->{oid},
        nothing_quit => 1
    );

    foreach my $oid (keys %{$snmp_result}) {
        $snmp_result->{$oid} = centreon::plugins::misc::trim($snmp_result->{$oid});
    }
    
    $self->{license} = {};
    
    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{sysExtLicenseKey}->{oid}\.(.*)/);
        my $instance = $1;
        
        my $result = $options{snmp}->map_instance(
            mapping => $mapping,
            results => $snmp_result,
            instance => $instance
        );

        $self->{license}->{$result->{sysExtLicenseService}} = { %{$result} };
    }
    
    if (scalar(keys %{$self->{license}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No license found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check license (WLSX-SYSTEMEXT-MIB).

=over 8

=item B<--warning-status>

Threshold warning.
Can use special variables like:%{key},
%{service}, %{flag}, %{expires} (Default: '')

=item B<--critical-status>

Threshold critical.
Can use special variables like: %{key},
%{service}, %{flag}, %{expires} (Default: '%{flag} !~ /enabled/i || (%{expires} ne "Never" && %{expires} < 86400)')

=back

=cut
