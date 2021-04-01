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

package network::beeware::snmp::mode::listreverseproxy;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %mapping_running = (
    0 => 'down',
    1 => 'running',
);

my $oid_rp = '.1.3.6.1.4.1.30800.132';
my $oid_running_suffix = '133.57'; # 1 seems running

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                  "filter-status:s"         => { name => 'filter_status' },
                                });
    $self->{rp} = {};

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(oid => $oid_rp,
                                                nothing_quit => 1);
                                                
    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$oid_rp\.(.*?)\.$oid_running_suffix$/ || defined($self->{rp}->{$1}));
        my $instance = $1;
        
        my $status = defined($mapping_running{$snmp_result->{$oid_rp . '.' . $instance . '.' . $oid_running_suffix}}) ? 
                              $mapping_running{$snmp_result->{$oid_rp . '.' . $instance . '.' . $oid_running_suffix}} : 'unknown';
        if (defined($self->{option_results}->{filter_status}) && $self->{option_results}->{filter_status} ne '' &&
            $status !~ /$self->{option_results}->{filter_status}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $instance . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{rp}->{$instance} = { status => $status };
    }
}

sub run {
    my ($self, %options) = @_;
  
    $self->manage_selection(%options);
    foreach my $instance (sort keys %{$self->{rp}}) { 
        $self->{output}->output_add(long_msg => '[instance = ' . $instance . "] [status = '" . $self->{rp}->{$instance}->{status} . "']");
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List reverse proxies:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['instance', 'status']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $instance (sort keys %{$self->{rp}}) {             
        $self->{output}->add_disco_entry(instance => $instance, status => $self->{rp}->{$instance}->{status});
    }
}

1;

__END__

=head1 MODE

List reverse proxies.

=over 8

=item B<--filter-status>

Filter which status (can be a regexp).

=back

=cut
    