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

package network::citrix::netscaler::snmp::mode::listvservers;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $oid_vsvrFullName = '.1.3.6.1.4.1.5951.4.1.3.1.1.59';
my $oid_vsvrEntityType = '.1.3.6.1.4.1.5951.4.1.3.1.1.64';

my %map_vs_type = (
    0 => 'unknown', 
    1 => 'loadbalancing', 
    2 => 'loadbalancinggroup', 
    3 => 'sslvpn', 
    4 => 'contentswitching', 
    5 => 'cacheredirection'
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'name:s'        => { name => 'name' },
        'regexp'        => { name => 'use_regexp' },
        'filter-type:s' => { name => 'filter_type' }
    });

    $self->{vs_id_selected} = [];

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{results} = $self->{snmp}->get_multiple_table(oids => [ { oid => $oid_vsvrFullName}, { oid => $oid_vsvrEntityType } ], nothing_quit => 1);
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_vsvrFullName}})) {
        next if ($oid !~ /^$oid_vsvrFullName\.(.*)$/);
        my $instance = $1;
        my $name = $self->{results}->{$oid_vsvrFullName}->{$oid};
        my $type = $self->{results}->{$oid_vsvrEntityType}->{$oid_vsvrEntityType . '.' . $instance};
        
        next if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
                 $map_vs_type{$type} !~ /$self->{option_results}->{filter_type}/);
        
        # Get all without a name
        if (!defined($self->{option_results}->{name})) {
            push @{$self->{vs_id_selected}}, $instance; 
            next;
        }
        
        $name = $self->{output}->decode($name);
        if (!defined($self->{option_results}->{use_regexp}) && $name eq $self->{option_results}->{name}) {
            push @{$self->{vs_id_selected}}, $instance;
            next;
        }
        if (defined($self->{option_results}->{use_regexp}) && $name =~ /$self->{option_results}->{name}/) {
            push @{$self->{vs_id_selected}}, $instance;
            next;
        }
        
        $self->{output}->output_add(long_msg => "Skipping virtual server '" . $name . "': no matching filter name");
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    $self->manage_selection();
    foreach my $instance (sort @{$self->{vs_id_selected}}) { 
        my $name = $self->{results}->{$oid_vsvrFullName}->{$oid_vsvrFullName . '.' . $instance};
        my $type = $self->{results}->{$oid_vsvrEntityType}->{$oid_vsvrEntityType . '.' . $instance};

        $self->{output}->output_add(long_msg => "'" . $name . "' [type = '" . $map_vs_type{$type} . "']");
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List Virtual Servers:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'type']);
}

sub disco_show {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    $self->manage_selection();
    foreach my $instance (sort @{$self->{vs_id_selected}}) {        
        my $name = $self->{results}->{$oid_vsvrFullName}->{$oid_vsvrFullName . '.' . $instance};
        my $type = $self->{results}->{$oid_vsvrEntityType}->{$oid_vsvrEntityType . '.' . $instance};
        
        $self->{output}->add_disco_entry(name => $name, type => $map_vs_type{$type});
    }
}

1;

__END__

=head1 MODE

List Virtual Servers.

=over 8

=item B<--name>

Set the virtual server name.

=item B<--regexp>

Allows to use regexp to filter virtual server name (with option --name).

=item B<--filter-type>

Filter which type of vserver (can be a regexp).

=back

=cut
    
