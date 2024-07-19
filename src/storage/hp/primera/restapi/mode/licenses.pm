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

package storage::hp::primera::restapi::mode::licenses;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_license_output {
    my ($self, %options) = @_;

    my $message;
    if (!defined($self->{result_values}->{expires_seconds})) {
        $message = $self->{result_values}->{name} . ' has permanent license';
    } elsif ($self->{result_values}->{expires_seconds} == 0) {
        $message = sprintf(
            "%s license has expired.",
            $self->{result_values}->{name}
        );
    } else {
        $message = sprintf(
            "%s license expires in %s.",
            $self->{result_values}->{name},
            centreon::plugins::misc::change_seconds(value => $self->{result_values}->{expires_seconds})
        );
    }

    return $message;
}

sub custom_license_perfdata {
    my ($self, %options) = @_;

    return if ($self->{result_values}->{expires_seconds} eq 'permanent');

    $self->{output}->perfdata_add(
        nlabel => $self->{result_values}->{name} . "#" . $self->{nlabel},
        unit => 's',
        instances => $self->{result_values}->{name},
        value => $self->{result_values}->{expires_seconds},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub custom_license_threshold {
    my ($self, %options) = @_;

    return 'ok' if (!defined($self->{result_values}->{expires_seconds}));
    return $self->{perfdata}->threshold_check(
        value => $self->{result_values}->{expires_seconds},
        threshold => [
            { label => 'critical-' . $self->{thlabel},   exit_litteral => 'critical' },
            { label => 'warning-' . $self->{thlabel},    exit_litteral => 'warning' }
        ]
    );
}

sub prefix_license_output {
    my ($self, %options) = @_;
    
    return "License '" . $options{instance_value}->{name} . "' expires: " . $options{instance_value}->{expiration_human} . ". ";
}
sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'license_expiration', type => 1, cb_prefix_output => 'prefix_license_output', message_multiple => 'All licenses are ok'} #, cb_prefix_output => 'prefix_license_output'
    ];

    $self->{maps_counters}->{global} = [
        {
            label => 'total',
            nlabel => 'licenses.total.count',
            set => {
                key_values => [ { name => 'total' } ],
                output_template => 'Number of licenses: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
            {
            label => 'expired',
            nlabel => 'licenses.expired.count',
            set => {
                key_values => [ { name => 'expired' }, { name => 'total' } ],
                output_template => 'Number of expired licenses: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        }
    ];
    $self->{maps_counters}->{license_expiration} = [
        { label => 'license-expiration', nlabel => 'license.expiration.seconds', set => {
                key_values => [ { name => 'name' }, { name => 'expires_seconds' }, { name => 'expiration_status' }, { name => 'expiration_human' }],
                closure_custom_output => $self->can('custom_license_output'),
                closure_custom_perfdata => $self->can('custom_license_perfdata'),
                closure_custom_threshold_check => $self->can('custom_license_threshold')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $response = $options{custom}->request_api(
        endpoint => '/api/v1/system'
    );
    my $licenses = $response->{licenseInfo}->{licenses};

    my ($total_licenses, $expired_licenses) = (0, 0);
    for my $license_item (@{$licenses}) {
        # skip if filter does not match
        next if (defined($self->{option_results}->{filter_name}) and $license_item->{name} !~ $self->{option_results}->{filter_name});

        $total_licenses = $total_licenses + 1;
        $self->{license_expiration}->{$license_item->{name}} = {
            name             => $license_item->{name},
            expiration_human => defined($license_item->{expiryTime8601}) ? $license_item->{expiryTime8601} : 'never'
        };

        my $license_status = 'valid';
        if (defined($license_item->{expiryTimeSec})) {
            if ($license_item->{expiryTimeSec} > time()) {
                $self->{license_expiration}->{$license_item->{name}}->{expires_seconds} = $license_item->{expiryTimeSec} - time();
            } else {
                $self->{license_expiration}->{$license_item->{name}}->{expires_seconds} = 0;
                $license_status = 'expired';
                $expired_licenses = $expired_licenses + 1;
            }
        }
        $self->{license_expiration}->{$license_item->{name}}->{expiration_status} = $license_status;
    }
    $self->{global} = {
        total   => $total_licenses,
        expired => $expired_licenses
    };

    if (scalar(keys %{$self->{license_expiration}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "Couldn't get information about licenses");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check storage capacities.

=over 8

=item B<--filter-name>

Filter licenses by name (regular expression).

=item B<--warning-*> B<--critical-*>

Thresholds for counters and license validity remaining time in seconds.
* may be replaced with:

'total': applies to the total number of licenses.
'expired': applies to the number of expired licenses.
'license-expiration': applies to the remaining time in seconds until the licenses will expire.

=back

=cut
