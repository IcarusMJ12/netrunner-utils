class DeckViewer
    constructor: (@deck, @card_types) ->
        @side = @deck.side
        @deck_div = $("##{@side}_deck")[0]
        @expanded = $(@deck_div).find('.expanded')[0]
        @padding = $("##{@side}_padding")[0]
        @fields = $(@deck_div).find(".deck_field")
        @name = $("##{@side}_name")[0]
        @makeDeckExpandedDiv()
        $(document).on('deck_view_toggled', (side) => if side is @side then @toggleDeckView())
        $(document).on('on_deck_cleared', (side) => if side is @side then @onDeckCleared())
        $(document).on('on_card_added', (card) => if card.side is @side then @onCardAdded(card))
        $(document).on('on_card_removed', (card) => if card.side is @side then @onCardRemoved(card))
        $(document).on('on_deck_saved', (side, faction, identity, name) => if side is @side then @onDeckSaved())
        $(document).on('on_deck_loaded', (side, cards, identity, name) => if side is @side then @onDeckLoaded(name))
        $(document).on('on_tab_switch', (tab_id) => if tab_id is @side + '_tab' then @onTabSwitch())

    makeDeckExpandedDiv: ->
        width = 80 / (@card_types.length - 1)
        expanded_html = "<div style='width: 80%; position: relative; float: left;'>\n"
        expanded_html += "<table class=\"card_list\">\n"
        expanded_html += "<tr class=\"card_list\">\n"
        for card_type in @card_types
            if card_type isnt 'Identity'
                expanded_html += "<th class=\"card_list\" style='width: #{width}%'><div id=\"#{@side + '_' + card_type + '_count'}\" style='float: left;'>0x</div><div style='float: left; padding-left: 4px;'>#{card_type}</div></th>\n"
        expanded_html += "</tr>\n"
        expanded_html += "<tr class=\"card_list\">\n"
        for card_type in @card_types
            if card_type isnt 'Identity'
                expanded_html += "<td id=\"#{@side + '_' + card_type}\" class=\"card_list\" style='width: #{width}%'></td>"
        expanded_html += "</tr>\n"
        expanded_html += "</table>\n"
        expanded_html += "</div>\n"
        expanded_html += "<div style='float: right;'>\n"
        expanded_html += "<div class='control_inverted clickable' style='width:100%'; onclick=\"$(document).trigger('export_to_o8d', '#{@side}');\">Export (o8d)</div>\n"
        expanded_html += "<div class='control_inverted clickable' style='width:100%'; onclick=\"$(document).trigger('export_to_tsv', '#{@side}');\">Export (tsv)</div>\n"
        expanded_html += "<div class='control_inverted clickable' style='width:100%'; onclick=\"$(document).trigger('save_deck', ['#{@side}', $('##{@side}_name')[0].value]);\">Save</div>\n"
        expanded_html += "<div class='control_inverted clickable' style='width:100%'; onclick=\"$(document).trigger('clear_deck', '#{@side}');\">Clear</div>\n"
        expanded_html += "</div>\n"
        @expanded.innerHTML = expanded_html

    onDeckSaved: ->
        @updateDeckDiv()

    onDeckLoaded: (name) ->
        @updateDeckDiv()
        for type in @card_types
            if type isnt "Identity"
                count = @deck.fillOrderedDivsByType(type, $("##{@side}_#{type}"))
                $("##{@side}_#{type}_count")[0].innerHTML = count + 'x'
        @deck_div.style.display = 'inline'
        @padding.style.height = @deck_div.offsetHeight + 'px'
        @name.value = name

    onDeckCleared: ->
        @makeDeckExpandedDiv()
        @deck_div.style.display = 'none'
        @expanded.style.display = 'none'
        @updateDeckDiv()
        @padding.style.height = @deck_div.offsetHeight + 'px'

    toggleDeckView: ->
        if @expanded.style.display is 'inline'
            @expanded.style.display = 'none'
        else
            @expanded.style.display = 'inline'
        @padding.style.height = @deck_div.offsetHeight + 'px'

    updateDeckDiv: ->
        invalid_properties = @deck.validateDeck()
        for f in @fields
            if f.dataset.property in invalid_properties
                f.style.color = "red"
            else
                f.style.color = "black"
            value = $(f).find(".value")[0]
            value.innerHTML = @deck[f.dataset.property]()
            if f.dataset.property_limit?
                value.innerHTML += '/' + @deck[f.dataset.property_limit]()

    onCardAdded: (card) ->
        console.log("+"+card.name)
        @updateDeckDiv()
        if card.type isnt 'Identity'
            count = @deck.fillOrderedDivsByType(card.type, $("##{@side}_#{card.type}"))
            $("##{@side}_#{card.type}_count")[0].innerHTML = count + 'x'
        @deck_div.style.display = "inline"
        @padding.style.height = @deck_div.offsetHeight + 'px'

    onCardRemoved: (card) ->
        console.log("-"+card.name)
        @updateDeckDiv()
        if @deck.size == 0 and not @deck.identity?
            @deck_div.style.display = "none"
            @expanded.style.display = 'none'
            @padding.style.height = 0
            return
        if card.type isnt 'Identity'
            count = @deck.fillOrderedDivsByType(card.type, $("##{@side}_#{card.type}"))
            $("##{@side}_#{card.type}_count")[0].innerHTML = count + 'x'
        @padding.style.height = @deck_div.offsetHeight + 'px'
    
    onTabSwitch: () ->
        @padding.style.height = @deck_div.offsetHeight + 'px'

@switchToTab = (tab_id) ->
    target_tab = undefined
    for tab in $(".tab")
        if tab.id isnt tab_id
            tab.style.display = "none"
        else
            target_tab = tab
    target_tab.style.display = "inline"
    $(document).trigger('on_tab_switch', tab_id)

@initialize = () ->
    @card_viewer = new @CardViewer(@cards)
    @deck_viewers = [] #should never be accessed, but paranoidly putting them here so they don't get garbage-collected
    for side in ['Corp', 'Runner']
        @decks[side] = @makeDeck(side)
        @deck_viewers.push(new DeckViewer(@decks[side], @card_types_order[side]))
        @decks[side].loadLastDeck()
    @decks_viewer = new @DecksViewer()
    @settings = new @SettingsManager()
    @switchToTab('Corp_tab')
