#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_output' }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'used', nlabel => 'database.usage.bytes',  set => {
                key_values => [ { name => 'database_used' }, { name => 'database_allocated' } ],
                closure_custom_calc => $self->can('custom_unit_calc'), closure_custom_calc_extra_options => { label_ref => 'database' },
                closure_custom_output => $self->can('custom_used_output'),
                threshold_use => 'prct',
                closure_custom_perfdata => $self->can('custom_used_perfdata')
            }
        },
        { label => 'attachment', nlabel => 'attachment.usage.bytes', set => {
                key_values => [ { name => 'attachment_used' }, { name => 'attachment_allocated' } ],
                closure_custom_calc => $self->can('custom_unit_calc'), closure_custom_calc_extra_options => { label_ref => 'attachment' },
                closure_custom_output => $self->can('custom_unit_output'),
                threshold_use => 'prct',
                closure_custom_perfdata => $self->can('custom_unit_perfdata')
            }
        },
        { label => 'transaction', nlabel => 'transaction.usage.bytes', set => {
                key_values => [ { name => 'transaction_used' }, { name => 'transaction_allocated' } ],
                closure_custom_calc => $self->can('custom_unit_calc'), closure_custom_calc_extra_options => { label_ref => 'transaction' },
                closure_custom_output => $self->can('custom_unit_output'),
                threshold_use => 'prct',
                closure_custom_perfdata => $self->can('custom_unit_perfdata')
            }
        },
        { label => 'statement', nlabel => 'statement.usage.bytes', set => {
                key_values => [ { name => 'statement_used' }, { name => 'statement_allocated' } ],
                closure_custom_calc => $self->can('custom_unit_calc'), closure_custom_calc_extra_options => { label_ref => 'statement' },
                closure_custom_output => $self->can('custom_unit_output'),
                threshold_use => 'prct',
                closure_custom_perfdata => $self->can('custom_unit_perfdata')
            }
        },
        { label => 'call', nlabel => 'call.usage.bytes', set => {
                key_values => [ { name => 'call_used' }, { name => 'call_allocated' } ],
                closure_custom_calc => $self->can('custom_unit_calc'), closure_custom_calc_extra_options => { label_ref => 'call' },
                closure_custom_output => $self->can('custom_unit_output'),
                threshold_use => 'prct',
                closure_custom_perfdata => $self->can('custom_unit_perfdata')
            }
        },
    ];
}

sub custom_used_output {
    my ($self, %options) = @_;
    
    my $free = $self->{result_values}->{total} - $self->{result_values}->{used};
    my ($total_value, $total_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($used_value, $used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($free_value, $free_unit) = $self->{perfdata}->change_bytes(value => $free);
    return sprintf(
        "Total: %s Used : %s (%.2f %%) Free : %s (%.2f %%)",
        $total_value . ' ' . $total_unit,
        $used_value . ' ' . $used_unit, $self->{result_values}->{prct},
        $free_value . ' ' . $free_unit, 100 - $self->{result_values}->{prct}
    );
}

sub custom_used_perfdata {
    my ($self, %options) = @_;
    
    $self->{output}->perfdata_add(
        label => 'used', unit => 'B',
        nlabel => $self->{nlabel},                                
        value => $self->{result_values}->{used},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, total => $self->{result_values}->{total}, cast_int => 1),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, total => $self->{result_values}->{total}, cast_int => 1),
        min => 0, max => $self->{result_values}->{total}
    );
}

sub custom_unit_perfdata {
    my ($self, %options) = @_;
    
    $self->{output}->perfdata_add(
        label => $self->{result_values}->{label}, unit => 'B',
        nlabel => $self->{nlabel},
        value => $self->{result_values}->{used},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, total => $self->{result_values}->{total}, cast_int => 1),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, total => $self->{result_values}->{total}, cast_int => 1),
        min => 0, max => $self->{result_values}->{total}
    );
}

sub custom_unit_output {
    my ($self, %options) = @_;
    
    my ($used_value, $used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    return sprintf(
        "%s : %s (%.2f %%)",
        ucfirst($self->{result_values}->{label}),
        $used_value . ' ' . $used_unit, $self->{result_values}->{prct}
    );
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

sub prefix_output {
    my ($self, %options) = @_;

    return "Memory ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {});
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $options{sql}->connect();
    $options{sql}->query(query => q{SELECT MON$STAT_GROUP as MYGROUP, MON$MEMORY_ALLOCATED AS MYTOTAL, MON$MEMORY_USED AS MYUSED FROM MON$MEMORY_USAGE});
    
    my %map_group = (0 => 'database', 1 => 'attachment', 2 => 'transaction', 3 => 'statement', 4 => 'call'); 

    $self->{global} = {};
    while ((my $row = $options{sql}->fetchrow_hashref())) {
        if (!defined($self->{firebird}->{$map_group{$row->{MYGROUP}} . '_used'})) {
            $self->{global}->{$map_group{ $row->{MYGROUP} } . '_used'} = 0;
            $self->{global}->{$map_group{ $row->{MYGROUP} } . '_allocated'} = 0;
        }
        $self->{global}->{$map_group{ $row->{MYGROUP} } . '_used'} += $row->{MYUSED};
        $self->{global}->{$map_group{ $row->{MYGROUP} } . '_allocated'} += $row->{MYTOTAL};
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
