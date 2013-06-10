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
	document.getElementById('corp_tab').innerHTML = @sides['Corp']
	document.getElementById('runner_tab').innerHTML = @sides['Runner']
	@switchToTab('corp_tab')
