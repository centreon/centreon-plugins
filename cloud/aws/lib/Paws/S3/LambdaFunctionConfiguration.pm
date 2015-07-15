package Paws::S3::LambdaFunctionConfiguration {
  use Moose;
  has Events => (is => 'ro', isa => 'ArrayRef[Str]', xmlname => 'Event', request_name => 'Event', traits => ['Unwrapped','NameInRequest'], required => 1);
  has Id => (is => 'ro', isa => 'Str');
  has LambdaFunctionArn => (is => 'ro', isa => 'Str', xmlname => 'CloudFunction', request_name => 'CloudFunction', traits => ['Unwrapped','NameInRequest'], required => 1);
}
1;
