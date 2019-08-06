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

package apps::voip::cisco::meetingplace::mode::audiolicenses;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                  "warning:s"       => { name => 'warning', default => '60' },
                                  "critical:s"      => { name => 'critical', default => '70' },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    $self->{warning} = $self->{option_results}->{warning};
    $self->{critical} = $self->{option_results}->{critical};
    
    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{warning})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{warning} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold'" . $self->{critical} . "'.");
       $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};
    
#   Nombre de ports audio utilise
    my $oid_cmpAudioLicense = '.1.3.6.1.4.1.9.9.733.1.3.1.0';
#   Nombre maximum de ports audio disponibles
    my $oid_cmpMaxAudioLicense = '.1.3.6.1.4.1.9.9.733.1.3.2.0';

    my $result = $self->{snmp}->get_leef(oids => [$oid_cmpAudioLicense, $oid_cmpMaxAudioLicense], nothing_quit => 1);
    my $prct;
    
    if ($result->{$oid_cmpAudioLicense} > 0) {
        $prct = $result->{$oid_cmpAudioLicense} / $result->{$oid_cmpMaxAudioLicense} * 100;
    } else {
        $prct = 0;
    }
    my $abs_warning = $self->{option_results}->{warning} / 100 * $result->{$oid_cmpMaxAudioLicense};
    my $abs_critical = $self->{option_results}->{critical} / 100 * $result->{$oid_cmpMaxAudioLicense};
    
    my $exit = $self->{perfdata}->threshold_check(value => $prct,
    	                                          threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]
						 );

    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("%.2f%% of audio licenses are in use.  (%d max)",
                                                     $prct, $result->{$oid_cmpMaxAudioLicense}));

    $self->{output}->perfdata_add(label => "audio-licenses", unit => 'licenses',
                                  value => $result->{$oid_cmpAudioLicense},
                                  warning => $abs_warning,
                                  critical => $abs_critical,
				  min => 0,
				  max => $result->{$oid_cmpMaxAudioLicense});
    
    $self->{output}->display();
    $self->{output}->exit();

}

1;

__END__

=head1 MODE

Check the percentage of audio licenses used on this cisco meeting place platform.

=over 8

=item B<--warning>

Threshold warning: Percentage value of audio licenses usage resulting in a warning state

=item B<--critical>

Threshold critical: Percentage value of audio licenses usage resulting in a critical state

=back

==cut
