
package Paws::Route53Domains::ListOperationsResponse {
  use Moose;
  has NextPageMarker => (is => 'ro', isa => 'Str');
  has Operations => (is => 'ro', isa => 'ArrayRef[Paws::Route53Domains::OperationSummary]', required => 1);

}

### main pod documentation begin ###

=head1 NAME

Paws::Route53Domains::ListOperationsResponse

=head1 ATTRIBUTES

=head2 NextPageMarker => Str

  

If there are more operations than you specified for C<MaxItems> in the
request, submit another request and include the value of
C<NextPageMarker> in the value of C<Marker>.

Type: String

Parent: C<Operations>









=head2 B<REQUIRED> Operations => ArrayRef[Paws::Route53Domains::OperationSummary]

  

Lists summaries of the operations.

Type: Complex type containing a list of operation summaries

Children: C<OperationId>, C<Status>, C<SubmittedDate>, C<Type>











=cut

1;