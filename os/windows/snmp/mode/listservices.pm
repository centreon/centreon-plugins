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

package os::windows::snmp::mode::listservices;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

my $map_installed_state = {
    1 => 'uninstalled', 
    2 => 'install-pending', 
    3 => 'uninstall-pending', 
    4 => 'installed'
};
my $map_operating_state = {
    1 => 'active',
    2 => 'continue-pending',
    3 => 'pause-pending',
    4 => 'paused'
};

my $mapping = {
    svSvcInstalledState => { oid => '.1.3.6.1.4.1.77.1.2.3.1.2', map => $map_installed_state },
    svSvcOperatingState => { oid => '.1.3.6.1.4.1.77.1.2.3.1.3', map => $map_operating_state },
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_svSvcEntry = '.1.3.6.1.4.1.77.1.2.3.1';
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_svSvcEntry,
        start => $mapping->{svSvcInstalledState}->{oid},
        end => $mapping->{svSvcOperatingState}->{oid},
        nothing_quit => 1
    );
    my $results = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{svSvcOperatingState}->{oid}\.(.*?)\.(.*)$/);
        my $instance = $1 . '.' . $2;
        my $svc_name = $self->{output}->decode(join('', map(chr($_), split(/\./, $2))));
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $svc_name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $svc_name . "': no matching filter.", debug => 1);
            next;
        }

        $results->{$svc_name} = { 
            name => $svc_name,
            %$result
        };
    }

    return $results;
}

sub run {
    my ($self, %options) = @_;
  
    my $results = $self->manage_selection(%options);
    foreach (sort keys %$results) {
        $self->{output}->output_add(long_msg => '[name = ' . $results->{$_}->{name} .
            "] [operating = " . $results->{$_}->{svSvcOperatingState} .
            "] [installed = " . $results->{$_}->{svSvcInstalledState} . "]"
        );
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List services:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'installed', 'operating']);
}

sub disco_show {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(%options);
    foreach (sort keys %$results) {
        $self->{output}->add_disco_entry(
            name => $results->{$_}->{name},
            operating => $results->{$_}->{svSvcOperatingState},
            installed => $results->{$_}->{svSvcInstalledState},
        );
    }
}

1;

__END__

=head1 MODE

List windows services.

=over 8

=item B<--filter-name>

Filter by service name (can be a regexp).

=back

=cut
    
