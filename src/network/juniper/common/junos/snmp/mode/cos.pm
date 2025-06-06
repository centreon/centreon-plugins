#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package network::juniper::common::junos::snmp::mode::cos;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub interface_long_output {
    my ($self, %options) = @_;

    return "checking interface '" . $options{instance_value}->{name} . "'";
}

sub prefix_interface_output {
    my ($self, %options) = @_;

    return "interface '" . $options{instance_value}->{name} . "' ";
}

sub prefix_cos_output {
    my ($self, %options) = @_;

    return "class of service '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'interfaces', type => 3, cb_prefix_output => 'prefix_interface_output', cb_long_output => 'interface_long_output', indent_long_output => '    ', message_multiple => 'All interfaces are ok',
            group => [
                { name => 'cos', display_long => 1, cb_prefix_output => 'prefix_cos_output',  message_multiple => 'All class of services are ok', type => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{cos} = [
        { label => 'queued', nlabel => 'interface.cos.queued.bitspersecond', set => {
                key_values => [ { name => 'queued_bytes', per_second => 1 }, { name => 'name' } ],
                output_template => 'queued: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%s',
                      unit => 'b/s', min => 0, cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'traffic-out', nlabel => 'interface.cos.traffic.out.bitspersecond', set => {
                key_values => [ { name => 'traffic_out_bytes', per_second => 1 }, { name => 'name' } ],
                output_template => 'traffic out: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%s',
                      unit => 'b/s', min => 0, cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'dropped', nlabel => 'interface.cos.dropped.bitspersecond', set => {
                key_values => [ { name => 'drop_bytes', per_second => 1 }, { name => 'name' } ],
                output_template => 'dropped: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%s',
                      unit => 'b/s', min => 0, cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-interface-name:s' => { name => 'filter_interface_name' },
        'filter-class-name:s'     => { name => 'filter_class_name' }
    });

    return $self;
}

my $mapping = {
    traffic_out_bytes => { oid => '.1.3.6.1.4.1.2636.3.15.4.1.9' }, # jnxCosQstatTxedBytes
    drop_bytes        => { oid => '.1.3.6.1.4.1.2636.3.15.4.1.55' } # jnxCosQstatTotalDropBytes
};
my $oid_jnxCosFcQueueNr = '.1.3.6.1.4.1.2636.3.15.2.1.2';
my $oid_jnxCosQstatQedBytes = '.1.3.6.1.4.1.2636.3.15.4.1.5';
my $oid_ifName = '.1.3.6.1.2.1.31.1.1.1.1';

sub manage_selection {
    my ($self, %options) = @_;

    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => 'Need to use SNMP v2c or v3.');
        $self->{output}->option_exit();
    }

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_jnxCosFcQueueNr },
            { oid => $oid_jnxCosQstatQedBytes }
        ],
        nothing_quit => 1
    );

    my $queues = {};
    foreach my $oid (keys %{$snmp_result->{$oid_jnxCosFcQueueNr}}) {
        $oid =~ /^$oid_jnxCosFcQueueNr\.\d+\.(.*)$/;
        $queues->{ $snmp_result->{$oid_jnxCosFcQueueNr}->{$oid} } = $self->{output}->decode(join('', map(chr($_), split(/\./, $1))));
    }

    $self->{interfaces} = {};
    my $load_instances = {};
    foreach (keys %{$snmp_result->{$oid_jnxCosQstatQedBytes}}) {
        /^$oid_jnxCosQstatQedBytes\.(\d+).(\d+)$/;
        my ($ifindex, $queue_num) = ($1, $2);

        $load_instances->{ $ifindex . '.' . $queue_num } = 1;
        if (!defined($self->{interfaces}->{$ifindex})) {
            $self->{interfaces}->{$ifindex} = {
                cos => {}
            };
        }

        if (defined($self->{option_results}->{filter_class_name}) && $self->{option_results}->{filter_class_name} ne '' &&
            $queues->{$queue_num} !~ /$self->{option_results}->{filter_class_name}/) {
            $self->{output}->output_add(long_msg => "skipping class of service '" . $queues->{$queue_num} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{interfaces}->{$ifindex}->{cos}->{ $queues->{$queue_num} } = {
            name => $queues->{$queue_num},
            instance => $queue_num,
            queued_bytes => $snmp_result->{$oid_jnxCosQstatQedBytes}->{$_} * 8
        };
    }

    # get interface name
    $options{snmp}->load(
        oids => [ $oid_ifName ],
        instances => [keys %{$self->{interfaces}}],
        instance_regexp => '^(.*)$'
    );
    $options{snmp}->load(
        oids => [ map($_->{oid}, values(%$mapping)) ],
        instances => [keys %$load_instances],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef();

    foreach my $ifindex (keys %{$self->{interfaces}}) {
        my $int_name = $snmp_result->{ $oid_ifName . '.' . $ifindex };
        if (defined($self->{option_results}->{filter_interface_name}) && $self->{option_results}->{filter_interface_name} ne '' &&
            $int_name !~ /$self->{option_results}->{filter_interface_name}/) {
            $self->{output}->output_add(long_msg => "skipping interface '" . $int_name . "': no matching filter.", debug => 1);
            delete $self->{interfaces}->{$ifindex};
            next;
        }

        $self->{interfaces}->{ $int_name } = delete $self->{interfaces}->{$ifindex};
        $self->{interfaces}->{ $int_name }->{name} = $int_name;
        foreach my $queue_name (keys %{$self->{interfaces}->{$int_name}->{cos}}) {
            my $queue_num = $self->{interfaces}->{$int_name}->{cos}->{$queue_name}->{instance};
            my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $ifindex . '.' . $queue_num);
            $self->{interfaces}->{$int_name}->{cos}->{$queue_name}->{traffic_out_bytes} = $result->{traffic_out_bytes} * 8
                if (defined($result->{traffic_out_bytes}));
            $self->{interfaces}->{$int_name}->{cos}->{$queue_name}->{drop_bytes} = $result->{drop_bytes} * 8
                if (defined($result->{drop_bytes}));
        }
    }

    $self->{cache_name} = 'juniper_junos_' . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_interface_name}) ? md5_hex($self->{option_results}->{filter_interface_name}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_class_name}) ? md5_hex($self->{option_results}->{filter_class_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check class of services.

=over 8

=item B<--filter-interface-name>

Filter interfaces (can be a regexp).

=item B<--filter-class-name>

Filter class of services (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'queued', 'traffic-out', 'dropped'. 

=back

=cut
