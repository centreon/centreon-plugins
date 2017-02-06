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

package database::firebird::mode::memory;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::values;

my $maps_counters = {
    global => {
        '000_used'   => { set => {
                key_values => [ { name => 'database_used' }, { name => 'database_allocated' } ],
                closure_custom_calc => \&custom_unit_calc, closure_custom_calc_extra_options => { label_ref => 'database' },
                closure_custom_output => \&custom_used_output,
                threshold_use => 'prct',
                closure_custom_perfdata => \&custom_used_perfdata,
            }
        },
        '001_attachment'   => { set => {
                key_values => [ { name => 'attachment_used' }, { name => 'database_allocated' } ],
                closure_custom_calc => \&custom_unit_calc, closure_custom_calc_extra_options => { label_ref => 'attachment' },
                closure_custom_output => \&custom_unit_output,
                threshold_use => 'prct',
                closure_custom_perfdata => \&custom_unit_perfdata,
            }
        },
        '002_transaction'   => { set => {
                key_values => [ { name => 'transaction_used' }, { name => 'database_allocated' } ],
                closure_custom_calc => \&custom_unit_calc, closure_custom_calc_extra_options => { label_ref => 'transaction' },
                closure_custom_output => \&custom_unit_output,
                threshold_use => 'prct',
                closure_custom_perfdata => \&custom_unit_perfdata,
            }
        },
        '003_statement'   => { set => {
                key_values => [ { name => 'statement_used' }, { name => 'database_allocated' } ],
                closure_custom_calc => \&custom_unit_calc, closure_custom_calc_extra_options => { label_ref => 'statement' },
                closure_custom_output => \&custom_unit_output,
                threshold_use => 'prct',
                closure_custom_perfdata => \&custom_unit_perfdata,
            }
        },
        '004_call'   => { set => {
                key_values => [ { name => 'call_used' }, { name => 'database_allocated' } ],
                closure_custom_calc => \&custom_unit_calc, closure_custom_calc_extra_options => { label_ref => 'call' },
                closure_custom_output => \&custom_unit_output,
                threshold_use => 'prct',
                closure_custom_perfdata => \&custom_unit_perfdata,
            }
        },
    },
};

sub custom_used_output {
    my ($self, %options) = @_;
    
    my $free = $self->{result_values}->{total} - $self->{result_values}->{used};
    my ($total_value, $total_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($used_value, $used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($free_value, $free_unit) = $self->{perfdata}->change_bytes(value => $free);
    my $msg = sprintf("Total: %s Used : %s (%.2f %%) Free : %s (%.2f %%)",
                      $total_value . ' ' . $total_unit,
                      $used_value . ' ' . $used_unit, $self->{result_values}->{prct},
                      $free_value . ' ' . $free_unit, 100 - $self->{result_values}->{prct});
    return $msg;
}

sub custom_used_perfdata {
    my ($self, %options) = @_;
    
    $self->{output}->perfdata_add(label => 'used', unit => 'B',
                                  value => $self->{result_values}->{used},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}, total => $self->{result_values}->{total}, cast_int => 1),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}, total => $self->{result_values}->{total}, cast_int => 1),
                                  min => 0, max => $self->{result_values}->{total});
}

sub custom_unit_perfdata {
    my ($self, %options) = @_;
    
    $self->{output}->perfdata_add(label => $self->{result_values}->{label}, unit => 'B',
                                  value => $self->{result_values}->{used},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}, total => $self->{result_values}->{total}, cast_int => 1),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}, total => $self->{result_values}->{total}, cast_int => 1),
                                  min => 0, max => $self->{result_values}->{total});
}

sub custom_unit_output {
    my ($self, %options) = @_;
    
    my ($used_value, $used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my $msg = sprintf("%s : %s (%.2f %%)",
                      ucfirst($self->{result_values}->{label}),
                      $used_value . ' ' . $used_unit, $self->{result_values}->{prct});
    return $msg;
}

sub custom_unit_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_database_allocated'};
    if ($self->{result_values}->{total} == 0) {
        $self->{error_msg} = "skipped";
        return -2;
    }
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref} . '_used'};    
    $self->{result_values}->{prct} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{label} = $options{extra_options}->{label_ref};

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
    
    foreach my $key (('global')) {
        foreach (keys %{$maps_counters->{$key}}) {
            my ($id, $name) = split /_/;
            if (!defined($maps_counters->{$key}->{$_}->{threshold}) || $maps_counters->{$key}->{$_}->{threshold} != 0) {
                $options{options}->add_options(arguments => {
                                                    'warning-' . $name . ':s'    => { name => 'warning-' . $name },
                                                    'critical-' . $name . ':s'    => { name => 'critical-' . $name },
                                               });
            }
            $maps_counters->{$key}->{$_}->{obj} = centreon::plugins::values->new(output => $self->{output},
                                                      perfdata => $self->{perfdata},
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
}

sub run {
    my ($self, %options) = @_;
    $self->{sql} = $options{sql};

    $self->manage_selection();
    
    my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
    my @exits;
    
    foreach (sort keys %{$maps_counters->{global}}) {
        my $obj = $maps_counters->{global}->{$_}->{obj};
                
        $obj->set(instance => 'firebird');
    
        my ($value_check) = $obj->execute(values => $self->{firebird});

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
                                    short_msg => "Memory $short_msg"
                                    );
    } else {
        $self->{output}->output_add(short_msg => "Memory $long_msg");
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{sql}->connect();
    $self->{sql}->query(query => q{SELECT MON$STAT_GROUP as MYGROUP, MON$MEMORY_ALLOCATED AS MYTOTAL, MON$MEMORY_USED AS MYUSED FROM MON$MEMORY_USAGE});
    
    my %map_group = (0 => 'database', 1 => 'attachment', 2 => 'transaction', 3 => 'statement', 4 => 'call'); 
    
    $self->{firebird} = {};
    while ((my $row = $self->{sql}->fetchrow_hashref())) {
        if (!defined($self->{firebird}->{$map_group{$row->{MYGROUP}} . '_used'})) {
            $self->{firebird}->{$map_group{$row->{MYGROUP}} . '_used'} = 0;
            $self->{firebird}->{$map_group{$row->{MYGROUP}} . '_allocated'} = 0;
        }
        $self->{firebird}->{$map_group{$row->{MYGROUP}} . '_used'} += $row->{MYUSED};
        $self->{firebird}->{$map_group{$row->{MYGROUP}} . '_allocated'} += $row->{MYTOTAL};
    }
}

1;

__END__

=head1 MODE

Check memory usage. 

=over 8)

=item B<--warning-*>

Threshold warning.
Can be: 'used' (%), 'attachment' (%), 'transaction' (%), 
'statement' (%), 'call' (%).

=item B<--critical-*>

Threshold critical.
Can be: 'used' (%), 'attachment' (%), 'transaction' (%), 
'statement' (%), 'call' (%).

=back

=cut
