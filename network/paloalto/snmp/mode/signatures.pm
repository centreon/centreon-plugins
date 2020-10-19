#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package network::paloalto::snmp::mode::signatures;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use DateTime;
use centreon::plugins::misc;

sub custom_av_output {
    my ($self, %options) = @_;

    return sprintf(
        "antivirus version '%s', last update %s",
        $self->{result_values}->{av_version},
        centreon::plugins::misc::change_seconds(value => $self->{result_values}->{av_lastupdate_time})
    );
}

sub custom_threat_output {
    my ($self, %options) = @_;

    return sprintf(
        "threat version '%s', last update %s",
        $self->{result_values}->{threat_version},
        centreon::plugins::misc::change_seconds(value => $self->{result_values}->{threat_lastupdate_time})
    );
}

sub custom_wildfire_output {
    my ($self, %options) = @_;

    return sprintf(
        "wildfire version '%s', last update %s",
        $self->{result_values}->{wildfire_version},
        centreon::plugins::misc::change_seconds(value => $self->{result_values}->{wildfire_lastupdate_time})
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'signatures', type => 0, message_separator => ' - ', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{signatures} = [
        { label => 'av-update', nlabel => 'signature.antivirus.lastupdate.time.seconds', set => {
                key_values => [ { name => 'av_lastupdate_time' }, { name => 'av_version' } ],
                closure_custom_output => $self->can('custom_av_output'),
                perfdatas => [
                    { template => '%d', min => 0, unit => 's' }
                ]
            }
        },
        { label => 'threat-update', nlabel => 'signature.threat.lastupdate.time.seconds', set => {
                key_values => [ { name => 'threat_lastupdate_time' }, { name => 'threat_version' } ],
                closure_custom_output => $self->can('custom_threat_output'),
                perfdatas => [
                    { template => '%d', min => 0, unit => 's' }
                ]
            }
        },
        { label => 'wildfire-update', nlabel => 'signature.wildfire.lastupdate.time.seconds', set => {
                key_values => [ { name => 'wildfire_lastupdate_time' }, { name => 'wildfire_version' } ],
                closure_custom_output => $self->can('custom_wildfire_output'),
                perfdatas => [
                    { template => '%d', min => 0, unit => 's' }
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
        'timezone:s' => { name => 'timezone' }
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{option_results}->{timezone} = 'GMT' if (!defined($self->{option_results}->{timezone}) || $self->{option_results}->{timezone} eq '');
}

sub get_diff_time {
    my ($self, %options) = @_;

    # '29/10/2018  08:44:54'
    return undef if ($options{time} !~ /^\s*(\d{4})\/(\d{2})\/(\d{2})\s+(\d+):(\d+):(\d+)/);

    my $tz = centreon::plugins::misc::set_timezone(name => $self->{option_results}->{timezone});
    my $dt = DateTime->new(
        year       => $1,
        month      => $2,
        day        => $3,
        hour       => $4,
        minute     => $5,
        second     => $6,
        %$tz
    );
    return (time() - $dt->epoch);
}

my $mapping = {
    panSysAvVersion         => { oid => '.1.3.6.1.4.1.25461.2.1.2.1.8' },
    panSysThreatVersion     => { oid => '.1.3.6.1.4.1.25461.2.1.2.1.9' },
    panSysWildfireVersion   => { oid => '.1.3.6.1.4.1.25461.2.1.2.1.17' },
    panSysThreatReleaseDate => { oid => '.1.3.6.1.4.1.25461.2.1.2.1.21' },
    panSysAvReleaseDate     => { oid => '.1.3.6.1.4.1.25461.2.1.2.1.22' },
    panSysWfReleaseDate     => { oid => '.1.3.6.1.4.1.25461.2.1.2.1.23' }
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_leef(
        oids => [ map($_->{oid} . '.0', values(%$mapping)) ],
        nothing_quit => 1
    );
    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => '0');

    $self->{signatures} = {
        av_lastupdate_time       => $self->get_diff_time(time => $result->{panSysThreatReleaseDate}),
        threat_lastupdate_time   => $self->get_diff_time(time => $result->{panSysAvReleaseDate}),
        wildfire_lastupdate_time => $self->get_diff_time(time => $result->{panSysWfReleaseDate}),
        av_version               => $result->{panSysAvVersion},
        threat_version           => $result->{panSysThreatVersion},
        wildfire_version         => $result->{panSysWildfireVersion}
    };
}

1;

__END__

=head1 MODE

Check signature last update time.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='av-update'

=item B<--timezone>

Timezone options. Default is 'GMT'.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'av-update' (s), 'threat-update' (s), 'wildfire-update' (s).

=back

=cut
