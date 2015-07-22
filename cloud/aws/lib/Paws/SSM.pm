package Paws::SSM {
  use Moose;
  sub service { 'ssm' }
  sub version { '2014-11-06' }
  sub target_prefix { 'AmazonSSM' }
  sub json_version { "1.1" }

  with 'Paws::API::Caller', 'Paws::API::EndpointResolver', 'Paws::Net::V4Signature', 'Paws::Net::JsonCaller', 'Paws::Net::JsonResponse';

  
  sub CreateAssociation {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::SSM::CreateAssociation', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateAssociationBatch {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::SSM::CreateAssociationBatch', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateDocument {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::SSM::CreateDocument', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteAssociation {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::SSM::DeleteAssociation', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteDocument {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::SSM::DeleteDocument', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeAssociation {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::SSM::DescribeAssociation', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeDocument {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::SSM::DescribeDocument', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetDocument {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::SSM::GetDocument', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListAssociations {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::SSM::ListAssociations', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListDocuments {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::SSM::ListDocuments', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdateAssociationStatus {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::SSM::UpdateAssociationStatus', @_);
    return $self->caller->do_call($self, $call_object);
  }
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SSM - Perl Interface to AWS Amazon Simple Systems Management Service

=head1 SYNOPSIS

  use Paws;

  my $obj = Paws->service('SSM')->new;
  my $res = $obj->Method(
    Arg1 => $val1,
    Arg2 => [ 'V1', 'V2' ],
    # if Arg3 is an object, the HashRef will be used as arguments to the constructor
    # of the arguments type
    Arg3 => { Att1 => 'Val1' },
    # if Arg4 is an array of objects, the HashRefs will be passed as arguments to
    # the constructor of the arguments type
    Arg4 => [ { Att1 => 'Val1'  }, { Att1 => 'Val2' } ],
  );

=head1 DESCRIPTION



Amazon EC2 Simple Systems Manager (SSM) enables you to configure and
manage your EC2 instances. You can create a configuration document and
then associate it with one or more running instances.

You can use a configuration document to automate the following tasks
for your Windows instances:

=over

=item *

Join an AWS Directory

=item *

Install, repair, or uninstall software using an MSI package

=item *

Run PowerShell scripts

=item *

Configure CloudWatch Logs to monitor applications and systems

=back

Note that configuration documents are not supported on Linux instances.










=head1 METHODS

=head2 CreateAssociation(InstanceId => Str, Name => Str)

Each argument is described in detail in: L<Paws::SSM::CreateAssociation>

Returns: a L<Paws::SSM::CreateAssociationResult> instance

  

Associates the specified configuration document with the specified
instance.

When you associate a configuration document with an instance, the
configuration agent on the instance processes the configuration
document and configures the instance as specified.

If you associate a configuration document with an instance that already
has an associated configuration document, we replace the current
configuration document with the new configuration document.











=head2 CreateAssociationBatch(Entries => ArrayRef[Paws::SSM::CreateAssociationBatchRequestEntry])

Each argument is described in detail in: L<Paws::SSM::CreateAssociationBatch>

Returns: a L<Paws::SSM::CreateAssociationBatchResult> instance

  

Associates the specified configuration documents with the specified
instances.

When you associate a configuration document with an instance, the
configuration agent on the instance processes the configuration
document and configures the instance as specified.

If you associate a configuration document with an instance that already
has an associated configuration document, we replace the current
configuration document with the new configuration document.











=head2 CreateDocument(Content => Str, Name => Str)

Each argument is described in detail in: L<Paws::SSM::CreateDocument>

Returns: a L<Paws::SSM::CreateDocumentResult> instance

  

Creates a configuration document.

After you create a configuration document, you can use
CreateAssociation to associate it with one or more running instances.











=head2 DeleteAssociation(InstanceId => Str, Name => Str)

Each argument is described in detail in: L<Paws::SSM::DeleteAssociation>

Returns: a L<Paws::SSM::DeleteAssociationResult> instance

  

Disassociates the specified configuration document from the specified
instance.

When you disassociate a configuration document from an instance, it
does not change the configuration of the instance. To change the
configuration state of an instance after you disassociate a
configuration document, you must create a new configuration document
with the desired configuration and associate it with the instance.











=head2 DeleteDocument(Name => Str)

Each argument is described in detail in: L<Paws::SSM::DeleteDocument>

Returns: a L<Paws::SSM::DeleteDocumentResult> instance

  

Deletes the specified configuration document.

You must use DeleteAssociation to disassociate all instances that are
associated with the configuration document before you can delete it.











=head2 DescribeAssociation(InstanceId => Str, Name => Str)

Each argument is described in detail in: L<Paws::SSM::DescribeAssociation>

Returns: a L<Paws::SSM::DescribeAssociationResult> instance

  

Describes the associations for the specified configuration document or
instance.











=head2 DescribeDocument(Name => Str)

Each argument is described in detail in: L<Paws::SSM::DescribeDocument>

Returns: a L<Paws::SSM::DescribeDocumentResult> instance

  

Describes the specified configuration document.











=head2 GetDocument(Name => Str)

Each argument is described in detail in: L<Paws::SSM::GetDocument>

Returns: a L<Paws::SSM::GetDocumentResult> instance

  

Gets the contents of the specified configuration document.











=head2 ListAssociations(AssociationFilterList => ArrayRef[Paws::SSM::AssociationFilter], [MaxResults => Int, NextToken => Str])

Each argument is described in detail in: L<Paws::SSM::ListAssociations>

Returns: a L<Paws::SSM::ListAssociationsResult> instance

  

Lists the associations for the specified configuration document or
instance.











=head2 ListDocuments([DocumentFilterList => ArrayRef[Paws::SSM::DocumentFilter], MaxResults => Int, NextToken => Str])

Each argument is described in detail in: L<Paws::SSM::ListDocuments>

Returns: a L<Paws::SSM::ListDocumentsResult> instance

  

Describes one or more of your configuration documents.











=head2 UpdateAssociationStatus(AssociationStatus => Paws::SSM::AssociationStatus, InstanceId => Str, Name => Str)

Each argument is described in detail in: L<Paws::SSM::UpdateAssociationStatus>

Returns: a L<Paws::SSM::UpdateAssociationStatusResult> instance

  

Updates the status of the configuration document associated with the
specified instance.











=head1 SEE ALSO

This service class forms part of L<Paws>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

