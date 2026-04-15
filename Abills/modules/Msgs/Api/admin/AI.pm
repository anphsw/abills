package Msgs::Api::admin::AI;

=head1 NAME

  Msgs AI

  Endpoints:
    /msgs/ai

=cut

use strict;
use warnings FATAL => 'all';

use Control::Errors;
use Msgs;

my Msgs $Msgs;
my Control::Errors $Errors;

#**********************************************************
=head2 new($db, $admin, $conf)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $attr) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf,
    attr  => $attr,
    html  => $attr->{html},
    lang  => $attr->{lang}
  };

  bless($self, $class);

  $Msgs = Msgs->new($db, $admin, $conf);
  $Msgs->{debug} = $self->{debug};
  $self->{permissions} = $Msgs->permissions_list($admin->{AID});

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 post_msgs_id_ai_suggest($path_params, $query_params) - Generate AI reply suggestion for message

  Endpoint POST /msgs/:id/ai_suggest/

  Arguments:
    $path_params - Path parameters
       id - Message ID

    $query_params - Query parameters (not used)

  Description:
    - Collects full ticket conversation (subject, client message, replies)
    - Detects client language automatically
    - Generates embeddings for the latest client message
    - Searches relevant documentation and previous tickets in Qdrant
    - Builds AI prompt using ticket history and knowledge base
    - Requests AI-generated reply suggestion

  Returns:
    Hash reference
       answer - AI-generated response text

  Notes:
    - Only client messages are used for language detection
    - Uses last client message for semantic search
    - Filters knowledge base results by score >= 0.60
    - Returns empty hashref if message or vector is not available

  Example:

    my $result = $self->post_msgs_id_ai_suggest(
      { id => 12345 },
      {}
    );

    print $result->{answer};

=cut
#**********************************************************
sub post_msgs_id_ai_suggest {
  my ($self, $path_params, $query_params) = @_;

  my $language = $query_params->{LANGUAGE} || '';
  my $followup = $query_params->{FOLLOWUP} || '';
  my $context = $query_params->{CONTEXT} || '';

  if ($followup && $context) {
    return $self->_ai_followup($language, $followup, $context);
  }

  return $self->_ai_suggest($path_params, $language);
}

#**********************************************************
=head2 post_msgs_id_ai_feedback($path_params, $query_params)

  Endpoint POST /msgs/:id/ai_feedback/

=cut
#**********************************************************
sub post_msgs_id_ai_feedback {
  my ($self, $path_params, $query_params) = @_;

  my $msg_id = $path_params->{id};
  my $status = $query_params->{STATUS};
  my $question = $query_params->{QUESTION} // '';
  my $answer = $query_params->{ANSWER} // '';

  if (!$question) {
    my $message = $Msgs->message_info($msg_id);
    return {} if (!$message->{TOTAL} || $message->{TOTAL} < 1);

    my $last_msg = $Msgs->{MESSAGE};
    my $messages_reply_list = $Msgs->messages_reply_list({
      MSG_ID    => $msg_id,
      AID       => '0',
      COLS_NAME => '_SHOW',
      DESC      => 'DESC',
      PAGE_ROWS => 1
    });

    if ($Msgs->{TOTAL} && $Msgs->{TOTAL} > 0) {
      $last_msg = $messages_reply_list->[0]{text};
    }

    $question = $last_msg;
  }

  if (!$question || !$answer) {
    return;
  }

  return $Msgs->msgs_ai_assist_feedback_add({
    MSG_ID   => $msg_id,
    STATUS   => $status,
    QUESTION => $question,
    ANSWER   => $answer
  });
}

#**********************************************************
=head2 post_msgs_ai_translate($path_params, $query_params)

  Endpoint POST /msgs/:id/ai_suggest/

=cut
#**********************************************************
sub post_msgs_ai_translate {
  my ($self, $path_params, $query_params) = @_;

  my $language = $query_params->{LANGUAGE} || '';
  my $text = $query_params->{TEXT} || '';
  return {} if (!$text || !$language);

  use Encode qw(encode_utf8 is_utf8);
  $text = encode_utf8($text) if is_utf8($text);

  my $prompt = <<TXT;
CRITICAL RULES - Strictly PRESERVE exactly as in original (do NOT translate, localize, alter case, or remove any characters/symbols):
- File, folder names and paths.
- CLI commands, flags, and arguments.
- Code blocks, variables (including prefixes like \$, \@, \%), functions, and tags.
- URLs and Markdown formatting.

Do not drop or modify ANY special characters in configuration lines (e.g., \$conf must remain \$conf).
Keep the tone professional. Use standard localized IT terms; otherwise, leave them in English.

Translate text to $language.

Text for translate:
$text
TXT

  if ($self->{conf}{AI_PROVIDER} && $self->{conf}{AI_PROVIDER} eq 'Puter') {
    return { prompt => $prompt };
  }

  use Abills::AI::Driver::Base;
  my $AI = Abills::AI::Driver::Base->create_driver($self->{conf});

  my $answer = $AI->chat({
    messages => [
      {
        role    => 'user',
        content => $prompt
      }
    ]
  });

  use utf8;
  my $result = { answer => $answer };
  return $result;
}

