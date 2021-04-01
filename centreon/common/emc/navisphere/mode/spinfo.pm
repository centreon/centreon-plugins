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

package centreon::common::emc::navisphere::mode::spinfo;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;
    my $clariion = $options{custom};
    
    my $response = $clariion->execute_command(cmd => 'getagent -ver -rev -prom -model -type -mem -serial -spid');
    
    my $sp_id = 'unknown';
    my $sp_agent_rev = 'unknown';
    my $sp_flare_rev = 'unknown';
    my $sp_prom_rev = 'unknown';
    my $sp_model = 'unknown';
    my $sp_model_type = 'unknown';
    my $sp_memory_total = 'unknown';
    my $sp_serial_number = 'unknown';

    $sp_id = $1 if ($response =~ /^SP Identifier:\s+(.*)$/im);
    $sp_agent_rev = $1 if ($response =~ /^Agent Rev:\s+(.*)$/im);
    $sp_flare_rev = $1 if ($response =~ /^Revision:\s+(.*)$/im);
    $sp_prom_rev = $1 if ($response =~ /^Prom Rev:\s+(.*)$/im);
    $sp_model = $1 if ($response =~ /^Model:\s+(.*)$/im);
    $sp_model_type = $1 if ($response =~ /^Model Type:\s+(.*)$/im);
    $sp_memory_total = ($1 * 1024 * 1024) if ($response =~ /^SP Memory:\s+(.*)$/im);
    $sp_serial_number = $1 if ($response =~ /^Serial No:\s+(.*)$/im);
    
    my ($memory_value, $memory_unit) = $self->{perfdata}->change_bytes(value => $sp_memory_total);
    
    $self->{output}->output_add(severity => 'ok',
                                short_msg => sprintf('[SP ID: %s] [Agent Revision: %s] [FLARE Revision: %s] [PROM Revision: %s] [Model: %s, %s] [Memory: %s %s] [Serial Number: %s]',
                                                    $sp_id, $sp_agent_rev, $sp_flare_rev, $sp_prom_rev, 
                                                    $sp_model, $sp_model_type, $memory_value, $memory_unit, $sp_serial_number));
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Display informations on the storage processor.

=over 8

=back

=cut
