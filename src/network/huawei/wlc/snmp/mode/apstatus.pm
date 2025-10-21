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

package network::huawei::wlc::snmp::mode::apstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = 'status: ' . $self->{result_values}->{runstate};
    return $msg;
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Access points ';
}

sub ap_long_output {
    my ($self, %options) = @_;

    return "checking access point '" . $options{instance_value}->{display} . "'";
}

sub prefix_ap_output {
    my ($self, %options) = @_;

    return "access point '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name                 => 'ap',
            type               => 3,
            cb_prefix_output   => 'prefix_ap_output',
            cb_long_output     => 'ap_long_output',
            indent_long_output => '    ',
            message_multiple   => 'All access points are ok',
            group              => [
                { name => 'ap_global', type => 0 }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total', nlabel => 'accesspoints.total.count', set => {
            key_values      => [ { name => 'total' } ],
            output_template => 'total: %s',
            perfdatas       => [
                { label => 'total', template => '%s', min => 0 }
            ]
        }
        },
        { label => 'total-idle', nlabel => 'accesspoints.idle.count', set => {
            key_values      => [ { name => 'idle' } ],
            output_template => 'idle: %s',
            perfdatas       => [
                { label => 'total_idle', template => '%s', min => 0 }
            ]
        }
        },
        { label => 'total-autofind', nlabel => 'accesspoints.autofind.count', set => {
            key_values      => [ { name => 'autofind' } ],
            output_template => 'autofind: %s',
            perfdatas       => [
                { label => 'total_autofind', template => '%s', min => 0 }
            ]
        }
        },
        { label => 'total-typeNotMatch', nlabel => 'accesspoints.typenotmatch.count', display_ok => 0, set => {
            key_values      => [ { name => 'typeNotMatch' } ],
            output_template => 'type not match: %s',
            perfdatas       => [
                { label => 'total_type_not_match', template => '%s', min => 0 }
            ]
        }
        },
        { label => 'total-fault', nlabel => 'accesspoints.fault.count', set => {
            key_values      => [ { name => 'fault' } ],
            output_template => 'fault: %s',
            perfdatas       => [
                { label => 'total_fault', template => '%s', min => 0 }
            ]
        }
        },
        { label => 'total-config', nlabel => 'accesspoints.config.count', set => {
            key_values      => [ { name => 'config' } ],
            output_template => 'config: %s',
            perfdatas       => [
                { label => 'total_config', template => '%s', min => 0 }
            ]
        }
        },
        { label => 'total-config-failed', nlabel => 'accesspoints.configfailed.count', set => {
            key_values      => [ { name => 'configFailed' } ],
            output_template => 'config failed: %s',
            perfdatas       => [
                { label => 'total_config_failed', template => '%s', min => 0 }
            ]
        }
        },
        { label => 'total-download', nlabel => 'accesspoints.download.count', set => {
            key_values      => [ { name => 'download' } ],
            output_template => 'download: %s',
            perfdatas       => [
                { label => 'total_download', template => '%s', min => 0 }
            ]
        }
        },
        { label => 'total-normal', nlabel => 'accesspoints.normal.count', set => {
            key_values      => [ { name => 'normal' } ],
            output_template => 'normal: %s',
            perfdatas       => [
                { label => 'total_normal', template => '%s', min => 0 }
            ]
        }
        },
        { label => 'total-committing', nlabel => 'accesspoints.committing.count', set => {
            key_values      => [ { name => 'committing' } ],
            output_template => 'committing: %s',
            perfdatas       => [
                { label => 'total_committing', template => '%s', min => 0 }
            ]
        }
        },
        { label => 'total-commit-failed', nlabel => 'accesspoints.commitfailed.count', set => {
            key_values      => [ { name => 'commitFailed' } ],
            output_template => 'commit failed: %s',
            perfdatas       => [
                { label => 'total_commit_failed', template => '%s', min => 0 }
            ]
        }
        },
        { label => 'total-standby', nlabel => 'accesspoints.standby.count', set => {
            key_values      => [ { name => 'standby' } ],
            output_template => 'standby: %s',
            perfdatas       => [
                { label => 'total_standby', template => '%s', min => 0 }
            ]
        }
        },
        { label => 'total-version-mismatch', nlabel => 'accesspoints.vermismatch.count', set => {
            key_values      => [ { name => 'verMismatch' } ],
            output_template => 'version mismatch: %s',
            perfdatas       => [
                { label => 'total_version_mismatch', template => '%s', min => 0 }
            ]
        }
        },
        { label => 'total-name-conflicted', nlabel => 'accesspoints.nameconflicted.count', set => {
            key_values      => [ { name => 'nameConflicted' } ],
            output_template => 'name conflicted: %s',
            perfdatas       => [
                { label => 'total_name_conflicted', template => '%s', min => 0 }
            ]
        }
        },
        { label => 'total-invalid', nlabel => 'accesspoints.invalid.count', set => {
            key_values      => [ { name => 'invalid' } ],
            output_template => 'invalid: %s',
            perfdatas       => [
                { label => 'total_invalid', template => '%s', min => 0 }
            ]
        }
        },
        { label => 'total-country-code-mismatch', nlabel => 'accesspoints.countrycodemismatch.count', set => {
            key_values      => [ { name => 'countryCodeMismatch' } ],
            output_template => 'country code mismatch: %s',
            perfdatas       => [
                { label => 'total_country_code_mismatch', template => '%s', min => 0 }
            ]
        }
        }
    ];

    $self->{maps_counters}->{ap_global} = [
        { label              => 'status',
            type             => 2,
            critical_default => '%{runstate} =~ /fault|configFailed|commitFailed|verMismatch|nameConflicted|invalid/',
            warning_default  => '%{runstate} =~ /countryCodeMismatch|typeNotMatch/',
            set              =>
                {
                    key_values                     =>
                        [ { name => 'runstate' }, { name => 'display' } ],
                    closure_custom_output          =>
                        $self->can('custom_status_output'),
                    closure_custom_perfdata        =>
                        sub {return 0;},
                    closure_custom_threshold_check =>
                        \&catalog_status_threshold_ng
                }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "filter-name:s"    => { name => 'filter_name' },
        "filter-address:s" => { name => 'filter_address' },
        "filter-group:s"   => { name => 'filter_group' }
    });

    return $self;
}

