use strictures 1;
use Test::More;
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
    <label for="select_field">Select 2</label>
    <select data-validate="required" name="select_field2">
      <option value="1">foo</option>
      <option value="2">bar</option>
      <option value="3">oof</option>
      <option value="4">rab</option>
    </select>

  </form>
</body>
END

my $z = HTML::Zoom->from_html($tmpl);

my ($expect);

($expect = $tmpl) =~ s/name="input_field" /name="input_field" value="testval" /;

is(
  $z->select('input[name="input_field"]')->val('testval')->to_html,
  $expect,
  'set value on input=text'
);

$z = HTML::Zoom->from_html($tmpl);
($expect = $tmpl) =~ s/value="0" type="checkbox" name="input_check" /value="1" type="checkbox" name="input_check" selected="selected" /;

is(
  $z->select('input[name="input_check"]')->val(1)->to_html,
  $expect,
  'set value on input=checkbox'
);

($expect = $tmpl) =~ s/value="1" type="checkbox" name="input_check" selected="selected" \>/value="0" type="checkbox" name="input_check" \>/;

is(
  $z->select('input[name="input_check"]')->val(0)->to_html,
  $expect,
  'remove value on input=checkbox'
);

$z = HTML::Zoom->from_html($tmpl);
($expect = $tmpl) =~ s/name="input_field" /name="input_field" value="testval" /;

is(
  $z->select('input')->val({input_field => "testval"})->to_html,
  $expect,
  'alternate fill'
);


SKIP: {
  skip "not implemented",1;
  $z = HTML::Zoom->from_html($tmpl);
  ($expect = $tmpl) =~ s/option value="2" /option value="2" selected="selected" /;

  is(
    $z->select('select[name="select_field"]')->val(2)->to_html,
    $expect,
    'Set value on select'
  );
  
}

my %rules;
$z->select('form')->validate_form(\%rules)->to_html;
is(scalar keys %rules, 5, "Correctly extracted validation info");

done_testing();
