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

package network::stormshield::snmp::mode::router_disco;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::constants qw/:counters :values/;
use centreon::plugins::misc;


sub build_gateways_detail {
    my ($self, %options) = @_;

    my @lines = "----------------------------List of the Gateways----------------------------";

    foreach my $gateway (@{ $options{gateways} }) {
        my $packet_loss_str = defined($gateway->{packet_loss_prct})
            ? sprintf('%s %%', $gateway->{packet_loss_prct})
            : 'not monitored';
        my $active_str = $gateway->{active} == 1 ? 'yes' : 'no';

        if ($gateway->{latency} == 0) {
            push @lines, sprintf(
                "Gateway '%s' (%s - %s) state: %s, active: %s, unreachable (latency: 0 ms), packet loss: %s.",
                $gateway->{display}, $gateway->{gateway_type}, $gateway->{address},
                $gateway->{state}, $active_str, $packet_loss_str
            );
        } else {
            push @lines, sprintf(
                "Gateway '%s' (%s - %s) state: %s, active: %s, latency: %s ms, jitter: %s ms, packet loss: %s.",
                $gateway->{display}, $gateway->{gateway_type}, $gateway->{address},
                $gateway->{state}, $active_str, $gateway->{latency}, $gateway->{jitter}, $packet_loss_str
            );
        }
    }

    return join("\n", @lines);
}

sub custom_router_status_output {
    my ($self, %options) = @_;

    my $principal_total = $self->{result_values}->{principal_total};
    my $principal_down  = $self->{result_values}->{principal_down};
    my $backup_total    = $self->{result_values}->{backup_total};
    my $backup_down     = $self->{result_values}->{backup_down};

    if ($principal_down == 0 && $backup_down == 0) {
        return sprintf(
            'All gateways are working (%d/%d principal, %d/%d backup).',
            $principal_total, $principal_total, $backup_total, $backup_total
        );
    }

    my $principal_seg = ($principal_total > 0)
        ? ($principal_down > 0
            ? sprintf('%d/%d principal down', $principal_down, $principal_total)
            : sprintf('%d/%d principal up', $principal_total, $principal_total))
        : '';
    my $backup_seg = ($backup_total > 0)
        ? ($backup_down > 0
            ? sprintf('%d/%d backup down', $backup_down, $backup_total)
            : sprintf('%d/%d backup up', $backup_total, $backup_total))
        : '';

    if ($principal_down > 0 && $backup_down > 0) {
        return sprintf(join(', ', grep { $_ ne '' } ($principal_seg, $backup_seg)) . '.');
    }

    if ($principal_seg ne '' && $backup_seg ne '') {
        return sprintf('%s (%s).', $principal_seg, $backup_seg);
    }
    return $principal_seg ne '' ? $principal_seg . '.' : $backup_seg . '.';
}

sub custom_gateways_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{gateways} = $options{new_datas}->{$self->{instance} . '_gateways'};

    return 0;
}

sub custom_packetloss_threshold {
    my ($self, %options) = @_;

    my $severity_rank = { ok => 0, warning => 1, unknown => 2, critical => 3 };
    my $worst_status = 'ok';

    foreach my $gateway (@{ $self->{result_values}->{gateways} }) {
        next if (!defined($gateway->{packet_loss_prct}));

        my $gw_status = $self->{perfdata}->threshold_check(
            value => $gateway->{packet_loss_prct},
            threshold => [
                { label => 'critical-packet-loss', exit_litteral => 'critical' },
                { label => 'warning-packet-loss', exit_litteral => 'warning' }
            ]
        );

        if ($severity_rank->{$gw_status} > $severity_rank->{$worst_status}) {
            $worst_status = $gw_status;
        }
    }

    return $worst_status;
}

sub custom_packetloss_output {
    my ($self, %options) = @_;

    my @bad;
    foreach my $gateway (@{ $self->{result_values}->{gateways} }) {
        next if (!defined($gateway->{packet_loss_prct}));

        my $gw_status = $self->{perfdata}->threshold_check(
            value => $gateway->{packet_loss_prct},
            threshold => [
                { label => 'critical-packet-loss', exit_litteral => 'critical' },
                { label => 'warning-packet-loss', exit_litteral => 'warning' }
            ]
        );
        next if ($gw_status eq 'ok');

        push @bad, sprintf(
            "packet loss: gateway '%s' %s%% (%s)",
            $gateway->{display}, $gateway->{packet_loss_prct}, $gw_status
        );
    }

    return join(', ', @bad) . '.';
}

