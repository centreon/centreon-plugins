#
# Copyright 2021 Centreon (http://www.centreon.com/)
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

package apps::antivirus::mcafee::webgateway::snmp::mode::versions;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);

sub custom_version_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{output} = $options{extra_options}->{output_ref};
    $self->{result_values}->{version} = $options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref}};
    $self->{result_values}->{timestamp} = $options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref} . '_timestamp'};
    $self->{result_values}->{since} = time() - $self->{result_values}->{timestamp};

    return 0;
}

sub custom_version_threshold {
    my ($self, %options) = @_;

    return $self->{perfdata}->threshold_check(
        value => $self->{result_values}->{since},
        threshold => [
            { label => 'critical-' . $self->{label}, exit_litteral => 'critical' },
            { label => 'warning-' . $self->{label}, exit_litteral => 'warning' }
        ]
    );
}

sub custom_version_output {
    my ($self, %options) = @_;

    return sprintf(
        "%s: %s [Last update: %s]",
        $self->{result_values}->{output},
        $self->{result_values}->{version},
        centreon::plugins::misc::change_seconds(value => $self->{result_values}->{since})
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'dat-version', set => {
                key_values => [ { name => 'pMFEDATVersion' }, { name => 'pMFEDATVersion_timestamp' } ],
                closure_custom_calc => $self->can('custom_version_calc'),
                closure_custom_calc_extra_options => { label_ref => 'pMFEDATVersion', output_ref => 'DAT Version' },
                closure_custom_output => $self->can('custom_version_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_version_threshold')
            }
        },
        { label => 'tsdb-version', set => {
                key_values => [ { name => 'pTSDBVersion' }, { name => 'pTSDBVersion_timestamp' } ],
                closure_custom_calc => $self->can('custom_version_calc'),
                closure_custom_calc_extra_options => { label_ref => 'pTSDBVersion', output_ref => 'TrustedSource Database Version' },
                closure_custom_output => $self->can('custom_version_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_version_threshold')
            }
        },
        { label => 'proactive-version', set => {
                key_values => [ { name => 'pAMProactiveVersion' }, { name => 'pAMProactiveVersion_timestamp' } ],
                closure_custom_calc => $self->can('custom_version_calc'),
                closure_custom_calc_extra_options => { label_ref => 'pAMProactiveVersion', output_ref => 'ProActive Database Version' },
                closure_custom_output => $self->can('custom_version_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_version_threshold')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    $self->{cache} = centreon::plugins::statefile->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{cache}->check_options(%options);
}

my $oid_pMFEDATVersion = '.1.3.6.1.4.1.1230.2.7.1.20.4.0';
my $oid_pAMProactiveVersion = '.1.3.6.1.4.1.1230.2.7.1.20.5.0';
my $oid_pTSDBVersion = '.1.3.6.1.4.1.1230.2.7.1.20.6.0';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache}->read(statefile => 'mcafee_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')));

    my $results = $options{snmp}->get_leef(
        oids => [ $oid_pMFEDATVersion, $oid_pAMProactiveVersion, $oid_pTSDBVersion ], 
        nothing_quit => 1
    );

    $self->{new_datas} = {
        pMFEDATVersion => $results->{$oid_pMFEDATVersion},
        pAMProactiveVersion => $results->{$oid_pAMProactiveVersion},
        pTSDBVersion => $results->{$oid_pTSDBVersion}
    };

    foreach my $version (('pMFEDATVersion', 'pAMProactiveVersion', 'pTSDBVersion')) {
        next if (!defined($self->{new_datas}->{$version}) || $self->{new_datas}->{$version} eq '');
        $self->{new_datas}->{$version . '_timestamp'} = ($self->{new_datas}->{$version} > $self->{cache}->{datas}->{$version}) ? time() : $self->{cache}->{datas}->{$version . '_timestamp'};
        $self->{new_datas}->{$version . '_timestamp'} = time() if (!defined($self->{new_datas}->{$version . '_timestamp'}));
    }

    $self->{global} = { %{$self->{new_datas}} };

    $self->{cache}->write(data => $self->{new_datas});
}

1;

__END__

=head1 MODE

Check signature databases versions
(last update is only guessed by version's changement,
it does not appear clearly in the MIB).

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
(Example: --filter-counters='dat')

=item B<--warning-*>

Threshold warning on last update.
Can be: 'dat-version', 'tsdb-version', 'proactive-version'.

=item B<--critical-*>

Threshold critical on last update.
Can be: 'dat-version', 'tsdb-version', 'proactive-version'.

=back

=cut
