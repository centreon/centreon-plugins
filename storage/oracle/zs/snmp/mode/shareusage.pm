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

package storage::oracle::zs::snmp::mode::shareusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

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
    my $msg = sprintf("Usage Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
                   $total_size_value . " " . $total_size_unit,
                   $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
                   $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free});
    return $msg;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{label} = $options{extra_options}->{label_ref};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_total'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_used'};
    $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used};
    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'project', type => 1, cb_prefix_output => 'prefix_project_output', message_multiple => 'All projects are ok' },
        { name => 'share', type => 1, cb_prefix_output => 'prefix_share_output', message_multiple => 'All shares are ok' }
    ];
    
    $self->{maps_counters}->{share} = [
        { label => 'share-usage', set => {
                key_values => [ { name => 'display' }, { name => 'used' }, { name => 'total' } ],
                closure_custom_calc => $self->can('custom_usage_calc'), closure_custom_calc_extra_options => { label_ref => 'share' },
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
            }
        },
    ];
    $self->{maps_counters}->{project} = [
        { label => 'project-usage', set => {
                key_values => [ { name => 'display' }, { name => 'used' }, { name => 'total' } ],
                closure_custom_calc => $self->can('custom_usage_calc'), closure_custom_calc_extra_options => { label_ref => 'project' },
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
        "filter-name:s"       => { name => 'filter_name' },
        "filter-project:s"    => { name => 'filter_project' },
        "units:s"             => { name => 'units', default => '%' },
        "free"                => { name => 'free' },
    });

    return $self;
}

sub prefix_share_output {
    my ($self, %options) = @_;
    
    return "Share '" . $options{instance_value}->{display} . "' ";
}

sub prefix_project_output {
    my ($self, %options) = @_;
    
    return "Project '" . $options{instance_value}->{display} . "' ";
}

my $mapping = {
    sunAkShareName      => { oid => '.1.3.6.1.4.1.42.2.225.1.6.1.2' },
    sunAkShareProject   => { oid => '.1.3.6.1.4.1.42.2.225.1.6.1.4' },
    sunAkShareSizeB     => { oid => '.1.3.6.1.4.1.42.2.225.1.6.1.10' },
    sunAkShareUsedB     => { oid => '.1.3.6.1.4.1.42.2.225.1.6.1.11' },
};

my $oid_sunAkShareEntry = '.1.3.6.1.4.1.42.2.225.1.6.1';

sub manage_selection {
    my ($self, %options) = @_;

    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Need to use SNMP v2c or v3.");
        $self->{output}->option_exit();
    }

    $self->{share} = {};
    $self->{project} = {};
    my $snmp_result = $options{snmp}->get_table(oid => $oid_sunAkShareEntry,
                                                nothing_quit => 1);


    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{sunAkShareName}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{sunAkShareName} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{sunAkShareName} . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_project}) && $self->{option_results}->{filter_project} ne '' &&
            $result->{sunAkShareProject} !~ /$self->{option_results}->{filter_project}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{sunAkShareName} . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{project}->{$result->{sunAkShareProject}} = { total => 0, used => 0, display => $result->{sunAkShareProject} }
            if (!defined($self->{project}->{$result->{sunAkShareProject}}));
        $self->{share}->{$instance} = { 
            display => $result->{sunAkShareName},
            total => $result->{sunAkShareSizeB},
            used => $result->{sunAkShareUsedB},
        };
        $self->{project}->{$result->{sunAkShareProject}}->{total} += $result->{sunAkShareSizeB};
        $self->{project}->{$result->{sunAkShareProject}}->{used} += $result->{sunAkShareUsedB};
    }
    
    if (scalar(keys %{$self->{share}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No share found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check shares.

=over 8

=item B<--filter-name>

Filter share name (can be a regexp).

=item B<--filter-project>

Filter project name (can be a regexp).

=item B<--warning-*>

Threshold warning.
Can be: 'share-usage', 'project-usage'.

=item B<--critical-*>

Threshold critical.
Can be: 'share-usage', 'project-usage'.

=item B<--units>

Units of thresholds (Default: '%') ('%', 'B').

=item B<--free>

Thresholds are on free space left.

=back

=cut
