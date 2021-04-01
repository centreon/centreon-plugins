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

package blockchain::parity::restapi::mode::infos;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'unknown-status:s'  => { name => 'unknown_status', default => '' },
        'warning-status:s'  => { name => 'warning_status', default => '' },
        'critical-status:s' => { name => 'critical_status', default => '%{listening} !~ /true/' },
    });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['unknown_status', 'warning_status', 'critical_status']);
}

sub prefix_module_output {
    my ($self, %options) = @_;
    
    return "Parity network module: ";
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = "parity_restapi_" . $self->{mode} . '_' . (defined($self->{option_results}->{hostname}) ? $self->{option_results}->{hostname} : 'me') . '_' .
           (defined($self->{option_results}->{port}) ? $self->{option_results}->{port} : 'default') . '_' .
           (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));

    my $query_form_post = [ { method => 'parity_versionInfo', params => [], id => "1", jsonrpc => "2.0" },
                            { method => 'parity_chain', params => [], id => "2", jsonrpc => "2.0" },
                            { method => 'eth_mining', params => [], id => "3", jsonrpc => "2.0" },
                            { method => 'parity_nodeName', params => [], id => "4", jsonrpc => "2.0" }, ];

    my $result = $options{custom}->request_api(method => 'POST', query_form_post => $query_form_post);

    my $res_parity_version = @{$result}[0]->{result}->{version}->{major} . '.' . @{$result}[0]->{result}->{version}->{minor} .  '.' . @{$result}[0]->{result}->{version}->{patch};

    $self->{output}->output_add(short_msg =>  "Parity version: '" . $res_parity_version . "'. Chain name: '" . @{$result}[1]->{result} . 
                                            "'. Node name: '" . @{$result}[3]->{result} . "'. is_validator: '" . @{$result}[2]->{result} . "'.", severity => 'OK');
}

1;

__END__

=head1 MODE

Check parity network cross module metrics  (Parity version, chain name and node name and type)
