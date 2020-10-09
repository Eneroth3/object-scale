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
  scales = [
    Geom::Vector3d.new(transformation.to_a.values_at(0..2)).length,
    Geom::Vector3d.new(transformation.to_a.values_at(4..6)).length,
    Geom::Vector3d.new(transformation.to_a.values_at(8..10)).length
  ]
  
  # Native Scale tool only scale flat objects in their plane.
  # If object is flat, ignore third axis when calculating scale.
  # Ignore hypothetical axial objects.
  # TODO: Can flatness be expressed as bitmask and axial objects be supported?
  flat = zero_axis(bounds)
  scales[flat] = 1 if flat
  
  # TODO: Honor last element
  product = scales.inject(:*)
  flat ? Math.sqrt(product) : Math.cbrt(product)
end

def uniform?(transformation, bounds)
  x_scale = Geom::Vector3d.new(transformation.to_a.values_at(0..2)).length
  y_scale = Geom::Vector3d.new(transformation.to_a.values_at(4..6)).length
  z_scale = Geom::Vector3d.new(transformation.to_a.values_at(8..10)).length
  
  x_scale == y_scale && x_scale == z_scale
end

# Get index to the bounds is flat in, if any.
#
# @param bounds [Geom::BoundingBox]
#
# @return [Integer, nil]
#   0 = x, 1 = y, 2 = z, nil = bounds is not flat.
def zero_axis(bounds)
  if bounds.width == 0
    0
  elsif bounds.height == 0 # "height" = depth (Y)
    1
  elsif bounds.depth == 0 # "depth" = height (z)
    2
  end
end

entity = Sketchup.active_model.selection.first
entity.transformation = apply_scaling(entity.transformation, 2)
