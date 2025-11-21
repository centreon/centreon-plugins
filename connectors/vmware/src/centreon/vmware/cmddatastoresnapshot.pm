# Copyright 2024 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets 
# the needs in IT infrastructure and application monitoring for 
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0  
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

package centreon::vmware::cmddatastoresnapshot;

use base qw(centreon::vmware::cmdbase);

use strict;
use warnings;
use centreon::vmware::common;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(%options);
    bless $self, $class;
    
    $self->{commandName} = 'datastoresnapshot';
    
    return $self;
}

sub checkArgs {
    my ($self, %options) = @_;

    if (defined($options{arguments}->{datastore_name}) && $options{arguments}->{datastore_name} eq "") {
        centreon::vmware::common::set_response(code => 100, short_message => "Argument error: datastore name cannot be null");
        return 1;
    }
    return 0;
}

sub run {
    my $self = shift;

    my $filters = $self->build_filter(label => 'name', search_option => 'datastore_name', is_regexp => 'filter');
    my @properties = ('summary.accessible', 'summary.name', 'browser');
    my $result = centreon::vmware::common::search_entities(command => $self, view_type => 'Datastore', properties => \@properties, filter => $filters);
    return if (!defined($result));
    
    my @ds_array = ();
    my %ds_names = ();
    my $data = {};
    foreach my $entity_view (@$result) {
        my $entity_value = $entity_view->{mo_ref}->{value};
        $data->{$entity_value} = {
            name => $entity_view->{'summary.name'},
            accessible => $entity_view->{'summary.accessible'},
            error_message => '',
            snapshost => [],
        };
        next if (centreon::vmware::common::is_accessible(accessible => $entity_view->{'summary.accessible'}) == 0);
        if (defined($entity_view->browser)) {
            push @ds_array, $entity_view->browser;
            $ds_names{$entity_view->{mo_ref}->{value}} = $entity_view->{'summary.name'};
        }
    }
    
    @properties = ();
    my $result2;
    return if (!($result2 = centreon::vmware::common::get_views($self->{connector}, \@ds_array, \@properties)));

    foreach my $browse_ds (@$result2) {
        my $dsName; 
        my $tmp_name = $browse_ds->{mo_ref}->{value};
        $tmp_name =~ s/^datastoreBrowser-//i;
        $dsName = $ds_names{$tmp_name};

        my ($snapshots, $msg) = centreon::vmware::common::search_in_datastore(
            connector => $self->{connector}, 
            browse_ds => $browse_ds, 
            ds_name => '[' . $dsName . ']',
            matchPattern => [ "*.vmsn", "*.vmsd", "*-000*.vmdk", "*-000*delta.vmdk" ],
            searchCaseInsensitive => 1,
            query => [ FileQuery->new()], 
            return => 1
        );
        if (!defined($snapshots)) {
            $msg =~ s/\n/ /g;
            if ($msg =~ /NoPermissionFault/i) {
                $msg = "Not enough permissions";
            }
            
            $data->{$tmp_name}->{error_message} = $msg;
            next;
        }

        foreach (@$snapshots) {
            if (defined($_->file)) {
                foreach my $x (@{$_->file}) {
                    push @{$data->{$tmp_name}->{snapshost}}, { folder_path => $_->folderPath, path => $x->path, size => $x->fileSize };
                }
            }
        }
    }
    
    centreon::vmware::common::set_response(data => $data);
}

1;
