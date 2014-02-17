################################################################################
# Copyright 2005-2014 MERETHIS
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

package apps::iis::local::mode::listapplicationpools;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use Win32::OLE;

my %state_map = (
    0   => 'starting',
    1   => 'started',
    2   => 'stopping',
    3   => 'stopped',
    4   => 'unknown',
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "name:s"          => { name => 'name' },
                                  "regexp"          => { name => 'use_regexp' },
                                  "filter-state:s"  => { name => 'filter_state' },
                                });
    $self->{result} = {};
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $wmi = Win32::OLE->GetObject('winmgmts:root\WebAdministration');
    if (!defined($wmi)) {
        $self->{output}->add_option_msg(short_msg => "Cant create server object:" . Win32::OLE->LastError());
        $self->{output}->option_exit();
    }
    my $query = 'SELECT Name, AutoStart FROM ApplicationPool';
    my $resultset = $wmi->ExecQuery($query);
    # AutoStart -> 1/0
    # State -> 1=started, 2=starting, 3 = stopped, 4=stopping
	foreach my $obj (in $resultset) {
        my $name = $obj->{Name};
        my $auto_start = $obj->{AutoStart};
        my $state = $obj->GetState();
		
        if (defined($self->{option_results}->{filter_state}) && $state_map{$state} !~ /$self->{option_results}->{filter_state}/) {
            next;
        }
		
        next if (defined($self->{option_results}->{name}) && !defined($self->{option_results}->{use_regexp}) && $name ne $self->{option_results}->{name});
        next if (defined($self->{option_results}->{name}) && defined($self->{option_results}->{use_regexp}) && $name !~ /$self->{option_results}->{name}/);

        $self->{result}->{$name} = {AutoStart => $auto_start, State => $state};	
    }
}

sub run {
    my ($self, %options) = @_;
	
    $self->manage_selection();
    my $pools_display = '';
    my $pools_display_append = '';
    foreach my $name (sort(keys %{$self->{result}})) {
        $pools_display .= $pools_display_append . 'name = ' . $name  . 
                                ' [AutoStart = ' . $self->{result}->{$name}->{AutoStart} . ', ' . 
                                 'State = ' . $state_map{$self->{result}->{$name}->{State}} .
                                ']';
        $pools_display_append = ', ';
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List application pools: ' . $pools_display);
    $self->{output}->display(nolabel => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'auto_start', 'state']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection();
    foreach my $name (sort(keys %{$self->{result}})) {     
        $self->{output}->add_disco_entry(name => $name,
                                         auto_start => $self->{result}->{$name}->{AutoStart},
                                         state => $state_map{$self->{result}->{$name}->{State}}
                                         );
    }
}

1;

__END__

=head1 MODE

List IIS Application Pools.

=over 8

=item B<--name>

Set the application pool name.

=item B<--regexp>

Allows to use regexp to filter application pool name (with option --name).

=item B<--filter-state>

Filter application pool state. Regexp can be used.

=back

=cut