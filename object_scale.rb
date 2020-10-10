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

# Extract scaling from transformation.
#
# For 2D objects, the scaling in the "flat" axis is ignored.
# Native scale tool doesn't set this scaling when performing a
# seemingly uniform scaling, so it can't be relied upon.
#
# @param transformation [Geom::Transformation]
# @param bounds [Geom::BoundingBox]
#   The bounds of the object's definition.
#
# @return [Float]
def extract_scaling(transformation, bounds)
  scales = [
    Geom::Vector3d.new(transformation.to_a.values_at(0..2)).length,
    Geom::Vector3d.new(transformation.to_a.values_at(4..6)).length,
    Geom::Vector3d.new(transformation.to_a.values_at(8..10)).length
  ]
  sizes = [
    bounds.width,
    bounds.height, # "height" = depth
    bounds.depth # "depth" = height
  ]
  sizes.each_with_index { |s, i| scales[i] = 1 if s == 0 }
  product = scales.inject(:*)
  dimensions = sizes.count { |s| s != 0 }
  
  scale = product
  scale = Math.sqrt(product) if dimensions == 2
  scale = Math.cbrt(product) if dimensions == 3
  
  # The bottom right value of matrix can be used for scaling in SU.
  # Native scale tool doesn't set this value, but the API can set it.
  scale / transformation.to_a[15]
end



def selected; Sketchup.active_model.selection.first end
selected.transformation = apply_scaling(selected.transformation, 2)
extract_scaling(selected.transformation, selected.definition.bounds)
