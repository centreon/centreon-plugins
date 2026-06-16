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

package hardware::server::cisco::ucs::xmlapi::mode::faults;

use strict;
use warnings;
use base qw(centreon::plugins::templates::counter);
use centreon::plugins::statefile;
use POSIX qw(mktime);

my $severities = {
    cleared   => 'OK',
    info      => 'OK',
    condition => 'OK',
    warning   => 'WARNING',
    minor     => 'WARNING',
    major     => 'CRITICAL',
    critical  => 'CRITICAL',
};

sub custom_status_output {
    my ($self, %options) = @_;
    return sprintf(
        "fault '%s' severity '%s': %s [affected: %s] [created: %s]",
        $self->{result_values}->{id},
        $self->{result_values}->{severity},
        $self->{result_values}->{descr},
        $self->{result_values}->{affected_obj},
        $self->{result_values}->{created}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'faults', type => 1, cb_prefix_output => 'prefix_output', message_multiple => 'All faults are ok' },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total', nlabel => 'faults.total.count', set => {
            key_values => [ { name => 'total' } ],
            output_template => 'Total faults: %d',
            perfdatas => [ { template => '%d', min => 0 } ],
        }},
    ];

    $self->{maps_counters}->{faults} = [
        { label => 'status', type => 2,
          set => {
            key_values => [
                { name => 'id' }, { name => 'severity' }, { name => 'descr' },
                { name => 'affected_obj' }, { name => 'created' },
            ],
            closure_custom_output => $self->can('custom_status_output'),
            closure_custom_perfdata  => sub { return 0; },
            closure_custom_threshold_check => \&custom_threshold_check,
          }
        },
    ];
}

sub custom_threshold_check {
    my ($self, %options) = @_;
    my $sev = $self->{result_values}->{severity};
    return $severities->{$sev} // 'UNKNOWN';
}

sub prefix_output {
    my ($self, %options) = @_;
    return "Fault '" . $options{instance_value}->{id} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-msg:s'       => { name => 'filter_msg' },
        'filter-severity:s'  => { name => 'filter_severity' },
        'retention-time:s'   => { name => 'retention_time' },
        'memory'             => { name => 'memory' },
        'warning-status:s'   => { name => 'warning_status', default => '%{severity} =~ /minor|warning/i' },
        'critical-status:s'  => { name => 'critical_status', default => '%{severity} =~ /major|critical/i' },
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
        $self->{statefile_cache}->read(statefile => 'cisco_ucs_xmlapi_faults_' . $options{custom}->{hostname});
        $last_time = $self->{statefile_cache}->get(name => 'last_time');
    }

    my $faults = $options{custom}->request(class_id => 'faultInst');

    $self->{global} = { total => 0 };
    $self->{faults} = {};

    my $current_time = time();

    foreach my $fault (@{$faults}) {
        my $id       = $fault->{id}          // 'unknown';
        my $severity = $fault->{severity}    // 'unknown';
        my $descr    = $fault->{descr}       // '';
        my $affected = $fault->{affectedObj} // '';
        my $created  = $fault->{created}     // '';

        next if defined($self->{option_results}->{filter_msg})
            && $self->{option_results}->{filter_msg} ne ''
            && $descr !~ /$self->{option_results}->{filter_msg}/;

        next if defined($self->{option_results}->{filter_severity})
            && $self->{option_results}->{filter_severity} ne ''
            && $severity !~ /$self->{option_results}->{filter_severity}/;

        next if $severity eq 'cleared';

        if (defined($self->{option_results}->{retention_time}) && $created =~ /(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})/) {
            my $fault_time = mktime($6, $5, $4, $3, $2 - 1, $1 - 1900);
            next if $current_time - $fault_time > $self->{option_results}->{retention_time} * 60;
        }

        if (defined($last_time) && $created =~ /(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})/) {
            my $fault_time = mktime($6, $5, $4, $3, $2 - 1, $1 - 1900);
            next if $fault_time <= $last_time;
        }

        $self->{global}->{total}++;
        $self->{faults}->{$id} = {
            id          => $id,
            severity    => $severity,
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

Check Cisco UCS faults via XML API (faultInst class).

=over 8

=item B<--filter-msg>

Filter faults by description (regexp).

=item B<--filter-severity>

Filter faults by severity (regexp).

=item B<--retention-time>

Only report faults created within the last N minutes.

=item B<--memory>

Only report new faults since last check (requires statefile).

=item B<--warning-status>

Warning threshold on fault status (default: '%{severity} =~ /minor|warning/i').

=item B<--critical-status>

Critical threshold on fault status (default: '%{severity} =~ /major|critical/i').

=back

=cut
