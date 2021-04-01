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

package apps::centreon::map4::jmx::mode::eventstatistics;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);

my %mapping_eventtype = (
    'EventCount'      => 'global',
    'EventTypeCreate' => 'create',
    'EventTypeRemove' => 'remove',
    'EventTypeUpdate' => 'update',
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                  "warning-global:s"      => { name => 'warning_global', },
                                  "critical-global:s"     => { name => 'critical_global', },
                                  "warning-create:s"      => { name => 'warning_create', },
                                  "critical-create:s"     => { name => 'critical_create', },
                                  "warning-update:s"      => { name => 'warning_update', },
                                  "critical-update:s"     => { name => 'critical_update', },
                                  "warning-remove:s"      => { name => 'warning_remove', },
                                  "critical-remove:s"     => { name => 'critical_remove', },
                                });

    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    foreach my $label ('warning_global', 'critical_global', 'warning_create', 'critical_create', 'warning_update', 'critical_update', 'warning_remove', 'critical_remove') {
        if (($self->{perfdata}->threshold_validate(label => $label, value => $self->{option_results}->{$label})) == 0) {
            my ($label_opt) = $label;
            $label_opt =~ tr/_/-/;
            $self->{output}->add_option_msg(short_msg => "Wrong " . $label_opt . " threshold '" . $self->{option_results}->{$label} . "'.");
            $self->{output}->option_exit();
        }
    }

    $self->{statefile_cache}->check_options(%options);

}

sub run {
    my ($self, %options) = @_;
    $self->{connector} = $options{custom};

    $self->{request} = [
         { mbean => "com.centreon.studio.map:name=statistics,type=whatsup" }
    ];

    my $result = $self->{connector}->get_attributes(request => $self->{request}, nothing_quit => 0);

    my $new_datas = {};
    $self->{statefile_cache}->read(statefile => 'centreon_map_' . $self->{mode} . '-' . md5_hex($self->{connector}->{url}));
    my $old_timestamp = $self->{statefile_cache}->get(name => 'last_timestamp');
    $new_datas->{last_timestamp} = time();

    if (defined($old_timestamp) && $new_datas->{last_timestamp} - $old_timestamp == 0) {
        $self->{output}->add_option_msg(short_msg => "Need at least one second between two checks.");
        $self->{output}->option_exit();
    }

    foreach my $type ('EventCount', 'EventTypeCreate', 'EventTypeUpdate', 'EventTypeRemove') {
        $new_datas->{$type} =  $result->{"com.centreon.studio.map:name=statistics,type=whatsup"}->{$type}->{andIncrement};
        my $old_val = $self->{statefile_cache}->get(name => $type);
        next if (!defined($old_val) || $result->{"com.centreon.studio.map:name=statistics,type=whatsup"}->{$type}->{andIncrement} < $old_val);
        my $value = int(($result->{"com.centreon.studio.map:name=statistics,type=whatsup"}->{$type}->{andIncrement} - $old_val) / ($new_datas->{last_timestamp} - $old_timestamp));     

        $self->{output}->perfdata_add(label => $type,
                                      value => $value,
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning_' . $mapping_eventtype{$type}), 
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical_' . $mapping_eventtype{$type}),
                                      min => 0);

        my $exit = $self->{perfdata}->threshold_check(value => $value,
                                                      threshold => [ { label => 'critical_' . $mapping_eventtype{$type}, exit_litteral => 'critical' },
                                                                     { label => 'warning_' . $mapping_eventtype{$type}, exit_litteral => 'warning' }  ]);

        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("%s = %d", $type, $value));
        }

        $self->{output}->output_add(severity => 'ok',
                                    short_msg => sprintf("%s = %s", $type, $value));

    }

    $self->{statefile_cache}->write(data => $new_datas);

    if (!defined($old_timestamp)) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => "Buffer creation...");
    }

    $self->{output}->display();
    $self->{output}->exit();

}

1;

__END__

=head1 MODE

Check Centreon Map Event Statistics

Example:

perl centreon_plugins.pl --plugin=apps::centreon::jmx::map::plugin --custommode=jolokia --url=http://10.30.2.22:8080/jolokia-war --mode=event-statistics

=over 8

=item B<--warning-global>

Warning threshold for global event count

=item B<--critical-global>

Critical threshold for global event count

=item B<--warning-create>

Warning threshold for create event count

=item B<--critical-create>

Critical threshold for create event count

=item B<--warning-update>

Warning threshold for update event count

=item B<--critical-update>

Critical threshold for update event count

=item B<--warning-remove>

Warning threshold for remove event count

=item B<--critical-remove>

Critical threshold for remove event count

=back

=cut

