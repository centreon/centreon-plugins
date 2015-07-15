package Paws::S3::CORSConfiguration {
  use Moose;
  has CORSRules => (is => 'ro', isa => 'ArrayRef[Paws::S3::CORSRule]', xmlname => 'CORSRule', request_name => 'CORSRule', traits => ['Unwrapped','NameInRequest']);
}
1;
