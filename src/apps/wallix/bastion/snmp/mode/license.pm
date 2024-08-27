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

package apps::wallix::bastion::snmp::mode::license;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use JSON::XS;
use DateTime;
use POSIX;

my $unitdiv = { s => 1, w => 604800, d => 86400, h => 3600, m => 60 };
my $unitdiv_long = { s => 'seconds', w => 'weeks', d => 'days', h => 'hours', m => 'minutes' };

sub custom_expires_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel} . '.' . $unitdiv_long->{ $self->{instance_mode}->{option_results}->{unit} },
        unit => $self->{instance_mode}->{option_results}->{unit},
        value => floor($self->{result_values}->{expires_seconds} / $unitdiv->{ $self->{instance_mode}->{option_results}->{unit} }),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub custom_expires_threshold {
    my ($self, %options) = @_;

    return $self->{perfdata}->threshold_check(
        value => floor($self->{result_values}->{expires_seconds} / $unitdiv->{ $self->{instance_mode}->{option_results}->{unit} }),
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' },
            { label => 'unknown-'. $self->{thlabel}, exit_litteral => 'unknown' }
        ]
    );
}

sub custom_status_output {
    my ($self, %options) = @_;

    return 'status: ' . $self->{result_values}->{status};
}

sub custom_license_output {
    my ($self, %options) = @_;

    my $msg;
    if ($self->{result_values}->{total} != -1) {
        $msg = sprintf(
            'total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
            $self->{result_values}->{total},
            $self->{result_values}->{used},
            $self->{result_values}->{prct_used},
            $self->{result_values}->{free},
            $self->{result_values}->{prct_free}
        );
    } else {
        $msg = sprintf(
            'used: %s',
            $self->{result_values}->{used}
        );
    }

    return $msg;
}

sub custom_license_usage_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        instances => $self->{result_values}->{name},
        value => $self->{result_values}->{used},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0,
        max => $self->{result_values}->{total} != -1 ? $self->{result_values}->{total} : undef
    );
}

sub custom_license_calc {
    my ($self, %options) = @_;

    return -10 if ($options{new_datas}->{$self->{instance} . '_total'} == -1);
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_total'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_used'};
    $self->{result_values}->{free} = $options{new_datas}->{$self->{instance} . '_free'};
    $self->{result_values}->{prct_free} = $options{new_datas}->{$self->{instance} . '_prct_free'};
    $self->{result_values}->{prct_used} = $options{new_datas}->{$self->{instance} . '_prct_used'};
    return 0;
}

