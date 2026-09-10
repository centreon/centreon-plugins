#
# Copyright 2026 Centreon (http://www.centreon.com/)
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

package hardware::server::cisco::ucs::xmlapi::mode::auditlogs;

use strict;
use warnings;
use base qw(centreon::plugins::templates::counter);
use centreon::plugins::statefile;
use POSIX qw(mktime);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'logs',   type => 1, cb_prefix_output => 'prefix_output',
          message_multiple => 'All audit log events are ok' },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total', nlabel => 'auditlogs.total.count', set => {
            key_values      => [ { name => 'total' } ],
            output_template => 'Total audit log events: %d',
            perfdatas       => [ { template => '%d', min => 0 } ],
        }},
    ];

    $self->{maps_counters}->{logs} = [
        { label => 'status', type => 2,
          set => {
            key_values => [
                { name => 'id' }, { name => 'severity' }, { name => 'user' },
                { name => 'descr' }, { name => 'affected_obj' }, { name => 'created' },
            ],
            output_template => "audit log '%s' [user: %s] [severity: %s]: %s [affected: %s] [created: %s]",
            output_use      => ['id', 'user', 'severity', 'descr', 'affected_obj', 'created'],
            closure_custom_perfdata          => sub { return 0; },
            closure_custom_threshold_check  => \&_threshold_check,
          }
        },
    ];
}

sub _threshold_check {
    my ($self, %options) = @_;
    my %sev_map = (
        cleared   => 'OK',
        info      => 'OK',
        condition => 'OK',
        warning   => 'WARNING',
        minor     => 'WARNING',
        major     => 'CRITICAL',
        critical  => 'CRITICAL',
    );
    return $sev_map{ $self->{result_values}->{severity} } // 'UNKNOWN';
}

sub prefix_output {
    my ($self, %options) = @_;
    return "Audit log '" . $options{instance_value}->{id} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-user:s'      => { name => 'filter_user' },
        'filter-msg:s'       => { name => 'filter_msg' },
        'retention-time:s'   => { name => 'retention_time' },
        'memory'             => { name => 'memory' },
    });

    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->check_options(option_results => $self->{option_results});
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $last_time;
    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->read(statefile => 'cisco_ucs_xmlapi_auditlogs_' . $options{custom}->{hostname});
        $last_time = $self->{statefile_cache}->get(name => 'last_time');
    }

    my $logs = $options{custom}->request(class_id => 'aaaModLR');

    $self->{global} = { total => 0 };
    $self->{logs}   = {};
    my $current_time = time();

    foreach my $log (@{$logs}) {
        my $id       = $log->{id}          // 'unknown';
        my $severity = $log->{severity}    // 'info';
        my $user     = $log->{user}        // '';
        my $descr    = $log->{descr}       // '';
        my $affected = $log->{affectedObj} // '';
        my $created  = $log->{created}     // '';

        next if defined($self->{option_results}->{filter_user})
            && $self->{option_results}->{filter_user} ne ''
            && $user !~ /$self->{option_results}->{filter_user}/;

        next if defined($self->{option_results}->{filter_msg})
            && $self->{option_results}->{filter_msg} ne ''
            && $descr !~ /$self->{option_results}->{filter_msg}/;

        if (defined($self->{option_results}->{retention_time}) && $created =~ /(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})/) {
            my $log_time = mktime($6, $5, $4, $3, $2 - 1, $1 - 1900);
            next if $current_time - $log_time > $self->{option_results}->{retention_time} * 60;
        }

        if (defined($last_time) && $created =~ /(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})/) {
            my $log_time = mktime($6, $5, $4, $3, $2 - 1, $1 - 1900);
            next if $log_time <= $last_time;
        }

        $self->{global}->{total}++;
        $self->{logs}->{$id} = {
            id          => $id,
            severity    => $severity,
            user        => $user,
            descr       => $descr,
            affected_obj => $affected,
            created     => $created,
        };
    }

    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->write(data => { last_time => $current_time });
    }
}

1;

__END__

=head1 MODE

Check Cisco UCS audit logs via XML API (aaaModLR class).

=over 8

=item B<--filter-user>

Filter audit log entries by user (regexp).

=item B<--filter-msg>

Filter by description (regexp).

=item B<--retention-time>

Only report entries from the last N minutes.

=item B<--memory>

Only report new entries since last check.

=back

=cut