sub custom_packetloss_perfdata {
    my ($self, %options) = @_;

    foreach my $gateway (@{ $self->{result_values}->{gateways} }) {
        next if (!defined($gateway->{packet_loss_prct}));

        $self->{output}->perfdata_add(
            nlabel => 'router.gateway.packetloss.percentage',
            instances => [$self->{result_values}->{display}, $gateway->{display}],
            value => $gateway->{packet_loss_prct},
            warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-packet-loss'),
            critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-packet-loss'),
            unit => '%',
            min => 0,
            max => 100
        );
    }
}

sub custom_latency_threshold {
    my ($self, %options) = @_;

    my $severity_rank = { ok => 0, warning => 1, unknown => 2, critical => 3 };
    my $worst_status = 'ok';

    foreach my $gateway (@{ $self->{result_values}->{gateways} }) {
        # latency 0 means unreachable: already covered by router-status, not a latency problem
        next if ($gateway->{latency} == 0);

        my $gw_status = $self->{perfdata}->threshold_check(
            value => $gateway->{latency},
            threshold => [
                { label => 'critical-latency', exit_litteral => 'critical' },
                { label => 'warning-latency', exit_litteral => 'warning' }
            ]
        );

        if ($severity_rank->{$gw_status} > $severity_rank->{$worst_status}) {
            $worst_status = $gw_status;
        }
    }

    return $worst_status;
}

sub custom_latency_output {
    my ($self, %options) = @_;

    my @bad;
    foreach my $gateway (@{ $self->{result_values}->{gateways} }) {
        next if ($gateway->{latency} == 0);

        my $gw_status = $self->{perfdata}->threshold_check(
            value => $gateway->{latency},
            threshold => [
                { label => 'critical-latency', exit_litteral => 'critical' },
                { label => 'warning-latency', exit_litteral => 'warning' }
            ]
        );
        next if ($gw_status eq 'ok');

        push @bad, sprintf(
            "latency: gateway '%s' %s ms (%s)",
            $gateway->{display}, $gateway->{latency}, $gw_status
        );
    }

    return join(', ', @bad) . '.';
}

sub custom_latency_perfdata {
    my ($self, %options) = @_;

    foreach my $gateway (@{ $self->{result_values}->{gateways} }) {
        next if ($gateway->{latency} == 0);

        $self->{output}->perfdata_add(
            nlabel => 'router.gateway.latency.milliseconds',
            instances => [$self->{result_values}->{display}, $gateway->{display}],
            value => $gateway->{latency},
            warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-latency'),
            critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-latency'),
            unit => 'ms',
            min => 0
        );
    }
}


sub custom_jitter_threshold {
    my ($self, %options) = @_;

    my $severity_rank = { ok => 0, warning => 1, unknown => 2, critical => 3 };
    my $worst_status = 'ok';

    foreach my $gateway (@{ $self->{result_values}->{gateways} }) {
        # if latency 0 jitter is not valid
        next if ($gateway->{latency} == 0);

        my $gw_status = $self->{perfdata}->threshold_check(
            value => $gateway->{jitter},
            threshold => [
                { label => 'critical-jitter', exit_litteral => 'critical' },
                { label => 'warning-jitter', exit_litteral => 'warning' }
            ]
        );

        if ($severity_rank->{$gw_status} > $severity_rank->{$worst_status}) {
            $worst_status = $gw_status;
        }
    }

    return $worst_status;
}

sub custom_jitter_output {
    my ($self, %options) = @_;

    my @bad;
    foreach my $gateway (@{ $self->{result_values}->{gateways} }) {
        next if ($gateway->{latency} == 0);

        my $gw_status = $self->{perfdata}->threshold_check(
            value => $gateway->{jitter},
            threshold => [
                { label => 'critical-jitter', exit_litteral => 'critical' },
                { label => 'warning-jitter', exit_litteral => 'warning' }
            ]
        );
        next if ($gw_status eq 'ok');

        push @bad, sprintf(
            "jitter: gateway '%s' %s ms (%s)",
            $gateway->{display}, $gateway->{jitter}, $gw_status
        );
    }

    return join(', ', @bad) . '.';
}

