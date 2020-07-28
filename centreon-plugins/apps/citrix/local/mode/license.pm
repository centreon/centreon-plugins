#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package apps::citrix::local::mode::license;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Win32::OLE;

sub custom_license_output {
    my ($self, %options) = @_;

    my $msg = sprintf("Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
        $self->{result_values}->{total},
        $self->{result_values}->{used},
        $self->{result_values}->{prct_used},
        $self->{result_values}->{free},
        $self->{result_values}->{prct_free}
    );
    return $msg;
}

sub prefix_license_output {
    my ($self, %options) = @_;

    return "License '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'license', type => 1, cb_prefix_output => 'prefix_license_output', message_multiple => 'All licenses are ok', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{license} = [
        { label => 'usage', nlabel => 'licenses.usage.count', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_license_output'),
                perfdatas => [
                    { value => 'used', template => '%d', min => 0, max => 'total', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'usage-free', display_ok => 0, nlabel => 'licenses.free.count', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_license_output'),
                perfdatas => [
                    { value => 'free', template => '%d', min => 0, max => 'total', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'usage-prct', display_ok => 0, nlabel => 'licenses.usage.percentage', set => {
                key_values => [ { name => 'prct_used' }, { name => 'used' }, { name => 'free' }, { name => 'prct_free' }, { name => 'total' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_license_output'),
                perfdatas => [
                    { value => 'prct_used', template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter:s' => { name => 'filter' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $wmi = Win32::OLE->GetObject('winmgmts:root\CitrixLicensing');
    if (!defined($wmi)) {
        $self->{output}->add_option_msg(short_msg => 'Cant create server object:' . Win32::OLE->LastError());
        $self->{output}->option_exit();
    }

    my $query = "Select PLD,InUseCount,Count from Citrix_GT_License_Pool";
    my $resultset = $wmi->ExecQuery($query);
    foreach my $obj (in $resultset) {
        if (!defined($self->{option_results}->{filter}) || ($obj->{PLD} =~ /$self->{option_results}->{filter}/i)) {
            $self->{license}->{$obj->{PLD}}->{display} = $obj->{PLD};
            $self->{license}->{$obj->{PLD}}->{used} = $obj->{InUseCount};
            $self->{license}->{$obj->{PLD}}->{total} = $obj->{Count};
            $self->{license}->{$obj->{PLD}}->{prct_used} = $obj->{InUseCount} * 100 / $obj->{Count};
            $self->{license}->{$obj->{PLD}}->{prct_free} = 100 - $self->{license}->{$obj->{PLD}}->{prct_used};
            $self->{license}->{$obj->{PLD}}->{free} = $obj->{Count} - $obj->{InUseCount};
        }
    }

    if (!scalar keys %{$self->{license}}) {
        $self->{output}->add_option_msg(short_msg => 'Cant get licenses count');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check Citrix licenses.

=over 8

=item B<--filter>

Filter license name.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'usage' (B), 'usage-free' (B), 'usage-prct' (%).

=back

=cut
