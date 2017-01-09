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

package apps::php::apc::web::mode::memory;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::values;

my $maps_counters = {
    'used' => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'free' }, { name => 'used' }, 
                                      ],
                        closure_custom_calc => \&custom_used_calc,
                        closure_custom_output => \&custom_used_output,
                        threshold_use => 'used_prct',
                        output_error_template => 'Memory Usage: %s',
                        perfdatas => [
                            { value => 'used', label => 'used', template => '%d',
                              unit => 'B', min => 0, max => 'total', threshold_total => 'total' },
                        ],
                    }
               },
    'fragmentation' => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'fragmentation' },
                                      ],
                        output_template => 'Memory Fragmentation: %.2f %%', output_error_template => 'Memory Fragmentation: %s',
                        output_use => 'fragmentation_absolute', threshold_use => 'fragmentation_absolute',
                        perfdatas => [
                            { value => 'fragmentation_absolute', label => 'fragmentation', template => '%.2f',
                              unit => '%', min => 0, max => 100 },
                        ],
                    }
               },
};

sub custom_used_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_free'} + $options{new_datas}->{$self->{instance} . '_used'};
    $self->{result_values}->{free} = $options{new_datas}->{$self->{instance} . '_free'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_used'};
    $self->{result_values}->{free_prct} =  $self->{result_values}->{free} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{used_prct} =  $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    return 0;
}

sub custom_used_output {
    my ($self, %options) = @_;

    my ($total_value, $total_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($used_value, $used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($free_value, $free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});

    return sprintf("Memory Usage Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
                   $total_value . " " . $total_unit,
                   $used_value . " " . $used_unit, $self->{result_values}->{used_prct},
                   $free_value . " " . $free_unit, $self->{result_values}->{free_prct});
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                "hostname:s"        => { name => 'hostname' },
                                "port:s"            => { name => 'port', },
                                "proto:s"           => { name => 'proto' },
                                "urlpath:s"         => { name => 'url_path', default => "/apc.php" },
                                "credentials"       => { name => 'credentials' },
                                "username:s"        => { name => 'username' },
                                "password:s"        => { name => 'password' },
                                "proxyurl:s"        => { name => 'proxyurl' },
                                "timeout:s"         => { name => 'timeout', default => 30 },
                                });
    
    $self->{http} = centreon::plugins::http->new(output => $self->{output});
    
    foreach (keys %{$maps_counters}) {
        $options{options}->add_options(arguments => {
                                                     'warning-' . $_ . ':s'    => { name => 'warning-' . $_ },
                                                     'critical-' . $_ . ':s'    => { name => 'critical-' . $_ },
                                      });
        my $class = $maps_counters->{$_}->{class};
        $maps_counters->{$_}->{obj} = $class->new(output => $self->{output}, perfdata => $self->{perfdata},
                                                  label => $_);
        $maps_counters->{$_}->{obj}->set(%{$maps_counters->{$_}->{set}});
    }
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    foreach (keys %{$maps_counters}) {
        $maps_counters->{$_}->{obj}->init(option_results => $self->{option_results});
    }

    $self->{http}->set_options(%{$self->{option_results}});
}

sub run {
    my ($self, %options) = @_;
    $self->{webcontent} = $self->{http}->request();

    $self->manage_selection();

    my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
    my @exits;
    foreach (sort keys %{$maps_counters}) {
        $maps_counters->{$_}->{obj}->set(instance => 'mem');
    
        my ($value_check) = $maps_counters->{$_}->{obj}->execute(values => $self->{mem});

        if ($value_check != 0) {
            $long_msg .= $long_msg_append . $maps_counters->{$_}->{obj}->output_error();
            $long_msg_append = ', ';
            next;
        }
        my $exit2 = $maps_counters->{$_}->{obj}->threshold_check();
        push @exits, $exit2;

        my $output = $maps_counters->{$_}->{obj}->output();
        $long_msg .= $long_msg_append . $output;
        $long_msg_append = ', ';
        
        if (!$self->{output}->is_status(litteral => 1, value => $exit2, compare => 'ok')) {
            $short_msg .= $short_msg_append . $output;
            $short_msg_append = ', ';
        }
        
        $maps_counters->{$_}->{obj}->perfdata();
    }

    my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
    if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => "Apc $short_msg"
                                    );
    } else {
        $self->{output}->output_add(short_msg => "Apc $long_msg");
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

sub in_bytes {
    my ($self, %options) = @_;
    my $value = $options{value};
    
    if ($options{unit} =~ /^G/) {
        $value *= 1024 * 1024 * 1024;
    } elsif ($options{unit} =~ /^M/) {
        $value *= 1024 * 1024;
    } elsif ($options{unit} =~ /^K/) {
        $value *= 1024;
    }
    
    return $value;
}

sub manage_selection {
    my ($self, %options) = @_;
    
    my ($free, $used);
    if ($self->{webcontent} =~ /Memory Usage.*?Free:.*?([0-9\.]+)\s*(\S*)/msi) {
        $free = $self->in_bytes(value => $1, unit => $2);
    }
    if ($self->{webcontent} =~ /Memory Usage.*?Used:.*?([0-9\.]+)\s*(\S*)/msi) {
        $used = $self->in_bytes(value => $1, unit => $2);
    }
    $self->{mem} = {};
    $self->{mem}->{free} = $free;
    $self->{mem}->{used} = $used;
    $self->{mem}->{fragmentation} = $self->{webcontent} =~ /Fragmentation:.*?([0-9\.]+)/msi ? $1 : undef;
}

1;

__END__

=head1 MODE

Check memory usage. 

=over 8

=item B<--hostname>

IP Addr/FQDN of the webserver host

=item B<--port>

Port used by web server

=item B<--proxyurl>

Proxy URL if any

=item B<--proto>

Specify https if needed

=item B<--urlpath>

Set path to get server-status page in auto mode (Default: '/apc.php')

=item B<--credentials>

Specify this option if you access server-status page over basic authentification

=item B<--username>

Specify username for basic authentification (Mandatory if --credentials is specidied)

=item B<--password>

Specify password for basic authentification (Mandatory if --credentials is specidied)

=item B<--timeout>

Threshold for HTTP timeout (Default: 30)

=item B<--warning-*>

Threshold warning.
Can be: 'used' (in percent), 'fragmentation' (in percent).

=item B<--critical-*>

Threshold critical.
Can be: 'used' (in percent), 'fragmentation' (in percent).

=back

=cut
