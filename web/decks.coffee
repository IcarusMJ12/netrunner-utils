class @DecksViewer
    constructor: () ->
        @tab = $("#Decks_tab")[0]
        @sides = ['Corp', 'Runner']
        @populate()
        $(document).on('on_deck_saved', () => @populate())
    
    populate: ->
        result = ""
        for side in @sides
            result += "<div style='width: 100%'>#{side}</div>"
            deck_keys = localStorage["#{side}:decks"]
            if deck_keys?
                deck_keys = JSON.parse(deck_keys)
            else
                deck_keys = {}
            for deck_name, v of deck_keys
                result += "<div class='deck_list_item' style='width: 100%' onclick='$(document).trigger(\"load_deck\", [\"#{side}\", \"#{deck_name}\"])'> #{deck_name}</div>\n"
        @tab.innerHTML = result
