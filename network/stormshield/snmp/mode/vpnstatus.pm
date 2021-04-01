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

package network::stormshield::snmp::mode::vpnstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub custom_threshold_output {
    my ($self, %options) = @_;
    
    return $self->{instance_mode}->get_severity(section => 'vpn', value => $self->{result_values}->{ntqVPNState});
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{ntqVPNState} = $options{new_datas}->{$self->{instance} . '_ntqVPNState'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'vpn', type => 1, cb_prefix_output => 'prefix_vpn_output', message_multiple => 'All vpn are ok' }
    ];
    
    $self->{maps_counters}->{vpn} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'ntqVPNState' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                output_template => 'status: %s', output_error_template => 'Status : %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_threshold_output'),
            }
        },
        { label => 'traffic', nlabel => 'vpn.traffic.bitspersecond', set => {
                key_values => [ { name => 'ntqVPNBytes', per_second => 1 }, { name => 'num' } ],
                output_template => 'traffic: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                     { label => 'traffic', template => '%s',
                       unit => 'b/s', min => 0, label_extra_instance => 1, cast_int => 1, instance_use => 'num' },
                ],
            }
        },
    ];
}

sub prefix_vpn_output {
    my ($self, %options) = @_;
    
    return "VPN '$options{instance_value}->{num}/$options{instance_value}->{ntqVPNIPSrc}/$options{instance_value}->{ntqVPNIPDst}' ";
}

my $thresholds = {
    vpn => [
        ['larval', 'WARNING'],
        ['mature', 'OK'],
        ['dying', 'CRITICAL'],
        ['dead', 'CRITICAL'],
    ],
};

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'filter-id:s'           => { name => 'filter_id' },
        'filter-src-ip:s'       => { name => 'filter_src_ip' },
        'filter-dst-ip:s'       => { name => 'filter_dst_ip' },
        'threshold-overload:s@' => { name => 'threshold_overload' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{overload_th} = {};
    foreach my $val (@{$self->{option_results}->{threshold_overload}}) {
        if ($val !~ /^(.*?),(.*?),(.*)$/) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload option '" . $val . "'.");
            $self->{output}->option_exit();
        }
        my ($section, $status, $filter) = ($1, $2, $3);
        if ($self->{output}->is_litteral_status(status => $status) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload status '" . $val . "'.");
            $self->{output}->option_exit();
        }
        $self->{overload_th}->{$section} = [] if (!defined($self->{overload_th}->{$section}));
        push @{$self->{overload_th}->{$section}}, {filter => $filter, status => $status};
    }
}

sub get_severity {
    my ($self, %options) = @_;
    my $status = 'UNKNOWN'; # default 
    
    if (defined($self->{overload_th}->{$options{section}})) {
        foreach (@{$self->{overload_th}->{$options{section}}}) {            
            if ($options{value} =~ /$_->{filter}/i) {
                $status = $_->{status};
                return $status;
            }
        }
    }
    foreach (@{$thresholds->{$options{section}}}) {           
        if ($options{value} =~ /$$_[0]/i) {
            $status = $$_[1];
            return $status;
        }
    }
    
    return $status;
}

my %map_state = (
    0 => 'larval',
    1 => 'mature',
    2 => 'dying',
    3 => 'dead',
);
my $mapping = {
    ntqVPNIPSrc => { oid => '.1.3.6.1.4.1.11256.1.1.1.1.2' },  
    ntqVPNIPDst => { oid => '.1.3.6.1.4.1.11256.1.1.1.1.3' },
    ntqVPNState => { oid => '.1.3.6.1.4.1.11256.1.1.1.1.11', map => \%map_state },
    ntqVPNBytes => { oid => '.1.3.6.1.4.1.11256.1.1.1.1.13' },
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $mapping->{ntqVPNIPSrc}->{oid} },
            { oid => $mapping->{ntqVPNIPDst}->{oid} },
            { oid => $mapping->{ntqVPNState}->{oid} },
            { oid => $mapping->{ntqVPNBytes}->{oid} },
        ],
        return_type => 1, nothing_quit => 1
    );

    $self->{vpn} = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{ntqVPNState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        if (defined($self->{option_results}->{filter_id}) && $self->{option_results}->{filter_id} ne '' &&
            $instance !~ /$self->{option_results}->{filter_id}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $instance . "': no matching filter id.");
            next;
        }
        if (defined($self->{option_results}->{filter_src_ip}) && $self->{option_results}->{filter_src_ip} ne '' &&
            $result->{ntqVPNIPSrc} !~ /$self->{option_results}->{filter_src_ip}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $result->{ntqVPNIPSrc} . "': no matching filter src-ip.");
            next;
        }
        if (defined($self->{option_results}->{filter_dst_ip}) && $self->{option_results}->{filter_dst_ip} ne '' &&
            $result->{ntqVPNIPDst} !~ /$self->{option_results}->{filter_dst_ip}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $result->{ntqVPNIPDst} . "': no matching filter dst-ip.");
            next;
        }
        
        $self->{vpn}->{$instance} = { num => $instance, %$result };
        $self->{vpn}->{$instance}->{ntqVPNBytes} *= 8 if (defined($self->{vpn}->{$instance}->{ntqVPNBytes}));
    }
    
    if (scalar(keys %{$self->{vpn}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No vpn found.");
        $self->{output}->option_exit();
    }

    $self->{cache_name} = "stormshield_" . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_id}) ? md5_hex($self->{option_results}->{filter_id}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_src_ip}) ? md5_hex($self->{option_results}->{filter_src_ip}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_dst_ip}) ? md5_hex($self->{option_results}->{filter_dst_ip}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check VPN states.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'traffic'.

=item B<--critical-*>

Threshold critical.
Can be: 'traffic'.

=item B<--filter-id>

Filter by id (regexp can be used).

=item B<--filter-src-ip>

Filter by src ip (regexp can be used).

=item B<--filter-dst-ip>

Filter by dst ip (regexp can be used).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='vpn,CRITICAL,^(?!(mature)$)'

=back

=cut
