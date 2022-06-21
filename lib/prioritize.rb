require 'prioritize/version'

# Корневой модуль отделяющий пространство имён Классов и Модулей гема от
# приложения.
module Prioritize
  # Собственные ошибки TODO: разработать список частых ошибок при использовании
  # гема с описанием исправления.
  class Error < StandardError
  end

  # Можно сказать точка входа, включаем гем в базовый класс ActiveRecord::Base,
  # после чего в любой модели унаследованной от этого класса появится метод
  # prioritize_column(...).
  # Метод расширяет конкретный класс дополнительными методами гема и
  # настройками.
  def self.included(base)
    base.extend ClassMethods
  end

  # Все Модели унаследованные от ActiveRecord::Base буду обладать указанным
  # настроечным методом класса prioritize_column(...)
  module ClassMethods
    # При вызове настроечного метода
    def prioritize_column(column, nested: false, parent_column: :parent_id)
      # Класс расширяется модулем PriorityAfter
      include PriorityAfter

      # fail Error.new('') if column.blank?

      # Настраиваем конкретную колонку для текущей модели.
      self.priority_column = column.to_s
      self.priority_nested = nested
      self.priority_parent = parent_column.to_s
    end
  end

  # Модуль которым расширяем Модели использовавшие в себе метод
  # prioritize_column(...)
  module PriorityAfter
    def self.included(base)
      base.extend ClassMethods
      # К экземпляру класса добавим поле, в которое необходимо записать значение
      # если необходимо выполнить сортировку.
      # После обновления экземпляра если в поле установлено значение - сработает
      # поведение.
      attr_accessor :priority_prev
      # Навесим поведение модели.
      base.after_update :priority_callback
    end

    # При заполннном поле priority_prev запустим запрос на обновление
    # сортировочного поля. В данном поле должен быть записан идентификатор
    # элемента ЗА которым должен слеовать перемещаемый элемент. Если такого
    # элемента нет (тоесть перемещаемый элемент переносится в начало списка),
    # тогда в поле необходимо записать строку '^'.
    def priority_callback
      if priority_prev.present?
        prev_id = priority_prev == '^' ? nil : priority_prev
        priority_after prev_id
      end
    end

    def priority_after(prev_id)
      self.class.priority_after prev_id, id
    end

    # Методы класса после расширения модулем PriorityAfter перечислены в этом
    # подмодуле.
    module ClassMethods
      def priority_after(prev_id, moved_id)
        if connection.adapter_name == 'SQLite'
          priority_sqlite(prev_id, moved_id)
        else
          connection.exec_query(
            priority_sql,
            'priority_after',
            [[nil, prev_id], [nil, moved_id]]
          )
        end
      end

      def priority_sql
        sql = <<-SQL
          UPDATE #{table_name} o
          SET "#{priority_column}" = ordered.rn
          FROM (
            SELECT *, ROW_NUMBER() OVER() AS rn
            FROM (
              -- Выбрать записи от начала и до предыдущего (включая его),
              -- конечно исключая перемещаемую запись.
              (
                SELECT o.*
                FROM #{table_name} o
                LEFT JOIN #{table_name} prev ON prev.id IS NOT DISTINCT FROM $1
                LEFT JOIN #{table_name} moved ON moved.id IS NOT DISTINCT FROM $2
                WHERE
                  o."#{priority_column}" <= prev."#{priority_column}"
                  AND o.id <> $2
                  nested_condition
                ORDER BY o."#{priority_column}" ASC
              )
              UNION ALL
              -- Выбрать перемещаемую запись.
              (
                SELECT o.*
                FROM #{table_name} o
                WHERE o.id = $2
              )
              UNION ALL
              -- Выбрать от предыдущего (не включая его) и до конца, так же
              -- исключая перемещаемую запись.
              (
                SELECT o.*
                FROM #{table_name} o
                LEFT JOIN #{table_name} prev ON prev.id IS NOT DISTINCT FROM $1
                LEFT JOIN #{table_name} moved ON moved.id IS NOT DISTINCT FROM $2
                WHERE
                  (o."#{priority_column}" > prev."#{priority_column}" OR prev."#{priority_column}" IS NULL)
                  AND o.id <> $2
                  nested_condition
                ORDER BY o."#{priority_column}" ASC
              )
            ) numbered
          ) ordered
          WHERE  o.id = ordered.id
        SQL
        nested_condition = priority_nested ?
          %Q(AND o."#{priority_parent}" IS NOT DISTINCT FROM moved."#{priority_parent}") :
          ''
        sql.gsub! 'nested_condition', nested_condition
        sql
      end

      def priority_sqlite(prev_id, moved_id)
        list = select('id', "#{priority_column}").order("#{priority_column}" => :asc).where.not(id: moved_id).to_a
        moved = select('id', "#{priority_column}").find_by_id(moved_id)
        if prev_id.nil?
          list.unshift(moved)
        else
          list.each_with_index do |model, index|
            if model.id == prev_id
              list.insert(index + 1, moved)
              break
            end
          end
        end
        transaction do
          list.each_with_index do |model, index|
            model.update("#{priority_column}" => index)
          end
        end
      end

      # def priority_column
      #   @priority_column.to_s
      # end

      # def priority_column=(value)
      #   @priority_column = value
      # end

      attr_accessor :priority_column, :priority_nested, :priority_parent

      def self.extended(base)
        base.class_eval do
          # @priority_column = :priority
        end
      end
    end
  end
end

# ActiveRecord::Base.send(:include, Prioritize)
ActiveRecord::Base.include Prioritize
