#
# Copyright 2022 Centreon (http://www.centreon.com/)
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

package hardware::pdu::gude::epc::snmp::mode::resources;

use strict;
use warnings;
use Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(find_gude_version);

my $regexp_gude_branch = {
    '1104' => '.1.3.6.1.4.1.28507.68',
    '1105' => '.1.3.6.1.4.1.28507.69',
    '1202' => '.1.3.6.1.4.1.28507.43',
    '8021' => '.1.3.6.1.4.1.28507.77',
    '8025' => '.1.3.6.1.4.1.28507.79',
    '8031' => '.1.3.6.1.4.1.28507.81',
    '8035' => '.1.3.6.1.4.1.28507.83',
    '8041' => '.1.3.6.1.4.1.28507.85',
    '8045' => '.1.3.6.1.4.1.28507.87',
    '8101' => '.1.3.6.1.4.1.28507.89',
    '8221' => '.1.3.6.1.4.1.28507.56',
    '8226' => '.1.3.6.1.4.1.28507.58',
    '8316' => '.1.3.6.1.4.1.28507.64'
};

sub find_gude_branch {
    my ($self, %options) = @_;

    my $oid_sysDescr = '.1.3.6.1.2.1.1.1.0';
    my $snmp_result = $options{snmp}->get_leef(
        oids => [ $oid_sysDescr ],
        nothing_quit => 1
    );
    my $branch;
    foreach my $re (keys %$regexp_gude_branch) {
        if ($snmp_result->{$oid_sysDescr} =~ /$re/) {
            $branch = $regexp_gude_branch->{$re};
            last;
        }
    }
    if (!defined($branch)) {
        $self->{output}->add_option_msg(short_msg => 'unsupported device: ' . $snmp_result->{$oid_sysDescr});
        $self->{output}->option_exit();
    }

    return $branch;
}

1;

__END__
