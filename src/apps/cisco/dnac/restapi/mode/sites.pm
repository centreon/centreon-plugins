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

package apps::cisco::dnac::restapi::mode::sites;

use centreon::plugins::constants qw/:counters :values/;
use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;

sub custom_health_output {
    my ($self, %options) = @_;

    return sprintf(
        'healthy %.2f%% (%s on %s)',
        $self->{result_values}->{prct},
        $self->{result_values}->{count},
        $self->{result_values}->{total}
    );
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'sites', type => COUNTER_TYPE_MULTIPLE, prefix_output => "Site '%{name}' ", long_output => "cheking site '%{name}' ", indent_long_output => '    ', message_multiple => 'All sites are ok',
            group => [
                { name => 'devices', type => COUNTER_MULTIPLE_INSTANCE, prefix_output => 'devices: ', skipped_code => { NO_VALUE() => 1 } },
                { name => 'clients', type => COUNTER_MULTIPLE_INSTANCE, prefix_output => 'clients: ', skipped_code => { NO_VALUE() => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{devices} = [
        { label => 'site-devices-healthy-usage', nlabel => 'site.network.devices.healthy.count', set => {
                key_values => [ { name => 'count' }, { name => 'prct' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_health_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total',  label_extra_instance => 1 }
                ]
            }
        },
        { label => 'site-devices-healthy-usage-prct', nlabel => 'site.network.devices.healthy.percentage', display_ok => 0, set => {
                key_values => [ { name => 'count' }, { name => 'prct' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_health_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{clients} = [
        { label => 'site-clients-healthy-usage', nlabel => 'site.clients.healthy.count', set => {
                key_values => [ { name => 'count' }, { name => 'prct' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_health_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total',  label_extra_instance => 1 }
                ]
            }
        },
        { label => 'site-clients-healthy-usage-prct', nlabel => 'site.clients.healthy.percentage', display_ok => 0, set => {
                key_values => [ { name => 'count' }, { name => 'prct' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_health_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, label_extra_instance => 1 }
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
        'filter-site-name:s' => { name => 'filter_site_name' },
        'use-site-fullname'  => { name => 'use_site_fullname' }
    });
    
    return $self;
}

sub get_fullname {
    my ($self, %options) = @_;

    return $options{name} if (!defined($options{parent_id}));
    my $name = $options{name};
    foreach (@{$options{response}}) {
        if ($_->{siteId} eq $options{parent_id}) {
            $name = $self->get_fullname(
                response => $options{response},
                name => centreon::plugins::misc::trim($_->{siteName}) . '>' . $name,
                parent_id => $_->{parentSiteId}
            );
            last;
        }
    }

    return $name;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $sites = $options{custom}->request_api(
        endpoint => '/site-health'
    );

    $self->{categories} = {};
    foreach (@{$sites->{response}}) {
        my $site_fullname = $self->get_fullname(
            response => $sites->{response},
            name => centreon::plugins::misc::trim($_->{siteName}),
            parent_id => $_->{parentSiteId}
        );
        my $site_name = defined($self->{option_results}->{use_site_fullname}) ? $site_fullname : centreon::plugins::misc::trim($_->{siteName});
        if (defined($self->{option_results}->{filter_site_name}) && $self->{option_results}->{filter_site_name} ne '' &&
            $site_name !~ /$self->{option_results}->{filter_site_name}/) {
            $self->{output}->output_add(long_msg => "skipping site '" . $site_name . "': no matching filter.", debug => 1);
            next;
        }

        $self->{sites}->{ $site_name } = {
            name => $site_name,
            devices => {
                name => $site_name,
                total => $_->{numberOfNetworkDevice},
                count => int($_->{numberOfNetworkDevice} * $_->{healthyNetworkDevicePercentage} / 100),
                prct => $_->{healthyNetworkDevicePercentage}
            },
            clients => {
                name => $site_name,
                total => $_->{numberOfClients},
                count => int($_->{numberOfClients} * $_->{healthyClientsPercentage} / 100),
                prct => $_->{healthyClientsPercentage}
            }
        };
    }
}

1;

__END__

=head1 MODE

Check sites.

=over 8

=item B<--filter-site-name>

Filter sites by name (can be a regexp).

=item B<--use-site-full-name>

Use site full name (with parents name).

=item B<--warning-site-clients-healthy-usage>

Threshold.

=item B<--critical-site-clients-healthy-usage>

Threshold.

=item B<--warning-site-clients-healthy-usage-prct>

Threshold.

=item B<--critical-site-clients-healthy-usage-prct>

Threshold.

=item B<--warning-site-devices-healthy-usage>

Threshold.

=item B<--critical-site-devices-healthy-usage>

Threshold.

=item B<--warning-site-devices-healthy-usage-prct>

Threshold.

=item B<--critical-site-devices-healthy-usage-prct>

Threshold.

=back

=cut
