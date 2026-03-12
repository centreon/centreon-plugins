#
# Copyright 2024 Centreon (http://www.centreon.com/)
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
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use Time::Local;

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = "status is '" . $self->{result_values}->{flag} . "'";
    if ($self->{result_values}->{expires_date} =~ /never/i) {
        $msg .= ', never expires';
    } elsif ($self->{result_values}->{expires_date} =~ /expired/i) {
        $msg .= ', expired';
    } else {
        $msg .= sprintf(
            "expires in %s [%s]",
            $self->{result_values}->{expires_human},
            $self->{result_values}->{expires_date}
        );
    }

    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{key} = $options{new_datas}->{$self->{instance} . '_sysExtLicenseKey'};
    $self->{result_values}->{flag} = $options{new_datas}->{$self->{instance} . '_sysExtLicenseFlags'};
    $self->{result_values}->{service} = $options{new_datas}->{$self->{instance} . '_sysExtLicenseService'};
    $self->{result_values}->{expires} = $options{new_datas}->{$self->{instance} . '_sysExtLicenseExpires'};
    $self->{result_values}->{expires_date} = $options{new_datas}->{$self->{instance} . '_sysExtLicenseExpires'};

    $self->{result_values}->{expires_human} = 'never';
    if ($self->{result_values}->{expires_date} =~ /Expired/) {
        $self->{result_values}->{expires_human} = 'expired';
        $self->{result_values}->{expires} = 0;
    }

    if ($self->{result_values}->{expires_date} !~ /Never|Expired/) {
        my ($year, $mon, $mday, $hour, $min, $sec) = split(/[\s\-:]+/, $self->{result_values}->{expires});
        $self->{result_values}->{expires} = timelocal($sec, $min, $hour, $mday, $mon - 1, $year) - time();
        $self->{result_values}->{expires_human} = centreon::plugins::misc::change_seconds(value => $self->{result_values}->{expires});
        $self->{result_values}->{expires_human} = $self->{result_values}->{expires} = 0 if ($self->{result_values}->{expires} < 0);
    }

    return 0;
}

sub prefix_output {
    my ($self, %options) = @_;

    return "License '" . $options{instance_value}->{sysExtLicenseService} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'license', type => 1, cb_prefix_output => 'prefix_output', message_multiple => 'All licenses status are ok' }
    ];
    
    $self->{maps_counters}->{license} = [
        { label => 'status', type => 2, critical_default => '%{flag} !~ /enabled/i || (%{expires} ne "Never" && %{expires} < 86400)', set => {
                key_values => [
                    { name => 'sysExtLicenseKey' }, { name => 'sysExtLicenseFlags' },
                    { name => 'sysExtLicenseService' }, { name => 'sysExtLicenseExpires' }
                ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

my %map_flags = (
    'E' => 'enabled', 'ES' => 'enabled', 'A' => 'auto-generated', 'R' => 'reboot-required'
);

my $oid_wlsxSysExtSwitchLicenseTable = '.1.3.6.1.4.1.14823.2.2.1.2.1.20.1';

my $mapping = {
    sysExtLicenseKey => { oid => '.1.3.6.1.4.1.14823.2.2.1.2.1.20.1.2' },
    sysExtLicenseInstalled => { oid => '.1.3.6.1.4.1.14823.2.2.1.2.1.20.1.3' },
    sysExtLicenseExpires => { oid => '.1.3.6.1.4.1.14823.2.2.1.2.1.20.1.4' },
    sysExtLicenseFlags => { oid => '.1.3.6.1.4.1.14823.2.2.1.2.1.20.1.5', map => \%map_flags },
    sysExtLicenseService => { oid => '.1.3.6.1.4.1.14823.2.2.1.2.1.20.1.6' }
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

Warning threshold.
Can use special variables like:%{key},
%{service}, %{flag}, %{expires} (default: '')

=item B<--critical-status>

Critical threshold.
Can use special variables like: %{key},
%{service}, %{flag}, %{expires} (default: '%{flag} !~ /enabled/i || (%{expires} ne "Never" && %{expires} < 86400)')

=back

=cut
