#!/usr/bin/perl
package Abills::Misc::Templates_generator;

use vars qw($begin_time $debug $DATE $TIME %conf $dbh $base_dir);
use strict;
use feature 'state';

use lib "../lib/";
use lib "../Abills/mysql/";

BEGIN {

  eval {
        require Time::HiRes;
    };
    if (!$@) {
        Time::HiRes->import(qw(gettimeofday tv_interval));
        $begin_time = [gettimeofday()];
    }
    else {
        $begin_time = 0;
    }
}

my $VERSION = 1.01;

use POSIX qw(strftime);
use Abills::HTML;
use Abills::Base;
use Abills::Misc;

my $html = Abills::HTML->new(
    {
        CONF     => \%conf,
        NO_PRINT => 0,
        PATH     => $conf{WEB_IMG_SCRIPT_PATH} || '../',
        CHARSET  => $conf{default_charset},
    }
);


my %default_classes = (

    text           => 'form-control',
    text_label     => 'control-label col-md-3',

    checkbox       => 'control-element',
    checkbox_label => 'control-label col-md-3',

    textarea       => 'form-control',

    select         => 'control-element',
    select_label   => 'control-label col-md-3'
);

my $line_counter = 1;

print "Content-Type: text/html\n\n";

print << '[END]';
<!DOCTYPE HTML>
<HTML>
<head>
  <meta charset="utf-8">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <!-- Bootstrap -->
  <link href="/styles/default_adm/css/bootstrap.min.css" rel="stylesheet">
  <link href="/styles/default_adm/css/style.css" rel="stylesheet">
    <style>
      .panel-form {
         max-width : 500px;

         margin-left : auto;
         margin-right: auto;
      }
    </style>

  <!-- jQuery -->
  <script src="/styles/default_adm/js/jquery.min.js"></script>

  <title>ABillS Form Generator</title>

    <script>
      jQuery(function(){
        var copyTextareaBtn = document.querySelector('.js-textareacopybtn');

        copyTextareaBtn.addEventListener('click', function(event) {
          var copyTextarea = document.querySelector('.js-copytextarea');
          var $copyTextarea = $(copyTextarea);

          var text = $copyTextarea.text();
          text = text.replace(/ttextarea/g, 'textarea');

          $copyTextarea.text(text);

          copyTextarea.select();

          try {
            var successful = document.execCommand('copy');
            var msg = successful ? 'successful' : 'unsuccessful';
            document.getSelection().removeAllRanges();
             alert(msg);
          } catch (err) {
            alert('Oops, unable to copy');
          }
        });
      });
    </script>
</head>
<body>
  <div class='container'>
  <div class='row'>
    <div class='well'>
      <h3>Usage</h3>
      <p class='text-muted'>
        <b>Text input:</b> text:$label:$name:$default_value:$placeholder:$required
        <br />
        <b>Textarea:</b> textarea:$label:$name:$default_value:$placeholder:$required
        <br />
        <b>Checkbox: </b> checkbox:$label:$name:$checked:$required
        <br />
        <b>Select: </b> select:$label:$name:$required
        <br />
        <b>Start collapsing panel: </b> collapse:$label:$name
        <br />
        <b>End collapsing panel: </b> collapse_end:
      </p>
      <div class='row'>
        <div class='col-md-6'>
          <div class='alert alert-info'>
            Pass empty (::) as false or skipped value
          </div>
        </div>
        <div class='col-md-6'>
          <div class='alert alert-warning'>
            <strong>Warning!</strong>
              $label and $name are required
          </div>
        </div>
      </div>
    </div>
  </div>
[END]

ask_form();

if ($FORM{GENERATE}) {
    my $result = generate_form(\%FORM);

    print "<hr />" .
     '<h1>Preview</h1>' .
     $result .
     "<hr />" .
    '<div class="row"><div class="col-md-3"><h2>Code</h2></div>' .
        '<div class="col-md-9"><button class="btn btn-primary btn-lg js-textareacopybtn"><span class="glyphicon glyphicon-export"></span>Copy</button></div></div>';
    $result =~ s/textarea/ttextarea/g;
    print "<textarea class='form-control js-copytextarea' rows='" . num_of_lines($result) . "'>$result</textarea><br />";
}
  if ($begin_time != 0) {
    my $gen_time = tv_interval ( $begin_time, [ gettimeofday() ] );
    print "<hr><div class='row' id='footer'> Version: $VERSION (GT: " . sprintf("%.6f", $gen_time) . ")</div>";
  }
print << '[FOOTER]';
  </div>
  <script src="/styles/default_adm/js/bootstrap.min.js"></script>
