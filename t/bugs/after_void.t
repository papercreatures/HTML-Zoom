use strictures 1;
use Test::More skip_all => 'TODO test';

use HTML::Zoom;

my $tmpl = <<END;
<body>
  <input class="main"/>
</body>
END

my $tmpl2 = <<END;
<body>
  <div>cluck</div><input class="main"/>
</body>
END

my $z = HTML::Zoom->from_html($tmpl);
is(
  $z->select('input')
  ->add_before(\"<div>cluck</div>")
  ->to_html, $tmpl2,
"added before void");

done_testing;
