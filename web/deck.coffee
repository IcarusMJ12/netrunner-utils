@decks =
	Corp: undefined,
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
	
	getIdentity: -> return if @identity? then @identity.name else '??'
	getSize: -> return @size
	getInfluence: -> return @current_influence

	addCard: (card) ->
		if card.side isnt @side
			return false
		if card.type is 'Agenda' and (card.faction isnt @faction and card.faction isnt 'Neutral')
			return false
		if card.type is 'Identity'
			@identity = card
			@faction = card.faction
			@removeInvalidAgendas()
			@recalculateInfluence()
			return true
		if @cards[card.card_id]?
			if @cards[card.card_id] == 3
				return false
			@cards[card.card_id] += 1
		else
			@cards[card.card_id] = 1
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
			@identity = undefined
			@removeInvalidAgendas()
			return true
		if not @cards[card.card_id]?
			return false
		@cards[card.card_id] -= 1
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

class CorpDeck extends BaseDeck
	constructor: (cards) ->
		super cards
		@side = 'Corp'
		@agenda_points = 0

	getAgendaPoints: -> return @agenda_points
	
	removeInvalidAgendas: ->
		for card_id, card_count of @cards
			card = @all_cards[card_id]
			if card.faction isnt @faction and card.faction isnt 'Neutral'
				@size -= card_count
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