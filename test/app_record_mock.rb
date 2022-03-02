class AppRecordMock
  class << self
    attr_writer :records
    def records
      @records ||= []
    end

    def table_name
      'app_record_mocks'
    end

    def columns_hash
      {
        'id' => OpenStruct.new(type: :integer),
        'name' => OpenStruct.new(type: :string),
        'date' => OpenStruct.new(type: :date),
        'data' => OpenStruct.new(type: :hash),
        'price' => OpenStruct.new(type: :decimal),
        'body' => OpenStruct.new(type: :text),
        'float' => OpenStruct.new(type: :float),
        'created_at' => OpenStruct.new(type: :datetime),
        'updated_at' => OpenStruct.new(type: :datetime),
      }
    end

    def find_by(**args)
      records.find do |rec|
        args.all?{|k,v| rec.send(k)==v}
      end
    end

    def has_many(name, **args)
      if name.to_s == 'application_record_logs'
        define_method(name) do
          ApplicationRecordLog.where(record_id: id, record_type: self.class.name)
        end
      else
        define_method(name) do
          []
        end
      end
    end
  end

  include ApplicationRecordLogger
  attr_accessor :id, :name, :date, :created_at, :updated_at, :data, :price, :body, :float

  def initialize(**args)
    args.each do |k,v|
      send("#{k}=", v)
    end
    self.class.records << self
  end

  def ==(other)
    (other.class == self.class) && (other.id == id)
  end
end
