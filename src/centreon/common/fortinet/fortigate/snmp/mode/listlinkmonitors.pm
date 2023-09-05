#
# Copyright 2023 Centreon (http://www.centreon.com/)
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

package centreon::common::fortinet::fortigate::snmp::mode::listlinkmonitors;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $mapping_status = { 0 => 'alive', 1 => 'dead' };
my $mapping = {
    name  => { oid => '.1.3.6.1.4.1.12356.101.4.8.2.1.2' }, # fgLinkMonitorName
    state => { oid => '.1.3.6.1.4.1.12356.101.4.8.2.1.3', map => $mapping_status } # fgLinkMonitorState
};
my $oid_table = '.1.3.6.1.4.1.12356.101.4.8.2';

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' },
        'filter-state:s' => { name => 'filter_state' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(oid => $oid_table, start => $mapping->{name}, end => $mapping->{state}, nothing_quit => 1);

    foreach my $oid ($options{snmp}->oid_lex_sort(keys %{$snmp_result})) {
        next if ($oid !~ /^$mapping->{name}->{oid}\.(.*)$/);
        my $instance = $1;
        
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{name} . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_state}) && $self->{option_results}->{filter_state} ne '' &&
            $result->{state} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{state} . "': no matching filter.", debug => 1);
            next;
        }
                
        push @{$self->{linkmonitor}}, $result; 
    }
}

sub run {
    my ($self, %options) = @_;

    $self->manage_selection(%options);

    foreach (sort @{$self->{linkmonitor}}) { 
        $self->{output}->output_add(long_msg => sprintf("[Name = %s] [State = %s]", $_->{name}, $_->{state}));
    }
    
    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List link monitors:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'state']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);

    foreach (sort @{$self->{linkmonitor}}) {
        $self->{output}->add_disco_entry(name => $_->{name}, state => $_->{state});
    }
}

1;

__END__

=head1 MODE

List link monitors.

=over 8

=item B<--filter-name>

Filter link monitor by name (can be a regexp).

=item B<--filter-state>

Filter link monitor by state (can be a regexp).

=back

=cut
