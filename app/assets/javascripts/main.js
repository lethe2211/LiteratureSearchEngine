//
//  main.js
//
//  A project template for using arbor.js
//

(function($){

    var Renderer = function(canvas){
	var canvas = $(canvas).get(0);

	var ctx = canvas.getContext("2d");
	var gfx = arbor.Graphics(canvas);
	var particleSystem;

	var position = {};	     // 各ノードの座標
	var hovered = null;	// 現在マウスホバーされているノードを表す
	
	var that = {
	    init:function(system){
		//
		// the particle system will call the init function once, right before the
		// first frame is to be drawn. it's a good place to set up the canvas and
		// to pass the canvas size to the particle system
		//
		// save a reference to the particle system for use in the .redraw() loop
		particleSystem = system
		
		// inform the system of the screen dimensions so it can map coords for us.
		// if the canvas is ever resized, screenSize should be called again with
		// the new dimensions
		particleSystem.screenSize(canvas.width, canvas.height)
		particleSystem.screenPadding(80) // leave an extra 80px of whitespace per side
		
		// マウスハンドラの初期化
		// set up some event handlers to allow for node-dragging
		that.initMouseHandling()
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
		ctx.fillStyle = "white"
		ctx.fillRect(0,0, canvas.width, canvas.height)
		
		// var nodeBoxes = {} // 矢印の描画に必要

		// すべてのノードについて
		particleSystem.eachNode(function(node, pt){
		    // node: {mass:#, p:{x,y}, name:"", data:{}}
		    // pt:   {x:#, y:#}  node position in screen coords
		    
		    // 幅wの時の
		    // var w = 10;

		    var r;	// ノード(円で表す)の半径

		    // if (!(node.name in position)) {

		    // 	position[node.name] = arbor.Point(parseInt(node.data.year) - 2000, Math.floor(Math.random() * 300));
		    // 	node.p = position[node.name];

		    // 	console.log(node.p);

		    // }

		    (node.data.type == "search_result")? r = 10: r = 5;
		    
		    // if (node.data.shape=='dot'){
		    // 		//gfx.oval(pt.x-w/2, pt.y-w/2, w,w, {fill:ctx.fillStyle})
		    // 		nodeBoxes[node.name] = [pt.x-w/2, pt.y-w/2, w,w]
		    // }else{
		    // 		//gfx.rect(pt.x-w/2, pt.y-10, w,20, 4, {fill:ctx.fillStyle})
		    // 		nodeBoxes[node.name] = [pt.x-w/2, pt.y-11, w, 22]
		    // }

		    // あるノードがホバーされているなら，そのノードの名前を描画(変更予定あり)
		    if(hovered != null && hovered.node.name == node.name) {
			ctx.fillStyle = "black";
			ctx.font = "normal 12px sans-serif";
			ctx.fillText(hovered.node.data.title, pt.x+10, pt.y-10);
			ctx.fillText(hovered.node.data.year, pt.x+10, pt.y+5);
		    }

		    // ノードの円を描画
		    ctx.fillStyle = node.data.color;
		    ctx.beginPath();
		    ctx.arc(pt.x, pt.y, r, 0, 2 * Math.PI, false);
		    ctx.fill();

		    if (node.data.type == "search_result") {

			ctx.fillStyle = "white";
			ctx.font = "normal 10px sans-serif";
			ctx.fillText(node.data.rank, pt.x - r / 4.0, pt.y + r / 4.0);

		    }
		    		    
		})

		// すべてのエッジについて
		particleSystem.eachEdge(function(edge, pt1, pt2){
		    // edge: {source:Node, target:Node, length:#, data:{}}
		    // pt1:  {x:#, y:#}  source position in screen coords
		    // pt2:  {x:#, y:#}  target position in screen coords
		    
		    var weight = edge.data.weight; // エッジの重み
		    var color = edge.data.color;	  // エッジの色
		    
		    if (!color || (""+color).match(/^[ \t]*$/)) color = null;
		    		    
		    // find the start point
		    // var tail = intersect_line_box(pt1, pt2, nodeBoxes[edge.source.name])
		    // var head = intersect_line_box(tail, pt2, nodeBoxes[edge.target.name])

		    var tail = arbor.Point(0, 0); // 有向枝の末尾座標

		    // ノードの大きさに応じて矢印の長さを変更する
		    if (edge.source.data.type == "search_result") {

		    	tail = intersect_line_circle(pt2, pt1, 10);

		    }
		    else {

		    	tail = intersect_line_circle(pt2, pt1, 5);

		    }

		    var head = arbor.Point(0, 0); // 有向枝の先頭座標

		    if (edge.target.data.type == "search_result") {

		    	head = intersect_line_circle(tail, pt2, 10);

		    }
		    else {

		    	head = intersect_line_circle(tail, pt2, 5);

		    }

		    console.log("tail: " + tail.x + " " + tail.y);
		    console.log("head: " + head.x + " " + head.y);

		    // エッジに線を引く
		    // draw a line from head to tail
		    ctx.strokeStyle = "rgba(0,0,0, .333)"
		    ctx.lineWidth = 1
		    ctx.beginPath()
		    ctx.moveTo(tail.x,tail.y)
		    ctx.lineTo(head.x, head.y)
		    ctx.stroke()
		    
		    // そのエッジが有向である場合，矢印の頭を書く
		    // draw an arrowhead if this is a -> style edge
		    if (edge.data.directed){
	    		ctx.save()
			// move to the head position of the edge we just drew
	    		var wt = !isNaN(weight) ? parseFloat(weight) : 1
	    		var arrowLength = 2 + wt
	    		var arrowWidth = 0 + wt
	    		ctx.fillStyle = (color) ? color : "#cccccc"
	    		ctx.translate(head.x, head.y); // 座標変換？
	    		ctx.rotate(Math.atan2(head.y - tail.y, head.x - tail.x));
			
			// delete some of the edge that's already there (so the point isn't hidden)
	    		ctx.clearRect(-arrowLength/2,-wt/2, arrowLength/2,wt)
			
			// draw the chevron
	    		ctx.beginPath();
	    		ctx.moveTo(-arrowLength, arrowWidth);
	    		ctx.lineTo(0, 0);
	    		ctx.lineTo(-arrowLength, -arrowWidth);
	    		ctx.lineTo(-arrowLength * 0.8, -0);
	    		ctx.closePath();
	    		ctx.fill();
	    		ctx.restore()
		    }
		    
		})

	
		
		
	    },
	    
	    // マウスハンドラの初期化
	    initMouseHandling:function(){

		var dragged = null; // ドラッグされているかどうか
		
		var handler = {
		    
		    // マウスホバー
		    hovered:function(e) {

			var pos = $(canvas).offset(); // canvasの左上の位置
			var _mouseP = arbor.Point(e.pageX-pos.left, e.pageY-pos.top); // 現在のマウスの相対位置
			// マウス位置から最も近いノードまでの距離が一定以下なら，そのノードをホバーしていることとする
			var dist = 20;
			hovered = particleSystem.nearest(_mouseP);
			hovered = (hovered.distance < dist)? hovered : null;

			return false;
		    },

		    // mousedown
		    clicked:function(e){
			var pos = $(canvas).offset();
			_mouseP = arbor.Point(e.pageX-pos.left, e.pageY-pos.top)

			// マウス位置から最も近いノードをドラッグする
			dragged = particleSystem.nearest(_mouseP);
			
			if (dragged && dragged.node !== null){
			    // ドラッグ中は物理演算をしない
			    // while we're dragging, don't let physics move the node
			    dragged.node.fixed = true
			}
			
			// ドラッグ中はmousemoveとmouseupに対してハンドラを設定
			$(canvas).bind('mousemove', handler.dragged)
			$(window).bind('mouseup', handler.dropped)

			return false
		    },

		    // ドラッグ
		    dragged:function(e){
			var pos = $(canvas).offset();
			var s = arbor.Point(e.pageX-pos.left, e.pageY-pos.top)
			
			// あるノードがドラッグされているとき，そのノードはマウスを追う
			if (dragged && dragged.node !== null){
			    var p = particleSystem.fromScreen(s) // 画面左上からの距離
			    dragged.node.p = p
			}
			
			return false
		    },
		    
		    // mouseup
		    dropped:function(e){
			if (dragged===null || dragged.node===undefined) return
			if (dragged.node !== null) dragged.node.fixed = false
			dragged.node.tempMass = 1000
			dragged = null
			$(canvas).unbind('mousemove', handler.dragged)
			$(window).unbind('mouseup', handler.dropped)
			_mouseP = null
			return false
		    }
		    
		}

		// start listening		
		$(canvas).mousemove(handler.hovered);
		$(canvas).mousedown(handler.clicked);
		
	    },
	    
	}
	return that
    }
    
    $(document).ready(function(){

	// 従来の検索エンジンが選択されている場合は，canvas要素を不可視化する必要がある
	if (parseInt(gon.interface) == 1) {

	    $("#citation_graph").hide();
	    return;

	}

	// Arbor.jsの初期化
	var sys = arbor.ParticleSystem(0, 0, 0) // create the system with sensible repulsion/stiffness/friction
	sys.parameters({gravity:false}) // use center-gravity to make the graph settle nicely (ymmv)
	sys.renderer = Renderer("#citation_graph") // our newly created renderer will have its .init() method called shortly by sys...

	// JSONの読み込み(static_pages/get_citationを呼び出すことで，コールバックにJSONが返ってくる)
	// var data = $.getJSON('send_graph',function(data){
	//     sys.graft({nodes:data.nodes, edges:data.edges})
	// })

	var data = gon.graph	// グラフのJSON

	sys.graft(data);

	// add some nodes to the graph and watch it go...
	// sys.addEdge('a','b')
	// sys.addEdge('a','c')
	// sys.addEdge('a','d')
	// sys.addEdge('a','e', {directed: true, weight: 3})
	// sys.addNode('f', {alone:true, mass:.25})
	
	// or, equivalently:
	//
	// sys.graft({
	//   nodes:{
	//     f:{alone:true, mass:.25}
	//   },
	//   edges:{
	//     a:{ b:{},
	//         c:{},
	//         d:{},
	//         e:{}
	//     }
	//   }
	// })

    })
    
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
    }
    
    // p1, p2からなる直線(線分？)と，長方形boxTupleの交点を求める
    var intersect_line_box = function(p1, p2, boxTuple)
    {
	var p3 = {x:boxTuple[0], y:boxTuple[1]},　 // x: 当たり判定を計算する長方形のx座標 y: y座標
        w = boxTuple[2],			   // 長方形の幅
        h = boxTuple[3]				   // 長方形の長さ
	
	var tl = {x: p3.x, y: p3.y}; // 長方形の左上
	var tr = {x: p3.x + w, y: p3.y};
	var bl = {x: p3.x, y: p3.y + h};
	var br = {x: p3.x + w, y: p3.y + h};
	
	// 長方形のいずれかの辺と交点を持てば，長方形と交わっているとする
	return intersect_line_line(p1, p2, tl, tr) ||
            intersect_line_line(p1, p2, tr, br) ||
            intersect_line_line(p1, p2, br, bl) ||
            intersect_line_line(p1, p2, bl, tl) ||
            false
    }

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


	console.log("p.x: " + p.x, " p.y: " + p.y);
	console.log("pc.x: " + pc.x, " pc.y: " + pc.y);
	console.log("x: " + x, " y: " + y);

	// 求める点が点pと点pcの間にない場合，円を挟んで裏側の点を求めてしまっているので，入れ替える
	if ((x < pc.x && x > p.x) || (x < p.x && x > pc.x)) {

	    return arbor.Point(x, y);

	}
	else {

	    x = pc.x + r * ex;
	    y = pc.y + r * ey;

	    return arbor.Point(x, y);

	}

    }
    
})(this.jQuery)