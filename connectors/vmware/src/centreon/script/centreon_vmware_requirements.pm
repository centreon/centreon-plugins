# Copyright 2025 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and application monitoring for
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

package centreon::script::centreon_vmware_requirements;

use strict;
use warnings;
use centreon::vmware::script;
use Getopt::Long;
use base qw(centreon::vmware::script);

# This package is only used to check if the VMware Perl SDK is installed
# If the SDK is not present a detailed error message is logged in the Centreon log file

sub new {
    my ($class) = @_;
    my $self = $class->SUPER::new('centreon_vmware_requirements');

    # "required" contain modules to check VMware::VIRuntime and VMware::VILib
    $self->{required} = [ 'VMware::VIRuntime', 'VMware::VILib' ];

    bless $self, $class;

    return $self;
}

sub parse_options {
    my $self = shift;

    # Here we only use --logfile parameter to log the error message if the VMware Perl SDK is not installed
    # We use pass_throuth because we dont want this module to raise an error if an unrecognized option is passed
    Getopt::Long::Configure('pass_through');
    GetOptions(%{$self->{options}});
}

sub run {
    my $self = shift;

    foreach (@{$self->{required}}) {
        eval "use $_;";
        if ($@) {
            my $msg = "$@\n\n***************\n".
                    "To make the Centreon VMware VM Monitoring Connector work, you will need the Perl VMware SDK.\n".
                    "Please refer to the documentation at https://docs.centreon.com/pp/integrations/plugin-packs/procedures/virtualization-vmware2-vm/#vmware-perl-sdk for the procedure.\n".
                    "***************\n";
            $self->SUPER::run();

            $self->{logger}->writeLogFatal($msg);
        }
    }
    return 1;
}

1;

__END__
