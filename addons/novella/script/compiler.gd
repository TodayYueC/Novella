extends RefCounted

class_name NovellaCompiler

func compile_to_dictionary(ast) -> Dictionary:
	if ast == null or not ast.has_method("to_dict"):
		return {"format": "novella-bytecode-json", "version": 1, "ast": {}}
	return {
		"format": "novella-bytecode-json",
		"version": 1,
		"ast": ast.to_dict(),
	}


func compile_to_json(ast) -> String:
	return JSON.stringify(compile_to_dictionary(ast), "\t")
