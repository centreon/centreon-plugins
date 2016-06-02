#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package hardware::server::sun::mgmt_cards::mode::showenvironment;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;
use hardware::server::sun::mgmt_cards::components::showenvironment::resources qw($thresholds);
use hardware::server::sun::mgmt_cards::components::showenvironment::psu;
use hardware::server::sun::mgmt_cards::components::showenvironment::fan;
use hardware::server::sun::mgmt_cards::components::showenvironment::temperature;
use hardware::server::sun::mgmt_cards::components::showenvironment::sensors;
use hardware::server::sun::mgmt_cards::components::showenvironment::voltage;
use hardware::server::sun::mgmt_cards::components::showenvironment::si;
use hardware::server::sun::mgmt_cards::components::showenvironment::disk;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "hostname:s"       => { name => 'hostname' },
                                  "port:s"           => { name => 'port', default => 23 },
                                  "username:s"       => { name => 'username' },
                                  "password:s"       => { name => 'password' },
                                  "timeout:s"        => { name => 'timeout', default => 30 },
                                  "command-plink:s"  => { name => 'command_plink', default => 'plink' },
                                  "ssh"              => { name => 'ssh' },           
                                  "exclude:s"        => { name => 'exclude' },
                                  "component:s"             => { name => 'component', default => 'all' },
                                  "no-component:s"          => { name => 'no_component' },
                                  "threshold-overload:s@"   => { name => 'threshold_overload' },
                                });
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

    $self->{overload_th} = {};
    foreach my $val (@{$self->{option_results}->{threshold_overload}}) {
        if ($val !~ /^(.*?),(.*?),(.*)$/) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload option '" . $val . "'.");
            $self->{output}->option_exit();
        }
        my ($section, $status, $filter) = ($1, $2, $3);
        if ($self->{output}->is_litteral_status(status => $status) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload status '" . $val . "'.");
            $self->{output}->option_exit();
        }
        $self->{overload_th}->{$section} = [] if (!defined($self->{overload_th}->{$section}));
        push @{$self->{overload_th}->{$section}}, {filter => $filter, status => $status};
    }
}

sub ssh_command {
    my ($self, %options) = @_;
    
    my $cmd_in = $self->{option_results}->{username} . '\n' . $self->{option_results}->{password} . '\nshowenvironment\nlogout\n';
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
    if ($exit_code != 0) {
        $stdout =~ s/\n/ - /g;
        $self->{output}->output_add(severity => 'UNKNOWN', 
                                    short_msg => "Command error: $stdout");
        $self->{output}->display();
        $self->{output}->exit();
    }

    if ($stdout !~ /Environmental Status/mi) {
        $self->{output}->output_add(long_msg => $stdout);
        $self->{output}->output_add(severity => 'UNKNOWN', 
                                    short_msg => "Command 'showenvironment' problems (see additional info).");
        $self->{output}->display();
        $self->{output}->exit();
    }
    
    return $stdout;
}

sub global {
    my ($self, %options) = @_;

    hardware::server::sun::mgmt_cards::components::showenvironment::psu::check($self);
    hardware::server::sun::mgmt_cards::components::showenvironment::fan::check($self);
    hardware::server::sun::mgmt_cards::components::showenvironment::temperature::check($self);
    hardware::server::sun::mgmt_cards::components::showenvironment::sensors::check($self);
    hardware::server::sun::mgmt_cards::components::showenvironment::voltage::check($self);
    hardware::server::sun::mgmt_cards::components::showenvironment::si::check($self);
    hardware::server::sun::mgmt_cards::components::showenvironment::disk::check($self);
}

