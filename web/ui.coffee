faction_color_map = @faction_color_map

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
        deck_div.style.display = "inline"
    deck = @decks[card.side]
    if deck.addCard(card)
        console.log("+"+card.name)
        @updateDeckDiv(deck_div, deck)
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
    @switchToTab('Corp_tab')
