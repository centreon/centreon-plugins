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
# Author : CHEN JUN , aladdin.china@gmail.com

package apps::kingdee::eas::mode::transaction;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'active', nlabel => 'transactions.active.count', set => {
                key_values => [ { name => 'active_count' } ],
                output_template => 'active: %s',
                perfdatas => [
                    { value => 'active_count', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'timedout', nlabel => 'transactions.timedout.count', display_ok => 0, set => {
                key_values => [ { name => 'timedout_count' } ],
                output_template => 'timed out: %s',
                perfdatas => [
                    { value => 'timedout_count', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'committed', nlabel => 'transactions.committed.count', set => {
                key_values => [ { name => 'committed_count', diff => 1 } ],
                output_template => 'committed: %s',
                perfdatas => [
                    { value => 'committed_count', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'rolledback', nlabel => 'transactions.rolledback.count', set => {
                key_values => [ { name => 'rolledback_count', diff => 1 } ],
                output_template => 'rolledback: %s',
                perfdatas => [
                    { value => 'rolledback_count', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'created', nlabel => 'transactions.created.count', set => {
                key_values => [ { name => 'transaction_count', diff => 1 } ],
                output_template => 'created: %s',
                perfdatas => [
                    { value => 'transaction_count', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'time-total', nlabel => 'transactions.time.total.milliseconds', set => {
                key_values => [ { name => 'total_transaction_time', diff => 1 } ],
                output_template => 'total time: %s ms',
                perfdatas => [
                    { value => 'total_transaction_time', template => '%s', min => 0, unit => 'ms' },
                ],
            }
        },
        { label => 'time-max', nlabel => 'transactions.time.max.milliseconds', display_ok => 0, set => {
                key_values => [ { name => 'max_transaction_time', diff => 1 } ],
                output_template => 'max time: %s ms',
                perfdatas => [
                    { value => 'max_transaction_time', template => '%s', min => 0, unit => 'ms' },
                ],
            }
        },
        { label => 'timeout-default', nlabel => 'transactions.timeout.default.count', display_ok => 0, set => {
                key_values => [ { name => 'default_timeout' } ],
                output_template => 'default timeout: %s',
                perfdatas => [
                    { value => 'default_timeout', template => '%s', min => 0 },
                ],
            }
        },
    ];
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'transactions ';
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'urlpath:s' => { name => 'url_path', default => "/easportal/tools/nagios/checktransaction.jsp" },
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $webcontent = $options{custom}->request(path => $self->{option_results}->{url_path});
    if ($webcontent !~ /TransactionCount=\d+/i) {
        $self->{output}->add_option_msg(short_msg => 'Cannot find transaction status.');
        $self->{output}->option_exit();
    }

    $self->{global} = {};
    $self->{global}->{transaction_count} = $1 if ($webcontent =~ /TransactionCount=(\d+)\s/i);
    $self->{global}->{total_transaction_time} = $1 if ($webcontent =~ /TotalTransactionTime=(\d+)\s/i);
    $self->{global}->{committed_count} = $1 if ($webcontent =~ /CommittedCount=(\d+)\s/i);
    $self->{global}->{rolledback_count} = $1 if ($webcontent =~ /RolledbackCount=(\d+)\s/i);
    $self->{global}->{active_count} = $1 if ($webcontent =~ /ActiveCount=(\d+)\s/i);
    $self->{global}->{max_transaction_time} = $1 if ($webcontent =~ /MaxTransactionTime=(\d+)\s/i);
    $self->{global}->{default_timeout} = $1 if ($webcontent =~ /DefaultTimeout=(\d+)\s/i);
    $self->{global}->{timedout_count} = $1 if ($webcontent =~ /TimedOutCount=(\d+)\s/i);

    $self->{cache_name} = 'kingdee_' . $self->{mode} . '_' . $options{custom}->get_hostname() . '_' . $options{custom}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check EAS application EJB transaction status.

=over 8

=item B<--urlpath>

Set path to get status page. (Default: '/easportal/tools/nagios/checktransaction.jsp')

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'active', 'timedout', 'committed',
'rolledback', 'created', 'time-total', 'time-max', 
'timeout-default'.

=back

=cut
