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

package storage::netapp::ontap::snmp::mode::listsnapvault;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

my $map_status = {
    1 => 'idle', 2 => 'transferring', 3 => 'pending',
    4 => 'aborting', 6 => 'quiescing', 7 => 'resyncing',
    12 => 'paused',
};
my $map_state = {
    1 => 'uninitialized', 2 => 'snapvaulted',
    3 => 'brokenOff', 4 => 'quiesced',
    5 => 'source', 6 => 'unknown', 7 => 'restoring',
};

my $oid_snapvaultStatusTable = '.1.3.6.1.4.1.789.1.19.11';
my $mapping = {
    svSrc       => { oid => '.1.3.6.1.4.1.789.1.19.11.1.2' }, 
    svDst       => { oid => '.1.3.6.1.4.1.789.1.19.11.1.3' }, 
    svStatus    => { oid => '.1.3.6.1.4.1.789.1.19.11.1.4', map => $map_status }, 
    svState     => { oid => '.1.3.6.1.4.1.789.1.19.11.1.5', map => $map_state },
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_snapvaultStatusTable, start => $mapping->{svSrc}->{oid}, end => $mapping->{svState}->{oid},
        nothing_quit => 1
    );
    
    $self->{snapvault} = {};
    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{svSrc}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        
        $self->{snapvault}->{$instance} = { %$result };
    }
}

sub run {
    my ($self, %options) = @_;
  
    $self->manage_selection(%options);
    foreach my $instance (sort keys %{$self->{snapvault}}) { 
        $self->{output}->output_add(long_msg => '[src = ' . $self->{snapvault}->{$instance}->{svSrc} . 
            '] [dst = ' . $self->{snapvault}->{$instance}->{svDst} . 
            '] [status = ' . $self->{snapvault}->{$instance}->{svStatus} . 
            '] [state = ' . $self->{snapvault}->{$instance}->{svState} . ']'
        );
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List snapvaults:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['src', 'dst', 'status', 'state']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $instance (sort keys %{$self->{snapvault}}) {             
        $self->{output}->add_disco_entry(
            src => $self->{snapvault}->{$instance}->{svSrc},
            dst => $self->{snapvault}->{$instance}->{svDst},
            status => $self->{snapvault}->{$instance}->{svStatus},
            state => $self->{snapvault}->{$instance}->{svState}
        );
    }
}

1;

__END__

=head1 MODE

List snapvaults.

=over 8

=back

=cut
    
