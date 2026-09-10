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

package cloud::juniper::mist::restapi::mode::nacauthentications;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::misc qw(json_decode);

# The composite (dual-condition) threshold is the whole point of this mode. A
# ratio alone is not comparable across sites of very different sizes: one denied
# client on a site seeing 3 authentications an hour is 33% (noise), while 7% on a
# site handling 800 verdicts is ~60 real failures. The status therefore degrades
# only when the ratio AND the absolute number of denials AND a minimum sample
# size are all reached at once.
my $warning_composite  = '%{total} >= 10 && %{deny_prct} >= 30 && %{deny} >= 5';
my $critical_composite = '%{total} >= 10 && %{deny_prct} >= 50 && %{deny} >= 15';

sub skip_aggregate {
    my ($self, %options) = @_;

    # In per-site mode the per-site statuses drive the verdict, so the
    # organization-wide aggregate status must not be evaluated.
    return ($self->{option_results}->{per_site}) ? 1 : 0;
}

sub skip_sites {
    my ($self, %options) = @_;

    return ($self->{option_results}->{per_site}) ? 0 : 1;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL },
        { name => 'aggregate', type => COUNTER_TYPE_GLOBAL, cb_init => 'skip_aggregate' },
        { name => 'sites', type => COUNTER_TYPE_INSTANCE, prefix_output => "Site '%{site_name}' ",
          message_multiple => 'All sites NAC verdicts are OK', cb_init => 'skip_sites', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        {
            label => 'deny-count', nlabel => 'mist.nac.verdicts.deny.count',
            set => {
                key_values => [ { name => 'deny' } ],
                output_template => 'deny: %d',
                perfdatas => [ { template => '%d', min => 0 } ]
            }
        },
        {
            label => 'deny-prct', nlabel => 'mist.nac.verdicts.deny.percentage', display_ok => 0,
            set => {
                key_values => [ { name => 'deny_prct' } ],
                output_template => 'deny rate: %.2f%%',
                perfdatas => [ { template => '%.2f', unit => '%', min => 0, max => 100 } ]
            }
        },
        {
            label => 'verdicts-total', nlabel => 'mist.nac.verdicts.total.count',
            set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total: %d',
                perfdatas => [ { template => '%d', min => 0 } ]
            }
        },
        {
            label => 'verdicts-permit', nlabel => 'mist.nac.verdicts.permit.count', display_ok => 0, threshold => 0,
            set => {
                key_values => [ { name => 'permit' } ],
                output_template => 'permit: %d',
                perfdatas => [ { template => '%d', min => 0 } ]
            }
        },
        {
            label => 'cert-validation-failure', nlabel => 'mist.nac.server.certificate.validation.failure.count', threshold => 0,
            set => {
                key_values => [ { name => 'server_cert_failure' } ],
                output_template => 'server cert validation failures: %d',
                perfdatas => [ { template => '%d', min => 0 } ]
            }
        }
    ];

    $self->{maps_counters}->{aggregate} = [
        {
            label => 'status',
            type => COUNTER_KIND_TEXT,
            warning_default => $warning_composite,
            critical_default => $critical_composite,
            set => {
                key_values => [
                    { name => 'total' }, { name => 'deny_prct' }, { name => 'deny' },
                    { name => 'permit' }, { name => 'server_cert_failure' },
                    { name => 'site_name' }, { name => 'site_id' }
                ],
                output_template => '%{site_name}: deny rate %{deny_prct|%.2f}%% (%{deny} deny / %{total} verdicts)',
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{sites} = [
        {
            label => 'status',
            type => COUNTER_KIND_TEXT,
            warning_default => $warning_composite,
            critical_default => $critical_composite,
            set => {
                key_values => [
                    { name => 'total' }, { name => 'deny_prct' }, { name => 'deny' },
                    { name => 'permit' }, { name => 'server_cert_failure' },
                    { name => 'site_name' }, { name => 'site_id' }
                ],
                output_template => 'deny rate %{deny_prct|%.2f}%% (%{deny} deny / %{total} verdicts)',
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        {
            label => 'site-deny-count', nlabel => 'mist.nac.site.verdicts.deny.count', threshold => 0,
            set => {
                key_values => [ { name => 'deny' }, { name => 'site_name' } ],
                output_template => 'deny: %d',
                perfdatas => [ { template => '%d', min => 0, label_extra_instance => 1, instance_use => 'site_name' } ]
            }
        },
        {
            label => 'site-deny-prct', nlabel => 'mist.nac.site.verdicts.deny.percentage', threshold => 0,
            set => {
                key_values => [ { name => 'deny_prct' }, { name => 'site_name' } ],
                output_template => 'deny rate: %.2f%%',
                perfdatas => [ { template => '%.2f', unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'site_name' } ]
            }
        },
        {
            label => 'site-verdicts-total', nlabel => 'mist.nac.site.verdicts.total.count', threshold => 0,
            set => {
                key_values => [ { name => 'total' }, { name => 'site_name' } ],
                output_template => 'total: %d',
                perfdatas => [ { template => '%d', min => 0, label_extra_instance => 1, instance_use => 'site_name' } ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'timeframe:s'        => { name => 'timeframe', type => 'numeric', default => 3600 },
        'site-id:s'          => { name => 'site_id' },
        'per-site'           => { name => 'per_site' },
        'filter-site-name:s' => { name => 'filter_site_name' },
        'filter-ssid:s'      => { name => 'filter_ssid' }
    });

    return $self;
}

sub run {
    my ($self, %options) = @_;

    # Per-site perfdata instances are site names, which carry UTF-8 (e.g.
    # "S├úo Paulo"). centreon::plugins::misc::json_decode returns decoded
    # character strings, but output.pm applies an encoding layer only on its
    # JSON and XML paths - the plain-text/perfdata output path prints as-is, so
    # without an explicit layer these characters degrade to raw Latin-1 and the
    # perfdata instance labels are corrupted (and unstable across polls). We
    # therefore set the UTF-8 layer locally for the plain-text case only.
    # Guarded against the byte-producing output formats (JSON/XML/OpenMetrics),
    # which serialise through their own encoders and would be double-encoded.
    binmode(STDOUT, ':encoding(UTF-8)')
        if (!defined($self->{option_results}->{output_json})
            && !defined($self->{option_results}->{output_xml})
            && !defined($self->{option_results}->{output_openmetrics}));

    $self->SUPER::run(%options);
}

# Resolve site UUID -> human name. Fault-tolerant: on any error we fall back to
# the raw UUID, so a transient /sites failure never breaks the NAC check itself.
# We must use no_exit_on_error here: request_api's error path calls option_exit
# (which exits the process, not die), so an eval would not catch it.
sub get_site_names {
    my ($self, %options) = @_;

    my %names;
    my $response = $options{custom}->request_api(
        endpoint => "/api/v1/orgs/" . $options{org_id} . "/sites",
        no_exit_on_error => 1,
        unknown_status => '', warning_status => '', critical_status => ''
    );

    return \%names if (!defined($response->{code}) || $response->{code} < 200 || $response->{code} >= 300);

    my $sites = json_decode($response->{content}, silence => 1);
    if (ref($sites) eq 'ARRAY') {
        foreach my $site (@$sites) {
            $names{ $site->{id} } = $site->{name}
                if (defined($site->{id}) && defined($site->{name}));
        }
    }

    return \%names;
}

# The NAC search endpoint ignores the site_id query parameter (verified caveat,
# documented in custom/api.pm), so per-site figures are computed here from the
# site_id field carried by each event, and --site-id is enforced client-side.
sub manage_selection {
    my ($self, %options) = @_;

    my $org_id = $options{custom}->get_org_id();
    my $timeframe = $self->{option_results}->{timeframe};

    my ($events, $truncated) = $options{custom}->request_api_search(
        endpoint => "/api/v1/orgs/$org_id/nac_clients/events/search",
        get_param => [ 'duration=' . $timeframe . 's' ]
    );

    my $site_names = $self->get_site_names(custom => $options{custom}, org_id => $org_id);

    my %global = (permit => 0, deny => 0, total => 0, server_cert_failure => 0);
    my %per_site;

    foreach my $event (@$events) {
        my $type = $event->{type} // '';
        next if ($type ne 'NAC_CLIENT_PERMIT' && $type ne 'NAC_CLIENT_DENY' && $type ne 'NAC_SERVER_CERT_VALIDATION_FAILURE');

        my $site_id = $event->{site_id} // 'unknown';

        # --site-id: hard restriction, applied client-side (API ignores it).
        next if (defined($self->{option_results}->{site_id}) && $self->{option_results}->{site_id} ne ''
            && $site_id ne $self->{option_results}->{site_id});

        next if (defined($self->{option_results}->{filter_ssid}) && $self->{option_results}->{filter_ssid} ne ''
            && (!defined($event->{ssid}) || $event->{ssid} !~ /$self->{option_results}->{filter_ssid}/));

        my $site_name = $site_names->{$site_id} // $site_id;

        next if (defined($self->{option_results}->{filter_site_name}) && $self->{option_results}->{filter_site_name} ne ''
            && $site_name !~ /$self->{option_results}->{filter_site_name}/);

        $per_site{$site_id} //= {
            site_id => $site_id, site_name => $site_name,
            permit => 0, deny => 0, total => 0, server_cert_failure => 0
        };

        if ($type eq 'NAC_CLIENT_PERMIT') {
            $global{permit}++; $global{total}++;
            $per_site{$site_id}->{permit}++; $per_site{$site_id}->{total}++;
        } elsif ($type eq 'NAC_CLIENT_DENY') {
            $global{deny}++; $global{total}++;
            $per_site{$site_id}->{deny}++; $per_site{$site_id}->{total}++;
        } else {
            $global{server_cert_failure}++;
            $per_site{$site_id}->{server_cert_failure}++;
        }
    }

    my $deny_prct = $global{total} > 0 ? $global{deny} * 100 / $global{total} : 0;

    $self->{global} = {
        deny => $global{deny},
        deny_prct => $deny_prct,
        permit => $global{permit},
        total => $global{total},
        server_cert_failure => $global{server_cert_failure}
    };

    # Aggregate status scope: the single site when --site-id is set, otherwise
    # the whole organization.
    my $scope_name = 'organization';
    $scope_name = ($site_names->{ $self->{option_results}->{site_id} } // $self->{option_results}->{site_id})
        if (defined($self->{option_results}->{site_id}) && $self->{option_results}->{site_id} ne '');

    $self->{aggregate} = {
        total => $global{total}, deny_prct => $deny_prct, deny => $global{deny},
        permit => $global{permit}, server_cert_failure => $global{server_cert_failure},
        site_name => $scope_name, site_id => $self->{option_results}->{site_id} // 'org'
    };

    if ($self->{option_results}->{per_site}) {
        $self->{output}->option_exit(short_msg => "No NAC event found over the last ${timeframe}s.")
            if (!%per_site);

        $self->{sites} = {};
        foreach my $site_id (keys %per_site) {
            my $entry = $per_site{$site_id};
            $self->{sites}->{$site_id} = {
                site_id => $site_id,
                site_name => $entry->{site_name},
                deny => $entry->{deny},
                deny_prct => $entry->{total} > 0 ? $entry->{deny} * 100 / $entry->{total} : 0,
                permit => $entry->{permit},
                total => $entry->{total},
                server_cert_failure => $entry->{server_cert_failure}
            };
        }
    }

    $self->{output}->output_add(long_msg => 'Note: result truncated (--max-pages reached), counts are a lower bound.')
        if ($truncated);
}

1;

__END__

=head1 MODE

Check the Juniper Mist Access Assurance (NAC) 802.1X authentication verdicts
over a time window, from the C</nac_clients/events/search> endpoint.

The default status rule is a composite (dual-condition) threshold: the status
degrades only when the deny ratio, the absolute number of denials and a minimum
sample size are all reached at once. This avoids alerting on statistical noise
on low-traffic sites while still catching real outages on busy ones.

The Mist NAC search endpoint ignores the C<site_id> query parameter, so per-site
figures are computed client-side from each event's C<site_id>.

=over 8

=item B<--timeframe>

Time window in seconds to look back for NAC events (default: 3600).

=item B<--site-id>

Restrict the check to a single site UUID (enforced client-side).

=item B<--per-site>

Evaluate and report one set of verdicts per site in a single check, instead of a
single organization-wide aggregate.

=item B<--filter-site-name>

Only keep events whose (resolved) site name matches this regular expression.

=item B<--filter-ssid>

Only keep events whose SSID matches this regular expression.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (evaluated per scope
/ per site).
Default: '%{total} >= 10 && %{deny_prct} >= 30 && %{deny} >= 5'.
Variables: %{total}, %{deny}, %{deny_prct}, %{permit}, %{server_cert_failure},
%{site_name}, %{site_id}.

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (evaluated per
scope / per site).
Default: '%{total} >= 10 && %{deny_prct} >= 50 && %{deny} >= 15'.

=item B<--warning-deny-count> B<--critical-deny-count>

Threshold on the absolute number of denied verdicts (no default).

=item B<--warning-deny-prct> B<--critical-deny-prct>

Threshold on the deny ratio in percent (no default).

=item B<--warning-verdicts-total> B<--critical-verdicts-total>

Threshold on the total number of verdicts (no default).

=back

=cut
