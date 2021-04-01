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

package hardware::server::sun::mgmt_cards::mode::showboards;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;
use hardware::server::sun::mgmt_cards::lib::telnet;
use centreon::plugins::statefile;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                  "hostname:s"       => { name => 'hostname' },
                                  "port:s"           => { name => 'port', default => 23 },
                                  "username:s"       => { name => 'username' },
                                  "password:s"       => { name => 'password' },
                                  "timeout:s"        => { name => 'timeout', default => 50 },
                                  "memory"           => { name => 'memory' },
                                  "command-plink:s"  => { name => 'command_plink', default => 'plink' },
                                  "ssh"              => { name => 'ssh' },
                                  "exclude:s"        => { name => 'exclude' },
                                  "no-component:s"   => { name => 'no_component' },
                                });
    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);
    $self->{components} = {};
    $self->{no_components} = undef;

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{hostname})) {
       $self->{output}->add_option_msg(short_msg => "Need to specify a hostname.");
       $self->{output}->option_exit(); 
    }
    if (!defined($self->{option_results}->{username})) {
       $self->{output}->add_option_msg(short_msg => "Need to specify a username.");
       $self->{output}->option_exit(); 
    }
    if (!defined($self->{option_results}->{password})) {
       $self->{output}->add_option_msg(short_msg => "Need to specify a password.");
       $self->{output}->option_exit(); 
    }
    
    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->check_options(%options);
    }
    
    if (!defined($self->{option_results}->{ssh})) {
        require hardware::server::sun::mgmt_cards::lib::telnet;
    }
    
    if (defined($self->{option_results}->{no_component})) {
        if ($self->{option_results}->{no_component} ne '') {
            $self->{no_components} = $self->{option_results}->{no_component};
        } else {
            $self->{no_components} = 'critical';
        }
    }
}

sub telnet_shell_plateform {
    my ($telnet_handle) = @_;
    
    # There are:
    #System Controller 'sf6800':
    #   Type  0  for Platform Shell
    #   Type  1  for domain A console
    #   Type  2  for domain B console
    #   Type  3  for domain C console
    #   Type  4  for domain D console
    #   Input:
    
    $telnet_handle->waitfor(Match => '/Input:/i', Errmode => "return") or telnet_error($telnet_handle->errmsg);
    $telnet_handle->print("0");
}

sub ssh_command {
    my ($self, %options) = @_;
    my $username = '';
    
    if (defined($self->{option_results}->{username}) && $self->{option_results}->{username} ne '') {
        $username = $self->{option_results}->{username} . '\n';
    }
    
    my $cmd_in = "0" . $username . $self->{option_results}->{password} . '\nshowboards\ndisconnect\n';
    my $cmd = "echo -e '$cmd_in' | " . $self->{option_results}->{command_plink} . " -batch " . $self->{option_results}->{hostname} . " 2>&1";
    my ($lerror, $stdout, $exit_code) = centreon::plugins::misc::backtick(
                                                 command => $cmd,
                                                 timeout => $self->{option_results}->{timeout},
                                                 wait_exit => 1
                                                 );
    $stdout =~ s/\r//g;
    if ($lerror <= -1000) {
        $self->{output}->output_add(severity => 'UNKNOWN', 
                                    short_msg => $stdout);
        $self->{output}->display();
        $self->{output}->exit();
    }
    
    return $stdout;
}

