targetLayerSet = ''
border = null

setup = ->
  border = UnitValue(2, 'px')
  preferences.rulerUnits = Units.PIXELS

  if app.documents.length == 0
    alert('対象のpsdを開いてから実行してください。')
    return false

  if app.activeDocument.activeLayer.typename == 'LayerSet'
    targetLayerSet = app.activeDocument.activeLayer
  else
    if app.activeDocument.activeLayer.parent.typename == 'LayerSet'
      targetLayerSet = app.activeDocument.activeLayer.parent
    else
      alert('対象のLayerSetを選択してください。')
      return false

  return true

main = ->
  prevActiveLayer = app.activeDocument.activeLayer
  sort()
  createAlpha()
  app.activeDocument.activeLayer = prevActiveLayer

find_targets = (layerSet) ->
  a = for layer in layerSet.artLayers when layer.visible
    {
      x: layer.bounds[0]
      y: layer.bounds[1]
      w: layer.bounds[2] - layer.bounds[0] + border
      h: layer.bounds[3] - layer.bounds[1] + border
      layer: layer
    }
  for set in layerSet.layerSets when set.visible
    a = a.concat(find_targets(set))
  a

sort = ->
  targets = find_targets(targetLayerSet)

  packer = new NETXUS.RectanglePacker(activeDocument.width.value, 4096)
  for target in targets
    target.coords = packer.findCoords(target.w.value, target.h.value)

  for target in targets
    target.layer.translate(
      UnitValue(target.coords.x, 'px') - target.x,
      UnitValue(target.coords.y, 'px')-target.y
    )

createAlpha = ->
  targetAlphaChannel = findOrCreateAlphaChannel(targetLayerSet.name + "_a")

  mergedLayer = targetLayerSet.duplicate().merge()
  selectTransparentArea(mergedLayer)
  activeDocument.selection.store(targetAlphaChannel)
  activeDocument.selection.deselect()
  mergedLayer.remove()

findOrCreateAlphaChannel = (layerName) ->
  target = null
  for channel in activeDocument.channels
    if channel.name == layerName
      target = channel
  if target == null
    target = activeDocument.channels.add()
    target.name = layerName
  target

selectTransparentArea = (target) ->
  # http://tiku.io/questions/3467018/setting-selection-to-layer-transparency-channel-using-extendscript-in-photoshop
  app.activeDocument.activeLayer = target
  idChnl = charIDToTypeID( "Chnl" )
  actionSelect = new ActionReference()
  actionSelect.putProperty( idChnl, charIDToTypeID( "fsel" ) )

  actionTransparent = new ActionReference()
  actionTransparent.putEnumerated( idChnl, idChnl, charIDToTypeID( "Trsp" ) )

  actionDesc = new ActionDescriptor()
  actionDesc.putReference( charIDToTypeID( "null" ), actionSelect )
  actionDesc.putReference( charIDToTypeID( "T   " ), actionTransparent )

  executeAction( charIDToTypeID( "setd" ), actionDesc, DialogModes.NO )

if setup()
  main()
