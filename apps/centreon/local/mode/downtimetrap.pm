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

package apps::centreon::local::mode::downtimetrap;

use base qw(centreon::plugins::mode);

my $use_module_snmp;
my $use_module_netsnmp;

BEGIN {
    eval {
        require SNMP;
        SNMP->import();
    };
    if ($@) {
        $use_module_snmp = 0;
        eval {
            require Net::SNMP;
            Net::SNMP->import();
        };
        if ($@) {
            $use_module_netsnmp = 0;
        } else {
            $use_module_netsnmp = 1;
        }
    } else {
        $use_module_snmp = 1;
    }
}

use strict;
use warnings;
use Sys::Hostname;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                 "oid-trap:s"           => { name => 'oid_trap', default => '.1.3.6.1.4.1.50000.1.1' },
                                 "oid-hostname:s"       => { name => 'oid_hostname', default => '.1.3.6.1.4.1.50000.2.1' },
                                 "oid-start:s"          => { name => 'oid_start', default => '.1.3.6.1.4.1.50000.2.2' },
                                 "oid-end:s"            => { name => 'oid_end', default => '.1.3.6.1.4.1.50000.2.4' },
                                 "oid-author:s"         => { name => 'oid_author', default => '.1.3.6.1.4.1.50000.2.5' },
                                 "oid-comment:s"        => { name => 'oid_comment', default => '.1.3.6.1.4.1.50000.2.6' },
                                 "oid-duration:s"       => { name => 'oid_duration', default => '.1.3.6.1.4.1.50000.2.7' },
                                 "centreon-server:s"    => { name => 'centreon_server' },
                                 "author:s"             => { name => 'author', default => 'system reboot' },
                                 "comment:s"            => { name => 'comment', default => 'the system reboots.' },
                                 "duration:s"           => { name => 'duration', default => 300 },
                                 "wait:s"               => { name => 'wait' },
                                 "snmptrap-command:s"   => { name => 'snmptrap_command', default => 'snmptrap' },
                                 "display-options"      => { name => 'display_options' },
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{centreon_server}) || $self->{option_results}->{centreon_server} eq '') {
        $self->{output}->add_option_msg(short_msg => "Please set centreon-server option.");
        $self->{output}->option_exit();
    }
}

sub snmp_build_args {
    my ($self, %options) = @_;

    $self->{snmp_args} = { hostname => {}, duration => {} };    
    if ($self->{option_results}->{oid_hostname} =~ /^(.*)\.(\d+)$/) {
        $self->{snmp_args}->{hostname} = { oid => $1, instance => $2, val => hostname(), type => 'OCTETSTR', type_cmd => 's' };
    }
    if ($self->{option_results}->{oid_start} =~ /^(.*)\.(\d+)$/) {
        $self->{snmp_args}->{start} = { oid => $1, instance => $2, val => time(), type => 'INTEGER', type_cmd => 'i' };
    }
    if ($self->{option_results}->{oid_end} =~ /^(.*)\.(\d+)$/) {
        $self->{snmp_args}->{end} = { oid => $1, instance => $2, val => time() + $self->{option_results}->{duration}, type => 'INTEGER', type_cmd => 'i' };
    }
    if ($self->{option_results}->{oid_author} =~ /^(.*)\.(\d+)$/) {
        $self->{snmp_args}->{author} = { oid => $1, instance => $2, val => $self->{option_results}->{author}, type => 'OCTETSTR', type_cmd => 's' };
    }
    if ($self->{option_results}->{oid_comment} =~ /^(.*)\.(\d+)$/) {
        $self->{snmp_args}->{comment} = { oid => $1, instance => $2, val => $self->{option_results}->{comment}, type => 'OCTETSTR', type_cmd => 's' };
    }
    if ($self->{option_results}->{oid_duration} =~ /^(.*)\.(\d+)$/) {
        $self->{snmp_args}->{duration} = { oid => $1, instance => $2, val => $self->{snmp_args}->{end}->{val} - $self->{snmp_args}->{start}->{val}, type => 'INTEGER', type_cmd => 'i' };
    }
}

