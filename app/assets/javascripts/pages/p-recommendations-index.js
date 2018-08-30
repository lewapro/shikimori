import delay from 'delay';
import Turbolinks from 'turbolinks';

import ajaxCacher from 'services/ajax_cacher';
import inNewTab from 'helpers/in_new_tab';

page_load('recommendations_index', 'recommendations_favourites', async () => {
  // если страница ещё не готова, перегрузимся через 5 секунд
  if ($('p.pending').exists()) {
    const url = document.location.href;
    await delay(5000);

    if (url === document.location.href) {
      return Turbolinks.visit(document.location.href, true);
    }
  }

  $('body').on('mouseover', '.b-catalog_entry', function () {
    const $node = $(this);

    if (!window.SHIKI_USER.isSignedIn) { return; }
    if ($node.hasClass('entry-ignored')) { return; }

    if ($node.data('ignore_augmented')) {
      $node.data('ignore_button').show();
      return;
    }

    const title = I18n.t('frontend.pages.p_recommendations_index.dont_recommend_franchise');
    const $button = $(
      `<span class='controls'>
        <span class='delete mark-ignored' title='${title}'></span>
      </span>`
    ).appendTo($node.find('.image-cutter'));

    $node.data({
      ignore_augmented: true,
      ignore_button: $button
    });
  });

  $('body').on('mouseout', '.b-catalog_entry', function () {
    const $button = $(this).data('ignore_button');
    if ($button) { return $button.hide(); }
  });

  $('body').on('click', '.entry-ignored', e => {
    if (!inNewTab(e)) {
      return false;
    }
  });

  return $('body').on('click', '.b-catalog_entry .mark-ignored', function () {
    const $node = $(this).closest('.b-catalog_entry');
    const $link = $node.find('a').first();

    if ($link.attr('href').match(/(anime|manga)s\//)) {
      const target_type = RegExp.$1;
      const target_id = $node.prop('id');

      $.post('/recommendation_ignores', { target_type, target_id }, data => {
        const selector = data.map(v => `.entry-${v}`).join(',');
        $(selector).addClass('entry-ignored');
      });

      $node.addClass('entry-ignored');
      $(this).hide();
      ajaxCacher.reset();
    }
    return false;
  });
});