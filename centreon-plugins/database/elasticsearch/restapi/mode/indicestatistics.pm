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

package database::elasticsearch::restapi::mode::indicestatistics;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    return "Status '" . $self->{result_values}->{status} . "'";
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};    
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'indices', type => 1, cb_prefix_output => 'prefix_indices_output', message_multiple => 'All indices are ok' },
    ];
    
    $self->{maps_counters}->{indices} = [
         { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'documents-total', nlabel => 'indice.documents.total.count', set => {
                key_values => [ { name => 'docs_count' }, { name => 'display' } ],
                output_template => 'Documents: %d',
                perfdatas => [
                    { value => 'docs_count', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'data-size-primaries', nlabel => 'indice.data.primaries.size.bytes', set => {
                key_values => [ { name => 'size_in_bytes_primaries' }, { name => 'display' } ],
                output_template => 'Data Primaries: %s%s',
                output_change_bytes => 1,
                perfdatas => [
                    { value => 'size_in_bytes_primaries', template => '%s',
                      min => 0, unit => 'B', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'data-size-total', nlabel => 'indice.data.total.size.bytes', set => {
                key_values => [ { name => 'size_in_bytes_total' }, { name => 'display' } ],
                output_template => 'Data Total: %s%s',
                output_change_bytes => 1,
                perfdatas => [
                    { value => 'size_in_bytes_total', template => '%s',
                      min => 0, unit => 'B', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'shards-active', nlabel => 'shards.active.count', set => {
                key_values => [ { name => 'shards_active' }, { name => 'display' } ],
                output_template => 'Shards Active: %d',
                perfdatas => [
                    { value => 'shards_active', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'shards-unassigned', nlabel => 'shards.unassigned.count', set => {
                key_values => [ { name => 'shards_unassigned' }, { name => 'display' } ],
                output_template => 'Shards Unassigned: %d',
                perfdatas => [
                    { value => 'shards_unassigned', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "filter-name:s"       => { name => 'filter_name' },
        "warning-status:s"    => { name => 'warning_status', default => '%{status} =~ /yellow/i' },
        "critical-status:s"   => { name => 'critical_status', default => '%{status} =~ /red/i' },
    });
   
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub prefix_indices_output {
    my ($self, %options) = @_;
    
    return "Indices '" . $options{instance_value}->{display} . "' ";
}

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{indices} = {};
    
    my $indices = $options{custom}->get(path => '/_cluster/health?level=indices');
    my $stats = $options{custom}->get(path => '/_stats');

    foreach my $indice (keys %{$indices->{indices}}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $indice !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $indice . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{indices}->{$indice} = { 
            display => $indice,
            status => $indices->{indices}->{$indice}->{status},
            shards_active => $indices->{indices}->{$indice}->{active_shards},
            shards_unassigned => $indices->{indices}->{$indice}->{unassigned_shards},
            docs_count => $stats->{indices}->{$indice}->{primaries}->{docs}->{count},
            size_in_bytes_primaries => $stats->{indices}->{$indice}->{primaries}->{store}->{size_in_bytes},
            size_in_bytes_total => $stats->{indices}->{$indice}->{total}->{store}->{size_in_bytes},
        };
    }
    
    if (scalar(keys %{$self->{indices}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No indices found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check indices statistics.

=over 8

=item B<--filter-name>

Filter name (can be a regexp).

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^status$'

=item B<--warning-*>

Threshold warning.
Can be: 'documents-total', 'data-size-primaries',
'data-size-total', 'shards-active', 'shards-unassigned'.

=item B<--critical-*>

Threshold critical.
Can be: 'documents-total', 'data-size-primaries',
'data-size-total', 'shards-active', 'shards-unassigned'.

=item B<--warning-status>

Set warning threshold for status (Default: '%{status} =~ /yellow/i')
Can used special variables like: %{display}, %{status}.

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /red/i').
Can used special variables like: %{display}, %{status}.

=back

=cut
