collection @models
attributes :id, :name, :description, :is_package, :manufacturer

node :type do |model|
  model.class.to_s.underscore
end

if params[:with]
  
  if params[:with][:availability]
    
    node :total_rentable_in_stock do |model|
      model.borrowable_items.in_stock.count
    end
    
    node :total_rentable do |model|
      model.borrowable_items.count
    end
        
  end
  
end
