/*
 * Initialize library functionality for document.
 * Call this function once the DOM is loaded.
 * @param {Object} [options={}]
 * @param {Boolean} [options.initAccessKeys=true]
 * @param {Boolean} [options.assignCallbacks=true]
 * @param {Boolean} [options.assignShortcuts=true]
 */
function dlgInitControls( options ) {
  "use strict";

  /*
   * Get the node being the label of a control.
   * If there isn't a specific label element, return element itself.
   * @param {HTMLElement} control
   * @return {HTMLElement}
   */
  function labelNode(control) {
    var c = $(control)
    var label = $("label[for='"+c.attr('id')+"']");
    if (label.length == 0) label = c.closest('label');

    return (label.length == 0) ? c.context : label[0];
  }

  /*
   * "Activate" a control.
   * Focus text elements, simulate click on other elements.
   * @param {HTMLElement} control
   */
  function activateControl(control) {
    switch(control.tagName) {
      case 'INPUT':
      case 'TEXTAREA':
        control.focus();
        if (control.getAttribute('type') == 'checkbox') control.click();
        break;
      default:
        // When element is triggered using shortcut/access key it should remain
        // focused afterwards.
        control.focus();
        control.click();
    }
  }

  /*
   * Find substring of text node and wrap in another node.
   * @param {textNode} textNode
   * @param {regExp} regex - A regular expression matching exactly 3 groups,
   *   text before wrap, text to wrap and text after wrap.
   * @param {node} wrapNode - A newly cerated node, not yet attached to a parent.
   * @return {Boolean} - Whether regex matched text node's content.
   */
  function wrapText(textNode, regex, wrapNode) {
    var matches = textNode.nodeValue.match(regex);
    if (!matches) return false;

    textNode.nodeValue = matches[1];
    wrapNode.appendChild(document.createTextNode(matches[2]));
    textNode.parentNode.insertBefore(wrapNode, textNode.nextSibling);
    var suffixNode = document.createTextNode(matches[3]);
    textNode.parentNode.insertBefore(suffixNode, wrapNode.nextSibling);

    return true;
  }

  /*
   * Find control's access key in its label and wrap it in stylable element.
   * Warn if access key couldn't be found in label.
   * @param {HTMLElement} control
   */
  function initAccessKey(control) {
    var accessKey = control.attr('data-access-key');
    var label = labelNode(control);
    var textNodes = $.grep(label.childNodes, function(n) {
      return n.nodeType == Node.TEXT_NODE
    });
    if (textNodes.length < 1) return;

    var match = false;
    for ( var i=0, l=textNodes.length; i < l; i++ ) {
      var textNode = textNodes[i];
      var akNode = document.createElement('span');
      akNode.className = 'dlg-access-key';
      if (wrapText(
          textNode,
          RegExp('^([^'+accessKey+']*)('+accessKey+')(.*)', 'i'),
          akNode
        )
      ) {
        match = true
        break;
      }
    }
    if (!match)
      console.warn('No access key \''+accessKey+'\' found in label \''+textNode.nodeValue+'\'.')
  }

  /*
   * Initialize all access keys in document.
   */
  function initAccessKeys() {
    $('[data-access-key]').each(function() {
      initAccessKey($(this));
    });

    $(document).keydown(function(e) {
      if (e.key != 'Alt') return;
      $('.dlg-access-key').css('text-decoration', 'underline');
    });

    $(document).keyup(function(e) {
      if (e.key != 'Alt') return;
      $('.dlg-access-key').css('text-decoration', '');
      e.preventDefault();
    });

    // TODO: Stop super annoying bing sound on Alt keydown in HtmlDialog.
    $(document).keydown(function(e) {
      if (!e.altKey) return;
      var control = $('[data-access-key="'+e.key+'"]')[0]
      if (!control) return;

      activateControl(control);
      e.preventDefault();
    });
  }

  /*
   * Assign callbacks to elements with dlg-callback-* class.
   * Warn if callback method is missing.
   */
  function assignCallbacks() {
    $('[class*="dlg-callback-"]').each(function() {
      var control = $(this).context;

      // If an onclick attribute is already defined for the element,
      // don't attach a new one.
      // This is the case when the developer wants to call their custom
      // callback, that e.g. sends some form data too.
      // REVIEW: Should perhaps also detect event listeners here?
      if (control.getAttribute('onclick')) return;

      var action = control.className.match(/dlg-callback-(\S+)/)[1];
      var func = sketchup[action];
      if (typeof func === 'function') {
        console.log('Assign SU callback \''+action+'\' to control \''+control+'\'.')
        // Wrap callback in anonymous method to prevent event from being sent
        // as parameter. This seemed to cause infinite loop as it froze the
        // dialog.
        // TODO: Maybe send hash of data in all named fields? If so, document
        // how to get vars into fields in the first palce.
        $(control).click( { func: func }, function(e) { func() });
      } else {
        console.warn('Missing SU callback \''+action+'\'.');
      }
    });
  }

  /*
   * Assign shortcuts to document.
   */
  function assignShortcuts() {
    $(document).keydown(function(e) {
      switch (e.key) {
        case 'Enter':
          // For following focused elements Enter should not be used as
          // shortcut for "submitting" the dialog.
          var active = document.activeElement;
          if (active.tagName == 'BUTTON') return;
          if (active.tagName == 'A') return;
          if (active.tagName == 'TEXTAREA') return;
          if (active.tagName == 'INPUT' && active.type == 'checkbox') return;
          if (active.tagName == 'INPUT' && active.type == 'radio') return;
          // Enter is only be used as shortcut for the control that is
          // explicitly the default action. It's up to the extensiond eveloper
          // to add this to Ok, Yes and Close for each individual dialog.
          var control = $('.dlg-default-action')[0];
          if (control) activateControl(control);
          break;
        case 'Escape':
          var control = $('.dlg-callback-cancel')[0];
          control = control || $('.dlg-callback-no')[0];
          control = control || $('.dlg-callback-ok')[0];
          control = control || $('.dlg-callback-close')[0];
          if (control) activateControl(control);
          break;
        case 'F1':
          var control = $('.dlg-callback-help')[0];
          if (control) activateControl(control);
          break;
        default:
          return;
      }
      e.preventDefault();
    });
  }

  function initControls(options = {}) {
    if (!options.hasOwnProperty('initAccessKeys') || options['initAccessKeys']) {
      initAccessKeys();
    }
    if (!options.hasOwnProperty('assignCallbacks') || options['assignCallbacks']) {
      assignCallbacks();
    }
    if (!options.hasOwnProperty('assignShortcuts') || options['assignShortcuts']) {
      assignShortcuts();
    }
    $('.dlg-default-action').focus();
  }

  initControls(options);

}
