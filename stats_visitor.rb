# frozen_string_literal: true
require 'prism'

class StatsVisitor < Prism::Visitor
  attr_reader :db, :filepath

  def initialize(storage, filepath)
    @filepath = filepath

    @db = storage.db
  end

  def visit_integer_node(node)
    db.execute "INSERT INTO integers (content, filepath) VALUES (?, ?)", node.slice, filepath
    visit_child_nodes(node)
  end

  def visit_x_string_node(node)
    db.execute "INSERT INTO x_strings (content, static_content, filepath) VALUES (?, ?, ?)", node.slice, node.slice, filepath
    visit_child_nodes(node)
  end

  def visit_call_node(node)
    node_name = node.name.to_s

    receiver = ""
    if node.receiver
      receiver = node.receiver.slice
    end

    arg_count = 0
    kwargs_count = 0
    if node.arguments
      arg_count = node.arguments.arguments.size
      if arg_count.positive? && node.arguments.arguments.last.is_a?(Prism::KeywordHashNode)
        kwargs_count = node.arguments.arguments.last.elements.size
      end
    end

    db.execute "INSERT INTO method_calls (name, receiver, arg_count, kwargs_count, filepath) VALUES (?, ?, ?, ?, ?)", node_name, receiver, arg_count, kwargs_count, filepath

    visit_child_nodes(node)
  end

  # foo.bar += 3
  def visit_call_operator_write_node(node)
    receiver = ""
    if node.receiver
      receiver = node.receiver.slice
    end

    arg_count = 1 # always one in node.value

    db.execute "INSERT INTO method_calls (name, receiver, operator, arg_count, kwargs_count, filepath) VALUES (?, ?, ?, ?, 0, ?)", node.write_name.to_s, receiver, node.operator.to_s, arg_count, filepath

    visit_child_nodes(node)
  end

  def visit_call_or_write_node(node)
    receiver = ""
    if node.receiver
      receiver = node.receiver.slice
    end

    arg_count = 1 # always one in node.value

    db.execute "INSERT INTO method_calls (name, receiver, operator, arg_count, kwargs_count, filepath) VALUES (?, ?, ?, ?, 0, ?)", node.write_name.to_s, receiver, "||", arg_count, filepath
    visit_child_nodes(node)
  end

  def visit_call_and_write_node(node)
    receiver = ""
    if node.receiver
      receiver = node.receiver.slice
    end

    arg_count = 1 # always one in node.value

    db.execute "INSERT INTO method_calls (name, receiver, operator, arg_count, kwargs_count, filepath) VALUES (?, ?, ?, ?, 0, ?)", node.write_name.to_s, receiver, "&&", arg_count, filepath
    visit_child_nodes(node)
  end

  def visit_call_target_node(node)
    receiver = ""
    if node.receiver
      receiver = node.receiver.slice
    end

    arg_count = 1 # always one in node.value

    db.execute "INSERT INTO method_calls (name, receiver, operator, arg_count, kwargs_count, filepath) VALUES (?, ?, ?, ?, 0, ?)", node.name.to_s, receiver, "", arg_count, filepath

    visit_child_nodes(node)
  end

  def visit_case_node(node)
    db.execute "INSERT INTO cases (predicate, condition_count, filepath) VALUES (?, ?, ?)", node.predicate.to_s, node.conditions.count, filepath
    visit_child_nodes(node)
  end

  # /foo#{bar}baz/, /[\d]:{2}#{?}/
  def visit_interpolated_regular_expression_node(node)
    string = node.parts.map { |p| p.is_a?(Prism::StringNode) ? p.content : '#{?}' }.join
    db.execute "INSERT INTO regexes (content, static_content, filepath) VALUES (?, ?, ?)", node.slice, string, filepath

    visit_child_nodes(node)
  end

  def visit_interpolated_string_node(node)
    string = node.parts.map { |p| p.is_a?(Prism::StringNode) ? p.content : '#{?}' }.join
    db.execute "INSERT INTO strings (content, static_content, filepath) VALUES (?, ?, ?)", node.slice, string, filepath

    visit_child_nodes(node)
  end

  def visit_interpolated_symbol_node(node)
    string = node.parts.map { |p| p.is_a?(Prism::StringNode) ? p.content : '#{?}' }.join
    db.execute "INSERT INTO symbols (content, static_content, filepath) VALUES (?, ?, ?)", node.slice, string, filepath

    visit_child_nodes(node)
  end

  def visit_class_node(node)
    # locals
    update_locals(node, 'class')

    class_name = node&.name.name

    super_class = ""
    if node.superclass
      super_class = node.superclass.slice
    end

    db.execute "INSERT INTO classes (name, super_class, filepath, locals_count, start_line, end_line) VALUES (?, ?, ?, ?, ?, ?)", class_name, super_class, filepath, node.locals.count, node.location.start_line, node.location.end_line

    visit_child_nodes(node)
  end

  def visit_interpolated_x_string_node(node)
    string = node.parts.map { |p| p.is_a?(Prism::StringNode) ? p.content : '#{?}' }.join
    db.execute "INSERT INTO x_strings (content, static_content, filepath) VALUES (?, ?, ?)", node.slice, string, filepath

    visit_child_nodes(node)
  end

  def visit_class_variable_and_write_node(node)
    visit_child_nodes(node)
  end

  def visit_keyword_hash_node(node)
    # TODO: keyword hash tracking
    visit_child_nodes(node)
  end

  def visit_class_variable_operator_write_node(node)
    visit_child_nodes(node)
  end

  def visit_class_variable_or_write_node(node)
    visit_child_nodes(node)
  end

  def visit_keyword_rest_parameter_node(node)
    visit_child_nodes(node)
  end

  def visit_class_variable_read_node(node)
    visit_child_nodes(node)
  end

  def visit_lambda_node(node)
    # locals
    update_locals(node, 'lambda')
    visit_child_nodes(node)
  end

  def visit_class_variable_target_node(node)
    visit_child_nodes(node)
  end

  def visit_local_variable_and_write_node(node)
    visit_child_nodes(node)
  end

  def visit_class_variable_write_node(node)
    visit_child_nodes(node)
  end

  def visit_local_variable_operator_write_node(node)
    visit_child_nodes(node)
  end

  def visit_constant_and_write_node(node)
    visit_child_nodes(node)
  end

  def visit_local_variable_or_write_node(node)
    visit_child_nodes(node)
  end

  def visit_constant_operator_write_node(node)
    visit_child_nodes(node)
  end

  def visit_local_variable_read_node(node)
    visit_child_nodes(node)
  end

  def visit_constant_or_write_node(node)
    visit_child_nodes(node)
  end

  def visit_local_variable_target_node(node)
    visit_child_nodes(node)
  end

  def visit_constant_path_and_write_node(node)
    visit_child_nodes(node)
  end

  def visit_local_variable_write_node(node)
    visit_child_nodes(node)
  end

  def visit_constant_path_node(node)
    visit_child_nodes(node)
  end

  def visit_match_last_line_node(node)
    visit_child_nodes(node)
  end

  def visit_match_predicate_node(node)
    visit_child_nodes(node)
  end

  def visit_constant_path_operator_write_node(node)
    visit_child_nodes(node)
  end

  def visit_match_required_node(node)
    visit_child_nodes(node)
  end

  def visit_constant_path_or_write_node(node)
    visit_child_nodes(node)
  end

  def visit_constant_path_target_node(node)
    visit_child_nodes(node)
  end

  def visit_match_write_node(node)
    visit_child_nodes(node)
  end

  def visit_constant_path_write_node(node)
    visit_child_nodes(node)
  end

  def visit_missing_node(node)
    # TODO: track this they are always errors right?
    visit_child_nodes(node)
  end
  def visit_constant_read_node(node)
    visit_child_nodes(node)
  end

  def visit_regular_expression_node(node)
    db.execute "INSERT INTO regexes (content, static_content, filepath) VALUES (?, ?, ?)", node.slice, node.slice, filepath

    visit_child_nodes(node)
  end

  def visit_constant_target_node(node)
    visit_child_nodes(node)
  end

  def visit_module_node(node)
    # locals
    update_locals(node, 'module')

    db.execute "INSERT INTO modules (name, filepath, locals_count, start_line, end_line) VALUES (?, ?, ?, ?, ?)", node.name.name, filepath, node.locals.count, node.location.start_line, node.location.end_line

    visit_child_nodes(node)
  end

  def visit_constant_write_node(node)
    visit_child_nodes(node)
  end

  def visit_multi_target_node(node)
    visit_child_nodes(node)
  end

  def visit_multi_write_node(node)
    visit_child_nodes(node)
  end

  def visit_def_node(node)
    # locals
    update_locals(node, 'def')
    locals_count = 0
    if node.locals
      locals_count = node.locals.count
    end

    # params
    requireds_count = 0
    optionals_count = 0
    kwargs_count = 0
    if node.parameters
      requireds_count = node.parameters.requireds.size
      optionals_count = node.parameters.optionals.size
      kwargs_count = node.parameters.keywords.size
    end

    receiver_type = ""
    if node.receiver
      receiver_type = node.receiver.type.to_s
    end

    db.execute "INSERT INTO methods (name, receiver_type, locals_count, required_count, optionals_count, kwargs_count, filepath, start_line, end_line, length) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", node.name.to_s, receiver_type, locals_count, requireds_count, optionals_count, kwargs_count, filepath, node.location.start_line, node.location.end_line, node.location.length

    visit_child_nodes(node)
  end

  def visit_next_node(node)
    visit_child_nodes(node)
  end

  def visit_nil_node(node)
    visit_child_nodes(node)
  end

  def visit_defined_node(node)
    visit_child_nodes(node)
  end

  def visit_no_keywords_parameter_node(node)
    visit_child_nodes(node)
  end

  def visit_else_node(node)
    visit_child_nodes(node)
  end

  def visit_numbered_parameters_node(node)
    visit_child_nodes(node)
  end

  def visit_embedded_statements_node(node)
    visit_child_nodes(node)
  end

  def visit_numbered_reference_read_node(node)
    visit_child_nodes(node)
  end

  def visit_embedded_variable_node(node)
    visit_child_nodes(node)
  end

  def visit_optional_keyword_parameter_node(node)
    visit_child_nodes(node)
  end

  def visit_alias_global_variable_node(node)
    visit_child_nodes(node)
  end

  def visit_optional_parameter_node(node)
    visit_child_nodes(node)
  end

  def visit_ensure_node(node)
    visit_child_nodes(node)
  end

  def visit_or_node(node)
    visit_child_nodes(node)
  end

  def visit_false_node(node)
    visit_child_nodes(node)
  end

  def visit_alias_method_node(node)
    visit_child_nodes(node)
  end

  def visit_find_pattern_node(node)
    visit_child_nodes(node)
  end

  def visit_flip_flop_node(node)
    visit_child_nodes(node)
  end

  def visit_parameters_node(node)
    visit_child_nodes(node)
  end

  def visit_alternation_pattern_node(node)
    visit_child_nodes(node)
  end

  def visit_parentheses_node(node)
    visit_child_nodes(node)
  end

  def visit_float_node(node)
    visit_child_nodes(node)
  end

  def visit_pinned_expression_node(node)
    visit_child_nodes(node)
  end

  def visit_and_node(node)
    visit_child_nodes(node)
  end

  def visit_pinned_variable_node(node)
    visit_child_nodes(node)
  end

  def visit_arguments_node(node)
    visit_child_nodes(node)
  end

  def visit_post_execution_node(node)
    visit_child_nodes(node)
  end

  def visit_pre_execution_node(node)
    visit_child_nodes(node)
  end

  def visit_for_node(node)
    visit_child_nodes(node)
  end

  def visit_program_node(node)
    # locals
    update_locals(node, 'prog')
    visit_child_nodes(node)
  end

  def visit_range_node(node)
    visit_child_nodes(node)
  end

  def visit_forwarding_arguments_node(node)
    visit_child_nodes(node)
  end

  def visit_array_node(node)
    visit_child_nodes(node)
  end

  def visit_rational_node(node)
    visit_child_nodes(node)
  end

  def visit_forwarding_parameter_node(node)
    visit_child_nodes(node)
  end

  def visit_redo_node(node)
    visit_child_nodes(node)
  end

  def visit_forwarding_super_node(node)
    visit_child_nodes(node)
  end

  def visit_global_variable_and_write_node(node)
    visit_child_nodes(node)
  end

  def visit_required_keyword_parameter_node(node)
    visit_child_nodes(node)
  end

  def visit_global_variable_operator_write_node(node)
    visit_child_nodes(node)
  end

  def visit_required_parameter_node(node)
    visit_child_nodes(node)
  end

  def visit_array_pattern_node(node)
    visit_child_nodes(node)
  end

  def visit_global_variable_or_write_node(node)
    visit_child_nodes(node)
  end

  def visit_global_variable_read_node(node)
    visit_child_nodes(node)
  end

  def visit_assoc_node(node)
    visit_child_nodes(node)
  end

  def visit_global_variable_target_node(node)
    visit_child_nodes(node)
  end

  def visit_assoc_splat_node(node)
    visit_child_nodes(node)
  end

  def visit_rescue_node(node)
    visit_child_nodes(node)
  end

  def visit_global_variable_write_node(node)
    visit_child_nodes(node)
  end

  def visit_back_reference_read_node(node)
    visit_child_nodes(node)
  end

  def visit_rest_parameter_node(node)
    visit_child_nodes(node)
  end

  def visit_hash_node(node)
    visit_child_nodes(node)
  end

  def visit_rescue_modifier_node(node)
    visit_child_nodes(node)
  end

  def visit_retry_node(node)
    visit_child_nodes(node)
  end

  def visit_hash_pattern_node(node)
    visit_child_nodes(node)
  end

  def visit_return_node(node)
    visit_child_nodes(node)
  end

  def visit_self_node(node)
    visit_child_nodes(node)
  end

  def visit_if_node(node)
    visit_child_nodes(node)
  end

  def visit_singleton_class_node(node)
    # locals
    update_locals(node, 'singleton_class')
    visit_child_nodes(node)
  end

  def visit_begin_node(node)
    visit_child_nodes(node)
  end

  def visit_source_encoding_node(node)
    visit_child_nodes(node)
  end

  def visit_imaginary_node(node)
    visit_child_nodes(node)
  end

  def visit_source_file_node(node)
    visit_child_nodes(node)
  end

  def visit_block_argument_node(node)
    visit_child_nodes(node)
  end

  def visit_implicit_node(node)
    visit_child_nodes(node)
  end

  def visit_source_line_node(node)
    visit_child_nodes(node)
  end

  def visit_block_local_variable_node(node)
    visit_child_nodes(node)
  end

  def visit_implicit_rest_node(node)
    visit_child_nodes(node)
  end

  def visit_splat_node(node)
    visit_child_nodes(node)
  end

  def visit_statements_node(node)
    visit_child_nodes(node)
  end

  def visit_in_node(node)
    visit_child_nodes(node)
  end

  def visit_block_node(node)
    # locals
    update_locals(node, 'block')
    visit_child_nodes(node)
  end

  def visit_string_node(node)
    db.execute "INSERT INTO strings (content, static_content, filepath) VALUES (?, ?, ?)", node.slice, node.slice, filepath

    visit_child_nodes(node)
  end

  def visit_index_and_write_node(node)
    visit_child_nodes(node)
  end

  def visit_index_operator_write_node(node)
    visit_child_nodes(node)
  end

  def visit_block_parameter_node(node)
    visit_child_nodes(node)
  end

  def visit_block_parameters_node(node)
    visit_child_nodes(node)
  end

  def visit_index_or_write_node(node)
    visit_child_nodes(node)
  end

  def visit_symbol_node(node)
    db.execute "INSERT INTO symbols (content, static_content, filepath) VALUES (?, ?, ?)", node.slice, node.slice, filepath

    visit_child_nodes(node)
  end

  def visit_break_node(node)
    visit_child_nodes(node)
  end

  def visit_index_target_node(node)
    visit_child_nodes(node)
  end

  def visit_instance_variable_and_write_node(node)
    visit_child_nodes(node)
  end

  private

  def update_locals(node, scope)
    if node&.locals
      node.locals.each do |local|
        if !db.query_single_value("SELECT name FROM locals WHERE name = ? AND scope = ? LIMIT 1", local.name, scope)
          db.execute("UPDATE locals SET count = count + 1 WHERE name = ? AND scope = ?", local.name, scope)
        else
          db.execute("INSERT INTO locals (name, scope, count) VALUES (?, ?, ?)", local.name, scope, 1)
        end
      end

      db.execute("INSERT INTO locals_scope (local_count, scope, filepath, start_line, end_line) VALUES (?, ?, ?, ?, ?)", node.locals.count, scope, filepath, node.location.start_line, node.location.end_line)
    end
  end
end
