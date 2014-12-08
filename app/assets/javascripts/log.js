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
	    var siblingsNeither = $(this).siblings(".neither");
	    var siblingsIrrelevant = $(this).siblings(".irrelevant");
	    if (siblingsNeither.attr("disabled")) siblingsNeither.attr("disabled", false);
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

    // 「どちらでもない」ボタン
    $(".neither").click(function() {

	var rank = $(".neither").index(this) + 1;
	var iteration = $(this).data('iteration') || 1;

	switch (iteration) {
	case 1:
	    // 他のボタンがdisabledなら戻しておく
	    var siblingsRelevant = $(this).siblings(".relevant");
	    var siblingsIrrelevant = $(this).siblings(".irrelevant");
	    if (siblingsRelevant.attr("disabled")) siblingsRelevant.attr("disabled", false);
	    if (siblingsIrrelevant.attr("disabled")) siblingsIrrelevant.attr("disabled", false);	    

	    // ログを書き換えて「非適合」にする
	    $.get(url, {search_string: gon.query, rank: rank, relevance: 'neither'}, function(json) {
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
	    var siblingsNeither = $(this).siblings(".neither");
	    var siblingsRelevant = $(this).siblings(".relevant");
	    if (siblingsNeither.attr("disabled")) siblingsNeither.attr("disabled", false);
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












