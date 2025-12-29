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

package database::mongodb::mode::vulnerabilities;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "MongoDB version %s is %s to CVE-2025-14847 (MongoBleed)",
        $self->{result_values}->{version},
        $self->{result_values}->{status}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'vulnerability', type => 0, message_separator => ' - ', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{vulnerability} = [
        {
            label => 'mongobleed-status',
            type => 2,
            warning_default => '%{status} =~ /vulnerable/i',
            critical_default => '%{status} =~ /vulnerable/i',
            set => {
                key_values => [
                    { name => 'status' }, { name => 'version' },
                    { name => 'major' }, { name => 'minor' }, { name => 'patch' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

sub check_mongobleed_vulnerability {
    my ($self, %options) = @_;

    my $version = $options{version};
    my ($major, $minor, $patch);

    # Parse version (format: x.y.z or x.y.z-xyz)
    if ($version =~ /^(\d+)\.(\d+)\.(\d+)/) {
        $major = $1;
        $minor = $2;
        $patch = $3;
    } else {
        return 'unknown';
    }

    # Check vulnerability based on version ranges
    # Versions without fix (always vulnerable)
    if ($major == 4 && $minor == 2) {
        return 'vulnerable';
    }
    if ($major == 4 && $minor == 0) {
        return 'vulnerable';
    }
    if ($major == 3 && $minor == 6) {
        return 'vulnerable';
    }

    # Version 8.2.x: vulnerable from 8.2.0 to 8.2.2
    if ($major == 8 && $minor == 2) {
        return ($patch <= 2) ? 'vulnerable' : 'patched';
    }

    # Version 8.0.x: vulnerable from 8.0.0 to 8.0.16
    if ($major == 8 && $minor == 0) {
        return ($patch <= 16) ? 'vulnerable' : 'patched';
    }

    # Version 7.0.x: vulnerable from 7.0.0 to 7.0.27
    if ($major == 7 && $minor == 0) {
        return ($patch <= 27) ? 'vulnerable' : 'patched';
    }

    # Version 6.0.x: vulnerable from 6.0.0 to 6.0.26
    if ($major == 6 && $minor == 0) {
        return ($patch <= 26) ? 'vulnerable' : 'patched';
    }

    # Version 5.0.x: vulnerable from 5.0.0 to 5.0.31
    if ($major == 5 && $minor == 0) {
        return ($patch <= 31) ? 'vulnerable' : 'patched';
    }

    # Version 4.4.x: vulnerable from 4.4.0 to 4.4.29
    if ($major == 4 && $minor == 4) {
        return ($patch <= 29) ? 'vulnerable' : 'patched';
    }

    # Other versions (not in vulnerable range)
    return 'not affected';
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->run_command(
        database => 'admin',
        command => $options{custom}->ordered_hash(buildInfo => 1)
    );

    if (!defined($result->{version})) {
        $self->{output}->add_option_msg(short_msg => "Cannot retrieve MongoDB version");
        $self->{output}->option_exit();
    }

    my $version = $result->{version};
    my ($major, $minor, $patch) = (0, 0, 0);
    
    if ($version =~ /^(\d+)\.(\d+)\.(\d+)/) {
        $major = $1;
        $minor = $2;
        $patch = $3;
    }

    my $status = $self->check_mongobleed_vulnerability(version => $version);

    $self->{vulnerability} = {
        version => $version,
        status => $status,
        major => $major,
        minor => $minor,
        patch => $patch
    };
}

1;

__END__

=head1 MODE

Check MongoDB server for known vulnerabilities (CVE-2025-14847 - MongoBleed).

The MongoBleed vulnerability (CVE-2025-14847) is a critical memory disclosure flaw
in MongoDB's zlib decompression that allows attackers to extract sensitive data
(credentials, session tokens, PII) directly from server memory without authentication.

Vulnerable versions:
- 8.2.0 - 8.2.2 (fixed in 8.2.3)
- 8.0.0 - 8.0.16 (fixed in 8.0.17)
- 7.0.0 - 7.0.27 (fixed in 7.0.28)
- 6.0.0 - 6.0.26 (fixed in 6.0.27)
- 5.0.0 - 5.0.31 (fixed in 5.0.32)
- 4.4.0 - 4.4.29 (fixed in 4.4.30)
- 4.2.x, 4.0.x, 3.6.x (no fix available)

Example:
./centreon_plugins.pl --plugin=database::mongodb::plugin --mode=vulnerabilities
    --hostname=127.0.0.1 --port=27017 --username=admin --password='xxx'

=over 8

=back

=cut
