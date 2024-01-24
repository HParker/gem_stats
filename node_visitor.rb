class NodeTypeVisitor < Prism::BasicVisitor
  attr_reader :db, :filepath

  def initialize(storage, filepath)
    @filepath = filepath
    @db = storage.db
  end

  def method_missing(method, node)
    db.execute "UPDATE nodes SET count = count + 1 WHERE node_name = ?", method.name

    visit_child_nodes(node)
  end
end
