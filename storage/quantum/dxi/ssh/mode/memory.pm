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

package storage::quantum::dxi::ssh::mode::memory;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        label => 'used',
        unit => 'B',
        value => $self->{result_values}->{used},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}, total => $self->{result_values}->{total}, cast_int => 1),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}, total => $self->{result_values}->{total}, cast_int => 1),
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
    $exit = $self->{perfdata}->threshold_check(
        value => $threshold_value,
        threshold => [
            { label => 'critical-' . $self->{label}, exit_litteral => 'critical' },
            { label => 'warning-' . $self->{label}, exit_litteral => 'warning' }
        ]
    );
    return $exit;
}

sub custom_usage_output {
    my ($self, %options) = @_;

    my ($used_value, $used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($free_value, $free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    my ($total_value, $total_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    
    return sprintf(
        "Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)", 
        $total_value . " " . $total_unit, 
        $used_value . " " . $used_unit, $self->{result_values}->{prct_used}, 
        $free_value . " " . $free_unit, $self->{result_values}->{prct_free}
    );
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{total} = $self->{instance_mode}->convert_to_bytes(raw_value => $options{new_datas}->{$self->{instance} . '_total'});
    $self->{result_values}->{free} = $self->{instance_mode}->convert_to_bytes(raw_value => $options{new_datas}->{$self->{instance} . '_free'});

    if ($self->{result_values}->{total} != 0) {
        $self->{result_values}->{used} = $self->{result_values}->{total} - $self->{result_values}->{free};
        $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
        $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};
    } else {
        $self->{result_values}->{free} = '0';
        $self->{result_values}->{prct_used} = '0';
        $self->{result_values}->{prct_free} = '0';
    }

    return 0;
}

sub convert_to_bytes {
    my ($class, %options) = @_;
    
    my ($value, $unit) = split(/\s+/, $options{raw_value});
    if ($unit =~ /kb*/i) {
        $value = $value * 1024;
    } elsif ($unit =~ /mb*/i) {
        $value = $value * 1024 * 1024;
    } elsif ($unit =~ /gb*/i) {
        $value = $value * 1024 * 1024 * 1024;
    } elsif ($unit =~ /tb*/i) {
        $value = $value * 1024 * 1024 * 1024 * 1024;
    }

    return $value;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'usage', set => {
                key_values => [ { name => 'total' }, { name => 'free' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'units:s' => { name => 'units', default => '%' },
        'free'    => { name => 'free' },
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $stdout = $options{custom}->execute_command(command => 'syscli --getstatus systemmemory');
    # Output data:
    #     Total Memory = 270.76 GB
    #     Free Memory = 91.19 GB

    $self->{global} = {};
    foreach (split(/\n/, $stdout)) {
        $self->{global}->{total} = $1 if (/.*Total\sMemory\s=\s(.*)$/i);
        $self->{global}->{free} = $1 if (/.*Free\sMemory\s=\s(.*)$/i);
    }
}

1;

__END__

=head1 MODE

Check memory usage.

=over 8

=item B<--warning-usage>

Threshold warning.

=item B<--critical-usage>

Threshold critical.

=back

=cut
