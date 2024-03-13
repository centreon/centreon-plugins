#
# Copyright 2023 Centreon (http://www.centreon.com/)
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

package apps::apache::karaf::api::mode::listbundles;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub get_bundle_values {
    my ($self, %options) = @_;

    if (defined($options{bundles}->{value}->{Bundles})) {
        return values(%{$options{bundles}->{value}->{Bundles}});
    }

    my @values = ();
    foreach my $entry (keys %{$options{bundles}->{value}}) {
        push @values, values(%{$options{bundles}->{value}->{$entry}->{Bundles}});
    }

    return @values;
}

sub get_features_list {
    my ($self, %options) = @_;

    if (defined($options{features}->{value}->{Features})) {
        return $options{features}->{value}->{Features};
    }

    my $features = {};
    foreach my $entry (keys %{$options{features}->{value}}) {
        $features = { %$features, %{$options{features}->{value}->{$entry}->{Features}} };
    }

    return $features;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $bundles = $options{custom}->request_api(
        method => 'POST',
        endpoint => '/jolokia/read',
        payload => {
            type => 'read',
            mbean => 'org.apache.karaf:type=bundle,name=*'
        }
    );

    my $features = $options{custom}->request_api(
        method => 'POST',
        endpoint => '/jolokia/read',
        payload => {
            type => 'read',
            mbean => 'org.apache.karaf:type=feature,name=*'
        }
    );
    my $feature_values = $self->get_features_list(features => $features);

    my $results = [];
    foreach ($self->get_bundle_values(bundles => $bundles)) {
        my $name = defined($_->{Name}) ? $_->{Name} : $_->{'Symbolic Name'};

        my $feature_version = 'n/a';
        my $feature_installed = 'n/a';
        if (defined($feature_values->{ $name . '-feature' })) {
            my @keys = keys %{$feature_values->{ $name . '-feature' }};
            my $version = shift(@keys);
            $feature_installed = ($feature_values->{ $name . '-feature' }->{$version}->{Installed} =~ /1|true/i ? 'yes' : 'no');
            $feature_version = $feature_values->{ $name . '-feature' }->{$version}->{Version};
        }

        push @$results, {
            id => $_->{ID},
            name => $name,
            symbolic_name => $_->{'Symbolic Name'},
            version => $_->{Version},
            status => lc($_->{State}),
            feature_installed => $feature_installed,
            feature_version => $feature_version
        };
    }

    return $results;
}

sub run {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(%options);
    foreach (@$results) {
        $self->{output}->output_add(
            long_msg => sprintf(
                '[id: %s][name: %s][symbolic_name: %s][version: %s][status: %s][feature_installed: %s][feature_version: %s]',
                $_->{id},
                $_->{name},
                $_->{symbolic_name},
                $_->{version},
                $_->{status},
                $_->{feature_installed},
                $_->{feature_version}
            )
        );
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List bundles:'
    );

    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['id', 'name', 'symbolic_name', 'version', 'status', 'feature_installed', 'feature_version']);
}

sub disco_show {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(%options);
    foreach (@$results) {
        $self->{output}->add_disco_entry(%$_);
    }
}

1;

=head1 MODE

List bundles.

=over 8

=back

=cut