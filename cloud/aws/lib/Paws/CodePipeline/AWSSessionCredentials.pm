package Paws::CodePipeline::AWSSessionCredentials {
  use Moose;
  has accessKeyId => (is => 'ro', isa => 'Str', required => 1);
  has secretAccessKey => (is => 'ro', isa => 'Str', required => 1);
  has sessionToken => (is => 'ro', isa => 'Str', required => 1);
}
1;
