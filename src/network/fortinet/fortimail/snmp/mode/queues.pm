#
# Copyright 2022 Centreon (http://www.centreon.com/)
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

package network::fortinet::fortimail::snmp::mode::queues;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_queue_output {
    my ($self, %options) = @_;

    return "Queue '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'queue', type => 1, cb_prefix_output => 'prefix_queue_output', message_multiple => 'All queues are ok' }
    ];

    $self->{maps_counters}->{queue} = [
        { label => 'count', nlabel => 'queue.mails.count', set => {
                key_values      => [ { name => 'count' }, { name => 'display' } ],
                output_template => 'mails: %s',
                perfdatas       => [
                    { template => '%d', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'size', nlabel => 'queue.mails.size.count', set => {
                key_values      => [ { name => 'size' }, { name => 'display' } ],
                output_template => 'size: %s %s',
                output_change_bytes => 1,
                perfdatas       => [
                    { template => '%d', unit => 'B', min => 0, label_extra_instance => 1, instance_use => 'display' }
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

my $mapping = {
    fmlMailQueueMailCount => { oid => '.1.3.6.1.4.1.12356.105.1.103.2.1.3' },
    fmlMailQueueMailSize  => { oid => '.1.3.6.1.4.1.12356.105.1.103.2.1.4' }
};
my $oid_fmlMailQueueEntry = '.1.3.6.1.4.1.12356.105.1.103.2.1';
my $oid_fmlMailQueueName = '.1.3.6.1.4.1.12356.105.1.103.2.1.2';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_fmlMailQueueName },
            { oid => $oid_fmlMailQueueEntry }
        ],
        nothing_quit => 1
    );

    $self->{queue} = {};
    foreach my $oid (keys %{$snmp_result->{$oid_fmlMailQueueName}}) {
        next if ($oid !~ /^$oid_fmlMailQueueName\.(.*)/);
        my $instance = $1;

       next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $snmp_result->{$oid_fmlMailQueueName}->{$oid} !~ /$self->{option_results}->{filter_name}/);

        my $result = $options{snmp}->map_instance(
            mapping  => $mapping,
            results  => $snmp_result->{$oid_fmlMailQueueEntry},
            instance => $instance
        );

        $self->{queue}->{$instance} = {
            display => $snmp_result->{$oid_fmlMailQueueName}->{$oid},
            count   => $result->{'fmlMailQueueMailCount'},
            size    => $result->{'fmlMailQueueMailSize'} * 1024
        };
    }

    if (scalar(keys %{$self->{queue}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No queue found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check queue statistics.

=over 8

=item B<--filter-name>

Filter queue name (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'count', 'size'.

=back

=cut
