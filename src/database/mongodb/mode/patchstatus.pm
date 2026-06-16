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

package database::mongodb::mode::patchstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use JSON::XS;

# Severity ranks: higher means worse. UNKNOWN is treated as neutral.
my %SEVERITY_RANK = (
    NONE     => 0,
    UNKNOWN  => 0,
    LOW      => 1,
    MEDIUM   => 2,
    HIGH     => 3,
    CRITICAL => 4
);
my @SEVERITY_BY_RANK = ('NONE', 'LOW', 'MEDIUM', 'HIGH', 'CRITICAL');

# Default in-module catalogue, kept minimalist (branches + fixed_version)
# so the plugin stays self-contained when no external catalogue is
# provided.
#
# Values are aligned with MongoDB vendor advisories and NVD CVE 2.0 data
# filtered on CPE cpe:2.3:a:mongodb:mongodb*.
#
# When CVE-level detail is required at check time, supply a full catalogue
# via --catalog-file or --catalog-url (schema centreon-mongodb-patch-catalog/1).
our $DEFAULT_CATALOG = {
    schema     => 'centreon-mongodb-patch-catalog/1',
    vendor     => 'mongodb',
    product    => 'mongodb-server',
    updated_at => '2026-06-02T00:00:00Z',
    source     => {
        vendor_advisory => 'https://www.mongodb.com/resources/products/mongodb-security-bulletins',
        nvd_search      => 'https://services.nvd.nist.gov/rest/json/cves/2.0?keywordSearch=MongoDB',
        generated_by    => 'built-in default catalogue'
    },
    branches => [
        {
            branch            => '5.0',
            vulnerable_range  => { min_inclusive => '5.0.0', max_exclusive => '5.0.33' },
            fixed_version     => '5.0.33',
            default_severity  => 'HIGH',
            cves              => []
        },
        {
            branch            => '6.0',
            vulnerable_range  => { min_inclusive => '6.0.0', max_exclusive => '6.0.28' },
            fixed_version     => '6.0.28',
            default_severity  => 'HIGH',
            cves              => []
        },
        {
            branch            => '7.0',
            vulnerable_range  => { min_inclusive => '7.0.0', max_exclusive => '7.0.34' },
            fixed_version     => '7.0.34',
            default_severity  => 'HIGH',
            cves              => []
        },
        {
            branch            => '8.0',
            vulnerable_range  => { min_inclusive => '8.0.0', max_exclusive => '8.0.23' },
            fixed_version     => '8.0.23',
            default_severity  => 'HIGH',
            cves              => []
        }
    ]
};

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'MongoDB patch status ';
}

sub prefix_member_output {
    my ($self, %options) = @_;

    return "Member '" . $options{instance_value}->{name} . "' ";
}

sub custom_member_output {
    my ($self, %options) = @_;

    my $msg = sprintf(
        "version is '%s' [branch: %s] [fixed: %s] [patched: %s]",
        $self->{result_values}->{version},
        $self->{result_values}->{branch},
        $self->{result_values}->{fixed_version},
        $self->{result_values}->{patched}
    );
    if ($self->{result_values}->{branch_known} eq 'no') {
        $msg .= ' [branch unknown in catalog]';
    } elsif ($self->{result_values}->{patched} eq 'no') {
        $msg .= sprintf(
            ' [outstanding CVE: %s] [max severity: %s]',
            $self->{result_values}->{cve_count},
            $self->{result_values}->{cve_max_severity}
        );
    }
    return $msg;
}

