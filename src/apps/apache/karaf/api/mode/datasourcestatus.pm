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

package apps::apache::karaf::api::mode::datasourcestatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "status is '%s'",
        $self->{result_values}->{status}
    );
}

sub prefix_datasource_output {
    my ($self, %options) = @_;

    return sprintf(
        "Datasource '%s' [product: %s] [version: %s] ",
        $options{instance_value}->{name},
        $options{instance_value}->{product},
        $options{instance_value}->{version}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name => 'datasources',
            type => 1,
            cb_prefix_output => 'prefix_datasource_output',
            message_multiple => 'All datasources are ok'
        },
    ];

    $self->{maps_counters}->{datasources} = [
        {
            label => 'status',
            type => 2,
            critical_default => '%{status} !~ /^(OK)/i',
            set => {
                key_values => [
                    { name => 'status' },
                    { name => 'version' },
                    { name => 'product' },
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
        'filter-instance:s' => { name => 'filter_instance' },
        'filter-name:s'     => { name => 'filter_name' },
        'filter-product:s'  => { name => 'filter_product' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->request_api(
        method => 'POST',
        endpoint => '/jolokia/read',
        payload => {
            type => 'read',
            mbean => 'org.apache.karaf:type=jdbc,name=*'
        }
    );

    foreach my $entry (keys %{$result->{value}}) {
        next if ($entry !~ /name=([a-zA-Z]+)/);
        my $instance = $1;
        next if (defined($self->{option_results}->{filter_instance}) && $self->{option_results}->{filter_instance} ne ''
            && $instance !~ /$self->{option_results}->{filter_instance}/);
        
        next if (!defined($result->{value}->{$entry}->{Datasources}));
        
        foreach my $id (keys %{$result->{value}->{$entry}->{Datasources}}) {
            my $name = $result->{value}->{$entry}->{Datasources}->{$id}->{name};
            $name = $1 if ($name =~ /jdbc\/(.*)/);

            next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne ''
                && $name !~ /$self->{option_results}->{filter_name}/);
            next if (defined($self->{option_results}->{filter_product}) && $self->{option_results}->{filter_product} ne ''
                && $result->{value}->{$entry}->{Datasources}->{$id}->{product} !~ /$self->{option_results}->{filter_product}/);
            $self->{datasources}->{$id} = {
                name => $name,
                product => $result->{value}->{$entry}->{Datasources}->{$id}->{product},
                version => $result->{value}->{$entry}->{Datasources}->{$id}->{version},
                status => $result->{value}->{$entry}->{Datasources}->{$id}->{status}
            };
        }
    }

    if (scalar(keys %{$self->{datasources}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No datasources found");
        $self->{output}->option_exit();
    }
}

1;

=head1 MODE

Check datasource status.

=over 8

=item B<--filter-instance>

Filter the Karaf instances by name (can be a regexp).

=item B<--filter-name>

Filter datasources by name (can be a regexp).

The 'jdbc/' part of the name is removed.

=item B<--filter-product>

Filter datasources by product (can be a regexp).

=item B<--warning-status>

Set warning threshold for status.
Can use special variables like: %{status}, %{version}, %{product}, %{name}.

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} !~ /^(OK)/i').
Can use special variables like: %{status}, %{version}, %{product}, %{name}.

=back

=cut