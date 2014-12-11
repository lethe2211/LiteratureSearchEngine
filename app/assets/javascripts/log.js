// ボタンが押されたかどうかに応じて，ログを書き換える

$(document).ready(function() {

    var url = '../../../logs/update_relevance/' + gon.userid + '/' + gon.interface;

    // 「適合」ボタン
    $(".relevant").click(function() {

	var rank = $(".relevant").index(this) + 1;
	var iteration = $(this).data('iteration') || 1;

	switch (iteration) {
	case 1:
	    // 他のボタンがdisabledなら戻しておく
	    var siblingsPartiallyRelevant = $(this).siblings(".partially_relevant");
	    var siblingsIrrelevant = $(this).siblings(".irrelevant");
	    if (siblingsPartiallyRelevant.attr("disabled")) siblingsPartiallyRelevant.attr("disabled", false);
	    if (siblingsIrrelevant.attr("disabled")) siblingsIrrelevant.attr("disabled", false);
	    
	    // ログを書き換えて「適合」にする
	    $.get(url, {search_string: gon.query, rank: rank, relevance: 'relevant'}, function(json) {
		console.log(url);
	    });

	    // 使えなくしておく
	    $(this).attr('disabled', true);
	    break;
	    
	case 2:
	    break;
	}
	iteration++;
	if (iteration > 2) iteration = 1;

	$(this).data('iteration',iteration);

    });

    // 「部分的に適合」ボタン
    $(".partially_relevant").click(function() {

	var rank = $(".partially_relevant").index(this) + 1;
	var iteration = $(this).data('iteration') || 1;

	switch (iteration) {
	case 1:
	    // 他のボタンがdisabledなら戻しておく
	    var siblingsRelevant = $(this).siblings(".relevant");
	    var siblingsIrrelevant = $(this).siblings(".irrelevant");
	    if (siblingsRelevant.attr("disabled")) siblingsRelevant.attr("disabled", false);
	    if (siblingsIrrelevant.attr("disabled")) siblingsIrrelevant.attr("disabled", false);	    

	    // ログを書き換えて「非適合」にする
	    $.get(url, {search_string: gon.query, rank: rank, relevance: 'partially_relevant'}, function(json) {
		console.log(url);
	    });

	    // 使えなくしておく
	    $(this).attr('disabled', true);
	    break;
	    
	case 2:
	    break;
	}
	iteration++;
	if (iteration > 2) iteration = 1;

	$(this).data('iteration', iteration);

    });

    // 「非適合」ボタン
    $(".irrelevant").click(function() {

	var rank = $(".irrelevant").index(this) + 1;
	var iteration = $(this).data('iteration') || 1;

	switch (iteration) {
	case 1:
	    // 他のボタンがdisabledなら戻しておく
	    var siblingsPartiallyRelevant = $(this).siblings(".partially_relevant");
	    var siblingsRelevant = $(this).siblings(".relevant");
	    if (siblingsPartiallyRelevant.attr("disabled")) siblingsPartiallyRelevant.attr("disabled", false);
	    if (siblingsRelevant.attr("disabled")) siblingsRelevant.attr("disabled", false);
	    
	    // ログを書き換えて「非適合」にする
	    $.get(url, {search_string: gon.query, rank: rank, relevance: 'irrelevant'}, function(json) {
		console.log(url);
	    });

	    // 使えなくしておく
	    $(this).attr('disabled', true);
	    break;
	    
	case 2:
	    break;
	}
	iteration++;
	if (iteration > 2) iteration = 1;

	$(this).data('iteration',iteration);

    });

    // 「元に戻す」ボタン
    $(".undo").click(function() {

	var rank = $(".undo").index(this) + 1;
	var siblings = $(this).siblings();

	siblings.data('iteration', 1);
	
	$.get(url, {search_string: gon.query, rank: rank, relevance: 'none'}, function(json) {
	    console.log(url);
	});

	siblings.attr("disabled", false);

    });

});












