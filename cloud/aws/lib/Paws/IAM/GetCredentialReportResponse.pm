
package Paws::IAM::GetCredentialReportResponse {
  use Moose;
  has Content => (is => 'ro', isa => 'Str');
  has GeneratedTime => (is => 'ro', isa => 'Str');
  has ReportFormat => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::IAM::GetCredentialReportResponse

=head1 ATTRIBUTES

=head2 Content => Str

  

Contains the credential report. The report is Base64-encoded.









=head2 GeneratedTime => Str

  

The date and time when the credential report was created, in ISO 8601
date-time format.









=head2 ReportFormat => Str

  

The format (MIME type) of the credential report.











=cut

