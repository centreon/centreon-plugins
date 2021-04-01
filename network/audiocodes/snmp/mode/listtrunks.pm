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

package network::audiocodes::snmp::mode::listtrunks;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                });
    $self->{trunks} = {};
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

my %map_deactivate = (0 => 'notAvailable', 1 => 'deActivated', 2 => 'activated');
my %map_alarm = (0 => 'greyDisabled', 1 => 'greenActive', 2 => 'redLosLof', 
3 => 'blueAis', 4 => 'yellowRai', 5 => 'orangeDChannel', 6 => 'purpleLowerLayerDown', 7 => 'darkOrangeNFASAlarm');

my $mapping = {
    acTrunkStatusAlarm      => { oid => '.1.3.6.1.4.1.5003.9.10.9.2.1.1.1.7', map => \%map_alarm },
    acTrunkDeactivate       => { oid => '.1.3.6.1.4.1.5003.9.10.9.1.1.1.1.1.11', map => \%map_deactivate },
    acTrunkName             => { oid => '.1.3.6.1.4.1.5003.9.10.9.1.1.1.1.1.13' },
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_multiple_table(oids => [ 
            { oid => $mapping->{acTrunkStatusAlarm}->{oid} },
            { oid => $mapping->{acTrunkDeactivate}->{oid} },
            { oid => $mapping->{acTrunkName}->{oid} },
        ],
        return_type => 1, nothing_quit => 1);

    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{acTrunkName}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        
        if (!defined($result->{acTrunkName}) || $result->{acTrunkName} eq '') {
            $self->{output}->output_add(long_msg => "skipping instance '" . $instance . "': no name defined.", debug => 1);
            next;
        }
        
        $self->{trunks}->{$instance} = 
            { name => $result->{acTrunkName}, status => $result->{acTrunkStatusAlarm}, state => $result->{acTrunkDeactivate} };
    }
}

sub run {
    my ($self, %options) = @_;
  
    $self->manage_selection(%options);
    foreach my $instance (sort keys %{$self->{trunks}}) { 
        $self->{output}->output_add(long_msg => '[name = ' . $self->{trunks}->{$instance}->{name} . 
            "] [status = '" . $self->{trunks}->{$instance}->{status} . "'] [state = '" .
            $self->{trunks}->{$instance}->{state} . "']"
            );
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List trunks:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'status', 'state']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $instance (sort keys %{$self->{trunks}}) {             
        $self->{output}->add_disco_entry(name => $self->{trunks}->{$instance}->{name}, 
            status => $self->{trunks}->{$instance}->{status}, state => $self->{trunks}->{$instance}->{state});
    }
}

1;

__END__

=head1 MODE

List trunks.

=over 8

=back

=cut
    
