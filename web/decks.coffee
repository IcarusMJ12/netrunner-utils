class @DecksViewer
    constructor: () ->
        @_is_dirty = true
        @tab = $("#Decks_tab")[0]
        @cv = new ColumnView(@tab)
        $(document).on('on_deck_saved', (side, faction, identity, name) => @_is_dirty = true)
        $(document).on('on_deck_deleted', (side, name) => @_is_dirty = true; @populate())
        $(document).on('on_tab_switch', (tab_id) => if tab_id is 'Decks_tab' then @populate())
    
    populate: ->
        if not @_is_dirty
            return
        decks = { Corp: {}, Runner: {} }
        for side in $.keys(decks)
            deck_keys = localStorage["#{side}:decks"]
            if deck_keys?
                deck_keys = JSON.parse(deck_keys)
            else
                deck_keys = {}
            for deck_name, v of deck_keys
                deck = JSON.parse(localStorage["deck:#{deck_name}"])
                faction = if deck.faction? then deck.faction else '??'
                identity = if deck.identity? then window.cards[deck.identity].name else '??'
                if not decks[side][faction]?
                    decks[side][faction] = {}
                if not decks[side][faction][identity]?
                    decks[side][faction][identity] = ''
                decks[side][faction][identity] += """
                    <div id='deck_#{deck_name}' class='columnview_entry'>
                        <div class='clickable' style='display: inline-block;' onclick='$(document).trigger(\"load_deck\", [\"#{side}\", \"#{deck_name}\"])'>#{deck_name}</div>
                        <div class='clickable' style='display: inline-block;' onclick='$(document).trigger(\"delete_deck\", [\"#{side}\", \"#{deck_name}\"])'>&#9003;</div>
                    </div>
                """
        @cv.fill(decks)
        @_is_dirty = false
