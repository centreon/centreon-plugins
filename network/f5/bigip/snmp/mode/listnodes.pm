#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

package network::f5::bigip::snmp::mode::listnodes;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $oid_ltmNodeAddrName = '.1.3.6.1.4.1.3375.2.2.4.1.2.1.17'; # old
my $oid_ltmNodeAddrStatusName = '.1.3.6.1.4.1.3375.2.2.4.3.2.1.7'; # new

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "filter-name:s"   => { name => 'filter_name' },
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $self->{snmp}->get_multiple_table(oids => [ { oid => $oid_ltmNodeAddrName }, { oid => $oid_ltmNodeAddrStatusName } ], nothing_quit => 1);
    
    my ($branch_name) = ($oid_ltmNodeAddrStatusName);
    if (!defined($snmp_result->{$oid_ltmNodeAddrStatusName}) || scalar(keys %{$snmp_result->{$oid_ltmNodeAddrStatusName}}) == 0)  {
        ($branch_name) = ($oid_ltmNodeAddrName);
    }
    
    $self->{node} = {};
    foreach my $oid (keys %{$snmp_result->{$branch_name}}) {        
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $snmp_result->{$branch_name}->{$oid} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping service class '" . $snmp_result->{$branch_name}->{$oid} . "'.", debug => 1);
            next;
        }
        
        $self->{node}->{$snmp_result->{$branch_name}->{$oid}} = { name => $snmp_result->{$branch_name}->{$oid} };
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    $self->manage_selection();
    foreach my $name (sort keys %{$self->{node}}) {
        $self->{output}->output_add(long_msg => "'" . $name . "'");
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List Nodes:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name']);
}

sub disco_show {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    $self->manage_selection();
    foreach my $name (sort keys %{$self->{node}}) {        
        $self->{output}->add_disco_entry(name => $name);
    }
}

1;

__END__

=head1 MODE

List nodes.

=over 8

=item B<--filter-name>

Filter by node name.

=back

=cut
