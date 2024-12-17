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

package network::cisco::meraki::cloudcontroller::restapi::mode::discovery;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use JSON::XS;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'prettify'                   => { name => 'prettify' },
        'resource-type:s'            => { name => 'resource_type'},
        'filter-network-id:s'        => { name => 'filter_network_id' },
        'filter-organization-name:s' => { name => 'filter_organization_name' },
        'filter-organization-id:s'   => { name => 'filter_organization_id' },
        'filter-model:s'             => { name => 'filter_model' },
        'filter-tags:s'              => { name => 'filter_tags' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{resource_type}) || $self->{option_results}->{resource_type} eq '') {
        $self->{option_results}->{resource_type} = 'device';
    }
    if ($self->{option_results}->{resource_type} !~ /^device|network$/) {
        $self->{output}->add_option_msg(short_msg => 'unknown resource type');
        $self->{output}->option_exit();
    }
}

sub discovery_devices {
    my ($self, %options) = @_;

    my $devices = $options{custom}->get_devices(
        orgs => [keys %{$options{organizations}}],
        extended => 1
    );
    my $devices_statuses = $options{custom}->get_organization_device_statuses(
        orgs => [keys %{$options{organizations}}],
        extended => 1
    );

    my @results;
    foreach (values %$devices) {
        next if (defined($self->{option_results}->{filter_model}) && $self->{option_results}->{filter_model} ne '' &&
            $_->{model} !~ /$self->{option_results}->{filter_model}/);
        next if (defined($self->{option_results}->{filter_network_id}) && $self->{option_results}->{filter_network_id} ne '' &&
            $_->{networkId} !~ /$self->{option_results}->{filter_network_id}/);
        next if (defined($self->{option_results}->{filter_tags}) && $self->{option_results}->{filter_tags} ne '' &&
            (!defined($_->{tags}) || $_->{tags} !~ /$self->{option_results}->{filter_tags}/));
        next if (defined($self->{option_results}->{filter_organization_id}) && $self->{option_results}->{filter_organization_id} ne '' &&
            $_->{orgId} !~ /$self->{option_results}->{filter_organization_id}/);
        next if (defined($self->{option_results}->{filter_organization_name}) && $self->{option_results}->{filter_organization_name} ne '' &&
            $options{organizations}->{ $_->{orgId} }->{name} !~ /$self->{option_results}->{filter_organization_name}/);

        my $node = {
            name => $_->{name},
            status => $devices_statuses->{ $_->{serial} }->{status},
            address => $_->{address},
            latitude => $_->{lat},
            longitude => $_->{lng},
            mac => $_->{mac},
            url => $_->{url},
            notes => $_->{notes},
            tags => $_->{tags},
            model => $_->{model},
            firmware => $_->{firmware},
            serial => $_->{serial},
            public_ip => $devices_statuses->{ $_->{serial} }->{publicIp},
            lan_ip => $_->{lanIp},
            network_id => $_->{networkId},
            network_name => $options{networks}->{ $_->{networkId} }->{name},
            organization_name => $options{organizations}->{ $_->{orgId} }->{name},
            configuration_updated_at => $_->{configurationUpdatedAt},
            last_reported_at => $devices_statuses->{ $_->{serial} }->{lastReportedAt}
        };

        push @results, $node;
    }

    return @results;

}

sub discovery_networks {
    my ($self, %options) = @_;

    my @results;
    foreach (values %{$options{networks}}) {
        next if (defined($self->{option_results}->{filter_tags}) && $self->{option_results}->{filter_tags} ne '' &&
            (!defined($_->{tags}) || $_->{tags} !~ /$self->{option_results}->{filter_tags}/));
        next if (defined($self->{option_results}->{filter_organization_id}) && $self->{option_results}->{filter_organization_id} ne '' &&
            $_->{organizationId} !~ /$self->{option_results}->{filter_organization_id}/);
        next if (defined($self->{option_results}->{filter_organization_name}) && $self->{option_results}->{filter_organization_name} ne '' &&
            $options{organizations}->{ $_->{organizationId} }->{name} !~ /$self->{option_results}->{filter_organization_name}/);

        my $node = {
            name => $_->{name},
            id => $_->{id},
            type => $_->{type},
            timezone => $_->{timeZone},
            tags => $_->{tags},
            product_types => $_->{productTypes},
            organization_id => $_->{organizationId},
            organization_name => $options{organizations}->{ $_->{organizationId} }->{name},
            disable_remote_status_page => $_->{disableRemoteStatusPage},
            disable_my_meraki_com => $_->{disableMyMerakiCom}
        };

        push @results, $node;
    }

    return @results;
}

sub run {
    my ($self, %options) = @_;

    my @disco_data;
    my $disco_stats;

    $disco_stats->{start_time} = time();

    my $organizations = $options{custom}->get_organizations();
    my $networks = $options{custom}->get_networks(
        orgs => [keys %{$organizations}],
        extended => 1
    );

    if ($self->{option_results}->{resource_type} eq 'network') {
        @disco_data = $self->discovery_networks(
            networks => $networks,
            organizations => $organizations
        );
    } else {
        @disco_data = $self->discovery_devices(
            networks => $networks,
            organizations => $organizations,
            %options
        );
    }

    $disco_stats->{end_time} = time();
    $disco_stats->{duration} = $disco_stats->{end_time} - $disco_stats->{start_time};
    $disco_stats->{discovered_items} = @disco_data;
    $disco_stats->{results} = \@disco_data;

    my $encoded_data;
    eval {
        if (defined($self->{option_results}->{prettify})) {
            $encoded_data = JSON::XS->new->utf8->pretty->encode($disco_stats);
        } else {
            $encoded_data = JSON::XS->new->utf8->encode($disco_stats);
        }
    };
    if ($@) {
        $encoded_data = '{"code":"encode_error","message":"Cannot encode discovered data into JSON format"}';
    }
    
    $self->{output}->output_add(short_msg => $encoded_data);
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1);
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Resources discovery.

=over 8

=item B<--prettify>

Prettify JSON output.

=item B<--resource-type>

Choose the type of resources to discover (can be: 'device', 'network').

=item B<--filter-model>

Filter by model (can be a regexp).

=item B<--filter-network-id>

Filter by network ID (can be a regexp).

=item B<--filter-organization-id>

Filter by organization ID (can be a regexp).

=item B<--filter-organization-name>

Filter by organization name (can be a regexp).

=item B<--filter-tags>

Filter by tags (can be a regexp).

=back

=cut
