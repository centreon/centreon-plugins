#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package network::paloalto::api::mode::licenses;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::constants qw(:counters);
use centreon::plugins::misc qw(is_excluded);
use DateTime;
use DateTime::Format::Strptime;

sub custom_expiration_output {
    my ($self, %options) = @_;
    my $days = $self->{result_values}->{days_left};
    return 'never expire' if $days && $days == -1;
    return ($days // 0) . ' days left';
}

sub prefix_license_output {
    my ($self, %options) = @_;
    return sprintf("license '%s' ", $options{instance_value}->{feature});
}

sub prefix_global_output {
    my ($self, %options) = @_;
    return 'Licenses ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL, cb_prefix_output => 'prefix_global_output' },
        { name => 'licenses', type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_license_output', message_multiple => 'All licenses are ok' }
    ];

    $self->{maps_counters}->{global} = [
        {
            label  => 'licenses-count',
            nlabel => 'licenses.count',
            set => {
                key_values => [ { name => 'licenses_count' } ],
                output_template => 'count: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{licenses} = [
        {
            label => 'status',
            type  => COUNTER_KIND_TEXT,
            critical_default => '%{expired} =~ /yes/i',
            set => {
                key_values => [ { name => 'expired' }, { name => 'feature' } ],
                output_template => 'expired: %s',
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        {
            label  => 'expiration-days',
            nlabel => 'license.empiration.days',
            critical_default => '@0',
            set => {
                key_values      => [ { name => 'days_left' }, { name => 'feature' } ],
                closure_custom_output => $self->can('custom_expiration_output'),
                perfdatas => [
                    { template => '%s', unit => 'd', min => -1,
                      label_extra_instance => 1, instance_use => 'feature' }
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
        'include-license-name:s' => { name => 'include_license_name', default => '' },
        'exclude-license-name:s' => { name => 'exclude_license_name', default => '' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->request_api(
        type       => 'op',
        cmd        => '<request><license><info></info></license></request>',
        ForceArray => ['entry']
    );

    $self->{licenses} = {};
    $self->{global} = { licenses_count => 0 };

    my $parser = DateTime::Format::Strptime->new(
        pattern => '%B %d, %Y',
        on_error => 'undef'
    );

    return unless defined($result->{licenses});

    foreach my $entry (@{$result->{licenses}->{entry}}) {
        my $feature = $entry->{feature} // '';
        next if is_excluded($feature, $self->{option_results}->{include_license_name}, $self->{option_results}->{exclude_license_name});

        my $days_left = -1;
        my $expires = $entry->{expires};

        if (defined($expires) && $expires ne 'Never') {
            my $exp_date = $parser->parse_datetime($expires);
            if ($exp_date) {
                my $now = DateTime->now(time_zone => 'UTC');
                $days_left = int(($exp_date->epoch() - $now->epoch()) / 86400);
                $days_left = 0 if $days_left < 0;
            }
        }
        $self->{licenses}->{$feature} = {
            feature   => $feature,
            expired   => lc($entry->{expired}),
            days_left => $days_left
        };
        $self->{global}->{licenses_count}++;
    }
}

1;

__END__

=head1 MODE

Check Palo Alto licenses status and expiration.

=over 8

=item B<--include-license-name>

Include license names (regexp).

=item B<--exclude-license-name>

Exclude license names (regexp).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{expired}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{expired}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{expired} =~ /yes/i').
You can use the following variables: %{expired}

=item B<--warning-expiration-days>

Warning threshold in days before expiration.

=item B<--critical-expiration-days>

Critical threshold in days before expiration (default: '@0').

=item B<--warning-licenses-count>

Warning threshold for licenses count.

=item B<--critical-licenses-count>

Critical threshold for licenses count.

=back

=cut
