#
## Copyright 2021 Centreon (http://www.centreon.com/)
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

package apps::graylog::restapi::mode::notifications;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'System notifications ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'notifications-total', nlabel => 'graylog.system.notifications.total.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total: %s',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        { label => 'notifications-normal', nlabel => 'graylog.system.notifications.normal.count', set => {
                key_values => [ { name => 'normal' } ],
                output_template => 'normal: %s',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        { label => 'notifications-urgent', nlabel => 'graylog.system.notifications.urgent.count', set => {
                key_values => [ { name => 'urgent' } ],
                output_template => 'urgent: %s',
                perfdatas => [
                    { template => '%d', min => 0 },
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
        'filter-severity:s' => { name => 'filter_severity' },
        'filter-node:s'     => { name => 'filter_node' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->request_api(endpoint => 'system/notifications');

    $self->{global} = { normal => 0, urgent => 0 };
    foreach my $notification (@{$result->{notifications}}) {
    	next if (defined($self->{option_results}->{filter_severity})
            && $self->{option_results}->{filter_severity} ne ''
            && $notification->{severity} !~ /$self->{option_results}->{filter_severity}/);

        next if (defined($self->{option_results}->{filter_node})
            && $self->{option_results}->{filter_node} ne ''
            && $notification->{node_id} !~ /$self->{option_results}->{filter_node}/);

        $self->{global}->{normal}++ if ($notification->{severity} =~ /normal/);
        $self->{global}->{urgent}++ if ($notification->{severity} =~ /urgent/);	
    }

    $self->{global}->{total} = $self->{global}->{normal} + $self->{global}->{urgent};
}

1;

__END__

=head1 MODE

Check Graylog system notifications using Graylog API

Example:
perl centreon_plugins.pl --plugin=apps::graylog::restapi::plugin
--mode=notifications --hostname=10.0.0.1 --api-username='username' --api-password='password' 

More information on https://docs.graylog.org/en/<version>/pages/configuration/rest_api.html

=over 8

=item B<--filter-severity>

Filter on specific notification severity.
Can be 'normal' or 'urgent'.
(Default: both severities shown).

=item B<--filter-node>

Filter notifications by node ID.
(Default: all notifications shown).

=item B<--warning-notifications-*>

Set warning threshold for notifications count (Default: '') where '*' can be 'total', 'normal'  or 'urgent'.

=item B<--critical-notifications-*>

Set critical threshold for notifications count (Default: '') where '*' can be 'total', 'normal'  or 'urgent'.

=back

=cut
