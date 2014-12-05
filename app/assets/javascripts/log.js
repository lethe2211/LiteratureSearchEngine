// ボタンが押されたかどうかに応じて，ログを書き換える

$(document).ready(function() {

    var url = '../../change_relevance/' + gon.userid + '/' + gon.interface;

    // 「適合」ボタン
    $(".relevant").click(function() {

	var rank = $(".relevant").index(this) + 1;
	var iteration = $(this).data('iteration') || 1;

	switch (iteration) {
	case 1:
	    // 隣の「非適合」ボタンがdisabledなら戻しておく
	    var siblings = $(this).siblings(".irrelevant");
	    if (siblings.attr("disabled")) siblings.attr("disabled", false);
	    
	    // ログを書き換えて「適合」にする
	    $.get(url, {search_string: gon.query, rank: rank, relevance: 'relevant'}, function(json) {
		// alert("odd");
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

	$(this).data('iteration',iteration)

    });

    // 「非適合」ボタン
    $(".irrelevant").click(function() {

	var rank = $(".irrelevant").index(this) + 1;
	var iteration = $(this).data('iteration') || 1;

	switch (iteration) {
	case 1:
	    // 隣の「適合」ボタンがdisabledなら戻しておく
	    var siblings = $(this).siblings(".relevant");
	    if (siblings.attr("disabled")) siblings.attr("disabled", false);
	    
	    // ログを書き換えて「非適合」にする
	    $.get(url, {search_string: gon.query, rank: rank, relevance: 'irrelevant'}, function(json) {
		console.log(url);
		//alert("odd");
	    });

	    // 使えなくしておく
	    $(this).attr('disabled', true);
	    break;
	    
	case 2:
	    break;
	}
	iteration++;
	if (iteration > 2) iteration = 1;

	$(this).data('iteration',iteration)

    });

    // 「元に戻す」ボタン
    $(".undo").click(function() {

	var rank = $(".undo").index(this) + 1;
	var siblings = $(this).siblings();

	siblings.data('iteration', 1);
	
	$.get('../../change_relevance/' + gon.userid + '/' + gon.interface, {search_string: gon.query, rank: rank, relevance: 'none'}, function(json) {
	});

	siblings.attr("disabled", false);

    });

});












