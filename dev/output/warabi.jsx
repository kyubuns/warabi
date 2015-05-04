/*
Script: RectanglePacker.js
	An algorithm implementation in JavaScript for rectangle packing.

Author:
	Iván Montes <drslump@drslump.biz>, <http://blog.netxus.es>

License:
	LGPL - Lesser General Public License

Credits:
	- Algorithm based on <http://www.blackpawn.com/texts/lightmaps/default.html>
*/

/*
	Class: NETXUS.RectanglePacker
	A class that finds an 'efficient' position for a rectangle inside another rectangle
	without overlapping the space already taken.
	
	Algorithm based on <http://www.blackpawn.com/texts/lightmaps/default.html>
	
	It uses a binary tree to partition the space of the parent rectangle and allocate the 
	passed rectangles by dividing the partitions into filled and empty.
*/


// Create a NETXUS namespace object if it doesn't exists
if (typeof NETXUS === 'undefined')
	var NETXUS = function() {};		
	

/*	
	Constructor: NETXUS.RectanglePacker
	Initializes the object with the given maximum dimensions
	
	Parameters:
	
		width - The containing rectangle maximum width as integer
		height - The containing rectangle maximum height as integer
		
*/	
NETXUS.RectanglePacker = function ( width, height ) {
	
	this.root = {};

	// initialize
	this.reset( width, height );	
}


/*
	Resets the object to its initial state by initializing the internal variables

	Parameters:
	
		width - The containing rectangle maximum width as integer
		height - The containing rectangle maximum height as integer
*/
NETXUS.RectanglePacker.prototype.reset = function ( width, height ) {
	this.root.x = 0;
	this.root.y = 0;
	this.root.w = width;
	this.root.h = height;
	delete this.root.lft;
	delete this.root.rgt;
	
	this.usedWidth = 0;
	this.usedHeight = 0;	
}
	

/*
	Returns the actual used dimensions of the containing rectangle.
	
	Returns:
	
		A object composed of the properties: 'w' for width and 'h' for height. 
*/
NETXUS.RectanglePacker.prototype.getDimensions = function () {
	return { w: this.usedWidth, h: this.usedHeight };	
}
	
	
/*
 	Finds a suitable place for the given rectangle
 	
	Parameters:
	
		w - The rectangle width as integer.
		h - The rectangle height as integer.
		
	Returns:
	
		If there is room for the rectangle then returns the coordinates as an object 
		composed of 'x' and 'y' properties. 
		If it doesn't fit returns null
*/  	
NETXUS.RectanglePacker.prototype.findCoords = function ( w, h ) {
	
	// private function to traverse the node tree by recursion
	function recursiveFindCoords ( node, w, h ) {

		// private function to clone a node coords and size
		function cloneNode ( node ) {
			return {
				x: node.x,
				y: node.y,
				w: node.w,
				h: node.h	
			};
		}		
		
		// if we are not at a leaf then go deeper
		if ( node.lft ) {
			// check first the left branch if not found then go by the right
			var coords = recursiveFindCoords( node.lft, w, h );
			return coords ? coords : recursiveFindCoords( node.rgt, w, h );	
		}
		else
		{
			// if already used or it's too big then return
			if ( node.used || w > node.w || h > node.h )
				return null;
				
			// if it fits perfectly then use this gap
			if ( w == node.w && h == node.h ) {
				node.used = true;
				return { x: node.x, y: node.y };
			}
			
			// initialize the left and right leafs by clonning the current one
			node.lft = cloneNode( node );
			node.rgt = cloneNode( node );
			
			// checks if we partition in vertical or horizontal
			if ( node.w - w > node.h - h ) {
				node.lft.w = w;
				node.rgt.x = node.x + w;
				node.rgt.w = node.w - w;	
			} else {
				node.lft.h = h;
				node.rgt.y = node.y + h;
				node.rgt.h = node.h - h;							
			}
			
			return recursiveFindCoords( node.lft, w, h );		
		}
	}
		
	// perform the search
	var coords = recursiveFindCoords( this.root, w, h );
	// if fitted then recalculate the used dimensions
	if (coords) {
		if ( this.usedWidth < coords.x + w )
			this.usedWidth = coords.x + w;
		if ( this.usedHeight < coords.y + h )
			this.usedHeight = coords.y + h;
	}
	return coords;
}

