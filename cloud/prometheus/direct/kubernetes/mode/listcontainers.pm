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

package cloud::prometheus::direct::kubernetes::mode::listcontainers;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                  "container:s"             => { name => 'container', default => 'container=~".*"' },
                                  "pod:s"                   => { name => 'pod', default => 'pod=~".*"' },
                                  "namespace:s"             => { name => 'namespace', default => 'namespace=~".*"' },
                                  "image:s"                 => { name => 'image', default => 'image=~".*"' },
                                  "extra-filter:s@"         => { name => 'extra_filter' },
                                  "metric-overload:s@"      => { name => 'metric_overload' },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    $self->{metrics} = {
        'info' => '^kube_pod_container_info$',
    };
    foreach my $metric (@{$self->{option_results}->{metric_overload}}) {
        next if ($metric !~ /(.*),(.*)/);
        $self->{metrics}->{$1} = $2 if (defined($self->{metrics}->{$1}));
    }

    $self->{labels} = {};
    foreach my $label (('container', 'pod', 'namespace', 'image')) {
        if ($self->{option_results}->{$label} !~ /^(\w+)[!~=]+\".*\"$/) {
            $self->{output}->add_option_msg(short_msg => "Need to specify --" . $label . " option as a PromQL filter.");
            $self->{output}->option_exit();
        }
        $self->{labels}->{$label} = $1;
    }

    $self->{extra_filter} = '';
    foreach my $filter (@{$self->{option_results}->{extra_filter}}) {
        $self->{extra_filter} .= ',' . $filter;
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{containers} = $options{custom}->query(queries => [ '{__name__=~"' . $self->{metrics}->{info} . '",' .
                                                            $self->{option_results}->{container} . ',' .
                                                            $self->{option_results}->{pod} . ',' .
                                                            $self->{option_results}->{namespace} . 
                                                            $self->{extra_filter} . '}' ]);
}

sub run {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $container (@{$self->{containers}}) {
        $self->{output}->output_add(long_msg => sprintf("[container = %s][pod = %s][namespace = %s][image = %s]",
            $container->{metric}->{$self->{labels}->{container}}, $container->{metric}->{$self->{labels}->{pod}},
            $container->{metric}->{$self->{labels}->{namespace}}, $container->{metric}->{$self->{labels}->{image}}));
    }

    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List containers:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['container', 'pod', 'namespace', 'image']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $container (@{$self->{containers}}) {
        $self->{output}->add_disco_entry(
            container => $container->{metric}->{$self->{labels}->{container}},
            pod => $container->{metric}->{$self->{labels}->{pod}},
            namespace => $container->{metric}->{$self->{labels}->{namespace}},
            image => $container->{metric}->{$self->{labels}->{image}},
        );
    }
}

1;

__END__

=head1 MODE

List containers.

=over 8

=item B<--container>

Filter on a specific container (Must be a PromQL filter, Default: 'container_name=~".*"')

=item B<--pod>

Filter on a specific pod (Must be a PromQL filter, Default: 'pod_name=~".*"')

=item B<--namespace>

Filter on a specific namespace (Must be a PromQL filter, Default: 'namespace=~".*"')

=item B<--image>

Filter on a specific image (Must be a PromQL filter, Default: 'image=~".*"')

=item B<--extra-filter>

Add a PromQL filter (Can be multiple)

Example : --extra-filter='name=~".*pretty.*"'

=item B<--metric-overload>

Overload default metrics name (Can be multiple, metric can be 'info')

Example : --metric-overload='metric,^my_metric_name$'

=back

=cut
