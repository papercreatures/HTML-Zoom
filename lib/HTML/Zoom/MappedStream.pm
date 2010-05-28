package HTML::Zoom::MappedStream;

use strict;
use warnings FATAL => 'all';
use base qw(HTML::Zoom::StreamBase);

sub new {
  my ($class, $args) = @_;
  bless({
    _source => $args->{source}, _mapper => $args->{mapper},
    _zconfig => $args->{zconfig}
  }, $class);
}

sub next {
  return unless (my $self = shift)->{_source};
  # If we were aiming for a "true" perl-like map then we should
  # elegantly handle the case where the map function returns 0 events
  # and the case where it returns >1 - if you're reading this comment
  # because you wanted it to do that, now would be the time to fix it :)
  if (my ($next) = $self->{_source}->next) {
    local $_ = $next;
    return $self->{_mapper}->($next);
  }
  delete $self->{_source};
  return
}

1;