</body>
</html>
[FOOTER]


=head2 ask_form

=cut
sub ask_form {

    my $in_panel = (defined $FORM{IN_PANEL} && $FORM{IN_PANEL} eq 'on') ? 'checked' : '';

    print << "[FORM]";
    <div class='row'>
    <div class='col-md-6 col-md-offset-3'>
      <form method='post' class='form form-horizontal'>
        <div class='panel panel-primary'>

          <div class='panel-heading text-center'>
            Input
          </div>
          <div class='panel-body'>

              <div class='form-group'>
                <label class='control-label col-md-3'>Form name</label>
                <div class='col-md-9'>
                  <input name='FORM_NAME' class='form-control' value='$FORM{FORM_NAME}'>
                </div>
              </div>

              <div class='form-group'>
                <label class='control-label col-md-3'>Input params</label>
                <div class='col-md-9'>
                  <textarea  name='FORM' class='form-control' rows='12'>$FORM{FORM}</textarea>
                </div>
              </div>

              <div class='form-group'>
                <label class='control-label col-md-3'>In panel?</label>
                <div class='col-md-9'>
                  <input type='checkbox' class='control-element' name='IN_PANEL' $in_panel>
                </div>
              </div>

          </div>
          <div class='panel-footer text-center'>
            <input class='btn btn-primary' type='submit' name='GENERATE' value='Generate'>
          </div>
        </div>
      </form>
    </div>
    </div>

[FORM]
}

=head2 generate_form

=cut
sub generate_form {
    my ($attr) = @_;

    my $in_panel = (defined $FORM{IN_PANEL} && $FORM{IN_PANEL} eq 'on');
    my $form_name = (defined $FORM{FORM_NAME} && !($FORM{FORM_NAME} eq '')) ? $FORM{FORM_NAME} : '%FORM_NAME%';

    my $input = $attr->{FORM};

    my @list = split('\n', $input);

    my $form = '';

    $form .= "    <form name='$form_name' id='form_$form_name' method='post' class='form form-horizontal'>\n";
    $form .= q{        <input type='hidden' name='index' value='$index' />} . "\n";

    for my $param (@list){
        $form .= parse_element_row($param);
    }

    $form .= "    </form>\n";

    my $result;

    if ($in_panel){
        $result = "
<div class='panel panel-primary panel-form'>
  <div class='panel-heading text-center'><h4>%PANEL_HEADING%</h4></div>
  <div class='panel-body'>
    
    $form
  </div>
  <div class='panel-footer text-center'>
      <input type='submit' form='form_$form_name' class='btn btn-primary' name='action' value='%SUBMIT_BTN_NAME%'>
  </div>
</div>\n
            ";

    } else {
        $result = $form;
    }

    return $result;
}

sub parse_element_row{
    my ($attr) = @_;

    my @element = split (':', $attr);

    #remove '\n'
    trim (@element);

    my $type = $element[0];

    my $result = 'Error';

    if ($type eq 'text'){
        my $label = $element[1];
        my $name = $element[2];

        my $default_value = $element[3];
        my $placeholder = $element[4];

        my $required = $element[5];

        $result = form_text_input_row($label, $name, $default_value, $placeholder, $required);

    } elsif ($type eq 'checkbox'){
        my $label = $element[1];
        my $name = $element[2];

        my $checked = $element[3];
        my $required = $element[4];

        $result = form_checkbox_input_row($label, $name, $checked, $required);

    } elsif ($type eq 'textarea'){
        my $label = $element[1];
        my $name = $element[2];

        my $default_value = $element[3];
        my $placeholder = $element[4];

        my $required = $element[5];

        $result = form_textarea_input_row($label, $name, $default_value, $placeholder, $required);

    } elsif ($type eq 'select'){
        my $label = $element[1];
        my $name = $element[2];

        my $required = $element[3];

        $result = form_select_row($label, $name, $required);

    } elsif ($type eq 'collapse'){
        my $label = $element[1];
        my $name = $element[2];

        $result = start_collapse_panel($label, $name);

    } elsif ($type eq 'collapse_end'){
        $result = close_collapse_panel();
    }
    else {
        print("<script>alert('ERROR :Unknown element: $type at line [$line_counter]')</script>");
        exit(1);
    }

    $line_counter++;

    return $result;
}