sub custom_member_calc {
    my ($self, %options) = @_;

    foreach my $key (qw(
        name version branch fixed_version patched branch_known
        cve_count cve_max_severity
    )) {
        $self->{result_values}->{$key} = $options{new_datas}->{ $self->{instance} . '_' . $key };
    }
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'members', type => 1, cb_prefix_output => 'prefix_member_output',
          message_multiple => 'All members run a patched MongoDB version' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'members-unpatched', nlabel => 'mongodb.members.unpatched.count',
          critical_default => '0', set => {
                key_values => [ { name => 'members_unpatched' } ],
                output_template => 'members unpatched: %s',
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
        { label => 'cve-outstanding-total', nlabel => 'mongodb.cve.outstanding.total.count',
          display_ok => 0, set => {
                key_values => [ { name => 'cve_outstanding_total' } ],
                output_template => 'outstanding CVE: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'cve-max-severity-numeric', nlabel => 'mongodb.cve.max.severity.numeric',
          display_ok => 0, set => {
                key_values => [ { name => 'cve_max_severity_numeric' } ],
                output_template => 'max severity (numeric): %s',
                perfdatas => [
                    { template => '%d', min => 0, max => 4 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{members} = [
        {
            label => 'member-patch-status',
            type => 2,
            warning_default  => '%{branch_known} eq "no" or %{cve_max_severity} eq "MEDIUM"',
            critical_default => '%{cve_max_severity} eq "HIGH" or %{cve_max_severity} eq "CRITICAL"',
            set => {
                key_values => [
                    { name => 'name' },
                    { name => 'version' },
                    { name => 'branch' },
                    { name => 'fixed_version' },
                    { name => 'patched' },
                    { name => 'branch_known' },
                    { name => 'cve_count' },
                    { name => 'cve_max_severity' }
                ],
                closure_custom_calc => $self->can('custom_member_calc'),
                closure_custom_output => $self->can('custom_member_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'member-cve-outstanding', nlabel => 'mongodb.member.cve.outstanding.count',
          display_ok => 0, set => {
                key_values => [ { name => 'cve_count' }, { name => 'name' } ],
                output_template => 'outstanding CVE: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'name' }
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
        'catalog-file:s'    => { name => 'catalog_file' },
        'catalog-url:s'     => { name => 'catalog_url' },
        'catalog-timeout:s' => { name => 'catalog_timeout', default => 10 },
        'ignore-branch:s@'  => { name => 'ignore_branch' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    if (defined($self->{option_results}->{catalog_file}) && defined($self->{option_results}->{catalog_url})
        && $self->{option_results}->{catalog_file} ne '' && $self->{option_results}->{catalog_url} ne '') {
        $self->{output}->add_option_msg(
            short_msg => '--catalog-file and --catalog-url are mutually exclusive.'
        );
        $self->{output}->option_exit();
    }

    $self->{ignored_branches} = {};
    if (defined($self->{option_results}->{ignore_branch})) {
        foreach my $entry (@{$self->{option_results}->{ignore_branch}}) {
            foreach my $branch (split(/,/, $entry)) {
                $branch =~ s/^\s+|\s+$//g;
                $self->{ignored_branches}->{$branch} = 1 if ($branch ne '');
            }
        }
    }

    $self->SUPER::check_options(%options);
}

sub pack_version {
    my ($self, $version) = @_;

    return undef if (!defined($version) || $version eq '');
    return undef if ($version !~ /^(\d+)\.(\d+)(?:\.(\d+))?/);
    return $1 * 1_000_000 + $2 * 1_000 + (defined($3) ? $3 : 0);
}

sub version_branch {
    my ($self, $version) = @_;

    return undef if (!defined($version) || $version !~ /^(\d+)\.(\d+)/);
    return $1 . '.' . $2;
}

sub load_catalog {
    my ($self, %options) = @_;

    my $source;
    my $payload;

    if (defined($self->{option_results}->{catalog_file}) && $self->{option_results}->{catalog_file} ne '') {
        $source = $self->{option_results}->{catalog_file};
        my $fh;
        if (!open($fh, '<', $source)) {
            $self->{output}->add_option_msg(
                short_msg => "Cannot open catalog file '$source': $!"
            );
            $self->{output}->option_exit();
        }
        local $/;
        $payload = <$fh>;
        close($fh);
    } elsif (defined($self->{option_results}->{catalog_url}) && $self->{option_results}->{catalog_url} ne '') {
        $source = $self->{option_results}->{catalog_url};
        $payload = $self->_http_get(url => $source);
    }

    if (!defined($payload)) {
        $self->{output}->output_add(long_msg => 'Using built-in default patch catalog.', debug => 1);
        return $DEFAULT_CATALOG;
    }

    my $catalog;
    eval { $catalog = decode_json($payload); };
    if ($@) {
        $self->{output}->add_option_msg(
            short_msg => "Cannot decode JSON catalog from '$source': $@"
        );
        $self->{output}->option_exit();
    }

    if (ref($catalog) ne 'HASH' || ref($catalog->{branches}) ne 'ARRAY') {
        $self->{output}->add_option_msg(
            short_msg => "Catalog from '$source' is missing required 'branches' array."
        );
        $self->{output}->option_exit();
    }

    return $catalog;
}

sub _http_get {
    my ($self, %options) = @_;

    my $timeout = $self->{option_results}->{catalog_timeout};
    my ($payload, $error);

    eval {
        require HTTP::Tiny;
        my $client = HTTP::Tiny->new(timeout => $timeout, agent => 'centreon-plugins/mongodb-patch-status');
        my $response = $client->get($options{url});
        if (!$response->{success}) {
            $error = sprintf(
                "HTTP %s %s",
                defined($response->{status}) ? $response->{status} : '?',
                defined($response->{reason}) ? $response->{reason} : ''
            );
        } else {
            $payload = $response->{content};
        }
    };
    if ($@) {
        $error = $@;
    }

    if (defined($error)) {
        $self->{output}->add_option_msg(
            short_msg => "Cannot fetch catalog from '$options{url}': $error"
        );
        $self->{output}->option_exit();
    }

    return $payload;
}

sub find_branch_entry {
    my ($self, %options) = @_;

    my $version_packed = $self->pack_version($options{version});
    return undef if (!defined($version_packed));

    foreach my $entry (@{$options{catalog}->{branches}}) {
        my $branch = defined($entry->{branch}) ? $entry->{branch} : '';
        # Primary match: major.minor of running version equals branch identifier.
        if ($branch ne '' && $self->version_branch($options{version}) eq $branch) {
            return $entry;
        }
        # Fallback match: explicit min_inclusive / max_exclusive range when
        # the catalog uses non-aligned branch identifiers.
        my $range = $entry->{vulnerable_range};
        if (defined($range)) {
            my $min = $self->pack_version($range->{min_inclusive});
            # max_exclusive may legitimately be missing for branches that
            # have no published fix yet; treat that as 'open ended'.
            my $max = $self->pack_version($range->{max_exclusive});
            if (defined($min) && $version_packed >= $min
                && (!defined($max) || $version_packed < $max)) {
                return $entry;
            }
        }
    }
    return undef;
}

sub outstanding_cves {
    my ($self, %options) = @_;

    my $member_packed = $self->pack_version($options{version});
    return { count => 0, max_severity => 'NONE' } if (!defined($member_packed));

    my $entry = $options{entry};
    my $cves = defined($entry->{cves}) && ref($entry->{cves}) eq 'ARRAY' ? $entry->{cves} : [];

    my $count = 0;
    my $max_rank = 0;
    my $max_name = 'NONE';

    foreach my $cve (@$cves) {
        my $fix_packed = $self->pack_version($cve->{fixed_in});
        next if (!defined($fix_packed));
        next if ($member_packed >= $fix_packed);

        $count++;
        my $sev = defined($cve->{severity}) ? uc($cve->{severity}) : 'UNKNOWN';
        my $rank = defined($SEVERITY_RANK{$sev}) ? $SEVERITY_RANK{$sev} : 0;
        if ($rank > $max_rank) {
            $max_rank = $rank;
            $max_name = $sev;
        }
    }

    # Empty (or unhelpful) CVE list: fall back to the branch's
    # default_severity so the operator still gets a usable signal when
    # the running version is below the recommended fix.
    if ($count == 0) {
        my $fix_packed = $self->pack_version($entry->{fixed_version});
        if (defined($fix_packed) && $member_packed < $fix_packed) {
            my $sev = defined($entry->{default_severity}) ? uc($entry->{default_severity}) : 'HIGH';
            my $rank = defined($SEVERITY_RANK{$sev}) ? $SEVERITY_RANK{$sev} : 3;
            return { count => 1, max_severity => $sev, max_rank => $rank };
        }
        return { count => 0, max_severity => 'NONE', max_rank => 0 };
    }

    return { count => $count, max_severity => $max_name, max_rank => $max_rank };
}

sub get_member_version {
    my ($self, %options) = @_;

    my $build_info = $options{custom}->run_command_on_host(
        host     => $options{host},
        database => 'admin',
        command  => $options{custom}->ordered_hash(buildInfo => 1)
    );

    return defined($build_info->{version}) ? $build_info->{version} : 'unknown';
}

sub manage_selection {
    my ($self, %options) = @_;

    my $catalog = $self->load_catalog();

    my $ismaster = $options{custom}->run_command(
        database => 'admin',
        command  => $options{custom}->ordered_hash(ismaster => 1)
    );

    my @members;
    if (defined($ismaster->{hosts})) {
        @members = sort(@{$ismaster->{hosts}});
        push @members, sort(@{$ismaster->{passives}}) if (defined($ismaster->{passives}));
        push @members, sort(@{$ismaster->{arbiters}}) if (defined($ismaster->{arbiters}));
    } else {
        # Standalone instance: behave as a single-member replica so the
        # mode is still usable outside of a real replica set.
        my $me = defined($ismaster->{me}) ? $ismaster->{me}
               : $options{custom}->get_hostname() . ':' . ($options{custom}->get_port() || '27017');
        push @members, $me;
    }

    my %seen;
    @members = grep { !$seen{$_}++ } @members;

    if (scalar(@members) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No members found');
        $self->{output}->option_exit();
    }

    $self->{global} = {
        members_total            => scalar(@members),
        members_unpatched        => 0,
        cve_outstanding_total    => 0,
        cve_max_severity_numeric => 0
    };
    $self->{members} = {};

    foreach my $member (@members) {
        my $version;
        if (scalar(@members) == 1 && !defined($ismaster->{hosts})) {
            # Already connected to the standalone host: no need to redial.
            $version = $options{custom}->run_command(
                database => 'admin',
                command  => $options{custom}->ordered_hash(buildInfo => 1)
            )->{version};
            $version = 'unknown' if (!defined($version));
        } else {
            eval {
                $version = $self->get_member_version(custom => $options{custom}, host => $member);
            };
            if ($@) {
                $self->{output}->output_add(long_msg => $@, debug => 1);
                $version = 'unknown';
            }
        }

        my $branch = $self->version_branch($version) || 'unknown';

        # Operator-driven exemption (e.g. a 5.0 node kept on purpose
        # for a migration window).
        if (exists($self->{ignored_branches}->{$branch})) {
            $self->{members}->{$member} = {
                name             => $member,
                version          => $version,
                branch           => $branch,
                fixed_version    => '-',
                patched          => 'ignored',
                branch_known     => 'yes',
                cve_count        => 0,
                cve_max_severity => 'NONE'
            };
            next;
        }

        my $entry = $self->find_branch_entry(catalog => $catalog, version => $version);

        if (!defined($entry)) {
            $self->{members}->{$member} = {
                name             => $member,
                version          => $version,
                branch           => $branch,
                fixed_version    => '-',
                patched          => 'unknown',
                branch_known     => 'no',
                cve_count        => 0,
                cve_max_severity => 'UNKNOWN'
            };
            next;
        }

        my $member_packed = $self->pack_version($version);
        my $fixed_packed  = $self->pack_version($entry->{fixed_version});
        my $patched = 'no';
        if (defined($member_packed) && defined($fixed_packed) && $member_packed >= $fixed_packed) {
            $patched = 'yes';
        }

        my $cve_info = $self->outstanding_cves(entry => $entry, version => $version);

        if ($patched eq 'no') {
            $self->{global}->{members_unpatched}++;
            $self->{global}->{cve_outstanding_total} += $cve_info->{count};
            $self->{global}->{cve_max_severity_numeric} = $cve_info->{max_rank}
                if ($cve_info->{max_rank} > $self->{global}->{cve_max_severity_numeric});
        }

        $self->{members}->{$member} = {
            name             => $member,
            version          => $version,
            branch           => defined($entry->{branch}) ? $entry->{branch} : $branch,
            fixed_version    => defined($entry->{fixed_version}) ? $entry->{fixed_version} : '-',
            patched          => $patched,
            branch_known     => 'yes',
            cve_count        => $cve_info->{count},
            cve_max_severity => $cve_info->{max_severity}
        };
    }
}

1;

__END__

=head1 MODE

Auto-discovery of MongoDB replica set members and comparison of each
member's running version against the patched version of its branch.

The mode connects to the seed member, discovers the replica set members
via C<ismaster>, then runs C<buildInfo> on each member to determine the
current version. Each version is matched against a patch catalog (NVD
style: vulnerable range + fixed version per branch) to decide whether
the member is patched and, if not, how serious it is.

The default catalog ships with the plugin and lists the recommended
fixed version per maintained branch (e.g. C<6.0.27>, C<7.0.28>,
C<8.0.17>). It can be replaced at runtime with C<--catalog-file> or
fetched via C<--catalog-url>.

=head2 Catalog schema

  {
    "schema": "centreon-mongodb-patch-catalog/1",
    "branches": [
      {
        "branch": "6.0",
        "vulnerable_range": { "min_inclusive": "6.0.0", "max_exclusive": "6.0.27" },
        "fixed_version": "6.0.27",
        "default_severity": "HIGH",
        "cves": [
          {
            "id": "CVE-YYYY-NNNN",
            "severity": "HIGH",
            "cvss": 7.5,
            "fixed_in": "6.0.27",
            "advisory_url": "https://jira.mongodb.org/browse/SERVER-XXXXX"
          }
        ]
      }
    ]
  }

=over 8

=item B<--catalog-file>

Path to a JSON catalog file overriding the built-in one. Useful when the
catalog is refreshed out-of-band on the poller filesystem.

=item B<--catalog-url>

HTTP/HTTPS URL pointing to a JSON catalog. The fetch uses C<HTTP::Tiny>
with the timeout from C<--catalog-timeout>. Mutually exclusive with
C<--catalog-file>.

=item B<--catalog-timeout>

Timeout (seconds) for the C<--catalog-url> fetch. Default: C<10>.

=item B<--ignore-branch>

Branch identifier to skip from the patch check, e.g.
C<--ignore-branch=5.0> for a node kept on purpose during a migration.
Can be repeated or comma-separated. Ignored members are still listed in
C<members-total> but do not count in C<members-unpatched>.

=item B<--warning-member-patch-status> / B<--critical-member-patch-status>

Define status conditions for each member. Defaults:
C<warning_default = %{branch_known} eq "no" or %{cve_max_severity} eq "MEDIUM">,
C<critical_default = %{cve_max_severity} eq "HIGH" or %{cve_max_severity} eq "CRITICAL">.

Variables: C<%{name}>, C<%{version}>, C<%{branch}>, C<%{fixed_version}>,
C<%{patched}>, C<%{branch_known}>, C<%{cve_count}>,
C<%{cve_max_severity}>.

=item B<--warning-*> B<--critical-*>

Thresholds. Can be: C<members-unpatched>, C<members-total>,
C<cve-outstanding-total>, C<cve-max-severity-numeric>,
C<member-cve-outstanding>.

The C<cve-max-severity-numeric> counter ranks severities as
C<NONE/UNKNOWN=0>, C<LOW=1>, C<MEDIUM=2>, C<HIGH=3>, C<CRITICAL=4>.

=back

=cut
