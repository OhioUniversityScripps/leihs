# encoding: utf-8
Wenn /^man im Inventar Bereich ist$/ do
  find("#topbar .topbar-navigation .topbar-item a", :text => _("Inventory")).click
  current_path.should == manage_inventory_path(@current_inventory_pool)
end

Dann /^kann man über die Tabnavigation zum Helferschirm wechseln$/ do
  find("#inventory-index-view nav a.navigation-tab-item", :text => _("Helper")).click
  find("h1", :text => _("Inventory Helper"))
end

Angenommen /^man ist auf dem Helferschirm$/ do
  @current_inventory_pool = @current_user.managed_inventory_pools.first
  visit manage_inventory_helper_path @current_inventory_pool
end

Dann /^wähle ich all die Felder über eine List oder per Namen aus$/ do
  i = find("#field-input")
  i.click
  page.has_selector?("a.ui-corner-all", :visible => true).should be_true
  number_of_items_left = all("a.ui-corner-all", :visible => true).size

  number_of_items_left.times do
    i.click
    find("a.ui-corner-all", match: :first, :visible => true).click
  end
end

Dann /^ich setze all ihre Initalisierungswerte$/ do
  @parent_el ||= find("#field-selection")
  @data = {}
  Field.all.each do |field|
    next if @parent_el.all(".field[data-id='#{field[:id]}']").empty?
    field_el = @parent_el.find(".field[data-id='#{field[:id]}']")
    case field[:type]
      when "radio"
        r = field_el.find("input[type=radio]", match: :first)
        r.click
        @data[field[:id]] = r.value
      when "textarea"
        ta = field_el.find("textarea")
        ta.set "This is a text for a textarea"
        @data[field[:id]] = ta.value
      when "select"
        o = field_el.find("option", match: :first)
        o.select_option
        @data[field[:id]] = o.value
      when "text"
        within field_el do
          string = if all("input[name='item[inventory_code]']").empty?
                     "This is a text for a input text"
                   else
                     "123456"
                   end
          i = find("input[type='text']")
          i.set string
          @data[field[:id]] = i.value
        end
      when "date"
        dp = field_el.find("[data-type='datepicker']")
        dp.click
        find(".ui-datepicker-calendar").find(".ui-state-highlight, .ui-state-active", visible: true).click
        @data[field[:id]] = dp.value
      when "autocomplete"
        target_name = find(".field[data-id='#{field[:id]}'] [data-type='autocomplete']")['data-autocomplete_value_target']
        find(".field[data-id='#{field[:id]}'] [data-type='autocomplete'][data-autocomplete_value_target='#{target_name}']").click
        sleep(0.44)
        find("a.ui-corner-all", match: :first).click
        @data[field[:id]] = find(".field[data-id='#{field[:id]}'] [data-type='autocomplete']")
      when "autocomplete-search"
        string = "Sharp Beamer"
        within ".field[data-id='#{field[:id]}']" do
          find("input").click
          find("input").set string
        end
        find("a.ui-corner-all", match: :prefer_exact, text: string).click
        @data[field[:id]] = Model.find_by_name(string).id
      when "checkbox"
        # currently we only have "ausgemustert"
        field_el.find("input[type='checkbox']").click
        find("[name='item[retired_reason]']").set "This is a text for a input text"
        @data[field[:id]] = "This is a text for a input text"
      else
        raise "field type not found"
    end
  end
end

Dann /^ich setze das Feld "(.*?)" auf "(.*?)"$/ do |field_name, value|
  field = Field.find find(".row.emboss[data-type='field']", match: :prefer_exact, text: field_name)["data-id"]
  within(".field[data-id='#{field[:id]}']") do
    case field[:type]
      when "radio"
        find("label", :text => value).click
      when "select"
        find("option", :text => value).select_option
      when "checkbox"
        find("label", :text => value).click
      else
        raise "unknown field"
    end
  end
end

Dann /^scanne oder gebe ich den Inventarcode von einem Gegenstand ein, der am Lager und in keinem Vertrag vorhanden ist$/ do
  @item = @current_inventory_pool.items.find {|i| i.in_stock? and i.contract_lines.blank?}
  within("#item-selection") do
    find("[data-barcode-scanner-target]").set @item.inventory_code
    find("button[type=submit]").click
  end
end

Dann /^scanne oder gebe ich den Inventarcode ein$/ do
  @item ||= @current_inventory_pool.items.select{|i| i.contract_lines.empty?}.first
  within("#item-selection") do
    find("[data-barcode-scanner-target]").set @item.inventory_code
    find("button[type=submit]").click
  end
end