if(false){ alert('trap') }
// Generated by CoffeeScript 1.9.1
(function() {
  var border, createAlpha, findOrCreateAlphaChannel, main, selectTransparentArea, setup, sort, targetLayerSet;

  if (app.documents.length === 0) {
    alert('対象のpsdを開いてから実行してください。');
    return;
  }

  if (app.activeDocument.activeLayer.typename !== 'LayerSet') {
    alert('対象のLayerSetを選択してください。');
    return;
  }

  targetLayerSet = '';

  border = null;

  setup = function() {
    border = UnitValue(2, 'px');
    preferences.rulerUnits = Units.PIXELS;
    return targetLayerSet = app.activeDocument.activeLayer;
  };

  main = function() {
    sort();
    createAlpha();
    return app.activeDocument.activeLayer = targetLayerSet;
  };

  sort = function() {
    var block, blocks, coords, i, layer, len, packer, results;
    blocks = (function() {
      var i, len, ref, results;
      ref = targetLayerSet.artLayers;
      results = [];
      for (i = 0, len = ref.length; i < len; i++) {
        layer = ref[i];
        results.push({
          x: layer.bounds[0],
          y: layer.bounds[1],
          w: layer.bounds[2] - layer.bounds[0] + border,
          h: layer.bounds[3] - layer.bounds[1] + border,
          layer: layer
        });
      }
      return results;
    })();
    packer = new NETXUS.RectanglePacker(activeDocument.width.value, activeDocument.height.value);
    results = [];
    for (i = 0, len = blocks.length; i < len; i++) {
      block = blocks[i];
      coords = packer.findCoords(block.w.value, block.h.value);
      results.push(block.layer.translate(UnitValue(coords.x, 'px') - block.x, UnitValue(coords.y, 'px') - block.y));
    }
    return results;
  };

  createAlpha = function() {
    var mergedLayer, targetAlphaChannel;
    targetAlphaChannel = findOrCreateAlphaChannel(targetLayerSet.name + "_a");
    mergedLayer = targetLayerSet.duplicate().merge();
    selectTransparentArea(mergedLayer);
    activeDocument.selection.store(targetAlphaChannel);
    activeDocument.selection.deselect();
    return mergedLayer.remove();
  };

  findOrCreateAlphaChannel = function(layerName) {
    var channel, i, len, ref, target;
    target = null;
    ref = activeDocument.channels;
    for (i = 0, len = ref.length; i < len; i++) {
      channel = ref[i];
      if (channel.name === layerName) {
        target = channel;
      }
    }
    if (target === null) {
      target = activeDocument.channels.add();
      target.name = layerName;
    }
    return target;
  };

  selectTransparentArea = function(target) {
    var actionDesc, actionSelect, actionTransparent, idChnl;
    app.activeDocument.activeLayer = target;
    idChnl = charIDToTypeID("Chnl");
    actionSelect = new ActionReference();
    actionSelect.putProperty(idChnl, charIDToTypeID("fsel"));
    actionTransparent = new ActionReference();
    actionTransparent.putEnumerated(idChnl, idChnl, charIDToTypeID("Trsp"));
    actionDesc = new ActionDescriptor();
    actionDesc.putReference(charIDToTypeID("null"), actionSelect);
    actionDesc.putReference(charIDToTypeID("T   "), actionTransparent);
    return executeAction(charIDToTypeID("setd"), actionDesc, DialogModes.NO);
  };

  setup();

  main();

}).call(this);
