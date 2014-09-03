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

package storage::emc::clariion::mode::portstate;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "filter-name:s"     => { name => 'filter_name' },
                                  "filter-id:s"       => { name => 'filter_id' },
                                });
    $self->{total_port} = 0;
    $self->{total_port_noskip} = 0;
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub check_logged {
    my ($self, %options) = @_;
    
    
}

sub check_port {
    my ($self, %options) = @_;
    
    if ($self->{response} =~ /Information about each SPPORT:(.*)/msi) {
        my $port_infos = $1;
        
        while ($port_infos =~ /(SP Name:.*?)\n\n/msig) {
            my $port_infos = $1;
            
            # Not in good section
            next if ($port_infos !~ /Switch Present:/mi);
            $port_infos =~ /SP Name:\s*(.*?)\s*$/mi;
            my $port_name = $1;
            $port_infos =~ /SP Port ID:\s*(.*?)\s*$/mi;
            my $port_id = $1;
            $port_infos =~ /Link Status:\s*(.*?)\s*$/mi;
            my $link_status = $1;
            $port_infos =~ /Port Status:\s*(.*?)\s*$/mi;
            my $port_status = $1;
            
            $self->{total_port}++;
            if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' && $port_name !~ /$self->{option_results}->{filter_name}/) {
                $self->{output}->output_add(long_msg => "Skipping SP $port_name port $port_id [link status: $link_status] [port status: $port_status]");
                next;
            }
            if (defined($self->{option_results}->{filter_id}) && $self->{option_results}->{filter_id} ne '' && $port_id !~ /$self->{option_results}->{filter_id}/) {
                $self->{output}->output_add(long_msg => "Skipping SP $port_name port $port_id [link status: $link_status] [port status: $port_status]");
                next;
            }
            $self->{total_port_noskip}++;
            
            $self->{output}->output_add(long_msg => "Checking SP $port_name port $port_id [link status: $link_status] [port status: $port_status]");
            my ($error, $error_append) = ('', ''); 
            if ($port_status !~ /Online|Enabled/i) {
                $error = "port status is '" . $port_status . "'";
                $error_append = ', ';
            }
            if ($link_status !~ /Up/i) {
                $error .= $error_append . "link status is '" . $link_status . "'";
            }
            if ($error ne '') {
                $self->{output}->output_add(severity => 'CRITICAL',
                                            short_msg => sprintf("SP %s port %s: %s.", 
                                                                 $port_name, $port_id, $error)
                                            );
            }
        }
    }
}

sub run {
    my ($self, %options) = @_;
    my $clariion = $options{custom};
    
    $self->{response} = $clariion->execute_command(cmd => 'getall -hba');
    chomp $self->{response};

    $self->check_port();
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => sprintf("All ports (%s/%s) are ok.", 
                                                     $self->{total_port_noskip}, $self->{total_port})
                                );

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check SP port states.

=over 8

=item B<--filter-name>

Set SP Name to check (not set, means 'all').

=item B<--filter-id>

Set SP port ID to check (not set, means 'all').

=back

=cut