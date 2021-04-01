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

package cloud::prometheus::direct::nginxingresscontroller::mode::requests;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'namespaces', type => 1, cb_prefix_output => 'prefix_namespaces_output',
          message_multiple => 'All namespaces request metrics are ok', skipped_code => { -10 => 1 } },
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'requests', nlabel => 'requests.total.persecond', set => {
                key_values => [ { name => 'requests', per_second => 1 } ],
                output_template => 'Requests: %.2f/s',
                perfdatas => [
                    { label => 'requests', template => '%.2f', min => 0, unit => 'requests/s' },
                ],
            }
        },
    ];

    $self->{maps_counters}->{namespaces} = [
        { label => 'requests-2xx', nlabel => 'namespace.requests.2xx.persecond', set => {
                key_values => [ { name => 'requests_2xx', per_second => 1 } ],
                output_template => 'Requests 2xx: %.2f/s',
                perfdatas => [
                    { label => 'requests_2xx', template => '%.2f', unit => 'requests/s', min => 0, label_extra_instance => 1 },
                ],
            }
        },
        { label => 'requests-3xx', nlabel => 'namespace.requests.2xx.persecond', set => {
                key_values => [ { name => 'requests_3xx', per_second => 1 } ],
                output_template => 'Requests 3xx: %.2f/s',
                perfdatas => [
                    { label => 'requests_3xx', template => '%.2f', unit => 'requests/s', min => 0, label_extra_instance => 1 },
                ],
            }
        },
        { label => 'requests-4xx', nlabel => 'namespace.requests.4xx.persecond', set => {
                key_values => [ { name => 'requests_4xx', per_second => 1 } ],
                output_template => 'Requests 4xx: %.2f/s',
                perfdatas => [
                    { label => 'requests_4xx', template => '%.2f', unit => 'requests/s', min => 0, label_extra_instance => 1 },
                ],
            }
        },
        { label => 'requests-5xx', nlabel => 'namespace.requests.5xx.persecond', set => {
                key_values => [ { name => 'requests_5xx', per_second => 1 } ],
                output_template => 'Requests 5xx: %.2f/s',
                perfdatas => [
                    { label => 'requests_5xx', template => '%.2f', unit => 'requests/s', min => 0, label_extra_instance => 1 },
                ],
            }
        },
    ];
}

sub prefix_namespaces_output {
    my ($self, %options) = @_;

    return "Namespace '" . $options{instance_value}->{display} . "' ";
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
        'requests_total' => '^nginx_ingress_controller_nginx_process_requests_total$',
        'requests' => '^nginx_ingress_controller_requests$',
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
            'label_replace({__name__=~"' . $self->{metrics}->{requests_total} . '",' .
                $self->{extra_filter} . '}, "__name__", "requests_total", "", "")'
        ]
    );

    foreach my $result (@{$results}) {
        $self->{global}->{requests} = ${$result->{value}}[1];
    }

    $self->{namespaces} = {};

    $results = $options{custom}->query(queries => [ 'label_replace({__name__=~"' . $self->{metrics}->{requests} . '",' .
                                                            $self->{extra_filter} . '}, "__name__", "requests", "", "")' ]);

    foreach my $result (@{$results}) {
        $self->{namespaces}->{$result->{metric}->{exported_namespace}}->{display} = $result->{metric}->{exported_namespace};
        $self->{namespaces}->{$result->{metric}->{exported_namespace}}->{requests_2xx} += ${$result->{value}}[1] if ($result->{metric}->{status} =~ /^2/);
        $self->{namespaces}->{$result->{metric}->{exported_namespace}}->{requests_3xx} += ${$result->{value}}[1] if ($result->{metric}->{status} =~ /^3/);
        $self->{namespaces}->{$result->{metric}->{exported_namespace}}->{requests_4xx} += ${$result->{value}}[1] if ($result->{metric}->{status} =~ /^4/);
        $self->{namespaces}->{$result->{metric}->{exported_namespace}}->{requests_5xx} += ${$result->{value}}[1] if ($result->{metric}->{status} =~ /^5/);
    }
}

1;

__END__

=head1 MODE

Check requests number.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'requests', 'requests-2xx', 'requests-3xx',
'requests-4xx', 'requests-5xx'.

=item B<--critical-*>

Threshold critical.
Can be: 'requests', 'requests-2xx', 'requests-3xx',
'requests-4xx', 'requests-5xx'.

=item B<--extra-filter>

Add a PromQL filter (Can be multiple)

Example : --extra-filter='name=~".*pretty.*"'

=item B<--metric-overload>

Overload default metrics name (Can be multiple)

Example : --metric-overload='metric,^my_metric_name$'

Default :

    - requests_total: ^nginx_ingress_controller_nginx_process_requests_total$
    - requests: ^nginx_ingress_controller_requests$

=back

=cut
