# Copyright (c) 2008-2013 Michael Dvorkin and contributors.
#
# Fat Free CRM is freely distributable under the terms of MIT license.
# See MIT-LICENSE file or http://www.opensource.org/licenses/mit-license.php
#------------------------------------------------------------------------------
(($) ->

  $ ->
    $("#advanced_search").ransack_search_form()

    # For basic search, remove placeholder text on focus, restore on blur
    $('#query').focusin (e) ->
      $(this).data('placeholder', $(this).attr('placeholder')).attr('placeholder', '')
    $('#query').focusout (e) ->
      $(this).attr('placeholder', $(this).data('placeholder'))

    $(document).ajaxComplete ->
      if $('.ransack_search').length
        $("#loading").hide()
        $("#advanced_search").css('opacity', 1)

    # Search tabs
    # -----------------------------------------------------
    $(document).on 'click', '#search .tabs a', ->
      search_form = $(this).data('search-form') || $(this).data('parent-search-form')
      search_form_filter = $(this).data('search-form-filter') || $(this).data('parent-search-form-filter')
      search_form_filter_value = $(this).data('search-form-filter-value')
      # Hide all
      $('#search .search_form').hide()
      $('#search .tabs li a').removeClass('active')
      # Show selected
      $('#' + search_form).show()
      dataToSend = {}
      if search_form_filter || search_form_filter_value
        dataToSend["filter_by"] = search_form_filter
        dataToSend["filter_by_value"] = search_form_filter_value
        $('a[data-search-form-filter=' + search_form_filter + ']').addClass('active')
        $('a[data-search-form-filter-value=' + search_form_filter_value + ']').addClass('active')
      $('a[data-search-form=' + search_form + ']').addClass('active')
      # Run search for current query
      switch search_form
        when 'basic_search'
          query_input = $('#basic_search input#query')
          if !query_input.is('.defaultTextActive')
            dataToSend["value"] = query_input.val()
          else
            dataToSend["value"] = ""
          crm.search(dataToSend, window.controller)
          $('#filters').prop('disabled', false) # Enable filters panel (if present)

        when 'advanced_search'
          $('#advanced_search form input:submit').submit()
          $('#filters').prop('disabled', true) # Disable filters panel (if present)

      return

    # Update URL in browser #434
    $(document).on 'click', '#advanced_search form input:submit', ->
      # history.pushState(stateObj, title, url)
      history.pushState("","",window.location.pathname + '?' + $('form.ransack_search').serialize())
      return

) jQuery
