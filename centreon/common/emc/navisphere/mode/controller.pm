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

package centreon::common::emc::navisphere::mode::controller;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::values;

my $maps_counters = {
    'read-iops'   => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'read', diff => 1 },
                                      ],
                        per_second => 1,
                        output_template => 'Read IOPs : %.2f',
                        perfdatas => [
                            { value => 'read_per_second',  template => '%.2f',
                              unit => 'iops', min => 0 },
                        ],
                    }
               },
    'write-iops'   => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'write', diff => 1 },
                                      ],
                        per_second => 1,
                        output_template => 'Write IOPs : %.2f',
                        perfdatas => [
                            { value => 'write_per_second', template => '%.2f',
                              unit => 'iops', min => 0 },
                        ],
                    }
               },
    'busy'  => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'idle_ticks', diff => 1 },
                                        { name => 'busy_ticks', diff => 1 },
                                      ],
                        closure_custom_calc => \&custom_busy_calc,
                        output_template => 'Busy : %.2f %%',
                        output_use => 'busy_prct',  threshold_use => 'busy_prct',
                        perfdatas => [
                            { value => 'busy_prct', template => '%.2f',
                              unit => '%', min => 0, max => 100 },
                        ],
                    }
               },
};

sub custom_busy_calc {
    my ($self, %options) = @_;
    my $diff_busy = ($options{new_datas}->{$self->{instance} . '_busy_ticks'} - $options{old_datas}->{$self->{instance} . '_busy_ticks'});
    my $total = $diff_busy
                + ($options{new_datas}->{$self->{instance} . '_idle_ticks'} - $options{old_datas}->{$self->{instance} . '_idle_ticks'});
    
    if ($total == 0) {
        $self->{error_msg} = "skipped";
        return -2;
    }
    
    $self->{result_values}->{busy_prct} = $diff_busy * 100 / $total;
    return 0;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {                       
                                });

    $self->{statefile_value} = centreon::plugins::statefile->new(%options);                           
     
    foreach (keys %{$maps_counters}) {
        $options{options}->add_options(arguments => {
                                                     'warning-' . $_ . ':s'    => { name => 'warning-' . $_ },
                                                     'critical-' . $_ . ':s'    => { name => 'critical-' . $_ },
                                      });
        my $class = $maps_counters->{$_}->{class};
        $maps_counters->{$_}->{obj} = $class->new(statefile => $self->{statefile_value},
                                                  output => $self->{output}, perfdata => $self->{perfdata},
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

    $self->{statefile_value}->check_options(%options);
}

sub run {
    my ($self, %options) = @_;
    my $clariion = $options{custom};
    
    $self->{response} = $clariion->execute_command(cmd => 'getcontrol -cbt -busy -write -read -idle');

    $self->manage_selection();
    
    $self->{new_datas} = {};
    $self->{statefile_value}->read(statefile => "cache_clariion_" . $clariion->{hostname}  . '_' . $self->{mode});
    $self->{new_datas}->{last_timestamp} = time();

    my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
    my @exits;
    foreach (sort keys %{$maps_counters}) {
        $maps_counters->{$_}->{obj}->set(instance => 'gcontrol');
    
        my ($value_check) = $maps_counters->{$_}->{obj}->execute(values => $self->{gcontrol},
                                                                 new_datas => $self->{new_datas});

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
                                    short_msg => "Global Controller $short_msg"
                                    );
    } else {
        $self->{output}->output_add(short_msg => "Global Controller $long_msg");
    }
    
    $self->{statefile_value}->write(data => $self->{new_datas});
    $self->{output}->display();
    $self->{output}->exit();
}

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{gcontrol} = {};
    $self->{gcontrol}->{read} = $self->{response} =~ /^Total Reads:\s*(\d+)/msi ? $1 : undef;
    $self->{gcontrol}->{write} = $self->{response} =~ /^Total Writes:\s*(\d+)/msi ? $1 : undef;;
    $self->{gcontrol}->{idle_ticks} = $self->{response} =~ /^Controller idle ticks:\s*(\d+)/msi ? $1 : undef;
    $self->{gcontrol}->{busy_ticks} = $self->{response} =~ /^Controller busy ticks:\s*(\d+)/msi ? $1 : undef;
}

1;

__END__

=head1 MODE

Check global controller (busy usage, iops). 

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'busy', 'read-iops', 'write-iops'.

=item B<--critical-*>

Threshold critical.
Can be: 'busy', 'read-iops', 'write-iops'.

=back

=cut
