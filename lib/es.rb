# Extentions for Stretcher

module ES
  extend self

  def server
    Thread.current[:es_connection] ||= Stretcher::Server.new(ENV['ELASTICSEARCH_URL'])
  end

  def index(index_name = :live)
    server.index(index_name)
  end

  def create_index(index_name = :live)
    # number_of_replicas doesn't count master
    index(index_name).create(:index => { :number_of_shards => 10, :number_of_replicas => 1 })
  end

  class Model < Hashie::Dash
    def self.mapping
      @mapping ||= {}
    end

    def self.property(property_name, options={})
      super(property_name, :default => options.delete(:default), :required => options.delete(:required))
      # XXX Does not support nested objects yet.
      self.mapping[property_name] = options
    end

    def self.type_name
      self.name.underscore
    end

    def self.update_mapping(index)
      index.type(self.type_name).put_mapping(self.type_name => { :properties => self.mapping,
                                                                 :_all       => { :enabled => false } })
    end
  end
end
