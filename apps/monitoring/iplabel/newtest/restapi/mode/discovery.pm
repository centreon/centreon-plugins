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

package apps::monitoring::iplabel::newtest::restapi::mode::discovery;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use JSON::XS;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'resource-type:s' => { name => 'resource_type' },
        'prettify'        => { name => 'prettify' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{resource_type}) || $self->{option_results}->{resource_type} eq '') {
        $self->{option_results}->{resource_type} = 'robot';
    }
    if ($self->{option_results}->{resource_type} !~ /^robot|scenario$/) {
        $self->{output}->add_option_msg(short_msg => 'unknown resource type');
        $self->{output}->option_exit();
    }
}

sub discovery_robots {
    my ($self, %options) = @_;

    my $robots = $options{custom}->request_api(endpoint => '/api/robots');

    my $nodes = {};
    foreach my $robot (@$robots) {
        $nodes->{ $robot->{Id} } = {
            id => $robot->{Id},
            name => $robot->{Name},
            description => $robot->{Description},
            comment => $robot->{Comment},
            status => $robot->{CurrentStatus}->{Value},
            company => $robot->{Company}->{Name},
            location => $robot->{Location}->{Name},
            version => $robot->{Version},
            ip => $robot->{IPAddress},
            scenarios => []
        };

        foreach (@{$options{instances}}) {
            next if ($_->{Robot}->{Id} ne $robot->{Id});
            push @{$nodes->{ $robot->{Id} }->{scenarios}}, $_->{Scenario}->{Name};
        }
    }

    return [values %$nodes];
}

sub discovery_scenarios {
    my ($self, %options) = @_;

    my $scenarios = $options{custom}->request_api(endpoint => '/api/measures');

    my $nodes = {};
    foreach my $scenario (@$scenarios) {
        $nodes->{ $scenario->{Id} } = {
            id => $scenario->{Id},
            name => $scenario->{Name},
            description => $scenario->{Description},
            robots => []
        };
        foreach (keys %{$scenario->{Properties}}) {
            $nodes->{ $scenario->{Id} }->{lc($_)} = $scenario->{Properties}->{$_};
        }

        foreach (@{$options{instances}}) {
            next if ($_->{Scenario}->{Id} ne $scenario->{Id});
            push @{$nodes->{ $scenario->{Id} }->{robots}}, $_->{Robot}->{Name};
        }
    }

    return [values %$nodes];
}

sub run {
    my ($self, %options) = @_;

    my $disco_stats;
    $disco_stats->{start_time} = time();

    my $instances = $options{custom}->request_api(endpoint => '/api/instances');

    my $results = [];
    if ($self->{option_results}->{resource_type} eq 'robot') {
        $results = $self->discovery_robots(
            custom => $options{custom},
            instances => $instances
        );
    } else {
        $results = $self->discovery_scenarios(
            custom => $options{custom},
            instances => $instances
        );
    }

    $disco_stats->{end_time} = time();
    $disco_stats->{duration} = $disco_stats->{end_time} - $disco_stats->{start_time};
    $disco_stats->{discovered_items} = scalar(@$results);
    $disco_stats->{results} = $results;

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

=item B<--resource-type>

Choose the type of resources to discover (Can be: 'robot', 'scenario').

=back

=cut
