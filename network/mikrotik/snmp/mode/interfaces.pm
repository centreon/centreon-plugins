#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package network::mikrotik::snmp::mode::interfaces;

use base qw(snmp_standard::mode::interfaces);

use strict;
use warnings;

sub set_oids_errors {
    my ($self, %options) = @_;
    
    $self->{oid_ifInDiscards} = '.1.3.6.1.2.1.2.2.1.13';
    $self->{oid_ifInErrors} = '.1.3.6.1.2.1.2.2.1.14';
    $self->{oid_ifOutDiscards} = '.1.3.6.1.2.1.2.2.1.19';
    $self->{oid_ifOutErrors} = '.1.3.6.1.2.1.2.2.1.20';
    $self->{oid_ifInTooShort} = '.1.3.6.1.4.1.14988.1.1.14.1.1.33';
    $self->{oid_ifInTooLong} = '.1.3.6.1.4.1.14988.1.1.14.1.1.41';
    $self->{oid_ifInFCSError} = '.1.3.6.1.4.1.14988.1.1.14.1.1.45';
    $self->{oid_ifInAlignError} = '.1.3.6.1.4.1.14988.1.1.14.1.1.46';
    $self->{oid_ifInFragment} = '.1.3.6.1.4.1.14988.1.1.14.1.1.47';
    $self->{oid_ifInOverflow} = '.1.3.6.1.4.1.14988.1.1.14.1.1.48';
    $self->{oid_ifInUnknownOp} = '.1.3.6.1.4.1.14988.1.1.14.1.1.50';
    $self->{oid_ifInLengthError} = '.1.3.6.1.4.1.14988.1.1.14.1.1.51';
    $self->{oid_ifInCodeError} = '.1.3.6.1.4.1.14988.1.1.14.1.1.52';
    $self->{oid_ifInCarrierError} = '.1.3.6.1.4.1.14988.1.1.14.1.1.53';
    $self->{oid_ifInJabber} = '.1.3.6.1.4.1.14988.1.1.14.1.1.54';
    $self->{oid_ifInDrop} = '.1.3.6.1.4.1.14988.1.1.14.1.1.55';
    $self->{oid_ifOutTooShort} = '.1.3.6.1.4.1.14988.1.1.14.1.1.63';
    $self->{oid_ifOutTooLong} = '.1.3.6.1.4.1.14988.1.1.14.1.1.71';
    $self->{oid_ifOutUnderrun} = '.1.3.6.1.4.1.14988.1.1.14.1.1.75';
    $self->{oid_ifOutCollision} = '.1.3.6.1.4.1.14988.1.1.14.1.1.76';
    $self->{oid_ifOutExcessiveCollision} = '.1.3.6.1.4.1.14988.1.1.14.1.1.77';
    $self->{oid_ifOutMultipleCollision} = '.1.3.6.1.4.1.14988.1.1.14.1.1.78';
    $self->{oid_ifOutSingleCollision} = '.1.3.6.1.4.1.14988.1.1.14.1.1.79';
    $self->{oid_ifOutExcessiveDeferred} = '.1.3.6.1.4.1.14988.1.1.14.1.1.80';
    $self->{oid_ifOutDeferred} = '.1.3.6.1.4.1.14988.1.1.14.1.1.81';
    $self->{oid_ifOutLateCollision} = '.1.3.6.1.4.1.14988.1.1.14.1.1.82';
    $self->{oid_ifOutTotalCollision} = '.1.3.6.1.4.1.14988.1.1.14.1.1.83';
    $self->{oid_ifOutDrop} = '.1.3.6.1.4.1.14988.1.1.14.1.1.85';
    $self->{oid_ifOutJabber} = '.1.3.6.1.4.1.14988.1.1.14.1.1.86';
    $self->{oid_ifOutFCSError} = '.1.3.6.1.4.1.14988.1.1.14.1.1.87';
    $self->{oid_ifOutFragment} = '.1.3.6.1.4.1.14988.1.1.14.1.1.89';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters} = { int => {}, global => {} };
    
    $self->{maps_counters}->{int}->{'133_in-tooshort'} = { filter => 'add_errors',
        set => {
            key_values => [ { name => 'intooshort', diff => 1 }, { name => 'total_in_packets', diff => 1 }, { name => 'display' }, { name => 'mode_cast' } ],
            closure_custom_calc => $self->can('custom_errors_calc'), closure_custom_calc_extra_options => { label_ref1 => 'in', label_ref2 => 'tooshort' },
            closure_custom_output => $self->can('custom_errors_output'), output_error_template => 'Packets In TooShort : %s',
            closure_custom_perfdata => $self->can('custom_errors_perfdata'),
            closure_custom_threshold_check => $self->can('custom_errors_threshold'),
        }
    };

    $self->{maps_counters}->{int}->{'141_in-toolong'} = { filter => 'add_errors',
        set => {
            key_values => [ { name => 'intoolong', diff => 1 }, { name => 'total_in_packets', diff => 1 }, { name => 'display' }, { name => 'mode_cast' } ],
            closure_custom_calc => $self->can('custom_errors_calc'), closure_custom_calc_extra_options => { label_ref1 => 'in', label_ref2 => 'toolong' },
            closure_custom_output => $self->can('custom_errors_output'), output_error_template => 'Packets In TooLong : %s',
            closure_custom_perfdata => $self->can('custom_errors_perfdata'),
            closure_custom_threshold_check => $self->can('custom_errors_threshold'),
        }
    };

    $self->{maps_counters}->{int}->{'145_in-fcserror'} = { filter => 'add_errors',
        set => {
            key_values => [ { name => 'infcserror', diff => 1 }, { name => 'total_in_packets', diff => 1 }, { name => 'display' }, { name => 'mode_cast' } ],
            closure_custom_calc => $self->can('custom_errors_calc'), closure_custom_calc_extra_options => { label_ref1 => 'in', label_ref2 => 'fcserror' },
            closure_custom_output => $self->can('custom_errors_output'), output_error_template => 'Packets In FCSError : %s',
            closure_custom_perfdata => $self->can('custom_errors_perfdata'),
            closure_custom_threshold_check => $self->can('custom_errors_threshold'),
        }
    };

    $self->{maps_counters}->{int}->{'146_in-alignerror'} = { filter => 'add_errors',
        set => {
            key_values => [ { name => 'inalignerror', diff => 1 }, { name => 'total_in_packets', diff => 1 }, { name => 'display' }, { name => 'mode_cast' } ],
            closure_custom_calc => $self->can('custom_errors_calc'), closure_custom_calc_extra_options => { label_ref1 => 'in', label_ref2 => 'alignerror' },
            closure_custom_output => $self->can('custom_errors_output'), output_error_template => 'Packets In AlignError : %s',
            closure_custom_perfdata => $self->can('custom_errors_perfdata'),
            closure_custom_threshold_check => $self->can('custom_errors_threshold'),
        }
    };

    $self->{maps_counters}->{int}->{'147_in-fragment'} = { filter => 'add_errors',
        set => {
            key_values => [ { name => 'infragment', diff => 1 }, { name => 'total_in_packets', diff => 1 }, { name => 'display' }, { name => 'mode_cast' } ],
            closure_custom_calc => $self->can('custom_errors_calc'), closure_custom_calc_extra_options => { label_ref1 => 'in', label_ref2 => 'fragment' },
            closure_custom_output => $self->can('custom_errors_output'), output_error_template => 'Packets In Fragment : %s',
            closure_custom_perfdata => $self->can('custom_errors_perfdata'),
            closure_custom_threshold_check => $self->can('custom_errors_threshold'),
        }
    };

    $self->{maps_counters}->{int}->{'148_in-overflow'} = { filter => 'add_errors',
        set => {
            key_values => [ { name => 'inoverflow', diff => 1 }, { name => 'total_in_packets', diff => 1 }, { name => 'display' }, { name => 'mode_cast' } ],
            closure_custom_calc => $self->can('custom_errors_calc'), closure_custom_calc_extra_options => { label_ref1 => 'in', label_ref2 => 'overflow' },
            closure_custom_output => $self->can('custom_errors_output'), output_error_template => 'Packets In Overflow : %s',
            closure_custom_perfdata => $self->can('custom_errors_perfdata'),
            closure_custom_threshold_check => $self->can('custom_errors_threshold'),
        }
    };

    $self->{maps_counters}->{int}->{'150_in-unknownop'} = { filter => 'add_errors',
        set => {
            key_values => [ { name => 'inunknownop', diff => 1 }, { name => 'total_in_packets', diff => 1 }, { name => 'display' }, { name => 'mode_cast' } ],
            closure_custom_calc => $self->can('custom_errors_calc'), closure_custom_calc_extra_options => { label_ref1 => 'in', label_ref2 => 'unknownop' },
            closure_custom_output => $self->can('custom_errors_output'), output_error_template => 'Packets In UnknownOp : %s',
            closure_custom_perfdata => $self->can('custom_errors_perfdata'),
            closure_custom_threshold_check => $self->can('custom_errors_threshold'),
        }
    };

    $self->{maps_counters}->{int}->{'151_in-lengtherror'} = { filter => 'add_errors',
        set => {
            key_values => [ { name => 'inlengtherror', diff => 1 }, { name => 'total_in_packets', diff => 1 }, { name => 'display' }, { name => 'mode_cast' } ],
            closure_custom_calc => $self->can('custom_errors_calc'), closure_custom_calc_extra_options => { label_ref1 => 'in', label_ref2 => 'lengtherror' },
            closure_custom_output => $self->can('custom_errors_output'), output_error_template => 'Packets In LengthError : %s',
            closure_custom_perfdata => $self->can('custom_errors_perfdata'),
            closure_custom_threshold_check => $self->can('custom_errors_threshold'),
        }
    };

    $self->{maps_counters}->{int}->{'152_in-codeerror'} = { filter => 'add_errors',
        set => {
            key_values => [ { name => 'incodeerror', diff => 1 }, { name => 'total_in_packets', diff => 1 }, { name => 'display' }, { name => 'mode_cast' } ],
            closure_custom_calc => $self->can('custom_errors_calc'), closure_custom_calc_extra_options => { label_ref1 => 'in', label_ref2 => 'codeerror' },
            closure_custom_output => $self->can('custom_errors_output'), output_error_template => 'Packets In CodeError : %s',
            closure_custom_perfdata => $self->can('custom_errors_perfdata'),
            closure_custom_threshold_check => $self->can('custom_errors_threshold'),
        }
    };

    $self->{maps_counters}->{int}->{'153_in-carriererror'} = { filter => 'add_errors',
        set => {
            key_values => [ { name => 'incarriererror', diff => 1 }, { name => 'total_in_packets', diff => 1 }, { name => 'display' }, { name => 'mode_cast' } ],
            closure_custom_calc => $self->can('custom_errors_calc'), closure_custom_calc_extra_options => { label_ref1 => 'in', label_ref2 => 'carriererror' },
            closure_custom_output => $self->can('custom_errors_output'), output_error_template => 'Packets In CarrierError : %s',
            closure_custom_perfdata => $self->can('custom_errors_perfdata'),
            closure_custom_threshold_check => $self->can('custom_errors_threshold'),
        }
    };

    $self->{maps_counters}->{int}->{'154_in-jabber'} = { filter => 'add_errors',
        set => {
            key_values => [ { name => 'injabber', diff => 1 }, { name => 'total_in_packets', diff => 1 }, { name => 'display' }, { name => 'mode_cast' } ],
            closure_custom_calc => $self->can('custom_errors_calc'), closure_custom_calc_extra_options => { label_ref1 => 'in', label_ref2 => 'jabber' },
            closure_custom_output => $self->can('custom_errors_output'), output_error_template => 'Packets In Jabber : %s',
            closure_custom_perfdata => $self->can('custom_errors_perfdata'),
            closure_custom_threshold_check => $self->can('custom_errors_threshold'),
        }
    };

    $self->{maps_counters}->{int}->{'155_in-drop'} = { filter => 'add_errors',
        set => {
            key_values => [ { name => 'indrop', diff => 1 }, { name => 'total_in_packets', diff => 1 }, { name => 'display' }, { name => 'mode_cast' } ],
            closure_custom_calc => $self->can('custom_errors_calc'), closure_custom_calc_extra_options => { label_ref1 => 'in', label_ref2 => 'drop' },
            closure_custom_output => $self->can('custom_errors_output'), output_error_template => 'Packets In Drop : %s',
            closure_custom_perfdata => $self->can('custom_errors_perfdata'),
            closure_custom_threshold_check => $self->can('custom_errors_threshold'),
        }
    };

    $self->{maps_counters}->{int}->{'163_out-tooshort'} = { filter => 'add_errors',
        set => {
            key_values => [ { name => 'outtooshort', diff => 1 }, { name => 'total_out_packets', diff => 1 }, { name => 'display' }, { name => 'mode_cast' } ],
            closure_custom_calc => $self->can('custom_errors_calc'), closure_custom_calc_extra_options => { label_ref1 => 'out', label_ref2 => 'tooshort' },
            closure_custom_output => $self->can('custom_errors_output'), output_error_template => 'Packets Out TooShort : %s',
            closure_custom_perfdata => $self->can('custom_errors_perfdata'),
            closure_custom_threshold_check => $self->can('custom_errors_threshold'),
        }
    };

    $self->{maps_counters}->{int}->{'171_out-toolong'} = { filter => 'add_errors',
        set => {
            key_values => [ { name => 'outtoolong', diff => 1 }, { name => 'total_out_packets', diff => 1 }, { name => 'display' }, { name => 'mode_cast' } ],
            closure_custom_calc => $self->can('custom_errors_calc'), closure_custom_calc_extra_options => { label_ref1 => 'out', label_ref2 => 'toolong' },
            closure_custom_output => $self->can('custom_errors_output'), output_error_template => 'Packets Out TooLong : %s',
            closure_custom_perfdata => $self->can('custom_errors_perfdata'),
            closure_custom_threshold_check => $self->can('custom_errors_threshold'),
        }
    };

    $self->{maps_counters}->{int}->{'175_out-underrun'} = { filter => 'add_errors',
        set => {
            key_values => [ { name => 'outunderrun', diff => 1 }, { name => 'total_out_packets', diff => 1 }, { name => 'display' }, { name => 'mode_cast' } ],
            closure_custom_calc => $self->can('custom_errors_calc'), closure_custom_calc_extra_options => { label_ref1 => 'out', label_ref2 => 'underrun' },
            closure_custom_output => $self->can('custom_errors_output'), output_error_template => 'Packets Out Underrun : %s',
            closure_custom_perfdata => $self->can('custom_errors_perfdata'),
            closure_custom_threshold_check => $self->can('custom_errors_threshold'),
        }
    };

    $self->{maps_counters}->{int}->{'176_out-collision'} = { filter => 'add_errors',
        set => {
            key_values => [ { name => 'outcollision', diff => 1 }, { name => 'total_out_packets', diff => 1 }, { name => 'display' }, { name => 'mode_cast' } ],
            closure_custom_calc => $self->can('custom_errors_calc'), closure_custom_calc_extra_options => { label_ref1 => 'out', label_ref2 => 'collision' },
            closure_custom_output => $self->can('custom_errors_output'), output_error_template => 'Packets Out Collision : %s',
            closure_custom_perfdata => $self->can('custom_errors_perfdata'),
            closure_custom_threshold_check => $self->can('custom_errors_threshold'),
        }
    };

    $self->{maps_counters}->{int}->{'177_out-excessivecollision'} = { filter => 'add_errors',
        set => {
            key_values => [ { name => 'outexcessivecollision', diff => 1 }, { name => 'total_out_packets', diff => 1 }, { name => 'display' }, { name => 'mode_cast' } ],
            closure_custom_calc => $self->can('custom_errors_calc'), closure_custom_calc_extra_options => { label_ref1 => 'out', label_ref2 => 'excessivecollision' },
            closure_custom_output => $self->can('custom_errors_output'), output_error_template => 'Packets Out ExcessiveCollision : %s',
            closure_custom_perfdata => $self->can('custom_errors_perfdata'),
            closure_custom_threshold_check => $self->can('custom_errors_threshold'),
        }
    };

    $self->{maps_counters}->{int}->{'178_out-multiplecollision'} = { filter => 'add_errors',
        set => {
            key_values => [ { name => 'outmultiplecollision', diff => 1 }, { name => 'total_out_packets', diff => 1 }, { name => 'display' }, { name => 'mode_cast' } ],
            closure_custom_calc => $self->can('custom_errors_calc'), closure_custom_calc_extra_options => { label_ref1 => 'out', label_ref2 => 'multiplecollision' },
            closure_custom_output => $self->can('custom_errors_output'), output_error_template => 'Packets Out MultipleCollision : %s',
            closure_custom_perfdata => $self->can('custom_errors_perfdata'),
            closure_custom_threshold_check => $self->can('custom_errors_threshold'),
        }
    };

    $self->{maps_counters}->{int}->{'179_out-singlecollision'} = { filter => 'add_errors',
        set => {
            key_values => [ { name => 'outsinglecollision', diff => 1 }, { name => 'total_out_packets', diff => 1 }, { name => 'display' }, { name => 'mode_cast' } ],
            closure_custom_calc => $self->can('custom_errors_calc'), closure_custom_calc_extra_options => { label_ref1 => 'out', label_ref2 => 'singlecollision' },
            closure_custom_output => $self->can('custom_errors_output'), output_error_template => 'Packets Out SingleCollision : %s',
            closure_custom_perfdata => $self->can('custom_errors_perfdata'),
            closure_custom_threshold_check => $self->can('custom_errors_threshold'),
        }
    };

    $self->{maps_counters}->{int}->{'180_out-excessivedeferred'} = { filter => 'add_errors',
        set => {
            key_values => [ { name => 'outexcessivedeferred', diff => 1 }, { name => 'total_out_packets', diff => 1 }, { name => 'display' }, { name => 'mode_cast' } ],
            closure_custom_calc => $self->can('custom_errors_calc'), closure_custom_calc_extra_options => { label_ref1 => 'out', label_ref2 => 'excessivedeferred' },
            closure_custom_output => $self->can('custom_errors_output'), output_error_template => 'Packets Out ExcessiveDeferred : %s',
            closure_custom_perfdata => $self->can('custom_errors_perfdata'),
            closure_custom_threshold_check => $self->can('custom_errors_threshold'),
        }
    };

    $self->{maps_counters}->{int}->{'181_out-deferred'} = { filter => 'add_errors',
        set => {
            key_values => [ { name => 'outdeferred', diff => 1 }, { name => 'total_out_packets', diff => 1 }, { name => 'display' }, { name => 'mode_cast' } ],
            closure_custom_calc => $self->can('custom_errors_calc'), closure_custom_calc_extra_options => { label_ref1 => 'out', label_ref2 => 'deferred' },
            closure_custom_output => $self->can('custom_errors_output'), output_error_template => 'Packets Out Deferred : %s',
            closure_custom_perfdata => $self->can('custom_errors_perfdata'),
            closure_custom_threshold_check => $self->can('custom_errors_threshold'),
        }
    };

    $self->{maps_counters}->{int}->{'182_out-latecollision'} = { filter => 'add_errors',
        set => {
            key_values => [ { name => 'outlatecollision', diff => 1 }, { name => 'total_out_packets', diff => 1 }, { name => 'display' }, { name => 'mode_cast' } ],
            closure_custom_calc => $self->can('custom_errors_calc'), closure_custom_calc_extra_options => { label_ref1 => 'out', label_ref2 => 'latecollision' },
            closure_custom_output => $self->can('custom_errors_output'), output_error_template => 'Packets Out LateCollision : %s',
            closure_custom_perfdata => $self->can('custom_errors_perfdata'),
            closure_custom_threshold_check => $self->can('custom_errors_threshold'),
        }
    };

    $self->{maps_counters}->{int}->{'183_out-totalcollision'} = { filter => 'add_errors',
        set => {
            key_values => [ { name => 'outtotalcollision', diff => 1 }, { name => 'total_out_packets', diff => 1 }, { name => 'display' }, { name => 'mode_cast' } ],
            closure_custom_calc => $self->can('custom_errors_calc'), closure_custom_calc_extra_options => { label_ref1 => 'out', label_ref2 => 'totalcollision' },
            closure_custom_output => $self->can('custom_errors_output'), output_error_template => 'Packets Out TotalCollision : %s',
            closure_custom_perfdata => $self->can('custom_errors_perfdata'),
            closure_custom_threshold_check => $self->can('custom_errors_threshold'),
        }
    };

    $self->{maps_counters}->{int}->{'185_out-drop'} = { filter => 'add_errors',
        set => {
            key_values => [ { name => 'outdrop', diff => 1 }, { name => 'total_out_packets', diff => 1 }, { name => 'display' }, { name => 'mode_cast' } ],
            closure_custom_calc => $self->can('custom_errors_calc'), closure_custom_calc_extra_options => { label_ref1 => 'out', label_ref2 => 'drop' },
            closure_custom_output => $self->can('custom_errors_output'), output_error_template => 'Packets Out Drop : %s',
            closure_custom_perfdata => $self->can('custom_errors_perfdata'),
            closure_custom_threshold_check => $self->can('custom_errors_threshold'),
        }
    };

    $self->{maps_counters}->{int}->{'186_out-jabber'} = { filter => 'add_errors',
        set => {
            key_values => [ { name => 'outjabber', diff => 1 }, { name => 'total_out_packets', diff => 1 }, { name => 'display' }, { name => 'mode_cast' } ],
            closure_custom_calc => $self->can('custom_errors_calc'), closure_custom_calc_extra_options => { label_ref1 => 'out', label_ref2 => 'jabber' },
            closure_custom_output => $self->can('custom_errors_output'), output_error_template => 'Packets Out Jabber : %s',
            closure_custom_perfdata => $self->can('custom_errors_perfdata'),
            closure_custom_threshold_check => $self->can('custom_errors_threshold'),
        }
    };

    $self->{maps_counters}->{int}->{'187_out-fcserror'} = { filter => 'add_errors',
        set => {
            key_values => [ { name => 'outfcserror', diff => 1 }, { name => 'total_out_packets', diff => 1 }, { name => 'display' }, { name => 'mode_cast' } ],
            closure_custom_calc => $self->can('custom_errors_calc'), closure_custom_calc_extra_options => { label_ref1 => 'out', label_ref2 => 'fcserror' },
            closure_custom_output => $self->can('custom_errors_output'), output_error_template => 'Packets Out FCSError : %s',
            closure_custom_perfdata => $self->can('custom_errors_perfdata'),
            closure_custom_threshold_check => $self->can('custom_errors_threshold'),
        }
    };

    $self->{maps_counters}->{int}->{'189_out-fragment'} = { filter => 'add_errors',
        set => {
            key_values => [ { name => 'outfragment', diff => 1 }, { name => 'total_out_packets', diff => 1 }, { name => 'display' }, { name => 'mode_cast' } ],
            closure_custom_calc => $self->can('custom_errors_calc'), closure_custom_calc_extra_options => { label_ref1 => 'out', label_ref2 => 'fragment' },
            closure_custom_output => $self->can('custom_errors_output'), output_error_template => 'Packets Out Fragment : %s',
            closure_custom_perfdata => $self->can('custom_errors_perfdata'),
            closure_custom_threshold_check => $self->can('custom_errors_threshold'),
        }
    };
    
    $self->SUPER::set_counters(%options);
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    return $self;
}

