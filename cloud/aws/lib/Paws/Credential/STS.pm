package Paws::Credential::STS {
  use JSON;
  use Moose;
  use DateTime;
  use DateTime::Format::ISO8601;
  with 'Paws::Credential';

  has expiration => (
    is => 'rw',
    isa => 'DateTime',
    lazy => 1,
    default => sub {
      DateTime->from_epoch(epoch => 0); # need a better way to do this
    }
  );

  has actual_creds => (is => 'rw');

  sub access_key {
    my $self = shift;
    $self->_refresh;
    $self->actual_creds->AccessKeyId;
  }

  sub secret_key {
    my $self = shift;
    $self->_refresh;
    $self->actual_creds->SecretAccessKey;
  }

  sub session_token {
    my $self = shift;
    $self->_refresh;
    $self->actual_creds->SessionToken;
  }

  has sts_region => (is => 'ro', isa => 'Str|Undef', default => sub { undef });

  has sts => (is => 'ro', isa => 'Paws::STS', lazy => 1, default => sub {
    my $self = shift;
    Paws->service('STS', region => $self->sts_region);
  });

  has Name => (is => 'rw', isa => 'Str', required => 1);
  has DurationSeconds => (is => 'rw', isa => 'Maybe[Int]');
  has Policy => (is => 'rw', isa => 'Maybe[Str]');

  sub _refresh {
    my $self = shift;

    return if (($self->expiration - DateTime->now())->is_positive);

    my $result = $self->sts->GetFederationToken(
      Name => $self->Name,
      (defined $self->DurationSeconds) ? (DurationSeconds => $self->DurationSeconds) : (),
      (defined $self->Policy) ? (Policy => $self->Policy) : (),
    );

    my $creds = $self->actual_creds($result->Credentials);
    $self->expiration(DateTime::Format::ISO8601->parse_datetime($result->Credentials->Expiration));
  }

  no Moose;
}

1;