my $map_run_state = {
    1  => 'idle',
    2  => 'autofind',
    3  => 'typeNotMatch',
    4  => 'fault',
    5  => 'config',
    6  => 'configFailed',
    7  => 'download',
    8  => 'normal',
    9  => 'committing',
    10 => 'commitFailed',
    11 => 'standby',
    12 => 'verMismatch',
    13 => 'nameConflicted',
    14 => 'invalid',
    15 => 'countryCodeMismatch'
};

my $mapping = {
    name    => { oid => '.1.3.6.1.4.1.2011.6.139.13.3.3.1.4' },# hwWlanApName
    address => { oid => '.1.3.6.1.4.1.2011.6.139.13.3.3.1.13' }# hwWlanApIpAddress
};

my $mapping_stat = {
    runtime  => { oid => '.1.3.6.1.4.1.2011.6.139.13.3.3.1.18' },# hwWlanApRunTime
    group    => { oid => '.1.3.6.1.4.1.2011.6.139.13.3.3.1.5' },# hwWlanApGroup
    runstate =>
        { oid => '.1.3.6.1.4.1.2011.6.139.13.3.3.1.6', map => $map_run_state }#  hwWlanApRunState
};

sub manage_selection {
    my ($self, %options) = @_;

    $self->{ap} = {};
    $self->{global} = {
        total               => 0,
        idle                => 0,
        autofind            => 0,
        typeNotMatch        => 0,
        fault               => 0,
        config              => 0,
        configFailed        => 0,
        download            => 0,
        normal              => 0,
        committing          => 0,
        commitFailed        => 0,
        standby             => 0,
        verMismatch         => 0,
        nameConflicted      => 0,
        invalid             => 0,
        countryCodeMismatch => 0
    };

    my $request = [ { oid => $mapping->{name}->{oid} } ];
    push @$request, { oid => $mapping->{group}->{oid} }
        if (defined($self->{option_results}->{filter_group})
            && $self->{option_results}->{filter_group} ne ''
        );

    push @$request, { oid => $mapping->{address}->{oid} }
        if (defined($self->{option_results}->{filter_address}) && $self->{option_results}->{filter_address} ne '');

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids         => $request,
        return_type  => 1,
        nothing_quit => 1
    );

    foreach (sort keys %$snmp_result) {
        next if (!/^$mapping->{name}->{oid}\.(.*)/);
        my $instance = $1;

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        if (!defined($result->{name}) || $result->{name} eq '') {
            $self->{output}->output_add(
                long_msg => "skipping WLC '$instance': cannot get a name. please set it.",
                debug    => 1
            );
            next;
        }

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(
                long_msg  => "skipping '" . $result->{name} . "': no matching name filter.",
                debug => 1
            );
            next;
        }

        if (defined($self->{option_results}->{filter_address}) && $self->{option_results}->{filter_address} ne '' &&
            $result->{address} !~ /$self->{option_results}->{filter_address}/) {
            $self->{output}->output_add(
                long_msg => "skipping '" . $result->{address} . "': no matching address filter.",
                debug    => 1
            );
            next;
        }

        if (defined($self->{option_results}->{filter_group}) && $self->{option_results}->{filter_group} ne '' &&
            $result->{group} !~ /$self->{option_results}->{filter_group}/) {
            $self->{output}->output_add(
                long_msg => "skipping '" . $result->{group} . "': no matching group filter.",
                debug    => 1
            );
            next;
        }

        $self->{ap}->{ $result->{name} } = {
            instance  => $instance,
            display   => $result->{name},
            ap_global => { display => $result->{name} }
        };
    }

    if (scalar(keys %{$self->{ap}}) <= 0) {
        $self->{output}->output_add(long_msg => 'no AP associated');
        return;
    }

    $options{snmp}->load(
        oids            => [ map($_->{oid}, values(%$mapping_stat)) ],
        instances       => [ map($_->{instance}, values %{$self->{ap}}) ],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef();

    foreach (sort keys %{$self->{ap}}) {
        my $result = $options{snmp}->map_instance(
            mapping  => $mapping_stat,
            results  => $snmp_result,
            instance => $self->{ap}->{$_}->{instance});

        $self->{global}->{total}++;
        $self->{global}->{ $result->{runstate} }++;
        $self->{ap}->{$_}->{ap_global}->{runstate} = $result->{runstate};
    }
}

