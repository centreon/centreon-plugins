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

package os::windows::wsman::mode::service;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'warning'    => { name => 'warning' },
        'critical'   => { name => 'critical' },
        'services:s' => { name => 'services' },
        'auto'       => { name => 'auto' },
        'exclude:s'  => { name => 'exclude' },
    });

    $self->{service_rules} = {};
    $self->{wql_filter} = '';
    $self->{threshold} = 'CRITICAL';
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{services}) && !defined($self->{option_results}->{auto})) {
       $self->{output}->add_option_msg(short_msg => "Need to specify at least '--services' or '--auto' option.");
       $self->{output}->option_exit();
    }
    
    if (defined($self->{option_results}->{services})) {
        my $append = '';
        foreach my $rule (split /,/, $self->{option_results}->{services}) {
            if ($rule !~ /^([^\!=]*)(\!=|=){0,1}(.*){0,1}/) {
                $self->{output}->add_option_msg(short_msg => "Wrong rule in --services option: " . $rule);
                $self->{output}->option_exit();
            }
            if (!defined($1) || $1 eq '') {
                $self->{output}->add_option_msg(short_msg => "Need service name for rule: " . $rule);
                $self->{output}->option_exit();
            }
            
            my $sname = $1;
            my $operator = defined($2) && $2 ne '' ? $2 : '!=';
            my $state = defined($3) && $3 ne '' ? lc($3) : 'running';
            
            if ($operator !~ /^(=|\!=)$/) {
                $self->{output}->add_option_msg(short_msg => "Wrong operator for rule: " . $rule . ". Should be '=' or '!='.");
                $self->{output}->option_exit();
            }
            
            if ($state !~ /^(stopped|start pending|stop pending|running|continue pending|pause pending|paused|unknown)$/i) {
                $self->{output}->add_option_msg(short_msg => "Wrong state for rule: " . $rule . ". See help for available state.");
                $self->{output}->option_exit();
            }
            
            $self->{service_rules}->{$sname} = {operator => $operator, state => $state};
            $self->{wql_filter} .= $append . "Name = '" . $sname  . "'";
            $append = ' Or ';
        }
        
        if ($self->{wql_filter} eq '') {
            $self->{output}->add_option_msg(short_msg => "Need to specify one rule for --services option.");
            $self->{output}->option_exit();
        }
    }
        
    $self->{threshold} = 'WARNING' if (defined($self->{option_results}->{warning}));
    $self->{threshold} = 'CRITICAL' if (defined($self->{option_results}->{critical}));
}

sub check_auto {
    my ($self, %options) = @_;
    
    $self->{result} = $self->{wsman}->request(
        uri => 'http://schemas.microsoft.com/wbem/wsman/1/wmi/root/cimv2/*',
        wql_filter => "Select Name, State From Win32_Service Where StartMode = 'Auto'",
        result_type => 'hash',
        hash_key => 'Name'
    );
    foreach my $name (sort(keys %{$self->{result}})) {
        if (defined($self->{option_results}->{exclude}) && $self->{option_results}->{exclude} ne '' && $self->{result}->{$name}->{Name} =~ /$self->{option_results}->{exclude}/) {
            $self->{output}->output_add(long_msg => "Skipping Service '" . $self->{result}->{$name}->{Name} . "'");
            next;
        }
    
        $self->{output}->output_add(long_msg => "Service '" . $self->{result}->{$name}->{Name} . "' state: " . $self->{result}->{$name}->{State});
        if ($self->{result}->{$name}->{State} !~ /^running$/i) {
            $self->{output}->output_add(severity => $self->{threshold},
                                        short_msg => "Service '" . $self->{result}->{$name}->{Name} . "' is " . $self->{result}->{$name}->{State});
        }
    }
}

sub check {
    my ($self, %options) = @_;
    
    $self->{result} = $self->{wsman}->request(
        uri => 'http://schemas.microsoft.com/wbem/wsman/1/wmi/root/cimv2/*',
        wql_filter => 'Select Name, State From Win32_Service Where ' . $self->{wql_filter},
        result_type => 'hash',
        hash_key => 'Name'
    );
    foreach my $name (sort(keys %{$self->{service_rules}})) {
        if (!defined($self->{result}->{$name})) {
            $self->{output}->output_add(severity => 'UNKNOWN',
                                        short_msg => "Service '" . $name . "' not found");
            next;
        }
        
        $self->{output}->output_add(long_msg => "Service '" . $name . "' state: " . $self->{result}->{$name}->{State});
        if ($self->{service_rules}->{$name}->{operator} eq '=' && 
            lc($self->{result}->{$name}->{State}) eq $self->{service_rules}->{$name}->{state}) {
            $self->{output}->output_add(severity => $self->{threshold},
                                        short_msg => "Service '" . $self->{result}->{$name}->{Name} . "' is " . $self->{result}->{$name}->{State});
        } elsif ($self->{service_rules}->{$name}->{operator} eq '!=' && 
                 lc($self->{result}->{$name}->{State}) ne $self->{service_rules}->{$name}->{state}) {
            $self->{output}->output_add(severity => $self->{threshold},
                                        short_msg => "Service '" . $self->{result}->{$name}->{Name} . "' is " . $self->{result}->{$name}->{State});
        }
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{wsman} = $options{wsman};
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'All service states are ok');
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

Check Windows Services.

=over 8

=item B<--warning>

Return warning.

=item B<--critical>

Return critical.

=item B<--services>

Services to monitor.
Syntax: [service_name[[=|!=]state]],...
Available states are:
- Stopped
- Start Pending
- Stop Pending
- Running
- Continue Pending
- Pause Pending
- Paused
- Unknown

=item B<--auto>

Return threshold for auto services not running.

=item B<--exclude>

Exclude some services for --auto option (Can be a regexp).

=back

=cut
