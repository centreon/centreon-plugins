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

    my $msg = sprintf("Licenses Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
        $self->{result_values}->{total},
        $self->{result_values}->{used},
        $self->{result_values}->{prct_used},
        $self->{result_values}->{free},
        $self->{result_values}->{prct_free}
    );
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'usage', nlabel => 'licenses.usage.count', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_license_output'),
                perfdatas => [
                    { value => 'used', template => '%d', min => 0, max => 'total' },
                ],
            }
        },
        { label => 'usage-free', display_ok => 0, nlabel => 'licenses.free.count', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_license_output'),
                perfdatas => [
                    { value => 'free', template => '%d', min => 0, max => 'total' },
                ],
            }
        },
        { label => 'usage-prct', display_ok => 0, nlabel => 'licenses.usage.percentage', set => {
                key_values => [ { name => 'prct_used' } ],
                output_template => 'Licenses Used : %.2f %%',
                perfdatas => [
                    { value => 'prct_used', template => '%.2f', min => 0, max => 100, unit => '%' },
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

    $self->{global} = { total => 0, used => 0 };
    my $query = "Select InUseCount,Count from Citrix_GT_License_Pool";
    my $resultset = $wmi->ExecQuery($query);
    foreach my $obj (in $resultset) {
        $self->{global}->{used} += $obj->{InUseCount};
        $self->{global}->{total} += $obj->{Count};
    }

    if ($self->{global}->{total} == 0) {
        $self->{output}->add_option_msg(short_msg => 'Cant get licenses count');
        $self->{output}->option_exit();
    }

    $self->{global}->{prct_used} = $self->{global}->{used} * 100 / $self->{global}->{total};
    $self->{global}->{prct_free} = 100 - $self->{global}->{prct_used};
    $self->{global}->{free} = $self->{global}->{total} - $self->{global}->{used};
}

1;

__END__

=head1 MODE

Check Citrix licenses.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'usage' (B), 'usage-free' (B), 'usage-prct' (%).

=back

=cut
