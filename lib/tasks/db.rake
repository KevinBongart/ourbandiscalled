namespace :db do
  desc "Deletes old 'Record' records when the table gets close to the Heroku limit"
  task trim: :environment do
    limit = 9000 # Heroku free db limit is 10000, this adds some padding

    number_of_records_to_delete = Record.count - limit
    if number_of_records_to_delete > 0
      Record.order(id: :asc).limit(number_of_records_to_delete).delete_all
    end
  end
end
