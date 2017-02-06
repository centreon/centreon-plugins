#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

package apps::varnish::local::mode::totals;

use base qw(centreon::plugins::mode);
use centreon::plugins::misc;
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);

my $maps_counters = {
    s_sess   => { thresholds => {
                                warning_sess  =>  { label => 'warning-sess', exit_value => 'warning' },
                                critical_sess =>  { label => 'critical-sess', exit_value => 'critical' },
                              },
                output_msg => 'Total Sessions: %.2f',
                factor => 1, unit => '',
               },
    s_req => { thresholds => {
                                warning_req  =>  { label => 'warning-req', exit_value => 'warning' },
                                critical_req =>  { label => 'critical-req', exit_value => 'critical' },
                                },
                 output_msg => 'Total Requests: %.2f',
                 factor => 1, unit => '',
                },
    s_pipe => { thresholds => {
                                warning_pipe    =>  { label => 'warning-pipe', exit_value => 'warning' },
                                critical_pipe   =>  { label => 'critical-pipe', exit_value => 'critical' },
                                },
                 output_msg => 'Total pipe: %.2f',
                 factor => 1, unit => '',
               },
    s_pass => { thresholds => {
                                warning_pass    =>  { label => 'warning-pass', exit_value => 'warning' },
                                critical_pass   =>  { label => 'critical-pass', exit_value => 'critical' },
                                },
                 output_msg => 'Total pass: %.2f',
                 factor => 1, unit => '',
               },
    s_fetch => { thresholds => {
                                warning_fetch    =>  { label => 'warning-fetch', exit_value => 'warning' },
                                critical_fetch   =>  { label => 'critical-fetch', exit_value => 'critical' },
                                },
                 output_msg => 'Total fetch: %.2f',
                 factor => 1, unit => '',
               },
    s_hdrbytes => { thresholds => {
                                warning_hdrbytes    =>  { label => 'warning-hdrbytes', exit_value => 'warning' },
                                critical_hdrbytes   =>  { label => 'critical-hdrbytes', exit_value => 'critical' },
                                },
                 output_msg => 'Total header bytes: %.2f',
                 factor => 1, unit => '',
               },
    s_bodybytes => { thresholds => {
                                warning_bodybytes    =>  { label => 'warning-bodybytes', exit_value => 'warning' },
                                critical_bodybytes   =>  { label => 'critical-bodybytes', exit_value => 'critical' },
                                },
                 output_msg => 'Total body bytes: %.2f',
                 factor => 1, unit => '',
               },
    accept_fail => { thresholds => {
                                warning_fail    =>  { label => 'warning-fail', exit_value => 'warning' },
                                critical_fail   =>  { label => 'critical-fail', exit_value => 'critical' },
                                },
                 output_msg => 'Accept failures: %.2f',
                 factor => 1, unit => '',
               },
};

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
    {
        "hostname:s"         => { name => 'hostname' },
        "remote"             => { name => 'remote' },
        "ssh-option:s@"      => { name => 'ssh_option' },
        "ssh-path:s"         => { name => 'ssh_path' },
        "ssh-command:s"      => { name => 'ssh_command', default => 'ssh' },
        "timeout:s"          => { name => 'timeout', default => 30 },
        "sudo"               => { name => 'sudo' },
        "command:s"          => { name => 'command', default => 'varnishstat' },
        "command-path:s"     => { name => 'command_path', default => '/usr/bin' },
        "command-options:s"  => { name => 'command_options', default => ' -1 ' },
        "command-options2:s" => { name => 'command_options2', default => ' 2>&1' },
    });

    foreach (keys %{$maps_counters}) {
        foreach my $name (keys %{$maps_counters->{$_}->{thresholds}}) {
            $options{options}->add_options(arguments => {
                $maps_counters->{$_}->{thresholds}->{$name}->{label} . ':s'    => { name => $name },
            });
        };
    };

    $self->{instances_done} = {};
    $self->{statefile_value} = centreon::plugins::statefile->new(%options);
    return $self;
};

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    foreach (keys %{$maps_counters}) {
        foreach my $name (keys %{$maps_counters->{$_}->{thresholds}}) {
            if (($self->{perfdata}->threshold_validate(label => $maps_counters->{$_}->{thresholds}->{$name}->{label}, value => $self->{option_results}->{$name})) == 0) {
                $self->{output}->add_option_msg(short_msg => "Wrong " . $maps_counters->{$_}->{thresholds}->{$name}->{label} . " threshold '" . $self->{option_results}->{$name} . "'.");
                $self->{output}->option_exit();
            };
        };
    };
    $self->{statefile_value}->check_options(%options);
};

