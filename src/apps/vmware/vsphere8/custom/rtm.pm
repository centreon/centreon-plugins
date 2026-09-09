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

package apps::vmware::vsphere8::custom::rtm;

# Performance counters source based on the VCF Operations Real-Time Metrics API,
# the official replacement Broadcom offers for the vStats API removed in vSphere 9.1.
#
# Unlike vStats and vim25, this API is NOT served by vCenter: it belongs to VCF
# Operations, needs its Real-Time Metrics component to be deployed, and authenticates
# with a JWT bearer token rather than a vCenter session. It therefore takes its own
# hostname and credentials, and is never selected automatically.
#
# Authentication is a three-step sequence documented by Broadcom:
#   POST /suite-api/api/auth/token/acquire      -> OpsToken
#   GET  /suite-api/api/integrations/services   -> service key of the VCF_VODAP entry
#   POST /suite-api/api/auth/token/exchange     -> JWT bearer token
#
# Metrics are then read with the Prometheus-compatible endpoints:
#   GET <base path>/v1/query        (instant PromQL query)
#   GET <base path>/v1/metadata     (metric catalogue)

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use Digest::SHA qw(sha256_hex);
use centreon::plugins::misc qw/json_encode json_decode is_empty/;

# Object type each resource id prefix maps to, as named in the metric labels.
my %entity_types = (
    'HOST' => 'HostSystem',
    'VM'   => 'VirtualMachine'
);

# Labels that may carry the managed object id of the resource, by order of preference.
# The label actually in use is discovered at runtime and can be pinned with
# --rtm-moid-label; this list only bootstraps the discovery.
my @moid_label_candidates = qw(moid entity_id resource_id object_id vm host id);

# Unit conversion, identical in spirit to the vim25 source: every unit is a factor
# towards the base unit of its dimension, so a conversion is only allowed inside one
# dimension and can never silently turn bytes into hertz.
my %units = (
    'hertz'              => [ 'frequency', 1 ],
    'kilohertz'          => [ 'frequency', 1e3 ],
    'megahertz'          => [ 'frequency', 1e6 ],
    'bytes'              => [ 'bytes',     1 ],
    'kilobytes'          => [ 'bytes',     1024 ],
    'megabytes'          => [ 'bytes',     1024 ** 2 ],
    'gigabytes'          => [ 'bytes',     1024 ** 3 ],
    'bytespersecond'     => [ 'rate',      1 ],
    'kilobytespersecond' => [ 'rate',      1024 ],
    'percent'            => [ 'percent',   1 ],
    'ratio'              => [ 'percent',   100 ],
    'number'             => [ 'number',    1 ],
    'watts'              => [ 'power',     1 ],
    'joules'             => [ 'energy',    1 ],
    'seconds'            => [ 'time',      1 ],
    'milliseconds'       => [ 'time',      1e-3 ],
    'microseconds'       => [ 'time',      1e-6 ],
    # canonical target units, expressing what the modes expect
    'Hz'   => [ 'frequency', 1 ],
    'kHz'  => [ 'frequency', 1e3 ],
    'MHz'  => [ 'frequency', 1e6 ],
    'B'    => [ 'bytes',     1 ],
    'KB'   => [ 'bytes',     1024 ],
    'MB'   => [ 'bytes',     1024 ** 2 ],
    'Bps'  => [ 'rate',      1 ],
    'KBps' => [ 'rate',      1024 ],
    'pct'  => [ 'percent',   1 ],
    'count'=> [ 'number',    1 ],
    'W'    => [ 'power',     1 ],
    'ms'   => [ 'time',      1e-3 ]
);

