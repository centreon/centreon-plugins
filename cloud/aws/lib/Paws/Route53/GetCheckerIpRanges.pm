
package Paws::Route53::GetCheckerIpRanges {
  use Moose;

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'GetCheckerIpRanges');
  class_has _api_uri  => (isa => 'Str', is => 'ro', default => '/2013-04-01/checkeripranges');
  class_has _api_method  => (isa => 'Str', is => 'ro', default => 'GET');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::Route53::GetCheckerIpRangesResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Route53::GetCheckerIpRangesResponse

=head1 ATTRIBUTES



=cut

