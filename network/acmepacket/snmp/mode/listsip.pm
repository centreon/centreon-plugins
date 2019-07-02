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

package network::acmepacket::snmp::mode::listsip;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                  "filter-name:s"       => { name => 'filter_name' },
                                });
    $self->{sip} = {};
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

my %map_status = (
    0 => 'disabled', 1 => 'outOfService',
    2 => 'standby', 3 => 'inService',
    4 => 'constraintsViolation', 5 => 'inServiceTimedOut',
    6 => 'oosprovisionedresponse',
);
my $mapping = {
    apSipSAStatsSessionAgentHostname    => { oid => '.1.3.6.1.4.1.9148.3.2.1.2.2.1.2' },
    apSipSAStatsSessionAgentStatus      => { oid => '.1.3.6.1.4.1.9148.3.2.1.2.2.1.22', map => \%map_status },
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_multiple_table(oids => [ 
            { oid => $mapping->{apSipSAStatsSessionAgentHostname}->{oid} },
            { oid => $mapping->{apSipSAStatsSessionAgentStatus}->{oid} },
        ],
        return_type => 1, nothing_quit => 1);


    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{apSipSAStatsSessionAgentHostname}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{apSipSAStatsSessionAgentHostname} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{apSipSAStatsSessionAgentHostname} . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{sip}->{$instance} = { name => $result->{apSipSAStatsSessionAgentHostname}, status => $result->{apSipSAStatsSessionAgentStatus} };
    }
}

sub run {
    my ($self, %options) = @_;
  
    $self->manage_selection(%options);
    foreach my $instance (sort keys %{$self->{sip}}) { 
        $self->{output}->output_add(long_msg => '[name = ' . $self->{sip}->{$instance}->{name} . "] [status = '" . $self->{sip}->{$instance}->{status} . "']");
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List SIPs:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'status']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $instance (sort keys %{$self->{sip}}) {             
        $self->{output}->add_disco_entry(name => $self->{sip}->{$instance}->{name}, status => $self->{sip}->{$instance}->{status});
    }
}

1;

__END__

=head1 MODE

List SIPs.

=over 8

=item B<--filter-name>

Filter by SIP name (can be a regexp).

=back

=cut
    
