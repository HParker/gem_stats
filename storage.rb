require 'prism'
require 'extralite'

class Storage
  attr_reader :db

  def initialize(db_name = "gem_data.db")
    @db_name = db_name
    @db = Extralite::Database.new(db_name)
  end

  def setup
    db.execute "PRAGMA journal_mode = OFF"
    db.execute "PRAGMA sychronous = 0"
    db.execute "PRAGMA cache_size = 1000000"
    db.execute "PRAGMA locking_mode = EXCLUSIVE"
    db.execute "PRAGMA temp_store = MEMORY"

    db.execute "CREATE TABLE IF NOT EXISTS nodes(node_name TEXT UNIQUE ON CONFLICT IGNORE, count INT NOT NULL)"
    (Prism::Visitor.instance_methods - Object.instance_methods).map(&:to_s).filter { |x| x.start_with?("visit_") }.each do |visit_method|
      db.execute "INSERT INTO nodes (node_name, count) VALUES (?, ?)", visit_method, 0
    end

    # visit_call_node
    db.execute "CREATE TABLE IF NOT EXISTS method_calls(name TEXT NOT NULL, receiver TEXT, operator TEXT, arg_count INT NOT NULL, kwargs_count INT NOT NULL, filepath TEXT NOT NULL)"

    # visit_class_node
    db.execute "CREATE TABLE IF NOT EXISTS classes(name TEXT NOT NULL, super_class TEXT, locals_count INT NOT NULL, filepath TEXT NOT NULL, start_line INT NOT NULL, end_line INT NOT NULL)"

    # visit_module_node
    db.execute "CREATE TABLE IF NOT EXISTS modules(name TEXT NOT NULL, filepath TEXT NOT NULL, locals_count INT NOT NULL, start_line INT NOT NULL, end_line INT NOT NULL)"

    # visit_integer_node
    db.execute "CREATE TABLE IF NOT EXISTS integers(content TEXT NOT NULL, filepath TEXT NOT NULL)"

    # visit_symbol_node
    db.execute "CREATE TABLE IF NOT EXISTS symbols(content TEXT NOT NULL, static_content TEXT NOT NULL, filepath TEXT NOT NULL)"

    # visit_string_node
    db.execute "CREATE TABLE IF NOT EXISTS strings(content TEXT NOT NULL, static_content TEXT NOT NULL, filepath TEXT NOT NULL)"

    # visit_x_string_node, visit_interpolated_x_string_node
    db.execute "CREATE TABLE IF NOT EXISTS x_strings(content TEXT NOT NULL, static_content TEXT NOT NULL, filepath TEXT NOT NULL)"

    # visit_regular_expression_node, visit_interpolated_regular_expression_node
    db.execute "CREATE TABLE IF NOT EXISTS regexes(content TEXT NOT NULL, static_content TEXT NOT NULL, filepath TEXT NOT NULL)"

    # visit_case_node
    db.execute "CREATE TABLE IF NOT EXISTS cases(predicate TEXT NOT NULL, condition_count INT NOT NULL, filepath TEXT NOT NULL)"

    # visit_def_node
    db.execute "CREATE TABLE IF NOT EXISTS methods(name TEXT NOT NULL, receiver_type TEXT NOT NULL, locals_count INT NOT NULL, required_count INT, optionals_count INT, kwargs_count INT, filepath TEXT, start_line INT, end_line INT, length INT)"

    # wrap PRISM.parse
    db.execute "CREATE TABLE IF NOT EXISTS parse_times(filepath TEXT UNIQUE, bytes INT NOT NULL, time INT NOT NULL)"

    # locals
    db.execute "CREATE TABLE IF NOT EXISTS locals(name TEXT NOT NULL, scope TEXT NOT NULL, count INT NOT NULL)"
    db.execute "CREATE TABLE IF NOT EXISTS locals_scope(local_count INT NOT NULL, scope TEXT NOT NULL, filepath TEXT NOT NULL, start_line INT NOT NULL, end_line INT NOT NULL)"
  end

  # def query(...)
  #   db.query(...)
  # end

  # def exec(...)
  #   db.execute(...)
  # end
end
