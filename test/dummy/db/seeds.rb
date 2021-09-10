FIXTURES_FOLDER = Rails.root.to_s+'/test/fixtures/'

# Clean up database
puts "######"
puts "CLEANING UP DATABASE!"

puts "Deleting records"
[User, Invoice, ApplicationRecordLog].each do |klass|
  puts "Deleting #{klass.name}: #{klass.delete_all}"
end
puts "######"

puts "######"
puts "SEEDING DATABASE"

users = YAML.load_file(FIXTURES_FOLDER+'users.yml').values
User.create(users)
puts "Created #{User.count} users"

invoices = YAML.load_file(FIXTURES_FOLDER+'invoices.yml').values
Invoice.create(invoices)
puts "Created #{Invoice.count} invoices"