sub custom_jitter_perfdata {
    my ($self, %options) = @_;

    foreach my $gateway (@{ $self->{result_values}->{gateways} }) {
        next if ($gateway->{latency} == 0);

        $self->{output}->perfdata_add(
            nlabel => 'router.gateway.jitter.milliseconds',
            instances => [$self->{result_values}->{display}, $gateway->{display}],
            value => $gateway->{jitter},
            warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-jitter'),
            critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-jitter'),
            unit => 'ms',
            min => 0
        );
    }
}


sub custom_principal_count_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{down} = $options{new_datas}->{$self->{instance} . '_principal_down'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_principal_total'};

    return 0;
}

sub custom_principal_count_threshold {
    my ($self, %options) = @_;

    return $self->{perfdata}->threshold_check(
        value => $self->{result_values}->{down},
        threshold => [
            { label => 'critical-principal-count', exit_litteral => 'critical' },
            { label => 'warning-principal-count', exit_litteral => 'warning' }
        ]
    );
}

# silent: the down count is already shown in the router-status line, this counter
# only exists to drive warning/critical off a user-defined numeric threshold
sub custom_principal_count_output {
    my ($self, %options) = @_;

    return '';
}

sub custom_principal_count_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => 'router.gateway.principal.down.count',
        instances => [$self->{result_values}->{display}],
        value => $self->{result_values}->{down},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-principal-count'),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-principal-count'),
        min => 0,
        max => $self->{result_values}->{total}
    );
}

sub custom_backup_count_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{down} = $options{new_datas}->{$self->{instance} . '_backup_down'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_backup_total'};

    return 0;
}

sub custom_backup_count_threshold {
    my ($self, %options) = @_;

    return $self->{perfdata}->threshold_check(
        value => $self->{result_values}->{down},
        threshold => [
            { label => 'critical-backup-count', exit_litteral => 'critical' },
            { label => 'warning-backup-count', exit_litteral => 'warning' }
        ]
    );
}

sub custom_backup_count_output {
    my ($self, %options) = @_;

    return '';
}

sub custom_backup_count_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => 'router.gateway.backup.down.count',
        instances => [$self->{result_values}->{display}],
        value => $self->{result_values}->{down},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-backup-count'),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-backup-count'),
        min => 0,
        max => $self->{result_values}->{total}
    );
}


sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name => 'router',
            type => COUNTER_TYPE_INSTANCE,
            message_multiple => 'All gateways are ok',
            display_long => 0,
            message_separator => ' ',
            skipped_code => { -10 => 1 }
        }
    ];

    $self->{maps_counters}->{router} = [
        {
            label => 'router-status',
            type => 2,
            warning_default => '%{one_principal_down} == 1',
            critical_default => '%{all_down} == 1',
            set => {
                key_values => [
                    { name => 'one_principal_down' }, { name => 'all_down' }, { name => 'display' },
                    { name => 'principal_down' }, { name => 'principal_total' },
                    { name => 'backup_down' }, { name => 'backup_total' }
                ],
                closure_custom_output => $self->can('custom_router_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        {
            label => 'packet-loss',
            nlabel => 'router.gateway.packetloss.percentage',
            type => COUNTER_KIND_METRIC,
            threshold => 0,
            set => {
                key_values => [ { name => 'display' }, { name => 'gateways' } ],
                closure_custom_calc => $self->can('custom_gateways_calc'),
                closure_custom_output => $self->can('custom_packetloss_output'),
                closure_custom_perfdata => $self->can('custom_packetloss_perfdata'),
                closure_custom_threshold_check => $self->can('custom_packetloss_threshold')
            }
        },
        {
            label => 'latency',
            nlabel => 'router.gateway.latency.milliseconds',
            type => COUNTER_KIND_METRIC,
            threshold => 0,
            set => {
                key_values => [ { name => 'display' }, { name => 'gateways' } ],
                closure_custom_calc => $self->can('custom_gateways_calc'),
                closure_custom_output => $self->can('custom_latency_output'),
                closure_custom_perfdata => $self->can('custom_latency_perfdata'),
                closure_custom_threshold_check => $self->can('custom_latency_threshold')
            }
        },
        {
            label => 'jitter',
            nlabel => 'router.gateway.jitter.milliseconds',
            type => COUNTER_KIND_METRIC,
            threshold => 0,
            set => {
                key_values => [ { name => 'display' }, { name => 'gateways' } ],
                closure_custom_calc => $self->can('custom_gateways_calc'),
                closure_custom_output => $self->can('custom_jitter_output'),
                closure_custom_perfdata => $self->can('custom_jitter_perfdata'),
                closure_custom_threshold_check => $self->can('custom_jitter_threshold')
            }
        },
        {
            label => 'principal-down-count',
            nlabel => 'router.gateway.principal.down.count',
            type => COUNTER_KIND_METRIC,
            threshold => 0,
            set => {
                key_values => [ { name => 'display' }, { name => 'principal_down' }, { name => 'principal_total' } ],
                closure_custom_calc => $self->can('custom_principal_count_calc'),
                closure_custom_output => $self->can('custom_principal_count_output'),
                closure_custom_perfdata => $self->can('custom_principal_count_perfdata'),
                closure_custom_threshold_check => $self->can('custom_principal_count_threshold')
            }
        },
        {
            label => 'backup-down-count',
            nlabel => 'router.gateway.backup.down.count',
            type => COUNTER_KIND_METRIC,
            threshold => 0,
            set => {
                key_values => [ { name => 'display' }, { name => 'backup_down' }, { name => 'backup_total' } ],
                closure_custom_calc => $self->can('custom_backup_count_calc'),
                closure_custom_output => $self->can('custom_backup_count_output'),
                closure_custom_perfdata => $self->can('custom_backup_count_perfdata'),
                closure_custom_threshold_check => $self->can('custom_backup_count_threshold')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'warning-packet-loss:s'      => { name => 'warning_packet_loss' },
        'critical-packet-loss:s'     => { name => 'critical_packet_loss' },
        'warning-latency:s'          => { name => 'warning_latency' },
        'critical-latency:s'         => { name => 'critical_latency' },
        'warning-jitter:s'           => { name => 'warning_jitter' },
        'critical-jitter:s'          => { name => 'critical_jitter' },
        'warning-principal-count:s'  => { name => 'warning_principal_count' },
        'critical-principal-count:s' => { name => 'critical_principal_count' },
        'warning-backup-count:s'     => { name => 'warning_backup_count' },
        'critical-backup-count:s'    => { name => 'critical_backup_count' },
        'filter-name:s'              => { name => 'filter_name' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    my @thresholds = (
        ['warning-packet-loss', 'warning_packet_loss'],
        ['critical-packet-loss', 'critical_packet_loss'],
        ['warning-latency', 'warning_latency'],
        ['critical-latency', 'critical_latency'],
        ['warning-jitter', 'warning_jitter'],
        ['critical-jitter', 'critical_jitter'],
        ['warning-principal-count', 'warning_principal_count'],
        ['critical-principal-count', 'critical_principal_count'],
        ['warning-backup-count', 'warning_backup_count'],
        ['critical-backup-count', 'critical_backup_count']
    );

    foreach my $threshold (@thresholds) {
        my ($label, $option_name) = @$threshold;

        if (($self->{perfdata}->threshold_validate(label => $label, value => $self->{option_results}->{$option_name})) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold '" . $label . "' value '" . $self->{option_results}->{$option_name} . "'.");
            $self->{output}->option_exit();
        }
    }
}

my $mapping = {
    snsRouteRouterName        => { oid => '.1.3.6.1.4.1.11256.1.14.1.1.4' },
    snsRouteGatewayName       => { oid => '.1.3.6.1.4.1.11256.1.14.1.1.5' },
    snsRouteGatewayAddr       => { oid => '.1.3.6.1.4.1.11256.1.14.1.1.6' },
    snsRouteGatewayType       => { oid => '.1.3.6.1.4.1.11256.1.14.1.1.7' },
    snsRouteState             => { oid => '.1.3.6.1.4.1.11256.1.14.1.1.9' },
    snsRouteActive            => { oid => '.1.3.6.1.4.1.11256.1.14.1.1.11' },
    snsRouteLatency           => { oid => '.1.3.6.1.4.1.11256.1.14.1.1.18' },
    snsRouteJitter            => { oid => '.1.3.6.1.4.1.11256.1.14.1.1.19' },
    snsRoutePacketLossPrctOld => { oid => '.1.3.6.1.4.1.11256.1.14.1.1.20' },
    snsRoutePacketLossPrctRaw => { oid => '.1.3.6.1.4.1.11256.1.14.1.1.23' }
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_snsVersion = '.1.3.6.1.4.1.11256.1.18.2.0';
    
    my $snmp_result_version = $options{snmp}->get_leef(
        oids => [ $oid_snsVersion ],
        nothing_quit => 0,
    );

    my $use_old_packet_loss_oid = 0;
    my $version_clean = '';

    if (defined $snmp_result_version && defined $snmp_result_version->{$oid_snsVersion}) {
        $version_clean = $snmp_result_version->{$oid_snsVersion};
        $version_clean =~ s/([0-9]+(?:\.[0-9]+)*).*/$1/;

        if (!centreon::plugins::misc::minimal_version($version_clean, '5.1.0')) {
            $use_old_packet_loss_oid = 1;
        }
    } else {
        $use_old_packet_loss_oid = 1;
    }

    my %packet_loss_oid_map = (
        use_old => $mapping->{snsRoutePacketLossPrctOld}->{oid},
        use_new => $mapping->{snsRoutePacketLossPrctRaw}->{oid}
    );

    my $packet_loss_oid = $use_old_packet_loss_oid ? $packet_loss_oid_map{use_old} : $packet_loss_oid_map{use_new};

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $mapping->{snsRouteRouterName}->{oid} },
            { oid => $mapping->{snsRouteGatewayName}->{oid} },
            { oid => $mapping->{snsRouteGatewayAddr}->{oid} },
            { oid => $mapping->{snsRouteGatewayType}->{oid} },
            { oid => $mapping->{snsRouteState}->{oid} },
            { oid => $mapping->{snsRouteActive}->{oid} },
            { oid => $mapping->{snsRouteLatency}->{oid} },
            { oid => $mapping->{snsRouteJitter}->{oid} },
            { oid => $packet_loss_oid }
        ],
        nothing_quit => 1
    );

    $self->{router} = {};
    foreach my $oid (keys %{$snmp_result->{ $mapping->{snsRouteRouterName}->{oid} }}) {
        next if ($oid !~ /^$mapping->{snsRouteRouterName}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        next if (
            defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne ''
            && lc($result->{snsRouteRouterName}) ne lc($self->{option_results}->{filter_name})
        );

        my $router_name = $result->{snsRouteRouterName};
        if (!defined($self->{router}->{$router_name})) {
            $self->{router}->{$router_name} = {
                display => $router_name,
                gateways => []
            };
        }

        my $is_principal = ($result->{snsRouteGatewayType} =~ /^principal$/i) ? 1 : 0;
        my $is_down;
        if ($is_principal) {
            # for a principal gateway, active=no while state=up is itself a problem
            # it's ready/up but not actually carrying traffic -> counted as down
            $is_down = (
                $result->{snsRouteState} =~ /^(down|undef)$/i
                || $result->{snsRouteActive} == 0
                || $result->{snsRouteLatency} == 0
            ) ? 1 : 0;
        } else {
            # for a backup gateway, active=no is the normal/expected state when it's
            # not currently taking over -> it does not make the gateway "down"
            $is_down = (
                $result->{snsRouteState} =~ /^(down|undef)$/i
                || $result->{snsRouteLatency} == 0
            ) ? 1 : 0;
        }
        
        my $packet_loss_value;
        my $raw = $result->{ $use_old_packet_loss_oid ? 'snsRoutePacketLossPrctOld' : 'snsRoutePacketLossPrctRaw' };

        if (defined $raw) {
            if ($use_old_packet_loss_oid) {
                if ($raw =~ /^-?[0-9]+(\.[0-9]+)?$/) {
                    $packet_loss_value = $raw;
                } else {
                    $packet_loss_value = undef;
                }
            } else {
                $packet_loss_value = ($raw < 0 ? undef : $raw / 10);
            }
        } else {
            $packet_loss_value = undef;
        }

        push @{ $self->{router}->{$router_name}->{gateways} }, {
            display => $result->{snsRouteGatewayName},
            address => $result->{snsRouteGatewayAddr},
            gateway_type => $result->{snsRouteGatewayType},
            state => $result->{snsRouteState},
            active => $result->{snsRouteActive},
            latency => $result->{snsRouteLatency},
            jitter => $result->{snsRouteJitter},
            packet_loss_prct => $packet_loss_value,
            is_down => $is_down
        };
    }

    if (scalar(keys %{$self->{router}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No routes found matching filters.');
        $self->{output}->option_exit();
    }

    foreach my $router_name (keys %{$self->{router}}) {
        my @gateways = @{ $self->{router}->{$router_name}->{gateways} };
        my @principal_gateways = grep { $_->{gateway_type} =~ /^principal$/i } @gateways;
        my @backup_gateways = grep { $_->{gateway_type} =~ /^backup$/i } @gateways;

        my $principal_total = scalar(@principal_gateways);
        my $principal_down = scalar(grep { $_->{is_down} == 1 } @principal_gateways);
        my $backup_total = scalar(@backup_gateways);
        my $backup_down = scalar(grep { $_->{is_down} == 1 } @backup_gateways);

        $self->{router}->{$router_name}->{principal_total} = $principal_total;
        $self->{router}->{$router_name}->{principal_down} = $principal_down;
        $self->{router}->{$router_name}->{backup_total} = $backup_total;
        $self->{router}->{$router_name}->{backup_down} = $backup_down;

        $self->{router}->{$router_name}->{one_principal_down} = ($principal_down > 0) ? 1 : 0;
        $self->{router}->{$router_name}->{all_down} = (
            scalar(@gateways) > 0 && $principal_down == $principal_total && $backup_down == $backup_total
        ) ? 1 : 0;
        
        $self->{output}->output_add(
            long_msg => $self->build_gateways_detail(gateways => $self->{router}->{$router_name}->{gateways})
        );
    }
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['display', 'gateway_count', 'principal_count', 'backup_count', 'gateways_summary']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $router_name (sort keys %{$self->{router}}) {
        my $router = $self->{router}->{$router_name};
        my @gateways = @{ $router->{gateways} };

        $self->{output}->add_disco_entry(
            display => $router->{display},
            gateway_count => scalar(@gateways),
            principal_count => scalar(grep { $_->{gateway_type} =~ /^principal$/i } @gateways),
            backup_count => scalar(grep { $_->{gateway_type} =~ /^backup$/i } @gateways),
            gateways_summary => join(', ', map { $_->{display} . '(' . $_->{gateway_type} . ')' } @gateways)
        );
    }
}

1;

__END__

=head1 MODE

Discovery mode for Stormshield SD-WAN/VPN routes, grouped by router.
This mode produces a single Centreon service per router, with every gateway of that router (latency, jitter, packet loss, reachability state)
folded into that one service's output and perfdata, plus an aggregated router-level status.

=over 8

=item B<--warning-principal-count>

Warning threshold on the number of Principal gateways currently DOWN for the router.

=item B<--critical-principal-count>

Critical threshold on the number of Principal gateways currently DOWN for the router.

=item B<--warning-backup-count>

Warning threshold on the number of Backup gateways currently DOWN for the router.

=item B<--critical-backup-count>

Critical threshold on the number of Backup gateways currently DOWN for the router.

=item B<--warning-packet-loss>

Warning threshold on packet loss (in percent), applied to C<snsRoutePacketLossPrctRaw> / C<snsRoutePacketLossPrctOld> for each gateway of the router.

=item B<--critical-packet-loss>

Critical threshold on packet loss (in percent), applied to C<snsRoutePacketLossPrctRaw> / C<snsRoutePacketLossPrctOld> for each gateway of the router.

=item B<--warning-latency>

Warning threshold on latency (in milliseconds), applied to C<snsRouteLatency> for each gateway of the router.
Gateways with a latency of 0 (unreachable) are excluded from this check, since they are already covered by the down logic above.

=item B<--critical-latency>

Critical threshold on latency (in milliseconds), applied to C<snsRouteLatency> for each gateway of the router.
Gateways with a latency of 0 (unreachable) are excluded from this check, since they are already covered by the down logic above.

=item B<--warning-jitter>

Warning threshold on jitter (in milliseconds), applied to C<snsRouteJitter> for each gateway of the router.

=item B<--critical-jitter>

Critical threshold on jitter (in milliseconds), applied to C<snsRouteJitter> for each gateway of the router.

=item B<--filter-name>

Filter routers on the exact router name (for discovery).

=back

=cut
