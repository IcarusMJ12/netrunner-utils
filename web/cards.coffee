# cards indexed by card_id, i.e. serial number, which we will also use for card div ids
@cards = {}

symbols =
    influence: '&#8226;'
    credit: '&#57344;'
    recurring_credit: '&#57345;'
    one_mu: '&#57346;'
    two_mu: '&#57347;'
    click: '&#57348;'
    trash: '&#57349;'
    subroutine: '&#57350;'
    link: '&#57351;'
    strength: '&#9889;'

@symbols = symbols

card_types_order =
    Corp: ["Identity", "Agenda", "Asset", "Upgrade", "ICE", "Operation"]
    Runner: ["Identity", "Event", "Program", "Hardware", "Resource"]

@card_types_order = card_types_order

factions_order =
    Corp: ["Haas-Bioroid", "Jinteki", "NBN", "Weyland Consortium", "Neutral"]
    Runner: ["Anarch", "Criminal", "Shaper", "Neutral"]

makeCard = (json) ->
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

class @CardViewer
    constructor: (cards) ->
        @cards = {}
        @viewers = {}
        card_array = (card for k, card of cards)
        card_array.sort( (a, b) -> if a.name.toLowerCase() > b.name.toLowerCase() then 1 else -1 )
        for card in card_array
            [side, faction, type] = [card['side'], card['faction'], card['type']]
            if not @cards[side]?
                @cards[side] = {}
                @viewers[side] = $("##{side}_viewer")[0]
            if not @cards[side][type]?
                @cards[side][type] = {}
            if not @cards[side][type][faction]?
                @cards[side][type][faction] = []
            @cards[side][type][faction].push(card)
        @populate()
        $(document).on('filter_cards', (filter_f) => @filter(filter_f))
        $(document).on('on_card_added', (card) => @onCardAdded(card))
        $(document).on('on_card_removed', (card) => @onCardRemoved(card))
        $(document).on('on_deck_cleared', (side) => @onDeckCleared(side))
        $(document).on('on_deck_loaded', (side, cards, identity, name) => @onDeckLoaded(side, cards, identity))
        $(document).on('card_expanded', (card) => @expandCard(card))
        $(document).on('card_collapsed', (card) => @collapseCard(card))
        for card in card_array
            # fuck css selectors
            card_div = document.getElementById(card.card_id)
            lhs = $(card_div).find('.card_leftside')[0]
            lhs.onclick = do (card) ->
                () => $(document).trigger('add_to_deck', card)
            lhs.oncontextmenu = do (card) ->
                () => $(document).trigger('remove_from_deck', card); return false
            rhs = $(card_div).find('.card_stats')[0]
            rhs.onclick = do (card) ->
                () => $(document).trigger('card_expanded', card)
            rhs.oncontextmenu = do (card) ->
                () => $(document).trigger('card_collapsed', card); return false
    
    populate: () ->
        for side, viewer of @viewers
            column_divisor = factions_order[side].length
            result = "<table class=\"card_viewer\">\n"
            result += "<tr class=\"card_viewer\">\n"
            for faction in factions_order[side]
                faction_class_name = faction.toLowerCase().replace(' ', '_')
                result += "<th class=\"card_viewer #{faction_class_name}\" style=\"width: #{100/column_divisor}%;\">#{faction}</th>\n"
            result += "</tr>\n"
            for type in card_types_order[side]
                result += "<tr class=\"card_viewer\">\n"
                for faction in factions_order[side]
                    faction_class_name = faction.toLowerCase().replace(' ', '_')
                    result += "<td class=\"card_viewer #{faction_class_name}\" style=\"width: #{100/column_divisor}%;\">\n"
                    if @cards[side][type][faction]?
                        for card in @cards[side][type][faction]
                            result += card.toDiv()
                    result += "</td>\n"
                result += "</tr>\n"
            result += "</table>"
            viewer.innerHTML = result

    filter: (filter_f) ->
        for card in $('.card')
            if filter_f(window.cards[card.id])
                card.style.display = "inline"
            else
                card.style.display = "none"

    onCardAdded: (card) ->
        for bar in $(document.getElementById(card.card_id)).find('.progress_bar')
            if bar.style.display is "none"
                bar.style.display = "inline"
                return

    onDeckCleared: (side) ->
        for bar in $("##{side}_viewer").find('.progress_bar')
            bar.style.display = "none"
    
    onDeckLoaded: (side, cards, identity) ->
        @onDeckCleared(side)
        for card_id, count of cards
            for i in [1..count]
                @onCardAdded(window.cards[card_id])
        if identity?
            @onCardAdded(identity)

    onCardRemoved: (card) ->
        bars = $(document.getElementById(card.card_id)).find('.progress_bar')
        for i in [bars.length-1..0]
            if bars[i].style.display is "inline"
                bars[i].style.display = "none"
                return

    expandCard: (card) ->
        card = document.getElementById(card.card_id)
        card_center = $(card).find(".card_center")[0]
        card_lower = $(card).find(".card_lower")[0]
        if card_center.style.display is "inline"
            if card_lower.style.display is "inline"
                card_lower.style.display = "none"
                card_center.style.display = "none"
            else
                card_lower.style.display = "inline"
        else
            card_center.style.display = "inline"

    collapseCard: (card) ->
        card = document.getElementById(card.card_id)
        card_center = $(card).find(".card_center")[0]
        card_lower = $(card).find(".card_lower")[0]
        if card_center.style.display is "inline"
            if card_lower.style.display is "inline"
                card_lower.style.display = "none"
            else
                card_center.style.display = "none"
        else
            card_center.style.display = "inline"
            card_lower.style.display = "inline"

