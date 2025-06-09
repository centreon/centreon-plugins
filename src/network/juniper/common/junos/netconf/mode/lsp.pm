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

package network::juniper::common::junos::netconf::mode::lsp;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use Digest::MD5 qw(md5_hex);

sub custom_lsp_perfdata {
    my ($self) = @_;

    my $instances = [];
    foreach (@{$self->{instance_mode}->{custom_perfdata_instances}}) {
        push @$instances, $self->{result_values}->{$_};
    }

    $self->{output}->perfdata_add(
        nlabel    => $self->{nlabel},
        instances => $instances,
        value     => sprintf('%d', $self->{result_values}->{ $self->{key_values}->[0]->{name} }),
        warning   => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical  => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min       => 0
    );
}

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'state: %s',
        $self->{result_values}->{lspState}
    );
}

sub lsp_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking LSP session '%s' [type: %s, srcAddress: %s, dstAddress: %s]",
        $options{instance_value}->{name},
        $options{instance_value}->{type},
        $options{instance_value}->{srcAddress},
        $options{instance_value}->{dstAddress}
    );
}

sub prefix_lsp_output {
    my ($self, %options) = @_;

    return sprintf(
        "LSP session '%s' [type: %s, srcAddress: %s, dstAddress: %s] ",
        $options{instance_value}->{name},
        $options{instance_value}->{type},
        $options{instance_value}->{srcAddress},
        $options{instance_value}->{dstAddress}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Number of LSP sessions ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name               => 'lsp', type => 3, cb_prefix_output => 'prefix_lsp_output', cb_long_output => 'lsp_long_output',
          indent_long_output => '    ', message_multiple => 'All LSP sessions are ok',
          group              => [
              { name => 'status', type => 0, skipped_code => { -10 => 1 } },
              { name => 'traffic', type => 0, skipped_code => { -10 => 1 } }
          ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'lsp-sessions-detected', display_ok => 0, nlabel => 'lsp.sessions.detected.count', set => {
            key_values      => [ { name => 'detected' } ],
            output_template => 'detected: %s',
            perfdatas       => [
                { template => '%s', min => 0 }
            ]
        }
        }
    ];

    $self->{maps_counters}->{status} = [
        {
            label            => 'status',
            type             => 2,
            critical_default => '%{lspState} !~ /up/i',
            set              => {
                key_values                     => [
                    { name => 'type' }, { name => 'name' }, { name => 'srcAddress' }, { name => 'dstAddress' },
                    { name => 'lspState' }
                ],
                closure_custom_output          => $self->can('custom_status_output'),
                closure_custom_perfdata        => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{traffic} = [
        { label => 'lsp-session-traffic', nlabel => 'lsp.session.traffic.bytespersecond', set => {
            key_values              => [ { name => 'lspBytes', per_second => 1 }, { name => 'type' }, { name => 'name' }, { name => 'srcAddress' }, { name => 'dstAddress' } ],
            output_template         => 'traffic: %s %s/s',
            output_change_bytes     => 1,
            closure_custom_perfdata => $self->can('custom_lsp_perfdata')
        }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-type:s'               => { name => 'filter_type' },
        'filter-name:s'               => { name => 'filter_name' },
        'custom-perfdata-instances:s' => { name => 'custom_perfdata_instances' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{custom_perfdata_instances}) || $self->{option_results}->{custom_perfdata_instances} eq '') {
        $self->{option_results}->{custom_perfdata_instances} = '%(type) %(name)';
    }

    $self->{custom_perfdata_instances} = $self->custom_perfdata_instances(
        option_name => '--custom-perfdata-instances',
        instances   => $self->{option_results}->{custom_perfdata_instances},
        labels      => { type => 1, name => 1, srcAddress => 1, dstAddress => 1 }
    );
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->get_lsp_infos();

    $self->{global} = { detected => 0 };
    $self->{lsp} = {};
    foreach my $item (@$result) {
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
                 $item->{name} !~ /$self->{option_results}->{filter_name}/);
        next if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
                 $item->{type} !~ /$self->{option_results}->{filter_type}/);

        $self->{lsp}->{ $item->{type} . '-' . $item->{name} } = {
            type       => $item->{type},
            name       => $item->{name},
            srcAddress => $item->{srcAddress},
            dstAddress => $item->{dstAddress},
            status     => {
                type       => $item->{type},
                name       => $item->{name},
                srcAddress => $item->{srcAddress},
                dstAddress => $item->{dstAddress},
                lspState   => $item->{lspState}
            },
            traffic    => {
                type       => $item->{type},
                name       => $item->{name},
                srcAddress => $item->{srcAddress},
                dstAddress => $item->{dstAddress},
                lspBytes   => $item->{lspBytes}
            }
        };
        $self->{global}->{detected}++;
    }

    $self->{cache_name} = 'juniper_api_' . $options{custom}->get_identifier() . '_' . $self->{mode} . '_' .
                          md5_hex(
                              (defined($self->{option_results}->{filter_counters}) ? $self->{option_results}->{filter_counters} : '') . '_' .
                              (defined($self->{option_results}->{filter_name}) ? $self->{option_results}->{filter_name} : '') . '_' .
                              (defined($self->{option_results}->{filter_type}) ? $self->{option_results}->{filter_type} : '')
                          );
}

1;

__END__

=head1 MODE

Check LSP (Label Switched Path) sessions.

=over 8

=item B<--filter-type>

Filter LSP session by type.

=item B<--filter-name>

Filter LSP session by name.

=item B<--custom-perfdata-instances>

Define perfdatas instance (default: '%(type) %(name)')

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{type}, %{name}, %{srcAddress}, %{dstAddress}, %{lspState}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{type}, %{name}, %{srcAddress}, %{dstAddress}, %{lspState}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{lspState} !~ /up/i').
You can use the following variables: %{type}, %{name}, %{srcAddress}, %{dstAddress}, %{lspState}

=item B<--warning-lsp-sessions-detected>

Define the LSP sessions detected conditions to match for the status to be WARNING.

=item B<--critical-lsp-sessions-detected>

Define the LSP sessions detected conditions to match for the status to be CRITICAL.

=item B<--warning-lsp-session-traffic>

Define the LSP session traffic conditions to match for the status to be WARNING.

=item B<--critical-lsp-session-traffic>

Define the LSP session traffic conditions to match for the status to be CRITICAL.

=back

=cut