# Each vStats counter id is mapped to the PromQL metric it is read from, the unit that
# metric is published in, and the unit the modes expect. The target units are derived
# from the arithmetic the modes apply to the value, exactly as in the vim25 source.
#
# The metric names below follow the VCF Operations naming of the vCenter adapter. They
# are ALWAYS validated against the /v1/metadata catalogue of the appliance before use,
# and an unknown name raises an explicit error instead of returning nothing. Any name
# can be overridden without touching this table, with --rtm-metric-map.
my %counter_map = (
    'cpu.capacity.provisioned.HOST'   => { metric => 'vcenter_host_cpu_capacity_provisioned_megahertz', unit => 'megahertz', target => 'kHz' },
    'cpu.capacity.usage.HOST'         => { metric => 'vcenter_host_cpu_capacity_usage_megahertz',       unit => 'megahertz', target => 'kHz' },
    'cpu.capacity.demand.HOST'        => { metric => 'vcenter_host_cpu_capacity_demand_megahertz',      unit => 'megahertz', target => 'kHz' },
    'cpu.capacity.contention.HOST'    => { metric => 'vcenter_host_cpu_capacity_contention_percent',    unit => 'percent',   target => 'pct' },
    'cpu.corecount.provisioned.HOST'  => { metric => 'vcenter_host_cpu_corecount_provisioned',          unit => 'number',    target => 'count' },
    'cpu.corecount.usage.HOST'        => { metric => 'vcenter_host_cpu_corecount_usage',                unit => 'number',    target => 'count' },
    'cpu.corecount.contention.HOST'   => { metric => 'vcenter_host_cpu_corecount_contention_percent',   unit => 'percent',   target => 'pct' },
    'mem.capacity.provisioned.HOST'   => { metric => 'vcenter_host_mem_capacity_provisioned_kilobytes', unit => 'kilobytes', target => 'MB' },
    'mem.capacity.usable.HOST'        => { metric => 'vcenter_host_mem_capacity_usable_kilobytes',      unit => 'kilobytes', target => 'MB' },
    'mem.capacity.usage.HOST'         => { metric => 'vcenter_host_mem_capacity_usage_kilobytes',       unit => 'kilobytes', target => 'MB' },
    'mem.capacity.contention.HOST'    => { metric => 'vcenter_host_mem_capacity_contention_percent',    unit => 'percent',   target => 'pct' },
    'mem.consumed.vms.HOST'           => { metric => 'vcenter_host_mem_consumed_vms_kilobytes',         unit => 'kilobytes', target => 'MB' },
    'mem.consumed.userworlds.HOST'    => { metric => 'vcenter_host_mem_consumed_userworlds_kilobytes',  unit => 'kilobytes', target => 'MB' },
    'mem.reservedCapacityPct.HOST'    => { metric => 'vcenter_host_mem_reserved_capacity_percent',      unit => 'percent',   target => 'pct' },
    'mem.swap.current.HOST'           => { metric => 'vcenter_host_mem_swap_current_kilobytes',         unit => 'kilobytes', target => 'KB' },
    'mem.swap.target.HOST'            => { metric => 'vcenter_host_mem_swap_target_kilobytes',          unit => 'kilobytes', target => 'KB' },
    'mem.swap.readrate.HOST'          => { metric => 'vcenter_host_mem_swap_readrate_kilobytespersecond',  unit => 'kilobytespersecond', target => 'KBps' },
    'mem.swap.writerate.HOST'         => { metric => 'vcenter_host_mem_swap_writerate_kilobytespersecond', unit => 'kilobytespersecond', target => 'KBps' },
    'disk.throughput.usage.HOST'      => { metric => 'vcenter_host_disk_throughput_usage_kilobytespersecond', unit => 'kilobytespersecond', target => 'KBps' },
    'disk.throughput.contention.HOST' => { metric => 'vcenter_host_disk_throughput_contention_milliseconds',  unit => 'milliseconds',       target => 'ms' },
    'net.throughput.usage.HOST'       => { metric => 'vcenter_host_net_throughput_usage_kilobytespersecond',       unit => 'kilobytespersecond', target => 'KBps' },
    'net.throughput.usable.HOST'      => { metric => 'vcenter_host_net_throughput_usable_kilobytespersecond',      unit => 'kilobytespersecond', target => 'KBps' },
    'net.throughput.provisioned.HOST' => { metric => 'vcenter_host_net_throughput_provisioned_kilobytespersecond', unit => 'kilobytespersecond', target => 'KBps' },
    'net.throughput.contention.HOST'  => { metric => 'vcenter_host_net_throughput_contention',          unit => 'number',    target => 'count' },
    'power.capacity.usage.HOST'       => { metric => 'vcenter_host_power_capacity_usage_watts',         unit => 'watts',     target => 'W' },
    'cpu.capacity.provisioned.VM'     => { metric => 'vcenter_vm_cpu_capacity_provisioned_megahertz',   unit => 'megahertz', target => 'MHz' },
    'cpu.capacity.entitlement.VM'     => { metric => 'vcenter_vm_cpu_capacity_entitlement_megahertz',   unit => 'megahertz', target => 'MHz' },
    'cpu.capacity.usage.VM'           => { metric => 'vcenter_vm_cpu_capacity_usage_megahertz',         unit => 'megahertz', target => 'MHz' },
    'mem.capacity.entitlement.VM'     => { metric => 'vcenter_vm_mem_capacity_entitlement_kilobytes',   unit => 'kilobytes', target => 'MB' },
    'mem.capacity.usage.VM'           => { metric => 'vcenter_vm_mem_capacity_usage_kilobytes',         unit => 'kilobytes', target => 'MB' },
    'disk.throughput.usage.VM'        => { metric => 'vcenter_vm_disk_throughput_usage_kilobytespersecond',       unit => 'kilobytespersecond', target => 'KBps' },
    'disk.throughput.contention.VM'   => { metric => 'vcenter_vm_disk_throughput_contention_milliseconds',        unit => 'milliseconds',       target => 'ms' },
    'net.throughput.usage.VM'         => { metric => 'vcenter_vm_net_throughput_usage_kilobytespersecond',        unit => 'kilobytespersecond', target => 'KBps' },
    'net.throughput.contention.VM'    => { metric => 'vcenter_vm_net_throughput_contention',            unit => 'number',    target => 'count' },
    'power.capacity.usage.VM'         => { metric => 'vcenter_vm_power_capacity_usage_watts',           unit => 'watts',     target => 'W' }
);

