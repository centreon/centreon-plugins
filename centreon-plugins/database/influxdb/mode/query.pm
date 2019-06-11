#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package database::influxdb::mode::query;

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
            instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef
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
        { name => 'queries_results', type => 1, 
            message_multiple => 'All queries results are ok', skipped_code => { -11 => 1 } },
    ];

    $self->{maps_counters}->{queries_results} = [
        { label => 'status', set => {
                key_values => [ { name => 'instance' }, { name => 'display' } ],
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
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments => {
        "query:s@"          => { name => 'query' },
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
        $self->{output}->add_option_msg(short_msg => "Need to specify --output option.");
        $self->{output}->option_exit();
    }
    
    if (!defined($self->{option_results}->{query})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify --query option.");
        $self->{output}->option_exit();
    }

    $self->{custom_keys} = [];
    $self->{queries} = {};
    foreach my $query (@{$self->{option_results}->{query}}) {
        next if ($query !~ /^(\w+),(.*)/);
        $self->{queries}->{$1} = $2;
        push @{$self->{maps_counters}->{queries_results}[0]->{set}->{key_values}}, { name => $1 };
        push @{$self->{custom_keys}}, $1;
    }

    $self->{maps_counters_type}[0]->{message_multiple} = $self->{option_results}->{multiple_output} if (defined($self->{option_results}->{multiple_output}));

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{queries_results} = {};
    my (@results, @queries);

    foreach my $label (keys %{$self->{queries}}) {
        push @queries, $self->{queries}->{$label};
    }
    
    my $queries_results = $options{custom}->query(queries => \@queries) if (scalar(@queries) > 0);

    foreach my $result (@{$queries_results}) {
        next if (!defined($result->{tags}->{$self->{option_results}->{instance}}));        
        my $value;
        $value = $options{custom}->compute(aggregation => $self->{option_results}->{aggregation}, values => $result->{values}) if (defined($result->{values}));
        $value = ${$result->{value}}[1] if (defined($result->{value}));
        
        $self->{queries_results}->{$result->{tags}->{$self->{option_results}->{instance}}}->{instance} = $result->{tags}->{$self->{option_results}->{instance}};
        $self->{queries_results}->{$result->{tags}->{$self->{option_results}->{instance}}}->{display} = $result->{tags}->{$self->{option_results}->{instance}};
        $self->{queries_results}->{$result->{tags}->{$self->{option_results}->{instance}}}->{$result->{columns}[1]} = $value;
    }
    
    if (scalar(keys %{$self->{queries_results}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No queries found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Launch queries.

Examples:

To come

=over 8

=back

=cut
