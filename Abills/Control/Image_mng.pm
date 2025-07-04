=head1 NAME

  Image mng functions

=cut

use strict;
use Abills::Base qw(decode_base64);

our (
  %FORM,
  %conf,
  %lang
);

our Abills::HTML $html;
our Users $users;

#**********************************************************
=head2 form_image_mng($attr)

   Arguments:
     $attr
       UID
       PHOTO

   Results:
     $file_content

=cut
#**********************************************************
sub form_image_mng {
  my ($attr) = @_;

  my $uid = $attr->{UID} || 0;
  my $photo = $attr->{PHOTO} || 1;

  if ($attr->{IMAGE}) {
    my $file_content;

    if(ref $attr->{IMAGE} eq 'HASH' && $attr->{IMAGE}{Contents}) {
      $file_content = $attr->{IMAGE};
    }
    elsif($attr->{IMAGE} eq 'URL') {
      require Abills::Fetcher;
      Abills::Fetcher->import('web_request');
      $file_content->{Contents} = web_request($attr->{URL});
      $file_content->{Size} = length($file_content->{Contents});
      $file_content->{'Content-Type'} = 'image/jpeg';
    }
    else {
      my $content = decode_base64($attr->{IMAGE});
      $file_content->{Contents}       = $content;
      $file_content->{Size}           = length($content);
      $file_content->{'Content-Type'} = 'image/jpeg';
    }

    if($attr->{TO_RETURN}) {
      return $file_content;
    }

    upload_file($file_content, { PREFIX    => 'if_image',
      FILE_NAME => "$uid.jpg",
      #EXTENSIONS=> 'jpg,gif,png'
      REWRITE   => 1
    });
  }
  elsif($attr->{show}) {
    print "Content-Type: image/jpeg\n\n";

    print file_op({
      FILENAME => "$conf{TPL_DIR}/if_image/$uid.jpg",
      PATH     => "$conf{TPL_DIR}/if_image"
    });
    return 0;
  }
  elsif($attr->{photo_del}) {
    if (unlink("$conf{TPL_DIR}/if_image/$uid.jpg") == 1) {
      $html->message('info', $lang{DELETED}, $lang{DELETED});
    }
    else {
      $html->message('err', $lang{DELETED}, $lang{ERROR});
    }
  }

  my @header_arr = (
    "$lang{MAIN}:index=$index&PHOTO=$photo&UID=$uid",
    "Webcam:index=$index&PHOTO=$photo&UID=$uid&webcam=1",
    "Upload:index=$index&PHOTO=$photo&UID=$uid&upload=1"
  );

  my $user_pi = $users->pi();
  if ($user_pi->{_FACEBOOK} && $user_pi->{_FACEBOOK} =~ m/[0-9]/x) {
    push (@header_arr, "Facebook:index=$index&PHOTO=$photo&UID=$uid&facebook=1");
  }

  if ($user_pi->{_VK} && $user_pi->{_VK} =~ m/[0-9]/x) {
    push (@header_arr, "Vk:index=$index&PHOTO=$photo&UID=$uid&vk=1");
  }

  print $html->table_header(\@header_arr, { TABS => 1 });

  $FORM{EXTERNAL_ID}=$attr->{EXTERNAL_ID};

  if($FORM{webcam}) {
    $html->tpl_show(templates('form_image_webcam'), { %FORM, %$attr },
      { ID => 'form_image_webcam' });
  }
  elsif($attr->{upload}) {
    $html->tpl_show(templates('form_image_upload'), { %FORM, %$attr },
      { ID => 'form_image_upload' });
  }
  elsif($attr->{facebook}) {
    my $Auth = Abills::Auth::Core->new({
      CONF      => \%conf,
      AUTH_TYPE => ucfirst('Facebook')
    });
    my ($fb_id) = $user_pi->{_FACEBOOK} =~ m/(\d+)/x;
    my $result = $Auth->get_fb_photo({
      USER_ID => $fb_id,
      SIZE    => 200,
    });
    unless(ref $result eq 'HASH' && $result->{data}->{url}){return 0;}

    print $html->form_main({
      HIDDEN  => {
        index => $index,
        UID   => $uid,
        PHOTO => $uid,
        IMAGE => 'URL',
        URL   => $result->{data}->{url},
      },
      SUBMIT  => { add => $lang{ADD} },
      CONTENT => $html->img($result->{data}->{url})
    });
  }
  elsif($attr->{vk}) {
    my $Auth = Abills::Auth::Core->new({
      CONF      => \%conf,
      AUTH_TYPE => ucfirst('Vk')
    });
    my ($vk_id) = $user_pi->{_VK} =~ m/(\d+)/x;
    my $result = $Auth->get_info({
      CLIENT_ID => $vk_id,
    });

    unless(ref $result && ref $result->{result} eq 'HASH' && $result->{result}->{photo_big}){return 0;}

    print $html->form_main({
      HIDDEN  => {
        index => $index,
        UID   => $uid,
        PHOTO => $uid,
        IMAGE => 'URL',
        URL   => $result->{result}->{photo_big},
      },
      SUBMIT  => { add => "$lang{ADD}" },
      CONTENT => $html->img($result->{result}->{photo_big}),
    });
  }
  else {
    if(-f "$conf{TPL_DIR}/if_image/$uid.jpg") {
      print $html->img("$SELF_URL?qindex=$index&PHOTO=1&UID=$uid&show=1");

      my $del_button = $html->button($lang{DEL}, "index=$index&PHOTO=1&UID=$uid&photo_del=$uid.jpg", {
        MESSAGE => $lang{DEL},
        class   => 'del'
      });

      print $html->element('div',
        $html->element('div',
          $del_button,
          { class => 'float-left' }
        ),
        { class => 'row' }
      );
    }
  }

  return 1;
}


1;