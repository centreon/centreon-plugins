#
# Copyright 2015 Centreon (http://www.centreon.com/)
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

package network::juniper::trapeze::snmp::mode::apusers;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'ssid', type => 1, cb_prefix_output => 'prefix_ssid_output', message_multiple => 'All users by SSID are ok' },
        { name => 'ap', type => 1, cb_prefix_output => 'prefix_ap_output', message_multiple => 'All users by AP are ok' },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'Total Users : %s',
                perfdatas => [
                    { label => 'total', value => 'total', template => '%s',
                      unit => 'users', min => 0 },
                ],
            }
        },
    ];

    $self->{maps_counters}->{ssid} = [
        { label => 'ssid', set => {
                key_values => [ { name => 'total' }, { name => 'display' } ],
                output_template => 'users : %s',
                perfdatas => [
                    { label => 'ssid', value => 'total', template => '%s',
                      unit => 'users', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];

    $self->{maps_counters}->{ap} = [
        { label => 'ap', set => {
                key_values => [ { name => 'total' }, { name => 'display' } ],
                output_template => 'users : %s',
                perfdatas => [
                    { label => 'ap', value => 'total', template => '%s',
                      unit => 'users', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];

}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments =>
                                {
                                "filter-ssid:s" => { name => 'filter_ssid' },
                                "filter-ap:s"   => { name => 'filter_ap' },
                                });

    return $self;
}

sub prefix_ssid_output {
    my ($self, %options) = @_;

    return "SSID '" . $options{instance_value}->{display} . "' ";
}

sub prefix_ap_output {
    my ($self, %options) = @_;

    return "AP '" . $options{instance_value}->{display} . "' ";
}

my $mapping = {
    trpzClSessClientSessApSerialNum   => { oid => '.1.3.6.1.4.1.14525.4.4.1.1.1.1.7' },
};

my $mapping1 = {
    trpzClSessClientSessSsid => { oid => '.1.3.6.1.4.1.14525.4.4.1.1.1.1.15' },
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_trpzApStatApStatusApName = '.1.3.6.1.4.1.14525.4.5.1.1.2.1.8';
    $self->{global} = { total => 0};
    $self->{ssid} = {};
    $self->{ap} = {};

    $self->{results} = $options{snmp}->get_multiple_table(oids => [{ oid => $oid_trpzApStatApStatusApName }, { oid => $mapping->{trpzClSessClientSessApSerialNum}->{oid} },
                                                                   { oid => $mapping1->{trpzClSessClientSessSsid}->{oid} }],
                                                          nothing_quit => 1);

    foreach my $oid (keys %{$self->{results}->{ $mapping->{trpzClSessClientSessApSerialNum}->{oid} }}) {
        $oid =~ /^$mapping->{trpzClSessClientSessApSerialNum}->{oid}\.(.*)$/;
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{ $mapping->{trpzClSessClientSessApSerialNum}->{oid} }, instance => $instance);
        my $result1 = $options{snmp}->map_instance(mapping => $mapping1, results => $self->{results}->{ $mapping1->{trpzClSessClientSessSsid}->{oid} }, instance => $instance);
        my @chars = split(//,$result->{trpzClSessClientSessApSerialNum});
        my $ap_oid = '12';
        foreach my $char (@chars) {
            $ap_oid .= '.'.ord($char);
        }
        my $ap_name = $self->{results}->{$oid_trpzApStatApStatusApName}->{$oid_trpzApStatApStatusApName . '.' . $ap_oid};
        if (defined($self->{option_results}->{filter_ap}) && $self->{option_results}->{filter_ap} ne '' &&
            $ap_name !~ /$self->{option_results}->{filter_ap}/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $ap_name . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_ssid}) && $self->{option_results}->{filter_ssid} ne '' &&
            $result1->{trpzClSessClientSessSsid} !~ /$self->{option_results}->{filter_ssid}/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $result1->{trpzClSessClientSessSsid} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{global}->{total}++;
        $self->{ap}->{$ap_name} = { total => 0, display => $ap_name } if (!defined($self->{ap}->{$ap_name}));
        $self->{ap}->{$ap_name}->{total}++;
        $self->{ssid}->{$result1->{trpzClSessClientSessSsid}} = { total => 0, display => $result1->{trpzClSessClientSessSsid} } if (!defined($self->{ssid}->{$result1->{trpzClSessClientSessSsid}}));
        $self->{ssid}->{$result1->{trpzClSessClientSessSsid}}->{total}++;
    }

    if (scalar(keys %{$self->{ap}}) <= 0 && scalar(keys %{$self->{ssid}}) <= 0) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'No AP nor SSID found, check your filter or maybe we are on a slave controller ? ');
    }
}

1;

__END__

=head1 MODE

Check AP users.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).

=item B<--filter-ap>

Filter AP name (can be a regexp).

=item B<--filter-ssid>

Filter SSID name (can be a regexp).

=item B<--warning-*>

Set warning threshold for number of user. Can be : 'total', 'ssid', 'ap' .

=item B<--critical-*>

Set critical threshold for number of user. Can be : 'total', 'ssid', 'ap' .

=back

=cut
