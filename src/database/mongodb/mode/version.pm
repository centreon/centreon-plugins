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

package database::mongodb::mode::version;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_version_output {
    my ($self, %options) = @_;

    return sprintf(
        'MongoDB version: %s',
        $self->{result_values}->{version_string}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];

    # Label is 'version-numeric' (not 'version') so that the counter
    # template generates --warning-version-numeric / --critical-version-numeric
    # and leaves --warning-version / --critical-version free for the
    # human-friendly X.Y.Z form provided below.
    $self->{maps_counters}->{global} = [
        { label => 'version-numeric', nlabel => 'mongodb.version.numeric', set => {
                key_values => [
                    { name => 'version_packed' },
                    { name => 'version_string' },
                    { name => 'version_major' },
                    { name => 'version_minor' },
                    { name => 'version_patch' }
                ],
                closure_custom_output => $self->can('custom_version_output'),
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    # Friendly options taking the X.Y[.Z] format. Distinct from
    # --warning-version-numeric / --critical-version-numeric (raw counter
    # thresholds) so that Getopt::Long auto-abbreviation cannot confuse them.
    $options{options}->add_options(arguments => {
        'minimum-version-warning:s'  => { name => 'minimum_version_warning' },
        'minimum-version-critical:s' => { name => 'minimum_version_critical' }
    });

    return $self;
}

sub _pack_version {
    my ($self, $value) = @_;

    return undef if (!defined($value) || $value eq '');

    if ($value !~ /^(\d+)\.(\d+)(?:\.(\d+))?$/) {
        $self->{output}->add_option_msg(
            short_msg => "Invalid version threshold '" . $value . "'. Expected format: X.Y[.Z]"
        );
        $self->{output}->option_exit();
    }

    return $1 * 1_000_000 + $2 * 1_000 + (defined($3) ? $3 : 0);
}

sub check_options {
    my ($self, %options) = @_;

    # Translate friendly "X.Y.Z" thresholds into the packed integer used
    # by the underlying version-numeric counter (range syntax "<min>:"
    # raises an alert when the running value is strictly lower than min).
    # We mutate %options before delegating to SUPER::check_options because
    # that method calls SUPER::init and would otherwise overwrite
    # $self->{option_results}.
    for my $level (qw(warning critical)) {
        my $val = $options{option_results}->{'minimum_version_' . $level};
        my $packed = $self->_pack_version($val);
        next if (!defined($packed));

        my $target = $level . '-version-numeric';
        if (defined($options{option_results}->{$target}) && $options{option_results}->{$target} ne '') {
            $self->{output}->add_option_msg(
                short_msg => "--minimum-version-${level} and --${level}-version-numeric are mutually exclusive."
            );
            $self->{output}->option_exit();
        }
        $options{option_results}->{$target} = $packed . ':';
    }

    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $build_info = $options{custom}->run_command(
        database => 'admin',
        command  => $options{custom}->ordered_hash(buildInfo => 1)
    );

    my $version = defined($build_info->{version}) ? $build_info->{version} : 'unknown';

    my ($major, $minor, $patch) = (0, 0, 0);
    if ($version =~ /^(\d+)\.(\d+)(?:\.(\d+))?/) {
        ($major, $minor, $patch) = ($1, $2, defined($3) ? $3 : 0);
    }

    $self->{global} = {
        version_string => $version,
        version_major  => $major,
        version_minor  => $minor,
        version_patch  => $patch,
        version_packed => $major * 1_000_000 + $minor * 1_000 + $patch
    };
}

1;

__END__

=head1 MODE

Check MongoDB server version.

The version reported by the server (C<buildInfo.version>, e.g. C<7.0.14>) is
exposed as a packed integer C<major * 1_000_000 + minor * 1_000 + patch>
(C<7.0.14> -> C<7000014>) so that classic Centreon counter thresholds work.

=over 8

=item B<--minimum-version-warning>

Friendly minimum version. Format: C<X.Y[.Z]>. The server is reported as
WARNING when the running version is strictly lower.

Example: C<--minimum-version-warning=7.0.10> warns on C<7.0.9>, C<6.x>, etc.

=item B<--minimum-version-critical>

Friendly minimum version. Format: C<X.Y[.Z]>. The server is reported as
CRITICAL when the running version is strictly lower.

Example: C<--minimum-version-critical=6.0.0> alerts critically on every C<5.x>.

=item B<--warning-version-numeric> / B<--critical-version-numeric>

Raw counter thresholds using the packed integer format (range syntax).
Equivalent to the friendly options above:
C<--warning-version-numeric=7000010:>.

The C<mongodb.version.numeric> nlabel is also accepted via
C<--warning-mongodb-version-numeric>.

=back

=cut
