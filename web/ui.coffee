faction_color_map = @faction_color_map

@toggleDeckView = (side) ->
    deck_div = document.getElementById(side + '_deck')
    expanded = deck_div.getElementsByClassName('expanded')[0]
    padding = document.getElementById(side + '_padding')
    if expanded.style.display is 'inline'
        console.log('-visible')
        expanded.style.display = 'none'
    else
        console.log('+visible')
        expanded.style.display = 'inline'
    document.getElementById(side + '_padding').style.height = deck_div.offsetHeight + 'px'

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
        deck_div.style.display = "inline"
        console.log("+"+card.name)
        @updateDeckDiv(deck_div, deck)
        if card.type isnt 'Identity'
            document.getElementById(card.side + '_' + card.type).innerHTML = deck.getOrderedDivsByType(card.type)
        else if card.side is 'Corp'
            document.getElementById(card.side + '_' + 'Agenda').innerHTML = deck.getOrderedDivsByType('Agenda')
        document.getElementById(card.side + '_padding').style.height = deck_div.offsetHeight + 'px'

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

@initialize = () ->
    document.getElementById('Corp_viewer').innerHTML = @sides['Corp']
    document.getElementById('Runner_viewer').innerHTML = @sides['Runner']
    for side, card_types of @card_types_order
        console.log(side + " " + card_types)
        expanded = document.getElementById(side + '_deck').getElementsByClassName('expanded')[0]
        table = "<table class=\"card_list\">\n"
        table += "<tr class=\"card_list\">\n"
        width = 80 / (card_types.length - 1)
        for card_type in card_types
            if card_type isnt 'Identity'
                table += "<th class=\"card_list\" style='width: #{width}%'>#{card_type}</th>\n"
        table += "</tr>\n"
        table += "<tr class=\"card_list\">\n"
        for card_type in card_types
            if card_type isnt 'Identity'
                table += "<td id=\"#{side + '_' + card_type}\" class=\"card_list\" style='width: #{width}%'></td>"
        table += "</tr>\n"
        expanded.innerHTML = table
    @switchToTab('Corp_tab')
