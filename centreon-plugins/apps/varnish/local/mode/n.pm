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

package apps::varnish::local::mode::n;

use base qw(centreon::plugins::mode);
use centreon::plugins::misc;
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);

my $maps_counters = {
    n_sess_mem   => { thresholds => {
                                warning_mem  =>  { label => 'warning-mem', exit_value => 'warning' },
                                critical_mem =>  { label => 'critical-mem', exit_value => 'critical' },
                              },
                output_msg => 'N struct sess_mem: %.2f',
                factor => 1, unit => '',
               },
    n_sess => { thresholds => {
                                warning_sess  =>  { label => 'warning-sess', exit_value => 'warning' },
                                critical_sess =>  { label => 'critical-sess', exit_value => 'critical' },
                                },
                 output_msg => 'N struct sess: %.2f',
                 factor => 1, unit => '',
                },
    n_object => { thresholds => {
                                warning_object    =>  { label => 'warning-object', exit_value => 'warning' },
                                critical_object   =>  { label => 'critical-object', exit_value => 'critical' },
                                },
                 output_msg => 'N struct object: %.2f',
                 factor => 1, unit => '',
               },
    n_vampireobject => { thresholds => {
                                warning_vampireobject    =>  { label => 'warning-vampireobject', exit_value => 'warning' },
                                critical_vampireobject   =>  { label => 'critical-vampireobject', exit_value => 'critical' },
                                },
                 output_msg => 'N unresurrected objects: %.2f',
                 factor => 1, unit => '',
               },
    n_objectcore => { thresholds => {
                                warning_objectcore    =>  { label => 'warning-objectcore', exit_value => 'warning' },
                                critical_objectcore   =>  { label => 'critical-objectcore', exit_value => 'critical' },
                                },
                 output_msg => 'N struct objectcore: %.2f',
                 factor => 1, unit => '',
               },
    n_objecthead => { thresholds => {
                                warning_objecthead    =>  { label => 'warning-objecthead', exit_value => 'warning' },
                                critical_objecthead   =>  { label => 'critical-objecthead', exit_value => 'critical' },
                                },
                 output_msg => 'N struct objecthead: %.2f',
                 factor => 1, unit => '',
               },
    n_waitinglist => { thresholds => {
                                warning_waitinglist    =>  { label => 'warning-waitinglist', exit_value => 'warning' },
                                critical_waitinglist   =>  { label => 'critical-waitinglist', exit_value => 'critical' },
                                },
                 output_msg => 'N struct waitinglist: %.2f',
                 factor => 1, unit => '',
               },
    n_vbc => { thresholds => {
                                warning_vbc    =>  { label => 'warning-vbc', exit_value => 'warning' },
                                critical_vbc   =>  { label => 'critical-vbc', exit_value => 'critical' },
                                },
                 output_msg => 'N struct vbc: %.2f',
                 factor => 1, unit => '',
               },
    n_backend => { thresholds => {
                                warning_backend    =>  { label => 'warning-backend', exit_value => 'warning' },
                                critical_backend   =>  { label => 'critical-backend', exit_value => 'critical' },
                                },
                 output_msg => 'N backends: %.2f',
                 factor => 1, unit => '',
               },
    n_expired => { thresholds => {
                                warning_expired    =>  { label => 'warning-expired', exit_value => 'warning' },
                                critical_expired   =>  { label => 'critical-expired', exit_value => 'critical' },
                                },
                 output_msg => 'N expired objects: %.2f',
                 factor => 1, unit => '',
               },
    n_lru_nuked => { thresholds => {
                                warning_nuked    =>  { label => 'warning-nuked', exit_value => 'warning' },
                                critical_nuked   =>  { label => 'critical-nuked', exit_value => 'critical' },
                                },
                 output_msg => 'N LRU nuked objects: %.2f',
                 factor => 1, unit => '',
               },
    n_lru_moved => { thresholds => {
                                warning_moved    =>  { label => 'warning-moved', exit_value => 'warning' },
                                critical_moved   =>  { label => 'critical-moved', exit_value => 'critical' },
                                },
                 output_msg => 'N LRU moved objects: %.2f',
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
n_sess_mem      => N struct sess_mem,
n_sess          => N struct sess,
n_object        => N struct object,
n_vampireobject => N unresurrected objects,
n_objectcore    => N struct objectcore,
n_objecthead    => N struct objecthead,
n_waitinglist   => N struct waitinglist,
n_vbc           => N struct vbc,
n_backend       => N backends,
n_expired       => N expired objects,
n_lru_nuked     => N LRU nuked objects,
n_lru_moved     => N LRU moved objects

=item B<--critical-*>

Critical Threshold for: 
n_sess_mem      => N struct sess_mem,
n_sess          => N struct sess,
n_object        => N struct object,
n_vampireobject => N unresurrected objects,
n_objectcore    => N struct objectcore,
n_objecthead    => N struct objecthead,
n_waitinglist   => N struct waitinglist,
n_vbc           => N struct vbc,
n_backend       => N backends,
n_expired       => N expired objects,
n_lru_nuked     => N LRU nuked objects,
n_lru_moved     => N LRU moved objects

=back

=cut