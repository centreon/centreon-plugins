#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package network::mikrotik::snmp::mode::update;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "expected-version:s"    => { name => 'expected_version', default => 'stable' },
                                  "timeout:s"             => { name => 'timeout', default => 30 },
                                });

    $self->{oids_label} = {
        'softwareVersion' => '.1.3.6.1.4.1.14988.1.1.4.4.0',
        'firmwareVersion' => '.1.3.6.1.4.1.14988.1.1.7.4.0',
    };

    $self->{urls_update} = {
        'stable' => '/routeros/LATEST.6',
        'testing' => '/routeros/LATEST.6rc',
        'longterm' => '/routeros/LATEST.6fix',
    };

    $self->{http} = centreon::plugins::http->new(%options);

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;
  
    my $snmp_result = $options{snmp}->get_leef(oids => [$self->{oids_label}->{'softwareVersion'}, $self->{oids_label}->{'firmwareVersion'}]);

    my $expected_version;
    if (defined($self->{urls_update}->{$self->{option_results}->{expected_version}})) {
        $expected_version = $self->{http}->request(
            hostname => 'upgrade.mikrotik.com',
            method => 'GET',
            url_path => $self->{urls_update}->{$self->{option_results}->{expected_version}},
            warning_status => '', unknown_status => '%{http_code} < 200 or %{http_code} >= 300', critical_status => '',
            timeout => $self->{option_results}->{timeout}
        );
        $expected_version =~ s/ .*//s;
    } else {
        $expected_version = $self->{option_results}->{expected_version};
    }

    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'RouterOS '.$expected_version.' uptodate');

    if ($snmp_result->{$self->{oids_label}->{'softwareVersion'}} ne $expected_version) {
        $self->{output}->output_add(severity => 'WARNING',
                                    short_msg => 'RouterOS software update '.$expected_version.' available ('.$snmp_result->{$self->{oids_label}->{'softwareVersion'}}.' running)');
    } elsif ($snmp_result->{$self->{oids_label}->{'firmwareVersion'}} ne $expected_version) {
        $self->{output}->output_add(severity => 'WARNING',
                                    short_msg => 'RouterOS firmware update '.$expected_version.' available ('.$snmp_result->{$self->{oids_label}->{'firmwareVersion'}}.' running)');
    }

    $self->{output}->display();

    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check for RouterOS update.

=over 8

=item B<--expected-version>

Which channel to check (Default: 'stable').
Can be: 'stable', 'testing', 'longterm'.
Can also be a literal version number, for example '6.44.3'.

=item B<--timeout>

Threshold for HTTP timeout (Default: '30').

=back

=cut
