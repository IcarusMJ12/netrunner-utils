class @SettingsManager
    constructor: () ->
        @sets = $.uniq([card.setcode, card.set_name, card.set_id, card.card_id] for k, card of window.cards,
            false, (a) -> a[0])
        # filter out promo/game kit cards
        @sets = $.filter(@sets, (n) -> n[0] isnt "promos")
        # filter out cards we don't have the OCTGN set id, for now
        @sets = $.filter(@sets, (n) -> n[2]?)
        @sets = $.sortBy(@sets, (n) -> n[3])
        @filter_tab = $('#Settings_tab')
        @dirty = true
        last_sets = localStorage["filter"]
        if last_sets?
            last_sets = last_sets.split(',')
        for set in @sets
            f = $.create('<div>').css({width: '100%'})
            checkbox = $.create('<input checked>').css({float: 'left'}).
                attr('type', 'checkbox').data('setcode', set[0])
            if last_sets? and set[0] in last_sets
                checkbox[0].checked = false
            checkbox[0].onclick = () => @dirty = true
            f.append(checkbox[0])
            f.append($.create('<div>').css({float: 'left'}).html(set[1]))
            f.append('<div style="clear: both;"></div>')
            @filter_tab.append(f[0])
        $(document).on('on_tab_switch', (tab_id) => @applyFilter())
        @applyFilter()
    
    applyFilter: () ->
        if not @dirty
            return
        $(document).trigger('filter_cards', (c) =>
            c["game_id"]? and c["setcode"] in ($(el).data('setcode') for el in @filter_tab.find("input:checked")))
        localStorage["filter"] = ($(el).data('setcode') for el in @filter_tab.find("input:not(:checked)")).join(',')
        @dirty = false
