module JsonApiClient
  module Linking
    class IncludedData
      attr_reader :data

      def initialize(record_class, data)
        grouped_data = data.group_by{|datum| datum["type"]}
        @data = grouped_data.inject({}) do |h, (type, records)|
          klass = Utils.compute_type(record_class, type.singularize.classify)
          h[type] = records.map do |datum|
            params = klass.parser.parameters_from_resource(datum)
            klass.new(params)
          end.index_by(&:id)
          h
        end
      end

      def data_for(method_name, definition)
        # If linkage is defined, pull the record from the included data
        if linkage = definition["linkage"]
          if linkage.is_a?(Array)
            # has_many link
            linkage.map do |link_def|
              record_for(link_def)
            end
          else
            # has_one link
            record_for(linkage)
          end
        else
          # TODO: if "related" URI is defined, fetch the delated object and stuff it in data
          nil
        end
      end

      def has_link?(name)
        data.has_key?(name)
      end

      private

      # should return a resource record of some type for this linked document
      def record_for(link_def)
        data[link_def["type"]][link_def["id"]]
      end
    end
  end
end
