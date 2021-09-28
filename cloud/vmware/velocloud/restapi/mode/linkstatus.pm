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

package cloud::vmware::velocloud::restapi::mode::linkstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "status is '%s' [vpn state: '%s'] [backup state: '%s']",
        $self->{result_values}->{state},
        $self->{result_values}->{vpn_state},
        $self->{result_values}->{backup_state}
    );
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'edges', type => 3, cb_prefix_output => 'prefix_edge_output', cb_long_output => 'long_output',
          message_multiple => 'All edges links status are ok', indent_long_output => '    ',
            group => [
                { name => 'global', type => 0 },
                { name => 'links', display_long => 1, cb_prefix_output => 'prefix_link_output',
                  message_multiple => 'All links status are ok', type => 1 }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'edge-links-count', nlabel => 'edge.links.total.count', set => {
                key_values => [ { name => 'link_count' } ],
                output_template => '%s link(s)',
                perfdatas => [ { template => '%d', unit => '', min => 0 } ]
            }
        }
    ];

    $self->{maps_counters}->{links} = [
        {
            label => 'status',
            type => 2,
            critical_default => '%{state} !~ /STABLE/ || %{vpn_state} !~ /STABLE/',
            set => {
                key_values => [
                    { name => 'state' }, { name => 'vpn_state' }, { name => 'backup_state' },
                    { name => 'display' }, { name => 'id' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub prefix_edge_output {
    my ($self, %options) = @_;

    return "Edge '" . $options{instance_value}->{display} . "' ";
}

sub prefix_link_output {
    my ($self, %options) = @_;
    
    return "Link '" . $options{instance_value}->{display} . "' [Id: " . $options{instance_value}->{id} . "] ";
}

sub long_output {
    my ($self, %options) = @_;

    return "Checking edge '" . $options{instance_value}->{display} . "' [Id: " . $options{instance_value}->{id} . "] ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-edge-name:s' => { name => 'filter_edge_name' },
        'filter-link-name:s' => { name => 'filter_link_name' }
    });
   
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{timeframe} = defined($self->{option_results}->{timeframe}) ? $self->{option_results}->{timeframe} : 900;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->list_edges();

    $self->{edges} = {};
    foreach my $edge (@{$results}) {
        if (defined($self->{option_results}->{filter_edge_name}) && $self->{option_results}->{filter_edge_name} ne '' &&
            $edge->{name} !~ /$self->{option_results}->{filter_edge_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $edge->{name} . "'.", debug => 1);
            next;
        }

        $self->{edges}->{$edge->{name}}->{id} = $edge->{id};
        $self->{edges}->{$edge->{name}}->{display} = $edge->{name};

        my $links = $options{custom}->get_links_metrics(
            edge_id => $edge->{id},
            timeframe => $self->{timeframe}
        );

        foreach my $link (@{$links}) {
            if (defined($self->{option_results}->{filter_link_name}) && $self->{option_results}->{filter_link_name} ne '' &&
                $link->{link}->{displayName} !~ /$self->{option_results}->{filter_link_name}/) {
                $self->{output}->output_add(long_msg => "skipping '" . $edge->{id} . "'.", debug => 1);
                next;
            }

            $self->{edges}->{$edge->{name}}->{global}->{link_count}++;
            $self->{edges}->{$edge->{name}}->{links}->{$link->{link}->{displayName}} = {
                id => $link->{linkId},
                display => $link->{link}->{displayName},
                state => $link->{link}->{state},
                vpn_state => $link->{link}->{vpnState},
                backup_state => defined($link->{link}->{backupState}) ? $link->{link}->{backupState} : '-'
            };
        }
    }

    if (scalar(keys %{$self->{edges}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No edge found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check edge links status.

=over 8

=item B<--filter-edge-name>

Filter edge by name (Can be a regexp).

=item B<--filter-link-name>

Filter link by name (Can be a regexp).

=item B<--unknown-status>

Set unknown threshold for status (Default: '').
Can used special variables like: %{state}, %{vpn_state}, %{backup_state}.

=item B<--warning-*> B<--critical-*>

Warning & Critical thresholds
Can be 'status', 'edge-links-count'.

For 'status', special variables can be used: %{state}, %{vpn_state}, %{backup_state}
(Critical threshold default: '%{state} !~ /STABLE/ || %{vpn_state} !~ /STABLE/').

=back

=cut
