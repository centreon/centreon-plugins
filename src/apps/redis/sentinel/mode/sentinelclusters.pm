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

package apps::redis::sentinel::mode::sentinelclusters;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "status: %s",
        $self->{result_values}->{status}
    );
}

sub prefix_cluster_output {
    my ($self, %options) = @_;

    return "cluster '" . $options{instance} . "' ";
}

sub cluster_long_output {
    my ($self, %options) = @_;

    return "checking cluster '" . $options{instance} . "'";
}

sub prefix_instance_output {
    my ($self, %options) = @_;

    return "instance '" . $options{instance} . "' ";
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'number of sentinels ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'clusters', type => 3, cb_prefix_output => 'prefix_cluster_output', cb_long_output => 'cluster_long_output', indent_long_output => '    ', message_multiple => 'All clusters are ok', 
            group => [
                { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -10 => 1 } },
                { name => 'quorum', type => 0, skipped_code => { -10 => 1 } },
                { name => 'instances', type => 1, display_long => 1, cb_prefix_output => 'prefix_instance_output', message_multiple => 'All sentinel instances are ok', skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'sentinels-detected', nlabel => 'cluster.sentinels.detected.count', set => {
                key_values => [ { name => 'num_sentinels' } ],
                output_template => 'detected: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'sentinels-sdown', nlabel => 'cluster.sentinels.subjectively_down.count', set => {
                key_values => [ { name => 'sdown' } ],
                output_template => 'subjectively down: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'sentinels-odown', nlabel => 'cluster.sentinels.objectively_down.count', set => {
                key_values => [ { name => 'odown' } ],
                output_template => 'objectively down: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{quorum} = [
        {
            label => 'quorum-status',
            type => 2,
            critical_default => '%{status} =~ /noQuorum/',
            set => {
                key_values => [ { name => 'status' }, { name => 'cluster_name' } ],
                output_template => 'quorum status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{instances} = [
        {
            label => 'status',
            type => 2,
            critical_default => '%{status} =~ /o_down|s_down|master_down|disconnected/i',
            set => {
                key_values => [
                    { name => 'status' }, { name => 'address' }, { name => 'port' }, { name => 'cluster_name' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'sentinel-ping-ok-latency', nlabel => 'cluster.sentinel.ping_ok.latency.milliseconds', set => {
                key_values => [ { name => 'ping_ok_latency' } ],
                output_template => 'last ok ping: %s ms',
                perfdatas => [
                    { template => '%d', min => 0, unit => 's', label_extra_instance => 1 }
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
        'filter-cluster-name:s' => { name => 'filter_cluster_name' }
    });

    return $self;
}

sub add_instance {
    my ($self, %options) = @_;

    my $key = $options{entry}->{ip} . ':' . $options{entry}->{port};
    $self->{clusters}->{ $options{cluster_name} }->{instances}->{$key} = {
        cluster_name => $options{cluster_name},
        address => $options{entry}->{ip},
        port => $options{entry}->{port},
        status => $options{entry}->{flags},
        ping_ok_latency => $options{entry}->{'last-ok-ping-reply'}
    };
    $self->{clusters}->{ $options{cluster_name} }->{global}->{sdown}++
        if ($options{entry}->{flags} =~ /s_down/);
    $self->{clusters}->{ $options{cluster_name} }->{global}->{odown}++
        if ($options{entry}->{flags} =~ /o_down/);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->command(command => 'sentinel masters');

    $self->{clusters} = {};
    foreach my $entry (@$results) {
        next if (defined($self->{option_results}->{filter_cluster_name}) && $self->{option_results}->{filter_cluster_name} ne ''
            && $entry->{name} !~ /$self->{option_results}->{filter_cluster_name}/);

        $self->{clusters}->{ $entry->{name} } = {
            global => { num_sentinels => $entry->{'num-other-sentinels'}, odown => 0, sdown => 0 },
            quorum => { status => 'unknown', cluster_name => $entry->{name} },
            instances => {}
        };

        my $quorum = $options{custom}->ckquorum(command => 'sentinel ckquorum ' . $entry->{name});
        if ($quorum =~ /OK \d+ usable Sentinels/m) {
            $self->{clusters}->{ $entry->{name} }->{quorum}->{status} = 'ok';
        } elsif ($quorum =~ /NOQUORUM \d+ usable Sentinels/m) {
            $self->{clusters}->{ $entry->{name} }->{quorum}->{status} = 'noQuorum';
        }

        my $sentinels = $options{custom}->command(command => 'sentinel sentinels ' . $entry->{name});
        foreach (@$sentinels) {
            $self->add_instance(cluster_name => $entry->{name}, entry => $_);
        }
    }

    if (scalar(keys %{$self->{clusters}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No sentinel cluster found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check sentinel clusters informations.

=over 8

=item B<--filter-cluster-name>

Filter clusters by name (can be a regexp).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{status}, %{address}, %{port}, %{cluster_name}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{status}, %{address}, %{port}, %{cluster_name}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} =~ /o_down|s_down|master_down|disconnected/i').
You can use the following variables: %{status}, %{address}, %{port}, %{cluster_name}

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{status}, %{address}, %{port}, %{cluster_name}

=item B<--warning-quorum-status>

Set warning threshold for quorum status.
You can use the following variables: %{status}, %{address}, %{port}, %{cluster_name}

=item B<--critical-quorum-status>

Set critical threshold for quorum status (default: '%{status} =~ /noQuorum/').
You can use the following variables: %{status}, %{cluster_name}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be:  'sentinel-ping-ok-latency', 'sentinels-sdown', 'sentinels-odown', 'sentinels-detected'.

=back

=cut
