package Crm::Api v1.30.03;
=head NAME

  Crm::Api - Crm api functions

=head VERSION

  DATE: 20221130
  UPDATE: 20221130
  VERSION: 0.01

=cut

use strict;
use warnings FATAL => 'all';

use Crm::Validations qw(POST_CRM_LEADS_SOCIAL POST_CRM_LEADS_DIALOGUE_MESSAGE);

#**********************************************************
=head2 admin_routes() - Returns available API paths

  ARGUMENTS
    admin_routes: boolean - if true return all admin routes, false - user

  Returns:
    [
      {
        method      => 'GET',          # HTTP method. Path can be queried only with this method

        path        => '/users/:uid/', # API path. May contain variables like ':uid'.
                                       # variables will be passed to handler function as argument ($path_params).
                                       # example: if route's path is '/users/:uid/', and queried URL
                                       # is '/users/9/', $path_params will be { uid => 9 }.
                                       # if credentials is 'ADMIN', 'ADMINSID', 'ADMINBOT',
                                       # variable :uid will be checked to contain only existing user's UID.

        params      => POST_USERS,     # Validation schema.
                                       # Can be used as hashref, but we use constant for clear
                                       # visual differences.

        controller  => 'Api::Controllers::Admin::Users::Info',
                                       # Name of loadable controller.

        endpoint    => \&Api::Controllers::Admin::Users::Info::get_users_uid,
                                       # Path to handler function, must be coderef.

        credentials => [               # arrayref of roles required to use this path.
                                       # if API admin/user is authorized as at least one of
                                       # these roles access to this path will be granted. REQUIRED.
                                       # List of credentials:
          'ADMIN'                      # 'ADMIN', 'ADMINSID', 'ADMINBOT', 'USER', 'USERBOT', 'BOT_UNREG', 'PUBLIC'
        ],
      },
    ]

