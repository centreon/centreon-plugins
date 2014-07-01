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

package apps::iis::wsman::mode::listapplicationpools;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %state_map = (
    1   => 'started',
    2   => 'starting',
    3   => 'stopped',
    4   => 'stopping'
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

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{result} = $self->{wsman}->request(uri => 'http://schemas.microsoft.com/wbem/wsman/1/wmi/root/MicrosoftIISv2/*',
                                              wql_filter => 'Select AppPoolState, AppPoolAutoStart, Name From IIsApplicationPoolSetting',
                                              result_type => 'hash',
                                              hash_key => 'Name');
    # AppPoolAutoStart -> true/false
    # AppPoolState -> 1=started, 2=starting, 3 = stopped, 4=stopping
    foreach my $name (sort(keys %{$self->{result}})) {
        if (defined($self->{option_results}->{filter_state}) && $state_map{$self->{result}->{$name}->{AppPoolState}} !~ /$self->{option_results}->{filter_state}/) {
            $self->{output}->output_add(long_msg => "Skipping application pool '" . $name . "': no matching filter state");
            delete $self->{result}->{$name};
            next;
        }
    
        # Get all without a name
        next if (!defined($self->{option_results}->{name}));
        
        next if (!defined($self->{option_results}->{use_regexp}) && $name eq $self->{option_results}->{name});
        next if (defined($self->{option_results}->{use_regexp}) && $name =~ /$self->{option_results}->{name}/);
        
        $self->{output}->output_add(long_msg => "Skipping application pool '" . $name . "': no matching filter name");
        delete $self->{result}->{$name};
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{wsman} = wsman object
    $self->{wsman} = $options{wsman};

    $self->manage_selection();
    foreach my $name (sort(keys %{$self->{result}})) {
        $self->{output}->output_add(long_msg => "'" . $name . "' [AutoStart = " . $self->{result}->{$name}->{AppPoolAutoStart} . '] [' . 
                                    'State = ' . $state_map{$self->{result}->{$name}->{AppPoolState}} .
                                    ']');
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List application pools:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'auto_start', 'state']);
}

sub disco_show {
    my ($self, %options) = @_;
    # $options{wsman} = wsman object
    $self->{wsman} = $options{wsman};

    $self->manage_selection();
    foreach my $name (sort(keys %{$self->{result}})) {     
        $self->{output}->add_disco_entry(name => $name,
                                         auto_start => $self->{result}->{$name}->{AppPoolAutoStart},
                                         state => $state_map{$self->{result}->{$name}->{AppPoolState}}
                                         );
    }
}

1;

__END__

=head1 MODE

List IIS Application Pools.
Need to install IIS WMI provider by installing the IIS Management Scripts and Tools component (compatibility IIS 6.0).

=over 8

=item B<--name>

Set the application pool name.

=item B<--regexp>

Allows to use regexp to filter application pool name (with option --name).

=item B<--filter-state>

Filter application pool state. Regexp can be used.

=back

=cut