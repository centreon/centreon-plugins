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

package storage::hp::3par::ssh::mode::uptime;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use DateTime;
use POSIX;
use centreon::plugins::misc;

my $unitdiv = { s => 1, w => 604800, d => 86400, h => 3600, m => 60 };
my $unitdiv_long = { s => 'seconds', w => 'weeks', d => 'days', h => 'hours', m => 'minutes' };

sub custom_uptime_output { 
    my ($self, %options) = @_;

    return sprintf(
        'uptime is: %s',
        centreon::plugins::misc::change_seconds(value => $self->{result_values}->{uptime}, start => 'd')
    );
}

sub custom_uptime_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => 'node.uptime.' . $unitdiv_long->{ $self->{instance_mode}->{option_results}->{unit} },
        unit => $self->{instance_mode}->{option_results}->{unit},
        instances => 'node' . $self->{result_values}->{id},
        value => floor($self->{result_values}->{uptime} / $unitdiv->{ $self->{instance_mode}->{option_results}->{unit} }),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub custom_uptime_threshold {
    my ($self, %options) = @_;

    return $self->{perfdata}->threshold_check(
        value => floor($self->{result_values}->{uptime} / $unitdiv->{ $self->{instance_mode}->{option_results}->{unit} }),
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' },
            { label => 'unknown-'. $self->{thlabel}, exit_litteral => 'unknown' }
        ]
    );
}

sub prefix_node_output {
    my ($self, %options) = @_;

    return "Node '" . $options{instance_value}->{id} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'nodes', type => 1, cb_prefix_output => 'prefix_node_output', message_multiple => 'All nodes uptime are ok' }
    ];

    $self->{maps_counters}->{nodes} = [
        { label => 'uptime', set => {
                key_values => [ { name => 'uptime' }, { name => 'id' } ],
                closure_custom_output => $self->can('custom_uptime_output'),
                closure_custom_perfdata => $self->can('custom_uptime_perfdata'),
                closure_custom_threshold_check => $self->can('custom_uptime_threshold')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-node-id:s' => { name => 'filter_node_id' },
        'unit:s'           => { name => 'unit', default => 's' },
        'timezone:s'       => { name => 'timezone' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if ($self->{option_results}->{unit} eq '' || !defined($unitdiv->{$self->{option_results}->{unit}})) {
        $self->{option_results}->{unit} = 's';
    }
    $self->{option_results}->{timezone} = 'UTC' if (!defined($self->{option_results}->{timezone}) || $self->{option_results}->{timezone} eq '');
}

sub get_diff_time {
    my ($self, %options) = @_;

    # 2021-09-16 10:50:15 MSK
    return undef if ($options{date} !~ /^\s*(\d{4})-(\d{2})-(\d{2})\s+(\d+):(\d+):(\d+)/);

    my $tz = centreon::plugins::misc::set_timezone(name => $self->{option_results}->{timezone});
    my $dt = DateTime->new(
        year       => $1,
        month      => $2,
        day        => $3,
        hour       => $4,
        minute     => $5,
        second     => $6,
        %$tz
    );
    return (time() - $dt->epoch());
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($content) = $options{custom}->execute_command(commands => ['shownode -uptime']);

    #Node -------Up Since--------
    #  0 2021-09-16 10:50:15 MSK
    #  1 2021-09-15 13:21:39 MSK
    $self->{nodes} = {};
    foreach my $line (split(/\n/, $content)) {
        next if ($line !~ /^\s*(\d+)\s+(.*)\s*$/);
        my ($node_id, $date) = ($1, $2);

        next if (defined($self->{option_results}->{filter_node_id}) && $self->{option_results}->{filter_node_id} ne '' &&
            $node_id !~ /$self->{option_results}->{filter_node_id}/);
        my $uptime = $self->get_diff_time(date => $date);
        next if (!defined($uptime));

        $self->{nodes}->{$node_id} = {
            id => $node_id,
            uptime => $uptime
        };
    }

    if (scalar(keys %{$self->{nodes}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "Couldn't get nodes uptime");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check nodes uptime.

=over 8

=item B<--filter-node-id>

Filter nodes by ID (can be a regexp).

=item B<--timezone>

Timezone options. Default is 'UTC'.

=item B<--unit>

Select the time unit for the performance data and thresholds. May be 's' for seconds, 'm' for minutes, 'h' for hours, 'd' for days, 'w' for weeks. Default is seconds.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'uptime'.

=back

=cut