=cut
#**********************************************************
sub admin_routes {
  return [
    {
      method      => 'POST',
      path        => '/crm/leads/',
      controller  => 'Crm::Api::admin::Leads',
      endpoint    => \&Crm::Api::admin::Leads::post_crm_leads,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'PUT',
      path        => '/crm/leads/:id/',
      controller  => 'Crm::Api::admin::Leads',
      endpoint    => \&Crm::Api::admin::Leads::put_crm_leads_id,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/crm/leads/:id/',
      controller  => 'Crm::Api::admin::Leads',
      endpoint    => \&Crm::Api::admin::Leads::delete_crm_leads_id,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'GET',
      path        => '/crm/leads/:id/',
      controller  => 'Crm::Api::admin::Leads',
      endpoint    => \&Crm::Api::admin::Leads::get_crm_leads_id,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'POST',
      path        => '/crm/leads/:id/phone/',
      controller  => 'Crm::Api::admin::Leads',
      endpoint    => \&Crm::Api::admin::Leads::post_crm_leads_id_phone,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'GET',
      path        => '/crm/leads/',
      controller  => 'Crm::Api::admin::Leads',
      endpoint    => \&Crm::Api::admin::Leads::get_crm_leads,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'POST',
      path        => '/crm/dialogue/:id/message/',
      controller  => 'Crm::Api::admin::Dialogues',
      endpoint    => \&Crm::Api::admin::Dialogues::post_crm_dialogue_id_message,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'GET',
      path        => '/crm/dialogue/:id/messages/',
      controller  => 'Crm::Api::admin::Dialogues',
      endpoint    => \&Crm::Api::admin::Dialogues::get_crm_dialogue_id_messages,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'PUT',
      path        => '/crm/dialogue/:id/',
      controller  => 'Crm::Api::admin::Dialogues',
      endpoint    => \&Crm::Api::admin::Dialogues::put_crm_dialogue_id,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'GET',
      path        => '/crm/dialogues/',
      controller  => 'Crm::Api::admin::Dialogues',
      endpoint    => \&Crm::Api::admin::Dialogues::get_crm_dialogues,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'POST',
      path        => '/crm/sections/',
      controller  => 'Crm::Api::admin::Sections',
      endpoint    => \&Crm::Api::admin::Sections::post_crm_sections,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'PUT',
      path        => '/crm/sections/:id/',
      controller  => 'Crm::Api::admin::Sections',
      endpoint    => \&Crm::Api::admin::Sections::put_crm_sections_id,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/crm/sections/:id/',
      controller  => 'Crm::Api::admin::Sections',
      endpoint    => \&Crm::Api::admin::Sections::delete_crm_sections_id,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'PUT',
      path        => '/crm/deals/:id/',
      controller  => 'Crm::Api::admin::Deals',
      endpoint    => \&Crm::Api::admin::Deals::put_crm_deals_id,
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'POST',
      path        => '/crm/progressbar/messages/',
      controller  => 'Crm::Api::admin::Progressbar',
      endpoint    => \&Crm::Api::admin::Progressbar::post_crm_progressbar_messages,
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'PUT',
      path        => '/crm/progressbar/messages/:id/',
      controller  => 'Crm::Api::admin::Progressbar',
      endpoint    => \&Crm::Api::admin::Progressbar::put_crm_progressbar_messages_id,
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'DELETE',
      path        => '/crm/progressbar/messages/:id/',
      controller  => 'Crm::Api::admin::Progressbar',
      endpoint    => \&Crm::Api::admin::Progressbar::delete_crm_progressbar_messages_id,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'POST',
      path        => '/crm/action/',
      controller  => 'Crm::Api::admin::Actions',
      endpoint    => \&Crm::Api::admin::Actions::post_crm_action,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'PUT',
      path        => '/crm/action/:action_id/',
      controller  => 'Crm::Api::admin::Actions',
      endpoint    => \&Crm::Api::admin::Actions::put_crm_action_action_id,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/crm/action/:action_id/',
      controller  => 'Crm::Api::admin::Actions',
      endpoint    => \&Crm::Api::admin::Actions::delete_crm_action_action_id,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'GET',
      path        => '/crm/action/:action_id/',
      controller  => 'Crm::Api::admin::Actions',
      endpoint    => \&Crm::Api::admin::Actions::get_crm_action_action_id,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'GET',
      path        => '/crm/actions/',
      controller  => 'Crm::Api::admin::Actions',
      endpoint    => \&Crm::Api::admin::Actions::get_crm_actions,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'POST',
      path        => '/crm/step/',
      controller  => 'Crm::Api::admin::Steps',
      endpoint    => \&Crm::Api::admin::Steps::post_crm_step,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'PUT',
      path        => '/crm/step/:step_id/',
      controller  => 'Crm::Api::admin::Steps',
      endpoint    => \&Crm::Api::admin::Steps::put_crm_step_step_id,
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'DELETE',
      path        => '/crm/step/:step_id/',
      controller  => 'Crm::Api::admin::Steps',
      endpoint    => \&Crm::Api::admin::Steps::delete_crm_step_step_id,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'GET',
      path        => '/crm/step/:step_id/',
      controller  => 'Crm::Api::admin::Steps',
      endpoint    => \&Crm::Api::admin::Steps::get_crm_step_step_id,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'GET',
      path        => '/crm/steps/',
      controller  => 'Crm::Api::admin::Steps',
      endpoint    => \&Crm::Api::admin::Steps::get_crm_steps,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'POST',
      path        => '/crm/workflow/',
      controller  => 'Crm::Api::admin::Workflow',
      endpoint    => \&Crm::Api::admin::Workflow::post_crm_workflow,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'POST',
      path        => '/crm/workflow/:id/',
      controller  => 'Crm::Api::admin::Workflow',
      endpoint    => \&Crm::Api::admin::Workflow::post_crm_workflow_id,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'POST',
      path        => '/crm/attachment/',
      controller  => 'Crm::Api::admin::Attachments',
      endpoint    => \&Crm::Api::admin::Attachments::post_crm_attachment,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/crm/attachment/:id/',
      controller  => 'Crm::Api::admin::Attachments',
      endpoint    => \&Crm::Api::admin::Attachments::delete_crm_attachment_id,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'GET',
      path        => '/crm/attachment/:id/content/',
      controller  => 'Crm::Api::admin::Attachments',
      endpoint    => \&Crm::Api::admin::Attachments::get_crm_attachment_id_content,
      content_type => 'Content-type: application/octet-stream',
      credentials => [
        'ADMINSID'
      ]
    },
    {
      method      => 'GET',
      path        => '/crm/sources/',
      controller  => 'Crm::Api::admin::Sources',
      endpoint    => \&Crm::Api::admin::Sources::get_crm_sources,
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'POST',
      path        => '/crm/leads/social/',
      params      => POST_CRM_LEADS_SOCIAL,
      controller  => 'Crm::Api::admin::Leads',
      endpoint    => \&Crm::Api::admin::Leads::post_crm_leads_social,
      credentials => [
        'BOT_UNREG', 'USERBOT'
      ]
    },
    {
      method      => 'POST',
      path        => '/crm/leads/dialogue/message/',
      params      => POST_CRM_LEADS_DIALOGUE_MESSAGE,
      controller  => 'Crm::Api::admin::Leads',
      endpoint    => \&Crm::Api::admin::Leads::post_crm_leads_dialogue_message,
      credentials => [
        'BOT_UNREG', 'USERBOT'
      ]
    },
  ];
}

1;
