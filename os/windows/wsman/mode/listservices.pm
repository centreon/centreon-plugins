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

package os::windows::wsman::mode::listservices;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "name:s"          => { name => 'name' },
                                  "regexp"          => { name => 'use_regexp' },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{result} = $self->{wsman}->request(uri => 'http://schemas.microsoft.com/wbem/wsman/1/wmi/root/cimv2/*',
                                              wql_filter => 'Select Name, DisplayName, StartMode, State From Win32_Service',
                                              result_type => 'hash',
                                              hash_key => 'Name');
    foreach my $name (sort(keys %{$self->{result}})) {
        # Get all without a name
        next if (!defined($self->{option_results}->{name}));
        
        next if (!defined($self->{option_results}->{use_regexp}) && $name eq $self->{option_results}->{name});
        next if (defined($self->{option_results}->{use_regexp}) && $name =~ /$self->{option_results}->{name}/);
        
        delete $self->{result}->{$name};
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{wsman} = wsman object
    $self->{wsman} = $options{wsman};

    $self->manage_selection();
    my $services_display = '';
    my $services_display_append = '';
    foreach my $name (sort(keys %{$self->{result}})) {

        $services_display .= $services_display_append . 'name = ' . $name  . 
                                ' [DisplayName = ' . $self->{output}->to_utf8($self->{result}->{$name}->{DisplayName}) . ',' . 
                                 'StartMode = ' . $self->{result}->{$name}->{StartMode} . ',' .
                                 'State = ' . $self->{result}->{$name}->{State} .
                                ']';
        $services_display_append = ', ';
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List services: ' . $services_display);
    $self->{output}->display(nolabel => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'display_name', 'start_mode', 'state']);
}

sub disco_show {
    my ($self, %options) = @_;
    # $options{wsman} = wsman object
    $self->{wsman} = $options{wsman};

    $self->manage_selection();
    foreach my $name (sort(keys %{$self->{result}})) {     
        $self->{output}->add_disco_entry(name => $name,
                                         display_name => $self->{output}->to_utf8($self->{result}->{$name}->{DisplayName}),
                                         start_mode => $self->{result}->{$name}->{StartMode},
                                         state => $self->{result}->{$name}->{State}
                                         );
    }
}

1;

__END__

=head1 MODE

List Windows Services.

=over 8

=item B<--name>

Set the service name.

=item B<--regexp>

Allows to use regexp to filter service name (with option --name).

=back

=cut