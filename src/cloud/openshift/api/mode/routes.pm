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

package cloud::openshift::api::mode::routes;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc qw(is_excluded exprintf is_empty is_not_empty);
use centreon::plugins::constants qw(:counters);

sub custom_options_threshold {
    my ($self, %options) = @_;

    my $check = $self->{thlabel};

    my $value = $self->{result_values}->{ $self->{key_values}->[0]->{name} } // '';

    my $status = $self->{perfdata}->threshold_check(
        value => $value, threshold => [
            { label => "critical-$check", exit_litteral => 'critical' },
            { label => "warning-$check",  exit_litteral => 'warning' },
            { label => "unknown-$check",  exit_litteral => 'unknown' }
        ]
    );

    if ($self->{instance_mode}->{verbose_requested} || $status ne 'ok') {
        $self->{instance_mode}->{display_details}->{$check} = 1;
        $self->{output}->{option_results}->{verbose} = 1;
    }

    return $status;
}

sub custom_output_detail {
    my ($self, %options) = @_;

    my $id = $options{id};

    my ($counter) = grep { $_->{label} eq $id } @{$self->{maps_counters}->{global}};

    $counter = $counter->{set} if $counter;
    my $msg = exprintf($counter->{output_template}, $self->{global});
    return $msg unless $self->{display_details}->{$id} && ref $self->{$id} eq 'ARRAY' && @{$self->{$id}};

    $self->{output}->output_add( long_msg => $options{title}."\n". join "\n", map { exprintf( "Route '%{name}' [namespace: %{namespace}, host: %{host}, service: %{service}]", $_) }
                                                                              sort { $a->{name} cmp $b->{name} }
                                                                              @{$self->{$id}} );

    return $msg;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, use_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "include-name:s"         => { name => 'include_name',      default => '' },
        "exclude-name:s"         => { name => 'exclude_name',      default => '' },
        "namespace:s"            => { name => 'namespace',         default => '' },
        "include-namespace:s"    => { name => 'include_namespace', default => '' },
        "exclude-namespace:s"    => { name => 'exclude_namespace', default => '' },
        "include-host:s"         => { name => 'include_host',      default => '' },
        "exclude-host:s"         => { name => 'exclude_host',      default => '' },
        "include-label:s"        => { name => 'include_label',     default => '' },
        "exclude-label:s"        => { name => 'exclude_label',     default => '' },
        "include-service:s"      => { name => 'include_service',   default => '' },
        "exclude-service:s"      => { name => 'exclude_service',   default => '' },
        "include-termination:s"  => { name => 'include_termination', default => '' },
        "exclude-termination:s"  => { name => 'exclude_termination', default => '' }
    });

    $self->{display_details} = {};
    $self->{verbose_requested} = $self->{output}->is_verbose();

    return $self;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL },
        { name => 'namespace', type => COUNTER_TYPE_INSTANCE, display_long => $self->{output}->is_verbose() },
        { name => 'termination', type => COUNTER_TYPE_INSTANCE, display_long => $self->{output}->is_verbose() },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'routes-total', nlabel => 'routes.total.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'Total routes: %{total}',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'routes-admitted', nlabel => 'routes.admitted.count', set => {
                key_values => [ { name => 'admitted' } ],
                closure_custom_output => sub { $self->custom_output_detail( id => 'routes-admitted',
                                                                            title => 'List of admitted routes:' ) },
                closure_custom_threshold_check => $self->can('custom_options_threshold'),
                output_template => 'Routes admitted: %{admitted}',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'routes-not-admitted', nlabel => 'routes.not.admitted.count', set => {
                key_values => [ { name => 'not_admitted' } ],
                output_template => 'Routes not admitted: %{not_admitted}',
                closure_custom_output => sub { $self->custom_output_detail( id => 'routes-not-admitted',
                                                                            title => 'List of non-admitted routes:' ) },
                closure_custom_threshold_check => $self->can('custom_options_threshold'),
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'routes-tls', nlabel => 'routes.tls.count', set => {
                key_values => [ { name => 'tls' } ],
                output_template => 'Routes with TLS: %{tls}',
                closure_custom_output => sub { $self->custom_output_detail( id => 'routes-tls',
                                                                            title => 'List of routes with TLS:' ) },
                closure_custom_threshold_check => $self->can('custom_options_threshold'),
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'routes-not-tls', nlabel => 'routes.not.tls.count', set => {
                key_values => [ { name => 'not_tls' } ],
                output_template => 'Routes without TLS: %{not_tls}',
                closure_custom_output => sub { $self->custom_output_detail( id => 'routes-not-tls',
                                                                            title => 'List of routes without TLS:' ) },
                closure_custom_threshold_check => $self->can('custom_options_threshold'),
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'hosts-exposed', nlabel => 'hosts.exposed.count', set => {
                key_values => [ { name => 'hosts' } ],
                output_template => 'Hosts exposed: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'services-targeted', nlabel => 'services.targeted.count', set => {
                key_values => [ { name => 'services' } ],
                output_template => 'Services targeted: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{namespace} = [
        { label => 'routes-per-namespace', nlabel => 'namespace.routes.count', set => {
                key_values => [ { name => 'count' }, { name => 'display' } ],
                output_template => 'Namespace %{display}: %{count} route(s)',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{termination} = [
        { label => 'termination-type', nlabel => 'routes.termination.count', set => {
                key_values => [ { name => 'count' }, { name => 'display' } ],
                output_template => 'Termination %{display}: %{count} route(s)',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{display_details} = {};

    $self->{global} = {
        total => 0,
        admitted => 0,
        not_admitted => 0,
        tls => 0,
        not_tls => 0,
        hosts => 0,
        services => 0
    };

    $self->{namespace} = {};
    $self->{termination} = {};
    $self->{"routes-admitted"} = [];
    $self->{"routes-not-admitted"} = [];
    $self->{"routes-tls"} = [];
    $self->{"routes-not-tls"} = [];

    my %seen_hosts = ();
    my %seen_services = ();

    my $results = $options{custom}->openshift_list_routes( namespace => $self->{option_results}->{namespace} );

    foreach my $route (@{$results}) {
        my $name = $route->{metadata}->{name};
        my $namespace = $route->{metadata}->{namespace};
        my $service = $route->{spec}->{to}->{name} // '';
        my $tls = defined($route->{spec}->{tls}) ? 1 : 0;
        my $termination = $tls ? ($route->{spec}->{tls}->{termination} // 'unset') : 'none';

        my $host = $self->_get_route_host($route);
        my $labels = $route->{metadata}->{labels} // {};
        my $labels_str = join ',', map { "$_=$labels->{$_}" } keys %$labels;

        next if is_excluded($name, $self->{option_results}->{include_name}, $self->{option_results}->{exclude_name}, output => $self->{output})
                || is_excluded($namespace, $self->{option_results}->{include_namespace}, $self->{option_results}->{exclude_namespace}, output => $self->{output})
                || is_excluded($host, $self->{option_results}->{include_host}, $self->{option_results}->{exclude_host}, output => $self->{output})
                || is_excluded($labels_str, $self->{option_results}->{include_label}, $self->{option_results}->{exclude_label}, output => $self->{output})
                || is_excluded($service, $self->{option_results}->{include_service}, $self->{option_results}->{exclude_service}, output => $self->{output})
                || is_excluded($termination, $self->{option_results}->{include_termination}, $self->{option_results}->{exclude_termination}, output => $self->{output});
        $self->{global}->{total}++;
        my $hr = { name => $name,
                   namespace => $namespace,
                   host => $host,
                   service => $service
                 };

        my $is_admitted = $self->_is_route_admitted($route);
        if ($is_admitted) {
            $self->{global}->{admitted}++;
            push @{$self->{"routes-admitted"}}, $hr;
        } else {
            $self->{global}->{not_admitted}++;
            push @{$self->{"routes-not-admitted"}}, $hr;
        }

        if ($tls) {
            $self->{global}->{tls}++;
            push @{$self->{"routes-tls"}}, $hr;
        } else {
            $self->{global}->{not_tls}++;
            push @{$self->{"routes-not-tls"}}, $hr;
        }

        $self->{namespace}->{$namespace} = { display => $namespace, count => 0 }
            unless $self->{namespace}->{$namespace};

        $self->{namespace}->{$namespace}->{count}++;

        $self->{termination}->{$termination} = { display => $termination, count => 0 }
            unless $self->{termination}->{$termination};

        $self->{termination}->{$termination}->{count}++;

        $seen_hosts{$host}++ if $host;
        $seen_services{$service}++ if $service;
    }

    $self->{global}->{hosts} = keys %seen_hosts;
    $self->{global}->{services} = keys %seen_services;
}

sub _get_route_host {
    my ($self, $route) = @_;

    return $route->{spec}->{host} if is_not_empty($route->{spec}->{host});

    if (ref $route->{status}->{ingress} eq 'ARRAY') {
        foreach my $ingress (@{$route->{status}->{ingress}}) {
            return $ingress->{host} if is_not_empty($ingress->{host});
        }
    }

    return '';
}

sub _is_route_admitted {
    my ($self, $route) = @_;

    return 0 unless ref $route->{status}->{ingress} eq 'ARRAY';

    foreach my $ingress (@{$route->{status}->{ingress}}) {
        next unless $ingress->{conditions};
        foreach my $condition (@{$ingress->{conditions}}) {
            return 1 if $condition->{type} eq 'Admitted' && $condition->{status} eq 'True';
        }
    }

    return 0;
}

1;

__END__

=head1 MODE

Check and monitor OpenShift routes status, TLS configuration, and admission status.

=over 8

=item B<--namespace>

Query routes in the specified namespace instead of all namespaces.

=item B<--include-name>

Include route name (can be a regexp).

=item B<--exclude-name>

Exclude route name (can be a regexp).

=item B<--include-namespace>

Include route namespace (can be a regexp).

=item B<--exclude-namespace>

Exclude route namespace (can be a regexp).

=item B<--include-host>

Include route host (can be a regexp).

=item B<--exclude-host>

Exclude route host (can be a regexp).

=item B<--include-label>

Include route labels in format key=value (can be a regexp).

=item B<--exclude-label>

Exclude route labels in format key=value (can be a regexp).

=item B<--include-service>

Include route service (can be a regexp).

=item B<--exclude-service>

Exclude route service (can be a regexp).

=item B<--include-termination>

Include route termination type: C<edge>, C<passthrough>, C<reencrypt>, C<none> (can be a regexp).

=item B<--exclude-termination>

Exclude route termination type: C<edge>, C<passthrough>, C<reencrypt>, C<none> (can be a regexp).

=item B<--warning-hosts-exposed>

Threshold.

=item B<--critical-hosts-exposed>

Threshold.

=item B<--warning-routes-admitted>

Threshold.

=item B<--critical-routes-admitted>

Threshold.

=item B<--warning-routes-not-admitted>

Threshold.

=item B<--critical-routes-not-admitted>

Threshold.

=item B<--warning-routes-not-tls>

Threshold.

=item B<--critical-routes-not-tls>

Threshold.

=item B<--warning-routes-per-namespace>

Threshold.

=item B<--critical-routes-per-namespace>

Threshold.

=item B<--warning-routes-tls>

Threshold.

=item B<--critical-routes-tls>

Threshold.

=item B<--warning-routes-total>

Threshold.

=item B<--critical-routes-total>

Threshold.

=item B<--warning-services-targeted>

Threshold.

=item B<--critical-services-targeted>

Threshold.

=item B<--warning-termination-type>

Threshold.

=item B<--critical-termination-type>

Threshold.

=back

=cut
