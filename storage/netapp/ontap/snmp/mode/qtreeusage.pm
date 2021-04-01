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

package storage::netapp::ontap::snmp::mode::qtreeusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'qtree', type => 1, cb_prefix_output => 'prefix_qtree_output', message_multiple => 'All qtree usages are ok.' },
    ];
    
    $self->{maps_counters}->{qtree} = [
        { label => 'usage', set => {
                key_values => [ { name => 'name' }, { name => 'used' }, { name => 'total' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
            }
        },
    ];
}

sub custom_usage_perfdata {
    my ($self, %options) = @_;
    
    my $label = 'used';
    my $value_perf = $self->{result_values}->{used};
    if ($self->{result_values}->{total} > 0 && defined($self->{instance_mode}->{option_results}->{free})) {
        $label = 'free';
        $value_perf = $self->{result_values}->{free};
    }

    my %total_options = ();
    if ($self->{result_values}->{total} > 0 && $self->{instance_mode}->{option_results}->{units} eq '%') {
        $total_options{total} = $self->{result_values}->{total};
        $total_options{cast_int} = 1;
    }

    $self->{output}->perfdata_add(
        label => $label, unit => 'B',
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{name} : undef,
        value => $value_perf,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, %total_options),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, %total_options),
        min => 0, max => $self->{result_values}->{total}
    );
}

sub custom_usage_threshold {
    my ($self, %options) = @_;
    
    # cannot use '%' or free option with unlimited system 
    return 'ok' if ($self->{result_values}->{total} <= 0 && ($self->{instance_mode}->{option_results}->{units} eq '%' || $self->{instance_mode}->{option_results}->{free}));
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

    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});    
    my $msg;
    if ($self->{result_values}->{total} <= 0) {
        $msg = sprintf("Used: %s (unlimited)", $total_used_value . " " . $total_used_unit);
    } else {
        my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
        my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
        $msg = sprintf("Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
                   $total_size_value . " " . $total_size_unit,
                   $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
                   $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free});
    }
    return $msg;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{name} = $options{new_datas}->{$self->{instance} . '_name'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_total'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_used'};
    
    return 0 if ($self->{result_values}->{total} == 0);
    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};
    $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used};
    # qtree can be over 100%
    if ($self->{result_values}->{free} < 0) {
        $self->{result_values}->{free} = 0;
        $self->{result_values}->{prct_free} = 0;
    }
    
    return 0;
}

sub prefix_qtree_output {
    my ($self, %options) = @_;
    
    return "Qtree '" . $options{instance_value}->{name} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'units:s'          => { name => 'units', default => '%' },
        'free'             => { name => 'free' },
        'filter-vserver:s' => { name => 'filter_vserver' },
        'filter-volume:s'  => { name => 'filter_volume' },
        'filter-qtree:s'   => { name => 'filter_qtree' },
        'not-kbytes'       => { name => 'not_kbytes' },
    });

    return $self;
}

my $mapping = {
    qrV2Tree            => { oid => '.1.3.6.1.4.1.789.1.4.6.1.14' },
    qrV264KBytesUsed    => { oid => '.1.3.6.1.4.1.789.1.4.6.1.25' },
    qrV264KBytesLimit   => { oid => '.1.3.6.1.4.1.789.1.4.6.1.26' },
    qrV2VolumeName      => { oid => '.1.3.6.1.4.1.789.1.4.6.1.29' },
    qrV2Vserver         => { oid => '.1.3.6.1.4.1.789.1.4.6.1.30' },
};

sub manage_selection {
    my ($self, %options) = @_;
    
    my $multi = 1;
    $multi = 1024 unless defined($self->{option_results}->{not_kbytes});

    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Need to use SNMP v2c or v3.");
        $self->{output}->option_exit();
    }
    my $results = $options{snmp}->get_multiple_table(oids => [
                                                       { oid => $mapping->{qrV2Tree}->{oid} },
                                                       { oid => $mapping->{qrV264KBytesUsed}->{oid} },
                                                       { oid => $mapping->{qrV264KBytesLimit}->{oid} },
                                                       { oid => $mapping->{qrV2VolumeName}->{oid} },
                                                       { oid => $mapping->{qrV2Vserver}->{oid} },
                                                    ], return_type => 1, nothing_quit => 1);
    $self->{qtree} = {};
    foreach my $oid (keys %{$results}) {
        next if ($oid !~ /^$mapping->{qrV2Tree}->{oid}\.(.*)/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $results, instance => $instance);

        if (defined($self->{option_results}->{filter_vserver}) && $self->{option_results}->{filter_vserver} ne '' &&
            defined($result->{qrV2Vserver}) && $result->{qrV2Vserver} ne '' && $result->{qrV2Vserver} !~ /$self->{option_results}->{filter_vserver}/) {
            $self->{output}->output_add(long_msg => "Skipping '" . $result->{qrV2Vserver} . "': no matching vserver name.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_volume}) && $self->{option_results}->{filter_volume} ne '' &&
            defined($result->{qrV2VolumeName}) && $result->{qrV2VolumeName} ne '' && $result->{qrV2VolumeName} !~ /$self->{option_results}->{filter_volume}/) {
            $self->{output}->output_add(long_msg => "Skipping '" . $result->{qrV2VolumeName} . "': no matching volume name.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_qtree}) && $self->{option_results}->{filter_qtree} ne '' &&
            $result->{qrV2Tree} !~ /$self->{option_results}->{filter_qtree}/) {
            $self->{output}->output_add(long_msg => "Skipping '" . $result->{qrV2Tree} . "': no matching qtree name.", debug => 1);
            next;
        }        
        if (!defined($result->{qrV264KBytesUsed}) && !defined($result->{qrV264KBytesLimit})) {
            $self->{output}->output_add(long_msg => "Skipping qtree '" . $result->{qrV2Tree} . "': no used or total values.", debug => 1);
            next;
        }

        my $name = '';
        $name = $result->{qrV2Vserver} . '/' if (defined($result->{qrV2Vserver}) && $result->{qrV2Vserver} ne ''); 
        $name .= $result->{qrV2VolumeName} . '/' if (defined($result->{qrV2VolumeName}) && $result->{qrV2VolumeName} ne ''); 
        $name .= $result->{qrV2Tree};
        
        $self->{qtree}->{$instance} = { name => $name, used => $result->{qrV264KBytesUsed} * $multi, total => $result->{qrV264KBytesLimit} * $multi }; 
    }
    
    if (scalar(keys %{$self->{qtree}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check qtree quote usage.

=over 8

=item B<--warning-usage>

Threshold warning.

=item B<--critical-usage>

Threshold critical.

=item B<--units>

Units of thresholds (Default: '%') ('%', 'B').

=item B<--free>

Thresholds are on free space left.

=item B<--filter-vserver>

Filter by vserver name (can be a regexp).

=item B<--filter-volume>

Filter by volume name (can be a regexp).

=item B<--filter-qtree>

Filter by qtree name (can be a regexp).

=item B<--not-kbytes>

If qrV264KBytesUsed and qrV264KBytesLimit OIDs are not really KBytes.

=back

=cut
