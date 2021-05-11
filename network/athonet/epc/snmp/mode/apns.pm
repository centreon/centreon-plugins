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

package network::athonet::epc::snmp::mode::apns;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub prefix_apn_output {
    my ($self, %options) = @_;

    return 'apn ';
}

sub apn_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking apn '%s'",
        $options{instance_value}->{name}
    );;
}

sub prefix_traffic_output {
    my ($self, %options) = @_;

    return 'traffic ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name => 'apns', type => 3, cb_prefix_output => 'prefix_apn_output', cb_long_output => 'apn_long_output', 
            indent_long_output => '    ', message_multiple => 'All access point names are ok',
            group => [
                { name => 'traffic', type => 0, cb_prefix_output => 'prefix_traffic_output', skipped_code => { -10 => 1 } },
                { name => 'pdp', type => 0, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{traffic} = [
        { label => 'traffic-in', nlabel => 'apn.traffic.in.bytespersecond', set => {
                key_values => [ { name => 'traffic_in', per_second => 1 } ],
                output_template => 'in: %.2f %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%.2f', unit => 'B/s', min => 0, label_extra_instance => 1  }
                ]
            }
        },
        { label => 'traffic-out', nlabel => 'apn.traffic.out.bytespersecond', set => {
                key_values => [ { name => 'traffic_out', per_second => 1 } ],
                output_template => 'out: %.2f %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%.2f', unit => 'B/s', min => 0, label_extra_instance => 1  }
                ]
            }
        }
    ];

    $self->{maps_counters}->{pdp} = [
        { label => 'pdp-contexts', nlabel => 'apn.pdp_contexts.count', set => {
                key_values => [ { name => 'contexts' } ],
                output_template => 'pdp contexts: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1  }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s'  => { name => 'filter_name' }
    });

    return $self;
}

my $mapping = {
    traffic_in   => { oid => '.1.3.6.1.4.1.35805.10.2.99.14.1.2' }, # aPNRowDownlinkBytes
    traffic_out  => { oid => '.1.3.6.1.4.1.35805.10.2.99.14.1.3' }, # aPNRowUplinkBytes
    pdp_contexts => { oid => '.1.3.6.1.4.1.35805.10.2.99.14.1.4' }  # aPNRowPdpContexts
};

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = 'athonet_epc_' . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));

    my $oid_apn_name = '.1.3.6.1.4.1.35805.10.2.99.14.1.1'; # aPNRowApnKey
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_apn_name,
        nothing_quit => 1
    );

    $self->{apns} = {};
    foreach (keys %$snmp_result) {
        /^$oid_apn_name\.(.*)$/;
        my $instance = $1;
        my $name = $self->{output}->decode($snmp_result->{$_});

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $name . "': no matching filter.", debug => 1);
            next;
        }

        $self->{apns}->{$name} = {
            instance => $instance,
            name => $name,
            traffic => {},
            context => {}
        };
    }

    $self->{global}->{total} = scalar(keys %{$self->{apns}});
    return if (scalar(keys %{$self->{apns}}) <= 0);

    $options{snmp}->load(oids => [
            map($_->{oid}, values(%$mapping))
        ],
        instances => [ map($_->{instance}, values(%{$self->{apns}})) ],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);

    foreach (keys %{$self->{apns}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $self->{apns}->{$_}->{instance});
        $self->{apns}->{$_}->{traffic}->{traffic_in} = $result->{traffic_in};
        $self->{apns}->{$_}->{traffic}->{traffic_out} = $result->{traffic_out};
        $self->{apns}->{$_}->{pdp}->{contexts} = $result->{pdp_contexts};
    }    
}

1;

__END__

=head1 MODE

Check access point names.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='traffic'

=item B<--filter-name>

Filter APN by name (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'traffic-in', 'traffic-out', 'pdp-contexts'.

=back

=cut
