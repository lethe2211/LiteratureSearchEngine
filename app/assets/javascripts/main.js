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

	var hovered = null;
	
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
		
		// set up some event handlers to allow for node-dragging
		that.initMouseHandling()
	    },
	    
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
		
		var nodeBoxes = {}
		
		if(hovered != null) {
		    ctx.fillStyle = "black";
		    ctx.fillText(hovered.node.name, hovered.point.x, hovered.point.y);
		    
		}

		particleSystem.eachNode(function(node, pt){
		    // node: {mass:#, p:{x,y}, name:"", data:{}}
		    // pt:   {x:#, y:#}  node position in screen coords
		    
		    var w = 10;
		    
		    if (node.data.shape=='dot'){
			//gfx.oval(pt.x-w/2, pt.y-w/2, w,w, {fill:ctx.fillStyle})
			nodeBoxes[node.name] = [pt.x-w/2, pt.y-w/2, w,w]
		    }else{
			//gfx.rect(pt.x-w/2, pt.y-10, w,20, 4, {fill:ctx.fillStyle})
			nodeBoxes[node.name] = [pt.x-w/2, pt.y-11, w, 22]
		    }
		    
		    // draw a rectangle centered at pt
		    ctx.fillStyle = (node.data.alone) ? "orange" : "black"
		    //ctx.fillRect(pt.x-w/2, pt.y-w/2, w,w)
		    ctx.beginPath();
		    ctx.arc(pt.x, pt.y, 3, 0, 2 * Math.PI, false);
		    ctx.fill();
		    if(hovered != null && hovered.node.name == node.name){
			ctx.fillStyle = "black";
			ctx.fillText(hovered.node.name, pt.x+10, pt.y-10);
		    }
		})
		
		particleSystem.eachEdge(function(edge, pt1, pt2){
		    // edge: {source:Node, target:Node, length:#, data:{}}
		    // pt1:  {x:#, y:#}  source position in screen coords
		    // pt2:  {x:#, y:#}  target position in screen coords
		    
		    var weight = edge.data.weight
		    var color = edge.data.color
		    
		    if (!color || (""+color).match(/^[ \t]*$/)) color = null
		    
		    
		    // find the start point
		    var tail = intersect_line_box(pt1, pt2, nodeBoxes[edge.source.name])
		    var head = intersect_line_box(tail, pt2, nodeBoxes[edge.target.name])
		    
		    // draw a line from pt1 to pt2
		    ctx.strokeStyle = "rgba(0,0,0, .333)"
		    ctx.lineWidth = 1
		    ctx.beginPath()
		    ctx.moveTo(pt1.x, pt1.y)
		    ctx.lineTo(pt2.x, pt2.y)
		    ctx.stroke()
		    
		    // draw an arrowhead if this is a -> style edge
		    if (edge.data.directed){
	    		ctx.save()
			// move to the head position of the edge we just drew
	    		var wt = !isNaN(weight) ? parseFloat(weight) : 1
	    		var arrowLength = 6 + wt
	    		var arrowWidth = 2 + wt
	    		ctx.fillStyle = (color) ? color : "#cccccc"
	    		ctx.translate(head.x, head.y);
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
	    
	    initMouseHandling:function(){
		// no-nonsense drag and drop (thanks springy.js)
		var dragged = null;
		
		var handler = {
		    
		    hovered:function(e) {

			var pos = $(canvas).offset();
			var _mouseP = arbor.Point(e.pageX-pos.left, e.pageY-pos.top);
			hovered = particleSystem.nearest(_mouseP);
			
			hovered = (hovered.distance < 20)? hovered : null;

			return false;
		    },

		    clicked:function(e){
			var pos = $(canvas).offset();
			_mouseP = arbor.Point(e.pageX-pos.left, e.pageY-pos.top)
			dragged = particleSystem.nearest(_mouseP);
			
			if (dragged && dragged.node !== null){
			    // while we're dragging, don't let physics move the node
			    dragged.node.fixed = true
			}
			
			$(canvas).bind('mousemove', handler.dragged)
			$(window).bind('mouseup', handler.dropped)

			return false
		    },

		    dragged:function(e){
			var pos = $(canvas).offset();
			var s = arbor.Point(e.pageX-pos.left, e.pageY-pos.top)
			
			if (dragged && dragged.node !== null){
			    var p = particleSystem.fromScreen(s)
			    dragged.node.p = p
			}
			
			return false
		    },
		    
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
	var sys = arbor.ParticleSystem(1000, 600, 0.5) // create the system with sensible repulsion/stiffness/friction
	sys.parameters({gravity:true}) // use center-gravity to make the graph settle nicely (ymmv)
	sys.renderer = Renderer("#citation_graph") // our newly created renderer will have its .init() method called shortly by sys...

	// var data = {
	// 	  nodes:{
	// 	      animals:{'color':'red','shape':'dot','label':'Animals'},
	// 	      dog:{'color':'green','shape':'dot','label':'dog'},
	// 	      cat:{'color':'blue','shape':'dot','label':'cat'}
	// 	  },
	// 	  edges:{
	// 	      animals:{ dog:{}, cat:{} }
	// 	  }
	// };
	// sys.graft(data);
	// sys.addEdge('cat', 'dog', {directed: true, weight: 3});

	// add some nodes to the graph and watch it go...
	sys.addEdge('a','b')
	sys.addEdge('a','c')
	sys.addEdge('a','d')
	sys.addEdge('a','e', {directed: true, weight: 3})
	sys.addNode('f', {alone:true, mass:.25})
	
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
    
    // helpers for figuring out where to draw arrows (thanks springy.js)
    var intersect_line_line = function(p1, p2, p3, p4)
    {
	var denom = ((p4.y - p3.y)*(p2.x - p1.x) - (p4.x - p3.x)*(p2.y - p1.y));
	if (denom === 0) return false // lines are parallel
	var ua = ((p4.x - p3.x)*(p1.y - p3.y) - (p4.y - p3.y)*(p1.x - p3.x)) / denom;
	var ub = ((p2.x - p1.x)*(p1.y - p3.y) - (p2.y - p1.y)*(p1.x - p3.x)) / denom;
	
	if (ua < 0 || ua > 1 || ub < 0 || ub > 1)  return false
	return arbor.Point(p1.x + ua * (p2.x - p1.x), p1.y + ua * (p2.y - p1.y));
    }
    
    var intersect_line_box = function(p1, p2, boxTuple)
    {
	var p3 = {x:boxTuple[0], y:boxTuple[1]},
        w = boxTuple[2],
        h = boxTuple[3]
	
	var tl = {x: p3.x, y: p3.y};
	var tr = {x: p3.x + w, y: p3.y};
	var bl = {x: p3.x, y: p3.y + h};
	var br = {x: p3.x + w, y: p3.y + h};
	
	return intersect_line_line(p1, p2, tl, tr) ||
            intersect_line_line(p1, p2, tr, br) ||
            intersect_line_line(p1, p2, br, bl) ||
            intersect_line_line(p1, p2, bl, tl) ||
            false
    }
    
})(this.jQuery)