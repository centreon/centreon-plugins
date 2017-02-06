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

package storage::hp::p2000::xmlapi::mode::volumesstats;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::statefile;
use centreon::plugins::values;

my $maps_counters = {
    read   => { class => 'centreon::plugins::values', obj => undef,
                set => {
                        key_values => [
                                        { name => 'data-read-numeric', diff => 1 },
                                      ],
                        per_second => 1,
                        output_template => 'Read I/O : %s %s/s',
                        output_change_bytes => 1,
                        perfdatas => [
                            { value => 'data-read-numeric_per_second', template => '%d',
                              unit => 'B/s', min => 0, label_extra_instance => 1 },
                        ],
                    }
               },
    write   => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'data-written-numeric', diff => 1 },
                                      ],
                        per_second => 1,
                        output_template => 'Write I/O : %s %s/s',
                        output_change_bytes => 1,
                        perfdatas => [
                            { value => 'data-written-numeric_per_second', template => '%d',
                              unit => 'B/s', min => 0, label_extra_instance => 1 },
                        ],
                    }
               },
    'write-cache-hits' => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'write-cache-hits', diff => 1 },
                                        { name => 'write-cache-misses', diff => 1 },
                                      ],
                        closure_custom_calc => \&custom_write_cache_calc,
                        output_template => 'Write Cache Hits : %.2f %%',
                        output_use => 'write-cache-hits_prct', threshold_use => 'write-cache-hits_prct',
                        perfdatas => [
                            { value => 'write-cache-hits_prct', template => '%.2f',
                              unit => '%', min => 0, max => 100, label_extra_instance => 1 },
                        ],
                    }
               },
    'read-cache-hits' => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'read-cache-hits', diff => 1 },
                                        { name => 'read-cache-misses', diff => 1 },
                                      ],
                        closure_custom_calc => \&custom_read_cache_calc,
                        output_template => 'Read Cache Hits : %.2f %%',
                        output_use => 'read-cache-hits_prct',  threshold_use => 'read-cache-hits_prct',
                        perfdatas => [
                            { value => 'read-cache-hits_prct', template => '%.2f',
                              unit => '%', min => 0, max => 100, label_extra_instance => 1 },
                        ],
                    }
               },
    iops   => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'iops' },
                                      ],
                        output_template => 'IOPs : %s',
                        perfdatas => [
                            { value => 'iops_absolute', 
                              unit => 'iops', min => 0, label_extra_instance => 1 },
                        ],
                    }
               },
};

sub custom_write_cache_calc {
    my ($self, %options) = @_;
    my $diff_hits = ($options{new_datas}->{$self->{instance} . '_write-cache-hits'} - $options{old_datas}->{$self->{instance} . '_write-cache-hits'});
    my $total = $diff_hits
                + ($options{new_datas}->{$self->{instance} . '_write-cache-misses'} - $options{old_datas}->{$self->{instance} . '_write-cache-misses'});
    
    if ($total == 0) {
        $self->{error_msg} = "skipped";
        return -2;
    }
    
    $self->{result_values}->{'write-cache-hits_prct'} = $diff_hits * 100 / $total;
    return 0;
}

sub custom_read_cache_calc {
    my ($self, %options) = @_;
    my $diff_hits = ($options{new_datas}->{$self->{instance} . '_read-cache-hits'} - $options{old_datas}->{$self->{instance} . '_read-cache-hits'});
    my $total = $diff_hits
                + ($options{new_datas}->{$self->{instance} . '_read-cache-misses'} - $options{old_datas}->{$self->{instance} . '_read-cache-misses'});
    
    if ($total == 0) {
        $self->{error_msg} = "skipped";
        return -2;
    }
    
    $self->{result_values}->{'read-cache-hits_prct'} = $diff_hits * 100 / $total;
    return 0;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "name:s"                => { name => 'name' },
                                  "regexp"                => { name => 'use_regexp' },
                                });
    $self->{volume_name_selected} = [];
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

sub manage_selection {
    my ($self, %options) = @_;

    $self->{results} = $self->{p2000}->get_infos(cmd => 'show volume-statistics', 
                                                 base_type => 'volume-statistics',
                                                 key => 'volume-name',
                                                 properties_name => '^data-read-numeric|data-written-numeric|write-cache-hits|write-cache-misses|read-cache-hits|read-cache-misses|iops$');
    foreach my $name (sort keys %{$self->{results}}) {
        # Get all without a name
        if (!defined($self->{option_results}->{name})) {
            push @{$self->{volume_name_selected}}, $name; 
            next;
        }
        
        if (!defined($self->{option_results}->{use_regexp}) && $name eq $self->{option_results}->{name}) {
            push @{$self->{volume_name_selected}}, $name;
            next;
        }
        if (defined($self->{option_results}->{use_regexp}) && $name =~ /$self->{option_results}->{name}/) {
            push @{$self->{volume_name_selected}}, $name;
            next;
        }        
    }

    if (scalar(@{$self->{volume_name_selected}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No volume found for name '" . $self->{option_results}->{name} . "'.");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{p2000} = $options{custom};
    
    $self->{p2000}->login(); 
    $self->manage_selection();
    
    my $multiple = 1;
    if (scalar(@{$self->{volume_name_selected}}) == 1) {
        $multiple = 0;
    }
    
    if ($multiple == 1) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All volumes statistics are ok.');
    }
    $self->{new_datas} = {};
    $self->{statefile_value}->read(statefile => "cache_hp_p2000_" . $self->{p2000}->{hostname}  . '_' . $self->{mode});
    $self->{new_datas}->{last_timestamp} = time();
    
    foreach my $name (sort @{$self->{volume_name_selected}}) {     
        my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
        my @exits;
        foreach (sort keys %{$maps_counters}) {
            $maps_counters->{$_}->{obj}->set(instance => $name);
        
            my ($value_check) = $maps_counters->{$_}->{obj}->execute(values => $self->{results}->{$name},
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
            
            $maps_counters->{$_}->{obj}->perfdata(extra_instance => $multiple);
        }

        $self->{output}->output_add(long_msg => "Volume '$name' $long_msg");
        my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
        if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => "Volume '$name' $short_msg"
                                        );
        }
        
        if ($multiple == 0) {
            $self->{output}->output_add(short_msg => "Volume '$name' $long_msg");
        }
    }
    
    $self->{statefile_value}->write(data => $self->{new_datas});
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check volume statistics.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'read', 'write', 'iops', 'write-cache-hits', 'read-cache-hits'.

=item B<--critical-*>

Threshold critical.
Can be: 'read', 'write', 'iops', 'write-cache-hits', 'read-cache-hits'.

=item B<--name>

Set the volume name.

=item B<--regexp>

Allows to use regexp to filter volume name (with option --name).

=back

=cut
    