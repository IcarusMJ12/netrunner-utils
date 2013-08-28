class @SettingsManager
    constructor: () ->
        @sets = $.uniq([card.id_set, card.set_name] for k, card of window.cards,
            false, (a) -> a[0])
        @sets = $.filter(@sets, (n) -> n[0] isnt 1)
        # standard sort wtfily converts keys to strings and is thus not numeric
        @sets = $.sortBy(@sets, (n) -> n[0])
        @filter_tab = $('#Settings_tab')
        for set in @sets
            f = $.create('<div>').css({width: '100%'})
            f.append($.create('<input checked>').css({float: 'left'}).attr('type', 'checkbox').data('id_set', set[0]))
            f.append($.create('<div>').css({float: 'left'}).html(set[1]))
            f.append('<div style="clear: both;"></div>')
            @filter_tab.append(f[0])
        apply = $.create('<div>').addClass('clickable').addClass('control').html('Apply')
        apply[0].onclick = () => @applyFilter()
        @filter_tab.append(apply)
    
    applyFilter: () ->
        $(document).trigger('filter_cards', (c) =>
            c["game_id"]? and c["id_set"] in ($(el).data('id_set') for el in @filter_tab.find("input:checked")))