sub load_errors {
    my ($self, %options) = @_;
    
    $self->set_oids_errors();
    $self->{snmp}->load(
        oids => [
            $self->{oid_ifInDiscards}, $self->{oid_ifInErrors},
            $self->{oid_ifOutDiscards}, $self->{oid_ifOutErrors},
            $self->{oid_ifInTooShort}, $self->{oid_ifInTooLong}, $self->{oid_ifInFCSError}, $self->{oid_ifInAlignError}, $self->{oid_ifInFragment}, $self->{oid_ifInOverflow}, $self->{oid_ifInUnknownOp}, $self->{oid_ifInLengthError}, $self->{oid_ifInCodeError}, $self->{oid_ifInCarrierError}, $self->{oid_ifInJabber}, $self->{oid_ifInDrop},
            $self->{oid_ifOutTooShort}, $self->{oid_ifOutTooLong}, $self->{oid_ifOutUnderrun}, $self->{oid_ifOutCollision}, $self->{oid_ifOutExcessiveCollision}, $self->{oid_ifOutMultipleCollision}, $self->{oid_ifOutSingleCollision}, $self->{oid_ifOutExcessiveDeferred}, $self->{oid_ifOutDeferred}, $self->{oid_ifOutLateCollision}, $self->{oid_ifOutTotalCollision}, $self->{oid_ifOutDrop}, $self->{oid_ifOutJabber}, $self->{oid_ifOutFCSError}, $self->{oid_ifOutFragment}
        ],
        instances => $self->{array_interface_selected}
    );
}

