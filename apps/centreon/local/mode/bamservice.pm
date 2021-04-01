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

package apps::centreon::local::mode::bamservice;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::dbi;

use vars qw($centreon_config);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'centreon-config:s' => { name => 'centreon_config', default => '/etc/centreon/centreon-config.pm' },
        'bam-id:s'          => { name => 'bam_id', },
    });
    $self->{options} = $options{options};
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{bam_id}) || $self->{option_results}->{bam_id} !~ /^[0-9]+$/) {
        $self->{output}->add_option_msg(short_msg => "Need to specify bam-id (numeric value) option.");
        $self->{output}->option_exit();
    }
    require $self->{option_results}->{centreon_config};
}

sub run {
    my ($self, %options) = @_;

    my $sql = centreon::plugins::dbi->new(options => $self->{options}, output => $self->{output}, nooptions => 1);
    $sql->{data_source} = 'mysql:host=' . $centreon_config->{db_host} . 'port=' . $centreon_config->{db_port};
    $sql->{username} = $centreon_config->{db_user};
    $sql->{password} = $centreon_config->{db_passwd};
    $sql->connect();

    $sql->query(query => "SELECT `name`,`current_level`,`level_w`,`level_c` FROM " . $centreon_config->{centreon_db} . 
         ".`mod_bam` WHERE `ba_id` = '" . $self->{option_results}->{bam_id} . "'"
    );
    my ($name, $current_level, $level_w, $level_c) = $self->{sql}->fetchrow_array();
    if (!defined($current_level)) {
        $self->{output}->add_option_msg(short_msg => "Cannot get bam information");
        $self->{output}->option_exit();
    }

    $self->{perfdata}->threshold_validate(label => 'warning', value => $level_w . ':');
    $self->{perfdata}->threshold_validate(label => 'critical', value => $level_c . ':');

    my $exit = $self->{perfdata}->threshold_check(value => $current_level, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    $self->{output}->output_add(
        severity => $exit,
        short_msg => sprintf('BA : %s - current_level = %s%%', $name, $current_level)
    );
    $self->{output}->perfdata_add(
        label => 'BA_Level',
        unit => '%',
        value => $current_level,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
        min => 0, max => 100,
    );   
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Do Centreon bam-service checks.

=over 8

=item B<--centreon-config>

Centreon Database Config File (Default: '/etc/centreon/centreon-config.pm').

=item B<--bam-id>

Bam-id to check (required).

=back

=cut
