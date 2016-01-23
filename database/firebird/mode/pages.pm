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

package database::firebird::mode::pages;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::values;
use centreon::plugins::statefile;

my $maps_counters = {
    global => {
        '000_reads'   => { set => {
                key_values => [ { name => 'reads', diff => 1 } ],
                per_second => 1,
                output_template => 'Reads : %.2f',
                perfdatas => [
                    { label => 'reads', template => '%.2f', value => 'reads_per_second',
                      unit => '/s', min => 0 },
                ],
            }
        },
        '001_writes'   => { set => {
                key_values => [ { name => 'writes', diff => 1 } ],
                per_second => 1,
                output_template => 'Writes : %.2f',
                perfdatas => [
                    { label => 'writes', template => '%.2f', value => 'writes_per_second',
                      unit => '/s', min => 0 },
                ],
            }
        },
        '002_fetches'   => { set => {
                key_values => [ { name => 'fetches', diff => 1 } ],
                per_second => 1,
                output_template => 'Fetches : %.2f',
                perfdatas => [
                    { label => 'fetches', template => '%.2f', value => 'fetches_per_second',
                      unit => '/s', min => 0 },
                ],
            }
        },
        '003_statement'   => { set => {
                key_values => [ { name => 'marks', diff => 1 } ],
                per_second => 1,
                output_template => 'Marks : %.2f',
                perfdatas => [
                    { label => 'marks', template => '%.2f', value => 'marks_per_second',
                      unit => '/s', min => 0 },
                ],
            }
        },
    },
};

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                });
    $self->{statefile_value} = centreon::plugins::statefile->new(%options);
    
    foreach my $key (('global')) {
        foreach (keys %{$maps_counters->{$key}}) {
            my ($id, $name) = split /_/;
            if (!defined($maps_counters->{$key}->{$_}->{threshold}) || $maps_counters->{$key}->{$_}->{threshold} != 0) {
                $options{options}->add_options(arguments => {
                                                    'warning-' . $name . ':s'    => { name => 'warning-' . $name },
                                                    'critical-' . $name . ':s'    => { name => 'critical-' . $name },
                                               });
            }
            $maps_counters->{$key}->{$_}->{obj} = centreon::plugins::values->new(statefile => $self->{statefile_value},
                                                      output => $self->{output}, perfdata => $self->{perfdata},
                                                      label => $name);
            $maps_counters->{$key}->{$_}->{obj}->set(%{$maps_counters->{$key}->{$_}->{set}});
        }
    }
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    foreach my $key (('global')) {
        foreach (keys %{$maps_counters->{$key}}) {
            $maps_counters->{$key}->{$_}->{obj}->init(option_results => $self->{option_results});
        }
    }
    
    $self->{statefile_value}->check_options(%options);
}

sub run {
    my ($self, %options) = @_;
    $self->{sql} = $options{sql};

    $self->manage_selection();
    
    $self->{new_datas} = {};
    $self->{statefile_value}->read(statefile => 'firebird_' . $self->{mode} . '_' . $self->{sql}->get_unique_id4save());
    $self->{new_datas}->{last_timestamp} = time();
    
    my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
    my @exits;
    
    foreach (sort keys %{$maps_counters->{global}}) {
        my $obj = $maps_counters->{global}->{$_}->{obj};
                
        $obj->set(instance => 'firebird');
    
        my ($value_check) = $obj->execute(values => $self->{firebird},
                                          new_datas => $self->{new_datas});

        if ($value_check != 0) {
            $long_msg .= $long_msg_append . $obj->output_error();
            $long_msg_append = ', ';
            next;
        }
        my $exit2 = $obj->threshold_check();
        push @exits, $exit2;

        my $output = $obj->output();
        $long_msg .= $long_msg_append . $output;
        $long_msg_append = ', ';
        
        if (!$self->{output}->is_status(litteral => 1, value => $exit2, compare => 'ok')) {
            $short_msg .= $short_msg_append . $output;
            $short_msg_append = ', ';
        }
        
        $obj->perfdata();
    }

    my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
    if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => "Page $short_msg"
                                    );
    } else {
        $self->{output}->output_add(short_msg => "Page $long_msg");
    }
    
    $self->{statefile_value}->write(data => $self->{new_datas});
    $self->{output}->display();
    $self->{output}->exit();
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{sql}->connect();
    $self->{sql}->query(query => q{SELECT MON$PAGE_READS as PAGE_READS, MON$PAGE_WRITES as PAGE_WRITES, MON$PAGE_FETCHES as PAGE_FETCHES, MON$PAGE_MARKS as PAGE_MARKS FROM MON$IO_STATS mi WHERE mi.MON$STAT_GROUP = 0});    
    my $row = $self->{sql}->fetchrow_hashref();
    if (!defined($row)) {
        $self->{output}->add_option_msg(short_msg => "Cannot get page informations");
        $self->{output}->option_exit();
    }
    
    $self->{firebird} = { reads => $row->{PAGE_READS}, writes => $row->{PAGE_WRITES}, 
        fetches => $row->{PAGE_FETCHES}, marks => $row->{PAGE_MARKS} };
}

1;

__END__

=head1 MODE

Check page statistics on current database. 

=over 8)

=item B<--warning-*>

Threshold warning.
Can be: 'reads', 'writes', 'fetches', 'marks'. 

=item B<--critical-*>

Threshold critical.
Can be: 'reads', 'writes', 'fetches', 'marks'. 

=back

=cut