sub component {
    my ($self, %options) = @_;
    
    if ($self->{option_results}->{component} eq 'si') {
        hardware::server::sun::mgmt_cards::components::showenvironment::si::check($self);
    } elsif ($self->{option_results}->{component} eq 'psu') {
        hardware::server::sun::mgmt_cards::components::showenvironment::psu::check($self);
    } elsif ($self->{option_results}->{component} eq 'fan') {
        hardware::server::sun::mgmt_cards::components::showenvironment::fan::check($self);
    } elsif ($self->{option_results}->{component} eq 'temperature') {
        hardware::server::sun::mgmt_cards::components::showenvironment::temperature::check($self);
    } elsif ($self->{option_results}->{component} eq 'sensors') {
        hardware::server::sun::mgmt_cards::components::showenvironment::sensors::check($self);
    } elsif ($self->{option_results}->{component} eq 'voltage') {
        hardware::server::sun::mgmt_cards::components::showenvironment::voltage::check($self);
    } elsif ($self->{option_results}->{component} eq 'disk') {
        hardware::server::sun::mgmt_cards::components::showenvironment::disk::check($self);
    } else {
        $self->{output}->add_option_msg(short_msg => "Wrong option. Cannot find component '" . $self->{option_results}->{component} . "'.");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    
    if (defined($self->{option_results}->{ssh})) {
        $self->{stdout} = $self->ssh_command();
    } else {
        my $telnet_handle = hardware::server::sun::mgmt_cards::lib::telnet::connect(
                                username => $self->{option_results}->{username},
                                password => $self->{option_results}->{password},
                                hostname => $self->{option_results}->{hostname},
                                port => $self->{option_results}->{port},
                                timeout => $self->{option_results}->{timeout},
                                output => $self->{output});
        my @lines = $telnet_handle->cmd("showenvironment");
        $self->{stdout} = join("", @lines);
    }
    
    $self->{stdout} =~ s/\r//msg;
    
    if ($self->{option_results}->{component} eq 'all') {
        $self->global();
    } else {
        $self->component();
    }
    
    my $total_components = 0;
    my $display_by_component = '';
    my $display_by_component_append = '';
    foreach my $comp (sort(keys %{$self->{components}})) {
        # Skipping short msg when no components
        next if ($self->{components}->{$comp}->{total} == 0 && $self->{components}->{$comp}->{skip} == 0);
        $total_components += $self->{components}->{$comp}->{total} + $self->{components}->{$comp}->{skip};
        $display_by_component .= $display_by_component_append . $self->{components}->{$comp}->{total} . '/' . $self->{components}->{$comp}->{skip} . ' ' . $self->{components}->{$comp}->{name};
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
        if (defined($self->{option_results}->{exclude}) && $self->{option_results}->{exclude} =~ /(^|\s|,)${options{section}}[^,]*#\Q$options{instance}\E#/) {
            $self->{components}->{$options{section}}->{skip}++;
            $self->{output}->output_add(long_msg => sprintf("Skipping $options{section} section $options{instance} instance."));
            return 1;
        }
    } elsif (defined($self->{option_results}->{exclude}) && $self->{option_results}->{exclude} =~ /(^|\s|,)$options{section}(\s|,|$)/) {
        $self->{output}->output_add(long_msg => sprintf("Skipping $options{section} section."));
        return 1;
    }
    return 0;
}

sub get_severity {
    my ($self, %options) = @_;
    my $status = 'UNKNOWN'; # default 
    
    if (defined($self->{overload_th}->{$options{section}})) {
        foreach (@{$self->{overload_th}->{$options{section}}}) {            
            if ($options{value} =~ /$_->{filter}/i) {
                $status = $_->{status};
                return $status;
            }
        }
    }
    foreach (@{$thresholds->{$options{section}}}) {           
        if ($options{value} =~ /$$_[0]/i) {
            $status = $$_[1];
            return $status;
        }
    }
    
    return $status;
}

1;

__END__

=head1 MODE

Check Sun vXXX (v240, v440, v245,...) Hardware (through ALOM).

=over 8

=item B<--hostname>

Hostname to query.

=item B<--port>

telnet port (Default: 23).

=item B<--username>

telnet username.

=item B<--password>

telnet password.

=item B<--timeout>

Timeout in seconds for the command (Default: 30).

=item B<--command-plink>

Plink command (default: plink). Use to set a path.

=item B<--ssh>

Use ssh (with plink) instead of telnet.

=item B<--component>

Which component to check (Default: 'all').
Can be: 'temperature', 'si', 'disk', 'fan', 'voltage', 'psu', 'sensors'.

=item B<--exclude>

Exclude some parts (comma seperated list) (Example: --exclude=fan)
Can also exclude specific instance: --exclude=fan#F1.RS#

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='fan,CRITICAL,^(?!(OK|NOT PRESENT)$)'

=back

=cut
