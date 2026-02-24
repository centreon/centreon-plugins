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

package apps::backup::veeam::vone::restapi::mode::proxies;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

my $map_repository_state_numeric = {
    unknown => 0,
    ok => 1,
    inaccessible => 2,
    disconnected => 3,
    outOfDate => 4,
    warning => 5
};

sub custom_status_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => 'proxy.state.count',
        instances => $self->{result_values}->{name},
        value => $map_repository_state_numeric->{ $self->{result_values}->{state} },
        min => 0
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Number of proxies ';
}

sub prefix_proxy_output {
    my ($self, %options) = @_;

    return sprintf(
        "proxy '%s' [type: %s] ",
        $options{instance_value}->{name},
        $options{instance_value}->{type}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'proxies', type => 1, cb_prefix_output => 'prefix_proxy_output', message_multiple => 'All proxies are ok' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'proxies-detected', display_ok => 0, nlabel => 'proxies.detected.count', set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'detected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{proxies} = [
        {
            label => 'proxy-status',
            type => 2,
            unknown_default => '%{state} =~ /unknown/i',
            warning_default => '%{state} =~ /warning|outOfDate/i',
            critical_default => '%{state} =~ /inaccessible|disconnected/i',
            set => {
                key_values => [
                    { name => 'state' }, { name => 'name' }, { name => 'type' }
                ],
                output_template => 'state: %s',
                closure_custom_perfdata => $self->can('custom_status_perfdata'),
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-uid:s'  => { name => 'filter_uid' },
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $repositories = $options{custom}->get_proxies();

    $self->{global} = { detected => 0 };
    $self->{proxies} = {};
    foreach my $repo (@{$repositories->{items}}) {
        next if ($repo->{enabled} !~ /true|1/i);
        next if (defined($self->{option_results}->{filter_uid}) && $self->{option_results}->{filter_uid} ne '' &&
            $repo->{proxyUidInVbr} !~ /$self->{option_results}->{filter_uid}/);
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $repo->{name} !~ /$self->{option_results}->{filter_name}/);

        $self->{proxies}->{ $repo->{name} } = {
            name => $repo->{name},
            type => $repo->{type},
            state => lcfirst($repo->{state})
        };
        $self->{global}->{detected}++;
    }
}

1;

__END__

=head1 MODE

Check proxies.

=over 8

=item B<--filter-uid>

Filter proxies by UID (can be a regexp).

=item B<--filter-name>

Filter proxies by name (can be a regexp).

=item B<--unknown-proxy-status>

Define the conditions to match for the status to be UNKOWN (default: '%{state} =~ /unknown/i').
You can use the following variables: %{state}, %{name}, %{type}

=item B<--warning-proxy-status>

Define the conditions to match for the status to be WARNING (default: '%{state} =~ /inaccessible|disconnected/i').
You can use the following variables: %{state}, %{name}, %{type}

=item B<--critical-proxy-status>

Define the conditions to match for the status to be CRITICAL (default: '%{state} =~ /warning|outOfDate/i').
You can use the following variables: %{state}, %{name}, %{type}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'proxies-detected'.

=back

=cut
