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

package database::mongodb::mode::patchdrift;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'MongoDB patch drift ';
}

sub prefix_member_output {
    my ($self, %options) = @_;

    return "Member '" . $options{instance_value}->{name} . "' ";
}

sub custom_member_output {
    my ($self, %options) = @_;

    my $msg = sprintf(
        "version is '%s' [reference: %s] [drift: %s]",
        $self->{result_values}->{version},
        $self->{result_values}->{reference_version},
        $self->{result_values}->{drift}
    );
    if (defined($self->{result_values}->{below_minimum})
        && $self->{result_values}->{below_minimum} ne 'no'
        && $self->{result_values}->{below_minimum} ne '') {
        $msg .= sprintf(" [below minimum: %s]", $self->{result_values}->{below_minimum});
    }
    return $msg;
}

sub custom_member_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{name} = $options{new_datas}->{ $self->{instance} . '_name' };
    $self->{result_values}->{version} = $options{new_datas}->{ $self->{instance} . '_version' };
    $self->{result_values}->{reference_version} = $options{new_datas}->{ $self->{instance} . '_reference_version' };
    $self->{result_values}->{drift} = $options{new_datas}->{ $self->{instance} . '_drift' };
    $self->{result_values}->{below_minimum} = $options{new_datas}->{ $self->{instance} . '_below_minimum' };

    return 0;
}

sub custom_member_version_output {
    my ($self, %options) = @_;

    return sprintf(
        "version numeric: %s",
        $self->{result_values}->{version_packed}
    );
}

sub custom_member_version_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{name} = $options{new_datas}->{ $self->{instance} . '_name' };
    $self->{result_values}->{version_packed} = $options{new_datas}->{ $self->{instance} . '_version_packed' };

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'members', type => 1, cb_prefix_output => 'prefix_member_output',
          message_multiple => 'All members have the same MongoDB version' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'drift-members', nlabel => 'mongodb.members.version.drift.count', critical_default => '0', set => {
                key_values => [ { name => 'drift_members' } ],
                output_template => 'members in drift: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'members-total', nlabel => 'mongodb.members.total.count', display_ok => 0, set => {
                key_values => [ { name => 'members_total' } ],
                output_template => 'members total: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'members-below-minimum', nlabel => 'mongodb.members.below.minimum.count', display_ok => 0, set => {
                key_values => [ { name => 'members_below_minimum' } ],
                output_template => 'members below minimum: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{members} = [
        {
            label => 'member-version-status',
            type => 2,
            critical_default => '%{drift} eq "yes" or %{below_minimum} eq "critical"',
            warning_default => '%{below_minimum} eq "warning"',
            set => {
                key_values => [
                    { name => 'name' },
                    { name => 'version' },
                    { name => 'reference_version' },
                    { name => 'drift' },
                    { name => 'below_minimum' }
                ],
                closure_custom_calc => $self->can('custom_member_calc'),
                closure_custom_output => $self->can('custom_member_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'member-version-numeric', nlabel => 'mongodb.member.version.numeric', display_ok => 0, set => {
                key_values => [
                    { name => 'version_packed' },
                    { name => 'name' }
                ],
                closure_custom_calc => $self->can('custom_member_version_calc'),
                closure_custom_output => $self->can('custom_member_version_output'),
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1, instance_use => 'name' }
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
        'reference-version:s'         => { name => 'reference_version' },
        'minimum-version-warning:s'   => { name => 'minimum_version_warning' },
        'minimum-version-critical:s'  => { name => 'minimum_version_critical' }
    });

    return $self;
}

sub pack_version {
    my ($self, $version) = @_;

    return 0 if (!defined($version) || $version !~ /^(\d+)\.(\d+)(?:\.(\d+))?/);
    return $1 * 1_000_000 + $2 * 1_000 + (defined($3) ? $3 : 0);
}

sub _check_version_format {
    my ($self, $value) = @_;

    return undef if (!defined($value) || $value eq '');
    if ($value !~ /^(\d+)\.(\d+)(?:\.(\d+))?$/) {
        $self->{output}->add_option_msg(
            short_msg => "Invalid version threshold '" . $value . "'. Expected format: X.Y[.Z]"
        );
        $self->{output}->option_exit();
    }
    return $self->pack_version($value);
}

sub check_options {
    my ($self, %options) = @_;

    # Validate minimum version threshold formats. Comparison itself is
    # performed in manage_selection where each member version is known.
    $self->{minimum_packed_warning}  = $self->_check_version_format($options{option_results}->{minimum_version_warning});
    $self->{minimum_packed_critical} = $self->_check_version_format($options{option_results}->{minimum_version_critical});

    $self->SUPER::check_options(%options);
}

