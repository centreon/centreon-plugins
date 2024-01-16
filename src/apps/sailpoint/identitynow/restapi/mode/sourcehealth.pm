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

package apps::sailpoint::identitynow::restapi::mode::sourcehealth;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -10 => 1 } },
        { name => 'sources', type => 1, cb_prefix_output => 'custom_prefix_output', message_multiple => 'All sources health are ok' },
    ];
    
    $self->{maps_counters}->{global} = [];
    foreach ('healthy', 'error', 'failure', 'unchecked') {
        push @{$self->{maps_counters}->{global}}, {
            label => 'sources-' . $_, nlabel => 'sources.status.' . $_ . '.count', set => {
                key_values => [ { name => $_ } ],
                output_template => $_ . ': %s',
                perfdatas => [
                    { template => '%s' }
                ]
            }
        };
    }

    $self->{maps_counters}->{sources} = [
        { label => 'health-status', type => 2, critical_default => '%{status} ne "SOURCE_STATE_HEALTHY"', set => {
                key_values => [ { name => 'status' }, { name => 'id' }, { name => 'name' } ],
                output_template => "health status is '%s'",
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Number of sources ';
}

sub custom_prefix_output {
    my ($self, %options) = @_;

    return "Source '" . $options{instance_value}->{name} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'source-id:s'   => { name => 'source_id' },
        'filter-name:s' => { name => 'filter_name' },
        'filter-type:s' => { name => 'filter_type' }
    });

    return $self;
}

sub set_options {
    my ($self, %options) = @_;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = { healthy => 0, error => 0, failure => 0, unchecked => 0 };

    my $sources = $options{custom}->get_sources(id => $self->{option_results}->{source_id});

    foreach my $source (@{$sources}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $source->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $source->{name} . "': no matching filter name.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
            $source->{type} !~ /$self->{option_results}->{filter_type}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $source->{type} . "': no matching filter type.", debug => 1);
            next;
        }
        
        $self->{global}->{healthy}++ if ($source->{status} eq 'SOURCE_STATE_HEALTHY');
        $self->{global}->{error}++ if ($source->{status} =~ /SOURCE_STATE_ERROR/);
        $self->{global}->{failure}++ if ($source->{status} =~ /SOURCE_STATE_FAILURE/);
        $self->{global}->{unchecked}++ if ($source->{status} =~ /SOURCE_STATE_UNCHECKED/);

        $self->{sources}->{$source->{id}} = {
            id => $source->{id},
            name => $source->{name},
            status => $source->{status}
        };
    }
}

1;

__END__

=head1 MODE

Check sources health status.

More information on 'https://developer.sailpoint.com/idn/api/v3/list-sources'.

=over 8

=item B<--source-id>

Define source ID to retrieve only one source health status (useful with service discovery).

=item B<--filter-name>

Filter source name (can be a regexp).

=item B<--filter-type>

Filter source type (can be a regexp).

=item B<--warning-health-status>

Set warning threshold for each source health status (default: none).

=item B<--critical-health-status>

Set critical threshold for each source health status (default: '%{status} ne "SOURCE_STATE_HEALTHY"').

=item B<--warning-sources-*> B<--critical-sources-*>

Set threshold for each status counter.
Can be: 'healthy', 'error', 'failure', 'unchecked'.

=back

=cut
