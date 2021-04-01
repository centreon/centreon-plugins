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

package cloud::prometheus::restapi::mode::expression;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_perfdata {
    my ($self, %options) = @_;
    
    foreach my $key (@{$self->{instance_mode}->{custom_keys}}) {
        $self->{output}->perfdata_add(
            label => $key,
            nlabel => $key,
            value => $self->{result_values}->{$key},
            instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{instance} : undef
        );
    }
}

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = $self->{instance_mode}->{option_results}->{output};
    while ($msg =~ /%\{(.*?)\}/g) {
        my $key = $1;
        if (defined($self->{result_values}->{$key})) {
            $msg =~ s/%\{$key\}/$self->{result_values}->{$key}/g;
        }
    }

    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{instance} = $options{new_datas}->{$self->{instance} . '_instance'};
    foreach my $key (@{$self->{instance_mode}->{custom_keys}}) {
        $self->{result_values}->{$key} = $options{new_datas}->{$self->{instance} . '_' . $key};
    }
    
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'expressions', type => 1, 
            message_multiple => 'All expressions results are ok', skipped_code => { -11 => 1 } },
    ];

    $self->{maps_counters}->{expressions} = [
        { label => 'status', set => {
                key_values => [ { name => 'instance' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => $self->can('custom_status_perfdata'),
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "query:s@"          => { name => 'query' },
        "query-range:s@"    => { name => 'query_range' },
        "instance:s"        => { name => 'instance' },
        "aggregation:s"     => { name => 'aggregation', default => 'average' },
        "output:s"          => { name => 'output' },
        "multiple-output:s" => { name => 'multiple_output' },
        "warning-status:s"  => { name => 'warning_status', default => '' },
        "critical-status:s" => { name => 'critical_status', default => '' },
    });
   
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
    if (!defined($self->{option_results}->{output}) || $self->{option_results}->{output} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify output option.");
        $self->{output}->option_exit();
    }
    
    if (!defined($self->{option_results}->{instance}) || $self->{option_results}->{instance} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify instance option.");
        $self->{output}->option_exit();
    }
    
    if (!defined($self->{option_results}->{query}) && !defined($self->{option_results}->{query_range})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify query or query-range option.");
        $self->{output}->option_exit();
    }

    $self->{custom_keys} = [];
    $self->{queries} = {};
    foreach my $query (@{$self->{option_results}->{query}}) {
        next if ($query !~ /^(\w+),(.*)/);
        $self->{queries}->{$1} = $2;
        push @{$self->{maps_counters}->{expressions}[0]->{set}->{key_values}}, { name => $1 };
        push @{$self->{custom_keys}}, $1;
    }

    $self->{query_ranges} = {};
    foreach my $query (@{$self->{option_results}->{query_range}}) {
        next if ($query !~ /^(\w+),(.*)/);
        $self->{query_ranges}->{$1} = $2;
        push @{$self->{maps_counters}->{expressions}[0]->{set}->{key_values}}, { name => $1 };
        push @{$self->{custom_keys}}, $1;
    }

    $self->{maps_counters_type}[0]->{message_multiple} = $self->{option_results}->{multiple_output} if (defined($self->{option_results}->{multiple_output}));

    $self->{prom_timeframe} = defined($self->{option_results}->{timeframe}) ? $self->{option_results}->{timeframe} : 900;
    $self->{prom_step} = defined($self->{option_results}->{step}) ? $self->{option_results}->{step} : "1m";

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{expressions} = {};
    my (@results, @queries, @query_ranges);

    foreach my $label (keys %{$self->{queries}}) {
        my $prom_query = sprintf('label_replace(%s,"__name__","%s","","")', $self->{queries}->{$label}, $label);
        push @queries, $prom_query;
    }
    foreach my $label (keys %{$self->{query_ranges}}) {
        my $prom_query = sprintf('label_replace(%s,"__name__","%s","","")', $self->{query_ranges}->{$label}, $label);
        push @query_ranges, $prom_query;
    }

    
    my $queries_results = $options{custom}->query(queries => \@queries) if (scalar(@queries) > 0);
    my $query_ranges_results = $options{custom}->query_range(queries => \@query_ranges, timeframe => $self->{prom_timeframe}, step => $self->{prom_step}) if (scalar(@query_ranges) > 0);
    push @results, @{$queries_results} if (defined($queries_results));
    push @results, @{$query_ranges_results} if (defined($query_ranges_results));

    foreach my $result (@results) {
        next if (!defined($result->{metric}->{$self->{option_results}->{instance}}));        
        my $value;
        $value = $options{custom}->compute(aggregation => $self->{option_results}->{aggregation}, values => $result->{values}) if (defined($result->{values}));
        $value = ${$result->{value}}[1] if (defined($result->{value}));
        $self->{expressions}->{$result->{metric}->{$self->{option_results}->{instance}}}->{instance} = $result->{metric}->{$self->{option_results}->{instance}};
        $self->{expressions}->{$result->{metric}->{$self->{option_results}->{instance}}}->{$result->{metric}->{__name__}} = $value;
    }

    if (scalar(keys %{$self->{expressions}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No expressions found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check expression.

Examples:

# perl centreon_plugins.pl --plugin=cloud::prometheus::restapi::plugin --mode=expression
--hostname=localhost --port=9090 --query='desired,kube_deployment_spec_replicas'
--query='available,kube_deployment_status_replicas_available' --instance='deployment'
--critical-status='%{available} < %{desired}'
--output='Deployment %{instance} Replicas Desired: %{desired}, Available: %{available}'
--multiple-output='All deployments replicas are ok'

# perl centreon_plugins.pl --plugin=cloud::prometheus::restapi::plugin --mode=expression
--hostname=localhost --port=9090 --query='last,container_cpu_usage_seconds_total{container_name!~".*POD.*"}'
--query-range='average,irate(container_cpu_usage_seconds_total{container_name!~".*POD.*"}[1m])*100' --timeframe='900'
--step='1m' --aggregation='average' --instance='name' --critical-status='%{last} > 50 || %{average} > 10'
--output='Container %{instance} CPU Average: %{average}%, Last: %{last}%'
--multiple-output='All containers CPU usage are ok'

# perl centreon_plugins.pl --plugin=cloud::prometheus::restapi::plugin --mode=expression
--hostname=localhost --port=9090 --query='usage_prct,container_memory_usage_bytes/container_spec_memory_limit_bytes*100'
--query='usage_bytes,container_memory_usage_bytes' --query='limits_bytes,container_spec_memory_limit_bytes'
--instance='name' --critical-status='%{limits_bytes} > 0 && %{usage_prct} > 10'
--output='Container %{instance} Memory usage: %{average}% [usage = %{usage_bytes}B][limits = %{limits_bytes}B]'

=over 8

=item B<--query>

Set a PromQL query. Query option must be like --query='label,query'.

=item B<--query-range>

Set a PromQL query. Query option must be like --query-range='label,query'.

This query type uses --step, --timeframe and --aggregation options to compute the values.

=item B<--instance>

Set the instance label on which the results should be calculate for (Example: --instance='name').

=item B<--output>

Set the output for each instances (Example: --output='Container %{instance} value is {label}').

=item B<--multiple-output>

Set the global output in case everything is fine for multiple instances
(Example: --multiple-output='Container %{instance} value is {label}').

=item B<--warning-status>

Set warning threshold for status (Default: '').

Can use special variables like %{instance} and any other
labels you set through --query and --query-range options.

=item B<--critical-status>

Set critical threshold for status (Default: '').

Can use special variables like %{instance} and any other
labels you set through --query and --query-range options.

=item B<--timeframe>

Set timeframe in seconds (i.e. 3600 to check last hour)
(Required for --query-range queries, Default: '900').

=item B<--step>

Set the step of the metric query (Examples: '30s', '1m', '15m', '1h')
(Required for --query-range queries, Default: '1m').

=item B<--aggregation>

Set the aggregation on metric values (Can be: 'average', 'min', 'max', 'sum')
(Required for --query-range queries, Default: 'average').

=back

=cut
