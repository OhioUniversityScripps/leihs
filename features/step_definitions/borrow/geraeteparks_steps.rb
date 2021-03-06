# -*- encoding : utf-8 -*-  

Wenn(/^ich den Gerätepark Link drücke$/) do
  visit borrow_root_path
  first("a[href='#{borrow_inventory_pools_path}']").click
end

Dann(/^sehe ich die Geräteparks für die ich berechtigt bin$/) do
  @current_user.inventory_pools.each do |ip|
    page.should have_content ip.name
  end
end

When(/^ich sehe nur die Geräteparks, die ausleihbare Gegenstände enthalten$/) do
  all(".row .padding-inset-l > .row > h2.padding-bottom-s").map(&:text).should == @current_user.inventory_pools.with_borrowable_items.sort_by {|ip| ip.name}.map(&:to_s)
end

Dann(/^sehe die Beschreibung für jeden Gerätepark$/) do
  @current_user.inventory_pools.each do |ip|
    ip.description.split(/\n/).each do |text|
      page.should have_content text
    end
  end
end

Dann(/^die Geräteparks sind auf dieser Seite alphabetisch sortiert$/) do
  all("h2").map(&:text).should == all("h2").map(&:text).sort
end
