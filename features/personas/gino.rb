# coding: UTF-8

# Persona:  Gino
# Job:      Admin
#

require "#{Rails.root}/features/support/leihs_factory.rb"

module Persona
  class Gino
    @@name = "Gino"
    @@lastname = "F."
    @@email = "gino@zhdk.ch"
    @@inventory_pool = FactoryGirl.create :inventory_pool

    def initialize
      ActiveRecord::Base.transaction do
        create_minimal_setup
        create_admin_user
      end
    end

    def create_minimal_setup
      FactoryGirl.create :setting unless Setting.first
      LeihsFactory.create_default_languages
      LeihsFactory.create_default_authentication_systems
      LeihsFactory.create_default_building
    end

    def create_admin_user
      @language = Language.find_by_locale_name "de-CH"
      @user = FactoryGirl.create(:user, :language => @language, :firstname => @@name, :lastname => @@lastname, :login => @@name.downcase, :email => @@email)
      @user.access_rights.create(:role => :admin)
    end
  end
end