1;

__END__

=head1 MODE

Check AP status.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: C<--filter-counters='^total$|^total-normal$'>

=item B<--filter-name>

Filter access point name (can be a regexp)

=item B<--filter-address>

Filter access point IP address (can be a regexp).

=item B<--filter-group>

Filter access point group (can be a regexp).

=item B<--warning-status>

Define the conditions to match for the status to be WARNING. (default: C<'%{runstate} =~ /countryCodeMismatch|typeNotMatch/'>).
You can use the following variables: C<%{runstate}>, C<%{display}>.
C<%(runstate)> can have one of these values: C<idle>, C<autofind>, C<typeNotMatch>, C<fault>, C<config>, C<configFailed>, C<download>, C<normal>, C<committing>, C<commitFailed>, C<standby>, C<verMismatch>, C<nameConflicted>, C<invalid>, C<countryCodeMismatch>.

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL. (default: C<'%{runstate} =~ /fault|configFailed|commitFailed|verMismatch|nameConflicted|invalid/'>).
You can use the following variables: C<%{runstate}>, C<%{display}>.
C<%(runstate)> can have one of these values: C<idle>, C<autofind>, C<typeNotMatch>, C<fault>, C<config>, C<configFailed>, C<download>, C<normal>, C<committing>, C<commitFailed>, C<standby>, C<verMismatch>, C<nameConflicted>, C<invalid>, C<countryCodeMismatch>.

=item B<--warning-total>

Thresholds.

=item B<--critical-total>

Thresholds.

=item B<--warning-total-idle>

Thresholds.

=item B<--critical-total-idle>

Thresholds.

=item B<--warning-total-autofind>

Thresholds.

=item B<--critical-total-autofind>

Thresholds.

=item B<--warning-total-typeNotMatch>

Thresholds.

=item B<--critical-total-typeNotMatch>

Thresholds.

=item B<--warning-total-fault>

Thresholds.

=item B<--critical-total-fault>

Thresholds.

=item B<--warning-total-config>

Thresholds.

=item B<--critical-total-config>

Thresholds.

=item B<--warning-total-config-failed>

Thresholds.

=item B<--critical-total-config-failed>

Thresholds.

=item B<--warning-total-download>

Thresholds.

=item B<--critical-total-download>

Thresholds.

=item B<--warning-total-normal>

Thresholds.

=item B<--critical-total-normal>

Thresholds.

=item B<--warning-total-committing>

Thresholds.

=item B<--critical-total-committing>

Thresholds.

=item B<--warning-total-commit-failed>

Thresholds.

=item B<--critical-total-commit-failed>

Thresholds.

=item B<--warning-total-standby>

Thresholds.

=item B<--critical-total-standby>

Thresholds.

=item B<--warning-total-version-mismatch>

Thresholds.

=item B<--critical-total-version-mismatch>

Thresholds.

=item B<--warning-total-name-conflicted>

Thresholds.

=item B<--critical-total-name-conflicted>

Thresholds.

=item B<--warning-total-invalid>

Thresholds.

=item B<--critical-total-invalid>

Thresholds.

=item B<--warning-total-country-code-mismatch>

Thresholds.

=item B<--critical-total-country-code-mismatch>

Thresholds.

=back

=cut