sub get_member_version {
    my ($self, %options) = @_;

    my $build_info = $options{custom}->run_command_on_host(
        host => $options{host},
        database => 'admin',
        command => $options{custom}->ordered_hash(buildInfo => 1)
    );

    return defined($build_info->{version}) ? $build_info->{version} : 'unknown';
}

sub manage_selection {
    my ($self, %options) = @_;

    my $ismaster = $options{custom}->run_command(
        database => 'admin',
        command => $options{custom}->ordered_hash(ismaster => 1)
    );

    if (!defined($ismaster->{me}) || !defined($ismaster->{hosts})) {
        $self->{output}->add_option_msg(short_msg => 'No replication detected');
        $self->{output}->option_exit();
    }

    my @members = sort(@{$ismaster->{hosts}});
    push @members, sort(@{$ismaster->{passives}}) if (defined($ismaster->{passives}));
    push @members, sort(@{$ismaster->{arbiters}}) if (defined($ismaster->{arbiters}));

    my %seen;
    @members = grep { !$seen{$_}++ } @members;

    if (scalar(@members) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No members found');
        $self->{output}->option_exit();
    }

    my %versions;
    foreach my $member (@members) {
        eval {
            $versions{$member} = $self->get_member_version(custom => $options{custom}, host => $member);
        };
        if ($@) {
            $self->{output}->output_add(long_msg => $@, debug => 1);
            $versions{$member} = 'unknown';
        }
    }

    my $reference_version = $self->{option_results}->{reference_version};
    if (!defined($reference_version) || $reference_version eq '') {
        my @known_versions = sort {
            $self->pack_version($b) <=> $self->pack_version($a)
        } grep { $_ ne 'unknown' } values(%versions);
        $reference_version = scalar(@known_versions) > 0 ? $known_versions[0] : 'unknown';
    }

    $self->{global} = {
        drift_members => 0,
        members_total => scalar(@members),
        members_below_minimum => 0
    };
    $self->{members} = {};

    foreach my $member (@members) {
        my $version = $versions{$member};
        my $drift = ($version ne $reference_version) ? 'yes' : 'no';
        $self->{global}->{drift_members}++ if ($drift eq 'yes');

        my $version_packed = $self->pack_version($version);
        my $below_minimum = 'no';
        if (defined($self->{minimum_packed_critical}) && $version_packed < $self->{minimum_packed_critical}) {
            $below_minimum = 'critical';
        } elsif (defined($self->{minimum_packed_warning}) && $version_packed < $self->{minimum_packed_warning}) {
            $below_minimum = 'warning';
        }
        $self->{global}->{members_below_minimum}++ if ($below_minimum ne 'no');

        $self->{members}->{$member} = {
            name => $member,
            version => $version,
            reference_version => $reference_version,
            drift => $drift,
            below_minimum => $below_minimum,
            version_packed => $version_packed
        };
    }
}

1;

__END__

=head1 MODE

Check MongoDB version patch drift across replica set members.

The mode connects to the seed member, discovers replica set members with the
C<ismaster> command, then runs C<buildInfo> on each member to compare their
MongoDB versions.

By default, the reference version is the highest version found in the replica
set. Any member with a different version is reported as drift.

=over 8

=item B<--reference-version>

Explicit version used as reference instead of the highest discovered version.
Example: C<--reference-version=7.0.14>.

=item B<--minimum-version-warning>

Friendly minimum version (format C<X.Y[.Z]>). A member is flagged
C<warning> when its version is strictly lower than this threshold.
Example: C<--minimum-version-warning=6.0.30>.

=item B<--minimum-version-critical>

Friendly minimum version (format C<X.Y[.Z]>). A member is flagged
C<critical> when its version is strictly lower than this threshold.
Example: C<--minimum-version-critical=6.0.0>.

=item B<--warning-member-version-status> / B<--critical-member-version-status>

Define status conditions for each member. Defaults:
C<warning_default = %{below_minimum} eq "warning">,
C<critical_default = %{drift} eq "yes" or %{below_minimum} eq "critical">.

You can use the following variables: C<%{name}>, C<%{version}>,
C<%{reference_version}>, C<%{drift}>, C<%{below_minimum}>.

=item B<--warning-drift-members> / B<--critical-drift-members>

Thresholds on the number of members with version drift.
Default: C<--critical-drift-members=0> (critical when any drift exists).

=item B<--warning-members-below-minimum> / B<--critical-members-below-minimum>

Thresholds on the number of members below the minimum version.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: C<drift-members>, C<members-total>, C<members-below-minimum>,
C<member-version-numeric>.

=back

=cut
