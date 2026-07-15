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

package cloud::openshift::api::mode::projects;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc qw(is_excluded exprintf flatten_arrays);
use centreon::plugins::constants qw(:counters);
use centreon::common::kubernetes::misc qw/is_excluded_label/;

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
    $self->{output}->output_add( long_msg => join "\n", map { exprintf("    %{name}".($_->{display_name} ne '' && $_->{display_name} ne $_->{name} ? " (%{display_name})" : ""), $_) }
                                                        sort { $a->{name} cmp $b->{name} }
                                                        @{$self->{$id}} );
    return $msg;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, use_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "include-name:s"       => { name => 'include_name',       default => '' },
        "exclude-name:s"       => { name => 'exclude_name',       default => '' },
        "include-label:s@"     => { name => 'include_label' },
        "exclude-label:s@"     => { name => 'exclude_label' },
        "required-label:s@"   => { name => 'required_label' }
    });

    $self->{display_details} = {};
    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    $self->SUPER::check_options(%options);

    $self->{verbose_requested} = $self->{output}->is_verbose();

    $self->{$_} = flatten_arrays($self->{option_results}->{$_})
        foreach qw/include_label exclude_label required_label/;
}


sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL, }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'projects-total', nlabel => 'projects.total.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'Total: %{total}',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'projects-active', nlabel => 'projects.active.count', set => {
                key_values => [ { name => 'active' } ],
                closure_custom_output => sub { $self->custom_output_detail( id => 'projects-active',
                                                                            title => 'Active projects (%{active}):' ) },
                closure_custom_threshold_check => $self->can('custom_options_threshold'),
                output_template => 'Active: %{active}',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'projects-terminating', nlabel => 'projects.terminating.count', set => {
                key_values => [ { name => 'terminating' } ],
                closure_custom_output => sub { $self->custom_output_detail( id => 'projects-terminating',
                                                                            title => 'Terminating projects (%{terminating}):' ) },
                closure_custom_threshold_check => $self->can('custom_options_threshold'),
                output_template => 'Terminating: %{terminating}',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'projects-noncompliant', nlabel => 'projects.noncompliant.count',
            critical_default => '@1:',
            set => {
                key_values => [ { name => 'noncompliant' } ],
                closure_custom_output => sub { $self->custom_output_detail( id => 'projects-noncompliant',
                                                                            title => 'Projects not respecting label policy (%{noncompliant}):' ) },
                closure_custom_threshold_check => $self->can('custom_options_threshold'),
                output_template => 'Non-compliant: %{noncompliant}',
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
        active => 0,
        terminating => 0,
        noncompliant => 0
    };

    $self->{"projects-active"} = [];
    $self->{"projects-terminating"} = [];
    $self->{"projects-noncompliant"} = [];

    my $results = $options{custom}->openshift_list_projects();

    foreach my $project (@{$results}) {
        my $name = $project->{metadata}->{name};
        my $labels = $project->{metadata}->{labels} // {};
        my $labels_str = join ',', map { "$_=$labels->{$_}" } keys %$labels;
        my $annotations = $project->{metadata}->{annotations} // {};
        my $display_name = $annotations->{"openshift.io/display-name"} // $name;

        next if is_excluded($name, $self->{option_results}->{include_name}, $self->{option_results}->{exclude_name}, output => $self->{output})
                || is_excluded($display_name, $self->{option_results}->{include_name}, $self->{option_results}->{exclude_name}, output => $self->{output})
                || is_excluded_label($project, $self->{include_label}, $self->{exclude_label}, output => $self->{output}, display => $name);
        $self->{global}->{total}++;

        my $phase = lc($project->{status}->{phase} // '-');

        my $hp ={ name => $name,
                  display_name => $display_name,
                  phase => $phase,
                  uid => $project->{metadata}->{uid}
                };
        if ($phase eq 'active') {
            $self->{global}->{active}++;
            push @{$self->{"projects-active"}}, $hp;
        } elsif ($phase eq 'terminating') {
            $self->{global}->{terminating}++;
            push @{$self->{"projects-terminating"}}, $hp;
        } else {
            $self->{output}->output_add(severity => 'critical', short_msg => "Project '$name' has unexpected phase '$phase'");
        }

        my $compliant = 1;
        foreach my $label (@{$self->{required_label}}) {
            next if $label eq '';
            if ($label =~ /^([^=]+)=(.*)$/) {
                my ($key, $value) = ($1, $2 // '');
                unless (exists $labels->{$key} && $labels->{$key} eq $value) {
                    $compliant = 0;
                    last
                }
            } else {
                unless (exists $labels->{$label}) {
                    $compliant = 0;
                    last
                }
            }
        }
        unless ($compliant) {
            $self->{global}->{noncompliant}++;
            push @{$self->{"projects-noncompliant"}}, $hp;
        }
    }
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['uid', 'name', 'display_name', 'phase' ]);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $project (sort { $a->{name} cmp $b->{name} } map { @{$self->{"projects-$_"}} } qw/active terminating/) {
        $self->{output}->add_disco_entry(
            uid => $project->{uid},
            name => $project->{name},
            display_name => $project->{display_name},
            phase => $project->{phase}
        );
    }
}

1;

__END__

=head1 MODE

Monitor OpenShift Projects availability, termination status, and label compliance.

=over 8

=item B<--include-name>

Include project name (can be a regexp).

=item B<--exclude-name>

Exclude project name (can be a regexp).

=item B<--include-label>

Include projects matching the specified label filters.
Filters are provided as a comma-separated list in the format key or key=value, where both key and value may be a regexp.

=item B<--exclude-label>

Exclude projects matching the specified label filters.
Filters are provided as a comma-separated list in the format key or key=value, where both key and value may be a regexp.

=item B<--required-label>

Comma-separated list of required labels. Format: key or key=value.
Example: --required-label="owner" --required-label="environment=prod"

=item B<--warning-projects-total>

Threshold.

=item B<--critical-projects-total>

Threshold.

=item B<--warning-projects-active>

Threshold.

=item B<--critical-projects-active>

Threshold.

=item B<--warning-projects-terminating>

Threshold.

=item B<--critical-projects-terminating>

Threshold.

=item B<--warning-projects-noncompliant>

Threshold.

=item B<--critical-projects-noncompliant>

Threshold (default: '@1:').

=back

=cut