sub add_result_errors {
    my ($self, %options) = @_;
    
    $self->{interface_selected}->{$options{instance}}->{indiscard} = $self->{results}->{$self->{oid_ifInDiscards} . '.' . $options{instance}};
    $self->{interface_selected}->{$options{instance}}->{inerror} = $self->{results}->{$self->{oid_ifInErrors} . '.' . $options{instance}};
    $self->{interface_selected}->{$options{instance}}->{outdiscard} = $self->{results}->{$self->{oid_ifOutDiscards} . '.' . $options{instance}};
    $self->{interface_selected}->{$options{instance}}->{outerror} = $self->{results}->{$self->{oid_ifOutErrors} . '.' . $options{instance}};
    $self->{interface_selected}->{$options{instance}}->{intooshort} = $self->{results}->{$self->{oid_ifInTooShort} . '.' . $options{instance}};
    $self->{interface_selected}->{$options{instance}}->{intoolong} = $self->{results}->{$self->{oid_ifInTooLong} . '.' . $options{instance}};
    $self->{interface_selected}->{$options{instance}}->{infcserror} = $self->{results}->{$self->{oid_ifInFCSError} . '.' . $options{instance}};
    $self->{interface_selected}->{$options{instance}}->{inalignerror} = $self->{results}->{$self->{oid_ifInAlignError} . '.' . $options{instance}};
    $self->{interface_selected}->{$options{instance}}->{infragment} = $self->{results}->{$self->{oid_ifInFragment} . '.' . $options{instance}};
    $self->{interface_selected}->{$options{instance}}->{inoverflow} = $self->{results}->{$self->{oid_ifInOverflow} . '.' . $options{instance}};
    $self->{interface_selected}->{$options{instance}}->{inunknownop} = $self->{results}->{$self->{oid_ifInUnknownOp} . '.' . $options{instance}};
    $self->{interface_selected}->{$options{instance}}->{inlengtherror} = $self->{results}->{$self->{oid_ifInLengthError} . '.' . $options{instance}};
    $self->{interface_selected}->{$options{instance}}->{incodeerror} = $self->{results}->{$self->{oid_ifInCodeError} . '.' . $options{instance}};
    $self->{interface_selected}->{$options{instance}}->{incarriererror} = $self->{results}->{$self->{oid_ifInCarrierError} . '.' . $options{instance}};
    $self->{interface_selected}->{$options{instance}}->{injabber} = $self->{results}->{$self->{oid_ifInJabber} . '.' . $options{instance}};
    $self->{interface_selected}->{$options{instance}}->{indrop} = $self->{results}->{$self->{oid_ifInDrop} . '.' . $options{instance}};
    $self->{interface_selected}->{$options{instance}}->{outtooshort} = $self->{results}->{$self->{oid_ifOutTooShort} . '.' . $options{instance}};
    $self->{interface_selected}->{$options{instance}}->{outtoolong} = $self->{results}->{$self->{oid_ifOutTooLong} . '.' . $options{instance}};
    $self->{interface_selected}->{$options{instance}}->{outunderrun} = $self->{results}->{$self->{oid_ifOutUnderrun} . '.' . $options{instance}};
    $self->{interface_selected}->{$options{instance}}->{outcollision} = $self->{results}->{$self->{oid_ifOutCollision} . '.' . $options{instance}};
    $self->{interface_selected}->{$options{instance}}->{outexcessivecollision} = $self->{results}->{$self->{oid_ifOutExcessiveCollision} . '.' . $options{instance}};
    $self->{interface_selected}->{$options{instance}}->{outmultiplecollision} = $self->{results}->{$self->{oid_ifOutMultipleCollision} . '.' . $options{instance}};
    $self->{interface_selected}->{$options{instance}}->{outsinglecollision} = $self->{results}->{$self->{oid_ifOutSingleCollision} . '.' . $options{instance}};
    $self->{interface_selected}->{$options{instance}}->{outexcessivedeferred} = $self->{results}->{$self->{oid_ifOutExcessiveDeferred} . '.' . $options{instance}};
    $self->{interface_selected}->{$options{instance}}->{outdeferred} = $self->{results}->{$self->{oid_ifOutDeferred} . '.' . $options{instance}};
    $self->{interface_selected}->{$options{instance}}->{outlatecollision} = $self->{results}->{$self->{oid_ifOutLateCollision} . '.' . $options{instance}};
    $self->{interface_selected}->{$options{instance}}->{outtotalcollision} = $self->{results}->{$self->{oid_ifOutTotalCollision} . '.' . $options{instance}};
    $self->{interface_selected}->{$options{instance}}->{outdrop} = $self->{results}->{$self->{oid_ifOutDrop} . '.' . $options{instance}};
    $self->{interface_selected}->{$options{instance}}->{outjabber} = $self->{results}->{$self->{oid_ifOutJabber} . '.' . $options{instance}};
    $self->{interface_selected}->{$options{instance}}->{outfcserror} = $self->{results}->{$self->{oid_ifOutFCSError} . '.' . $options{instance}};
    $self->{interface_selected}->{$options{instance}}->{outfragment} = $self->{results}->{$self->{oid_ifOutFragment} . '.' . $options{instance}};
}

