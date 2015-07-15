package Paws::CloudFront::InvalidationSummary {
  use Moose;
  has CreateTime => (is => 'ro', isa => 'Str', required => 1);
  has Id => (is => 'ro', isa => 'Str', required => 1);
  has Status => (is => 'ro', isa => 'Str', required => 1);
}
1;
