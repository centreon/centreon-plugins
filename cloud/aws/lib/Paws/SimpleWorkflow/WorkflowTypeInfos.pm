
package Paws::SimpleWorkflow::WorkflowTypeInfos {
  use Moose;
  has nextPageToken => (is => 'ro', isa => 'Str');
  has typeInfos => (is => 'ro', isa => 'ArrayRef[Paws::SimpleWorkflow::WorkflowTypeInfo]', required => 1);

}

### main pod documentation begin ###

=head1 NAME

Paws::SimpleWorkflow::WorkflowTypeInfos

=head1 ATTRIBUTES

=head2 nextPageToken => Str

  

If a C<NextPageToken> was returned by a previous call, there are more
results available. To retrieve the next page of results, make the call
again using the returned token in C<nextPageToken>. Keep all other
arguments unchanged.

The configured C<maximumPageSize> determines how many results can be
returned in a single call.









=head2 B<REQUIRED> typeInfos => ArrayRef[Paws::SimpleWorkflow::WorkflowTypeInfo]

  

The list of workflow type information.











=cut

1;