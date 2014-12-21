// ボタンが押されたかどうかに応じて，ログを書き換える

var ready = function() {

    var url = '../../../logs/update_relevance/' + gon.userid + '/' + gon.interface;

    // FIXME: なぜかgon.start_num，gon.end_numが使えないので，URLからこれらの値を取ってきている
    // 現在のURLからパラメータのハッシュを生成する
    var getUrlVars = function() { 
	var vars = {}, hash; 
	var hashes = window.location.href.slice(window.location.href.indexOf('?') + 1).split('&'); 
	for(var i = 0; i < hashes.length; i++) { 
            hash = hashes[i].split('='); 
	    vars[hash[0]] = hash[1];
	} 
	return vars; 
    };
    var params = getUrlVars();
    var start_num = (typeof params['start_num'] !== 'undefined') ? parseInt(params['start_num']) : 1;
    var end_num = (typeof params['end_num'] !== 'undefined') ? parseInt(params['end_num']) : 10;
    console.log(start_num);
    console.log(end_num);
    // 「適合」ボタン
    $(".relevant").click(function() {
	console.log('relevant!');
	var rank = $(".relevant").index(this);
	var $search_result_row = $(this).parents('.search_result_row');

	var iteration = $(this).data('iteration') || 1;
	
	switch (iteration) {
	case 1:
	    // 他のボタンがdisabledなら戻しておく
	    var siblingsPartiallyRelevant = $(this).siblings(".partially_relevant");
	    var siblingsIrrelevant = $(this).siblings(".irrelevant");
	    if (siblingsPartiallyRelevant.attr("disabled")) siblingsPartiallyRelevant.attr("disabled", false);
	    if (siblingsIrrelevant.attr("disabled")) siblingsIrrelevant.attr("disabled", false);
	    
	    // ログを書き換えて「適合」にする
	    $.get(url, { search_string: gon.query, start_num: start_num, end_num: end_num, rank: start_num + rank, relevance: 'relevant' }, function(json) {
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

	var rank = $(".partially_relevant").index(this);
	var $search_result_row = $(this).parents('.search_result_row');

	var iteration = $(this).data('iteration') || 1;

	switch (iteration) {
	case 1:
	    // 他のボタンがdisabledなら戻しておく
	    var siblingsRelevant = $(this).siblings(".relevant");
	    var siblingsIrrelevant = $(this).siblings(".irrelevant");
	    if (siblingsRelevant.attr("disabled")) siblingsRelevant.attr("disabled", false);
	    if (siblingsIrrelevant.attr("disabled")) siblingsIrrelevant.attr("disabled", false);	    

	    // ログを書き換えて「非適合」にする
	    $.get(url, { search_string: gon.query, start_num: start_num, end_num: end_num, rank: start_num + rank, relevance: 'partially_relevant' }, function(json) {
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

	var rank = $(".irrelevant").index(this);
	var $search_result_row = $(this).parents('.search_result_row');

	var iteration = $(this).data('iteration') || 1;

	switch (iteration) {
	case 1:
	    // 他のボタンがdisabledなら戻しておく
	    var siblingsPartiallyRelevant = $(this).siblings(".partially_relevant");
	    var siblingsRelevant = $(this).siblings(".relevant");
	    if (siblingsPartiallyRelevant.attr("disabled")) siblingsPartiallyRelevant.attr("disabled", false);
	    if (siblingsRelevant.attr("disabled")) siblingsRelevant.attr("disabled", false);
	    
	    // ログを書き換えて「非適合」にする
	    $.get(url, { search_string: gon.query, start_num: start_num, end_num: end_num, rank: start_num + rank, relevance: 'irrelevant' }, function(json) {
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

	var rank = $(".undo").index(this);
	var siblings = $(this).siblings();

	siblings.data('iteration', 1);
	
	$.get(url, { search_string: gon.query, start_num: start_num, end_num: end_num, rank: start_num + rank, relevance: 'none' }, function(json) {
	    console.log(url);
	});

	siblings.attr("disabled", false);

    });
}

$(document).ready(ready);
$(document).on('page:load', ready);












