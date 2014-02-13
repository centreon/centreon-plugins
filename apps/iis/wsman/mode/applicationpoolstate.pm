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

package apps::iis::wsman::mode::applicationpoolstate;

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
                                  "warning"             => { name => 'warning', },
                                  "critical"            => { name => 'critical', },
                                  "pools:s"             => { name => 'pools', },
                                  "auto"                => { name => 'auto', },
                                  "exclude:s"           => { name => 'exclude', },
                                });
    $self->{pools_rules} = {};
    $self->{wql_filter} = '';
    $self->{threshold} = 'CRITICAL';
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{pools}) && !defined($self->{option_results}->{auto})) {
       $self->{output}->add_option_msg(short_msg => "Need to specify at least '--pools' or '--auto' option.");
       $self->{output}->option_exit();
    }
    
    if (defined($self->{option_results}->{pools})) {
        my $append = '';
        foreach my $rule (split /,/, $self->{option_results}->{pools}) {
            if ($rule !~ /^([^\!=]*)(\!=|=){0,1}(.*){0,1}/) {
                $self->{output}->add_option_msg(short_msg => "Wrong rule in --pools option: " . $rule);
                $self->{output}->option_exit();
            }
            if (!defined($1) || $1 eq '') {
                $self->{output}->add_option_msg(short_msg => "Need pool name for rule: " . $rule);
                $self->{output}->option_exit();
            }
            
            my $poolname = $1;
            my $operator = defined($2) && $2 ne '' ? $2 : '!=';
            my $state = defined($3) && $3 ne '' ? lc($3) : 'starting';
            
            if ($operator !~ /^(=|\!=)$/) {
                $self->{output}->add_option_msg(short_msg => "Wrong operator for rule: " . $rule . ". Should be '=' or '!='.");
                $self->{output}->option_exit();
            }
            
            if ($state !~ /^(started|starting|stopped|stopping)$/i) {
                $self->{output}->add_option_msg(short_msg => "Wrong state for rule: " . $rule . ". See help for available state.");
                $self->{output}->option_exit();
            }
            
            $self->{service_rules}->{$poolname} = {operator => $operator, state => $state};
            $self->{wql_filter} .= $append . "Name = '" . $poolname  . "'";
            $append = ' Or ';
        }
        
        if ($self->{wql_filter} eq '') {
            $self->{output}->add_option_msg(short_msg => "Need to specify one rule for --pools option.");
            $self->{output}->option_exit();
        }
    }
        
    $self->{threshold} = 'WARNING' if (defined($self->{option_results}->{warning}));
    $self->{threshold} = 'CRITICAL' if (defined($self->{option_results}->{critical}));
}

sub check_auto {
    my ($self, %options) = @_;
    
    $self->{result} = $self->{wsman}->request(uri => 'http://schemas.microsoft.com/wbem/wsman/1/wmi/root/MicrosoftIISv2/*',
                                              wql_filter => "Select AppPoolState, Name From IIsApplicationPoolSetting Where AppPoolAutoStart = 'true'",
                                              result_type => 'hash',
                                              hash_key => 'Name');
    foreach my $name (sort(keys %{$self->{result}})) {
        if (defined($self->{option_results}->{exclude}) && $self->{option_results}->{exclude} ne '' && $self->{result}->{$name}->{Name} =~ /$self->{option_results}->{exclude}/) {
            $self->{output}->output_add(long_msg => "Skipping pool '" . $self->{result}->{$name}->{Name} . "'");
            next;
        }
    
        $self->{output}->output_add(long_msg => "Pool '" . $self->{result}->{$name}->{Name} . "' state: " . $state_map{$self->{result}->{$name}->{AppPoolState}});
        if ($state_map{$self->{result}->{$name}->{AppPoolState}} !~ /^starting$/i) {
            $self->{output}->output_add(severity => $self->{threshold},
                                        short_msg => "Service '" . $self->{result}->{$name}->{Name} . "' is " . $state_map{$self->{result}->{$name}->{AppPoolState}});
        }
    }
}

sub check {
    my ($self, %options) = @_;
    
    $self->{result} = $self->{wsman}->request(uri => 'http://schemas.microsoft.com/wbem/wsman/1/wmi/root/MicrosoftIISv2/*',
                                              wql_filter => 'Select AppPoolState, Name From IIsApplicationPoolSetting Where ' . $self->{wql_filter},
                                              result_type => 'hash',
                                              hash_key => 'Name');
    foreach my $name (sort(keys %{$self->{service_rules}})) {
        if (!defined($self->{result}->{$name})) {
            $self->{output}->output_add(severity => 'UNKNOWN',
                                        short_msg => "Pool '" . $name . "' not found");
            next;
        }
        
        $self->{output}->output_add(long_msg => "Pool '" . $name . "' state: " . $state_map{$self->{result}->{$name}->{AppPoolState}});
        if ($self->{service_rules}->{$name}->{operator} eq '=' && 
            $state_map{$self->{result}->{$name}->{AppPoolState}} eq $self->{service_rules}->{$name}->{state}) {
            $self->{output}->output_add(severity => $self->{threshold},
                                        short_msg => "Pool '" . $self->{result}->{$name}->{Name} . "' is " . $state_map{$self->{result}->{$name}->{AppPoolState}});
        } elsif ($self->{service_rules}->{$name}->{operator} eq '!=' && 
                 $state_map{$self->{result}->{$name}->{AppPoolState}} ne $self->{service_rules}->{$name}->{state}) {
            $self->{output}->output_add(severity => $self->{threshold},
                                        short_msg => "Service '" . $self->{result}->{$name}->{Name} . "' is " . $state_map{$self->{result}->{$name}->{AppPoolState}});
        }
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{wsman} = wsman object
    $self->{wsman} = $options{wsman};
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'All application pools are ok');
    if (defined($self->{option_results}->{auto})) {
        $self->check_auto();
    } else {
        $self->check();
    }
   
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check IIS Application Pools State.
Need to install IIS WMI provider by installing the IIS Management Scripts and Tools component (compatibility IIS 6.0).

=over 8

=item B<--warning>

Return warning.

=item B<--critical>

Return critical.

=item B<--pools>

Application Pool to monitor.
Syntax: [pool_name[[=|!=]state]],...
Available states are:
- 'started',
- 'starting',
- 'stopped',
- 'stopping'

=item B<--auto>

Return threshold for auto start pools not starting.

=item B<--exclude>

Exclude some pool for --auto option (Can be a regexp).

=back

=cut