sub form_text_input_row{
    my ($label, $name, $def_value, $placeholder, $required) = @_;

    my $classes = $default_classes{text};

    my $id = '';
    my $attr_id = '';
    my $attr_name = '';
    my $prop_required = '';

    $def_value = to_attr('value', $def_value);
    $placeholder = to_attr('placeholder', $placeholder);

    if ($name ne ''){
        $attr_name = to_attr('name', $name);
        $id = trim($name) . "_id";
        $attr_id = to_attr('id', $id);
    }
#    show($required);
    if ($required ne ''){
        $prop_required = ' required';
    }


    my $element = "
      <div class='form-group'>
          <label class='$default_classes{text_label}$prop_required' for='$id'>$label</label>
          <div class='col-md-9'>
              <input type='text' class='$classes' $prop_required$attr_name$def_value$attr_id$placeholder />
          </div>
      </div>\n";

    return $element;

}

sub form_checkbox_input_row {
    my ($label, $name, $checked, $required) = @_;

    my $classes = $default_classes{checkbox};

    my $id = '';
    my $attr_id = '';
    my $attr_name = '';
    my $prop_required = '';
    my $prop_checked = '';

    if ($name ne ''){
        $attr_name = to_attr('name', $name);
        $id = trim($name . "_id");
        $attr_id = to_attr('id', $id);
    }

    if ($checked ne ''){
        $prop_checked = ' checked ';
    }

    if ($required ne ''){
        $prop_required = ' required';
    }


    my $element = "
      <div class='form-group'>
          <label class='$default_classes{checkbox_label}$prop_required' for='$id'>$label</label>
          <div class='col-md-6 col-md-push-3'>
              <input type='checkbox' class='$classes' $prop_checked$prop_required$attr_name$attr_id />
          </div>
      </div>\n";

    return $element;
}

sub form_select_row {
    my ($label, $name, $required) = @_;

    my $classes = $default_classes{select};

    my $id = $name;
    my $prop_required = '';

    if ($required ne ''){
        $prop_required = ' required';
    }


    my $element = "
      <div class='form-group'>
          <label class='$default_classes{select_label}$prop_required' for='$id'>$label</label>
          <div class='col-md-9'>
              %$name%
          </div>
      </div>\n";

    return $element;
}

sub form_textarea_input_row {
    my ($label, $name, $def_value, $placeholder, $required) = @_;

    my $classes = $default_classes{text};

    my $id = '';
    my $attr_id = '';
    my $attr_name = '';
    my $prop_required = '';
    my $attr_rows = to_attr('rows', 5);

    $def_value = trim($def_value);
    $placeholder = to_attr('placeholder', $placeholder);

    if ($name ne ''){
        $attr_name = to_attr('name', $name);
        $id = trim($name) . "_id";
        $attr_id = to_attr('id', $id);
    }
    #    show($required);
    if ($required ne ''){
        $prop_required = ' required';
    }


    my $element = "
      <div class='form-group'>
          <label class='$default_classes{text_label}$prop_required' for='$id'>$label</label>
          <div class='col-md-9'>
              <textarea class='$classes' $attr_rows$prop_required$attr_name$attr_id$placeholder>$def_value</textarea>
          </div>
      </div>\n";

    return $element;

}

sub start_collapse_panel{
    my ($label, $name) = @_;

    $name = trim($name);
    my $collapse_id = trim($name . "_collapse");
    my $heading_id = trim($name . "_heading");

    my $element = "
    <div class='form-group'>
      <div class='panel panel-default'>
          <div class='panel-heading' role='tab' id='$heading_id'>
            <h4 class='panel-title text-center'>
              <a role='button' data-toggle='collapse' href='#$collapse_id' aria-expanded='true' aria-controls='$collapse_id'>
                $label
              </a>
            </h4>
          </div>
        <div id='$collapse_id' class='panel-collapse collapse' role='tabpanel' aria-labelledby='$heading_id'>
        <div class='panel-body'>
        ";

    return $element;
}

sub close_collapse_panel {
    return "       </div> <!-- end of collapse panel-body -->
      </div> <!-- end of collapse div -->
      </div> <!-- end of collapse panel -->
    </div> <!-- end of collapse form-group -->
";
}

sub to_attr{
    my ($name, $value) = @_;

    if ($value ne ''){
        return " $name='" . trim($value) . "' ";
    }

    return '';
}

sub trim {
    my @out = @_;
    for (@out) {
        s/^\s+//;
        s/\s+$//;
        s/\n$//;
    }
    return wantarray ? @out : $out[0];
}

sub num_of_lines{
    my ($text) = @_;
    return scalar split /\n/, $text;
}

sub show{
    my ($attr) = @_;

    print "<hr />";
    print "'$attr'";
    print "<hr />";

}
1;
