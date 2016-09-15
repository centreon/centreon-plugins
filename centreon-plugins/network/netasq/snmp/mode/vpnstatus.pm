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

package network::netasq::snmp::mode::vpnstatus;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::values;
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);

my $thresholds = {
    vpn => [
        ['larval', 'WARNING'],
        ['mature', 'OK'],
        ['dying', 'CRITICAL'],
        ['dead', 'CRITICAL'],
    ],
};
my $instance_mode;

my $maps_counters = {
    vpn => { 
        '000_status'   => { set => {
                        key_values => [ { name => 'ntqVPNState' } ],
                        closure_custom_calc => \&custom_status_calc,
                        output_template => 'Status : %s', output_error_template => 'Status : %s',
                        output_use => 'ntqVPNState',
                        closure_custom_perfdata => sub { return 0; },
                        closure_custom_threshold_check => \&custom_threshold_output,
                    }
               },
        '001_traffic'   => { set => {
                        key_values => [ { name => 'ntqVPNBytes', diff => 1 }, { name => 'num' } ],
                        per_second => 1,  output_change_bytes => 2,
                        output_template => 'Traffic: %s %s/s',
                        perfdatas => [
                             { label => 'traffic', value => 'ntqVPNBytes_per_second', template => '%s',
                              unit => 'b/s', min => 0, label_extra_instance => 1, cast_int => 1, instance_use => 'num_absolute' },
                        ],
                    }
               },
        },
};


sub custom_threshold_output {
    my ($self, %options) = @_;
    
    return $instance_mode->get_severity(section => 'vpn', value => $self->{result_values}->{ntqVPNState});
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{ntqVPNState} = $options{new_datas}->{$self->{instance} . '_ntqVPNState'};
    return 0;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "filter-id:s"  => { name => 'filter_id' },
                                  "filter-src-ip:s"  => { name => 'filter_src_ip' },
                                  "filter-dst-ip:s"  => { name => 'filter_dst_ip' },
                                  "threshold-overload:s@"   => { name => 'threshold_overload' },
                                });

    $self->{statefile_value} = centreon::plugins::statefile->new(%options);
 
    foreach my $key (('vpn')) {
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
    
    foreach my $key (('vpn')) {
        foreach (keys %{$maps_counters->{$key}}) {
            $maps_counters->{$key}->{$_}->{obj}->init(option_results => $self->{option_results});
        }
    }
    
    $instance_mode = $self;
    $self->{statefile_value}->check_options(%options);
    
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

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};
    $self->{hostname} = $self->{snmp}->get_hostname();
    $self->{snmp_port} = $self->{snmp}->get_port();
    
    $self->manage_selection();
    
    my $multiple = 1;
    if (scalar(keys %{$self->{vpn}}) == 1) {
        $multiple = 0;
    }
    
    if ($multiple == 1) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All VPN are ok');
    }
    
    my $matching = '';
    foreach (('filter_id', 'filter_src_ip', 'filter_dst_ip')) {
        $matching .= defined($self->{option_results}->{$_}) ? $self->{option_results}->{$_} : 'all';
    }
    $self->{new_datas} = {};
    $self->{statefile_value}->read(statefile => "netasq_" . $self->{hostname}  . '_' . $self->{snmp_port} . '_' . $self->{mode} . '_' . md5_hex($matching));
    $self->{new_datas}->{last_timestamp} = time();
    
    foreach my $id (sort keys %{$self->{vpn}}) {     
        my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
        my @exits = ();
        foreach (sort keys %{$maps_counters->{vpn}}) {
            my $obj = $maps_counters->{vpn}->{$_}->{obj};
            $obj->set(instance => $id);
        
            my ($value_check) = $obj->execute(values => $self->{vpn}->{$id},
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
            
            $maps_counters->{vpn}->{$_}->{obj}->perfdata(extra_instance => $multiple);
        }

        $self->{output}->output_add(long_msg => "VPN '$self->{vpn}->{$id}->{num}/$self->{vpn}->{$id}->{ntqVPNIPSrc}/$self->{vpn}->{$id}->{ntqVPNIPDst}' $long_msg");
        my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
        if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => "VPN '$self->{vpn}->{$id}->{num}/$self->{vpn}->{$id}->{ntqVPNIPSrc}/$self->{vpn}->{$id}->{ntqVPNIPDst}' $short_msg"
                                        );
        }
        
        if ($multiple == 0) {
            $self->{output}->output_add(short_msg => "VPN '$self->{vpn}->{$id}->{num}/$self->{vpn}->{$id}->{ntqVPNIPSrc}/$self->{vpn}->{$id}->{ntqVPNIPDst}' $long_msg");
        }
    }
    
    $self->{statefile_value}->write(data => $self->{new_datas});
    $self->{output}->display();
    $self->{output}->exit();
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
};
my $mapping2 = {
    ntqVPNIPDst => { oid => '.1.3.6.1.4.1.11256.1.1.1.1.3' },
};
my $mapping3 = {
    ntqVPNState => { oid => '.1.3.6.1.4.1.11256.1.1.1.1.11', map => \%map_state },
};
my $mapping4 = {
    ntqVPNBytes => { oid => '.1.3.6.1.4.1.11256.1.1.1.1.13' },
};

