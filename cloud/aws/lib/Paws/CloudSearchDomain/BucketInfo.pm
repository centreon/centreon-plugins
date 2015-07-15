package Paws::CloudSearchDomain::BucketInfo {
  use Moose;
  has buckets => (is => 'ro', isa => 'ArrayRef[Paws::CloudSearchDomain::Bucket]');
}
1;
