
package Paws::StorageGateway::DescribeCacheOutput {
  use Moose;
  has CacheAllocatedInBytes => (is => 'ro', isa => 'Int');
  has CacheDirtyPercentage => (is => 'ro', isa => 'Num');
  has CacheHitPercentage => (is => 'ro', isa => 'Num');
  has CacheMissPercentage => (is => 'ro', isa => 'Num');
  has CacheUsedPercentage => (is => 'ro', isa => 'Num');
  has DiskIds => (is => 'ro', isa => 'ArrayRef[Str]');
  has GatewayARN => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::StorageGateway::DescribeCacheOutput

=head1 ATTRIBUTES

=head2 CacheAllocatedInBytes => Int

  
=head2 CacheDirtyPercentage => Num

  
=head2 CacheHitPercentage => Num

  
=head2 CacheMissPercentage => Num

  
=head2 CacheUsedPercentage => Num

  
=head2 DiskIds => ArrayRef[Str]

  
=head2 GatewayARN => Str

  


=cut

1;