package Paws::S3::WebsiteConfiguration {
  use Moose;
  has ErrorDocument => (is => 'ro', isa => 'Paws::S3::ErrorDocument');
  has IndexDocument => (is => 'ro', isa => 'Paws::S3::IndexDocument');
  has RedirectAllRequestsTo => (is => 'ro', isa => 'Paws::S3::RedirectAllRequestsTo');
  has RoutingRules => (is => 'ro', isa => 'ArrayRef[Paws::S3::RoutingRule]');
}
1;
