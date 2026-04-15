package Msgs::Plugins::Msgs_AI;

use strict;
use warnings FATAL => 'all';

#**********************************************************
=head2 new($html, $lang)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $attr) = @_;

  my $self = {
    MODULE      => 'Msgs',
    db          => $db,
    admin       => $admin,
    conf        => $conf,
    html        => $attr->{HTML} || undef,
    lang        => $attr->{LANG} || {},
    permissions => $attr->{MSGS_PERMISSIONS},
    libpath     => $attr->{libpath}
  };

  bless($self, $class);

  use Msgs;
  $self->{msgs} = Msgs->new($db, $admin, $conf);

  return $self;
}

#**********************************************************
=head2 plugin_info()

=cut
#**********************************************************
sub plugin_info {
  return {
    NAME     => "AI",
    POSITION => 'RIGHT',
    DESCR    => 'AI Assist'
  };
}

#**********************************************************
=head2 plugin_show($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub plugin_show {
  my ($self, $attr) = @_;

  return '' if !$self->{html};

  use Abills::Template;
  my $Templates = Abills::Template->new($self->{db}, $self->{admin}, $self->{conf}, {
    html    => $self->{html},
    lang    => $self->{lang},
    libpath => $self->{libpath}
  });

  my $message = $self->{html}->tpl_show($Templates->_include('msgs_ai_plugin', 'Msgs'), {
    PUTER_AI_MODEL => $self->{conf}{PUTER_AI_MODEL}
  }, { OUTPUT2RETURN => 1, SKIP_DEBUG_MARKERS => 1 });
  return $message;
}

1;
