escape = (s) ->
    return (''+s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#x27;').replace(/\//g,'&#x2F;')

onCardAdded = (card_id, index) ->
    card_div = document.getElementById(card_id)
    card_bars = card_div.getElementsByClassName("progress_bar")
    card_bars[index].style.display = "inline"

onCardRemoved = (card_id, index) ->
    card_div = document.getElementById(card_id)
    card_bars = card_div.getElementsByClassName("progress_bar")
    card_bars[index].style.display = "none"

@decks =
    Corp: undefined
    Runner: undefined

@makeDeck = (side) ->
    result = switch side
        when 'Corp' then new CorpDeck(@cards)
        when 'Runner' then new RunnerDeck(@cards)

class BaseDeck
    constructor: (cards) ->
        @all_cards = cards
        @cards = {}
        @current_influence = 0
        @identity = undefined
        @side = undefined
        @faction = undefined
        @size = 0
    
    getIdentity: -> return if @identity? then '<strong>' + @identity.name + '</strong> (' + @faction + ')' else '??'
    getSize: -> return @size
    getInfluence: -> return @current_influence

    getOrderedDivsByType: (type) ->
        result =[]
        for card_id, count of @cards
            if @all_cards[card_id].type is type
                result.push([@all_cards[card_id].name, count])
        result.sort( (a, b) -> if a[0].toLowerCase() > b[0].toLowerCase() then 1 else -1)
        return ("<div style=\"width: 100%; float: left;\">#{i[1] + ' ' + i[0]}</div>" for i in result).join('\n')

    addCard: (card) ->
        if card.side isnt @side
            return false
        if card.type is 'Identity'
            if @identity?
                onCardRemoved(@identity.card_id, 0)
            @identity = card
            onCardAdded(card.card_id, 0)
            @faction = card.faction
            @removeInvalidAgendas()
            @recalculateInfluence()
            return true
        if not card.influence? and ((card.faction isnt @faction and card.faction isnt 'Neutral') or not @faction?)
            return false
        if @cards[card.card_id]?
            if @cards[card.card_id] == 3
                return false
            @cards[card.card_id] += 1
        else
            @cards[card.card_id] = 1
        onCardAdded(card.card_id, @cards[card.card_id] - 1)
        @size += 1
        if card.type is 'Agenda'
            @agenda_points += card.agenda_points
        if card.faction isnt @faction and card.faction isnt 'Neutral'
            @current_influence += card.influence
        return true
    
    removeCard: (card) ->
        if card.side isnt @side
            return false
        if card.type is 'Identity' and card.card_id == @identity.card_id
            if @identity?
                onCardRemoved(@identity.card_id, 0)
            @identity = undefined
            @removeInvalidAgendas()
            return true
        if not @cards[card.card_id]?
            return false
        @cards[card.card_id] -= 1
        onCardRemoved(card.card_id, @cards[card.card_id])
        if @cards[card.card_id] == 0
            delete @cards[card.card_id]
        if card.type is 'Agenda'
            @agenda_points -= card.agenda_points
        if card.faction isnt @faction and card.faction isnt 'Neutral'
            @current_influence -= card.influence
        @size -= 1
        return true

    getInfluenceLimit: ->
        return if @identity? then @identity.influence_limit else 15

    getDeckSizeLimit: ->
        return if @identity? then @identity.min_deck_size else 45
    
    recalculateInfluence: ->
        @current_influence = 0
        for card_id, card_count of @cards
            card = @all_cards[card_id]
            if card.faction isnt @faction and card.faction isnt 'Neutral'
                @current_influence += card.influence * card_count
    
    validateDeck: ->
        invalid_properties = []
        if not @identity?
            invalid_properties.push('getIdentity')
        if @current_influence > @getInfluenceLimit()
            invalid_properties.push('getInfluence')
        if @size < @getDeckSizeLimit()
            invalid_properties.push('getSize')
        return invalid_properties

    makeOctgnCard: (card_id) ->
        card = @all_cards[card_id]
        return "<card qty=\"#{@cards[card_id]}\" id=\"#{card.id}\">#{escape(card.name)}</card>\n"

    toO8D: ->
        for card_id, count of @cards
            game_id = @all_cards[card_id].game_id
            break
        result = '<?xml version="1.0" encoding="utf-8" standalone="yes"?>\n'
        result += "<deck game=\"#{game_id}\">"
        result += "<section name=\"Identity\">"
        if @identity?
            result += "<card qty=\"1\" id=\"#{@identity.id}\">#{escape(@identity.name)}</card>\n"
        result += "</section>\n"
        result += "<section name=\"R&amp;D / Stack\">\n"
        result += (@makeOctgnCard(card_id) for card_id, count of @cards).join('')
        result += "</section>\n"
        result += "</deck>\n"

class CorpDeck extends BaseDeck
    constructor: (cards) ->
        super cards
        @side = 'Corp'
        @agenda_points = 0

    getAgendaPoints: -> return @agenda_points
    
    removeInvalidAgendas: ->
        for card_id, card_count of @cards
            card = @all_cards[card_id]
            if card.type is 'Agenda' and card.faction isnt @faction and card.faction isnt 'Neutral'
                @size -= card_count
                for i in [card_count-1..0]
                    onCardRemoved(card_id, i)
                @agenda_points -= card.agenda_points * card_count
                delete @cards[card_id]
    
    getAgendaPointLimit: ->
        return Math.floor(Math.max(@size, @getDeckSizeLimit())/5)*2 + 2

    validateDeck: ->
        invalid_properties = super
        min_agenda_points = @getAgendaPointLimit()
        if not(min_agenda_points <= @agenda_points <= min_agenda_points + 1)
            invalid_properties.push('getAgendaPoints')
        return invalid_properties

class RunnerDeck extends BaseDeck
    constructor: (cards) ->
        super cards
        @side = 'Runner'
    
    removeInvalidAgendas: ->
        return true
    
    validateDeck: ->
        super
