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

package cloud::vmware::velocloud::restapi::mode::edgeqoe;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'edges', type => 3, cb_prefix_output => 'prefix_edge_output', cb_long_output => 'long_output',
          message_multiple => 'All edges links QOE are ok', indent_long_output => '    ',
            group => [
                { name => 'global', type => 0 },
                { name => 'links', display_long => 1, cb_prefix_output => 'prefix_link_output',
                  message_multiple => 'All links QOE are ok', type => 1 }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'qoe-voice-global', nlabel => 'global.qoe.voice.count', set => {
                key_values => [ { name => 'voice' } ],
                output_template => 'Global voice QOE: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 10, label_extra_instance => 1  }
                ]
            }
        },
        { label => 'qoe-video-global', nlabel => 'global.qoe.video.count', set => {
                key_values => [ { name => 'video' } ],
                output_template => 'Global video QOE: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 10, label_extra_instance => 1  }
                ]
            }
        },
        { label => 'qoe-transactional-global', nlabel => 'global.qoe.transactional.count', set => {
                key_values => [ { name => 'transactional' } ],
                output_template => 'Global transactional QOE: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 10, label_extra_instance => 1  }
                ]
            }
        },
        { label => 'edge-links-count', nlabel => 'global.links.total.count', set => {
                key_values => [ { name => 'link_count' } ],
                output_template => '%s link(s)',
                perfdatas => [
                    { template => '%d', unit => '', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{links} = [
        { label => 'qoe-voice', nlabel => 'link.qoe.voice.count', set => {
                key_values => [ { name => 'voice' }, { name => 'display' }, { name => 'id' } ],
                output_template => 'Voice QOE: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 10, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'qoe-video', nlabel => 'link.qoe.video.count', set => {
                key_values => [ { name => 'video' }, { name => 'display' }, { name => 'id' } ],
                output_template => 'Video QOE: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 10, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'qoe-transactional', nlabel => 'link.qoe.transactional.count', set => {
                key_values => [ { name => 'transactional' }, { name => 'display' }, { name => 'id' } ],
                output_template => 'Transactional QOE: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 10, label_extra_instance => 1 }
                ]
            }
        },
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

        my $links = $options{custom}->list_links(
            edge_id => $edge->{id},
            timeframe => $self->{timeframe}
        );

        my $qoes = $options{custom}->get_links_qoe(
            edge_id => $edge->{id},
            timeframe => $self->{timeframe}
        );

        next if (ref($qoes) ne 'HASH');

        $self->{edges}->{$edge->{name}}->{global} = {
            voice => $qoes->{overallLinkQuality}->{score}->{0},
            video => $qoes->{overallLinkQuality}->{score}->{1},
            transactional => $qoes->{overallLinkQuality}->{score}->{2}
        };

        foreach my $link (@{$links}) {
            next if (!defined($qoes->{$link->{link}->{internalId}}));

            if (defined($self->{option_results}->{filter_link_name}) && $self->{option_results}->{filter_link_name} ne '' &&
                $link->{link}->{displayName} !~ /$self->{option_results}->{filter_link_name}/) {
                $self->{output}->output_add(long_msg => "skipping '" . $edge->{id} . "'.", debug => 1);
                next;
            }

            $self->{edges}->{$edge->{name}}->{global}->{link_count}++;
            $self->{edges}->{$edge->{name}}->{links}->{$link->{link}->{displayName}} = {
                id => $link->{linkId},
                display => $link->{link}->{displayName},
                voice => $qoes->{$link->{link}->{internalId}}->{score}->{0},
                video => $qoes->{$link->{link}->{internalId}}->{score}->{1},
                transactional => $qoes->{$link->{link}->{internalId}}->{score}->{2}
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

Check links QOE before and global QOE after VeloCloud Enhancements.

=over 8

=item B<--filter-edge-name>

Filter edge by name (Can be a regexp).

=item B<--filter-link-name>

Filter link by name (Can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'edge-links-count', 'qoe-voice-global', 'qoe-video-global', 'qoe-transactional-global' (global values) and/or
'qoe-voice', 'qoe-video', 'qoe-transactional' (per link values).

=back

=cut