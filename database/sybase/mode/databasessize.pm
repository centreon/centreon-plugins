#
# Copyright 2021 Centreon (http://www.centreon.com/)
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

package database::sybase::mode::databasessize;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'database', type => 1, cb_prefix_output => 'prefix_database_output', message_multiple => 'All databases are OK', message_separator => ' - ' },
    ];

    $self->{maps_counters}->{database} = [
        { label => 'data', set => {
                key_values => [ { name => 'data_used' }, { name => 'data_size' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_usage_calc'), closure_custom_calc_extra_options => { label_ref => 'data' },
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
            }
        },
        { label => 'log', set => {
                key_values => [ { name => 'log_used' }, { name => 'log_size' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_usage_calc'), closure_custom_calc_extra_options => { label_ref => 'log' },
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
            }
        },
    ];
}

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    my $label = $self->{result_values}->{label} . '_used';
    my $value_perf = $self->{result_values}->{used};
    if (defined($self->{instance_mode}->{option_results}->{free})) {
        $label = $self->{result_values}->{label} . '_free';
        $value_perf = $self->{result_values}->{free};
    }

    my %total_options = ();
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $total_options{total} = $self->{result_values}->{total};
        $total_options{cast_int} = 1;
    }

    $self->{output}->perfdata_add(
        label => $label, unit => 'B',
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
        value => $value_perf,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, %total_options),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, %total_options),
        min => 0, max => $self->{result_values}->{total}
    );
}

sub custom_usage_threshold {
    my ($self, %options) = @_;

    my ($exit, $threshold_value);
    $threshold_value = $self->{result_values}->{used};
    $threshold_value = $self->{result_values}->{free} if (defined($self->{instance_mode}->{option_results}->{free}));
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $threshold_value = $self->{result_values}->{prct_used};
        $threshold_value = $self->{result_values}->{prct_free} if (defined($self->{instance_mode}->{option_results}->{free}));
    }
    $exit = $self->{perfdata}->threshold_check(value => $threshold_value, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    my $msg = sprintf("Total %s: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
                   ucfirst($self->{result_values}->{label}),
                   $total_size_value . " " . $total_size_unit,
                   $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
                   $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free});
    return $msg;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    my $label = $options{extra_options}->{label_ref};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_' . $label . '_size'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_' . $label . '_used'};
    $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used};
    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};
    $self->{result_values}->{label} = $label;

    return 0;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "filter-database:s"   => { name => 'filter_database' },
        "units:s"             => { name => 'units', default => '%' },
        "free"                => { name => 'free' },
    });

    return $self;
}

sub prefix_database_output {
    my ($self, %options) = @_;

    return "Database '" . $options{instance_value}->{display} . "' ";
}

sub manage_selection {
    my ($self, %options) = @_;

    $options{sql}->connect();
    $options{sql}->query(query => q{
        select db_name(d.dbid) as db_name,
ceiling(sum(case when u.segmap != 4 then u.size/1.*@@maxpagesize end )) as data_size,
ceiling(sum(case when u.segmap != 4 then size - curunreservedpgs(u.dbid, u.lstart, u.unreservedpgs) end)/1.*@@maxpagesize) as data_used,
ceiling(sum(case when u.segmap in (4, 7) then u.size/1.*@@maxpagesize end)) as log_size,
ceiling(sum(case when u.segmap in (4, 7) then u.size/1.*@@maxpagesize end) - lct_admin("logsegment_freepages",d.dbid)/1.*@@maxpagesize) as log_used
from master..sysdatabases d, master..sysusages u
where u.dbid = d.dbid  and d.status not in (256,4096)
group by d.dbid
order by db_name(d.dbid)
    });
    
    my $result = $options{sql}->fetchall_arrayref();
    
    foreach my $row (@$result) {
        if (defined($self->{option_results}->{filter_database}) && $self->{option_results}->{filter_database} ne '' &&
            $$row[0] !~ /$self->{option_results}->{filter_database}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $$row[0] . "': no matching filter.", debug => 1);
            next;
        }

        $self->{database}->{$$row[0]} = {  data_size => $$row[1], data_used => $$row[2],
                                           log_size => $$row[3], log_used => $$row[4],
                                           display => lc($$row[0]) };
    }
}

1;

__END__

=head1 MODE

Check MSSQL Database usage

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'data', 'log'.

=item B<--critical-*>

Threshold warning.
Can be: 'data', 'log'.

=item B<--filter-database>

Filter database by name. Can be a regex

=item B<--units>

Units of thresholds (Default: '%') ('%', 'B').

=item B<--free>

Thresholds are on free space left.

=back

=cut
