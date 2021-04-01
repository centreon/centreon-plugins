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

package network::kemp::snmp::mode::listvs;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                  "filter-name:s"         => { name => 'filter_name' },
                                });
    $self->{vs_id_selected} = [];

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

my %map_state = (
    1 => 'inService',
    2 => 'outOfService',
    4 => 'disabled',
    5 => 'sorry',
    6 => 'redirect',
    7 => 'errormsg',
);
my $mapping = {
    vSname          => { oid => '.1.3.6.1.4.1.12196.13.1.1.13' },
    vSstate         => { oid => '.1.3.6.1.4.1.12196.13.1.1.14', map => \%map_state },
};

sub manage_selection {
    my ($self, %options) = @_;

    $self->{results} = $self->{snmp}->get_multiple_table(oids => [ { oid => $mapping->{vSname}->{oid} }, { oid => $mapping->{vSstate}->{oid} } ], 
                                                         nothing_quit => 1, return_type => 1);
    foreach my $oid (keys %{$self->{results}}) {
        next if ($oid !~ /^$mapping->{vSname}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}, instance => $instance);
        
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{vSname} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{vSname} . "': no matching filter.", debug => 1);
            next;
        }
        
        push @{$self->{vs_id_selected}}, $instance;
    }
}

sub run {
    my ($self, %options) = @_;
    
    $self->{snmp} = $options{snmp};
    $self->manage_selection();
    foreach my $instance (sort @{$self->{vs_id_selected}}) { 
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}, instance => $instance);

        $self->{output}->output_add(long_msg => "'" . $result->{vSname} . "' [state = " . $result->{vSstate} . "]");
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List Virtual Servers:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'state']);
}

sub disco_show {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    $self->manage_selection(disco => 1);
    foreach my $instance (sort @{$self->{vs_id_selected}}) {        
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}, instance => $instance);
        
        $self->{output}->add_disco_entry(name => $result->{vSname}, state => $result->{vSstate});
    }
}

1;

__END__

=head1 MODE

List virtual servers.

=over 8

=item B<--filter-name>

Set the virtual server name.

=back

=cut
    