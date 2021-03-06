class RemovePurposeColumns < ActiveRecord::Migration
  def change

    [Contract].each do |k|
      k.all.each do |x|
        description = x.read_attribute(:purpose)
        next if description.nil?
        p_id = Purpose.create(description: description).id
        "#{k}Line".constantize.update_all({purpose_id: p_id}, {id: x.send("#{k}_line_ids".downcase), purpose_id: nil})
      end    
    end
    
    remove_column :orders, :purpose
    remove_column :contracts, :purpose
    
  end
end
