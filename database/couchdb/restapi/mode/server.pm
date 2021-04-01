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

package database::couchdb::restapi::mode::server;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);
use JSON::XS;

sub custom_server_output {
    my ($self, %options) = @_;

    my $msg = 'server status is ' . $self->{result_values}->{status};
    return $msg;
}

sub custom_compaction_output {
    my ($self, %options) = @_;

    my $msg = "compaction status is '" . $self->{result_values}->{compaction_status} . "'";
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'database', type => 1, cb_prefix_output => 'prefix_db_output', message_multiple => 'All databases are ok', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_server_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];

    $self->{maps_counters}->{database} = [
        { label => 'compaction-status', threshold => 0, set => {
                key_values => [ { name => 'compaction_status' }, { name => 'display' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_compaction_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'database-size-active', nlabel => 'server.database.size.active.bytes', set => {
                key_values => [ { name => 'sizes_active' }, { name => 'display' } ],
                output_template => 'live data size: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { value => 'sizes_active', template => '%d', min => 0,
                      unit => 'B', label_extra_instance => 1, instance_use => 'display' }
                ],
            }
        },
        { label => 'database-size-file', nlabel => 'server.database.size.file.bytes', set => {
                key_values => [ { name => 'sizes_file' }, { name => 'display' } ],
                output_template => 'file size: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { value => 'sizes_file', template => '%d', min => 0,
                      unit => 'B', label_extra_instance => 1, instance_use => 'display' }
                ],
            }
        },
        { label => 'database-documents-current', nlabel => 'server.database.documents.currrent.count', display_ok => 0, set => {
                key_values => [ { name => 'doc_count' }, { name => 'display' } ],
                output_template => 'number of documents: %s',
                perfdatas => [
                    { value => 'doc_count', template => '%d', min => 0,
                      label_extra_instance => 1, instance_use => 'display' }
                ],
            }
        },
        { label => 'database-documents-deleted', nlabel => 'server.database.documents.deleted.count', display_ok => 0, set => {
                key_values => [ { name => 'doc_del_count' }, { name => 'display' } ],
                output_template => 'number of deleted documents: %s',
                perfdatas => [
                    { value => 'doc_del_count', template => '%d', min => 0,
                      label_extra_instance => 1, instance_use => 'display' }
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'filter-db-name:s'             => { name => 'filter_db_name' },
        'unknown-status:s'             => { name => 'unknown_status', default => '' },
        'warning-status:s'             => { name => 'warning_status', default => '' },
        'critical-status:s'            => { name => 'critical_status', default => '%{status} !~ /^ok/i' },
        'unknown-compaction-status:s'  => { name => 'unknown_compaction_status', default => '' },
        'warning-compaction-status:s'  => { name => 'warning_compaction_status', default => '' },
        'critical-compaction-status:s' => { name => 'critical_compaction_status', default => '' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => [
        'warning_status', 'critical_status', 'unknown_status',
        'warning_compaction_status', 'critical_compaction_status', 'unknown_compaction_status'
    ]);
}

sub prefix_db_output {
    my ($self, %options) = @_;
    
    return "Database '" . $options{instance_value}->{display} . "' ";
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->request_api(url_path => '/_up');
    $self->{global} = { status => $results->{status} };

    $results = $options{custom}->request_api(url_path => '/_all_dbs');
    my $db = {
        keys => $results
    };
    my $encoded;
    eval {
        $encoded = JSON::XS->new->utf8->encode($db);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot encode json request");
        $self->{output}->option_exit();
    }

    $results = $options{custom}->request_api(
        method => 'POST',
        url_path => '/_dbs_info',
        query_form_post => $encoded
    );

    $self->{database} = {};
    foreach (@$results) {
        if (defined($self->{option_results}->{filter_db_name}) && $self->{option_results}->{filter_db_name} ne '' &&
            $_->{info}->{db_name} !~ /$self->{option_results}->{filter_db_name}/) {
            $self->{output}->output_add(long_msg => "skipping database '" . $_->{info}->{db_name} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{database}->{$_->{info}->{db_name}} = {
            display => $_->{info}->{db_name},
            compaction_status => $_->{info}->{compact_running} ? 'running' : 'notRunning',
            doc_count => $_->{info}->{doc_count},
            doc_del_count => $_->{info}->{doc_del_count},
            sizes_active => $_->{info}->{sizes}->{active},
            sizes_file => $_->{info}->{sizes}->{file}
        };
    }
}

1;

__END__

=head1 MODE

Check server status and database stastistics.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^status$'

=item B<--filter-db-name>

Filter database name (can be a regexp).

=item B<--unknown-status>

Set unknown threshold for status (Default: '').
Can used special variables like: %{status}

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{status}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} !~ /^ok/i').
Can used special variables like: %{status}

=item B<--unknown-compaction-status>

Set unknown threshold for status (Default: '').
Can used special variables like: %{compaction_status}, %{display}

=item B<--warning-compaction-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{compaction_status}, %{display}

=item B<--critical-compaction-status>

Set critical threshold for status (Default: '').
Can used special variables like: %{compaction_status}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'database-size-active' (B), 'database-size-file' (B), 
'database-documents-deleted', 'database-documents-current'.

=back

=cut
