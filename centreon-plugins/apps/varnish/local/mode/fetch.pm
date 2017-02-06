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

package apps::varnish::local::mode::fetch;

use base qw(centreon::plugins::mode);
use centreon::plugins::misc;
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);

my $maps_counters = {
    fetch_head   => { thresholds => {
                                warning_head  =>  { label => 'warning-head', exit_value => 'warning' },
                                critical_head =>  { label => 'critical-head', exit_value => 'critical' },
                              },
                output_msg => 'Fetch head: %.2f',
                factor => 1, unit => '',
               },
    fetch_length => { thresholds => {
                                warning_length  =>  { label => 'warning-length', exit_value => 'warning' },
                                critical_length =>  { label => 'critical-length', exit_value => 'critical' },
                                },
                 output_msg => 'Fetch with Length: %.2f',
                 factor => 1, unit => '',
                },
    fetch_chunked => { thresholds => {
                                warning_chunked    =>  { label => 'warning-chunked', exit_value => 'warning' },
                                critical_chunked   =>  { label => 'critical-chunked', exit_value => 'critical' },
                                },
                 output_msg => 'Fetch chunked: %.2f',
                 factor => 1, unit => '',
               },
    fetch_eof => { thresholds => {
                                warning_eof    =>  { label => 'warning-eof', exit_value => 'warning' },
                                critical_eof   =>  { label => 'critical-eof', exit_value => 'critical' },
                                },
                 output_msg => 'Fetch EOF: %.2f',
                 factor => 1, unit => '',
               },
    fetch_bad => { thresholds => {
                                warning_bad    =>  { label => 'warning-bad', exit_value => 'warning' },
                                critical_bad   =>  { label => 'critical-bad', exit_value => 'critical' },
                                },
                 output_msg => 'Fetch had bad headers: %.2f',
                 factor => 1, unit => '',
               },
    fetch_close => { thresholds => {
                                warning_close    =>  { label => 'warning-close', exit_value => 'warning' },
                                critical_close   =>  { label => 'critical-close', exit_value => 'critical' },
                                },
                 output_msg => 'Fetch wanted close: %.2f',
                 factor => 1, unit => '',
               },
    fetch_oldhttp => { thresholds => {
                                warning_oldhttp    =>  { label => 'warning-oldhttp', exit_value => 'warning' },
                                critical_oldhttp   =>  { label => 'critical-oldhttp', exit_value => 'critical' },
                                },
                 output_msg => 'Fetch pre HTTP/1.1 closed: %.2f',
                 factor => 1, unit => '',
               },
    fetch_zero => { thresholds => {
                                warning_zero    =>  { label => 'warning-zero', exit_value => 'warning' },
                                critical_zero   =>  { label => 'critical-zero', exit_value => 'critical' },
                                },
                 output_msg => 'Fetch zero len: %.2f',
                 factor => 1, unit => '',
               },
    fetch_failed => { thresholds => {
                                warning_failed    =>  { label => 'warning-failed', exit_value => 'warning' },
                                critical_failed   =>  { label => 'critical-failed', exit_value => 'critical' },
                                },
                 output_msg => 'Fetch failed: %.2f',
                 factor => 1, unit => '',
               },
    fetch_1xx => { thresholds => {
                                warning_1xx    =>  { label => 'warning-1xx', exit_value => 'warning' },
                                critical_1xx   =>  { label => 'critical-1xx', exit_value => 'critical' },
                                },
                 output_msg => 'Fetch no body (1xx): %.2f',
                 factor => 1, unit => '',
               },
    fetch_204 => { thresholds => {
                                warning_204    =>  { label => 'warning-204', exit_value => 'warning' },
                                critical_204   =>  { label => 'critical-204', exit_value => 'critical' },
                                },
                 output_msg => 'Fetch no body (204): %.2f',
                 factor => 1, unit => '',
               },
    fetch_304 => { thresholds => {
                                warning_304    =>  { label => 'warning-304', exit_value => 'warning' },
                                critical_304   =>  { label => 'critical-304', exit_value => 'critical' },
                                },
                 output_msg => 'Fetch no body (304): %.2f',
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
head    => Fetch head,
length  => Fetch with Length,
chunked => Fetch chunked,
eof     => Fetch EOF,
bad     => Fetch had bad headers,
close   => Fetch wanted close,
oldhttp => Fetch pre HTTP/1.1 closed,
zero    => Fetch zero len,
failed  => Fetch failed,
1xx     => Fetch no body (1xx),
204     => Fetch no body (204),
304     => Fetch no body (304)

=item B<--critical-*>

Critical Threshold for: 
head    => Fetch head,
length  => Fetch with Length,
chunked => Fetch chunked,
eof     => Fetch EOF,
bad     => Fetch had bad headers,
close   => Fetch wanted close,
oldhttp => Fetch pre HTTP/1.1 closed,
zero    => Fetch zero len,
failed  => Fetch failed,
1xx     => Fetch no body (1xx),
204     => Fetch no body (204),
304     => Fetch no body (304)

=back

=cut