Dann /^sehe ich alle Werte des Gegenstandes in der Übersicht mit Modellname, die geänderten Werte sind bereits gespeichert$/ do
  FastGettext.locale = @current_user.language.locale_name.gsub(/-/, "_")
  Field.all.each do |field|
    next if all(".field[data-id='#{field[:id]}']").empty?
    within("form#flexible-fields") do
      field_el = find(".field[data-id='#{field.id}']")
      value = field.get_value_from_params @item.reload
      field_type = field.type
      if field_type == "date"
        unless value.blank?
          value = Date.parse(value) if value.is_a?(String)
          field_el.should have_content value.year
          field_el.should have_content value.month
          field_el.should have_content value.day
        end
      elsif field[:attribute] == "retired"
        unless value.blank?
          field_el.should have_content _(field[:values].first[:label])
        end
      elsif field_type == "radio"
        if value
          value = field[:values].detect{|v| v[:value] == value}[:label]
          field_el.should have_content _(value)
        end
      elsif field_type == "select"
        if value
          value = field[:values].detect{|v| v[:value] == value}[:label]
          field_el.should have_content _(value)
        end
      elsif field_type == "autocomplete"
        if value
          value = field.as_json["values"].detect{|v| v["value"] == value}["label"]
          field_el.should have_content _(value)
        end
      elsif field_type == "autocomplete-search"
        if value
          if field[:label] == "Model"
            value = Model.find(value).name
            field_el.should have_content value
          end
        end
      else
        field_el.should have_content _(value)
      end
    end
  end

  find("form#flexible-fields .field[data-id='#{Field.find_by_label("Model").id}']", text: @item.reload.model.name)
end

Dann /^die geänderten Werte sind hervorgehoben$/ do
  find("#field-selection .field", match: :first)
  all("#field-selection .field").each do |selected_field|
    c = all("#item-section .field[data-id='#{selected_field['data-id']}'].success").count + all("#item-section .field[data-id='#{selected_field['data-id']}'].error").count
    c.should == 1
  end
end

Dann /^wähle ich die Felder über eine List oder per Namen aus$/ do
  field = Field.all.select{|f| f[:readonly] == nil and f[:type] != "autocomplete-search"}.last
  find("#field-input").click
  find("#field-input").set field.label
  find("a.ui-corner-all", match: :first, text: field.label).click
  @all_editable_fields = all("#field-selection .field", :visible => true)
end

Dann /^ich setze ihre Initalisierungswerte$/ do
  fields = all("#field-selection .field input, #field-selection .field textarea", :visible => true)
  fields.count.should > 0
  fields.each do |input|
    input.set "Test123"
  end
end

Dann /^scanne oder gebe ich den Inventarcode eines Gegenstandes ein der nicht gefunden wird$/ do
  @not_existing_inventory_code = "THIS FOR SURE NO INVENTORY CODE"
  within("#item-selection") do
    find("[data-barcode-scanner-target]").set @not_existing_inventory_code
    find("button[type=submit]").click
  end
end

Dann /^erhählt man eine Fehlermeldung$/ do
  find("#flash .error", text: _("The Inventory Code %s was not found.") % @not_existing_inventory_code)
end

Dann /^gebe ich den Anfang des Inventarcodes eines Gegenstand ein$/ do
  @item= @current_inventory_pool.items.first
  find("#item-selection [data-barcode-scanner-target]").set @item.inventory_code[0..1]
end

Dann /^wähle den Gegenstand über die mir vorgeschlagenen Suchtreffer$/ do
  page.should have_selector(".ui-menu-item")
  find("a.ui-corner-all", :text => @item.inventory_code).click
end

Angenommen /^man editiert ein Gerät über den Helferschirm mittels Inventarcode$/ do
  step 'man ist auf dem Helferschirm'
  step 'wähle ich die Felder über eine List oder per Namen aus'
  step 'ich setze ihre Initalisierungswerte'
  step 'scanne oder gebe ich den Inventarcode ein'
  step 'sehe ich alle Werte des Gegenstandes in der Übersicht mit Modellname, die geänderten Werte sind bereits gespeichert'
  step 'die geänderten Werte sind hervorgehoben'
end

Wenn /^man die Editierfunktion nutzt$/ do
  find("#item-section button#item-edit", :text => _("Edit Item")).click
end

Dann /^kann man an Ort und Stelle alle Werte des Gegenstandes editieren$/ do
  @parent_el = find("#item-section")
  step 'ich setze all ihre Initalisierungswerte'
end

Dann /^man die Änderungen speichert$/ do
  find("#item-section button#save-edit").click
  find("#notifications .green")
end

Dann /^sind sie gespeichert$/ do
  step %Q{sehe ich alle Werte des Gegenstandes in der Übersicht mit Modellname, die geänderten Werte sind bereits gespeichert}
end

Wenn /^man seine Änderungen widerruft$/ do
  find("#item-section a", :text => _("Cancel")).click
