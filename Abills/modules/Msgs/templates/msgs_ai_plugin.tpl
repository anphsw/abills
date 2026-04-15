<input type='hidden' name='PUTER_AI_MODEL' id='PUTER_AI_MODEL' value='%PUTER_AI_MODEL%'/>

<div class='card card-outline card-primary collapsed-card' id='ai-assist-card'>
  <div class='progress d-none' id='ai-progress' style='height:3px; border-radius:0; margin:-1px'>
    <div class='progress-bar progress-bar-striped progress-bar-animated bg-warning w-100'></div>
  </div>

  <div class='card-header'>
    <h3 class='card-title'>
      <i class='fas fa-robot mr-1 text-primary'></i> AI Assist
    </h3>
    <div class='card-tools'>
      <button type='button' class='btn btn-tool' data-card-widget='collapse'>
        <i class='fas fa-plus'></i>
      </button>
    </div>
  </div>

  <div class='card-body p-2'>
    <div class='d-flex bd-highlight w-100 align-items-stretch mb-2'>

      <div class='bd-highlight pr-2'>
        <button type='button' class='btn btn-warning h-100' id='btn-ai-suggest'>
          <i class='fas fa-magic'></i> AI
        </button>
      </div>

      <div class='flex-fill bd-highlight'>
        <select id='ai-generate-lang' class='form-control w-100' title='_{MSGS_GENERATION_LANGUAGE}_'>
          <option value=''>_{MSGS_AUTO}_</option>
          <option value='Ukrainian'>🇺🇦 Українська</option>
          <option value='Russian'>🇷🇺 Русский</option>
          <option value='English'>🇬🇧 English</option>
        </select>
      </div>

    </div>
    <div class='form-group mb-2'>
      <textarea id='PUBLIC_DSC' name='PUBLIC_DSC' class='form-control form-control-sm' rows='6'
                placeholder='_{MSGS_AI_ANSWER_WILL_APPEAR_HERE}_'>%PUBLIC_DSC%</textarea>
    </div>

    <div class='d-flex align-items-center mb-2'>
      <small class='text-muted mr-2 text-nowrap'>_{MSGS_TRANSLATE}_:</small>
      <div class='btn-group btn-group-sm w-100'>
        <button type='button' class='btn btn-outline-info btn-ai-translate' data-lang='Ukrainian'>🇺🇦 UA</button>
        <button type='button' class='btn btn-outline-info btn-ai-translate' data-lang='Russian'>🇷🇺 RU</button>
        <button type='button' class='btn btn-outline-info btn-ai-translate' data-lang='English'>🇬🇧 EN</button>
      </div>
    </div>

    <div id='ai-feedback-wrap' class='d-none mt-2 mb-1'>
      <div class='d-flex align-items-center justify-content-between'>
        <small class='text-muted'>_{MSGS_AI_WAS_HELPFUL}_?</small>
        <div class='btn-group btn-group-sm' id='ai-feedback-btns'>
          <button type='button' class='btn btn-outline-success' id='btn-ai-useful'
                  title='_{MSGS_AI_USEFUL}_'>
            <i class='fas fa-thumbs-up'></i> _{MSGS_AI_USEFUL}_
          </button>
          <button type='button' class='btn btn-outline-danger' id='btn-ai-not-useful'
                  title='_{MSGS_AI_NOT_USEFUL}_'>
            <i class='fas fa-thumbs-down'></i> _{MSGS_AI_NOT_USEFUL}_
          </button>
        </div>
      </div>
      <small id='ai-feedback-status' class='text-muted d-block mt-1 text-center'></small>
    </div>

    <div id='ai-followup-wrap' class='d-none mt-2'>
      <div class='input-group input-group-sm'>
    <textarea id='ai-followup-input' class='form-control form-control-sm' rows='2'
              placeholder='_{MSGS_AI_FOLLOWUP_PLACEHOLDER}_' style='resize:vertical'></textarea>
      </div>
      <div class='d-flex mt-1 gap-1'>
        <button type='button' class='btn btn-warning btn-sm flex-fill rounded-right-0' id='btn-ai-followup'>
          <i class='fas fa-paper-plane'></i> _{MSGS_ASK}_
        </button>
        <button type='button' class='btn btn-outline-secondary btn-sm rounded-left-0' id='btn-ai-followup-cancel'>
          <i class='fas fa-times'></i>
        </button>
      </div>
    </div>

    <div class='mt-2 mb-2' id='ai-actions-wrap' style='display:none'>
      <button type='button' class='btn btn-outline-warning btn-sm btn-block' id='btn-ai-show-followup'>
        <i class='fas fa-comment-dots'></i> _{MSGS_ASK_FOLLOWUP}_
      </button>
    </div>

    <div class='d-flex align-items-center justify-content-between mb-2'>
      <button type='button' class='btn btn-outline-secondary btn-sm btn-block' id='btn-ai-copy'>
        <i class='far fa-copy'></i> _{COPY}_
      </button>
    </div>

    <div class='d-flex align-items-center justify-content-between'>
      <button type='button' class='btn btn-outline-primary btn-sm btn-block' id='btn-ai-insert-to-reply'>
        <i class='fas fa-sign-in-alt'></i> _{MSGS_INSERT_TO_REPLY}_
      </button>
    </div>

    <small id='ai-status' class='text-muted d-block mt-1'></small>
  </div>
