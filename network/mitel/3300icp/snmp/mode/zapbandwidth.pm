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

package network::mitel::3300icp::snmp::mode::zapbandwidth;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub custom_usage_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_mitelBWMCurrentBandwidthInUse'} * 1000;
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_mitelBWMCurrentBandwidthLimit'} * 1000;
    $self->{result_values}->{used_prct} = $self->{result_values}->{used} / $self->{result_values}->{total} * 100;
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    my $extra_label = '';
    $extra_label = '_' . $self->{result_values}->{display} if (!defined($options{extra_instance}) || $options{extra_instance} != 0);
    
    $self->{output}->perfdata_add(
        label => 'usage' . $extra_label, unit => 'b/s',
        value => $self->{result_values}->{used},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}, total => $self->{result_values}->{total}, cast_int => 1),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}, total => $self->{result_values}->{total}, cast_int => 1),
        min => 0, max => $self->{result_values}->{total}
    );
}

sub custom_usage_output {
    my ($self, %options) = @_;
    
    my ($used_value, $used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used}, network => 1);
    return sprintf("Bandwidth usage: %s/s (%.2f %%)", $used_value . ' ' . $used_unit, $self->{result_values}->{used_prct});
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'zap', type => 1, cb_prefix_output => 'prefix_zap_output',
          message_multiple => 'All zone access points are ok' },
    ];
    
    $self->{maps_counters}->{zap} = [
        { label => 'usage', set => {
                key_values => [ { name => 'mitelBWMCurrentBandwidthInUse' },
                                { name => 'mitelBWMCurrentBandwidthLimit' },
                                { name => 'display' } ],
                closure_custom_calc => $self->can('custom_usage_calc'), 
                closure_custom_output => $self->can('custom_usage_output'),
                threshold_use => 'used_prct',
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
            }
        },
    ];
}

sub prefix_zap_output {
    my ($self, %options) = @_;

    return "Zone access point '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "filter-name:s" => { name => 'filter_name' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

my $oid_mitelBWMCurrentZAPLabel = '.1.3.6.1.4.1.1027.4.1.1.2.5.1.1.1.1.4',
my $mapping = {
    mitelBWMCurrentBandwidthInUse => { oid => '.1.3.6.1.4.1.1027.4.1.1.2.5.1.1.1.1.5' },
    mitelBWMCurrentBandwidthLimit => { oid => '.1.3.6.1.4.1.1027.4.1.1.2.5.1.1.1.1.6' },
};

sub manage_selection {
    my ($self, %options) = @_;

    $self->{zap} = {};
    my $snmp_result = $options{snmp}->get_table(oid => $oid_mitelBWMCurrentZAPLabel, nothing_quit => 1);
    foreach my $oid (keys %{$snmp_result}) {
        $oid =~ /^$oid_mitelBWMCurrentZAPLabel\.(.*)$/;
        my $instance = $1;
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $snmp_result->{$oid} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $snmp_result->{$oid} . "'.", debug => 1);
            next;
        }
        
        $self->{zap}->{$instance} = { display => $snmp_result->{$oid} };
    }
    
    $options{snmp}->load(oids => [ $mapping->{mitelBWMCurrentBandwidthInUse}->{oid},
                                   $mapping->{mitelBWMCurrentBandwidthLimit}->{oid} ],
                         instances => [ keys %{$self->{zap}} ],
                         instance_regexp => '^(.*)$');
    $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);
    
    foreach (keys %{$self->{zap}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $_);
        foreach my $name (keys %{$mapping}) {
            $self->{zap}->{$_}->{$name} = $result->{$name};
        }
    }

    if (scalar(keys %{$self->{zap}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No zone access points found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check zone access points bandwidth usage.

=over 8

=item B<--filter-name>

Filter by zone access points name (can be a regexp).

=item B<--warning-usage>

Threshold warning in percentage of bandwidth limit.

=item B<--critical-usage>

Threshold critical in percentage of bandwidth limit.

=back

=cut
    