end

Dann /^sind die Änderungen widerrufen$/ do
  @item.to_json.should == @item.reload.to_json
end

Dann /^man sieht alle ursprünglichen Werte des Gegenstandes in der Übersicht$/ do
  step %Q{sehe ich alle Werte des Gegenstandes in der Übersicht mit Modellname, die geänderten Werte sind bereits gespeichert}
end

Dann(/^wähle ich das Feld "(.*?)" aus der Liste aus$/) do |field|
  find("#field-input").click
  find("#field-input").set field
  sleep(0.44)
  find("a.ui-corner-all", match: :prefer_exact, text: field).click
  @all_editable_fields = all("#field-selection .field", :visible => true)
end

Dann(/^ich setze den Wert für das Feld "(.*?)"$/) do |field|
  find(".row.emboss", match: :prefer_exact, text: field).find("input").set "Test123"
end

Angenommen(/^es existiert ein Gegenstand, welches sich denselben Ort mit einem anderen Gegenstand teilt$/) do
  location = Location.find {|l| l.items.count >= 2}
  @item, @item_2 = location.items.first, location.items.second
  @item_2_location = @item_2.location
end

Dann(/^gebe ich den Anfang des Inventarcodes des spezifischen Gegenstandes ein$/) do
  find("#item-selection [data-barcode-scanner-target]").set @item.inventory_code[0..1]
end

Dann(/^der Ort des anderen Gegenstandes ist dergleiche geblieben$/) do
  @item_2.reload.location.should == @item_2_location
end

Wenn(/^"(.*?)" ausgewählt und auf "(.*?)" gesetzt wird, dann muss auch "(.*?)" angegeben werden$/) do |field, value, dependent_field|
  find("#field-input").click
  find("#field-input").set field
  sleep(0.5)
  find("a.ui-corner-all", match: :prefer_exact, text: field).click
  step 'ich setze das Feld "%s" auf "%s"' % [field, value]
  find(".row.emboss", match: :prefer_exact, text: dependent_field)
end

Wenn(/^ein Pflichtfeld nicht ausgefüllt\/ausgewählt ist, dann lässt sich der Inventarhelfer nicht nutzen$/) do
  step %Q{scanne oder gebe ich den Inventarcode ein}
end

Angenommen(/^man editiert das Feld "(.*?)" eines ausgeliehenen Gegenstandes$/) do |name|
  field = Field.all.detect{|f| _(f.label) == name}
  step %Q{wähle ich das Feld "#{name}" aus der Liste aus}
  @item = @current_inventory_pool.items.not_in_stock.sample
  @item_before = @item.to_json
  step %Q{scanne oder gebe ich den Inventarcode ein}
end

Dann(/^erhält man eine Fehlermeldung, dass man diese Eigenschaft nicht editieren kann, da das Gerät ausgeliehen ist$/) do
  page.should have_content _("The responsible inventory pool cannot be changed because the item is currently not in stock.")
  @item_before.should == @item.reload.to_json
end

Dann(/^erhält man eine Fehlermeldung, dass man den Gegenstand nicht ausmustern kann, da das Gerät ausgeliehen ist$/) do
  page.should have_content _("The item cannot be retired because it's not returned yet.")
  @item_before.should == @item.reload.to_json
end

Dann(/^erhält man eine Fehlermeldung, dass man diese Eigenschaft nicht editieren kann, da das Gerät in einem Vortrag vorhanden ist$/) do
  page.should have_content _("The model cannot be changed because the item is used in contracts already.")
  @item_before.should == @item.reload.to_json
end

Angenommen(/^man editiert das Feld "(.*?)" eines Gegenstandes, der im irgendeinen Vertrag vorhanden ist$/) do |name|
  field = Field.all.detect{|f| _(f.label) == name}
  step %Q{wähle ich das Feld "#{name}" aus der Liste aus}
  @item = @current_inventory_pool.items.select{|i| not i.contract_lines.blank?}.sample
  @item_before = @item.to_json
  fill_in_autocomplete_field name, @current_inventory_pool.models.select{|m| m != @item.model}.sample.name
  step %Q{scanne oder gebe ich den Inventarcode ein}
end

Angenommen(/^man mustert einen ausgeliehenen Gegenstand aus$/) do
  step 'wähle ich das Feld "Ausmusterung" aus der Liste aus'
  find(".row.emboss", match: :prefer_exact, text: _("Retirement")).find("select").select _("Yes")
  find(".row.emboss", match: :prefer_exact, text: _("Reason for Retirement")).find("input, textarea").set "Retirement reason"
  @item = @current_inventory_pool.items.not_in_stock.sample
  @item_before = @item.to_json
  step 'scanne oder gebe ich den Inventarcode ein'
end
