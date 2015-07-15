
package Paws::StorageGateway::DescribeBandwidthRateLimitOutput {
  use Moose;
  has AverageDownloadRateLimitInBitsPerSec => (is => 'ro', isa => 'Int');
  has AverageUploadRateLimitInBitsPerSec => (is => 'ro', isa => 'Int');
  has GatewayARN => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::StorageGateway::DescribeBandwidthRateLimitOutput

=head1 ATTRIBUTES

=head2 AverageDownloadRateLimitInBitsPerSec => Int

  

The average download bandwidth rate limit in bits per second. This
field does not appear in the response if the download rate limit is not
set.









=head2 AverageUploadRateLimitInBitsPerSec => Int

  

The average upload bandwidth rate limit in bits per second. This field
does not appear in the response if the upload rate limit is not set.









=head2 GatewayARN => Str

  


=cut

1;