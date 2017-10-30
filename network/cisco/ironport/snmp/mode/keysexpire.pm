#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

package network::cisco::ironport::snmp::mode::keysexpire;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'keys', type => 1, cb_prefix_output => 'prefix_keys_output', message_multiple => 'All keys are ok' }
    ];
    
    $self->{maps_counters}->{keys} = [
        { label => 'seconds', set => {
                key_values => [ { name => 'seconds' }, { name => 'msg' }, { name => 'display' } ],
                output_template => '%s remaining before expiration',
                output_use => 'msg_absolute',
                closure_custom_perfdata => sub { return 0; },
            }
        },
    ];
}

sub prefix_keys_output {
    my ($self, %options) = @_;
    
    return "Key '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                });

    return $self;
}

my $mapping = {
    keyDescription          => { oid => '.1.3.6.1.4.1.15497.1.1.1.12.1.2' },
    keyIsPerpetual          => { oid => '.1.3.6.1.4.1.15497.1.1.1.12.1.3' },
    keySecondsUntilExpire   => { oid => '.1.3.6.1.4.1.15497.1.1.1.12.1.4' },
};
my $oid_keyExpirationEntry = '.1.3.6.1.4.1.15497.1.1.1.12.1';

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{keys} = {};
    my $snmp_result = $options{snmp}->get_table(oid => $oid_keyExpirationEntry, 
        nothing_quit => 1);

    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{keySecondsUntilExpire}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        next if ($result->{keyIsPerpetual} == 1);
        
        $self->{keys}->{$instance} = { 
            display => $result->{keyDescription},
            seconds => $result->{keySecondsUntilExpire},
            msg     => centreon::plugins::misc::change_seconds(value => $result->{keySecondsUntilExpire}),
        };
    }
    
    if (scalar(keys %{$self->{keys}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No key found.");
        $self->{output}->option_exit();
    }
}
    
1;

__END__

=head1 MODE

Check number of seconds remaining before the expiration of keys.

=over 8

=item B<--warning-seconds>

Threshold warning in seconds.

=item B<--critical-seconds>

Threshold critical in seconds.

=back

=cut
    
