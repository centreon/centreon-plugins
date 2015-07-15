
package Paws::Route53Domains::GetOperationDetailResponse {
  use Moose;
  has DomainName => (is => 'ro', isa => 'Str');
  has Message => (is => 'ro', isa => 'Str');
  has OperationId => (is => 'ro', isa => 'Str');
  has Status => (is => 'ro', isa => 'Str');
  has SubmittedDate => (is => 'ro', isa => 'Str');
  has Type => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::Route53Domains::GetOperationDetailResponse

=head1 ATTRIBUTES

=head2 DomainName => Str

  

The name of a domain.

Type: String









=head2 Message => Str

  

Detailed information on the status including possible errors.

Type: String









=head2 OperationId => Str

  

The identifier for the operation.

Type: String









=head2 Status => Str

  

The current status of the requested operation in the system.

Type: String









=head2 SubmittedDate => Str

  

The date when the request was submitted.









=head2 Type => Str

  

The type of operation that was requested.

Type: String











=cut

1;