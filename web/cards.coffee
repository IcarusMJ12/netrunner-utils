# cards indexed by card_id, i.e. serial number, which we will also use for card div ids
@cards = {}

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
        for card in card_array
            # fuck css selectors
            ls = document.getElementById(card.card_id)
            ls = $(ls).find('.card_leftside')[0]
            #rs = $("##{card.card_id}").find('.card_stats')[0]
            ls.onclick = do (card) ->
                () => $(document).trigger('add_to_deck', card)
            ls.oncontextmenu = do (card) ->
                () => $(document).trigger('remove_from_deck', card); return false
    
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

    onCardRemoved: (card) ->
        for bar in $(document.getElementById(card.card_id)).find('.progress_bar')
            if bar.style.display is "inline"
                bar.style.display = "none"
                return


class BaseCard
    constructor: (keywords) ->
        @card_id = keywords['card_id']
        @card_text = keywords['card_text']
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
    
    toDiv: ->
        maximum_index = if @type is 'Identity' then 0 else 2
        bar_width = 100 / (maximum_index + 1)
        """
        <div class='card' id="#{@card_id}">
            <div style="position: relative; float: left; z-index: 10; width: 100%;">
                <div class="card_header">
                    <div class="card_leftside">
                        <div class="card_name"#{if @is_unique then ' style="font-style: italic;"' else ''}>#{@short_name}</div>
                        <div class="card_subtype">#{if @subtype? then '('+@subtype+')' else ''}</div>
                    </div>
                    <div class="card_stats" onclick="expandCard('#{@card_id}')" oncontextmenu="collapseCard('#{@card_id}'); return false;">#{@getStats()}</div>
                </div>
                <div class="card_center">#{@card_text}</div>
                <div class="card_lower">#{if @flavor? then @flavor else '--'}</div>
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
        "#{@influence}&#8226;#{@cost}<"

class TrashableCard extends ShareableCard
    constructor: (keywords) ->
        super
        @trash_cost = keywords['trash_cost']

    getStats: ->
        "#{@influence}&#8226;#{@cost}<#{if @trash_cost? then @trash_cost else '-'}]"

class AgendaCard extends BaseCard
    constructor: (keywords) ->
        super
        @advancement_cost = keywords['advancement_cost']
        @agenda_points = keywords['agenda_points']

    getStats: ->
        "#{@advancement_cost}<#{@agenda_points}A"

class AssetCard extends TrashableCard

class EventCard extends ShareableCard

class HardwareCard extends ShareableCard

class ICECard extends ShareableCard
    constructor: (keywords) ->
        super
        @strength = keywords['strength']

    getStats: ->
        "#{@influence}&#8226;#{@cost}<#{@strength}S"

class IdentityCard extends BaseCard
    constructor: (keywords) ->
        super
        @base_link = keywords['base_link']
        @influence_limit = keywords['influence_limit']
        @min_deck_size = keywords['min_deck_size']

    getStats: ->
        "#{@influence_limit}&#8226;#{@min_deck_size}D#{if @base_link? then (@base_link + '~') else ''}"

class OperationCard extends ShareableCard

class ProgramCard extends ShareableCard
    constructor: (keywords) ->
        super
        @memory_cost = keywords['memory_cost']
        @strength = keywords['strength']

    getStats: ->
        "#{@influence}&#8226;#{@cost}<#{if @memory_cost is 2 then '#' else '@'} #{if @strength? then (@strength + 'S') else ''}"

class ResourceCard extends ShareableCard

class UpgradeCard extends TrashableCard

#TODO: this filter needs to be a feature of CardViewer
#for card in raw_card_data["cards"] when card["game_id"]?
for card in raw_card_data["cards"]
    @cards[card["card_id"]] = makeCard(card)