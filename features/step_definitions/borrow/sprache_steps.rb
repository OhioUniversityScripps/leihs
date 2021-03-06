# -*- encoding : utf-8 -*-

Wenn(/^ich die Sprache auf "(.*?)" umschalte$/) do |language|
  first("a[href*='locale']", :text => language).click
end

Dann(/^ist die Sprache "(.*?)"$/) do |language|
  s = case language
        when "English"
          "en-GB"
        when "Deutsch"
          "de-CH"
  end
  @current_user.reload.language.locale_name.should == s
  first("a[href=''] strong", :text => language)
end