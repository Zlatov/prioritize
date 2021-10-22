require "prioritize/version"

module Prioritize
  class Error < StandardError; end

  def self.included base
    base.extend ClassMethods
  end

  module ClassMethods
    def prioritize_column
      self.include PriorityAfter
    end
  end

  module PriorityAfter
    def self.included base
      base.extend ClassMethods
    end
    def priority_after
    end
    module ClassMethods
      def priority_after before_id, moved_id
        connection.exec_query(
          <<-SQL,
            UPDATE #{table_name} o
            SET #{priority_column} = ordered.rn
            FROM (
              SELECT *, ROW_NUMBER() OVER() AS rn
              FROM (
                (
                  SELECT o.*
                  FROM #{table_name} o
                  LEFT JOIN #{table_name} ai ON ai.id = $1
                  WHERE
                    (o.#{priority_column} < ai.#{priority_column} OR ai.#{priority_column} IS NULL) AND
                    o.id <> $2
                  ORDER BY o.#{priority_column} ASC
                )
                UNION ALL
                (
                  SELECT o.*
                  FROM #{table_name} o
                  WHERE o.id = $2
                )
                UNION ALL
                (
                  SELECT o.*
                  FROM #{table_name} o
                  LEFT JOIN #{table_name} ai ON ai.id = $1
                  WHERE
                    o.#{priority_column} >= ai.#{priority_column} AND
                    o.id <> $2
                  ORDER BY o.#{priority_column} ASC
                )
              ) numbered
            ) ordered
            WHERE  o.id = ordered.id
          SQL
          'priority_after',
          [[nil,before_id], [nil,moved_id]]
        )
      end
      attr_accessor :priority_column
      def priority_column
        @priority_column.to_s
      end
      def self.extended base
        base.class_eval do
          @priority_column = :priority
        end
      end
    end
  end
end

ActiveRecord::Base.send(:include, Prioritize)


# byebug

# Кто после кого
# PostSection.priority_after 1, 2
# post_section.priority_after 2
# 
# 
# self.implicit_order_column = "updated_at"
# 
