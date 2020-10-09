# Replace scaling in transformation.
#
# @param transformation [Geom::Transformation]
#
# @return [Geom::Transformation]
def apply_scaling(transformation, scale = 1)
  scaling = Geom::Transformation.scaling(scale, scale, scale)
  
  remove_scaling(transformation) * scaling
end

# Remove scaling from transformation.
#
# @param transformation [Geom::Transformation]
#
# @return [Geom::Transformation]
def remove_scaling(transformation)
  Geom::Transformation.new([
    *transformation.xaxis.normalize.to_a, 0,
    *transformation.yaxis.normalize.to_a, 0,
    *transformation.zaxis.normalize.to_a, 0,
    *transformation.origin.to_a, 1
  ])
end

def scaling(transformation, bounds)
  x_scale = Geom::Vector3d.new(transformation.to_a.values_at(0..2)).length
  y_scale = Geom::Vector3d.new(transformation.to_a.values_at(4..6)).length
  z_scale = Geom::Vector3d.new(transformation.to_a.values_at(8..10)).length
  
  # In case instance is 2D, native SketchUp scale tool will only affect two
  # axes. Ignore the scaling in he flat axis.
  flat = true
  if bounds.width == 0
    x_scale = 1
  elsif bounds.height == 0 # "height" = depth (Y)
    y_scale = 1
  elsif bounds.depth == 0 # "depth" = height (z)
    z_scale = 1
  else
    flat = false
  end
  product = x_scale * y_scale * z_scale
  
  # TODO: Honor last element
  flat ? Math.sqrt(product) : Math.cbrt(product)
end

def uniform?(transformation, bounds)
  x_scale = Geom::Vector3d.new(transformation.to_a.values_at(0..2)).length
  y_scale = Geom::Vector3d.new(transformation.to_a.values_at(4..6)).length
  z_scale = Geom::Vector3d.new(transformation.to_a.values_at(8..10)).length
  
  x_scale == y_scale && x_scale == z_scale
end

def flat?(bounds)
  
end





# Extract scaling from transformation.
#
# @param transformation [Geom::Transformation]
#
# @return [Float]
def scaling(transformation)
  xscale = Geom::Vector3d.new(transformation.to_a.values_at(0..2)).length
  yscale = Geom::Vector3d.new(transformation.to_a.values_at(4..6)).length
  zscale = Geom::Vector3d.new(transformation.to_a.values_at(8..10)).length
  
  # By default Scale tool scales flat objects only in two axes,
  # meaning we need to ignore any axis scaling not matching the other two.
  return x_scale.to_f if xscale == y_scale
  return x_scale.to_f if xscale == z_scale
  return y_scale.to_f if yscale == z_scale
  
  # What if object is stretched in just one axis?
  
  Math.cbrt(x_scale * y_scale * z_scale)
end

def scaling(transformation)
  xaxis = Geom::Vector3d.new(transformation.to_a.values_at(0..2))
  yaxis = Geom::Vector3d.new(transformation.to_a.values_at(4..6))
  zaxis = Geom::Vector3d.new(transformation.to_a.values_at(8..10))
  
  xaxis % (yaxis * zaxis) / transformation.to_a[15]
end



# Get uniform scaling from component.
#
# @return [Float, nil]
def scaling(transformation)
  xaxis = Geom::Vector3d.new(transformation.to_a.values_at(0..2))
  yaxis = Geom::Vector3d.new(transformation.to_a.values_at(4..6))
  zaxis = Geom::Vector3d.new(transformation.to_a.values_at(8..10))
  return unless xaxis.length == yaxis.length
  return unless xaxis.length == zaxis.length
  
  # Last element in transformation may be used for uniform scaling inverted.
  xaxis.length / transformation.to_a[15]
end

entity = Sketchup.active_model.selection.first
entity.transformation = apply_scaling(entity.transformation, 2)
