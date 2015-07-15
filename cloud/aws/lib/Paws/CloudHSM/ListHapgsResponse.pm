
package Paws::CloudHSM::ListHapgsResponse {
  use Moose;
  has HapgList => (is => 'ro', isa => 'ArrayRef[Str]', required => 1);
  has NextToken => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::CloudHSM::ListHapgsResponse

=head1 ATTRIBUTES

=head2 B<REQUIRED> HapgList => ArrayRef[Str]

  

The list of high-availability partition groups.









=head2 NextToken => Str

  

If not null, more results are available. Pass this value to ListHapgs
to retrieve the next set of items.











=cut

1;