sub manage_selection {
    my ($self, %options) = @_;

    $self->{results} = $self->{snmp}->get_multiple_table(oids => [
                                                            { oid => $mapping->{ntqVPNIPSrc}->{oid} },
                                                            { oid => $mapping2->{ntqVPNIPDst}->{oid} },
                                                            { oid => $mapping3->{ntqVPNState}->{oid} },
                                                            { oid => $mapping4->{ntqVPNBytes}->{oid} },
                                                         ],
                                                         , nothing_quit => 1);
    
    $self->{vpn} = {};
    foreach my $oid (keys %{$self->{results}->{$mapping3->{ntqVPNState}->{oid}}}) {
        next if ($oid !~ /^$mapping3->{ntqVPNState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$mapping->{ntqVPNIPSrc}->{oid}}, instance => $instance);
        my $result2 = $self->{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{$mapping2->{ntqVPNIPDst}->{oid}}, instance => $instance);
        my $result3 = $self->{snmp}->map_instance(mapping => $mapping3, results => $self->{results}->{$mapping3->{ntqVPNState}->{oid}}, instance => $instance);
        my $result4 = $self->{snmp}->map_instance(mapping => $mapping4, results => $self->{results}->{$mapping4->{ntqVPNBytes}->{oid}}, instance => $instance);
        
        if (defined($self->{option_results}->{filter_id}) && $self->{option_results}->{filter_id} ne '' &&
            $instance !~ /$self->{option_results}->{filter_id}/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $instance . "': no matching filter id.");
            next;
        }
        if (defined($self->{option_results}->{filter_src_ip}) && $self->{option_results}->{filter_src_ip} ne '' &&
            $result->{ntqVPNIPSrc} !~ /$self->{option_results}->{filter_src_ip}/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $result->{ntqVPNIPSrc} . "': no matching filter src-ip.");
            next;
        }
        if (defined($self->{option_results}->{filter_dst_ip}) && $self->{option_results}->{filter_dst_ip} ne '' &&
            $result2->{ntqVPNIPDst} !~ /$self->{option_results}->{filter_dst_ip}/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $result2->{ntqVPNIPDst} . "': no matching filter dst-ip.");
            next;
        }
        
        $self->{vpn}->{$instance} = { num => $instance, %$result, %$result2, %$result3, %$result4};
        $self->{vpn}->{$instance}->{ntqVPNBytes} *= 8 if (defined($self->{vpn}->{$instance}->{ntqVPNBytes}));
    }
    
    if (scalar(keys %{$self->{vpn}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found.");
        $self->{output}->option_exit();
    }
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
