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

package snmp_standard::mode::dynamiccommand;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $oid_nsExtendArgs = '.1.3.6.1.4.1.8072.1.3.2.2.1.3';
my $oid_nsExtendStatus = '.1.3.6.1.4.1.8072.1.3.2.2.1.21'; # 4 = CreateAndGo
my $oid_nsExtendCommand = '.1.3.6.1.4.1.8072.1.3.2.2.1.2';
my $oid_nsExtendStorage = '.1.3.6.1.4.1.8072.1.3.2.2.1.20'; # 2 = Volatile (what we want)
my $oid_nsExtendExecType = '.1.3.6.1.4.1.8072.1.3.2.2.1.6'; # 1 = exec, 2 = sub shell

my $oid_nsExtendOutput1Line = '.1.3.6.1.4.1.8072.1.3.2.3.1.1';
my $oid_nsExtendOutNumLines = '.1.3.6.1.4.1.8072.1.3.2.3.1.3';
my $oid_nsExtendOutputFull = '.1.3.6.1.4.1.8072.1.3.2.3.1.2';
my $oid_nsExtendResult = '.1.3.6.1.4.1.8072.1.3.2.3.1.4';

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'label:s'   => { name => 'label' },
        'command:s' => { name => 'command' },
        'args:s'    => { name => 'args' },
        'shell'     => { name => 'shell' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{label})) {
       $self->{output}->add_option_msg(short_msg => "Need to specify an label.");
       $self->{output}->option_exit(); 
    }
    if (!defined($self->{option_results}->{command})) {
       $self->{output}->add_option_msg(short_msg => "Need to specify a command.");
       $self->{output}->option_exit(); 
    }
    if (!defined($self->{option_results}->{args})) {
       $self->{output}->add_option_msg(short_msg => "Need to specify arguments (can be empty).");
       $self->{output}->option_exit(); 
    }
}

sub get_instance {
    my ($self, %options) = @_;
    
    # nsExtendStatus.LengthStr.CharacterInDecimal
    my $instance = length($self->{option_results}->{label});
    foreach (split //, $self->{option_results}->{label}) {
        $instance .= '.' . ord($_);
    }
    
    return $instance;
}

sub create_command {
    my ($self, %options) = @_;
    my $oids2set = {};

    $oids2set->{$oid_nsExtendStatus . '.' . $options{instance}} = { value => 4, type => 'INTEGER' };
    $oids2set->{$oid_nsExtendArgs . '.' . $options{instance}} = { value => $self->{option_results}->{args}, type => 'OCTETSTR' };
    $oids2set->{$oid_nsExtendCommand . '.' . $options{instance}} = { value => $self->{option_results}->{command}, type => 'OCTETSTR' };
    $oids2set->{$oid_nsExtendExecType . '.' . $options{instance}} = { value => (defined($self->{option_results}->{shell}) ? 2 : 1), type => 'INTEGER' };
    $self->{snmp}->set(oids => $oids2set);
}

sub update_command {
    my ($self, %options) = @_;
    my $shell = defined($self->{option_results}->{shell}) ? 2 : 1;

    # Cannot change values
    if ($options{result}->{$oid_nsExtendStorage . '.' . $options{instance}} != 2) {
        $self->{output}->add_option_msg(short_msg => "Command label '" . $self->{option_results}->{label} . "' is not volatile. So we can't manage it.");
        $self->{output}->option_exit();
    }

    my $oids2set = {};
    if (!defined($options{result}->{$oid_nsExtendCommand . '.' . $options{instance}}) || 
        $options{result}->{$oid_nsExtendCommand . '.' . $options{instance}} ne $self->{option_results}->{command}) {
        $oids2set->{$oid_nsExtendCommand . '.' . $options{instance}} = { value => $self->{option_results}->{command}, type => 'OCTETSTR' };
    }
    if (!defined($options{result}->{$oid_nsExtendArgs . '.' . $options{instance}}) || 
        $options{result}->{$oid_nsExtendArgs . '.' . $options{instance}} ne $self->{option_results}->{args}) {
        $oids2set->{$oid_nsExtendArgs . '.' . $options{instance}} = { value => $self->{option_results}->{args}, type => 'OCTETSTR' };
    }
    if (!defined($options{result}->{$oid_nsExtendExecType . '.' . $options{instance}}) || 
        $options{result}->{$oid_nsExtendExecType . '.' . $options{instance}} ne $shell) {
        $oids2set->{$oid_nsExtendExecType . '.' . $options{instance}} = { value => $shell, type => 'INTEGER' };
    }
    
    if (scalar(keys %$oids2set) > 0) {
        $self->{snmp}->set(oids => $oids2set);
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    # snmpset -On -c test -v 2c localhost \
    #    '.1.3.6.1.4.1.8072.1.3.2.2.1.21.4.104.102.101.102'  = 4 \
    #    '.1.3.6.1.4.1.8072.1.3.2.2.1.2.4.104.102.101.102' = /bin/echo \
    #    '.1.3.6.1.4.1.8072.1.3.2.2.1.3.4.104.102.101.102'    = 'myplop' 
    #
    my $instance = $self->get_instance();
    $self->{snmp}->load(
        oids => [
            $oid_nsExtendArgs, $oid_nsExtendStatus, 
            $oid_nsExtendCommand, $oid_nsExtendStorage, $oid_nsExtendExecType
        ],
        instances => [$instance],
        instance_regexp => '^(.+)$'
    );
    my $result = $self->{snmp}->get_leef();

    if (!defined($result->{$oid_nsExtendCommand . '.' . $instance})) {
        $self->create_command(instance => $instance);
    } else {
        $self->update_command(result => $result, instance => $instance);
    }

    $result = $self->{snmp}->get_leef(
        oids => [
            $oid_nsExtendOutputFull . '.' . $instance,
            $oid_nsExtendResult . '.' . $instance
        ],
        nothing_quit => 1
    );
    
    $self->{output}->output_add(
        severity => $self->{output}->get_litteral_status(status => $result->{$oid_nsExtendResult . '.' . $instance}),
        short_msg => $result->{$oid_nsExtendOutputFull . '.' . $instance}
    );
    $self->{output}->display(force_ignore_perfdata => 1);
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Execute command through SNMP.
Some prerequisites:
- 'net-snmp' and 'NET-SNMP-EXTEND-MIB' support ;
- a write account.

=over 8

=item B<--label>

Label which identify the command

=item B<--command>

Command executable.

=item B<--args>

Command arguments.

=item B<--shell>

Use a sub-shell to execute the command.

=back

=cut
