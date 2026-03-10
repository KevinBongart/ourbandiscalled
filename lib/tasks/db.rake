namespace :db do
  desc "Deletes oldest records beyond the 9000 row limit"
  task trim: :environment do
    limit = 9000

    number_of_records_to_delete = Record.count - limit
    if number_of_records_to_delete > 0
      Record.order(id: :asc).limit(number_of_records_to_delete).delete_all
    end
  end
end
