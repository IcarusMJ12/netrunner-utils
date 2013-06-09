@cards = (makeCard(card) for card in card_data["cards"] when card["game_id"]?)
@cards.sort( (a,b) -> a.name.toLowerCase() > b.name.toLowerCase() )

manager = new CardManager(@cards)
@sides = {'Corp': manager.toTable('Corp'), 'Runner': manager.toTable('Runner')}

@initialize = () ->
	document.getElementById('controls').innerHTML = """
		<div class="control" onclick="document.getElementById('main').innerHTML=sides['Corp']">Corp</div>
		<div class="control" onclick="document.getElementById('main').innerHTML=sides['Runner']">Runner</div>
	"""
	document.getElementById('main').innerHTML = @sides['Corp']
