#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package network::f5::bigip::mode::listnodes;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $oid_ltmNodeAddrStatusAvailState = '.1.3.6.1.4.1.3375.2.2.4.3.2.1.3';

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "name:s"                => { name => 'name' },
                                  "regexp"                => { name => 'use_regexp' },
                                });
    $self->{node_id_selected} = [];

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{result_names} = $self->{snmp}->get_table(oid => $oid_ltmNodeAddrStatusAvailState, nothing_quit => 1);
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{result_names}})) {
        next if ($oid !~ /^$oid_ltmNodeAddrStatusAvailState\.(.*)$/);
        my $instance = $1;
        
        # Get all without a name
        if (!defined($self->{option_results}->{name})) {
            push @{$self->{node_id_selected}}, $instance; 
            next;
        }
        
        my $name = $instance;
        # prefix by '1.4'
        $name =~ s/^1\.4\.//;
        if (!defined($self->{option_results}->{use_regexp}) && $name eq $self->{option_results}->{name}) {
            push @{$self->{node_id_selected}}, $instance;
            next;
        }
        if (defined($self->{option_results}->{use_regexp}) && $name =~ /$self->{option_results}->{name}/) {
            push @{$self->{node_id_selected}}, $instance;
            next;
        }
        
        $self->{output}->output_add(long_msg => "Skipping node '" . $name . "': no matching filter name", debug => 1);
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    $self->manage_selection();
    foreach my $instance (sort @{$self->{node_id_selected}}) {
        my $name = $instance;
        # prefix by '1.4'
        $name =~ s/^1\.4\.//;

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
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    $self->manage_selection(disco => 1);
    foreach my $instance (sort @{$self->{node_id_selected}}) {        
        my $name = $instance;
        # prefix by '1.4'
        $name =~ s/^1\.4\.//;
        
        $self->{output}->add_disco_entry(name => $name);
    }
}

1;

__END__

=head1 MODE

List F-5 Nodes.

=over 8

=item B<--name>

Set the node name.

=item B<--regexp>

Allows to use regexp to filter node name (with option --name).

=back

=cut
    