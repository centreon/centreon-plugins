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

package network::cisco::meraki::cloudcontroller::restapi::mode::apirequests;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'organizations', type => 1, cb_prefix_output => 'prefix_organization_output', message_multiple => 'All organizations are ok' }
    ];

    $self->{maps_counters}->{organizations} = [
        { label => 'api-requests-200', nlabel => 'organization.api.requests.200.count', set => {
                key_values => [ { name => 'requests_200' }, { name => 'display' } ],
                output_template => 'code 200: %s',
                perfdatas => [
                    { value => 'requests_200',
                      template => '%d', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'api-requests-404', nlabel => 'organization.api.requests.404.count', set => {
                key_values => [ { name => 'requests_404' }, { name => 'display' } ],
                output_template => 'code 404: %s',
                perfdatas => [
                    { value => 'requests_404',
                      template => '%d', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'api-requests-429', nlabel => 'organization.api.requests.429.count', set => {
                key_values => [ { name => 'requests_429' }, { name => 'display' } ],
                output_template => 'code 429: %s',
                perfdatas => [
                    { value => 'requests_429',
                      template => '%d', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];
}

sub prefix_organization_output {
    my ($self, %options) = @_;
    
    return "Organization '" . $options{instance_value}->{display} . "' requests ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-organization-name:s' => { name => 'filter_organization_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = 'meraki_' . $self->{mode} . '_' . $options{custom}->get_token()  . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_organization_name}) ? md5_hex($self->{option_results}->{filter_organization_name}) : md5_hex('all'));
    my $last_timestamp = $self->read_statefile_key(key => 'last_timestamp');
    my $timespan = 300;
    $timespan = time() - $last_timestamp if (defined($last_timestamp));

    my $cache_organizations = $options{custom}->get_cache_organizations();
    my $api_requests = $options{custom}->get_organization_api_requests_overview(timespan => $timespan, filter_name => $self->{option_results}->{filter_organization_name});

    $self->{organizations} = {};
    foreach my $id (keys %$api_requests) {
        $self->{organizations}->{$id} = {
            display => $cache_organizations->{$id}->{name},
            requests_200 => defined($api_requests->{$id}->{responseCodeCounts}->{200}) ? $api_requests->{$id}->{responseCodeCounts}->{200} : 0,
            requests_404 => defined($api_requests->{$id}->{responseCodeCounts}->{404}) ? $api_requests->{$id}->{responseCodeCounts}->{404} : 0,
            requests_429 => defined($api_requests->{$id}->{responseCodeCounts}->{429}) ? $api_requests->{$id}->{responseCodeCounts}->{429} : 0,
        };
    }

    if (scalar(keys %{$self->{organizations}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No organizations found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check api requests.

=over 8

=item B<--filter-organization-name>

Filter organization name (Can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'api-requests-200', 'api-requests-404', 'api-requests-429'.

=back

=cut
