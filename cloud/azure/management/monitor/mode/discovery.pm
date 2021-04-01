#
# Copyright 2021 Centreon (http://www.centreon.com/)
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

package cloud::azure::management::monitor::mode::discovery;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use JSON::XS;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "namespace:s"           => { name => 'namespace' },
        "type:s"                => { name => 'type' },
        "resource-group:s"      => { name => 'resource_group' },
        "location:s"            => { name => 'location' },
        "prettify"              => { name => 'prettify' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    $self->{namespace} = $self->{option_results}->{namespace};
    $self->{type} = $self->{option_results}->{type};
    $self->{location} = $self->{option_results}->{location};
    $self->{resource_group} = $self->{option_results}->{resource_group};
}

sub run {
    my ($self, %options) = @_;

    my @disco_data;
    my $disco_stats;

    $disco_stats->{start_time} = time();

    my $resources = $options{custom}->azure_list_resources(
        namespace => $self->{namespace},
        resource_type => $self->{type},
        location => $self->{location},
        resource_group => $self->{resource_group}
    );

    $disco_stats->{end_time} = time();
    $disco_stats->{duration} = $disco_stats->{end_time} - $disco_stats->{start_time};

    foreach my $resource (@{$resources}) {
        my $resource_group = '';
        $resource_group = $resource->{resourceGroup} if (defined($resource->{resourceGroup}));
        $resource_group = $1 if ($resource_group eq '' && defined($resource->{id}) && $resource->{id} =~ /resourceGroups\/(.*)\/providers/);
        $resource->{resourceGroup} = $resource_group;

        foreach my $entry (keys %{$resource}) {
            next if (ref($resource->{$entry}) ne "HASH");
            my @array;
            foreach my $key (keys %{$resource->{$entry}}) {
                push @array, { key => $key, value => $resource->{$entry}->{$key} };
            }
            $resource->{$entry} = \@array;
        }
        push @disco_data, $resource;
    }

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

=item B<--namespace>

Specify resources namespace.

=item B<--type>

Specify resources type.

=item B<--resource-group>

Specify resources resource group.

=item B<--location>

Specify resources location.

=item B<--prettify>

Prettify JSON output.

=back

=cut
