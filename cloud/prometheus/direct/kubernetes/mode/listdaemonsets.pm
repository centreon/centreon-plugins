#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

package cloud::prometheus::direct::kubernetes::mode::listdaemonsets;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "filter-name:s"           => { name => 'filter_name' },
                                  "extra-filter:s@"         => { name => 'extra_filter' },
                                  "metric-overload:s@"      => { name => 'metric_overload' },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    $self->{metrics} = {
        'created' => '^kube_daemonset_created$',
    };
    foreach my $metric (@{$self->{option_results}->{metric_overload}}) {
        next if ($metric !~ /(.*),(.*)/);
        $self->{metrics}->{$1} = $2 if (defined($self->{metrics}->{$1}));
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $extra_filter = '';
    foreach my $filter (@{$self->{option_results}->{extra_filter}}) {
        $extra_filter .= ',' . $filter;
    }

    $self->{daemonsets} = $options{custom}->query(queries => [ '{__name__=~"' . $self->{metrics}->{created} . '"' . $extra_filter . '}' ]);
}

sub run {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $daemonset (@{$self->{daemonsets}}) {
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne ''
            && $daemonset->{metric}->{daemonset} !~ /$self->{option_results}->{filter_name}/);
        $self->{output}->output_add(long_msg => sprintf("[daemonset = %s][namespace = %s]",
            $daemonset->{metric}->{daemonset}, $daemonset->{metric}->{namespace}));
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List daemonsets:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['daemonset', 'namespace']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $daemonset (@{$self->{daemonsets}}) {
        $self->{output}->add_disco_entry(
            daemonset => $daemonset->{metric}->{daemonset},
            namespace => $daemonset->{metric}->{namespace},
        );
    }
}

1;

__END__

=head1 MODE

List daemonsets.

=over 8

=item B<--filter-name>

Filter daemonset name (Can be a regexp).

=item B<--extra-filter>

Add a PromQL filter (Can be multiple)

Example : --extra-filter='name=~".*pretty.*"'

=item B<--metric-overload>

Overload default metrics name (Can be multiple, metric can be 'labels')

Example : --metric-overload='metric,^my_metric_name$'

=back

=cut
