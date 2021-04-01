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

package cloud::prometheus::direct::nginxingresscontroller::mode::connections;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_containers_output' },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'reading', nlabel => 'connections.reading.count', set => {
                key_values => [ { name => 'reading' } ],
                output_template => 'Reading: %d',
                perfdatas => [
                    { label => 'reading',template => '%d', min => 0, unit => 'connections' },
                ],
            }
        },
        { label => 'waiting', nlabel => 'connections.waiting.count', set => {
                key_values => [ { name => 'waiting' } ],
                output_template => 'Waiting: %d',
                perfdatas => [
                    { label => 'waiting', template => '%d', min => 0, unit => 'connections' },
                ],
            }
        },
        { label => 'writing', nlabel => 'connections.writing.count', set => {
                key_values => [ { name => 'writing' } ],
                output_template => 'Writing: %d',
                perfdatas => [
                    { label => 'writing', template => '%d', min => 0, unit => 'connections' },
                ],
            }
        },
        { label => 'active', nlabel => 'connections.active.count', set => {
                key_values => [ { name => 'active' } ],
                output_template => 'Active: %d',
                perfdatas => [
                    { label => 'active', template => '%d', min => 0, unit => 'connections' },
                ],
            }
        },
        { label => 'accepted', nlabel => 'connections.accepted.persecond', set => {
                key_values => [ { name => 'accepted', per_second => 1 } ],
                output_template => 'Accepted: %.2f/s',
                perfdatas => [
                    { label => 'accepted', template => '%.2f', min => 0, unit => 'connections/s' },
                ],
            }
        },
        { label => 'handled', nlabel => 'connections.handled.persecond', set => {
                key_values => [ { name => 'handled', per_second => 1 } ],
                output_template => 'Handled: %.2f/s',
                perfdatas => [
                    { label => 'handled', template => '%.2f', min => 0, unit => 'connections/s' },
                ],
            }
        },
    ];
}

sub prefix_containers_output {
    my ($self, %options) = @_;

    return "Connections ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'extra-filter:s@'    => { name => 'extra_filter' },
        'metric-overload:s@' => { name => 'metric_overload' },
    });
   
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
    $self->{metrics} = {
        'connections' => '^nginx_ingress_controller_nginx_process_connections$',
        'connections_total' => '^nginx_ingress_controller_nginx_process_connections_total$',
    };
    foreach my $metric (@{$self->{option_results}->{metric_overload}}) {
        next if ($metric !~ /(.*),(.*)/);
        $self->{metrics}->{$1} = $2 if (defined($self->{metrics}->{$1}));
    }

    $self->{extra_filter} = '';
    foreach my $filter (@{$self->{option_results}->{extra_filter}}) {
        $self->{extra_filter} .= ',' . $filter;
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = "prometheus_nginxingresscontroller_" . md5_hex($options{custom}->get_connection_info()) . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));

    $self->{global} = {};

    my $results = $options{custom}->query(
        queries => [
            'label_replace({__name__=~"' . $self->{metrics}->{connections} . '",' .
                $self->{extra_filter} . '}, "__name__", "connections", "", "")',
            'label_replace({__name__=~"' . $self->{metrics}->{connections_total} . '",' .
                $self->{extra_filter} . '}, "__name__", "connections_total", "", "")'
        ]
    );

    foreach my $result (@{$results}) {
        $self->{global}->{$result->{metric}->{state}} = ${$result->{value}}[1];
    }
}

1;

__END__

=head1 MODE

Check connections number.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'reading', 'waiting', 'writing', 'active',
'accepted', 'handled'.

=item B<--critical-*>

Threshold critical.
Can be: 'reading', 'waiting', 'writing', 'active',
'accepted', 'handled'.

=item B<--extra-filter>

Add a PromQL filter (Can be multiple)

Example : --extra-filter='name=~".*pretty.*"'

=item B<--metric-overload>

Overload default metrics name (Can be multiple)

Example : --metric-overload='metric,^my_metric_name$'

Default :

    - connections: ^nginx_ingress_controller_nginx_process_connections$
    - connections_total: ^nginx_ingress_controller_nginx_process_connections_total$

=back

=cut