sub send_trap_snmp {
    my ($self, %options) = @_;
    
    $SNMP::auto_init_mib = 0;
    $self->snmp_build_args();

    my $varlist = new SNMP::VarList(
        new SNMP::Varbind([$self->{snmp_args}->{hostname}->{oid}, $self->{snmp_args}->{hostname}->{instance}, $self->{snmp_args}->{hostname}->{val}, $self->{snmp_args}->{hostname}->{type}]),
        new SNMP::Varbind([$self->{snmp_args}->{start}->{oid}, $self->{snmp_args}->{start}->{instance}, $self->{snmp_args}->{start}->{val}, $self->{snmp_args}->{start}->{type}]),
        new SNMP::Varbind([$self->{snmp_args}->{end}->{oid}, $self->{snmp_args}->{end}->{instance}, $self->{snmp_args}->{end}->{val}, $self->{snmp_args}->{end}->{type}]),
        new SNMP::Varbind([$self->{snmp_args}->{author}->{oid}, $self->{snmp_args}->{author}->{instance}, $self->{snmp_args}->{author}->{val}, $self->{snmp_args}->{author}->{type}]),
        new SNMP::Varbind([$self->{snmp_args}->{comment}->{oid}, $self->{snmp_args}->{comment}->{instance}, $self->{snmp_args}->{comment}->{val}, $self->{snmp_args}->{comment}->{type}]),
        new SNMP::Varbind([$self->{snmp_args}->{duration}->{oid}, $self->{snmp_args}->{duration}->{instance}, $self->{snmp_args}->{duration}->{val}, $self->{snmp_args}->{duration}->{type}]),
    );
    my $trapsess = new SNMP::TrapSession(DestHost => $self->{option_results}->{centreon_server}, RemotePort => 162,  
        UseNumeric => 1, Version => '2c', Community => 'public');
    $trapsess->trap(oid => $self->{option_results}->{oid_trap},
                    uptime => time(),
                    $varlist);
}

sub send_trap_netsnmp {
    my ($self, %options) = @_;
    
    $self->snmp_build_args();

    my ($snmp_session, $error) = Net::SNMP->session(-hostname   => $self->{option_results}->{centreon_server},
                                                    -community  => "public",
                                                    -port       => 162,
                                                    -version    => "snmpv2c",
                                                    -translate   => [-all => 0]);
    if (!defined($snmp_session)) {
        $self->{output}->add_option_msg(short_msg => "SNMP Session : $error");
        $self->{output}->option_exit();
    }
    
    my $args = [];
    push @$args, ('1.3.6.1.2.1.1.3.0', eval "Net::SNMP::TIMETICKS", time());
    push @$args, ('1.3.6.1.6.3.1.1.4.1.0', eval "Net::SNMP::OBJECT_IDENTIFIER", $self->{option_results}->{oid_trap});
    foreach (('hostname', 'start', 'end', 'author', 'comment', 'duration')) {
        my $type = $self->{snmp_args}->{$_}->{type};
        $type = 'OCTET_STRING' if ($type eq 'OCTETSTR');
        my $result;
        my $ltmp = "\$result = Net::SNMP::$type;";
        eval $ltmp;
        push @$args, ($self->{snmp_args}->{$_}->{oid} . '.' . $self->{snmp_args}->{$_}->{instance}, $result, $self->{snmp_args}->{$_}->{val});
    }    
    
    $snmp_session->snmpv2_trap(-varbindlist => $args);
    $snmp_session->close();
}