sub run {
    my ($self, %options) = @_;
    my ($output, @lines);
    
    if (defined($self->{option_results}->{ssh})) {
        $output = $self->ssh_command();
        @lines = split /\n/, $output;
    } else {
        my $telnet_handle = hardware::server::sun::mgmt_cards::lib::telnet::connect(
                                username => $self->{option_results}->{username},
                                password => $self->{option_results}->{password},
                                hostname => $self->{option_results}->{hostname},
                                port => $self->{option_results}->{port},
                                timeout => $self->{option_results}->{timeout},
                                output => $self->{output},
                                closure => \&telnet_shell_plateform);
        @lines = $telnet_handle->cmd("showboards");
    }
    
    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->read(statefile => 'cache_sun_mgmtcards_' . $self->{option_results}->{hostname}  . '_' .  $self->{mode});
    }
    
    #Slot     Pwr Component Type                 State      Status     Domain
    #----     --- --------------                 -----      ------     ------
    #SSC0     On  System Controller              Main       Passed     -
    #ID0      On  Sun Fire 6800 Centerplane      -          OK         -
    #PS0      On  A212 Power Supply              -          OK         -
    #PS1      On  A212 Power Supply              -          OK         -
    #PS2      On  A212 Power Supply              -          OK         -
    #PS3      On  A212 Power Supply              -          OK         -
    #PS4      On  A212 Power Supply              -          OK         -
    #PS5      On  A212 Power Supply              -          OK         -

    my $datas = {};
    $self->{output}->output_add(long_msg => "Checking slots");
    $self->{components}->{slot} = {name => 'slot', total => 0, skip => 0, known_error => 0};

    foreach (@lines) {
        chomp;

        my ($id, $status);
        $id = $1 if (/([^\s]+?)\s+/);
        $status = $1 if (/\s+(Degraded|Failed|Not tested|Passed|OK|Under Test)\s+/i);
        next if (!defined($status) || $status eq '');
        
        next if ($self->check_exclude(section => 'slot', instance => $id));
        $self->{components}->{slot}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Slot '%s' status is %s.",
                                                        $id, $status)
                                    );
        if ($status =~ /^(Degraded|Failed)$/i) {
            if (defined($self->{option_results}->{memory})) {
                my $old_status = $self->{statefile_cache}->get(name => "slot_$id");
                if (!defined($old_status) || $old_status ne $status) {
                    $self->{output}->output_add(severity => 'CRITICAL', 
                                                short_msg => "Slot '$id' status is '$status'");
                } else {
                    $self->{components}->{slot}->{known_error}++;
                }
                $datas->{"slot_$id"} = $status;
            } else {
                $self->{output}->output_add(severity => 'CRITICAL', 
                                            short_msg => "Slot '$id' status is '$status'");
            }
        }
    }
    
    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->write(data => $datas);
    }
    
    my $total_components = 0;
    my $display_by_component = '';
    my $display_by_component_append = '';
    foreach my $comp (sort(keys %{$self->{components}})) {
        # Skipping short msg when no components
        next if ($self->{components}->{$comp}->{total} == 0 && $self->{components}->{$comp}->{skip} == 0);
        $total_components += $self->{components}->{$comp}->{total} + $self->{components}->{$comp}->{skip};
        $display_by_component .= $display_by_component_append . $self->{components}->{$comp}->{total} . '/' . $self->{components}->{$comp}->{skip} . '/' . $self->{components}->{$comp}->{known_error} . ' ' . $self->{components}->{$comp}->{name};
        $display_by_component_append = ', ';
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => sprintf("All %s components [%s] are ok.", 
                                                     $total_components,
                                                     $display_by_component)
                                );

    if (defined($self->{option_results}->{no_component}) && $total_components == 0) {
        $self->{output}->output_add(severity => $self->{no_components},
                                    short_msg => 'No components are checked.');
    }
 
    $self->{output}->display();
    $self->{output}->exit();
}

sub check_exclude {
    my ($self, %options) = @_;

    if (defined($options{instance})) {
        if (defined($self->{option_results}->{exclude}) && $self->{option_results}->{exclude} =~ /(^|\s|,)$options{instance}(\s|,|$)/) {
            $self->{output}->output_add(long_msg => sprintf("Skipping $options{instance}."));
            return 1;
        }
    }
    return 0;
}

1;

__END__

=head1 MODE

Check Sun SFxxxx (sf6900, sf6800, sf3800,...) Hardware (through ScApp).

=over 8

=item B<--hostname>

Hostname to query.

=item B<--port>

telnet port (Default: 23).

=item B<--username>

telnet username.

=item B<--password>

telnet password.

=item B<--memory>

Returns new errors (retention file is used by the following option).

=item B<--timeout>

Timeout in seconds for the command (Default: 30).

=item B<--command-plink>

Plink command (default: plink). Use to set a path.

=item B<--ssh>

Use ssh (with plink) instead of telnet.

=item B<--exclude>

Exclude some slots (comma seperated list) (Example: --exclude=IDO,PS0)

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=back

=cut
