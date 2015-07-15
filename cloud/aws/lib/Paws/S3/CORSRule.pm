package Paws::S3::CORSRule {
  use Moose;
  has AllowedHeaders => (is => 'ro', isa => 'ArrayRef[Str]', xmlname => 'AllowedHeader', request_name => 'AllowedHeader', traits => ['Unwrapped','NameInRequest']);
  has AllowedMethods => (is => 'ro', isa => 'ArrayRef[Str]', xmlname => 'AllowedMethod', request_name => 'AllowedMethod', traits => ['Unwrapped','NameInRequest']);
  has AllowedOrigins => (is => 'ro', isa => 'ArrayRef[Str]', xmlname => 'AllowedOrigin', request_name => 'AllowedOrigin', traits => ['Unwrapped','NameInRequest']);
  has ExposeHeaders => (is => 'ro', isa => 'ArrayRef[Str]', xmlname => 'ExposeHeader', request_name => 'ExposeHeader', traits => ['Unwrapped','NameInRequest']);
  has MaxAgeSeconds => (is => 'ro', isa => 'Int');
}
1;