sub prefix_license_output {
    my ($self, %options) = @_;

    return sprintf(
        "License '%s' ",
        $options{instance_value}->{name},
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'License ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'licenses', type => 1, cb_prefix_output => 'prefix_license_output', message_multiple => 'All license usages are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'status', type => 2, critical_default => '%{status} eq "expired"', set => {
                key_values => [ { name => 'status' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'expires', nlabel => 'license.expires', set => {
                key_values      => [ { name => 'expires_seconds' }, { name => 'expires_human' } ],
                output_template => 'expires in %s',
                output_use => 'expires_human',
                closure_custom_perfdata => $self->can('custom_expires_perfdata'),
                closure_custom_threshold_check => $self->can('custom_expires_threshold')
            }
        }
    ];

    $self->{maps_counters}->{licenses} = [
        { label => 'license-usage', nlabel => 'license.usage.count', set => {
                key_values => [
                    { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' },
                    { name => 'total' }, { name => 'name' }
                ],
                closure_custom_output => $self->can('custom_license_output'),
                closure_custom_perfdata => $self->can('custom_license_usage_perfdata'),
            }
        },
        { label => 'license-free', display_ok => 0, nlabel => 'license.free.count', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_calc => $self->can('custom_license_calc'),
                closure_custom_output => $self->can('custom_license_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'license-usage-prct', display_ok => 0, nlabel => 'license.usage.percentage', set => {
                key_values => [ { name => 'prct_used' }, { name => 'used' }, { name => 'free' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_calc => $self->can('custom_license_calc'),
                closure_custom_output => $self->can('custom_license_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-category:s' => { name => 'filter_category' },
        'unit:s'            => { name => 'unit', default => 's' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if ($self->{option_results}->{unit} eq '' || !defined($unitdiv->{$self->{option_results}->{unit}})) {
        $self->{option_results}->{unit} = 's';
    }
}

sub add_license {
    my ($self, %options) = @_;

    return if (defined($self->{option_results}->{filter_category}) && $self->{option_results}->{filter_category} ne '' &&
        $options{name} !~ /$self->{option_results}->{filter_category}/);

    $self->{licenses}->{ $options{name} } = {
        name => $options{name},
        used => $options{used}
    };
    if (defined($options{max}) && $options{max} > 0) {
        $self->{licenses}->{ $options{name} }->{total} = $options{max};
        $self->{licenses}->{ $options{name} }->{free} = $options{max} - $options{used};
        $self->{licenses}->{ $options{name} }->{prct_used} = $options{used} * 100 / $options{max};
        $self->{licenses}->{ $options{name} }->{prct_free} = 100 - $self->{licenses}->{ $options{name} }->{prct_used};
    } else {
        $self->{licenses}->{ $options{name} }->{total} = -1;
        $self->{licenses}->{ $options{name} }->{free} = -1;
        $self->{licenses}->{ $options{name} }->{prct_used} = -1;
        $self->{licenses}->{ $options{name} }->{prct_free} = -1;
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_licenseInfo = '.1.3.6.1.4.1.30373.1.5.0';
    my $snmp_result = $options{snmp}->get_leef(
        oids => [ $oid_licenseInfo ],
        nothing_quit => 1
    );

    #{
    #   "resource_max": -1, 
    #   "primary": 7,
    #   "waapm": 0,
    #   "externvault_enabled": true,
    #   "secondary_max": -1,
    #   "siem_enabled": true,
    #   "secondary": 6,
    #   "evaluation": false, 
    #   "resource": 1063,
    #   "session_manager": true, 
    #   "expiration_date": "2021-12-31",
    #   "waapm_max": -1, 
    #   "primary_max": -1, 
    #   "password_manager": true, 
    #   "enterprise": false, 
    #   "is_expired": false
    #}

    my $decoded;
    eval {
        $snmp_result->{ $oid_licenseInfo } =~ s/\\//g;
        $decoded = JSON::XS->new->decode($snmp_result->{ $oid_licenseInfo });
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }

    $self->{global} = {
        status => $decoded->{is_expired} =~ /true|1/i ? 'expired' : 'ok'
    };
    if (defined($decoded->{expiration_date}) && $decoded->{expiration_date} =~ /^(\d+)-(\d+)-(\d+)$/) {
        my $dt = DateTime->new(
            year       => $1,
            month      => $2,
            day        => $3,
            hour       => 0,
            minute     => 0,
            second     => 0
        );
        my $expiration = $dt->epoch();

        $self->{global}->{expires_seconds} = $expiration - time();
        $self->{global}->{expires_human} = centreon::plugins::misc::change_seconds(
            value => $self->{global}->{expires_seconds}
        );
    }

    $self->{licenses} = {};
    $self->add_license(name => 'primary', used => $decoded->{primary}, max => $decoded->{primary_max});
    $self->add_license(name => 'secondary', used => $decoded->{secondary}, max => $decoded->{secondary_max});
    $self->add_license(name => 'resource', used => $decoded->{resource}, max => $decoded->{resource_max});
}

1;

__END__

=head1 MODE

Check license.

=over 8

=item B<--filter-category>

Filter licenses by category ('primary', 'secondary', 'resource').

=item B<--unit>

Select the time unit for the expired license thresholds. May be 's' for seconds, 'm' for minutes, 'h' for hours, 'd' for days, 'w' for weeks. Default is seconds.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{status}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} eq "expired"').
You can use the following variables: %{status}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total', 'expires', 'license-usage', 'license-free', 'license-usage-prct'.

=back

=cut
