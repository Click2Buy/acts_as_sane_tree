module ActsAsSaneTree
  module InstanceMethods

    # Returns all ancestors of the current node.
    def ancestors
      query =
        "(WITH RECURSIVE crumbs AS (
          SELECT #{self.class.configuration[:class].table_name}.*,
          1 AS depth
          FROM #{self.class.configuration[:class].table_name}
          WHERE id = #{id}
          UNION ALL
          SELECT alias1.*,
          depth + 1
          FROM crumbs
          JOIN #{self.class.configuration[:class].table_name} alias1 ON alias1.id = crumbs.parent_id
        ) SELECT * FROM crumbs WHERE crumbs.id != #{id}) as #{self.class.configuration[:class].table_name}"
      scope_strip_method = self.class.configuration[:class].methods.map(&:to_sym).include?(:unscoped) ? :unscoped : :with_exclusive_scope
      if(self.class.rails_arel?)
        self.class.configuration[:class].send(scope_strip_method) do
          self.class.configuration[:class].from(
            query
          ).order("#{self.class.configuration[:class].table_name}.depth DESC")
        end
      else
        self.class.configuration[:class].send(scope_strip_method) do
          self.class.configuration[:class].scoped(
            :from => query,
            :order => "#{self.class.configuration[:class].table_name}.depth DESC"
          )
        end
      end
    end

    # Returns the node and all its ancestors
    def self_and_ancestors
      query =
        "(WITH RECURSIVE crumbs AS (
          SELECT #{self.class.configuration[:class].table_name}.*,
          1 AS depth
          FROM #{self.class.configuration[:class].table_name}
          WHERE id = #{id}
          UNION ALL
          SELECT alias1.*,
          depth + 1
          FROM crumbs
          JOIN #{self.class.configuration[:class].table_name} alias1 ON alias1.id = crumbs.parent_id
        ) SELECT * FROM crumbs) as #{self.class.configuration[:class].table_name}"
      scope_strip_method = self.class.configuration[:class].methods.map(&:to_sym).include?(:unscoped) ? :unscoped : :with_exclusive_scope
      if(self.class.rails_arel?)
        self.class.configuration[:class].send(scope_strip_method) do
          self.class.configuration[:class].from(
            query
          ).order("#{self.class.configuration[:class].table_name}.depth DESC")
        end
      else
        self.class.configuration[:class].send(scope_strip_method) do
          self.class.configuration[:class].scoped(
            :from => query,
            :order => "#{self.class.configuration[:class].table_name}.depth DESC"
          )
        end
      end
    end

    # Returns the root node of the tree.
    def root
      ancestors.first
    end

    # Returns all siblings of the current node.
    #
    #   subchild1.siblings # => [subchild2]
    def siblings
      self_and_siblings - [self]
    end

    # Returns all siblings and a reference to the current node.
    #
    #   subchild1.self_and_siblings # => [subchild1, subchild2]
    def self_and_siblings
      parent ? parent.children : self.class.configuration[:class].roots
    end

    # Returns if the current node is a root
    def root?
      parent_id.nil?
    end

    # Returns all descendants of the current node
    # Note: results are unsorted
    def descendants
      query =
        "(WITH RECURSIVE crumbs AS (
          SELECT #{self.class.configuration[:class].table_name}.*,
          1 AS depth
          FROM #{self.class.configuration[:class].table_name}
          WHERE parent_id = #{id}
          UNION ALL
          SELECT alias1.*,
          depth + 1
          FROM crumbs
          JOIN #{self.class.configuration[:class].table_name} alias1 ON alias1.parent_id = crumbs.id
        ) SELECT * FROM crumbs) as #{self.class.configuration[:class].table_name}"
      scope_strip_method = self.class.configuration[:class].methods.map(&:to_sym).include?(:unscoped) ? :unscoped : :with_exclusive_scope
      if(self.class.rails_arel?)
        self.class.configuration[:class].send(scope_strip_method) do
          self.class.configuration[:class].from(query)
        end
      else
        self.class.configuration[:class].send(scope_strip_method) do
          self.class.configuration[:class].scoped(:from => query)
        end
      end
    end
    alias_method :descendents, :descendants

    # Returns the node and all its descendants
    # Note: results are unsorted
    def self_and_descendants
      query =
        "(WITH RECURSIVE crumbs AS (
          SELECT #{self.class.configuration[:class].table_name}.*,
          1 AS depth
          FROM #{self.class.configuration[:class].table_name}
          WHERE id = #{id}
          UNION ALL
          SELECT alias1.*,
          depth + 1
          FROM crumbs
          JOIN #{self.class.configuration[:class].table_name} alias1 ON alias1.parent_id = crumbs.id
        ) SELECT * FROM crumbs) as #{self.class.configuration[:class].table_name}"
      scope_strip_method = self.class.configuration[:class].methods.map(&:to_sym).include?(:unscoped) ? :unscoped : :with_exclusive_scope
      if(self.class.rails_arel?)
        self.class.configuration[:class].send(scope_strip_method) do
          self.class.configuration[:class].from(query)
        end
      else
        self.class.configuration[:class].send(scope_strip_method) do
          self.class.configuration[:class].scoped(:from => query)
        end
      end
    end
    alias_method :self_and_descendents, :self_and_descendants

    # Returns the depth of the current node. 0 depth represents the root of the tree
    def depth
      query =
        "WITH RECURSIVE crumbs AS (
          SELECT parent_id, 0 AS level
          FROM #{self.class.configuration[:class].table_name}
          WHERE id = #{self.id}
          UNION ALL
          SELECT alias1.parent_id, level + 1
          FROM crumbs
          JOIN #{self.class.configuration[:class].table_name} alias1 ON alias1.id = crumbs.parent_id
        ) SELECT level FROM crumbs ORDER BY level DESC LIMIT 1"
      ActiveRecord::Base.connection.select_all(query).first.try(:[], 'level').try(:to_i)
    end

    # Check if the node has no children
    def leaf?
      children.empty?
    end
  end
end
