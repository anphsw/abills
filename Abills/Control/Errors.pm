package Control::Errors;

use strict;
use warnings FATAL => 'all';

use Abills::Base qw(vars2lang is_number decamelize);

#**********************************************************
=head2 new($db, $conf, $admin, $attr)

  $attr
   lang
   module
   language

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $attr) = @_;

  my $self = {
    db             => $db,
    admin          => $admin,
    conf           => $conf,
    lang           => $attr->{lang},
    module         => $attr->{module},
    language       => $attr->{language},
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
      errmsg?: str  - en/conf lang key of error

=cut
#**********************************************************
sub throw_error {
  my $self = shift;
  my ($errno, $attr) = @_;

  if (!$self->{is_lazy_loaded}) {
    $self->_module_language_load();
  }

  my %response = (
    errno  => $errno || -1,
    errstr => 'ERROR'
  );

  return \%response if (!is_number($errno));

  my $module_name = $self->{module};

  if ($attr && $attr->{errstr}) {
    $response{errstr} = $attr->{errstr};
  }
  else {
    if (!$module_name) {
      return \%response;
    }
    else {
      $response{errstr} = $self->_get_errors($errno, $module_name) // '';
    }
  }

  if ($errno == 9 && "$response{errstr}" eq 'VALIDATION_FAILED' && $attr->{errors} && ref $attr->{errors} eq 'ARRAY') {
    $response{errors} = $attr->{errors};
    $response{errmsg} = $self->_validation_object($attr);
  }
  else {
    my $lang_vars = ($attr && $attr->{lang_vars}) ? $attr->{lang_vars} : {};
    $response{errmsg} = vars2lang($self->{lang}->{$response{errstr}}, $lang_vars);
  }

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
      $self->{lang} = { %{$self->{lang}}, %lang };
      my $language = $self->{language} || $self->{conf}->{default_language} || 'english';
      require "Abills/modules/$self->{module}/lng_$language.pl";
      $self->{lang} = { %{$self->{lang}}, %lang };
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

#**********************************************************
=head2 _validation_object($attr) - process error object from validation

  Arguments:
    $attr: obj
      errstr?: str - predefined of errstr without search of it
      lang_vars:? obj - params for lang key of error

  Returns:

    FOUND RESULT
      errmsg: str - description of errors in human style

=cut
#**********************************************************
sub _validation_object {
  my $self = shift;
  my ($attr) = @_;

  my $lang = $self->{lang};

  my %types = (
    date             => $lang->{DATE},
    unsigned_integer => $lang->{VALIDATION_FAILED},
    integer          => $lang->{INTEGER},
    unsigned_number  => $lang->{UNSIGNED_NUMBER},
    number           => $lang->{ANY_NUMBER},
  );

  my $errmsg = "$lang->{VALIDATION_FAILED}\n" || '';

  foreach my $error (@{$attr->{errors}}) {
    next if ($error->{errno} && !is_number($error->{errno}));

    # add errmsg if its present in error obj
    if ($error->{errmsg}) {
      $errmsg .= "$error->{errmsg}\n";
      next;
    }

    my $parameter = $lang->{decamelize($error->{param} || '') || ''} // $error->{param};

    # no required parameter
    if ($error->{errno} == 20) {
      $errmsg .= vars2lang($lang->{$error->{errstr}} || $lang->{ERR_REQUIRED_PARAMETER}, { PARAMETER => $parameter });
      $errmsg .= "\n";
      next;
    }

    # not default error code
    elsif ($error->{errno} != 21 || !$error->{type}) {
      $errmsg .= $error->{errstr} || '';
      $errmsg .= "\n";
      next;
    }

    # parameter not valid
    if ($error->{type} eq 'string') {
      my $message = '';
      $message .= " $lang->{MIN} $lang->{LENGTH} $error->{min_length} " if ($error->{min_length});
      $message .= "$lang->{MAX} $lang->{LENGTH} $error->{max_length} " if ($error->{max_length});

      $errmsg .= vars2lang($lang->{$error->{errstr}} || $lang->{ERR_PARAMETER_NOT_VALID}, {
        PARAMETER => $parameter,
        MESSAGE   => $message,
      });
    }
    else {
      $errmsg .= vars2lang($lang->{$error->{errstr}} || $lang->{ERR_PARAMETER_NOT_VALID}, {
        PARAMETER => $parameter,
        MESSAGE   => " $lang->{TYPE} - " . ($types{$error->{type}} || $error->{type}),
      });
    }

    $errmsg .= "\n";
  }

  return $errmsg;
}

1;
