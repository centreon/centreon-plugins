################################################################################
# Copyright 2005-2013 MERETHIS
# Centreon is developped by : Julien Mathis and Romain Le Merlus under
# GPL Licence 2.0.
# 
# This program is free software; you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation ; either version 2 of the License.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along with 
# this program; if not, see <http://www.gnu.org/licenses>.
# 
# Linking this program statically or dynamically with other modules is making a 
# combined work based on this program. Thus, the terms and conditions of the GNU 
# General Public License cover the whole combination.
# 
# As a special exception, the copyright holders of this program give MERETHIS 
# permission to link this program with independent modules to produce an executable, 
# regardless of the license terms of these independent modules, and to copy and 
# distribute the resulting executable under terms of MERETHIS choice, provided that 
# MERETHIS also meet, for each linked independent module, the terms  and conditions 
# of the license of that module. An independent module is a module which is not 
# derived from this program. If you modify this program, you may extend this 
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
# 
# For more information : contact@centreon.com
# Authors : Quentin Garnier <qgarnier@merethis.com>
#
####################################################################################

package network::citrix::netscaler::common::mode::listvservers;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $oid_vsvrName = '.1.3.6.1.4.1.5951.4.1.3.1.1.1';
my $oid_vsvrEntityType = '.1.3.6.1.4.1.5951.4.1.3.1.1.64';

my %map_vs_type = (
    0 => 'unknown', 
    1 => 'loadbalancing', 
    2 => 'loadbalancinggroup', 
    3 => 'sslvpn', 
    4 => 'contentswitching', 
    5 => 'cacheredirection',
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "name:s"                => { name => 'name' },
                                  "regexp"                => { name => 'use_regexp' },
                                  "filter-type:s"         => { name => 'filter_type' },
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

    $self->{results} = $self->{snmp}->get_multiple_table(oids => [ { oid => $oid_vsvrName}, { oid => $oid_vsvrEntityType } ], nothing_quit => 1);
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_vsvrName}})) {
        next if ($oid !~ /^$oid_vsvrName\.(.*)$/);
        my $instance = $1;
        my $name = $self->{results}->{$oid_vsvrName}->{$oid};
        my $type = $self->{results}->{$oid_vsvrEntityType}->{$oid_vsvrEntityType . '.' . $instance};
        
        next if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
                 $map_vs_type{$type} !~ /$self->{option_results}->{filter_type}/);
        
        # Get all without a name
        if (!defined($self->{option_results}->{name})) {
            push @{$self->{vs_id_selected}}, $instance; 
            next;
        }
        
        $name = $self->{output}->to_utf8($name);
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
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    $self->manage_selection();
    foreach my $instance (sort @{$self->{vs_id_selected}}) { 
        my $name = $self->{results}->{$oid_vsvrName}->{$oid_vsvrName . '.' . $instance};
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
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    $self->manage_selection();
    foreach my $instance (sort @{$self->{vs_id_selected}}) {        
        my $name = $self->{results}->{$oid_vsvrName}->{$oid_vsvrName . '.' . $instance};
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
    