#**********************************************************
=head2 _ai_suggest($path_params, $language) - Build and send full AI suggestion

  Arguments:
    $path_params - contains id (ticket ID)
    $language    - override language (optional)

  Returns:
    Hash reference with answer or prompt

=cut
#**********************************************************
sub _ai_suggest {
  my ($self, $path_params, $language) = @_;

  my $message = $Msgs->message_info($path_params->{id});
  return {} if (!$message->{TOTAL} || $message->{TOTAL} < 1);

  my $subject = $Msgs->{SUBJECT} || '';
  my $main_message = $Msgs->{MESSAGE} || '';

  my $full_text = "Subject: $subject\n";
  $full_text .= "Client: $main_message\n";

  my $messages_reply_list = $Msgs->messages_reply_list({
    MSG_ID    => $path_params->{id},
    AID       => '_SHOW',
    COLS_NAME => '_SHOW',
    DESC      => 'DESC',
    PAGE_ROWS => 10
  });

  my $last_msg = $main_message;
  my @client_messages = ($main_message);

  if ($Msgs->{TOTAL} && $Msgs->{TOTAL} > 0) {
    foreach my $reply (reverse @$messages_reply_list) {
      my $role = $reply->{aid} ? "Support" : "Client";
      $full_text .= "$role: $reply->{text}\n";
      if (!$reply->{aid}) {
        $last_msg = $reply->{text};
        push @client_messages, $reply->{text};
      }
    }
  }

  my $detected_language = $language || _detect_language(join(" ", @client_messages));
  my $system_prompt = $self->_build_system_prompt($detected_language);

  my $knowledge = $self->_search_knowledge($last_msg);
  my $context_info = $knowledge
    ? "=== RELEVANT KNOWLEDGE BASE ===\n$knowledge"
    : "=== KNOWLEDGE BASE ===\nNo highly relevant documentation found. Use your expertise.\n";

  my $user_prompt = <<TXT;
=== TICKET #$path_params->{id} HISTORY ===
$full_text

$context_info

=== TASK ===
Customer's latest message: "$last_msg"

Provide your response in $detected_language:
TXT

  return $self->_ai_call($system_prompt, $user_prompt);
}

#**********************************************************
=head2 _ai_followup($language, $followup, $context) - Refine existing AI answer

  Arguments:
    $language - response language
    $followup - operator's follow-up question
    $context  - previous AI answer

  Returns:
    Hash reference with answer or prompt

=cut
#**********************************************************
sub _ai_followup {
  my ($self, $language, $followup, $context) = @_;

  my $detected_language = $language || _detect_language($followup);

  use Encode qw(encode_utf8 is_utf8);
  $context = encode_utf8($context) if is_utf8($context);
  $followup = encode_utf8($followup) if is_utf8($followup);

  my $extra_context = $self->_search_knowledge($followup);

  my $prompt = <<TXT;
Previous answer you gave:
$context

TXT

  if ($extra_context) {
    $prompt .= <<TXT;
Additional information from knowledge base that may help:
$extra_context

TXT
  }

  $prompt .= <<TXT;
Operator's follow-up question: $followup

Refine or extend your answer in $detected_language:
TXT

  return $self->_ai_call(undef, $prompt);
}

#**********************************************************
=head2 _build_system_prompt($language) - Build system prompt for AI

  Arguments:
    $language - response language

  Returns:
    String with system prompt

=cut
#**********************************************************
sub _build_system_prompt {
  my ($self, $language) = @_;

  return <<TXT;
You are an experienced technical support engineer.

Your task: Provide a helpful response to the customer's latest message.

Instructions:
- Respond in $language language (the same language the customer is using)
- Be polite and professional
- Provide direct solutions based on the knowledge base when available
- If information is insufficient, ask clarifying questions
- Do not mention "according to the knowledge base" - just provide the solution naturally
- Keep responses concise and actionable

CRITICAL: Respond ONLY in $language. Do not translate or use any other language.
TXT
}