sub new {
    my ($class, %options) = @_;
    my $self = bless {}, $class;

    $self->{output} = $options{output};
    $self->{http}   = centreon::plugins::http->new(%options);
    $self->{cache}  = $options{cache};

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub check_options {
    my ($self, %options) = @_;

    my $results = $self->{option_results};

    $self->{hostname}   = $results->{rtm_hostname};
    $self->{port}       = $results->{rtm_port}      // 443;
    $self->{proto}      = $results->{rtm_proto}     // 'https';
    $self->{base_path}  = $results->{rtm_base_path} // '/data-query-service';
    $self->{username}   = $results->{rtm_username};
    $self->{password}   = $results->{rtm_password};
    $self->{auth_source}= $results->{rtm_auth_source};
    $self->{moid_label} = $results->{rtm_moid_label};
    $self->{timeout}    = $results->{timeout} // 10;

    for my $option (qw/rtm-hostname rtm-username rtm-password/) {
        (my $key = $option) =~ tr/-/_/;
        next if (!is_empty($results->{$key}));
        $self->{output}->option_exit(short_msg => "The Real-Time Metrics source needs the --"
            . $option . " option. It queries VCF Operations, not the vCenter, so it takes "
            . "its own address and credentials.");
    }

    # --rtm-metric-map cid=metric_name overrides an entry of the built-in mapping
    $self->{metric_overrides} = {};
    for my $override (@{ $results->{rtm_metric_map} // [] }) {
        if ($override !~ /^([^=]+)=(.+)$/) {
            $self->{output}->option_exit(short_msg => "Malformed --rtm-metric-map value '" . $override
                . "'. Expected the 'counter.id=metric_name' format.");
        }
        $self->{metric_overrides}->{$1} = $2;
    }

    $self->{base_path} =~ s/\/$//;

    return 0;
}

sub settings {
    my ($self, %options) = @_;

    return 1 if (defined($self->{settings_done}));

    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{port}     = $self->{port};
    $self->{option_results}->{proto}    = $self->{proto};
    $self->{option_results}->{timeout}  = $self->{timeout};
    # error payloads carry the reason and must be read rather than turned into UNKNOWN
    $self->{option_results}->{unknown_status}  = '';
    $self->{option_results}->{warning_status}  = '';
    $self->{option_results}->{critical_status} = '';

    $self->{http}->set_options(%{$self->{option_results}});
    $self->{settings_done} = 1;

    return 1;
}

sub request {
    my ($self, %options) = @_;

    $self->settings();

    my $headers = [ 'Accept: application/json' ];
    push @$headers, 'Content-Type: application/json' if (defined($options{post_body}));
    push @$headers, @{ $options{header} // [] };

    my $content = $self->{http}->request(
        method          => $options{method} // 'GET',
        url_path        => $options{url_path},
        get_param       => $options{get_param},
        query_form_post => $options{post_body},
        header          => $headers,
        insecure        => (defined($self->{option_results}->{insecure}) ? 1 : 0)
    );

    my $code = $self->{http}->get_code();
    if (!defined($content) || $content eq '') {
        $self->{output}->option_exit(short_msg => "Real-Time Metrics API returned an empty body for '"
            . $options{url_path} . "' [http code: '" . $code . "'].");
    }

    my $decoded = json_decode($content);
    if (!defined($decoded)) {
        $self->{output}->option_exit(short_msg => "Real-Time Metrics API returned a non-JSON body for '"
            . $options{url_path} . "' [http code: '" . $code . "'].");
    }

    return ($decoded, $code);
}

# Three-step JWT acquisition. The resulting token is cached: replaying the whole
# sequence on every check would triple the calls against VCF Operations.
sub get_token {
    my ($self, %options) = @_;

    return $self->{token} if (defined($self->{token}));

    my $statefile = 'vsphere8_rtm_token_' . sha256_hex($self->{hostname} . ':' . $self->{port} . '_' . $self->{username});
    if (!$options{force_authentication} && defined($self->{cache}) && $self->{cache}->read(statefile => $statefile)) {
        my $token   = $self->{cache}->get(name => 'token');
        my $expires = $self->{cache}->get(name => 'expires');
        if (!is_empty($token) && defined($expires) && $expires > time()) {
            $self->{token} = $token;
            return $self->{token};
        }
    }

    # 1. acquire an OpsToken from the VCF Operations credentials
    my $credentials = { username => $self->{username}, password => $self->{password} };
    $credentials->{authSource} = $self->{auth_source} if (!is_empty($self->{auth_source}));

    my ($acquired) = $self->request(
        method    => 'POST',
        url_path  => '/suite-api/api/auth/token/acquire',
        post_body => json_encode($credentials)
    );
    if (is_empty($acquired->{token})) {
        $self->{output}->option_exit(short_msg => "Could not acquire a VCF Operations token on '"
            . $self->{hostname} . "'. Check --rtm-username, --rtm-password and --rtm-auth-source.");
    }

    # 2. find the service key of the Real-Time Metrics service (VCF_VODAP)
    my ($services) = $self->request(
        url_path => '/suite-api/api/integrations/services',
        header   => [ 'Authorization: OpsToken ' . $acquired->{token} ]
    );

    my @service_list = @{ $services->{services} // $services->{service} // [] };
    my ($rtm_service) = grep { ($_->{type} // '') eq 'VCF_VODAP' } @service_list;
    if (!defined($rtm_service) || is_empty($rtm_service->{serviceKey})) {
        $self->{output}->option_exit(short_msg => "No 'VCF_VODAP' service is registered on '"
            . $self->{hostname} . "' (found: " . (join(', ', map { $_->{type} // '?' } @service_list) || 'none')
            . "). The Real-Time Metrics component is most likely not deployed: install it from "
            . "Build > Lifecycle > VCF Management > Add Component.");
    }

    # 3. exchange the service key for the JWT bearer token
    my ($exchanged) = $self->request(
        method    => 'POST',
        url_path  => '/suite-api/api/auth/token/exchange',
        post_body => json_encode([ $rtm_service->{serviceKey} ]),
        header    => [ 'Authorization: OpsToken ' . $acquired->{token} ]
    );

    my $jwt = $exchanged->{token} // $exchanged->{accessToken};
    if (is_empty($jwt)) {
        $self->{output}->option_exit(short_msg => "Could not exchange the 'VCF_VODAP' service key for a "
            . "JWT token on '" . $self->{hostname} . "'.");
    }

    $self->{token} = $jwt;
    # the announced validity is honoured when present, with a safety margin
    my $validity = $exchanged->{expiresIn} // $exchanged->{validity} // 3600;
    $self->{cache}->write(data => { updated => time(), token => $jwt, expires => time() + $validity - 60 })
        if (defined($self->{cache}));

    return $self->{token};
}

sub query_api {
    my ($self, %options) = @_;

    my ($response, $code) = $self->request(
        %options,
        url_path => $self->{base_path} . $options{endpoint},
        header   => [ 'Authorization: Bearer ' . $self->get_token() ]
    );

    # the token may have expired between two checks: authenticate again once
    if ($code == 401 || $code == 403) {
        delete $self->{token};
        ($response, $code) = $self->request(
            %options,
            url_path => $self->{base_path} . $options{endpoint},
            header   => [ 'Authorization: Bearer ' . $self->get_token(force_authentication => 1) ]
        );
    }

    if (($response->{status} // '') eq 'error') {
        $self->{output}->option_exit(short_msg => "Real-Time Metrics API error on '" . $options{endpoint}
            . "': " . ($response->{errorType} // 'unknown') . " - " . ($response->{error} // 'no detail'));
    }

    return $response;
}

# Metric catalogue advertised by the appliance, cached for the lifetime of the run.
sub metric_catalogue {
    my ($self, %options) = @_;

    return $self->{catalogue} if (defined($self->{catalogue}));

    my $response = $self->query_api(endpoint => '/v1/metadata');
    my $data     = $response->{data} // {};

    # the Prometheus metadata payload is keyed by metric name
    $self->{catalogue} = { map { $_ => 1 } keys %$data };

    if (!keys %{$self->{catalogue}}) {
        $self->{output}->option_exit(short_msg => "The Real-Time Metrics API of '" . $self->{hostname}
            . "' advertises no metric. The collection profile is most likely not enabled: activate "
            . "'Standard' and/or 'ESXi Top' for the vCenter object types in "
            . "Operate > Administration > Configurations > Policy Definition.");
    }

    return $self->{catalogue};
}

sub resolve_metric {
    my ($self, %options) = @_;

    my $mapping = $counter_map{ $options{cid} };
    if (!defined($mapping)) {
        $self->{output}->option_exit(short_msg => "Counter '" . $options{cid} . "' has no Real-Time Metrics "
            . "equivalent declared. Use --rtm-metric-map '" . $options{cid} . "=<metric_name>' to map it.");
    }

    # a copy, so an override never mutates the package-level table
    my %resolved = %$mapping;
    $resolved{metric} = $self->{metric_overrides}->{ $options{cid} }
        if (defined($self->{metric_overrides}->{ $options{cid} }));

    my $catalogue = $self->metric_catalogue();
    if (!defined($catalogue->{ $resolved{metric} })) {
        $self->{output}->option_exit(short_msg => "Metric '" . $resolved{metric} . "' (counter '" . $options{cid}
            . "') is not advertised by the Real-Time Metrics API of '" . $self->{hostname} . "'. "
            . "Check the enabled collection profile, or map the counter explicitly with "
            . "--rtm-metric-map '" . $options{cid} . "=<metric_name>'.");
    }

    return \%resolved;
}

# Discovers which label carries the managed object id, by looking at the labels of the
# series the appliance actually returns. Pinned with --rtm-moid-label when needed.
sub resolve_moid_label {
    my ($self, %options) = @_;

    return $self->{moid_label} if (!is_empty($self->{moid_label}));

    my $response = $self->query_api(
        endpoint  => '/v1/query',
        get_param => [ 'query=' . $options{metric} ]
    );

    my @series = @{ $response->{data}->{result} // [] };
    for my $candidate (@moid_label_candidates) {
        for my $serie (@series) {
            next if (!defined($serie->{metric}->{$candidate}));
            if ($serie->{metric}->{$candidate} eq $options{rsrc_id}) {
                $self->{moid_label} = $candidate;
                $self->{output}->add_option_msg(long_msg => "Real-Time Metrics: resource ids are carried by the '"
                    . $candidate . "' label. Pass --rtm-moid-label=" . $candidate . " to skip this discovery query.");
                return $self->{moid_label};
            }
        }
    }

    my %seen;
    my @labels = grep { !$seen{$_}++ } map { keys %{ $_->{metric} // {} } } @series;
    $self->{output}->option_exit(short_msg => "Could not find which label of metric '" . $options{metric}
        . "' carries the resource id '" . $options{rsrc_id} . "' (labels seen: "
        . (join(', ', sort @labels) || 'none') . "). Pin it with --rtm-moid-label.");
}

sub convert_unit {
    my ($self, %options) = @_;

    my $from = $units{ lc($options{from}) } // $units{ $options{from} };
    my $to   = $units{ $options{to} };

    if (!defined($from) || !defined($to)) {
        $self->{output}->option_exit(short_msg => "Unknown unit in the conversion of counter '" . $options{cid}
            . "' ('" . $options{from} . "' to '" . $options{to} . "').");
    }
    if ($from->[0] ne $to->[0]) {
        $self->{output}->option_exit(short_msg => "Counter '" . $options{cid} . "' is published in '"
            . $options{from} . "' but is expected in '" . $options{to} . "', which measures something else ('"
            . $from->[0] . "' against '" . $to->[0] . "'). Refusing to report a wrong value.");
    }

    return $options{value} * $from->[1] / $to->[1];
}

# Reads one counter for one resource and returns it in the unit the modes expect.
sub get_perf_value {
    my ($self, %options) = @_;

    if (is_empty($options{cid}) || is_empty($options{rsrc_id})) {
        $self->{output}->option_exit(short_msg => "Real-Time Metrics: get_perf_value needs both a cid and a rsrc_id.");
    }

    my $mapping = $self->resolve_metric(cid => $options{cid});
    my $label   = $self->resolve_moid_label(metric => $mapping->{metric}, rsrc_id => $options{rsrc_id});

    my $query = $mapping->{metric} . '{' . $label . '="' . escape_label_value($options{rsrc_id}) . '"}';
    my $response = $self->query_api(endpoint => '/v1/query', get_param => [ 'query=' . $query ]);

    my @series = @{ $response->{data}->{result} // [] };
    if (!@series) {
        # An empty result is ambiguous: the resource may genuinely have no sample right
        # now, or the selector may simply match nothing because the label or the resource
        # id is wrong. One selector-less query tells both apart, so that a mistake is
        # reported instead of silently looking like an idle resource.
        my $unfiltered = $self->query_api(endpoint => '/v1/query', get_param => [ 'query=' . $mapping->{metric} ]);
        my @all = @{ $unfiltered->{data}->{result} // [] };

        if (@all) {
            my %seen;
            my @values = grep { !$seen{$_}++ } map { $_->{metric}->{$label} // '' } @all;
            $self->{output}->option_exit(short_msg => "Metric '" . $mapping->{metric} . "' has "
                . scalar(@all) . " series but none with " . $label . '="' . $options{rsrc_id} . '". '
                . "Check the resource id, or the label carrying it (--rtm-moid-label). "
                . "Values seen for '" . $label . "': " . (join(', ', grep { $_ ne '' } @values) || 'none') . ".");
        }

        $self->{output}->add_option_msg(short_msg => "no data for resource " . $options{rsrc_id}
            . " counter " . $options{cid} . " at the moment.");
        return undef;
    }
    if (@series > 1) {
        $self->{output}->option_exit(short_msg => "The query '" . $query . "' returned " . scalar(@series)
            . " series instead of one. Refusing to pick one arbitrarily.");
    }

    # instant vector: value is the [ timestamp, "value" ] pair
    my $raw = $series[0]->{value}->[1];
    return undef if (!defined($raw) || $raw !~ /^-?\d+(\.\d+)?([eE][-+]?\d+)?$/);

    return $self->convert_unit(
        value => $raw,
        from  => $mapping->{unit},
        to    => $mapping->{target},
        cid   => $options{cid}
    );
}

# Only used to build the label selector, so the value is quoted, not interpolated.
sub escape_label_value {
    my ($value) = @_;

    return '' if (!defined($value));
    $value =~ s/\\/\\\\/g;
    $value =~ s/"/\\"/g;

    return $value;
}

1;

__END__

=head1 NAME

apps::vmware::vsphere8::custom::rtm - Performance counters read from the VCF Operations Real-Time Metrics API

=head1 DESCRIPTION

Collects performance counters through the Real-Time Metrics API of VCF Operations, the
replacement Broadcom offers for the vStats API removed in vSphere 9.1.

This API is not served by vCenter. It belongs to VCF Operations, requires its
Real-Time Metrics component to be deployed and a collection profile to be enabled, and
authenticates with a JWT bearer token obtained in three steps. It therefore takes its
own address and credentials through the C<--rtm-*> options and is never selected
automatically by C<--metrics-source=auto>.

Counter ids keep the vStats naming (C<cpu.capacity.usage.HOST>), so the modes are
unchanged. Every metric name is validated against the C</v1/metadata> catalogue of the
appliance before being queried, the label carrying the managed object id is discovered
at runtime, and values are converted to the unit each mode expects. Anything that
cannot be resolved raises an explicit error rather than a wrong or empty value.

=head1 METHODS

=head2 get_perf_value

    my $value = $rtm->get_perf_value(cid => 'cpu.capacity.usage.HOST', rsrc_id => 'host-35');

Returns the current value of the given counter for the given resource, converted to the
unit expected by the modes, or C<undef> when the appliance currently has no sample.

=head2 get_token

Runs the three-step authentication sequence (C<token/acquire>, C<integrations/services>
filtered on the C<VCF_VODAP> entry, C<token/exchange>) and caches the resulting JWT for
its announced validity.

=head2 metric_catalogue

Returns the set of metric names advertised by C</v1/metadata>. An empty catalogue means
no collection profile is enabled on the appliance.

=head2 resolve_moid_label

Discovers which metric label carries the managed object id of the monitored resource,
by inspecting the labels of the series the appliance returns. Bypassed by
C<--rtm-moid-label>.

=cut
