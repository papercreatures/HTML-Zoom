package HTML::Zoom::SelectorParser;

use strict;
use warnings FATAL => 'all';
use base qw(HTML::Zoom::SubObject);
use Carp qw(confess);

my $sel_char = '-\w_';
my $sel_re = qr/([$sel_char]+)/;
my $match_value_re = qr/"?$sel_re"?/;


sub new { bless({}, shift) }

sub _raw_parse_simple_selector {
  for ($_[1]) { # same pos() as outside

    # '*' - match anything

    /\G\*/gc and
      return sub { 1 };

    # 'element' - match on tag name

    /\G$sel_re/gc and
      return do {
        my $name = $1;
        sub { $_[0]->{name} && $_[0]->{name} eq $name }
      };

    # '#id' - match on id attribute

    /\G#$sel_re/gc and
      return do {
        my $id = $1;
        sub { $_[0]->{attrs}{id} && $_[0]->{attrs}{id} eq $id }
      };

    # '.class1.class2' - match on intersection of classes

    /\G((?:\.$sel_re)+)/gc and
      return do {
        my $cls = $1; $cls =~ s/^\.//;
        my @cl = split(/\./, $cls);
        sub {
          $_[0]->{attrs}{class}
          && !grep $_[0]->{attrs}{class} !~ /(^|\s+)$_($|\s+)/, @cl
        }
      };

    # '[attr^=foo]' - match attribute with ^ anchored regex
    /\G\[$sel_re\^=$match_value_re\]/gc and
      return do {
        my $attribute = $1;
        my $value = $2;
        sub {
          $_[0]->{attrs}{$attribute}
          && $_[0]->{attrs}{$attribute} =~ qr/^\Q$value\E/;
        }
      };

    # '[attr$=foo]' - match attribute with $ anchored regex
    /\G\[$sel_re\$=$match_value_re\]/gc and
      return do {
        my $attribute = $1;
        my $value = $2;
        sub {
          $_[0]->{attrs}{$attribute}
          && $_[0]->{attrs}{$attribute} =~ qr/\Q$value\E$/;
        }
      };

    # '[attr*=foo] - match attribute with regex:
    /\G\[$sel_re\*=$match_value_re\]/gc and
      return do {
        my $attribute = $1;
        my $value = $2;
        sub {
          $_[0]->{attrs}{$attribute}
          && $_[0]->{attrs}{$attribute} =~ qr/\Q$value\E/;
        }
      };

    # '[attr=bar]' - match attributes
    /\G\[$sel_re=$match_value_re\]/gc and
      return do {
        my $attribute = $1;
        my $value = $2;
        sub {
          $_[0]->{attrs}{$attribute}
          && $_[0]->{attrs}{$attribute} eq $value;
        }
      };

    # '[attr] - match attribute being present:
    /\G\[$sel_re\]/gc and
      return do {
        my $attribute = $1;
        sub {
          exists $_[0]->{attrs}{$attribute};
        }
      }
  }
}

sub parse_selector {
  my $self = $_[0];
  my $sel = $_[1]; # my pos() only please
  die "No selector provided" unless $sel;
  local *_;
  for ($sel) {
    my @sub;
    PARSE: { do {

      my @this_chain;

      # slurp selectors until we find something else:
      while( my $sel = $self->_raw_parse_simple_selector($_) ){
        push @this_chain, $sel;
      }

      if( @this_chain == 1 )
      {
        push @sub, @this_chain;
      }
      else{
        # make a compound match closure of everything
        # in this chain of selectors:
        push @sub, sub{
          my $r;
          for my $inner ( @this_chain ){
            if( ! ($r = $inner->( @_ )) ){
              return $r;
            }
          }
          return $r;
        }
      }

      # now we're at the end or a delimiter:
      last PARSE if( pos == length );
      /\G\s*,\s*/gc or do {
        /\G(.*)/;
        $self->_blam( "Selectors not comma separated." );
      }

     } until (pos == length) };
    return $sub[0] if (@sub == 1);
    return sub {
      foreach my $inner (@sub) {
        if (my $r = $inner->(@_)) { return $r }
      }
    };
  }
}


sub _blam {
  my ($self, $error) = @_;
  my $hat = (' ' x (pos||0)).'^';
  die "Error parsing dispatch specification: ${error}\n
${_}
${hat} here\n";
}

1;
