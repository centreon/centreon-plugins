
package Paws::Support::DescribeServicesResponse {
  use Moose;
  has services => (is => 'ro', isa => 'ArrayRef[Paws::Support::Service]');

}

### main pod documentation begin ###

=head1 NAME

Paws::Support::DescribeServicesResponse

=head1 ATTRIBUTES

=head2 services => ArrayRef[Paws::Support::Service]

  

A JSON-formatted list of AWS services.











=cut

1;