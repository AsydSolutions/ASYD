module Monitoring

  class Notification
    include DataMapper::Resource

    def self.default_repository_name #here we use the monitoring_db for the Monitoring::Notification objects
     :monitoring_db
    end

    property :id, Serial
    property :type, Enum[ :error, :info, :success ], :lazy => false
    property :acknowledge, Boolean, :default => false
    property :host_hostname, String
    property :service, String
    property :message, Text, :lazy => false
    property :sticky, Boolean, :default => true #keep for compatibility
    property :dismiss, Boolean, :default => false, :lazy => false
    property :created_at, DateTime
    property :updated_at, DateTime
    property :inclass, Discriminator
  end

end