1;

__END__

=head1 MODE

Check interfaces.

=over 8

=item B<--add-global>

Check global port statistics (By default if no --add-* option is set).

=item B<--add-status>

Check interface status.

=item B<--add-duplex-status>

Check duplex status (with --warning-status and --critical-status).

=item B<--add-traffic>

Check interface traffic.

=item B<--add-errors>

Check interface errors.

=item B<--add-cast>

Check interface cast.

=item B<--add-speed>

Check interface speed.

=item B<--add-volume>

Check interface data volume between two checks (not supposed to be graphed, useful for BI reporting).

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{admstatus}, %{opstatus}, %{duplexstatus}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{admstatus} eq "up" and %{opstatus} ne "up"').
Can used special variables like: %{admstatus}, %{opstatus}, %{duplexstatus}, %{display}

=item B<--warning-*>

Threshold warning.
Can be: 'total-port', 'total-admin-up', 'total-admin-down', 'total-oper-up', 'total-oper-down',
'in-traffic', 'out-traffic', 'in-error', 'in-discard', 'out-error', 'out-discard',
'in-ucast' (%), 'in-bcast' (%), 'in-mcast' (%), 'out-ucast' (%), 'out-bcast' (%), 'out-mcast' (%),
'speed' (b/s).

And also: 'in-tooshort' (%), 'in-toolong' (%), 'in-fcserror' (%), 'in-alignerror' (%), 'in-fragment' (%),
'in-overflow' (%), 'in-unknownop' (%), 'in-lengtherror' (%), 'in-codeerror' (%), 'in-carriererror' (%),
'in-jabber' (%), 'in-drop' (%), 'out-tooshort' (%), 'out-toolong' (%), 'out-underrun' (%),
'out-collision' (%), 'out-excessivecollision' (%), 'out-multiplecollision' (%), 'out-singlecollision' (%),
'out-excessivedeferred' (%),'out-deferred' (%), 'out-latecollision' (%), 'out-totalcollision' (%),
'out-drop' (%), 'out-jabber' (%), 'out-fcserror' (%), 'out-fragment' (%).