#**********************************************************
=head2 _ai_call($system_prompt, $user_prompt) - Execute AI request or return prompt for Puter

  Arguments:
    $system_prompt - system instructions (undef for follow-up)
    $user_prompt   - user message / full prompt

  Returns:
    Hash reference
      answer        - AI response (server-side providers)
      prompt        - prompt text (Puter provider)
      system_prompt - system prompt (Puter provider, optional)

=cut
#**********************************************************
sub _ai_call {
  my ($self, $system_prompt, $user_prompt) = @_;

  if ($self->{conf}{AI_PROVIDER} && $self->{conf}{AI_PROVIDER} eq 'Puter') {
    my $result = { prompt => $user_prompt };
    $result->{system_prompt} = $system_prompt if $system_prompt;
    return $result;
  }

  use Abills::AI::Driver::Base;
  my $AI = Abills::AI::Driver::Base->create_driver($self->{conf});

  my @messages;
  push @messages, { role => 'system', content => $system_prompt } if $system_prompt;
  push @messages, { role => 'user', content => $user_prompt };

  my $answer = $AI->chat({ messages => \@messages });

  use utf8;
  return { answer => $answer };
}

#**********************************************************
=head2 _search_knowledge($text) - Search relevant docs in Qdrant

  Arguments:
    $text - query text for semantic search

  Returns:
    String with relevant knowledge or empty string

=cut
#**********************************************************
sub _search_knowledge {
  my ($self, $text) = @_;

  use Abills::AI::Qdrant;
  use Abills::AI::Embeddings;

  my $Embeddings = Abills::AI::Embeddings->new($self->{db}, $self->{admin}, $self->{conf});
  my $vector = $Embeddings->vector({ text => $text });
  return '' if (!$vector);

  my $Qdrant = Abills::AI::Qdrant->new($self->{conf});
  my $qres = $Qdrant->search({
    collection => 'docs_confluence',
    vector     => $vector,
    limit      => 5,
  });

  my $knowledge = '';
  my $relevant_docs = 0;
  foreach my $item (@{$qres->{result} || []}) {
    next if $item->{score} < 0.60;
    my $p = $item->{payload};
    if ($p->{source} && $p->{source} eq 'confluence') {
      $knowledge .= "[Documentation] $p->{title}\n$p->{text}\n\n";
    }
    else {
      $knowledge .= "[Previous Ticket] $p->{subject}\n$p->{chapter}\n\n";
    }
    last if ++$relevant_docs >= 3;
  }

  return $knowledge;
}

#**********************************************************
=head2 _detect_language($text) - Detect language of text

  Arguments:
    $text - Source text

  Returns:
    Detected language name
       Ukrainian
       Russian
       English

  Notes:
    - Defaults to C<Ukrainian> for empty or very short text
    - Uses character heuristics and common word patterns
    - Prioritizes explicit alphabet markers (ї, є, ґ, ы, э, ъ)
    - English is detected by Latin character dominance

  Example:

    my $lang = _detect_language('Дякую за допомогу');
    # Ukrainian

=cut
#**********************************************************
sub _detect_language {
  my ($text) = @_;

  return 'Ukrainian' if !$text;

  my $clean_text = $text;
  $clean_text =~ s/[^\p{L}]//g;

  return 'Ukrainian' if length($clean_text) < 3;

  return 'Russian' if $text =~ /[ыэъЫЭЪ]/;
  return 'Ukrainian' if $text =~ /[іїєґІЇЄҐ]/;

  my $latin_count = () = $clean_text =~ /[a-zA-Z]/g;
  my $total_count = length($clean_text);
  return 'English' if $total_count > 0 && ($latin_count / $total_count) > 0.5;

  if ($text =~ /[а-яА-Я]/) {
    my $ua_patterns = () = $text =~ /([нН][еЕ]|[шШ][оО]|[яЯ][кК]|[цЦ][еЕ]|[тТ][ьЬ]|[вВ][іІ][дД]|[зЗ][аА])/g;

    my $ru_patterns = () = $text =~ /([чЧ][тТ][оО]|[эЭ][тТ][оО]|[тТ][сС][яЯ]|[шШ][ьЬ]|[жЖ][еЕ]|[оО][йЙ])/g;

    my $i_count = () = $text =~ /[іІ]/g;
    my $y_count = () = $text =~ /[иИ]/g;

    my $ua_score = $ua_patterns + ($i_count * 2);
    my $ru_score = $ru_patterns + ($y_count * 0.5);

    return 'Russian' if $ru_score > $ua_score && $ru_score > 2;
    return 'Ukrainian';
  }

  return 'Ukrainian';
}

1;