sub getdata {
    my ($self, %options) = @_;

    my $stdout = centreon::plugins::misc::execute(output => $self->{output},
                                                  options => $self->{option_results},
                                                  sudo => $self->{option_results}->{sudo},
                                                  command => $self->{option_results}->{command},
                                                  command_path => $self->{option_results}->{command_path},
                                                  command_options => $self->{option_results}->{command_options} . $self->{option_results}->{command_options2});
    #print $stdout;

    foreach (split(/\n/, $stdout)) {
        #client_conn            7390867         1.00 Client connections
        # - Symbolic entry name
        # - Value
        # - Per-second average over process lifetime, or a period if the value can not be averaged
        # - Descriptive text

        if  (/^(.\S*)\s*([0-9]*)\s*([0-9.]*)\s(.*)$/i) {
            #print "FOUND: " . $1 . "=" . $2 . "\n";
            $self->{result}->{$1} = $2;
        };
    };
};

sub run {
    my ($self, %options) = @_;

    $self->getdata();

    $self->{statefile_value}->read(statefile => 'cache_apps_varnish' . '_' . $self->{mode} . '_' . (defined($self->{option_results}->{name}) ? md5_hex($self->{option_results}->{name}) : md5_hex('all')));
    $self->{result}->{last_timestamp} = time();
    my $old_timestamp = $self->{statefile_value}->get(name => 'last_timestamp');
    
    # Calculate
    my $delta_time = $self->{result}->{last_timestamp} - $old_timestamp;
    $delta_time = 1 if ($delta_time == 0); # One seconds ;)

    
    foreach (keys %{$maps_counters}) {
        #print $_ . "\n";
        $self->{old_cache}->{$_} = $self->{statefile_value}->get(name => '$_');     # Get Data from Cache
        $self->{old_cache}->{$_} = 0 if ( $self->{old_cache}->{$_} > $self->{result}->{$_} );
        $self->{outputdata}->{$_} = ($self->{result}->{$_} - $self->{old_cache}->{$_}) / $delta_time;
    };

    # Write Cache if not there
    $self->{statefile_value}->write(data => $self->{result}); 
    if (!defined($old_timestamp)) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => "Buffer creation...");
        $self->{output}->display();
        $self->{output}->exit();
    }

    my @exits;
    foreach (keys %{$maps_counters}) {
        foreach my $name (keys %{$maps_counters->{$_}->{thresholds}}) {
            push @exits, $self->{perfdata}->threshold_check(value => $self->{outputdata}->{$_}, threshold => [ { label => $maps_counters->{$_}->{thresholds}->{$name}->{label}, 'exit_litteral' => $maps_counters->{$_}->{thresholds}->{$name}->{exit_value} }]);
        }
    }

    my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
    

    my $extra_label = '';
    $extra_label = '_' . $instance_output if ($num > 1);

    my $str_output = "";
    my $str_append = '';
    foreach (keys %{$maps_counters}) {
        $str_output .= $str_append . sprintf($maps_counters->{$_}->{output_msg}, $self->{outputdata}->{$_} * $maps_counters->{$_}->{factor});
        $str_append = ', ';
        my ($warning, $critical);
        foreach my $name (keys %{$maps_counters->{$_}->{thresholds}}) {
            $warning = $self->{perfdata}->get_perfdata_for_output(label => $maps_counters->{$_}->{thresholds}->{$name}->{label}) if ($maps_counters->{$_}->{thresholds}->{$name}->{exit_value} eq 'warning');
            $critical = $self->{perfdata}->get_perfdata_for_output(label => $maps_counters->{$_}->{thresholds}->{$name}->{label}) if ($maps_counters->{$_}->{thresholds}->{$name}->{exit_value} eq 'critical');
        }
        $self->{output}->perfdata_add(label => $_ . $extra_label, unit => $maps_counters->{$_}->{unit},
                                        value => sprintf("%.2f", $self->{outputdata}->{$_} * $maps_counters->{$_}->{factor}),
                                        warning => $warning,
                                        critical => $critical);
    }
    $self->{output}->output_add(severity => $exit,
                                short_msg => $str_output);

    $self->{output}->display();
    $self->{output}->exit();
};


1;

__END__

=head1 MODE

Check Varnish Cache with varnishstat Command

=over 8

=item B<--remote>

If you dont run this script locally, if you wanna use it remote, you can run it remotely with 'ssh'.

=item B<--hostname>

Hostname to query (need --remote).

=item B<--ssh-option>

Specify multiple options like the user (example: --ssh-option='-l=centreon-engine' --ssh-option='-p=52').

=item B<--command>

Varnishstat Binary Filename (Default: varnishstat)

=item B<--command-path>

Directory Path to Varnishstat Binary File (Default: /usr/bin)

=item B<--command-options>

Parameter for Binary File (Default: ' -1 ')

=item B<--warning-*>

Warning Threshold for: 
sess      => Total Sessions,
req       => Total Requests,
pipe      => Total pipe,
pass      => Total pass,
fetch     => Total fetch,
hdrbytes  => Total header bytes,
bodybytes => Total body bytes,
fail      => Accept failures

=item B<--critical-*>

Critical Threshold for: 
sess      => Total Sessions,
req       => Total Requests,
pipe      => Total pipe,
pass      => Total pass,
fetch     => Total fetch,
hdrbytes  => Total header bytes,
bodybytes => Total body bytes,
fail      => Accept failures

=back

=cut