class BaseCard
    constructor: (keywords) ->
        @card_id = keywords['card_id']
        @card_text = keywords['card_text']
        @card_text_formatted = @formatCardText(keywords['card_text'])
        @count = keywords['count']
        @faction = keywords['faction']
        @game_id = keywords['game_id']
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
        @short_name = @name.split(':')[if @side is 'Corp' and @type is 'Identity' then 1 else 0]
    
    formatCardText: (text) ->
        return text.replace(/\[Click\]/gi, window.symbols.click).
            replace(/\[Credits\]/gi, window.symbols.credit).
            replace(/\[Recurring Credits\]/gi, window.symbols.recurring_credit).
            replace(/\[Memory Unit\]/gi, window.symbols.one_mu).
            replace(/\[Link\]/gi, window.symbols.link).
            replace(/\[Trash\]/gi, window.symbols.trash).
            replace(/\[Subroutine\]/gi, window.symbols.subroutine).
            replace(/\r\n/g, '<br>')

    #TODO: replace this now that I know better
    toDiv: ->
        maximum_index = if @type is 'Identity' then 0 else 2
        bar_width = 100 / (maximum_index + 1)
        """
        <div class='card #{@card_id}' id="#{@card_id}">
            <div style="position: relative; float: left; z-index: 10; width: 100%;">
                <div class="card_header">
                    <div class="card_leftside clickable">
                        <div class="card_name"#{if @is_unique then ' style="font-style: italic;"' else ''}>#{@short_name}</div>
                        <div class="card_subtype">#{if @subtype? then '('+@subtype+')' else ''}</div>
                    </div>
                    <div class="card_stats clickable">#{@getStats()}</div>
                </div>
                <div class="card_center">#{@card_text_formatted}</div>
                <div class="card_lower">(#{@count}x #{@set_name})<br>#{if @flavor? then @flavor else '--'}</div>
            </div>
            #{("<div class=\"progress_bar\" style=\"width: #{bar_width}%;left: #{i*bar_width}%; display: none;\"></div>" for i in [0..maximum_index]).join('')}
            <div style="clear: both;"></div>
        </div>
        """
    
class ShareableCard extends BaseCard
    constructor: (keywords) ->
        super
        @cost = keywords['cost']
        @influence = keywords['influence']
    
    getStats: ->
        "#{@influence}#{symbols.influence}#{@cost}#{symbols.credit}"

class TrashableCard extends ShareableCard
    constructor: (keywords) ->
        super
        @trash_cost = keywords['trash_cost']

    getStats: ->
        "#{@influence}#{symbols.influence}#{@cost}#{symbols.credit}#{if @trash_cost? then @trash_cost else '-'}#{symbols.trash}"

class AgendaCard extends BaseCard
    constructor: (keywords) ->
        super
        @advancement_cost = keywords['advancement_cost']
        @agenda_points = keywords['agenda_points']

    getStats: ->
        "#{@advancement_cost}#{symbols.credit}#{@agenda_points}A"

class AssetCard extends TrashableCard

class EventCard extends ShareableCard

class HardwareCard extends ShareableCard

class ICECard extends ShareableCard
    constructor: (keywords) ->
        super
        @strength = keywords['strength']

    getStats: ->
        "#{@influence}#{symbols.influence}#{@cost}#{symbols.credit}#{@strength}#{symbols.strength}"

class IdentityCard extends BaseCard
    constructor: (keywords) ->
        super
        @base_link = keywords['base_link']
        @influence_limit = keywords['influence_limit']
        @min_deck_size = keywords['min_deck_size']

    getStats: ->
        "#{@influence_limit}#{symbols.influence}#{@min_deck_size}##{if @base_link? then (@base_link + symbols.link) else ''}"

class OperationCard extends ShareableCard

class ProgramCard extends ShareableCard
    constructor: (keywords) ->
        super
        @memory_cost = keywords['memory_cost']
        @strength = keywords['strength']

    getStats: ->
        "#{@influence}#{symbols.influence}#{@cost}#{symbols.credit}#{if @memory_cost is 2 then symbols.two_mu else symbols.one_mu} #{if @strength? then (@strength + symbols.strength) else ''}"

class ResourceCard extends ShareableCard

class UpgradeCard extends TrashableCard

#TODO: this filter needs to be a feature of CardViewer
#for card in raw_card_data["cards"] when card["game_id"]?
for card in raw_card_data["cards"]
    @cards[card["card_id"]] = makeCard(card)
