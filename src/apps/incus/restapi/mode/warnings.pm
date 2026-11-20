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

package apps::incus::restapi::mode::warnings;

use strict;
use warnings;
use base qw(centreon::plugins::templates::counter);
use centreon::plugins::constants qw(:counters);

# GET /1.0/warnings?recursion=1 entry, shortened:
# {"uuid":"e9e9da0d-2538-4351-8047-46d4a8ae4dbb","status":"new","severity":"low",
#  "count":1,"entity_url":"/1.0/instances/c1?project=default",
#  "last_seen_at":"2021-03-23T17:38:37.753398689-04:00",
#  "last_message":"Couldn't find the CGroup blkio.weight, disk priority will be ignored",
#  "type":"Couldn't find CGroup"}
# Warning.status: new, acknowledged, or resolved.
# Source: https://github.com/lxc/incus/blob/main/doc/rest-api.yaml

sub new_warnings {
    my ($warnings, $severity) = @_;

    my @selected;
    foreach my $warning (@{$warnings // []}) {
        next if (!defined($warning->{status}) || $warning->{status} ne 'new');
        if (defined($severity) && $severity ne '') {
            next if (!defined($warning->{severity}) || $warning->{severity} ne $severity);
        }
        push @selected, $warning;
    }
    return \@selected;
}

sub count_new_warnings {
    my ($warnings, $severity) = @_;

    return scalar(@{new_warnings($warnings, $severity)});
}

# One line per warning: severity, type, entity, count, last seen, message.
sub warning_detail {
    my ($warning) = @_;

    my $entity = $warning->{entity_url} // '';
    $entity =~ s{^/1\.0/}{};
    $entity =~ s{\?.*$}{};
    my $last_seen = $warning->{last_seen_at} // '';
    $last_seen =~ s/^(\d{4}-\d\d-\d\dT\d\d:\d\d).*$/$1/;

    my $detail = sprintf('[%s] %s', $warning->{severity} // '-', $warning->{type} // '-');
    $detail .= " on $entity" if ($entity ne '');
    $detail .= sprintf(' (x%s, last %s)', $warning->{count} // 1, $last_seen) if ($last_seen ne '');
    $detail .= ': ' . $warning->{last_message} if (defined($warning->{last_message}) && $warning->{last_message} ne '');
    return $detail;
}

sub warnings_exit {
    my ($count, $critical) = @_;

    $count = 0 if (!defined($count));
    if (!defined($critical) || $critical eq '~:0') {
        return ($count >= 1) ? 'critical' : 'ok';
    }
    return 'ok' if ($critical eq '');
    return undef;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-severity:s' => { name => 'filter_severity' }
    });
    return $self;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'warnings', type => COUNTER_TYPE_GLOBAL, prefix_output => 'warnings ' }
    ];

    $self->{maps_counters}->{warnings} = [
        { label => 'new', nlabel => 'incus.warnings.new.count', critical_default => '~:0', set => {
                key_values => [ { name => 'new' }, { name => 'detail' } ],
                closure_custom_output => $self->can('custom_new_output'),
                closure_custom_threshold_check => $self->can('custom_warnings_threshold'),
                perfdatas => [ { template => '%d', min => 0 } ]
            }
        }
    ];
}

# The detail is appended only when at least one new warning exists.
# output_template cannot express that.
sub custom_new_output {
    my ($self, %options) = @_;

    my $output = 'new: ' . $self->{result_values}->{new};
    $output .= ' - ' . $self->{result_values}->{detail} if ($self->{result_values}->{detail} ne '');
    return $output;
}

sub custom_warnings_threshold {
    my ($self, %options) = @_;

    my $critical = $self->{instance_mode}->{option_results}->{'critical-' . $self->{thlabel}};
    my $exit = warnings_exit($self->{result_values}->{new}, $critical);
    return $exit if (defined($exit));
    return $self->{perfdata}->threshold_check(
        value => $self->{result_values}->{new},
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' }
        ]
    );
}

sub manage_selection {
    my ($self, %options) = @_;

    my $metadata = $options{custom}->warnings();
    my $warnings = $options{custom}->filter_records(records => $metadata, name_key => 'uuid');
    my $selected = new_warnings($warnings, $self->{option_results}->{filter_severity});
    foreach my $warning (@$selected) {
        $self->{output}->output_add(long_msg => 'warning ' . ($warning->{uuid} // '-') . ' ' . warning_detail($warning));
    }
    $self->{warnings} = {
        new => scalar(@$selected),
        detail => join(' ; ', map { warning_detail($_) } @$selected)
    };
}

1;

__END__

=head1 MODE

Count warnings whose status is new, from GET /1.0/warnings?recursion=1.

Default: critical when at least one new warning exists. --filter-severity
keeps an exact severity string (the spec example is low). --filter-name matches
the warning uuid.

The output lists each new warning: severity, type, entity, count, last seen
and last message. The long output (--verbose) adds its uuid, for
incus warning ack.

=over 8

=item B<--filter-severity>

Exact severity to count. Empty counts every severity.

=item B<--warning-new>

Warning threshold for the number of new warnings. Empty by default.

=item B<--critical-new>

Critical threshold for the number of new warnings.
Default: C<~:0> (critical when the count is greater than 0).
An empty value disables this default.

=back

=cut
