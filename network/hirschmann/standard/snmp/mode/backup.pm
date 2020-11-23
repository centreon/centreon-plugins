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
# Authors : LLFT <<loic.laffont@gmail.com>>
# Check the backup status 
# OID hm2FMNvmState under Software HiOS : .1.3.6.1.4.1.248.11.21.1.3.1.0
# OID hmConfigurationStatus under Software L2P : .1.3.6.1.4.1.248.14.2.4.12.0

package network::hirschmann::standard::snmp::mode::backup;

use strict;
use warnings;
use base qw(centreon::plugins::mode);


sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });
    $self->{version} = '1.0';

    return $self;
}

sub check_options {

}


sub run {

my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    my $oid_hmConfigurationStatus  = '.1.3.6.1.4.1.248.14.2.4.12.0'; # integer

    my $result = $self->{snmp}->get_leef(oids => [$oid_hmConfigurationStatus],
                                         nothing_quit => 1);
    
    my $iBackupStatus = $result->{$oid_hmConfigurationStatus};
    
    if ($iBackupStatus == 1 ){
      $self->{output}->output_add(severity  => 'OK',
                              short_msg => 'This Switch is saved');
    } else {
      $self->{output}->output_add(severity  => 'Critical',
                              short_msg => 'This Switch is not saved');
    }
    $self->{output}->perfdata_add(label    => 'backup_status',
                                value    => $iBackupStatus,
                                unit     => '',
                                warning  => '0',
                                critical => '2',
                                min      => 0,
                                max      => 3);

    $self->{output}->display();
    $self->{output}->exit();

}

1;
__END__

  =head1 PLUGIN DESCRIPTION

  <Add a plugin description here>.

  =cut
