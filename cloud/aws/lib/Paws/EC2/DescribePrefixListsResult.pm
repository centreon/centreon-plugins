
package Paws::EC2::DescribePrefixListsResult {
  use Moose;
  has NextToken => (is => 'ro', isa => 'Str', xmlname => 'nextToken', traits => ['Unwrapped',]);
  has PrefixLists => (is => 'ro', isa => 'ArrayRef[Paws::EC2::PrefixList]', xmlname => 'prefixListSet', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::DescribePrefixListsResult

=head1 ATTRIBUTES

=head2 NextToken => Str

  

The token to use when requesting the next set of items. If there are no
additional items to return, the string is empty.









=head2 PrefixLists => ArrayRef[Paws::EC2::PrefixList]

  

All available prefix lists.











=cut