sub send_trap_cmd {
    my ($self, %options) = @_;
    
    $self->snmp_build_args();
    my $options = '-v 2c -c public ' . $self->{option_results}->{centreon_server} . ' ' . time() . ' ' . $self->{option_results}->{oid_trap};
    $options .= ' ' . $self->{snmp_args}->{hostname}->{oid} . '.' . $self->{snmp_args}->{hostname}->{instance} . ' ' . $self->{snmp_args}->{hostname}->{type_cmd} . ' "' . $self->{snmp_args}->{hostname}->{val} . '"';
    $options .= ' ' . $self->{snmp_args}->{start}->{oid} . '.' . $self->{snmp_args}->{start}->{instance} . ' ' . $self->{snmp_args}->{start}->{type_cmd} . ' "' . $self->{snmp_args}->{start}->{val} . '"';
    $options .= ' ' . $self->{snmp_args}->{end}->{oid} . '.' . $self->{snmp_args}->{end}->{instance} . ' ' . $self->{snmp_args}->{end}->{type_cmd} . ' "' . $self->{snmp_args}->{end}->{val} . '"';
    $options .= ' ' . $self->{snmp_args}->{author}->{oid} . '.' . $self->{snmp_args}->{author}->{instance} . ' ' . $self->{snmp_args}->{author}->{type_cmd} . ' "' . $self->{snmp_args}->{author}->{val} . '"';
    $options .= ' ' . $self->{snmp_args}->{comment}->{oid} . '.' . $self->{snmp_args}->{comment}->{instance} . ' ' . $self->{snmp_args}->{comment}->{type_cmd} . ' "' . $self->{snmp_args}->{comment}->{val} . '"';
    $options .= ' ' . $self->{snmp_args}->{duration}->{oid} . '.' . $self->{snmp_args}->{duration}->{instance} . ' ' . $self->{snmp_args}->{duration}->{type_cmd} . ' "' . $self->{snmp_args}->{duration}->{val} . '"';
    
    if (defined($self->{option_results}->{display_options})) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => $options);
        $self->{output}->display(force_ignore_perfdata => 1, nolabel => 1);
        $self->{output}->exit();
    }
    $self->{option_results}->{timeout} = 10;
    centreon::plugins::misc::execute(output => $self->{output},
                                     options => $self->{option_results},
                                     command => $self->{option_results}->{snmptrap_command},
                                     command_options => $options);
}

sub run {
    my ($self, %options) = @_;
    
    if ($use_module_snmp == 1 && !defined($self->{option_results}->{display_options})) {
        $self->send_trap_snmp();
    } elsif ($use_module_netsnmp == 1 && !defined($self->{option_results}->{display_options})) {
        $self->send_trap_netsnmp();
    } else {
        $self->send_trap_cmd();
    }
    
    if (defined($self->{option_results}->{wait}) && $self->{option_results}->{wait} =~ /\d+/) {
        sleep($self->{option_results}->{wait});
    }
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'SNMP trap sent.');
    $self->{output}->display(force_ignore_perfdata => 1);
    $self->{output}->exit();
    
}

1;

__END__

=head1 MODE

Send a SNMP trap to set a downtime.

=over 8

=item B<--oid-trap>

Specify OID trap (Default: '.1.3.6.1.4.1.50000.1.1')

=item B<--oid-hostname>

Specify OID for hostname (Default: '.1.3.6.1.4.1.50000.2.1')

=item B<--oid-start>

Specify OID for downtime start time (Default: '.1.3.6.1.4.1.50000.2.2')

=item B<--oid-end>

Specify OID for downtime end time (Default: '.1.3.6.1.4.1.50000.2.3')

=item B<--oid-author>

Specify OID for downtime author (Default: '.1.3.6.1.4.1.50000.2.4')

=item B<--oid-comment>

Specify OID for downtime comment (Default: '.1.3.6.1.4.1.50000.2.5')

=item B<--oid-duration>

Specify OID for downtime duration (Default: '.1.3.6.1.4.1.50000.2.6')

=item B<--centreon-server>

Address of centreon server to send the trap (Required)

=item B<--author>

Set the downtime author (Default: 'system reboot').

=item B<--comment>

Set the downtime comment (Default: 'the system reboots.').

=item B<--duration>

Set the downtime duration in seconds (Default: 300)

=item B<--wait>

Time in seconds to wait

=item B<--snmptrap-command>

snmptrap command used (Default: 'snmptrap').
Use if the SNMP perl module is not installed.

=item B<--display-options>

Only display snmptrap command options.

=back

=cut
