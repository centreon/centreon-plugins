package certificates_date;

# Always use the same fixed date to test certificate validity

BEGIN {
   *CORE::GLOBAL::time = sub { 1747989383 };
}

1
