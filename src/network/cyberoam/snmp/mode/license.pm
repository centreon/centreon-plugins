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

package network::cyberoam::snmp::mode::license;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::misc;
use POSIX;
use Time::Local;
use DateTime::Format::Strptime;

my $unitdiv = { s => 1, w => 604800, d => 86400, h => 3600, m => 60 };
my $unitdiv_long = { s => 'seconds', w => 'weeks', d => 'days', h => 'hours', m => 'minutes' };

sub custom_expires_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel    => $self->{nlabel} . '.' . $unitdiv_long->{ $self->{instance_mode}->{option_results}->{unit} },
        unit      => $self->{instance_mode}->{option_results}->{unit},
        instances => $self->{result_values}->{name},
        value     => floor($self->{result_values}->{expires_seconds} / $unitdiv->{ $self->{instance_mode}->{option_results}->{unit} }),
        warning   => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical  => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min       => 0
    );
}

sub custom_expires_threshold {
    my ($self, %options) = @_;

    return $self->{perfdata}->threshold_check(
        value     =>
            floor($self->{result_values}->{expires_seconds} / $unitdiv->{ $self->{instance_mode}->{option_results}->{unit} }),
        threshold =>
            [
                { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
                { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' },
                { label => 'unknown-' . $self->{thlabel}, exit_litteral => 'unknown' }
            ]
    );
}

sub custom_status_output {
    my ($self, %options) = @_;

    return 'status: ' . $self->{result_values}->{status} . ', expires in ' . $self->{result_values}->{expires_human};
}

sub prefix_license_output {
    my ($self, %options) = @_;

    return sprintf(
        "License '%s' ",
        $options{instance_value}->{name}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name             => 'licenses',
            type             => 1,
            cb_prefix_output => 'prefix_license_output',
            message_multiple => 'All licenses are ok',
            skipped_code     => { -10 => 1 }
        }
    ];

    $self->{maps_counters}->{licenses} = [
        {
            label            => 'status',
            type             => 2,
            critical_default => '%{status} =~ /expired/i',
            set              => {
                key_values                     => [ { name => 'name' }, { name => 'status' }, { name => 'expires_human' } ],
                closure_custom_output          => $self->can('custom_status_output'),
                closure_custom_perfdata        => sub {return 0;},
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        {
            label  => 'expires',
            type => 1,
            nlabel => 'license.expires',
            set    => {
                key_values                     => [ { name => 'expires_seconds' }, { name => 'expires_human' }, { name => 'name' } ],
                output_template                => 'expires in %s',
                output_use                     => 'expires_human',
                closure_custom_perfdata        => $self->can('custom_expires_perfdata'),
                closure_custom_threshold_check => $self->can('custom_expires_threshold')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' },
        'unit:s'        => { name => 'unit', default => 's' }
    });

    return $self;
}

my %map_lic_status = (
    0 => 'none',
    1 => 'evaluating',
    2 => 'notsubscribed',
    3 => 'subscribed',
    4 => 'expired',
    5 => 'deactivated'
);

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if ($self->{option_results}->{unit} eq '' || !defined($unitdiv->{$self->{option_results}->{unit}})) {
        $self->{option_results}->{unit} = 's';
    }
}

sub add_license {
    my ($self, %options) = @_;

    return if (!defined($options{status}));
    return if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
        $options{name} !~ /$self->{option_results}->{filter_name}/);

    $self->{licenses}->{ $options{name} } = {
        name    => $options{name},
        status  => $options{status},
        expires => $options{expires}
    };

    if (defined($options{expires}) && $options{expires} ne "fail" && $options{status} =~ /subscribed|expired|evaluating/i) {
        my $strp = DateTime::Format::Strptime->new(
            pattern => '%b %d %Y',
            locale  => 'en_US',
        );

        my $dt = $strp->parse_datetime($options{expires});

        $self->{licenses}->{ $options{name} }->{expires_seconds} = $dt->epoch - time();
        $self->{licenses}->{ $options{name} }->{expires_seconds} = 0 if ($self->{licenses}->{ $options{name} }->{expires_seconds} < 0);
        $self->{licenses}->{ $options{name} }->{expires_human} = centreon::plugins::misc::change_seconds(
            value => $self->{licenses}->{ $options{name} }->{expires_seconds}
        );
    } else {
        $self->{licenses}->{ $options{name} }->{expires_human} = "n.d.";
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_base_fw_lic_status = '.1.3.6.1.4.1.2604.5.1.5.1.1.0';# sfosBaseFWLicRegStatus
    my $oid_base_fw_lic_expiry_date = '.1.3.6.1.4.1.2604.5.1.5.1.2.0';# sfosBaseFWLicExpiryDate
    my $oid_net_protection_lic_status = '.1.3.6.1.4.1.2604.5.1.5.2.1.0';# sfosNetProtectionLicRegStatus
    my $oid_net_protection_lic_expiry_date = '.1.3.6.1.4.1.2604.5.1.5.2.2.0';# sfosNetProtectionLicExpiryDate
    my $oid_web_protection_lic_status = '.1.3.6.1.4.1.2604.5.1.5.3.1.0';# sfosWebProtectionLicRegStatus
    my $oid_web_protection_lic_expiry_date = '.1.3.6.1.4.1.2604.5.1.5.3.2.0';# sfosWebProtectionLicExpiryDate
    my $oid_mail_protection_lic_status = '.1.3.6.1.4.1.2604.5.1.5.4.1.0';# sfosMailProtectionLicRegStatus
    my $oid_mail_protection_lic_expiry_date = '.1.3.6.1.4.1.2604.5.1.5.4.2.0';# sfosMailProtectionLicExpiryDate
    my $oid_web_server_protection_lic_status = '.1.3.6.1.4.1.2604.5.1.5.5.1';# sfosWebServerProtectionLicRegStatus
    my $oid_web_server_protection_lic_expiry_date = '.1.3.6.1.4.1.2604.5.1.5.5.2';# sfosWebServerProtectionLicExpiryDate
    my $oid_sand_storm_lic_status = '.1.3.6.1.4.1.2604.5.1.5.6.1';# sfosSandstromLicRegStatus
    my $oid_sand_storm_protection_lic_expiry_date = '.1.3.6.1.4.1.2604.5.1.5.6.2';# sfosSandstromLicExpiryDate
    my $oid_enhanced_support_lic_status = '.1.3.6.1.4.1.2604.5.1.5.7.1';# sfosEnhancedSupportLicRegStatus
    my $oid_enhanced_support_lic_expiry_date = '.1.3.6.1.4.1.2604.5.1.5.7.2';# sfosEnhancedSupportLicExpiryDate
    my $oid_enhanced_plus_lic_status = '.1.3.6.1.4.1.2604.5.1.5.8.1';# sfosEnhancedPlusLicRegStatus
    my $oid_enhanced_plus_lic_expiry_date = '.1.3.6.1.4.1.2604.5.1.5.8.2';# sfosEnhancedPlusLicExpiryDate
    my $oid_central_orchestra_lic_status = '.1.3.6.1.4.1.2604.5.1.5.9.1';# sfosCentralOrchestrationLicRegStatus
    my $oid_central_orchestra_lic_expiry_date = '.1.3.6.1.4.1.2604.5.1.5.9.2';# sfosCentralOrchestrationLicExpiryDate

    my $result = $options{snmp}->get_leef(
        oids         => [
            $oid_base_fw_lic_status,
            $oid_base_fw_lic_expiry_date,
            $oid_net_protection_lic_status,
            $oid_net_protection_lic_expiry_date,
            $oid_web_protection_lic_status,
            $oid_web_protection_lic_expiry_date,
            $oid_mail_protection_lic_status,
            $oid_mail_protection_lic_expiry_date,
            # $oid_web_server_protection_lic_status,
            # $oid_web_server_protection_lic_expiry_date,
            # $oid_sand_storm_lic_status,
            # $oid_sand_storm_protection_lic_expiry_date,
            # $oid_enhanced_support_lic_status,
            # $oid_enhanced_support_lic_expiry_date,
            # $oid_enhanced_plus_lic_status,
            # $oid_mail_protection_lic_status,
            # $oid_enhanced_plus_lic_expiry_date,
            # $oid_central_orchestra_lic_status,
            # $oid_central_orchestra_lic_expiry_date
        ],
        nothing_quit => 1
    );

    $self->{licenses} = {};
    $self->add_license(
        name    => 'base_fw',
        status  => $map_lic_status{$result->{$oid_base_fw_lic_status}},
        expires => $result->{$oid_base_fw_lic_expiry_date}
    );
    $self->add_license(
        name    => 'net_protection',
        status  => $map_lic_status{$result->{$oid_net_protection_lic_status}},
        expires => $result->{$oid_net_protection_lic_expiry_date}
    );
    $self->add_license(
        name    => 'web_protection',
        status  => $map_lic_status{$result->{$oid_web_protection_lic_status}},
        expires => $result->{$oid_web_protection_lic_expiry_date}
    );
    $self->add_license(
        name    => 'mail_protection',
        status  => $map_lic_status{$result->{$oid_mail_protection_lic_status}},
        expires => $result->{$oid_mail_protection_lic_expiry_date}
    );
}

1;

__END__

=head1 MODE

Check license (SFOS-FIREWALL-MIB).

=over 8

=item B<--filter-name>

Filter licenses by name (can be a regexp).

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{name}, %{status}.

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} =~ /expired/i').
You can use the following variables: %{name}, %{status}.

=item B<--unit>

Select the time unit for the expiration thresholds. May be 's' for seconds, 'm' for minutes, 'h' for hours, 'd' for days, 'w' for weeks. Default is seconds.

=item B<--warning-expires>

Threshold.
Example: C<--unit=w --warning-expires=2:> will result in a WARNING state when one of the licenses expires in less than
two weeks.

=item B<--critical-expires>

Threshold.
Example: C<--unit=w --critical-expires=2:> will result in a CRITICAL state when one of the licenses expires in less than
two weeks.

=back

=cut
