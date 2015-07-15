package Paws::CloudFront::CustomErrorResponse {
  use Moose;
  has ErrorCachingMinTTL => (is => 'ro', isa => 'Int');
  has ErrorCode => (is => 'ro', isa => 'Int', required => 1);
  has ResponseCode => (is => 'ro', isa => 'Str');
  has ResponsePagePath => (is => 'ro', isa => 'Str');
}
1;
