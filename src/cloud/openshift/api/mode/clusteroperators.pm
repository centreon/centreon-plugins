#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package cloud::openshift::api::mode::clusteroperators;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc qw(is_excluded exprintf);
use centreon::plugins::constants qw(:counters);

sub custom_options_threshold {
    my ($self, %options) = @_;

    my $check = $self->{thlabel};

    my $value = $self->{result_values}->{ $self->{key_values}->[0]->{name} } // '';

    my $status = $self->{perfdata}->threshold_check(
        value => $value, threshold => [
            { label => "critical-$check", exit_litteral => 'critical' },
            { label => "warning-$check",  exit_litteral => 'warning' },
            { label => "unknown-$check",  exit_litteral => 'unknown' }
        ]
    );

    if ($self->{instance_mode}->{verbose_requested} || $status ne 'ok') {
        $self->{instance_mode}->{display_details}->{$check} = 1;
        $self->{output}->{option_results}->{verbose} = 1;
    }

    return $status;
}

sub custom_output_detail {
    my ($self, %options) = @_;

    my $id = $options{id};

    my ($counter) = grep { $_->{label} eq $id } @{$self->{maps_counters}->{global}};
    $counter = $counter->{set} if $counter;
    my $msg = exprintf($counter->{output_template}, $self->{global});

    return $msg unless $self->{display_details}->{$id} && ref $self->{$id} eq 'ARRAY' && @{$self->{$id}};

    $self->{output}->output_add( long_msg => exprintf($options{title}, $self->{global}) );

    my $tmpl = $self->{option_results}->{show_details}
               ? "    %{name}\n      Reason: %{reason}\n      Message: %{message}"
               : "    %{name}";


    $self->{output}->output_add( long_msg => join "\n", map { exprintf($tmpl, $_) }
                                                        sort { $a->{name} cmp $b->{name} }
                                                        @{$self->{$id}} );
    return $msg;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, use_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "include-name:s"   => { name => 'include_name',  default => '' },
        "exclude-name:s"   => { name => 'exclude_name',  default => '' },
        "show-details"     => { name => 'show_details' }
    });

    $self->{display_details} = {};
    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    $self->SUPER::check_options(%options);

    $self->{verbose_requested} = $self->{output}->is_verbose();
}


sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL, }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'clusteroperators-total', nlabel => 'clusteroperators.total.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'Total: %{total}',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'clusteroperators-available', nlabel => 'clusteroperators.available.count', set => {
                key_values => [ { name => 'available' } ],
                closure_custom_output => sub { $self->custom_output_detail( id => 'clusteroperators-available',
                                                                            title => 'Available operators (%{available}):' ) },
                closure_custom_threshold_check => $self->can('custom_options_threshold'),
                output_template => 'Available: %{available}',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'clusteroperators-unavailable', nlabel => 'clusteroperators.unavailable.count',
                critical_default => '@1:',
            set => {
                key_values => [ { name => 'unavailable' } ],
                closure_custom_output => sub { $self->custom_output_detail( id => 'clusteroperators-unavailable',
                                                                            title => 'Unavailable operators (%{unavailable}):' ) },
                closure_custom_threshold_check => $self->can('custom_options_threshold'),
                output_template => 'Unavailable: %{unavailable}',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'clusteroperators-degraded', nlabel => 'clusteroperators.degraded.count', set => {
                key_values => [ { name => 'degraded' } ],
                closure_custom_output => sub { $self->custom_output_detail( id => 'clusteroperators-degraded',
                                                                            title => 'Degraded operators (%{degraded}):' ) },
                closure_custom_threshold_check => $self->can('custom_options_threshold'),
                output_template => 'Degraded: %{degraded}',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'clusteroperators-progressing', nlabel => 'clusteroperators.progressing.count', set => {
                key_values => [ { name => 'progressing' } ],
                closure_custom_output => sub { $self->custom_output_detail( id => 'clusteroperators-progressing',
                                                                            title => 'Progressing operators (%{progressing}):' ) },
                closure_custom_threshold_check => $self->can('custom_options_threshold'),
                output_template => 'Progressing: %{progressing}',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'clusteroperators-not-upgradeable', nlabel => 'clusteroperators.notupgradeable.count', set => {
                key_values => [ { name => 'not_upgradeable' } ],
                closure_custom_output => sub { $self->custom_output_detail( id => 'clusteroperators-not-upgradeable',
                                                                            title => 'Not upgradeable operators (%{not_upgradeable}):' ) },
                closure_custom_threshold_check => $self->can('custom_options_threshold'),
                output_template => 'Not upgradeable: %{not_upgradeable}',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{display_details} = {};

    $self->{global} = {
        total => 0,
        available => 0,
        unavailable => 0,
        degraded => 0,
        progressing => 0,
        not_upgradeable => 0
    };

    $self->{"clusteroperators-available"} = [];
    $self->{"clusteroperators-unavailable"} = [];
    $self->{"clusteroperators-degraded"} = [];
    $self->{"clusteroperators-not-upgradeable"} = [];
    $self->{"clusteroperators-progressing"} = [];

    my $results = $options{custom}->openshift_list_clusteroperators();

    foreach my $co (@{$results}) {
        my $name = $co->{metadata}->{name};

        next if is_excluded($name, $self->{option_results}->{include_name}, $self->{option_results}->{exclude_name}, output => $self->{output});

        $self->{global}->{total}++;

        my $conditions = $co->{status}->{conditions};
        next unless ref $conditions eq 'ARRAY';

        foreach my $cond (@{$conditions}) {
            my $type = lc $cond->{type};
            next unless exists $self->{global}->{$type};

            my $status = $cond->{status};
            $status =~ s/True/1/gi;
            $status =~ s/False/0/gi;

            if ($type eq 'available' and !$status) {
                $type = 'unavailable'
            } elsif ($type eq 'upgradeable') {
                next if $status;
                $type = 'not-upgradeable';
            } elsif (!$status) {
                next
            }

            $self->{global}->{$type} ++;
            push @{$self->{"clusteroperators-$type"}}, {   name => $name,
                                                           reason => $cond->{reason} // '',
                                                           message => ($cond->{message} // '') =~ s/[\r\n]+/ /gmr
                                                       };
        }
    }
}

1;

__END__

=head1 MODE

Monitor C<OpenShift ClusterOperators> health, operator availability, degradation, and upgrade readiness.

=over 8

=item B<--include-name>

Include operator name (can be a regexp).

=item B<--exclude-name>

Exclude operator name (can be a regexp).

=item B<--warning-clusteroperators-total>

Threshold.

=item B<--critical-clusteroperators-total>

Threshold.

=item B<--warning-clusteroperators-available>

Threshold.

=item B<--critical-clusteroperators-available>

Threshold.

=item B<--warning-clusteroperators-unavailable>

Threshold.

=item B<--critical-clusteroperators-unavailable>

Threshold (default: '@1:').

=item B<--warning-clusteroperators-degraded>

Threshold.

=item B<--critical-clusteroperators-degraded>

Threshold.

=item B<--warning-clusteroperators-progressing>

Threshold.

=item B<--critical-clusteroperators-progressing>

Threshold.

=item B<--warning-clusteroperators-not-upgradeable>

Threshold.

=item B<--critical-clusteroperators-not-upgradeable>

Threshold.

=back

=cut
