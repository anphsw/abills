package Control::Errors;

use strict;
use warnings FATAL => 'all';

use Abills::Base qw(vars2lang);

#**********************************************************
=head2 new($db, $conf, $admin, $attr)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $attr) = @_;

  my $self = {
    db        => $db,
    admin     => $admin,
    conf      => $conf,
    lang      => $attr->{lang},
    module    => $attr->{module},
    is_lazy_loaded => 0,
  };

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 throw_error($attr) - return error object

  Arguments:
    $errno: int   - id of error
    $attr: obj
      errstr?: str - predefined of errstr without search of it
      lang_vars:? obj - params for lang key of error

  Returns:
    $obj
      errno: int    - id of error
      errstr: str   - error short desc
      errmsg?: str  - en lang key of error

=cut
#**********************************************************
sub throw_error {
  my $self = shift;
  my ($errno, $attr) = @_;

  if (!$self->{is_lazy_loaded}) {
    $self->_module_language_load();
  }

  my %response = (
    errno  => $errno,
    errstr => 'ERROR'
  );

  my $module_name = $self->{module};

  if ($attr && $attr->{errstr}) {
    $response{errstr} = $attr->{errstr};
  }
  else {
    if (!$module_name) {
      return \%response;
    }
    else {
      $response{errstr} = $self->_get_errors($errno, $module_name);
    }
  }

  my $lang_vars = ($attr && $attr->{lang_vars}) ? $attr->{lang_vars} : {};
  $response{errmsg} = vars2lang($self->{lang}->{$response{errstr}}, $lang_vars);

  return \%response;
}

#**********************************************************
=head2 _module_language_load() - language lazy load

  Returns:
    undef or error

=cut
#**********************************************************
sub _module_language_load {
  my $self = shift;

  if ($self->{module}) {
    eval {
      our %lang;
      require "Abills/modules/$self->{module}/lng_english.pl";
      $self->{lang} = { %lang, %{$self->{lang}} };
    };
  }

  if (!$@) {
    $self->{is_lazy_loaded} = 1;
  }
  return $@;
}

#**********************************************************
=head2 _get_errors($errno, $module) - get errors file of module

  Arguments:
    $errno: int - id of error
    $module: str - module where could take an error

  Returns:

    FOUND RESULT
      errstr: str - error short desc which found in in error module

    NOT FOUND RESULT
      errstr: str - default key ERROR

=cut
#**********************************************************
sub _get_errors {
  shift;
  my ($errno, $module) = @_;

  my $module_name = "$module\::Errors";
  my $module_path = $module_name . '.pm';
  $module_path =~ s{::}{/}g;
  eval {require $module_path};

  return 'ERROR' if ($@);

  my $errors = $module_name->errors();

  return $errors->{$errno} || 'ERROR';
}

1;
