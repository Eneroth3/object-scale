def selected; Sketchup.active_model.selection.first end
selected.transformation = Eneroth::ObjectScale::Transformation.apply_scaling(selected.transformation, 2)
Eneroth::ObjectScale::Transformation.extract_scaling(selected.transformation, selected.definition.bounds)
