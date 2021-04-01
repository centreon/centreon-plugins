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

package apps::mq::rabbitmq::restapi::mode::vhostusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use URI::Encode;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = 'status: ' . $self->{result_values}->{status};
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'vhost', type => 1, cb_prefix_output => 'prefix_vhost_output', message_multiple => 'All vhosts are ok', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{vhost} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'queue-msg', nlabel => 'vhost.queue.messages.count', set => {
                key_values => [ { name => 'queue_messages' }, { name => 'display' } ],
                output_template => 'current queue messages : %s',
                perfdatas => [
                    { label => 'queue_msg', value => 'queue_messages', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'queue-msg-ready', nlabel => 'vhost.queue.messages.ready.count', set => {
                key_values => [ { name => 'queue_messages_ready' }, { name => 'display' } ],
                output_template => 'current queue messages ready : %s',
                perfdatas => [
                    { label => 'queue_msg_ready', value => 'queue_messages_ready', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_vhost_output {
    my ($self, %options) = @_;

    return "Vhost '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s'     => { name => 'filter_name' },
        'warning-status:s'  => { name => 'warning_status', default => '' },
        'critical-status:s' => { name => 'critical_status', default => '%{status} ne "ok"' },
    });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->query(url_path => '/api/vhosts');

    my $uri = URI::Encode->new({encode_reserved => 1});
    $self->{vhost} = {};
    foreach (@$result) {
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' 
            && $_->{name} !~ /$self->{option_results}->{filter_name}/);

        my $result_alive = $options{custom}->query(url_path => '/api/aliveness-test/' . $uri->encode($_->{name}));

        $self->{vhost}->{$_->{name}} = {
            display => $_->{name},
            queue_messages_ready => $_->{messages_ready},
            queue_messages => $_->{messages},
            status => $result_alive->{status}
        };
    }

    if (scalar(keys %{$self->{vhost}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No vhost found');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check vhost usage.

=over 8

=item B<--filter-name>

Filter vhost name (Can use regexp).

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{status}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} ne "ok"').
Can used special variables like: %{status}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'queue-msg-ready', 'queue-msg'.

=back

=cut
