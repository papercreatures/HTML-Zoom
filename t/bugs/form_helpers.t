use strictures 1;
use Test::More;

use HTML::Zoom;

my $tmpl =<<END;
<body>
  <form name="main">
    <label for="input_field">Input</label>
    <input data-validate="required" type="text" name="input_field" />
    <label for="input_field2">Input 2</label>
    <input data-validate="required" value="gorch" type="text" name="input_field2" />

    <label for="input_check">Checkbox</label>
    <input data-validate="required" value="0" type="checkbox" name="input_check" />

    <label for="select_field">Select</label>
    <select data-validate="required" name="select_field">
      <option value="1">foo</option>
      <option value="2">bar</option>
      <option value="3" selected="selected">oof</option>
      <option value="4">rab</option>
    </select>
  </form>
</body>
END

my $z = HTML::Zoom->from_html($tmpl);

my @fields;
$z->select('input')->collect({ 
    into => \@fields,
    passthrough => 1,
})->memoize;
is(scalar @fields,2,"correctly extracted all inputs");

my $expect;

($expect = $tmpl) =~ s#name="input_field" />#name="input_field" /><div>cluck</div>#;

is(
  $z->select('input[name="input_field"]')
  ->add_after(\"<div>cluck</div>")
  ->to_html, $expect,
"added after void");

($expect = $tmpl) =~ s#Input</label>#Input</label><div>cluck</div>#;

is(
  $z->select('input[name="input_field"]')
  ->add_before(\"<div>cluck</div>")
  ->to_html, $expect,
"added before void");
