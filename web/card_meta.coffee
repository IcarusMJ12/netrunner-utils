card_types_order =
	Corp: ["Identity", "Agenda", "Asset", "Upgrade", "ICE", "Operation"]
	Runner: ["Identity", "Event", "Program", "Hardware", "Resource"]

factions_order =
	Corp: ["Haas-Bioroid", "Jinteki", "NBN", "Weyland Consortium", "Neutral"]
	Runner: ["Anarch", "Criminal", "Shaper", "Neutral"]

@makeCard = (json) ->
	result = switch json['type']
		when 'Agenda' then new AgendaCard(json)
		when 'Asset' then new AssetCard(json)
		when 'Event' then new EventCard(json)
		when 'Hardware' then new HardwareCard(json)
		when 'ICE' then new ICECard(json)
		when 'Identity' then new IdentityCard(json)
		when 'Operation' then new OperationCard(json)
		when 'Program' then new ProgramCard(json)
		when 'Resource' then new ResourceCard(json)
		when 'Upgrade' then new UpgradeCard(json)

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

class @CardManager
	constructor: (cards) ->
		@cards = {}
		for card in cards
			[side, faction, type] = [card['side'], card['faction'], card['type']]
			if not @cards[side]?
				@cards[side] = {}
			if not @cards[side][type]?
				@cards[side][type] = {}
			if not @cards[side][type][faction]?
				@cards[side][type][faction] = []
			@cards[side][type][faction].push(card)
	
	toTable: (side) ->
		column_divisor = factions_order[side].length
		result = "<table>\n"
		result += "<tr>\n"
		for faction in factions_order[side]
			result+= "<th style=\"width: #{100/column_divisor}%\">#{faction}</th>\n"
		result += "</tr>\n"
		for type in card_types_order[side]
			result += "<tr>\n"
			for faction in factions_order[side]
				result += "<td style=\"width: #{100/column_divisor}%\">\n"
				if @cards[side][type][faction]?
					for card in @cards[side][type][faction]
						result += card.toDiv()
				result += "</td>\n"
			result += "</tr>\n"
		result += "</table>"
		return result

class BaseCard
	constructor: (keywords) ->
		@card_id = keywords['card_id']
		@card_text = keywords['card_text']
		@count = keywords['count']
		@faction = keywords['faction']
		@id = keywords['id']
		@is_unique = keywords['is_unique']
		@name = keywords['name']
		@rulings = keywords['rulings']
		@set_name = keywords['set_name']
		@side = keywords['side']
		@type = keywords['type']
		@flavor = keywords['flavor']
		@set_id = keywords['set_id']
		@illustrator = keywords['illustrator']
		@subtype = keywords['subtype']
	
	toDiv: ->
		"""
		<div class='card' id="#{@card_id}">
			<div class="card_header">
				<div class="card_leftside">
					<div class="card_name">#{(if @is_unique then '(u) ' else '') + @name.split(':')[if @side is 'Corp' and @type is 'Identity' then 1 else 0]}</div>
					<div class="card_subtype">#{if @subtype? then '('+@subtype+')' else ''}</div>
				</div>
				<div class="card_stats" onclick="expandCard('#{@card_id}')" oncontextmenu="collapseCard('#{@card_id}'); return false;">#{@getStats()}</div>
			</div>
			<div class="card_center">#{@card_text}</div>
			<div class="card_lower">#{if @flavor? then @flavor else '--'}</div>
		</div>
		"""


class ShareableCard extends BaseCard
	constructor: (keywords) ->
		super
		@cost = keywords['cost']
		@influence = keywords['influence']
	
	getStats: ->
		"#{@influence}/#{@cost}/-"

class TrashableCard extends ShareableCard
	constructor: (keywords) ->
		super
		@trash_cost = keywords['trash_cost']

	getStats: ->
		"#{@influence}/#{@cost}/#{if @trash_cost? then @trash_cost else '-'}"

class AgendaCard extends BaseCard
	constructor: (keywords) ->
		super
		@advancement_cost = keywords['advancement_cost']
		@agenda_points = keywords['agenda_points']

	getStats: ->
		"-/#{@advancement_cost}/#{@agenda_points}"

class AssetCard extends TrashableCard

class EventCard extends ShareableCard

class HardwareCard extends ShareableCard

class ICECard extends ShareableCard
	constructor: (keywords) ->
		super
		@strength = keywords['strength']

	getStats: ->
		"#{@influence}/#{@cost}/#{@strength}"

class IdentityCard extends BaseCard
	constructor: (keywords) ->
		super
		@base_link = keywords['base_link']
		@influence_limit = keywords['influence_limit']
		@min_deck_size = keywords['min_deck_size']

	getStats: ->
		"#{@influence_limit}/#{@min_deck_size}/#{if @base_link? then @base_link else '-'}"

class OperationCard extends ShareableCard

class ProgramCard extends ShareableCard
	constructor: (keywords) ->
		super
		@memory_cost = keywords['memory_cost']
		@strength = keywords['strength']

	getStats: ->
		"#{@influence}/#{@cost}/#{if @strength? then @strength else '-'}"

class ResourceCard extends ShareableCard

class UpgradeCard extends TrashableCard
