#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package apps::apache::karaf::api::mode::bundlestatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::statefile;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "status is '%s' [version: %s] [feature installed: %s, version: %s]",
        $self->{result_values}->{status},
        $self->{result_values}->{version},
        $self->{result_values}->{feature_installed},
        $self->{result_values}->{feature_version}
    );
}

sub prefix_bundle_output {
    my ($self, %options) = @_;

    return "Bundle '" . $options{instance_value}->{name} . "' ";
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Number of bundles ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name => 'global',
            type => 0,
            cb_prefix_output => 'prefix_global_output'
        },
        {
            name => 'bundles',
            type => 1,
            cb_prefix_output => 'prefix_bundle_output',
            message_multiple => 'All bundles are ok'
        },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'bundles-failed', nlabel => 'bundles.failed.count', set => {
                key_values => [
                    { name => 'failed' },
                    { name => 'total' }
                ],
                output_template => 'failed: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        },
        { label => 'bundles-active', nlabel => 'bundles.active.count', set => {
                key_values => [
                    { name => 'active' },
                    { name => 'total' }
                ],
                output_template => 'active: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        },
        { label => 'bundles-resolved', nlabel => 'bundles.resolved.count', set => {
                key_values => [
                    { name => 'resolved' },
                    { name => 'total' }
                ],
                output_template => 'resolved: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{bundles} = [
        {
            label => 'status',
            type => 2,
            critical_default => '%{status} !~ /^(active|resolved)/i',
            set => {
                key_values => [
                    { name => 'status' },
                    { name => 'version' },
                    { name => 'feature_installed' },
                    { name => 'feature_version' },
                    { name => 'name' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
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
        'filter-instance:s'      => { name => 'filter_instance' },
        'filter-id:s'            => { name => 'filter_id' },
        'filter-name:s'          => { name => 'filter_name' },
        'filter-symbolic-name:s' => { name => 'filter_symbolic_name' },
        'reload-cache-time:s'    => { name => 'reload_cache_time', default => 60 }
    });

    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{statefile_cache}->check_options(%options);
}

sub reload_features_cache {
    my ($self, %options) = @_;

    my $response = $options{custom}->request_api(
        method => 'POST',
        endpoint => '/jolokia/read',
        payload => {
            type => 'read',
            mbean => 'org.apache.karaf:type=feature,name=*'
        }
    );

    my $data = { last_timestamp => time() };

    if (defined($response->{value}->{Features})) {
        $data->{features} = $response->{value}->{Features};
    } else {
        my $features = {};
        foreach my $entry (keys %{$response->{value}}) {
            $features = { %$features, %{$response->{value}->{$entry}->{Features}} };
        }
        $data->{features} = $features;
    }

    $self->{statefile_cache}->write(data => $data);
}

sub get_features {
    my ($self, %options) = @_;

    my $has_cache_file = $self->{statefile_cache}->read(statefile => 'cache_karaf_features_' . md5_hex($self->{option_results}->{hostname}));
    my $timestamp_cache = $self->{statefile_cache}->get(name => 'last_timestamp');
    if ($has_cache_file == 0 || !defined($timestamp_cache) ||
        ((time() - $timestamp_cache) > (($self->{option_results}->{reload_cache_time}) * 60))) {      
        $self->reload_features_cache(%options);
        $self->{statefile_cache}->read();
    }

    return $self->{statefile_cache}->get(name => 'features');
}

sub get_bundles {
    my ($self, %options) = @_;

    my $response = $options{custom}->request_api(
        method => 'POST',
        endpoint => '/jolokia/read',
        payload => {
            type => 'read',
            mbean => 'org.apache.karaf:type=bundle,name=*'
        }
    );

    if (defined($response->{value}->{Bundles})) {
        return values(%{$response->{value}->{Bundles}});
    }

    my @values = ();
    foreach my $entry (keys %{$response->{value}}) {
        next if ($entry !~ /name=([a-zA-Z]+)/);
        my $instance = $1;
        next if (defined($self->{option_results}->{filter_instance}) && $self->{option_results}->{filter_instance} ne ''
            && $instance !~ /$self->{option_results}->{filter_instance}/);
        push @values, values(%{$response->{value}->{$entry}->{Bundles}});
    }

    return @values;
}

sub manage_selection {
    my ($self, %options) = @_;

    my @bundles = $self->get_bundles(%options);
    my $features = $self->get_features(%options);

    $self->{global} = { total => 0, failed => 0, active => 0, resolved => 0 };
    $self->{bundles} = {};

    foreach (@bundles) {
        my $name = defined($_->{Name}) ? $_->{Name} : $_->{'Symbolic Name'};
        next if (defined($self->{option_results}->{filter_id}) && $self->{option_results}->{filter_id} ne '' &&
            $_->{ID} !~ /$self->{option_results}->{filter_id}/);
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/);
        next if (defined($self->{option_results}->{filter_symbolic_name}) && $self->{option_results}->{filter_symbolic_name} ne '' &&
            $_->{'Symbolic Name'} !~ /$self->{option_results}->{filter_symbolic_name}/);

        $self->{global}->{failed}++ if ($_->{State} eq 'Failure');
        $self->{global}->{active}++ if ($_->{State} eq 'Active');
        $self->{global}->{resolved}++ if ($_->{State} eq 'Resolved');
        $self->{global}->{total}++;

        my $feature_version = 'n/a';
        my $feature_installed = 'n/a';
        if (defined($features->{ $name . '-feature' })) {
            my @keys = keys %{$features->{ $name . '-feature' }};
            my $version = shift(@keys);
            $feature_installed = ($features->{ $name . '-feature' }->{$version}->{Installed} =~ /1|true/i ? 'yes' : 'no');
            $feature_version = $features->{ $name . '-feature' }->{$version}->{Version};
        }

        $self->{bundles}->{ $_->{ID} } = {
            name => $name,
            status => lc($_->{State}),
            version => $_->{Version},
            feature_installed => $feature_installed,
            feature_version => $feature_version
        };
    }

    if (scalar(keys %{$self->{bundles}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No bundles found");
        $self->{output}->option_exit();
    }
}

1;

=head1 MODE

Check bundle status.

=over 8

=item B<--filter-instance>

Filter the Karaf instances by name (can be a regexp).

=item B<--filter-id>

Filter bundles by ID (can be a regexp).

=item B<--filter-name>

Filter bundles by name (can be a regexp).

=item B<--filter-symbolic-name>

Filter bundles by symbolic name (can be a regexp).

=item B<--warning-status>

Set warning threshold for status.
Can use special variables like: %{status}, %{name}, %{version}, %{feature_installed}, %{feature_version}.

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} !~ /^(active|resolved)/i').
Can use special variables like: %{status}, %{name}, %{version}, %{feature_installed}, %{feature_version}.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'bundles-failed', 'bundles-active', 'bundles-resolved'.

=back

=cut