=item B<--critical-*>

Threshold critical.
Can be: 'total-port', 'total-admin-up', 'total-admin-down', 'total-oper-up', 'total-oper-down',
'in-traffic', 'out-traffic', 'in-error', 'in-discard', 'out-error', 'out-discard',
'in-ucast' (%), 'in-bcast' (%), 'in-mcast' (%), 'out-ucast' (%), 'out-bcast' (%), 'out-mcast' (%),
'speed' (b/s).

And also: 'in-tooshort' (%), 'in-toolong' (%), 'in-fcserror' (%), 'in-alignerror' (%), 'in-fragment' (%),
'in-overflow' (%), 'in-unknownop' (%), 'in-lengtherror' (%), 'in-codeerror' (%), 'in-carriererror' (%),
'in-jabber' (%), 'in-drop' (%), 'out-tooshort' (%), 'out-toolong' (%), 'out-underrun' (%),
'out-collision' (%), 'out-excessivecollision' (%), 'out-multiplecollision' (%), 'out-singlecollision' (%),
'out-excessivedeferred' (%),'out-deferred' (%), 'out-latecollision' (%), 'out-totalcollision' (%),
'out-drop' (%), 'out-jabber' (%), 'out-fcserror' (%), 'out-fragment' (%).

=item B<--units-traffic>

