use strictures 1;
use Test::More skip_all => 'TODO test';
use HTML::Zoom;
use Test::Fatal;

foreach my $void (qw/ area base br col command embed hr 
  img input keygen link meta param source wbr/) {
  my $tmpla = <<END;
<body>
  <div class="main">
    <$void class="void" src="moo">
  </div>
  <div class="main2">
    <$void class="void" src="moo">
  </div>
</body>
END
  my $ra;
  is(
    exception { 
      $ra = HTML::Zoom->from_html( $tmpla )
               ->select('.main')->replace_content('foo')->to_html;
    },
    undef,
    "Zoom didn't die for $void"
  );
  #like( $ra, qr^<div class="main">foo</div>^ );
}

done_testing;
