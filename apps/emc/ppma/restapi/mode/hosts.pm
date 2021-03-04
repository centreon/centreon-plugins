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

package apps::emc::ppma::restapi::mode::hosts;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'status: %s',
        $self->{result_values}->{status}
    );
}

sub host_long_output {
    my ($self, %options) = @_;

    return "checking host '" . $options{instance_value}->{name} . "'";
}

sub prefix_host_output {
    my ($self, %options) = @_;

    return "Host '" . $options{instance_value}->{name} . "' ";
}

sub prefix_path_output {
    my ($self, %options) = @_;

    return 'path ';
}

sub prefix_volume_output {
    my ($self, %options) = @_;

    return 'volume ';
}

sub set_counters {
    my ($self, %options) = @_;

     $self->{maps_counters_type} = [
        {
            name => 'hosts', type => 3, cb_prefix_output => 'prefix_host_output', cb_long_output => 'host_long_output', indent_long_output => '    ',
            message_multiple => 'All hosts are ok',
            group => [
                { name => 'status', type => 0, skipped_code => { -10 => 1 } },
                { name => 'path', type => 0, cb_prefix_output => 'prefix_path_output', skipped_code => { -10 => 1 } },
                { name => 'volume', type => 0, cb_prefix_output => 'prefix_volume_output', skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{status} = [
        {
            label => 'status',
            type => 2,
            critical_default => '%{status} !~ /powerPathManaged/',
            set => {
                key_values => [ { name => 'status' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{path} = [
        { label => 'paths-total', nlabel => 'host.paths.total.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'paths-dead', nlabel => 'host.paths.dead.count', set => {
                key_values => [ { name => 'dead' }, { name => 'total' } ],
                output_template => 'dead: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 'total', label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{volume} = [
        { label => 'volumes-total', nlabel => 'host.volumes.total.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'volumes-dead', nlabel => 'host.volumes.dead.count', set => {
                key_values => [ { name => 'dead' }, { name => 'total' } ],
                output_template => 'dead: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 'total', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'volumes-degraded', nlabel => 'host.volumes.degraded.count', set => {
                key_values => [ { name => 'degraded' }, { name => 'total' } ],
                output_template => 'degraded: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 'total', label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $hosts = $options{custom}->request(endpoint => '/hosts');

    $self->{hosts} = {};
    foreach my $host (@$hosts) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $host->{hostname} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $host->{hostname} . "': no matching filter.", debug => 1);
            next;
        }

        my $detail = $options{custom}->request(endpoint => '/hosts/' . $host->{id});

        $self->{hosts}->{ $host->{hostname} } = {
            name => $host->{hostname},
            status => {
                name => $host->{hostname},
                status => $detail->{state}
            },
            path => {
                total => $detail->{totalPathCount},
                dead => $detail->{deadPathCount}
            },
            volume => {
                total => $detail->{totalVolumeCount},
                dead => $detail->{deadVolumeCount},
                degraded => $detail->{degradedVolumeCount}
            }
        };
    }
}

1;

__END__

=head1 MODE

Check host powerpath informations.

=over 8

=item B<--filter-name>

Filter hosts by host name (can be a regexp).

=item B<--unknown-status>

Set unknown threshold for status.
Can used special variables like: %{status}, %{name}

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{status}, %{name}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} !~ /powerPathManaged/').
Can used special variables like: %{status}, %{name}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'paths-total', 'paths-dead',
'volumes-total', 'volumes-dead', 'volumes-degraded'.

=back

=cut
