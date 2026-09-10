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

package cloud::juniper::mist::restapi::mode::licenses;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters);
use POSIX qw(floor);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'licenses', type => COUNTER_TYPE_INSTANCE, prefix_output => "License '%{type}' ",
          message_multiple => 'All licenses are OK', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{licenses} = [
        {
            label => 'license-expiry',
            nlabel => 'mist.license.expiry.days',
            # '90:'/'30:' fire when fewer than 90/30 days remain; a negative
            # value (already expired) is below the range too, so it alerts.
            warning_default => '90:',
            critical_default => '30:',
            set => {
                key_values => [ { name => 'expiration' }, { name => 'type' } ],
                output_template => 'expires in %{expiration} days',
                perfdatas => [
                    { template => '%d', unit => 'd', label_extra_instance => 1, instance_use => 'type' }
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
        'filter-license-type:s' => { name => 'filter_license_type' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $org_id = $options{custom}->get_org_id();
    my $data = $options{custom}->request_api(endpoint => "/api/v1/orgs/$org_id/licenses");

    my $licenses = (ref($data) eq 'HASH' && ref($data->{licenses}) eq 'ARRAY') ? $data->{licenses} : [];
    $self->{output}->option_exit(short_msg => "No license found for this organization.")
        if (!@$licenses);

    # Keep the earliest expiry per subscription type: that is the one that will
    # bite first, and reporting every individual entitlement would be noise.
    my %closest;
    foreach my $license (@$licenses) {
        my $end = $license->{end_time} // 0;
        next if ($end <= 0);

        my $type = $license->{type} // $license->{subscription_id} // 'unknown';

        next if (defined($self->{option_results}->{filter_license_type}) && $self->{option_results}->{filter_license_type} ne ''
            && $type !~ /$self->{option_results}->{filter_license_type}/i);

        my $days = floor(($end - time()) / 86400);
        $closest{$type} = $days if (!exists($closest{$type}) || $days < $closest{$type});
    }

    $self->{output}->option_exit(short_msg => "No license with an expiry date found.")
        if (!%closest);

    $self->{licenses} = {};
    foreach my $type (keys %closest) {
        $self->{licenses}->{$type} = {
            type => $type,
            expiration => $closest{$type}
        };
    }
}

1;

__END__

=head1 MODE

Check the expiry of Juniper Mist organization licenses from the C</licenses>
endpoint. For each subscription type, only the earliest expiry is reported: it is
the one that will bite first.

=over 8

=item B<--filter-license-type>

Only check licenses whose type matches this regular expression.

=item B<--warning-license-expiry>

Warning threshold, in days, for license expiry (default: '90:', i.e. warn when
fewer than 90 days remain).

=item B<--critical-license-expiry>

Critical threshold, in days, for license expiry (default: '30:', including an
already expired license).

=back

=cut
