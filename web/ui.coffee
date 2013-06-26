@exportDeckToO8D = (side) ->
    deck = @decks[side]
    open("data:application/xml;charset=utf-8,#{encodeURIComponent(deck.toO8D())}")

@exportDeckToTSV = (side) ->
    deck = @decks[side]
    open("data:text/plain;charset=utf-8,#{encodeURIComponent(deck.toTSV())}")

@deleteDeck = (side) ->
    @makeDeckExpandedDiv(side, @card_types_order[side])
    delete @decks[side]
    deck = @makeDeck(side)
    deck_div = document.getElementById(side + '_deck')
    deck_div.style.display = 'none'
    deck_div.getElementsByClassName('expanded')[0].style.display = 'none'
    @updateDeckDiv(deck_div, deck)
    document.getElementById(side + '_padding').style.height = deck_div.offsetHeight + 'px'
    #TODO: fix bug clearing all bars regardless of side
    for bar in document.getElementsByClassName("progress_bar")
        bar.style.display = "none"

@toggleDeckView = (side) ->
    deck_div = $('#' + side + '_deck')
    expanded = $('.expanded', deck_div)[0]
    padding = $('#' + side + '_padding')
    if expanded.style.display is 'inline'
        console.log('-visible')
        expanded.style.display = 'none'
    else
        console.log('+visible')
        expanded.style.display = 'inline'
    padding[0].style.height = deck_div[0].offsetHeight + 'px'

@updateDeckDiv = (deck_div, deck) ->
    invalid_properties = deck.validateDeck()
    fields = deck_div.getElementsByClassName("deck_field")
    for f in fields
        if f.dataset.property in invalid_properties
            f.style.color = "red"
        else
            f.style.color = "black"
        value = f.getElementsByClassName("value")[0]
        value.innerHTML = deck[f.dataset.property]()
        if f.dataset.property_limit?
            value.innerHTML += '/' + deck[f.dataset.property_limit]()

@addToDeck = (card_id) ->
    card = @cards[card_id]
    deck_div = document.getElementById(card.side + '_deck')
    if not @decks[card.side]?
        @decks[card.side] = @makeDeck(card.side)
    deck = @decks[card.side]
    if deck.addCard(card)
        console.log("+"+card.name)
        @updateDeckDiv(deck_div, deck)
        if card.type isnt 'Identity'
            document.getElementById(card.side + '_' + card.type).innerHTML = deck.getOrderedDivsByType(card.type)
        else if card.side is 'Corp'
            document.getElementById(card.side + '_' + 'Agenda').innerHTML = deck.getOrderedDivsByType('Agenda')
        document.getElementById(card.side + '_padding').style.height = deck_div.offsetHeight + 'px'
        deck_div.style.display = "inline"

@removeFromDeck = (card_id) ->
    card = @cards[card_id]
    if not @decks[card.side]?
        return
    deck = @decks[card.side]
    if deck.removeCard(card)
        deck_div = document.getElementById(card.side + '_deck')
        console.log("-"+card.name)
        @updateDeckDiv(deck_div, deck)
        if deck.size == 0 and not deck.identity?
            delete @decks[card.side]
            deck_div.style.display = "none"
            deck_div.getElementsByClassName('expanded')[0].style.display = 'none'
            document.getElementById(card.side + '_padding').style.height = 0
            return
        if card.type isnt 'Identity'
            document.getElementById(card.side + '_' + card.type).innerHTML = deck.getOrderedDivsByType(card.type)
        document.getElementById(card.side + '_padding').style.height = deck_div.offsetHeight

@expandCard = (card_id) ->
    card = document.getElementById(card_id)
    card_center = card.getElementsByClassName("card_center")[0]
    card_lower = card.getElementsByClassName("card_lower")[0]
    if card_center.style.display is "inline"
        if card_lower.style.display is "inline"
            card_lower.style.display = "none"
            card_center.style.display = "none"
        else
            card_lower.style.display = "inline"
    else
        card_center.style.display = "inline"

@collapseCard = (card_id) ->
    card = document.getElementById(card_id)
    card_center = card.getElementsByClassName("card_center")[0]
    card_lower = card.getElementsByClassName("card_lower")[0]
    if card_center.style.display is "inline"
        if card_lower.style.display is "inline"
            card_lower.style.display = "none"
        else
            card_center.style.display = "none"
    else
        card_center.style.display = "inline"
        card_lower.style.display = "inline"

@switchToTab = (tab_id) ->
    tabs = document.getElementsByClassName("tab")
    target_tab = undefined
    for tab in tabs
        if tab.id isnt tab_id
            tab.style.display = "none"
        else
            target_tab = tab
    target_tab.style.display = "inline"

@makeDeckExpandedDiv = (side, card_types) ->
    width = 80 / (card_types.length - 1)
    expanded = document.getElementById(side + '_deck').getElementsByClassName('expanded')[0]
    expanded_html = "<div style='width: 80%; position: relative; float: left;'>\n"
    expanded_html += "<table class=\"card_list\">\n"
    expanded_html += "<tr class=\"card_list\">\n"
    for card_type in card_types
        if card_type isnt 'Identity'
            expanded_html += "<th class=\"card_list\" style='width: #{width}%'>#{card_type}</th>\n"
    expanded_html += "</tr>\n"
    expanded_html += "<tr class=\"card_list\">\n"
    for card_type in card_types
        if card_type isnt 'Identity'
            expanded_html += "<td id=\"#{side + '_' + card_type}\" class=\"card_list\" style='width: #{width}%'></td>"
    expanded_html += "</tr>\n"
    expanded_html += "</table>\n"
    expanded_html += "</div>\n"
    expanded_html += "<div style='float: right;'>\n"
    expanded_html += "<div class='control' style='width:100%'; onclick=exportDeckToO8D('#{side}')>Export (o8d)</div>\n"
    expanded_html += "<div class='control' style='width:100%'; onclick=exportDeckToTSV('#{side}')>Export (tsv)</div>\n"
    expanded_html += "<div class='control' style='width:100%'; onclick=deleteDeck('#{side}')>Delete</div>\n"
    expanded_html += "</div>\n"
    expanded.innerHTML = expanded_html

@initialize = () ->
    document.getElementById('Corp_viewer').innerHTML = @card_manager.toTable('Corp')
    document.getElementById('Runner_viewer').innerHTML = @card_manager.toTable('Runner')
    for side, card_types of @card_types_order
        @makeDeckExpandedDiv(side, card_types)
    @switchToTab('Corp_tab')
