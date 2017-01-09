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

package database::postgres::mode::tablespace;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "warning:s"               => { name => 'warning', default => ''},
                                  "critical:s"              => { name => 'critical', default => ''},
                                  "tablespace:s"            => { name => 'tablespace', }, # tablespace name to check
                                });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
       $self->{output}->option_exit();
    }
    
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
       $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{sql} = $options{sql};

    $self->{sql}->connect();
    
    my $target_fields = undef;

    # Query to get tablespace size
    my $query = sprintf("SELECT pg_tablespace_size('%s') FROM pg_tablespace LIMIT 1;",$self->{option_results}->{tablespace});
    $self->{sql}->query(query => $query);

    my $result = $self->{sql}->fetchrow_array();
    
    if (defined($result)) {
        my $exit_code = $self->{perfdata}->threshold_check(value => $result, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
        my ($value, $value_unit) = $self->{perfdata}->change_bytes(value => $result);
        $self->{output}->output_add(severity => $exit_code,
                                    short_msg => sprintf('Tablespace "%s" size is %s %s',$self->{option_results}->{tablespace}, $value, $value_unit));
        
        $self->{output}->perfdata_add(label => $self->{option_results}->{tablespace}, unit => 'B',
                                      value => $result,
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                      min => 0);
    } else {
        $self->{output}->output_add(severity => 'UNKNOWN',
                                    short_msg => sprintf('Table space "%s" is unknown ...', $self->{option_results}->{tablespace}));
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check a tablespace size

=over 8

=item B<--warning>

Threshold warning in bytes, maximum size allowed.

=item B<--critical>

Threshold critical in bytes, maximum size allowed.

=item B<--tablespace>

The of the tablespace to check.

=back

=cut