Units of thresholds for the traffic (Default: '%') ('%', 'b/s').

=item B<--units-errors>

Units of thresholds for errors/discards (Default: '%') ('%', 'absolute').

=item B<--nagvis-perfdata>

Display traffic perfdata to be compatible with nagvis widget.

=item B<--interface>

Set the interface (number expected) ex: 1,2,... (empty means 'check all interface').

=item B<--name>

Allows to use interface name with option --interface instead of interface oid index (Can be a regexp)

=item B<--speed>

Set interface speed for incoming/outgoing traffic (in Mb).

=item B<--speed-in>

Set interface speed for incoming traffic (in Mb).

=item B<--speed-out>

Set interface speed for outgoing traffic (in Mb).

=item B<--no-skipped-counters>

Don't skip counters when no change.

=item B<--force-counters32>

Force to use 32 bits counters (even in snmp v2c and v3). Should be used when 64 bits counters are buggy.

=item B<--reload-cache-time>

Time in minutes before reloading cache file (default: 180).

=item B<--oid-filter>

Choose OID used to filter interface (default: ifName) (values: ifDesc, ifAlias, ifName, IpAddr).

=item B<--oid-display>

Choose OID used to display interface (default: ifName) (values: ifDesc, ifAlias, ifName, IpAddr).

=item B<--oid-extra-display>

Add an OID to display.

=item B<--display-transform-src>

Regexp src to transform display value.

=item B<--display-transform-dst>

Regexp dst to transform display value.

=item B<--show-cache>

Display cache interface datas.

=back

=cut
