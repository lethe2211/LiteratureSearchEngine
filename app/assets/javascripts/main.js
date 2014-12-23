// Arbor.jsによるグラフの生成(コードが恐ろしいほど汚いので直す)
(function($) {

    var Renderer = function(canvas){
	var canvas = $(canvas).get(0);

	if (!canvas || !canvas.getContext) {
	    return false;
	}

	var ctx = canvas.getContext("2d");
	var gfx = arbor.Graphics(canvas);
	var particleSystem;

	var pos = arbor.Point(0, 0);
	var _mouseP = arbor.Point(0, 0);

	// グラフを描画するところのパディング
	var topPadding = 80;
	var rightPadding = 160;
	var bottomPadding = 80;
	var leftPadding = 160;

	var position = {};   // 各ノードの座標
	var hovered = null;  // 現在マウスホバーされているノードを表す
	var nodeVisualized = {}; // ノードが可視化されているかどうか
	var edgeVisualized = {}; // エッジが可視化されているかどうか

	var thresholdNumCitation = 100; // 被引用数によって，非検索結果論文ノードの数を削減する

	var that = {
	    init:function(system){
		//
		// the particle system will call the init function once, right before the
		// first frame is to be drawn. it's a good place to set up the canvas and
		// to pass the canvas size to the particle system
		//
		// save a reference to the particle system for use in the .redraw() loop
		particleSystem = system;
		
		// inform the system of the screen dimensions so it can map coords for us.
		// if the canvas is ever resized, screenSize should be called again with
		// the new dimensions
		particleSystem.screenSize(canvas.width, canvas.height);
		particleSystem.screenPadding(topPadding, rightPadding, bottomPadding, leftPadding);
		
		// マウスハンドラの初期化
		// set up some event handlers to allow for node-dragging
		that.initMouseHandling();

		// プルダウンメニューの初期化
		$("#num_citations").change(function() {
		    thresholdNumCitation = parseInt($(this).val());
		    console.log(thresholdNumCitation);
		});
	    },
	    
	    // ノードの位置が変わるごとに呼ばれる(ほぼ毎フレームと思ってよい？)
	    redraw:function(e){
		//
		// redraw will be called repeatedly during the run whenever the node positions
		// change. the new positions for the nodes can be accessed by looking at the
		// .p attribute of a given node. however the p.x & p.y values are in the coordinates
		// of the particle system rather than the screen. you can either map them to
		// the screen yourself, or use the convenience iterators .eachNode (and .eachEdge)
		// which allow you to step through the actual node objects but also pass an
		// x,y point in the screen's coordinate system
		//
		
		var isNodeHovered = false;
		var publishedYears = new Set(); // 発行年

		// console.log(_mouseP);
		// console.log(_mouseP.x);
		// console.log(_mouseP.y);

		var init_canvas = function(ctx, width, height) {
		    ctx.fillStyle = "white";
		    ctx.fillRect(0,0, width, height);
		}(ctx, canvas.width, canvas.height);

		// グラフの囲み線の描画
		var draw_surrouding_line = function(ctx, x, y, width, height) {
		    ctx.strokeStyle = "#99aaaa";
		    ctx.lineWidth = 3;
		    ctx.strokeRect(x, y, width, height);
		    ctx.fillStyle = "#EEFFFF";
		    ctx.fillRect(x, y, width, height);
		}(ctx, 30, 50, canvas.width - 50, canvas.height - 55);

		// 時系列を表す矢印の描画
		var draw__time_arrow = function(ctx, x, y, width) {
		    ctx.strokeStyle = "#99aaaa";
		    ctx.beginPath();
		    ctx.moveTo(x, y);
		    ctx.lineTo(x + width - 10, y);
		    ctx.lineWidth = 5;
		    ctx.closePath();
		    ctx.stroke();
		    ctx.fillStyle = "#99aaaa";
		    ctx.moveTo(x + width, y);
		    ctx.lineTo(x + width - 10, y + 10);
		    ctx.lineTo(x + width - 10, y - 10);
		    ctx.closePath();
		    ctx.fill();
		}(ctx, 50, canvas.height - 50, canvas.width - 80);



		// すべてのノードについて
		particleSystem.eachNode(function(node, pt){
		    // node: {mass:#, p:{x,y}, name:"", data:{}}
		    // pt:   {x:#, y:#}  node position in screen coords
		    
		    var type = node.data.type; // ノードタイプ
		    var numCitations = node.data.bibliography.num_citations;
		    var rank = node.data.rank; // 検索結果ノードのランキング

		    if (type == "search_result") {
			nodeVisualized[node.name] = true;
		    }
		    else {
			if (numCitations < thresholdNumCitation) {
			    nodeVisualized[node.name] = false;
			}
			else {
			    nodeVisualized[node.name] = true;
			}			
		    }

		    if (nodeVisualized[node.name]) {

			// ノードの半径を計算
			var r = function(node, type, rank) {
			    var r;	// ノード(円で表す)の半径
			    var weightType;	// ノードタイプによる半径の重み
			    var weightCitation = parseInt(numCitations);	// 被引用数による重み
			    var weightRank = parseInt(rank);	// 検索結果ノードのランクによる(逆)重み

			    if (type == "search_result") {
				weightType = 24;
				if (weightCitation < 100) {
				    weightCitation = 0.0;
				} else if (weightCitation < 1000) {
				    weightCitation = 4.0;
				} else {
				    weightCitation = 8.0;
				}
				// weightRank = -0.8 * node.data.rank;
				// weightRank = 0;
			    }
			    else {
				weightType = 8;
				if (weightCitation < 100) {
				    weightCitation = 0.0;
				} else if (weightCitation < 1000) {
				    weightCitation = 4.0;
				} else {
				    weightCitation = 8.0;
				}			    
				weightRank = 0;
			    }
			    r = weightType + weightCitation;
			    node.data.r = r; // プロパティrはノードの半径を表す
			    return r;
			}(node, type, rank);

			// ノードの位置決定
			var calculate_node_position = function(node, position) {
			    if (!(node.name in position)) {
				var x, y;
				if (node.data.bibliography.year) {
				    if (parseInt(node.data.bibliography.year) === 0) x = 0;
				    else x = parseInt(node.data.bibliography.year) - 2000;
				}
				else x = 0;
				y = Math.floor(Math.random() * 80); // '120 + 'を消したらノードが下に偏らなくなったけどよくわからない
		    		position[node.name] = arbor.Point(x, y);
		    		node.p = position[node.name]; // arbor.Pointは，代入される際に，x = 0, y = 0がcanvas要素の中心に来て，かつすべてのノードが画面内に収まるように座標変換されるらしい
			    }
			}(node, position);

			// ノードの円を描画
			var draw_circle_of_node = function(node, pt, r) {
			    ctx.fillStyle = node.data.color;
			    ctx.beginPath();
			    ctx.arc(pt.x, pt.y, r, 0, 2 * Math.PI, false);
			    // console.log(r);
			    ctx.fill();
			}(node, pt, r);

			// ノードの発行年情報を座標軸下に描画
			var draw_published_year = function(node) {
			    var year = node.data.bibliography.year;
			    if (!(publishedYears.has(parseInt(year))) && year && parseInt(year) !== 0) {
				ctx.fillStyle = "black";
				ctx.font = "normal 9px sans-serif";
				ctx.fillText(year, pt.x, canvas.height - 20);
				publishedYears.add(parseInt(year));
			    }
			}(node);
			
			// 検索結果ノードにランクを描画
			var overdraw_search_result_node = function(node, type) {
			    if (type == "search_result") {
				ctx.fillStyle = "white";
				ctx.font = "normal 20px sans-serif";
				
				if (rank <= 9) ctx.fillText(node.data.rank, pt.x - r / 4.0, pt.y + r / 4.0);
				else ctx.fillText(node.data.rank, pt.x - r / 4.0 - 8.0, pt.y + r / 4.0);
			    }
			}(node, type);

			// あるノードがホバーされている時に
			if(hovered !== null && hovered.node.name == node.name) {
			    isNodeHovered = true;
			}
		    }		    
		});

		var nearestEdge = null; // 最も近いエッジ
		var dist_nearestEdge = Infinity; // 最も近いエッジまでの距離
		var dist_edge_threshold = 10;	  // ホバーされたと判定する距離の上限

		// エッジに線を引く

		// すべてのエッジについて
		particleSystem.eachEdge(function(edge, pt1, pt2){
		    // edge: {source:Node, target:Node, length:#, data:{}}
		    // pt1:  {x:#, y:#}  source position in screen coords
		    // pt2:  {x:#, y:#}  target position in screen coords
		    
		    var weight = edge.data.weight; // エッジの重み
		    var color = edge.data.color;	  // エッジの色
		    
		    if (nodeVisualized[edge.source.name] && nodeVisualized[edge.target.name]) {
			edgeVisualized[[edge.source.name, edge.target.name]] = true;
		    }
		    else {
			edgeVisualized[[edge.source.name, edge.target.name]] = false;
		    }

		    if (edgeVisualized[[edge.source.name, edge.target.name]]) {

			if (!color || (""+color).match(/^[ \t]*$/)) color = null;

			var tail = arbor.Point(0, 0); // 有向枝の末尾座標

			// ノードの大きさに応じて矢印の長さを変更する
			if (edge.source.data.type == "search_result") {
			    tail = intersect_line_circle(pt2, pt1, edge.source.data.r);
			}
			else {
			    tail = intersect_line_circle(pt2, pt1, edge.source.data.r);
			}

			var head = arbor.Point(0, 0); // 有向枝の先頭座標

			if (edge.target.data.type == "search_result") {
			    head = intersect_line_circle(tail, pt2, edge.target.data.r);
			}
			else {
			    head = intersect_line_circle(tail, pt2, edge.target.data.r);
			}

			drawEdge(ctx, head, tail, edge, color, weight);
			// マウスカーソルに最も近いエッジを計算する

			// 点p1，p2からなる線分と，点pとの距離を求める
			// 点pが点p1，p2からなる長方形の外にある場合は，計算の対象外とする
			var dist_edge = (include_point_rect(_mouseP, pt1, pt2))? distance_point_line(_mouseP, pt1, pt2) : Infinity;
			if (dist_edge < dist_edge_threshold && dist_edge < dist_nearestEdge) {
		    	    // console.log("near");
			    nearestEdge = edge;
			    nearestEdge.data.head = head;
			    nearestEdge.data.tail = tail;
			    dist_nearestEdge = dist_edge;
			} else {
		    	    // console.log("not near");
			}
		    }		    
		});

		// ノードがホバーされている時の処理
		if (isNodeHovered) {
		    var type = hovered.node.data.type;
		    var color = hovered.node.data.color;
		    var numCitations = hovered.node.data.bibliography.num_citations;
		    var rank = hovered.node.data.rank;
		    var pt = particleSystem.toScreen(hovered.point); // ホバーされたノードのある座標

		    // ノードの半径を計算
		    var r = function(node, type, rank) {
		    	var r;	// ノード(円で表す)の半径
		    	var weightType;	// ノードタイプによる半径の重み
		    	var weightCitation = numCitations;
		    	var weightRank = rank;	// 検索結果ノードのランクによる(逆)重み

		    	if (type == "search_result") {
		    	    weightType = 24;
		    	    if (weightCitation < 100) {
		    		weightCitation = 0.0;
		    	    } else if (weightCitation < 1000) {
		    		weightCitation = 4.0;
		    	    } else {
		    		weightCitation = 8.0;
		    	    }
		    	    // weightRank = -0.8 * node.data.rank;
		    	    // weightRank = 0;
		    	}
		    	else {
		    	    weightType = 8;
		    	    if (weightCitation < 100) {
		    		weightCitation = 0.0;
		    	    } else if (weightCitation < 1000) {
		    		weightCitation = 4.0;
		    	    } else {
		    		weightCitation = 8.0;
		    	    }			    
		    	    // weightRank = 0;
		    	}
		    	r = weightType + weightCitation;
		    	node.data.r = r; // プロパティrはノードの半径を表す
		    	// console.log('hovered node: ' + node.data.r);
		    	return r;
		    }(hovered.node, type, rank);

		    // ノードを強調
		    if (type == "search_result") {
			ctx.fillStyle = "#3333EE";
			ctx.beginPath();
			ctx.arc(pt.x, pt.y, r + 3, 0, 2 * Math.PI, false);
			ctx.fill();

			ctx.fillStyle = "white";
			ctx.font = "normal 20px sans-serif";
			
			if (rank <= 9) ctx.fillText(hovered.node.data.rank, pt.x - r / 4.0, pt.y + r / 4.0);
			else ctx.fillText(hovered.node.data.rank, pt.x - r / 4.0 - 8.0, pt.y + r / 4.0);
		    }
		    else {
			ctx.fillStyle = (color == '#00ff00') ? color : "#333333";
			ctx.beginPath();
			ctx.arc(pt.x, pt.y, r + 3, 0, 2 * Math.PI, false);
			ctx.fill();
		    }

		    var title = hovered.node.data.bibliography.title;
		    // console.log(title);
		    // console.log(hovered.node.data.bibliography.authors);
		    var authors = hovered.node.data.bibliography.authors.join(", ");
		    var year = hovered.node.data.bibliography.year;
		    var bibliography = [title, authors, year];
		    
		    // 書誌情報を描画する
		    var drawTexts = function(ctx, texts, x, y, width, point) {
			ctx.fillStyle = "#000000";
			ctx.font = "normal 12px sans-serif";

			var lineCount = countTextLines(ctx, texts, width); // 実際に用いる行数の先読み
			var lineHeight = ctx.measureText("あ").width + 1.0; // 1行に用いる文字の高さ
			//console.log(lineCount);

			if (x < 0) {
			    x = 0;
			} else if (x > canvas.width - width) {
			    x = canvas.width - width;
			}

			if (y - 5 * texts.length - lineHeight * lineCount - 20 < 0) {
			    y = 5 * texts.length + lineHeight * lineCount + 20;
			}
 
			var balloonPos = arbor.Point(x, y - 5 * texts.length - lineHeight * lineCount - 20); // 吹き出しの左上座標

			// 吹き出しを描画する
			var drawBalloon = function(ctx, x, y, width, height, point) {
			    ctx.strokeStyle = "#A4A4A4";
			    ctx.fillStyle = "#FFFFFF";
			    ctx.beginPath();
			    ctx.lineWidth = 3;
			    ctx.moveTo(x, y);
			    ctx.lineTo(x + width, y);
			    ctx.lineTo(x + width, y + height);
			    ctx.lineTo(x + width / 2.0 + 10, y + height);
			    ctx.lineTo(point.x, point.y);
			    ctx.lineTo(x + width / 2.0 - 10, y + height);
			    ctx.lineTo(x, y + height);
			    ctx.lineTo(x, y);
			    ctx.closePath();
			    ctx.fill();
			    ctx.stroke();
			}(ctx, balloonPos.x, balloonPos.y, width,  5 * texts.length + lineHeight * lineCount + 20, point);
			// console.log(lineHeight);
			// console.log(lineCount);
			
			// 書誌情報の描画
			var fillBibliography = function(ctx, texts, x, y) {
			    // console.log(texts);
			    // console.log(x);
			    // console.log(y);
			    ctx.fillStyle = "#000000";
			    ctx.font = "normal 12px sans-serif";

			    if (texts.length === 0) {
				ctx.fillText("No citation contexts", x, y);
			    }
			    else {
				var count = 0;
				texts.forEach(function(text, i) {
				    // ctx.fillText('*', x, y + lineHeight * lineCount);
				    if (i === 0) {
					ctx.fillStyle = "#1155CC";
					ctx.font = "normal 12px sans-serif";
				    } else if (i == 1) {
					ctx.fillStyle = "#000000";
					ctx.font = "normal 10px sans-serif";
				    } else {
					ctx.fillStyle = "#000000";
					ctx.font = "normal 12px sans-serif";
				    }
				    var textSegments = multiLineText(ctx, text, width - 20); // 吹き出しに収めるため，1つのCitation contextを数行に分解したもの
				    textSegments.forEach(function(textSegment, j) {
					ctx.fillText(textSegment, x + 10, y + 5 * i + lineHeight * count);
					count += 1;
				    });
				});
			    }
			}(ctx, texts, balloonPos.x + 10, balloonPos.y + 15);
		    }(ctx, bibliography, pt.x - 250, pt.y - 20, 500, pt);
		}

		// エッジがホバーされている時の処理
		if (!isNodeHovered && nearestEdge) {
		    // console.log(nearestEdge);
		    // console.log(nearestEdge.data);
		    // console.log(nearestEdge.data.head);
		    // console.log(nearestEdge.data.tail);

		    var head = nearestEdge.data.head;
		    var tail = nearestEdge.data.tail;
		    var weight = nearestEdge.data.weight;

		    // マウスカーソルに最も近いエッジを強調する
		    drawEdge(ctx, head, tail, nearestEdge, "#FF7E00", 2 * weight);

		    // Citation contextがある場合，吹き出しの上に描画
		    var citationContexts = nearestEdge.data.bibliography.citation_context;
		    var middlePoint = particleSystem.toScreen(nearestEdge.source.p.add(nearestEdge.target.p).divide(2.0)); // 矢印の中点

		    var drawCitationContexts = function(ctx, citationContexts, x, y, width, point) {
			ctx.fillStyle = "#000000";
			ctx.font = "normal 12px sans-serif";

			var lineCount = countTextLines(ctx, citationContexts, width);
			var lineHeight = ctx.measureText("あ").width + 1.0;
			//console.log(lineCount);
			
			var balloonPos = arbor.Point(x, y - 5 * citationContexts.length - lineHeight * lineCount - 20); // 吹き出しの左上座標

			// 吹き出しの描画
			var drawBalloon = function(ctx, x, y, width, height, point) {
			    ctx.strokeStyle = "#A4A4A4";
			    ctx.fillStyle = "#FFFFFF";
			    ctx.beginPath();
			    ctx.lineWidth = 3;
			    ctx.moveTo(x, y);
			    ctx.lineTo(x + width, y);
			    ctx.lineTo(x + width, y + height);
			    ctx.lineTo(x + width / 2.0 + 10, y + height);
			    ctx.lineTo(point.x, point.y);
			    ctx.lineTo(x + width / 2.0 - 10, y + height);
			    ctx.lineTo(x, y + height);
			    ctx.lineTo(x, y);
			    ctx.closePath();
			    ctx.fill();
			    ctx.stroke();
			}(ctx, balloonPos.x, balloonPos.y, width, 5 * citationContexts.length + lineHeight * lineCount + 20, point);
			
			// Citation contextの描画
			var fillCitationContexts = function(ctx, texts, x, y) {
			    ctx.fillStyle = "#3F9933";
			    ctx.font = "normal 12px sans-serif";
			    // console.log(texts);
			    // console.log(x);
			    // console.log(y);

			    if (texts.length === 0) {
				ctx.fillText("No citation contexts", x, y);
			    }
			    else {
				var count = 0;
				texts.forEach(function(text, i) {
				    ctx.fillText('*', x, y + 5 * i + lineHeight * count);
				    var textSegments = multiLineText(ctx, text, width - 20);
				    textSegments.forEach(function(textSegment, j) {
					ctx.fillText(textSegment, x + 10, y + 5 * i + lineHeight * count);
					count += 1;
				    });
				});
			    }
			}(ctx, citationContexts, balloonPos.x + 10, balloonPos.y + 15);
		    }(ctx, citationContexts, middlePoint.x - 250, middlePoint.y - 20, 500, middlePoint);
		}

	    },
	    
	    // マウスハンドラの初期化
	    initMouseHandling:function(){
		var dragged = null; // ドラッグされているかどうか

		var mouseDownTime;
		var mouseUpTime;
		
		var handler = {
		    
		    // マウスホバー
		    hovered:function(e) {
			pos = $(canvas).offset(); // canvasの左上の位置
			_mouseP = arbor.Point(e.pageX-pos.left, e.pageY-pos.top); // 現在のマウスの相対位置
			// マウス位置から最も近いノードまでの距離が一定以下なら，そのノードをホバーしていることとする
			var dist = 20;
			hovered = particleSystem.nearest(_mouseP);
			hovered = (hovered.distance < dist)? hovered : null;

			return false;
		    },

		    // mousedown
		    clicked:function(e){
			mouseDownTime = new Date($.now()); // マウスが押された時の時刻
			
			pos = $(canvas).offset();
			_mouseP = arbor.Point(e.pageX-pos.left, e.pageY-pos.top);

			// マウス位置から最も近いノードをドラッグする
			dragged = particleSystem.nearest(_mouseP);

			if (dragged && dragged.node !== null){
			    // ドラッグ中は物理演算をしない
			    // while we're dragging, don't let physics move the node
			    dragged.node.fixed = true;
			}
			
			// ドラッグ中はmousemoveとmouseupに対してハンドラを設定
			$(canvas).bind('mousemove', handler.dragged);
			$(window).bind('mouseup', handler.dropped);

			return false;
		    },

		    // ドラッグ
		    dragged:function(e){
			pos = $(canvas).offset();
			_mouseP = arbor.Point(e.pageX-pos.left, e.pageY-pos.top);

			// あるノードがドラッグされているとき，そのノードはマウスを追う
			if (dragged && dragged.node !== null){
			    var p = particleSystem.fromScreen(_mouseP); // 画面左上からの距離
			    dragged.node.p = p;
			}
			
			return false;
		    },
		    
		    // mouseup
		    dropped:function(e){
			if (dragged===null || dragged.node===undefined) return;
			if (dragged.node !== null) dragged.node.fixed = false;

			if (dragged.node.data.type == "search_result") {

			    mouseUpTime = new Date($.now()); // マウスが離された時の時刻
			    // マウスが100ミリ秒以下の時間でクリックされたら(ドラッグされていなければ)
			    if (mouseUpTime - mouseDownTime < 100) {

				var rank = dragged.node.data.rank;
				var p = $(".search_result").eq(rank-1).offset().top;
				$("body").animate({ scrollTop: p - 50 }, "fast"); // 対応する検索結果まで移動

			    }

			}

			dragged.node.tempMass = 1000;
			dragged = null;
			$(canvas).unbind('mousemove', handler.dragged);
			$(window).unbind('mouseup', handler.dropped);
			// _mouseP = null

			return false;
		    }
		    
		};

		// start listening		
		$(canvas).mousemove(handler.hovered);
		$(canvas).mousedown(handler.clicked);
		
	    }
	    
	};

	// 有向グラフの矢印を引く
	var drawEdge = function(ctx, head, tail, edge, color, weight) {
	    var wt = !isNaN(weight) ? parseFloat(weight) : 1;

	    // draw a line from head to tail
	    ctx.strokeStyle = (color) ? color : "#cccccc";
	    ctx.lineWidth = wt / 5.0;
	    ctx.beginPath();
	    ctx.moveTo(tail.x,tail.y);
	    ctx.lineTo(head.x, head.y);
	    ctx.stroke();

	    // そのエッジが有向である場合，矢印の頭を書く
	    // draw an arrowhead if this is a -> style edge
	    if (edge.data.directed){
	    	ctx.save();
		// move to the head position of the edge we just drew
	    	var arrowLength = 2 + wt;
	    	var arrowWidth = 0 + wt;
	    	ctx.fillStyle = (color) ? color : "#cccccc";
	    	ctx.translate(head.x, head.y); // 座標変換？
	    	ctx.rotate(Math.atan2(head.y - tail.y, head.x - tail.x));
		
		// delete some of the edge that's already there (so the point isn't hidden)
	    	ctx.clearRect(-arrowLength/2,-wt/2, arrowLength/2,wt);
		
		// draw the chevron
	    	ctx.beginPath();
	    	ctx.moveTo(-arrowLength, arrowWidth);
	    	ctx.lineTo(0, 0);
	    	ctx.lineTo(-arrowLength, -arrowWidth);
	    	ctx.lineTo(-arrowLength * 0.8, -0);
	    	ctx.closePath();
	    	ctx.fill();
	    	ctx.restore();
	    }
	}

	return that;

    };
    
    $(document).ready(function() {

	// // アクションがresultでなければ関数を出ることで，ノードを読み込もうとするエラーを消す
	// // FIXME: できるならアクションごとに読み込むJavaScriptを変えるべき
	if (gon.action != "result") return;

	// 従来の検索エンジンが選択されている場合は，canvas要素を不可視化する必要がある
	if (parseInt(gon.interface) == 1) {
	    $("#citation_graph").hide();
	    return;
	}


	var canvas = $("canvas").get(0);
	var ctx = canvas.getContext("2d");

        $('#status').text('Composing graph');
	ctx.fillStyle = "black";
	ctx.font = "normal 24px sans-serif";
	ctx.fillText("Now Loading...", canvas.width / 2 - 100, canvas.height / 2);

	// Arbor.jsの初期化
	var sys = arbor.ParticleSystem(0, 0, 0); // create the system with sensible repulsion/stiffness/friction
	sys.parameters({gravity:false}); // use center-gravity to make the graph settle nicely (ymmv)

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

	// FIXME: なぜかgon.start_num，gon.end_numが使えないので，URLからこれらの値を取ってきている
	var params = getUrlVars();
	var start_num = (typeof params['start_num'] !== 'undefined') ? params['start_num'] : 1;
	var end_num = (typeof params['end_num'] !== 'undefined') ? params['end_num'] : 10;

	graph_url = '../../graph/' + gon.interface + "?search_string=" + gon.query + '&start_num=' + start_num + '&end_num=' + end_num;

	// JSONの読み込み
	$.getJSON(graph_url, function(json){
	    console.log(graph_url);
	    sys.renderer = Renderer("#citation_graph");
	    sys.graft(json);
	})
	    .success(function(json) {
		console.log("success");		
		// 実験モード
		isExperimentalMode = Cookie.getCookie('is_experimental_mode');
		if (isExperimentalMode === 'true') {
		    alert('Ready to search'); 		// ユーザへの通知
		    $('#citation_graph').show();
		    $('#search_results').show();
		    $('#other_search_results').show();

		    $('#countdown_timer').countdown('resume');
		    $.get(
		    	'../../../logs/resume_countdown/' + gon.userid + '/' + gon.interface,
		    	{ elapsed_time: calculateElapsedTime() },
		    	function(json) {console.log('../../../logs/resume_countdown/' + gon.userid + '/' + gon.interface);}
		    );
		} else {
		    $('.relevance').hide();
		}

		$('#status').text('Search completed');
		var url = '../../../logs/page_loaded/' + gon.userid + '/' + gon.interface;
		$.get(
		    url, 
		    { search_string: gon.query, start_num: start_num, end_num: end_num, elapsed_time: calculateElapsedTime() },
		    function(json) {console.log(url);}
		);
	    })
	    .error(function(jqXHR, textStatus, errorThrown) {
		console.log("error: " + textStatus);

		ctx.clearRect(0, 0, canvas.width, canvas.height);

		ctx.fillStyle = "black";
		ctx.font = "normal 24px sans-serif";
		ctx.fillText("Graph Loading Failed...", 150, 150);
		$('#status').text('Graph Loading Failed...');

		// TODO: グラフのロードが失敗した時のログ
		var url = '../../../logs/graph_load_failed/' + gon.userid + '/' + gon.interface;
		$.get(
		    url, 
		    { search_string: gon.query, start_num: start_num, end_num: end_num, elapsed_time: calculateElapsedTime() },
		    function(json) {console.log(url);}
		);
	    });

    });

    // 2点間の距離を求める
    var distance_point_point = function(p1, p2) {
	return Math.sqrt((p2.x - p1.x) * (p2.x - p1.x) + (p2.y - p1.y) * (p2.y - p1.y));
    };

    // 2点間の内積を求める
    var inner_product = function(p1, p2) {
	return p1.x * p2.x + p1.y * p2.y;
    };

    // 2点間の外積を求める
    var cross_product = function(p1, p2) {
	return p1.x * p2.y - p1.y * p2.x;
    };

    // 点p1とp2を通る直線と点pの距離を求める
    var distance_point_line = function(p, p1, p2) {
	var p1_p2 = {x: 0, y: 0};
	var p1_p = {x: 0, y: 0};

	p1_p2.x = p2.x - p1.x;
	p1_p2.y = p2.y - p1.y;
	p1_p.x = p.x - p1.x;
	p1_p.y = p.y - p1.y;

	var d = Math.abs(cross_product(p1_p2, p1_p));
	var l = distance_point_point(p1, p2);
	// console.log(d);
	// console.log(l);

	if (l > 0) {
	    return d / l;
	} else {
	    return 0;
	}
    };

    // 点p1とp2からなる長方形に点pが含まれているかどうかを返す
    // 対応しているのはx軸，y軸に平行な長方形のみ．p1，p2の位置は問わない
    var include_point_rect = function(p, p1, p2) {
	if (p1.x == p2.x && p1.y == p2.y) return 0;
	else {
	    var p1_p = {x: 0, y: 0};
	    var p1_p2 = {x: 0, y: 0};

	    p1_p.x = p.x - p1.x;
	    p1_p.y = p.y - p1.y;
	    p1_p2.x = p2.x - p1.x;
	    p1_p2.y = 0;

	    var intersect = inner_product(p1_p2, p1_p) / inner_product(p1_p2, p1_p2);

	    return (intersect >= 0 && intersect <= 1)? true : false;
	}
    };

    // 矢印の描画に必要
    // helpers for figuring out where to draw arrows (thanks springy.js)
    // 点p1, p2からなる直線(線分？)とp3, p4からなる直線の交点を求める
    var intersect_line_line = function(p1, p2, p3, p4)
    {
	var denom = ((p4.y - p3.y)*(p2.x - p1.x) - (p4.x - p3.x)*(p2.y - p1.y));
	if (denom === 0) return false // lines are parallel
	var ua = ((p4.x - p3.x)*(p1.y - p3.y) - (p4.y - p3.y)*(p1.x - p3.x)) / denom;
	var ub = ((p2.x - p1.x)*(p1.y - p3.y) - (p2.y - p1.y)*(p1.x - p3.x)) / denom;
	
	if (ua < 0 || ua > 1 || ub < 0 || ub > 1)  return false
	return arbor.Point(p1.x + ua * (p2.x - p1.x), p1.y + ua * (p2.y - p1.y));
    };
    
    // p1, p2からなる直線(線分？)と，長方形boxTupleの交点を求める
    var intersect_line_box = function(p1, p2, boxTuple)
    {
	var p3 = {x:boxTuple[0], y:boxTuple[1]}, // x: 当たり判定を計算する長方形のx座標 y: y座標
            w = boxTuple[2],			   // 長方形の幅
            h = boxTuple[3];			   // 長方形の長さ
	
	var tl = {x: p3.x, y: p3.y}; // 長方形の左上
	var tr = {x: p3.x + w, y: p3.y};
	var bl = {x: p3.x, y: p3.y + h};
	var br = {x: p3.x + w, y: p3.y + h};
	
	// 長方形のいずれかの辺と交点を持てば，長方形と交わっているとする
	return intersect_line_line(p1, p2, tl, tr) ||
            intersect_line_line(p1, p2, tr, br) ||
            intersect_line_line(p1, p2, br, bl) ||
            intersect_line_line(p1, p2, bl, tl) ||
            false;
    };

    // 点pから，半径rの円の中心pcまで直線を引いた際の交点のうち，pに近いものを求める
    var intersect_line_circle = function (p, pc, r) {
	// 点pからpcまでの距離
	var length = Math.sqrt((pc.x - p.x) * (pc.x - p.x) + (pc.y - p.y) * (pc.y - p.y));

	// 点pcからpまでの単位ベクトル
	var ex = (p.x - pc.x) / length;
	var ey = (p.y - pc.y) / length;

	// 点pcから(ex, ey)の向きに距離r離れた点が求める点
	var x = pc.x - r * ex;
	var y = pc.y - r * ey;

	// 求める点が点pと点pcの間にない場合，円を挟んで裏側の点を求めてしまっているので，入れ替える
	if ((x < pc.x && x > p.x) || (x < p.x && x > pc.x)) {
	    return arbor.Point(x, y);
	}
	else {
	    x = pc.x + r * ex;
	    y = pc.y + r * ey;
	    return arbor.Point(x, y);
	}
    };

    var multiLineText = function(context, text, width) {
	var len = text.length; 
	var strArray = [];
	var tmp = "";
	var i = 0;
	
	if( len < 1 ){
            //textの文字数が0だったら終わり
            return strArray;
	}
	
	for( i = 0; i < len; i++ ){
            var c = text.charAt(i);  //textから１文字抽出
            if( c == "\n" ){
		/* 改行コードの場合はそれまでの文字列を配列にセット */
		strArray.push( tmp );
		tmp = "";
		
		continue;
            }
	    
            /* contextの現在のフォントスタイルで描画したときの長さを取得 */
            if (context.measureText( tmp + c ).width <= width){
		/* 指定幅を超えるまでは文字列を繋げていく */
		tmp += c;
            }else{
		/* 超えたら、それまでの文字列を配列にセット */
		strArray.push( tmp );
		tmp = c;
            }
	}
	
	/* 繋げたままの分があれば回収 */
	if( tmp.length > 0 )
            strArray.push( tmp );
	
	return strArray;
    }

    var countTextLines = function(ctx, texts, width) {
	var count = 0;
	if (texts.length === 0) {
	    count = 1;
	} 
	else {
	    texts.forEach(function(text, i) {
		count += multiLineText(ctx, text, width).length;
	    });
	}
	return count;
    };

    var fillTextLine = function(ctx, text, x, y) {
	var textList = text.split('\n');
	var lineHeight = ctx.measureText("あ").width;
	textList.forEach(function(text, i) {
	    ctx.fillText(text, x, y + lineHeight * i);
	});
    };

    // 経過時間を計算する
    var calculateElapsedTime = function() {
	var experimentSeconds = 3600;
	var periods = $('#countdown_timer').countdown('getTimes');
        var remainingSeconds = $.countdown.periodsToSeconds(periods);
        var elapsedTime = experimentSeconds - remainingSeconds;
        return elapsedTime;
    };

})(this.jQuery);