</div>
<script>
  jQuery(document).ready(function () {
    const puterAIModel = jQuery('#PUTER_AI_MODEL').val();
    const textarea = jQuery('#PUBLIC_DSC');
    const progress = jQuery('#ai-progress');
    const statusEl = jQuery('#ai-status');
    const btnSuggest = jQuery('#btn-ai-suggest');
    const btnCopy = jQuery('#btn-ai-copy');
    const btnInsert = jQuery('#btn-ai-insert-to-reply');
    const langSelect = jQuery('#ai-generate-lang');
    const replyTextarea = jQuery('#REPLY_TEXT');

    const followupWrap = jQuery('#ai-followup-wrap');
    const followupInput = jQuery('#ai-followup-input');
    const btnFollowup = jQuery('#btn-ai-followup');
    const btnFollowupCancel = jQuery('#btn-ai-followup-cancel');
    const actionsWrap = jQuery('#ai-actions-wrap');
    const btnShowFollowup = jQuery('#btn-ai-show-followup');
    const btnSendReply = jQuery('#btn-ai-send-reply');

    const feedbackWrap = jQuery('#ai-feedback-wrap');
    const feedbackStatus = jQuery('#ai-feedback-status');
    const btnUseful = jQuery('#btn-ai-useful');
    const btnNotUseful = jQuery('#btn-ai-not-useful');

    const SUGGEST_IDLE = '<i class="fas fa-magic"></i> AI';

    let conversationContext = [];
    let lastQuestion = '';

    function getTicketId() {
      return new URLSearchParams(window.location.search).get('chg');
    }

    function setLoading(active, msg, activeBtn) {
      progress.toggleClass('d-none', !active);
      btnCopy.prop('disabled', active);
      jQuery('.btn-ai-translate').prop('disabled', active);
      btnSuggest.prop('disabled', active);
      btnFollowup.prop('disabled', active);
      btnSendReply.prop('disabled', active);

      if (activeBtn) {
        activeBtn.html(active ? '<i class="fas fa-spinner fa-spin"></i>' : activeBtn.data('idle'));
      } else {
        btnSuggest.html(active ? '<i class="fas fa-spinner fa-spin"></i> ' + (msg || '_{MSGS_GENERATING}_') : SUGGEST_IDLE);
      }
    }

    function setStatus(msg, cls) {
      statusEl.text(msg);
      statusEl.attr('class', 'd-block mt-1 ' + (cls || 'text-muted'));
      if (cls === 'text-success') {
        setTimeout(function () {
          statusEl.text('');
        }, 3000);
      }
    }

    function typeWriter(text) {
      textarea.val('');
      let i = 0;
      const tick = function () {
        if (i < text.length) {
          textarea.val(textarea.val() + text.charAt(i++));
          textarea.scrollTop(textarea[0].scrollHeight);
          setTimeout(tick, 5);
        }
      };
      tick();
    }

    function showActionsAfterResponse(answer) {
      conversationContext.push({role: 'assistant', content: answer});
      actionsWrap.show();

      feedbackWrap.removeClass('d-none');
      feedbackStatus.text('');
      btnUseful.removeClass('btn-success').addClass('btn-outline-success').prop('disabled', false);
      btnNotUseful.removeClass('btn-danger').addClass('btn-outline-danger').prop('disabled', false);
    }

    function sendFeedback(status) {
      const ticketId = getTicketId();
      if (!ticketId) return;

      const question = lastQuestion;
      const answer = textarea.val().trim();

      btnUseful.prop('disabled', true);
      btnNotUseful.prop('disabled', true);

      sendRequest('/api.cgi/msgs/' + ticketId + '/ai_feedback', {
        status: status,
        question: question,
        answer: answer
      }, 'POST')
        .then(function () {
          if (status === 'useful') {
            btnUseful.removeClass('btn-outline-success').addClass('btn-success');
            feedbackStatus.html('<i class="fas fa-check text-success"></i> _{MSGS_AI_FEEDBACK_SAVED}_');
          } else {
            btnNotUseful.removeClass('btn-outline-danger').addClass('btn-danger');
            feedbackStatus.html('<i class="fas fa-check text-danger"></i> _{MSGS_AI_FEEDBACK_SAVED}_');
          }
          setTimeout(function () {
            feedbackStatus.text('');
          }, 3000);
        })
        .catch(function () {
          feedbackStatus.text('⚠ _{MSGS_AI_FEEDBACK_ERROR}_');
          btnUseful.prop('disabled', false);
          btnNotUseful.prop('disabled', false);
        });
    }

    btnUseful.on('click', function () {
      sendFeedback(1);
    });
    btnNotUseful.on('click', function () {
      sendFeedback(0);
    });

    let puterLoaderPromise = null;

    function loadPuter() {
      if (typeof puter !== 'undefined') return Promise.resolve();
      if (puterLoaderPromise) return puterLoaderPromise;
      puterLoaderPromise = new Promise(function (resolve, reject) {
        const s = document.createElement('script');
        s.src = 'https://js.puter.com/v2/';
        s.async = true;
        s.onload = resolve;
        s.onerror = function () {
          puterLoaderPromise = null;
          reject(new Error('Puter.js load error'));
        };
        document.head.appendChild(s);
      });
      return puterLoaderPromise;
    }

    btnSuggest.on('click', function () {
      const ticketId = getTicketId();
      if (!ticketId) return;

      conversationContext = [];
      actionsWrap.hide();
      followupWrap.addClass('d-none');

      setLoading(true);
      setStatus('_{MSGS_GENERATING_RESPONSE}_');

      sendRequest('/api.cgi/msgs/' + ticketId + '/ai_suggest', {language: langSelect.val()}, 'POST')
        .then(function (data) {
          if (!data.answer && data.prompt && puterAIModel) {
            return loadPuter().then(function () {
              const sys = data.system_prompt ? data.system_prompt + '\n' : '';
              conversationContext.push({role: 'user', content: sys + data.prompt});
              return puter.ai.chat(sys + data.prompt, {model: puterAIModel});
            }).then(function (result) {
              const answer = result.message.content;
              typeWriter(answer);
              showActionsAfterResponse(answer);
            });
          }
          const answer = typeof data === 'object' ? data.answer : data;
          typeWriter(answer);
          showActionsAfterResponse(answer);
        })
        .then(function () {
          setStatus('✓ _{MSGS_RESPONSE_GENERATED}_', 'text-success');
        })
        .catch(function (err) {
          console.error(err);
          setStatus('⚠ _{MSGS_GENERATION_ERROR}_', 'text-danger');
        })
        .finally(function () {
          setLoading(false);
        });
    });

    btnShowFollowup.on('click', function () {
      followupWrap.toggleClass('d-none');
      btnShowFollowup.toggleClass('d-none');
      if (!followupWrap.hasClass('d-none')) {
        followupInput.focus();
      }
    });

    btnFollowupCancel.on('click', function () {
      btnShowFollowup.toggleClass('d-none');
      followupWrap.addClass('d-none');
      followupInput.val('');
    });

    btnFollowup.on('click', function () {
      const ticketId = getTicketId();
      if (!ticketId) return;

      const question = followupInput.val().trim();
      if (!question) {
        setStatus('⚠ _{MSGS_ENTER_QUESTION}_', 'text-warning');
        return;
      }

      setLoading(true);
      setStatus('_{MSGS_GENERATING_RESPONSE}_');

      const currentAnswer = textarea.val().trim();
      conversationContext.push({role: 'user', content: question});
      lastQuestion = question;

      sendRequest('/api.cgi/msgs/' + ticketId + '/ai_suggest', {
        followup: question,
        context: currentAnswer,
        language: langSelect.val()
      }, 'POST')
        .then(function (data) {
          if (!data.answer && data.prompt && puterAIModel) {
            return loadPuter().then(function () {
              const sys = data.system_prompt ? data.system_prompt + '\n' : '';
              const messages = conversationContext.map(function (m) {
                return sys + (m.role === 'user' ? 'User: ' : 'Assistant: ') + m.content;
              }).join('\n') + '\n' + question;
              return puter.ai.chat(messages, {model: puterAIModel});
            }).then(function (result) {
              const answer = result.message.content;
              typeWriter(answer);
              showActionsAfterResponse(answer);
              followupInput.val('');
              followupWrap.addClass('d-none');
            });
          }
          const answer = typeof data === 'object' ? (data.answer || data) : data;
          typeWriter(answer);
          showActionsAfterResponse(answer);
          followupInput.val('');
          followupWrap.addClass('d-none');
        })
        .then(function () {
          setStatus('✓ _{MSGS_RESPONSE_GENERATED}_', 'text-success');
        })
        .catch(function (err) {
          console.error(err);
          setStatus('⚠ _{MSGS_GENERATION_ERROR}_', 'text-danger');
        })
        .finally(function () {
          setLoading(false);
          btnShowFollowup.toggleClass('d-none');
        });
    });

    followupInput.on('keydown', function (e) {
      if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault();
        btnFollowup.trigger('click');
      }
    });

    jQuery('.btn-ai-translate').on('click', function () {
      const lang = jQuery(this).data('lang');
      const text = textarea.val().trim();
      if (!text) {
        setStatus('⚠ _{MSGS_NO_TEXT_TO_TRANSLATE}_', 'text-warning');
        return;
      }

      setLoading(true);
      setStatus('_{MSGS_TRANSLATING}_');

      sendRequest('/api.cgi/msgs/ai_translate', {text: text, language: lang}, 'POST')
        .then(function (data) {
          if (!data.answer && data.prompt && puterAIModel) {
            return loadPuter().then(function () {
              const sys = data.system_prompt ? data.system_prompt + '\n' : '';
              return puter.ai.chat(sys + data.prompt, {model: puterAIModel});
            }).then(function (result) {
              typeWriter(result.message.content);
            });
          }
          typeWriter(typeof data === 'object' ? (data.translated || data.answer) : data);
        })
        .then(function () {
          setStatus('✓ _{MSGS_TRANSLATED}_', 'text-success');
        })
        .catch(function (err) {
          console.error(err);
          setStatus('⚠ _{MSGS_TRANSLATION_ERROR}_', 'text-danger');
        })
        .finally(function () {
          setLoading(false);
        });
    });

    btnCopy.on('click', function () {
      if (!textarea.val()) return;
      const orig = btnCopy.html();
      const done = function () {
        btnCopy.html('<i class="fas fa-check"></i> _{COPIED}_!');
        btnCopy.removeClass('btn-outline-secondary').addClass('btn-success');
        setTimeout(function () {
          btnCopy.html(orig);
          btnCopy.removeClass('btn-success').addClass('btn-outline-secondary');
        }, 2000);
      };
      if (navigator.clipboard) {
        navigator.clipboard.writeText(textarea.val()).then(done);
      } else {
        textarea[0].select();
        document.execCommand('copy');
        done();
      }
    });

    btnInsert.on('click', function () {
      if (!textarea.val()) return;
      replyTextarea.val(textarea.val());
    });
  });
</script>