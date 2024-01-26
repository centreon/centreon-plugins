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

package cloud::microsoft::office365::management::mode::appcredentials;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::misc;
use POSIX;
use DateTime;

my $unitdiv = { s => 1, w => 604800, d => 86400, h => 3600, m => 60 };
my $unitdiv_long = { s => 'seconds', w => 'weeks', d => 'days', h => 'hours', m => 'minutes' };

sub custom_expires_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel} . '.' . $unitdiv_long->{ $self->{instance_mode}->{option_results}->{unit} },
        unit => $self->{instance_mode}->{option_results}->{unit},
        instances => [$self->{result_values}->{app_name}, $self->{result_values}->{id}],
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

sub application_long_output {
    my ($self, %options) = @_;

    return "checking application '" . $options{instance_value}->{name} . "'";
}

sub prefix_application_output {
    my ($self, %options) = @_;

    return "application '" . $options{instance_value}->{name} . "' ";
}

sub prefix_key_output {
    my ($self, %options) = @_;

    return "key credential '" . $options{instance} . "' ";
}

sub prefix_password_output {
    my ($self, %options) = @_;

    return "password credential '" . $options{instance} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'applications', type => 3, cb_prefix_output => 'prefix_application_output', cb_long_output => 'application_long_output', indent_long_output => '    ', message_multiple => 'All application credentials are ok',
            group => [
                { name => 'password', display_long => 1, cb_prefix_output => 'prefix_password_output',  message_multiple => 'All password credentials are ok', type => 1, skipped_code => { -10 => 1 } },
                { name => 'key', display_long => 1, cb_prefix_output => 'prefix_key_output',  message_multiple => 'All key credentials are ok', type => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{password} = [
        { label => 'password-status', type => 2, critical_default => '%{status} =~ /expired/i', set => {
                key_values => [ { name => 'status' }, { name => 'app_name' }, { name => 'id' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'password-expires', nlabel => 'application.password.expires', set => {
                key_values => [
                    { name => 'expires_seconds' }, { name => 'expires_human' },
                    { name => 'app_name' }, { name => 'id' }
                ],
                output_template => 'expires in %s',
                output_use => 'expires_human',
                closure_custom_perfdata => $self->can('custom_expires_perfdata'),
                closure_custom_threshold_check => $self->can('custom_expires_threshold')
            }
        }
    ];

    $self->{maps_counters}->{key} = [
        { label => 'key-status', type => 2, critical_default => '%{status} =~ /expired/i', set => {
                key_values => [ { name => 'status' }, { name => 'app_name' }, { name => 'id' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'key-expires', nlabel => 'application.key.expires', set => {
                key_values => [
                    { name => 'expires_seconds' }, { name => 'expires_human' },
                    { name => 'app_name' }, { name => 'id' }
                ],
                output_template => 'expires in %s',
                output_use => 'expires_human',
                closure_custom_perfdata => $self->can('custom_expires_perfdata'),
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
        'filter-app-name:s' => { name => 'filter_app_name' },
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

sub add_credential {
    my ($self, %options) = @_;

    # 2022-03-17T17:11:43.932Z
    return if (!defined($options{end}) || $options{end} !~ /^(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)/);

    my $dt = DateTime->new(
        year => $1,
        month => $2,
        day => $3,
        hour => $4,
        minute => $5,
        second => $6,
    );
    my $elapsed = $dt->epoch() - time();
    $elapsed = 0 if ($elapsed < 0);

    $self->{applications}->{ $options{app} }->{ $options{type} }->{ $options{id} } = {
        app_name => $self->{applications}->{ $options{app} }->{name},
        id => $options{id},
        status => $elapsed == 0 ? 'expired' : 'valid',
        expires_seconds => $elapsed,
        expires_human => centreon::plugins::misc::change_seconds(
            value => $elapsed
        )
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->get_applications();

    $self->{applications} = {};
    foreach my $app (@$results) {
        if (defined($self->{option_results}->{filter_app_name}) && $self->{option_results}->{filter_app_name} ne '' &&
            $app->{displayName} !~ /$self->{option_results}->{filter_app_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $app->{displayName} . "': no matching filter name.", debug => 1);
            next;
        }

        $self->{applications}->{ $app->{id} } = {
            name => $app->{displayName},
            key => {},
            password => {}
        };

        foreach (@{$app->{keyCredentials}}) {
            $self->add_credential(app => $app->{id}, type => 'key', id => $_->{keyId}, end => $_->{endDateTime});
        }
        foreach (@{$app->{passwordCredentials}}) {
            $self->add_credential(app => $app->{id}, type => 'password', id => $_->{keyId}, end => $_->{endDateTime});
        }
    }
}

1;

__END__

=head1 MODE

Check application credentials.

=over 8

=item B<--filter-app-name>

Filter applications (can be a regexp).

=item B<--warning-key-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{status}, %{id}, %{app_name}.

=item B<--critical-key-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} =~ /expired/i').
You can use the following variables: %{status}, %{id}, %{app_name}.

=item B<--warning-password-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{status}, %{id}, %{app_name}.

=item B<--critical-password-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} =~ /expired/i').
You can use the following variables: %{status}, %{id}, %{app_name}.

=item B<--unit>

Select the time unit for the expiration thresholds. May be 's' for seconds, 'm' for minutes, 'h' for hours, 'd' for days, 'w' for weeks. Default is secondss.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'key-expires', 'password-expires'.

=back

=cut
