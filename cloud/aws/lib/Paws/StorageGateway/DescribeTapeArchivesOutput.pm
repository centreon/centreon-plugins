
package Paws::StorageGateway::DescribeTapeArchivesOutput {
  use Moose;
  has Marker => (is => 'ro', isa => 'Str');
  has TapeArchives => (is => 'ro', isa => 'ArrayRef[Paws::StorageGateway::TapeArchive]');

}

### main pod documentation begin ###

=head1 NAME

Paws::StorageGateway::DescribeTapeArchivesOutput

=head1 ATTRIBUTES

=head2 Marker => Str

  

An opaque string that indicates the position at which the virtual tapes
that were fetched for description ended. Use this marker in your next
request to fetch the next set of virtual tapes in the virtual tape
shelf (VTS). If there are no more virtual tapes to describe, this field
does not appear in the response.









=head2 TapeArchives => ArrayRef[Paws::StorageGateway::TapeArchive]

  

An array of virtual tape objects in the virtual tape shelf (VTS). The
description includes of the Amazon Resource Name(ARN) of the virtual
tapes. The information returned includes the Amazon Resource Names
(ARNs) of the tapes, size of the tapes, status of the tapes, progress
of the description and tape barcode.











=cut

1;